local ECSWorld = require("src.ecs.ECSWorld")
local Camera = require("lib.cam11")
local ParticleService = require(".particles.ParticleService")

local CAMERA_SPEED = 400
local CAMERA_ZOOM = 2

local battle_scene = {}

function battle_scene:init()
end


local function test()
    -- spawn test allies
    for x=100, 200, 30 do
        for y=100, 160, 20 do
            g.spawnEntity("militia", x, y)
        end
        for y=180, 200, 20 do
            g.spawnEntity("archer", x, y)
        end
    end
    -- spawn test enemies
    for x=400, 500, 30 do
        for y=100, 160, 20 do
            g.spawnEntity("demon", x, y)
        end
        for y=180, 200, 20 do
            g.spawnEntity("imp", x, y)
        end
    end
end


function battle_scene:enter()
    self.ecs = ECSWorld({"stats", "ai", "attacking", "physics"})
    self.camera = Camera(0, 0, CAMERA_ZOOM)
    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.particles = ParticleService()
end

function battle_scene:leave()
    self.ecs = nil
    self.camera = nil
    self.particles = nil
end

function battle_scene:pollHandlers()
    self.ecs:addSystemHandlers()
end

function battle_scene:update(dt)
    self:updateCamera(dt)
    self.ecs:update(dt)
    self.particles:update(dt)
end

function battle_scene:updateCamera(dt)
    local cam = self.camera
    cam:setViewport(0, 0, love.graphics.getDimensions())

    local spd = CAMERA_SPEED / math.sqrt(cam:getZoom())
    local mx, my = 0, 0
    if love.keyboard.isScancodeDown("w") then my = my - spd * dt end
    if love.keyboard.isScancodeDown("a") then mx = mx - spd * dt end
    if love.keyboard.isScancodeDown("s") then my = my + spd * dt end
    if love.keyboard.isScancodeDown("d") then mx = mx + spd * dt end
    local x, y = cam:getPos()
    cam:setPos(x + mx, y + my)
end

function battle_scene:mousemoved(x, y, dx, dy)
    if love.mouse.isDown(3) then
        local cx, cy = self.camera:getPos()
        local z = self.camera:getZoom()
        self.camera:setPos(cx - dx / z, cy - dy / z)
    end
end

function battle_scene:keypressed(k)
    if consts.DEV_MODE and k == "q" then
        test()
    end
end

function battle_scene:draw()
    local lg = love.graphics
    lg.clear(0.08, 0.06, 0.06, 1)

    self.camera:attach(false)
    iml.pushTransform(self.camera:getTransform())
    self.ecs:draw()
    self.particles:draw()
    iml.popTransform()
    self.camera:detach()

    ui.startUI()
    -- HERE.
    ui.endUI()
end

return battle_scene
