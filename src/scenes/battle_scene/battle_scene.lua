local ECSWorld = require("src.ecs.ECSWorld")

local battle_scene = {}

function battle_scene:init()
end

function battle_scene:enter()
    self.ecs = ECSWorld()
end

function battle_scene:leave()
    self.ecs = nil
end

function battle_scene:update(dt)
    self.ecs:update(dt)
end

function battle_scene:draw()
    local lg = love.graphics
    lg.clear(0.08, 0.06, 0.06, 1)
    self.ecs:draw()
end

return battle_scene
