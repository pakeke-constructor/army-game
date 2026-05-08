local ECSWorld = require("src.ecs.ECSWorld")
local Camera = require("lib.cam11")
local MapGraph = require("src.scenes.map_scene.MapGraph")
local PixelCanvas = require("src.modules.PixelCanvas")
local decor_types = require("src.scenes.map_scene.decor_types")
local fogService = require("src.fogService")

local CAMERA_ZOOM = 0.5
local NODE_RADIUS = 4
local PLAYER_RADIUS = 5
local PAN_SPEED = 200
local HOVER_DIST_FRAC = 0.4 -- fraction of distanceBetweenNodes
local COMMANDER_SPEED = 80 -- world pixels per second

local PATH_SEARCH_DEPTH = 3
local FOG_CLEAR_RADIUS = 120
local FOG_REVEAL_DEPTH = 5


---@class g.MapScene
local map_scene = {}

function map_scene:init()
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

local function renderNodeAt(node, nx, ny, r, g, b, a, radius)
    local lg = love.graphics
    if node and node.draw then
        node:draw(nx, ny)
    else
        lg.setColor(r, g, b, a or 1)
        lg.ellipse("fill", nx, ny, radius or NODE_RADIUS, (radius or NODE_RADIUS) * 0.5)
    end
end

---@param graph MapGraph
local function renderNode(graph, node, r, g, b, a, radius)
    local nx, ny = graph:getDrawPos(node)
    renderNodeAt(node, nx, ny, r, g, b, a, radius)
end

---@param graph MapGraph
---@param pnode MapNode
local function getHoveredNode(graph, pnode, wx, wy)
    local best, bestDist = nil, math.huge
    local neighbors = graph:getNeighbors(pnode.x, pnode.y)
    for i = 1, #neighbors do
        local node = neighbors[i]
        local nx, ny = graph:getDrawPos(node)
        local dx, dy = nx - wx, ny - wy
        local d2 = dx * dx + dy * dy
        if d2 < bestDist then
            best = node
            bestDist = d2
        end
    end
    return best
end

function map_scene:enter()
    self.ecs = ECSWorld()
    self.camera = Camera(0, 0, CAMERA_ZOOM)
    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.pixelCanvas = PixelCanvas.new(love.graphics.getDimensions())
    self.hud = HUD()
    self.dragging = false
    self.commanderFacing = -1

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

    local nearPlayer = {}
    local pnode = graph:getPlayerNode()
    if pnode then
        local queue = {pnode}
        nearPlayer[pnode] = 0
        local head = 1
        while head <= #queue do
            local node = queue[head]
            local depth = nearPlayer[node]
            head = head + 1
            if depth < FOG_REVEAL_DEPTH then
                for _, nb in ipairs(graph:getNeighbors(node.x, node.y)) do
                    if not nearPlayer[nb] then
                        nearPlayer[nb] = depth + 1
                        queue[#queue + 1] = nb
                    end
                end
            end
        end
    end

    for _, entry in ipairs(self.nodeList) do
        if entry.node.visited or nearPlayer[entry.node] ~= nil then
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
    g.addBlessingHandlers()
end


---@param node MapNode
local function enterNode(node)
    if not node.visited then
        node.visited = true
        node:enter()
    end
end

function map_scene:update(dt)
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
    --self.camera:setZoom(CAMERA_ZOOM * ui.getUIScaling())
    self.camera:setPos(self.camX, self.camY)
    self.ecs:update(dt)
end


function map_scene:keypressed(k)
    if consts.DEV_MODE and k == "o" then
        g.gotoScene("shop_scene")
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
                local hovered = getHoveredNode(graph, pnode, wx, wy)
                if hovered and hovered ~= pnode then
                    local path = graph:findPath(pnode.x, pnode.y, hovered.x, hovered.y, PATH_SEARCH_DEPTH)
                    if path and #path >= 2 then
                        local ax, ay = graph:getDrawPos(path[1])
                        local bx, by = graph:getDrawPos(path[2])
                        local dist = math.sqrt((bx - ax)^2 + (by - ay)^2)
                        if bx < ax then self.commanderFacing = 1 end
                        if bx > ax then self.commanderFacing = -1 end
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
local function drawCommander(scene, graph, pnode)
    local cx, cy
    if scene.traveling then
        local trav = scene.traveling
        cx = trav.ax + (trav.bx - trav.ax) * trav.t
        cy = trav.ay + (trav.by - trav.ay) * trav.t
    else
        cx, cy = graph:getDrawPos(pnode)
    end
    local run = g.getRun()
    local cinfo = g.getCommanderInfo(run.commander)
    lg.setColor(1,1,1)
    g.drawImage(cinfo.image, cx,cy-8, 0, scene.commanderFacing, 1)
    -- love.graphics.setColor(1, 0.8, 0.2, 1)
    -- love.graphics.circle("fill", cx, cy, PLAYER_RADIUS)
end

local function hash(x,y)
    return math.abs(math.sin(x * 12.9898 + y * 78.233) * 43758.5453)
end

function map_scene:draw()
    local lg = love.graphics
    lg.clear(g.COLORS.GROUND_COLOR)

    self.pixelCanvas:start(self.camera:getTransform())
    iml.pushTransform(self.camera:getTransform())

    self.ecs:draw()

    local run = g.getRun()
    local graph = run.mapGraph
    if graph then
        -- drawGround (TODO)

        -- edges
        graph:forEachEdge(function(a, b)
            renderEdge(graph, a, b, g.COLORS.MAP_EDGE:getRGBA())
        end)

        -- decor + nodes (sorted by y)
        local i, j = 1, 1
        while true do
            local d = self.decorList and self.decorList[i]
            local n = self.nodeList and self.nodeList[j]
            if not d and not n then break end
            if d and (not n or d.y <= n.y) then
                local dtype = decor_types.get(d.decorType)
                if dtype and dtype.image then
                    love.graphics.setColor(1, 1, 1, 1)
                    local sx = (math.floor(hash(d.x,d.y))%2==0) and -1 or 1
                    -- 50% chance to draw flipped on scaleX
                    g.drawImage(dtype.image, d.x, d.y, 0, sx,1)
                end
                i = i + 1
            elseif n then
                n.node:drawBelow(n.x, n.y)
                renderNodeAt(n.node, n.x, n.y)
                j = j + 1
            end
        end

        -- hover highlight: path from player to hovered node
        local pnode = graph:getPlayerNode()
        if pnode then
            local mx, my = love.mouse.getPosition()
            local wx, wy = self.camera:toWorld(mx, my)
            local hovered = getHoveredNode(graph, pnode, wx, wy)
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
            end

            -- player / commander
            drawCommander(self, graph, pnode)
        end
    end

    -- fog
    local sw, sh = love.graphics.getDimensions()
    local x1, y1 = self.camera:toWorld(0, 0)
    local x2, y2 = self.camera:toWorld(sw, sh)
    local fogRegion = {
        x = math.min(x1, x2),
        y = math.min(y1, y2),
        w = math.abs(x2 - x1),
        h = math.abs(y2 - y1),
    }
    local step = 24
    local clearCells = self:_buildFogClearCells()
    fogService.renderFog(fogRegion, function(x, y)
        local cx = math.floor(x / step)
        local row = clearCells[cx]
        return not (row and row[math.floor(y / step)])
    end)

    lg.setColor(1, 1, 1, 1)
    iml.popTransform()
    self.pixelCanvas:finish()

    ui.startUI()
    self.hud:drawUI({ mapScene = true })
    ui.endUI()
end

return map_scene
