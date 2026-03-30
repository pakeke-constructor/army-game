local ECSWorld = require("src.ecs.ECSWorld")
local Camera = require("lib.cam11")
local ParticleService = require(".particles.ParticleService")

local CAMERA_SPEED = 400
local CAMERA_ZOOM = 2
local WIN_DELAY = 1.5
local VICTORY_FADE_IN = 0.25

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



local function spawnTestEnemies()
    for x=400, 500, 30 do
        for y=100, 160, 20 do
            g.spawnEntity("demon", x, y)
        end
        for y=180, 200, 20 do
            g.spawnEntity("imp", x, y)
        end
    end


    for x=100, 200, 30 do
        for y=100, 160, 20 do
            g.spawnEntity("militia", x, y)
        end
        for y=180, 200, 20 do
            g.spawnEntity("archer", x, y)
        end
    end
end

function battle_scene:enter()
    self.ecs = ECSWorld({"stats", "ai", "attacking", "physics"})
    local run = g.getRun()
    for _, squad in ipairs(run.squads) do
        squad.deployed = false
    end
    self.camera = Camera(0, 0, CAMERA_ZOOM)
    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.particles = ParticleService()
    self.noEnemyTimer = 0
    self.victoryPopup = false
    self.victoryPopupTime = 0

    spawnTestEnemies()
    -- TODO: remove / replace this with actual proper enemies from pool
end

function battle_scene:leave()
    self.ecs = nil
    self.camera = nil
    self.particles = nil
end

function battle_scene:pollHandlers()
    self.ecs:addSystemHandlers()
end

local function countEnemies(ecs)
    local count = 0
    for _, ent in ecs:iterate("team") do
        if ent.team == "enemy" and g.isAlive(ent) then
            count = count + 1
        end
    end
    return count
end

function battle_scene:update(dt)
    self:updateCamera(dt)
    if not self.victoryPopup and not self.paused then
        self.ecs:update(dt)
        self.particles:update(dt)
        -- track how long no enemies have existed
        if countEnemies(self.ecs) == 0 then
            self.noEnemyTimer = self.noEnemyTimer + dt
        else
            self.noEnemyTimer = 0
        end
        if self.noEnemyTimer >= WIN_DELAY then
            self.victoryPopup = true
            self.victoryPopupTime = 0
        end
    else
        self.victoryPopupTime = self.victoryPopupTime + dt
    end
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
    if consts.DEV_MODE then
        if k == "q" then
            test()
        end
        if k == "m" then
            g.gotoScene("map_scene")
        end
        if k == "p" then
            self.paused = not self.paused
        end
    end
end

local VICTORY_COL1 = objects.Color(0.12, 0.08, 0.20)
local VICTORY_COL2 = objects.Color(0.06, 0.04, 0.14)
local BTN_COL1 = objects.Color(0.15, 0.55, 0.25)
local BTN_COL2 = objects.Color(0.08, 0.30, 0.15)

local function victoryPopup(self)
    local r = ui.getScreenRegion()
    iml.panel(r:get())

    local progress = math.min(1, self.victoryPopupTime / VICTORY_FADE_IN)

    -- darken background
    love.graphics.setColor(0, 0, 0, 0.6 * progress)
    love.graphics.rectangle("fill", r:get())

    -- popup area
    local popup = r:padRatio(0.15 + (1 - progress) * 0.1)
    local panelArea, buttonArea = popup:splitVertical(3, 1)

    -- panel background
    love.graphics.setColor(1, 1, 1)
    helper.gradientRect("horizontal", VICTORY_COL1, VICTORY_COL2, panelArea:get())
    ui.drawSingleColorPanel(panelArea:get())

    -- title text
    love.graphics.setColor(1, 1, 1)
    local font = g.getSmallFont(16)
    love.graphics.setFont(font)
    local tx, ty, tw, th = panelArea:padRatio(0.3):get()
    love.graphics.printf("Victory!", tx, ty + th / 2 - font:getHeight() / 2, tw, "center")

    -- OK button
    buttonArea = buttonArea:padRatio(0.3, 0.2)
    if ui.Button("{o}OK{/o}", BTN_COL1, BTN_COL2, buttonArea) then
        g.gotoScene("map_scene")
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
    if self.victoryPopup then
        victoryPopup(self)
    end
    ui.endUI()
end

return battle_scene
