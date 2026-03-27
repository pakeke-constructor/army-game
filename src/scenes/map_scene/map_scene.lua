local ECSWorld = require("src.ecs.ECSWorld")
local Camera = require("lib.cam11")
local MapGraph = require("src.scenes.map_scene.MapGraph")

local CAMERA_ZOOM = 2
local NODE_SPACING = 64
local NODE_RADIUS = 8
local PLAYER_RADIUS = 5
local PAN_SPEED = 200

local map_scene = {}

function map_scene:init()
end

local function getNodeWorldPos(node)
    return node.x * NODE_SPACING + node.ox, node.y * NODE_SPACING + node.oy
end

function map_scene:enter()
    self.ecs = ECSWorld()
    self.camera = Camera(0, 0, CAMERA_ZOOM)
    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.dragging = false

    local run = g.getRun()
    if not run.mapGraph then
        run.mapGraph = MapGraph.generate(7, 8)
        for x = 0, run.mapGraph.width - 1 do
            if run.mapGraph:hasNode(x, 0) then
                run.mapGraph:setPlayerPosition(x, 0)
                break
            end
        end
    end

    local pnode = run.mapGraph:getPlayerNode()
    if pnode then
        self.camX, self.camY = getNodeWorldPos(pnode)
    else
        self.camX, self.camY = 0, 0
    end
end

function map_scene:leave()
    self.ecs = nil
    self.camera = nil
end

function map_scene:pollHandlers()
    self.ecs:addSystemHandlers()
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

    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.camera:setPos(self.camX, self.camY)
    self.ecs:update(dt)
end

function map_scene:mousepressed(mx, my, button)
    if button == 1 then
        self.dragging = true
        self.dragLastX, self.dragLastY = mx, my
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

function map_scene:draw()
    local lg = love.graphics
    lg.clear(0.08, 0.06, 0.06, 1)

    self.camera:attach(false)
    iml.pushTransform(self.camera:getTransform())

    self.ecs:draw()

    local run = g.getRun()
    local graph = run.mapGraph
    if graph then
        -- draw edges
        lg.setColor(0.4, 0.4, 0.4, 1)
        lg.setLineWidth(2)
        graph:forEachEdge(function(a, b)
            local ax, ay = getNodeWorldPos(a)
            local bx, by = getNodeWorldPos(b)
            lg.line(ax, ay, bx, by)
        end)

        -- draw nodes
        graph:forEachNode(function(node)
            local nx, ny = getNodeWorldPos(node)
            lg.setColor(0.6, 0.6, 0.6, 1)
            lg.circle("fill", nx, ny, NODE_RADIUS)
            lg.setColor(0.9, 0.9, 0.9, 1)
            lg.circle("line", nx, ny, NODE_RADIUS)
        end)

        -- draw player
        local pnode = graph:getPlayerNode()
        if pnode then
            local px, py = getNodeWorldPos(pnode)
            lg.setColor(1, 0.8, 0.2, 1)
            lg.circle("fill", px, py, PLAYER_RADIUS)
        end
    end

    lg.setColor(1, 1, 1, 1)
    iml.popTransform()
    self.camera:detach()

    ui.startUI()
    ui.endUI()
end

return map_scene
