local ECSWorld = require("src.ecs.ECSWorld")
local Camera = require("lib.cam11")
local MapGraph = require("src.scenes.map_scene.MapGraph")
local PixelCanvas = require("src.modules.PixelCanvas")
local decor_types = require("src.scenes.map_scene.decor_types")
local DecorBuilder = require("src.scenes.map_scene.DecorBuilder")
local fogService = require("src.fogService")
local hoverService = require("src.hud.hoverService")
local juiceService = require("src.juiceService")

local CAMERA_ZOOM = 1--0.5
local NODE_RADIUS = 4
local PLAYER_RADIUS = 5
local PAN_SPEED = 200
local HOVER_DIST_FRAC = 0.4 -- fraction of distanceBetweenNodes
local COMMANDER_SPEED = 80 -- world pixels per second
local CULL_PAD = 100

local PATH_SEARCH_DEPTH = 3
local FOG_CLEAR_RADIUS = 120
local FOG_REVEAL_DEPTH = 4

local GALLOP_FREQ = 18
local GALLOP_TILT = 0.15
local GALLOP_BOUNCE = 4


---@class g.MapScene
local map_scene = {}

function map_scene:init()
end

local function isPointVisible(x, y, view, pad)
    pad = pad or 0
    return x >= view.x - pad and x <= view.x + view.w + pad and y >= view.y - pad and y <= view.y + view.h + pad
end

---@param graph MapGraph
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
local function getHoveredNode(graph, wx, wy)
    local best, bestDist = nil, math.huge
    graph:forEachNode(function(node)
        local nx, ny = graph:getDrawPos(node)
        local dx, dy = nx - wx, ny - wy
        local d2 = dx * dx + dy * dy
        if d2 < bestDist then
            best = node
            bestDist = d2
        end
    end)
    local maxDist = (graph.distanceBetweenNodes * HOVER_DIST_FRAC)
    if best and bestDist <= maxDist * maxDist then
        return best
    end
    return nil
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

    local run = g.getRun()
    if not run.mapGraph then
        -- Run the proc gen algorithm until we have a valid setup.
        -- (nodeCount > 20 is valid)
        repeat run.mapGraph = MapGraph.generate({
            width = 50,
            height = 30,
            nodePruneChance = 0.35,
            edgePruneChance = 0.02,
            distanceBetweenNodes = 130,
            randomDiagonalChance = 0.5,
            nodeOffsetFactor = 0.35,
            scaleX = 1,
            scaleY = 0.6,
            decorTypes = {
                "mountain_large",
                "mountain_small_1",
                "mountain_small_2",
                "tree_large_1",
                "tree_small_1",
                "grass_1",
                "grass_2",
                "grass_3"
            },
        }) until run.mapGraph:countNodes() > 20
    end

    -- Build sorted decor list for drawing
    self.decorList = {}
    run.mapGraph:forEachDecor(function(d)
        self.decorList[#self.decorList + 1] = d
    end)

    -- Build sorted node list for drawing
    self.nodeList = {}
    run.mapGraph:forEachNode(function(node)
        local nx, ny = run.mapGraph:getDrawPos(node)
        self.nodeList[#self.nodeList + 1] = {node = node, x = nx, y = ny}
    end)

    local function byY(a, b)
        return a.y < b.y
    end
    table.sort(self.decorList, byY)
    table.sort(self.nodeList, byY)

    local pnode = run.mapGraph:getPlayerNode()
    if pnode then
        self.camX, self.camY = run.mapGraph:getDrawPos(pnode)
    else
        self.camX, self.camY = 0, 0
    end
end

function map_scene:_buildFogClearCells()
    local run = g.getRun()
    local graph = run.mapGraph
    local step = 24
    local clearCells = math.ceil(FOG_CLEAR_RADIUS / step)
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

    for _, entry in ipairs(self.nodeList) do
        if entry.node.seen then
            local cx = math.floor(entry.x / step)
            local cy = math.floor(entry.y / step)
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
local function enterNode(node)
    g.call("arrivedAtNode", node.nodeType, node)
    if not node.visited then
        node.visited = true
        node:enter()
    end
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
        gold = 10 * run.level,
        randomMana = true,
    })
end

function map_scene:update(dt)
    checkLevelUp()

    -- WASD panning
    local dx, dy = 0, 0
    if love.keyboard.isDown("w") or love.keyboard.isDown("up")    then dy = dy - 1 end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down")  then dy = dy + 1 end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left")  then dx = dx - 1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then dx = dx + 1 end
    self.camX = self.camX + dx * PAN_SPEED * dt
    self.camY = self.camY + dy * PAN_SPEED * dt

    -- Commander travel
    if self.traveling then
        local trav = self.traveling
        trav.t = trav.t + trav.speed * dt
        self.gallop = self.gallop + dt * GALLOP_FREQ
        if trav.t >= 1 then
            local graph = g.getRun().mapGraph
            graph:setPlayerPosition(trav.toNode.x, trav.toNode.y)
            self.traveling = nil
            enterNode(trav.toNode)
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
    self.ecs:update(dt)
end


function map_scene:keypressed(k)
    if consts.DEV_MODE then
        if k == "o" then
            g.gotoScene("shop_scene")
        end
        if k == "q" then
            nodeEventService.startRandomEvent()
        end
    end
end

function map_scene:mousepressed(mx, my, button)
    if button == 1 then
        self.dragging = true
        self.dragMoved = false
    end
end

function map_scene:mousereleased(mx, my, button)
    if button == 1 then
        self.dragging = false
        -- If we didn't drag, treat as a click
        if not self.dragMoved and not self.traveling then
            local run = g.getRun()
            local graph = run.mapGraph
            local pnode = graph and graph:getPlayerNode()
            if pnode then
                local wx, wy = self.camera:toWorld(mx, my)
                local hovered = getHoveredNode(graph, wx, wy)
                if hovered and hovered ~= pnode then
                    local path = graph:findPath(pnode.x, pnode.y, hovered.x, hovered.y, PATH_SEARCH_DEPTH)
                    if path and #path >= 2 then
                        local ax, ay = graph:getDrawPos(path[1])
                        local bx, by = graph:getDrawPos(path[2])
                        local dist = math.sqrt((bx - ax)^2 + (by - ay)^2)
                        if bx < ax then self.commanderFacing = -1 end
                        if bx > ax then self.commanderFacing = 1 end
                        self.traveling = {
                            toNode = path[2],
                            ax = ax, ay = ay, bx = bx, by = by,
                            t = 0, speed = dist > 0 and (COMMANDER_SPEED / dist) or 1,
                        }
                    end
                end
            end
        end
    end
end

function map_scene:mousemoved(mx, my, dmx, dmy)
    if self.dragging then
        if math.abs(dmx) + math.abs(dmy) > 2 then
            self.dragMoved = true
        end
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

    local run = g.getRun()
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

        -- drawGround (TODO)

        -- edges
        graph:forEachEdge(function(a, b)
            if isEdgeVisible(graph, a, b, view, CULL_PAD) then
                renderEdge(graph, a, b, g.COLORS.MAP_EDGE:getRGBA())
            end
        end)

        -- ground ellipses
        for _, n in ipairs(self.nodeList) do
            if isPointVisible(n.x, n.y, view, CULL_PAD) then
                n.node:drawBelow(n.x, n.y)
            end
        end

        -- decor + node images, sorted by y
        local builder = DecorBuilder()
        for _, d in ipairs(self.decorList) do
            if isPointVisible(d.x, d.y, view, CULL_PAD) then
                local dtype = decor_types.get(d.decorType)
                if dtype and dtype.image then
                    builder:addImage(dtype.image, d.x, d.y, 0, nil, dtype.opacity)
                end
            end
        end
        for _, n in ipairs(self.nodeList) do
            if isPointVisible(n.x, n.y, view, CULL_PAD) then
                n.node:buildDecor(builder, n.x, n.y)
            end
        end

        -- hover highlight: path from player to hovered node
        local pnode = graph:getPlayerNode()
        if pnode then
            local mx, my = love.mouse.getPosition()
            local wx, wy = self.camera:toWorld(mx, my)
            local hovered = getHoveredNode(graph, wx, wy)
            if (not self.traveling) and hovered and hovered ~= pnode then
                local path = graph:findPath(pnode.x, pnode.y, hovered.x, hovered.y, PATH_SEARCH_DEPTH)
                if path and #path >= 2 then
                    -- first edge bold yellow, rest pale yellow
                    local r, gg, b, a = g.COLORS.MAP_EDGE_HIGHLIGHT:getRGBA()
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

        -- fog
        local fogRegion = {
            x = view.x,
            y = view.y,
            w = view.w,
            h = view.h,
        }
        local step = 24
        local clearCells = self:_buildFogClearCells()
        fogService.renderFog(fogRegion, function(x, y)
            local cx = math.floor(x / step)
            local row = clearCells[cx]
            return not (row and row[math.floor(y / step)])
        end)
    end

    lg.setColor(1, 1, 1, 1)
    iml.popTransform()
    self.pixelCanvas:finish()

    ui.startUI()
    self.hud:drawUI({ mapScene = true })
    ui.endUI()
end

return map_scene
