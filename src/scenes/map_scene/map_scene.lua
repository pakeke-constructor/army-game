local ECSWorld = require("src.ecs.ECSWorld")
local Camera = require("lib.cam11")

local CAMERA_ZOOM = 2

local map_scene = {}

function map_scene:init()
end

function map_scene:enter()
    self.ecs = ECSWorld()
    self.camera = Camera(0, 0, CAMERA_ZOOM)
    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.x = 0
    self.y = 0
end

function map_scene:leave()
    self.ecs = nil
    self.camera = nil
end

function map_scene:update(dt)
    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.camera:setPos(self.x, self.y)
    self.ecs:update(dt)
end

function map_scene:draw()
    local lg = love.graphics
    lg.clear(0.08, 0.06, 0.06, 1)

    self.camera:attach(false)
    iml.pushTransform(self.camera:getTransform())
    self.ecs:draw()
    iml.popTransform()
    self.camera:detach()

    ui.startUI()
    -- HERE.
    ui.endUI()
end

return map_scene
