local ECSWorld = require("src.ecs.ECSWorld")
local Camera = require("lib.cam11")
local MapGraph = require("src.scenes.map_scene.MapGraph")
local PixelCanvas = require("src.modules.PixelCanvas")
local decor_types = require("src.scenes.map_scene.decor_types")

local CAMERA_ZOOM = 0.5
local NODE_RADIUS = 4
local PLAYER_RADIUS = 5
local PAN_SPEED = 200
local HOVER_DIST_FRAC = 0.4 -- fraction of distanceBetweenNodes
local COMMANDER_SPEED = 80 -- world pixels per second

local PATH_SEARCH_DEPTH = 3


local map_scene = {}

function map_scene:init()
end

local function getNodeWorldPos(graph, node)
    local sp = graph.distanceBetweenNodes
    return (node.x * sp + node.ox) * graph.scaleX, (node.y * sp + node.oy) * graph.scaleY
end

local function renderEdge(graph, a, b, r, g_c, b_c, a_c, width)
    local lg = love.graphics
    local ax, ay = getNodeWorldPos(graph, a)
    local bx, by = getNodeWorldPos(graph, b)
    lg.setColor(r, g_c, b_c, a_c or 1)
    lg.setLineWidth(width or 6)
    lg.line(ax, ay, bx, by)
end

local function renderNode(graph, node, r, g_c, b_c, a_c, radius)
    local lg = love.graphics
    local nx, ny = getNodeWorldPos(graph, node)
    if r then
        lg.setColor(r, g_c, b_c, a_c or 1)
        lg.circle("fill", nx, ny, radius or NODE_RADIUS)
    else
        node:draw(nx, ny)
    end
end

local function getHoveredNode(graph, wx, wy)
    local hoverDist = graph.distanceBetweenNodes * HOVER_DIST_FRAC
    local best, bestDist = nil, hoverDist * hoverDist
    graph:forEachNode(function(node)
        local nx, ny = getNodeWorldPos(graph, node)
        local dx, dy = nx - wx, ny - wy
        local d2 = dx * dx + dy * dy
        if d2 < bestDist then
            best = node
            bestDist = d2
        end
    end)
    return best
end

function map_scene:enter()
    self.ecs = ECSWorld()
    self.camera = Camera(0, 0, CAMERA_ZOOM)
    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.pixelCanvas = PixelCanvas.new(love.graphics.getDimensions())
    self.dragging = false

    local run = g.getRun()
    if not run.mapGraph then
        run.mapGraph = MapGraph.generate({
            width = 50,
            height = 30,
            nodePruneChance = 0.2,
            edgePruneChance = 0.02,
            distanceBetweenNodes = 120,
            randomDiagonalChance = 0.4,
            nodeOffsetFactor = 0.35,
            scaleX = 1,
            scaleY = 0.6,
            decorTypes = {"mountain_large", "tree_large_1", "tree_small_1"},
        })
    end

    -- Build sorted decor list for drawing
    self.decorList = {}
    run.mapGraph:forEachDecor(function(d)
        self.decorList[#self.decorList + 1] = d
    end)
    table.sort(self.decorList, function(a, b) return a.y < b.y end)

    local pnode = run.mapGraph:getPlayerNode()
    if pnode then
        self.camX, self.camY = getNodeWorldPos(run.mapGraph, pnode)
    else
        self.camX, self.camY = 0, 0
    end
end

function map_scene:leave()
    self.ecs = nil
    self.camera = nil
    self.decorList = nil
end

function map_scene:pollHandlers()
    self.ecs:addSystemHandlers()
    g.addBlessingHandlers()
end

local function enterNode(node)
    node:enter()
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
    self.camera:setZoom(CAMERA_ZOOM * ui.getUIScaling())
    self.camera:setPos(self.camX, self.camY)
    self.ecs:update(dt)
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
                        local ax, ay = getNodeWorldPos(graph, path[1])
                        local bx, by = getNodeWorldPos(graph, path[2])
                        local dist = math.sqrt((bx - ax)^2 + (by - ay)^2)
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

local function drawCommander(scene, graph, pnode)
    local cx, cy
    if scene.traveling then
        local trav = scene.traveling
        cx = trav.ax + (trav.bx - trav.ax) * trav.t
        cy = trav.ay + (trav.by - trav.ay) * trav.t
    else
        cx, cy = getNodeWorldPos(graph, pnode)
    end
    love.graphics.setColor(1, 0.8, 0.2, 1)
    love.graphics.circle("fill", cx, cy, PLAYER_RADIUS)
end

function map_scene:draw()
    local lg = love.graphics
    lg.clear(0.08, 0.06, 0.06, 1)

    self.pixelCanvas:start(self.camera:getTransform())
    iml.pushTransform(self.camera:getTransform())

    self.ecs:draw()

    local run = g.getRun()
    local graph = run.mapGraph
    if graph then
        -- decor (behind everything)
        if self.decorList then
            for _, d in ipairs(self.decorList) do
                local dtype = decor_types.get(d.decorType)
                if dtype and dtype.image then
                    love.graphics.setColor(1, 1, 1, 1)
                    g.drawImage(dtype.image, d.x, d.y)
                end
            end
        end

        -- drawBelow (under edges)
        graph:forEachNode(function(node)
            local nx, ny = getNodeWorldPos(graph, node)
            node:drawBelow(nx, ny)
        end)

        -- edges
        graph:forEachEdge(function(a, b)
            renderEdge(graph, a, b, 0.16, 0.28, 0.18)
        end)

        -- nodes
        graph:forEachNode(function(node)
            renderNode(graph, node)
        end)

        -- hover highlight: path from player to hovered node
        local pnode = graph:getPlayerNode()
        if pnode then
            local mx, my = love.mouse.getPosition()
            local wx, wy = self.camera:toWorld(mx, my)
            local hovered = getHoveredNode(graph, wx, wy)
            if hovered and hovered ~= pnode then
                local path = graph:findPath(pnode.x, pnode.y, hovered.x, hovered.y, PATH_SEARCH_DEPTH)
                if path and #path >= 2 then
                    -- first edge bold yellow, rest pale yellow
                    renderEdge(graph, path[1], path[2], 1, 1, 0.2, 1, 6)
                    renderNode(graph, path[2], 1, 1, 0.2, 1, NODE_RADIUS + 1)
                    for i = 2, #path - 1 do
                        renderEdge(graph, path[i], path[i + 1], 1, 1, 0.2, 1, 6)
                        renderNode(graph, path[i + 1], 1, 1, 0.2, 1, NODE_RADIUS + 1)
                    end
                end
            end

            -- player / commander
            drawCommander(self, graph, pnode)
        end
    end

    lg.setColor(1, 1, 1, 1)
    iml.popTransform()
    self.pixelCanvas:finish()

    ui.startUI()
    ui.endUI()
end

return map_scene

