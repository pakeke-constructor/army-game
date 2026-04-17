local ECSWorld = require("src.ecs.ECSWorld")
local encounters = require("src.scenes.battle_scene.encounters")
local Camera = require("lib.cam11")
local ParticleService = require(".particles.ParticleService")
local HUD = require("src.hud.hud")

local CAMERA_SPEED = 400
local CAMERA_ZOOM = 2
local WIN_DELAY = 2.5
local VICTORY_FADE_IN = 0.25

---@class g.BattleScene
local battle_scene = {}

function battle_scene:init()
end




function battle_scene:pollHandlers()
    self.ecs:addSystemHandlers()
    g.addBlessingHandlers()
end

function battle_scene:enter()
    self.ecs = ECSWorld({"stats", "ai", "attacking", "physics"})
    self.ecs:setBorder(600, 350)
    local border = self.ecs.border
    local run = g.getRun()
    run:resetForBattle()
    self.camera = Camera(0, 0, CAMERA_ZOOM)
    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.camera:setPos(border[3] * 0.45, border[4] * 0.5)
    self.particles = ParticleService()
    self.hud = HUD()
    self.noEnemyTimer = 0
    self.victoryPopup = false
    self.victoryPopupTime = 0
    self.squadChoices = nil

    local run = g.getRun()
    encounters.startRandomEncounter(run.day, self.ecs)
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

local function buildVictoryChoices()
    -- copy squad list
    -- shuffle list
    -- take first 3
    local list = {}
    for _, id in ipairs(g.getSquadList()) do
        list[#list + 1] = id
    end
    helper.shuffle(list)
    local choices = {}
    local count = math.min(3, #list)
    for i = 1, count do
        choices[i] = list[i]
    end
    return choices
end


function battle_scene:update(dt)
    self:updateCamera(dt)
    self.ecs:update(dt)
    if not self.paused then
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
            if not self.squadChoices then
                self.squadChoices = buildVictoryChoices()
            end
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

function battle_scene:wheelmoved(dx, dy)
    self.hud:wheelmoved(dx, dy)
end


local function killAllEnemies(self)
    for _, ent in self.ecs:iterate("team") do
        if ent.team == "enemy" and g.isAlive(ent) then
            g.killEntity(ent)
        end
    end
    self.noEnemyTimer = WIN_DELAY
    self.victoryPopup = true
    self.victoryPopupTime = 0
    if not self.squadChoices then
        self.squadChoices = buildVictoryChoices()
    end
end

function battle_scene:keypressed(k)
    if consts.DEV_MODE then
        if k == "k" then
            killAllEnemies(self)
        end
        if k == "m" then
            g.gotoScene("map_scene")
        end
        if k == "p" then
            self.paused = not self.paused
        end
    end
end

---@param self g.BattleScene
local function drawCardSelect(self)
    local r = ui.getFullScreenRegion()
    local cardArea = r:padRatio(0.05, 0.1)
    local c1, c2, c3 = cardArea:splitHorizontal(1, 1, 1)
    local choices = self.squadChoices or {}
    local regions = {c1:padRatio(0.1), c2:padRatio(0.1), c3:padRatio(0.1)}
    for i = 1, #regions do
        local id = choices[i]
        if id then
            if ui.drawSquadCard(id, regions[i]) then
                g.addSquadToArmy(g.newSquad(id))
                g.gotoScene("map_scene")
            end
        end
    end
end



function battle_scene:draw()
    self.camera:attach()
    love.graphics.clear(0.15, 0.15, 0.15)
    iml.pushTransform(self.camera:getTransform())

    local border = self.ecs.border
    love.graphics.rectangle("line", border[1], border[2], border[3], border[4])

    self.ecs:draw()
    self.particles:draw()

    if not self.victoryPopup then
        local typ, entry = self.hud:getSelection()
        local mx, my = love.mouse.getPosition()
        local wx, wy = self.camera:toWorld(mx, my)
        if typ == "squad" and not entry.deployed then
            local info = g.getSquadInfo(entry.squadId)
            local offsets = entry:getFormationOffsets()
            lg.setColor(0.2, 1, 0.3, 0.5)
            for i = 1, #offsets do
                local ox, oy = offsets[i].x, offsets[i].y
                g.drawUnit(info.entityId, wx + ox, wy + oy)
            end
            lg.setColor(1, 1, 1, 1)
        elseif typ == "spell" then
            local info = g.getSpellInfo(entry)
            if info.drawSpellHover then
                info.drawSpellHover(wx, wy)
            end
        end
    end

    iml.popTransform()
    self.camera:detach()

    ui.startUI()

    local sw, sh = love.graphics.getDimensions()
    if not self.victoryPopup and iml.wasJustClicked(0, 0, sw, sh, 1, "deploy_click") then
        local typ, entry = self.hud:getSelection()
        local mx, my = love.mouse.getPosition()
        local wx, wy = self.camera:toWorld(mx, my)
        if typ == "squad" and not entry.deployed then
            entry:spawn(wx, wy)
        elseif typ == "spell" then
            g.tryCastSpell(entry, wx, wy)
        end
    end
    self.hud:drawUI({ battleScene = true })

    if self.victoryPopup then
        drawCardSelect(self)
    end

    ui.endUI()
end

return battle_scene
