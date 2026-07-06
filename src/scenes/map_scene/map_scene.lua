local ECSWorld = require("src.ecs.ECSWorld")
local Camera = require("lib.cam11")
local MapGraph = require("src.scenes.map_scene.MapGraph")
local nodes = require("src.scenes.map_scene.nodes")
local PixelCanvas = require("src.modules.PixelCanvas")
local decor_types = require("src.scenes.map_scene.decor_types")
local DecorBuilder = require("src.scenes.map_scene.DecorBuilder")
local fogService = require("src.fogService")
local hoverService = require("src.hud.hoverService")
local juiceService = require("src.juiceService")
local ambienceService = require("src.ambienceService")
local mapTypes = require("src.scenes.map_scene.map_types")
local s = require("src.hud.settings")

local CAMERA_ZOOM = 1--0.5
local NODE_RADIUS = 4
local PLAYER_RADIUS = 5
local PAN_SPEED = 200
local HOVER_DIST_FRAC = 0.4 -- fraction of distanceBetweenNodes
local COMMANDER_SPEED = 80 -- world pixels per second
local CULL_PAD = 100

local PATH_SEARCH_DEPTH = 3
local FOG_CLEAR_RADIUS = 120
local FOG_STEP = 24
local FOG_REVEAL_DEPTH = 4

local GALLOP_FREQ = 8
local GALLOP_TILT = 0.2
local GALLOP_BOUNCE = 8


---@class g.MapScene
local map_scene = {}

function map_scene:init()
end

local function isPointVisible(x, y, view, pad)
    pad = pad or 0
    return x >= view.x - pad and x <= view.x + view.w + pad and y >= view.y - pad and y <= view.y + view.h + pad
end

---@param graph MapGraph
---@param a MapNode
---@param b MapNode
---@param rr number
---@param gg number
---@param bb number
---@param aa number?
---@param width number?
local function renderEdge(graph, a, b, rr, gg, bb, aa, width)
    local lg = love.graphics
    local ax, ay = graph:getDrawPos(a)
    local bx, by = graph:getDrawPos(b)
    lg.setColor(rr, gg, bb, aa or 1)
    lg.setLineWidth(width or 4)
    lg.line(ax, ay, bx, by)
end

local function isEdgeVisible(graph, a, b, view, pad)
    local ax, ay = graph:getDrawPos(a)
    local bx, by = graph:getDrawPos(b)
    pad = pad or 0
    local minX = math.min(ax, bx) - pad
    local maxX = math.max(ax, bx) + pad
    local minY = math.min(ay, by) - pad
    local maxY = math.max(ay, by) + pad
    return maxX >= view.x and minX <= view.x + view.w and maxY >= view.y and minY <= view.y + view.h
end

local function renderNodeAt(node, nx, ny, r, g, b, a, radius)
    local lg = love.graphics
    lg.setColor(r, g, b, a or 1)
    lg.ellipse("fill", nx, ny, radius or NODE_RADIUS, (radius or NODE_RADIUS) * 0.5)
end

---@param graph MapGraph
local function renderNode(graph, node, r, g, b, a, radius)
    local nx, ny = graph:getDrawPos(node)
    renderNodeAt(node, nx, ny, r, g, b, a, radius)
end

---@param graph MapGraph
---@param node MapNode Base node
---@param count {shrine:integer,fountain:integer,shop:integer}
---@return MapNode
local function rerollDynamicNode(graph, node, count)
    if nodes.getType(node) ~= "dynamic" then
        return node
    end

    local totalWeight = count.shrine + count.fountain + count.shop
    local list = {
        {nodes.ShrineNode, math.max(1, totalWeight - count.shrine)},
        {nodes.FountainNode, math.max(1, totalWeight - count.fountain)},
        {nodes.ShopNode, math.max(1, totalWeight - count.shop)},
    }
    local choice = helper.pickWeighted(list, graph.rng)
    ---@cast choice -integer
    return assert(graph:setNode(node.x, node.y, choice))
end

--- Registers an iml panel per node (under the camera transform) and
--- returns the hovered node, plus whether it was just clicked.
---@param graph MapGraph
---@param clearCells table<integer, table<integer, boolean>>
---@return MapNode? hovered
---@return MapNode? clicked
local function updateNodePanels(graph, clearCells)
    local size = graph.distanceBetweenNodes * HOVER_DIST_FRAC
    local mx, my = iml.getTransformedPointer()
    ---@type MapNode?
    local potential = nil
    local distance = math.huge
    local hovered, clicked = nil, nil
    graph:forEachNode(function(node)
        local nx, ny = graph:getDrawPos(node)
        local cx = math.floor(nx / FOG_STEP)
        local cy = math.floor(ny / FOG_STEP)
        if not (clearCells and clearCells[cx] and clearCells[cx][cy]) then
            return
        end
        local d = helper.magnitude(nx - mx, ny - my)
        -- Do a circle distance check to select potential node.
        if d <= size and d < distance then
            potential = node
            distance = d
        end
    end)

    if potential then
        -- IML check is important because a popup may have higher priority panel
        -- which can make these hovered and wasJustClicked call false (which is intended)
        -- Since our selection is a circle, the IML rectangle check is always inside a circle.
        local nx, ny = graph:getDrawPos(potential)
        local x, y, w, h = nx - size, ny - size, size * 2, size * 2
        if iml.isHovered(x, y, w, h, potential) then hovered = potential end
        if iml.wasJustClicked(x, y, w, h, 1, potential) then clicked = potential end
    end

    return hovered, clicked
end

function map_scene:enter()
    juiceService.reset()
    self.ecs = ECSWorld()
    self.camera = Camera(0, 0, CAMERA_ZOOM)
    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.pixelCanvas = PixelCanvas.new(love.graphics.getDimensions())
    self.hud = HUD()
    self.dragging = false
    self.commanderFacing = 1
    self.gallop = 0
    self.traveling = nil

    local run = g.getRun()
    local firstMapEntry = not run.mapGraph
    if firstMapEntry then
        -- TODO: Pick map type based on level
        -- Example: level 1 = forest, level 2 = fall, level 3 = hell
        self:_buildMap("forest")
        self:_incrementDays()
    end
    self:_buildNodeState()
    if firstMapEntry then
        g.saveRun()
    end
end

---@param mapType string
---@param fromPortal boolean?
function map_scene:_buildMap(mapType, fromPortal)
    local run = g.getRun()
    -- Run the proc gen algorithm until we have a valid setup.
    -- (nodeCount > 20 is valid)
    repeat run.mapGraph = MapGraph.generate({
        width = 50,
        height = 30,
        nodePruneChance = 0.35,
        edgePruneChance = 0.02,
        distanceBetweenNodes = 160,
        randomDiagonalChance = 0.5,
        nodeOffsetFactor = 0.35,
        scaleX = 1,
        scaleY = 0.6,
        mapType = mapType,
        fromPortal = not not fromPortal,
    }) until run.mapGraph:countNodes() > 20
    return self:_buildNodeState()
end

function map_scene:_buildNodeState()
    local run = g.getRun()

    -- Build sorted decor list for drawing
    self.decorList = {}
    run.mapGraph:forEachDecor(function(d)
        self.decorList[#self.decorList + 1] = d
    end)

    -- Build sorted node list for drawing
    ---@type MapNode[]
    self.nodeList = {}
    run.mapGraph:forEachNode(function(node)
        self.nodeList[#self.nodeList + 1] = node
    end)

    local function byY(a, b)
        return a.y < b.y
    end
    table.sort(self.decorList, byY)
    table.sort(self.nodeList, function(a, b)
        local _, ay = run.mapGraph:getDrawPos(a)
        local _, by = run.mapGraph:getDrawPos(b)
        return ay < by
    end)

    local pnode = run.mapGraph:getPlayerNode()
    if pnode then
        self.camX, self.camY = run.mapGraph:getDrawPos(pnode)
    else
        self.camX, self.camY = 0, 0
    end

    self.camera:setPos(self.camX, self.camY)
    ambienceService.reInitialize(self.camera:getTransform(), g.getMapType().cloudSprites)
end

function map_scene:_buildFogClearCells()
    local run = g.getRun()
    local graph = run.mapGraph
    local clearCells = math.ceil(FOG_CLEAR_RADIUS / FOG_STEP)
    ---@type table<integer, table<integer, boolean>>
    local cells = {}

    local pnode = graph:getPlayerNode()
    if pnode then
        local queue = {pnode}
        local depths = {[pnode] = 0}
        local head = 1
        while head <= #queue do
            local node = queue[head]
            local depth = depths[node]
            head = head + 1
            node.seen = true
            if depth < FOG_REVEAL_DEPTH then
                for _, nb in ipairs(graph:getNeighbors(node.x, node.y)) do
                    if not depths[nb] then
                        depths[nb] = depth + 1
                        queue[#queue + 1] = nb
                    end
                end
            end
        end
    end

    for _, node in ipairs(self.nodeList) do
        if node.seen then
            local nx, ny = graph:getDrawPos(node)
            local cx = math.floor(nx / FOG_STEP)
            local cy = math.floor(ny / FOG_STEP)
            for dx = -clearCells, clearCells do
                local row = cells[cx + dx]
                if not row then
                    row = {}
                    cells[cx + dx] = row
                end
                for dy = -clearCells, clearCells do
                    row[cy + dy] = true
                end
            end
        end
    end
    return cells
end

function map_scene:leave()
    self.ecs = nil
    self.camera = nil
    self.decorList = nil
    self.nodeList = nil
end

function map_scene:pollHandlers()
    self.ecs:addSystemHandlers()
    g.addBlessingAndEntityHandlers()
end


---@param node MapNode
---@return boolean delayedDayIncrement
local function enterNode(node)
    g.call("arrivedAtNode", node.nodeType, node)
    if not node.visited then
        node.visited = true
        node:enter()
        return nodes.getType(node) ~= "empty"
    end
    return false
end

---@param count integer?
function map_scene:_incrementDays(count)
    g.incrementDays(count)
    -- TODO: If incursion happends, spawn boss node all nearest to empty node
    g.saveRun()
end

function map_scene:_incrementPendingDaysWhenReady()
    if not self.pendingDayIncrement then return end
    if fadeToBlackService.isAnimating() or g.isAnyPopupOpen() then return end

    self:_incrementDays(self.pendingDayIncrement)
    self.pendingDayIncrement = nil
end


local function checkLevelUp()
    local run = g.getRun()
    local xpReq = run:getXpRequirement()

    if xpReq <= 0 or run.xp < xpReq then
        return
    end

    if g.isAnyPopupOpen() then
        return
    end

    -- otherwise, level up!
    run.xp = run.xp - xpReq
    run.level = run.level + 1

    rewardPopupService.levelUpReward({
        {type = "gold", amount = 10 * run.level},
        {type = "mana_blessing"}
    })
end

function map_scene:update(dt)
    checkLevelUp()
    self:_incrementPendingDaysWhenReady()

    -- WASD panning
    local dx, dy = 0, 0
    if love.keyboard.isDown("w") or love.keyboard.isDown("up")    then dy = dy - 1 end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down")  then dy = dy + 1 end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left")  then dx = dx - 1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then dx = dx + 1 end
    self.camX = self.camX + dx * PAN_SPEED * dt
    self.camY = self.camY + dy * PAN_SPEED * dt

    -- Reroll dynamic nodes if they were seen.
    if self.nodeList then
        local graph = g.getRun().mapGraph
        table.sort(self.nodeList, function(a, b)
            local _, ay = graph:getDrawPos(a)
            local _, by = graph:getDrawPos(b)
            return ay < by
        end)

        local count = {shrine = 0, fountain = 0, shop = 0}
        for _, node in ipairs(self.nodeList) do
            local nodeType = nodes.getType(node)
            if count[nodeType] then
                count[nodeType] = count[nodeType] + 1
            end
            node:update(dt)
        end

        for i, node in ipairs(self.nodeList) do
            if node.seen and nodes.getType(node) == "dynamic" then
                local newNode = rerollDynamicNode(graph, node, count)
                newNode.seen = true
                self.nodeList[i] = newNode

                local newnt = nodes.getType(newNode)
                count[newnt] = count[newnt] + 1
            end
        end
    end

    -- Commander travel
    if self.traveling then
        local trav = self.traveling
        trav.t = trav.t + trav.speed * dt
        self.gallop = self.gallop + dt * GALLOP_FREQ
        if trav.t >= 1 then
            local graph = g.getRun().mapGraph
            graph:setPlayerPosition(trav.toNode.x, trav.toNode.y)
            local delayedDayIncrement = enterNode(trav.toNode)
            if delayedDayIncrement then
                self.pendingDayIncrement = (self.pendingDayIncrement or 0) + 1
            else
                self:_incrementDays()
            end
            -- Continue through intermediate nodes, unless the node we just
            -- arrived at opened a popup / scene-transition (eg battle, shop).
            local hasMore = trav.index + 1 < #trav.path
            if hasMore and not fadeToBlackService.isAnimating() and not g.isAnyPopupOpen() then
                trav.index = trav.index + 1
                self:_startTravelLeg(graph)
            else
                self.traveling = nil
            end
            return
        end
    end

    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.pixelCanvas:resize(love.graphics.getDimensions())
    if not consts.DEV_MODE then
        self.camera:setZoom(CAMERA_ZOOM * ui.getUIScaling())
    end
    juiceService.update(dt)
    local _sx, _sy = juiceService.getShakeOffset()
    self.camera:setPos(self.camX + _sx, self.camY + _sy)
    ambienceService.update(dt, self.camera:getTransform())
    self.ecs:update(dt)
end


function map_scene:keypressed(k)
    if s.keypressed(k) then return end
    if consts.DEV_MODE then
        if k == "o" then
            nodeEventService.openFountainPopup()
        end
        if k == "q" then
            nodeEventService.startRandomEvent()
        end
    end
end

---@param graph MapGraph
function map_scene:travelTo(graph, pnode, hovered)
    if self.traveling or hovered == pnode then return end
    local path = graph:findPath(pnode.x, pnode.y, hovered.x, hovered.y, PATH_SEARCH_DEPTH)
    if not (path and #path >= 2) then return end
    -- index = the leg currently being walked; toNode is path[index + 1].
    self.traveling = { path = path, index = 1 }
    self:_startTravelLeg(graph)
end

--- (Re)start the current leg of self.traveling (from path[index] to path[index+1]).
---@param graph MapGraph
function map_scene:_startTravelLeg(graph)
    local trav = self.traveling
    local fromNode = trav.path[trav.index]
    local toNode = trav.path[trav.index + 1]
    local ax, ay = graph:getDrawPos(fromNode)
    local bx, by = graph:getDrawPos(toNode)
    local dist = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
    if bx < ax then self.commanderFacing = -1 end
    if bx > ax then self.commanderFacing = 1 end
    trav.toNode = toNode
    trav.ax, trav.ay, trav.bx, trav.by = ax, ay, bx, by
    trav.t = 0
    trav.speed = dist > 0 and (COMMANDER_SPEED / dist) or 1
end

function map_scene:mousepressed(mx, my, button)
    if button == 1 then
        self.dragging = true
    end
end

function map_scene:mousereleased(mx, my, button)
    if button == 1 then
        self.dragging = false
    end
end

function map_scene:mousemoved(mx, my, dmx, dmy)
    if self.dragging then
        local zoom = self.camera:getZoom()
        self.camX = self.camX - dmx / zoom
        self.camY = self.camY - dmy / zoom
    end
end

function map_scene:wheelmoved(dx, dy)
    if dy ~= 0 then
        local zoom = self.camera:getZoom()
        zoom = zoom * (1 + dy * 0.1)
        zoom = math.max(0.1, math.min(2, zoom))
        self.camera:setZoom(zoom)
    end
end



---@param scene g.MapScene
---@param graph MapGraph
---@param pnode any
---@param builder g.DecorBuilder
local function addCommander(scene, graph, pnode, builder)
    local cx, cy
    local r, bounce = 0, 0
    if scene.traveling then
        local trav = scene.traveling
        cx = trav.ax + (trav.bx - trav.ax) * trav.t
        cy = trav.ay + (trav.by - trav.ay) * trav.t
        r = math.sin(scene.gallop) * GALLOP_TILT * scene.commanderFacing
        bounce = -math.abs(math.sin(scene.gallop)) * GALLOP_BOUNCE
    else
        cx, cy = graph:getDrawPos(pnode)
    end
    local run = g.getRun()
    local cinfo = g.getCommanderInfo(run.commander)
    builder:addImage(cinfo.image, cx, cy + bounce, r, scene.commanderFacing)
end

function map_scene:draw()
    local lg = love.graphics
    lg.clear(g.COLORS.MAP_GROUND_COLOR)

    self.pixelCanvas:start(self.camera:getTransform())
    iml.pushTransform(self.camera:getTransform())

    self.ecs:draw()

    juiceService.draw()

    local run = g.getRun()
    local mapType = g.getMapType()
    local graph = run.mapGraph
    if graph then
        local sw, sh = love.graphics.getDimensions()
        local x1, y1 = self.camera:toWorld(0, 0)
        local x2, y2 = self.camera:toWorld(sw, sh)
        local view = {
            x = math.min(x1, x2),
            y = math.min(y1, y2),
            w = math.abs(x2 - x1),
            h = math.abs(y2 - y1),
        }

        -- drawGround
        graph:drawGroundDecors(view)

        -- edges
        graph:forEachEdge(function(a, b)
            if isEdgeVisible(graph, a, b, view, CULL_PAD) then
                renderEdge(graph, a, b, mapType.mapPath:getRGBA())
            end
        end)

        -- ground ellipses
        for _, n in ipairs(self.nodeList) do
            local nx, ny = graph:getDrawPos(n)
            if isPointVisible(nx, ny, view, CULL_PAD) then
                n:drawBelow(nx, ny)
            end
        end

        -- decor + node images, sorted by y
        local builder = DecorBuilder() --[[@as g.DecorBuilder]]
        for _, d in ipairs(self.decorList) do
            if isPointVisible(d.x, d.y, view, CULL_PAD) then
                local dtype = decor_types.get(d.decorType)
                if dtype and dtype.image then
                    builder:addImage(dtype.image, d.x, d.y, 0, nil, dtype.opacity, dtype.transformModifier)
                end
            end
        end
        for _, n in ipairs(self.nodeList) do
            local nx, ny = graph:getDrawPos(n)
            if isPointVisible(nx, ny, view, CULL_PAD) then
                n:buildDecor(builder, nx, ny)
            end
        end

        -- fog processing
        local fogRegion = {
            x = view.x,
            y = view.y,
            w = view.w,
            h = view.h,
        }
        local clearCells = self:_buildFogClearCells()

        -- hover highlight: path from player to hovered node
        local pnode = graph:getPlayerNode()
        if pnode then
            local hovered, clicked = updateNodePanels(graph, clearCells)
            if clicked then self:travelTo(graph, pnode, clicked) end
            if (not self.traveling) and hovered and hovered ~= pnode then
                local path = graph:findPath(pnode.x, pnode.y, hovered.x, hovered.y, PATH_SEARCH_DEPTH)
                if path and #path >= 2 then
                    -- first edge bold yellow, rest pale yellow
                    local r, gg, b, a = mapType.mapPathHighlight:getRGBA()
                    renderEdge(graph, path[1], path[2], r, gg, b, a, 6)
                    renderNode(graph, path[2], r, gg, b, a, NODE_RADIUS + 1)
                    for i = 2, #path - 1 do
                        renderEdge(graph, path[i], path[i + 1], r, gg, b, a, 6)
                        renderNode(graph, path[i + 1], r, gg, b, a, NODE_RADIUS + 1)
                    end
                end
                local hoverDescription = hovered:getHoverDescription()
                if hoverDescription then
                    hoverService.requestHover(function(box, fonts)
                        box:addText(hoverDescription, fonts.body)
                    end)
                end
            end

            -- commander (added to builder so it sorts by y)
            addCommander(self, graph, pnode, builder)
        end

        builder:finalize()

        -- fog rendering
        fogService.renderFog(fogRegion, graph.mapType.fogColor, function(x, y)
            local cx = math.floor(x / FOG_STEP)
            local row = clearCells[cx]
            return not (row and row[math.floor(y / FOG_STEP)])
        end)
    end

    lg.setColor(1, 1, 1, 1)
    iml.popTransform()
    self.pixelCanvas:finish()

    ambienceService.draw(self.camera:getTransform())

    ui.startUI()
    self.hud:drawUI({ mapScene = true })
    s.draw()
    ui.endUI()
end

return map_scene
