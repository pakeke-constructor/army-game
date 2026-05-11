local ECSWorld = require("src.ecs.ECSWorld")
local encounters = require("src.scenes.battle_scene.encounters")
local Camera = require("lib.cam11")
local ParticleService = require(".particles.ParticleService")
local fogService = require("src.fogService")


local CAMERA_SPEED = 400
local CAMERA_ZOOM = 2

local INTRO_ZOOM_TEXT_FADE_TIME = 0.4
local INTRO_ZOOM_DURATION = 1.6

local WIN_DELAY = 2.5
local VICTORY_FADE_IN = 0.25

---@class g.BattleScene
local battle_scene = {}



function battle_scene:init()
    self.victory = false
    self.victoryPopupTime = 0
    self.sandbox = false -- dev-mode sandbox

    self.editingSquadLineup = false
end



function battle_scene:pollHandlers()
    self.ecs:addSystemHandlers()
    g.addBlessingHandlers()
    g.addHandler({ postDraw = function()
        lg.setColor(1,1,1)
        self.particles:draw()
    end})
end


function battle_scene:enter()
    local run = g.getRun()
    run:resetForBattle()

    self.editingSquadLineup = true

    self.randomI = love.math.random(1,1000) -- random integer, doesnt really matter

    self.ecs = ECSWorld({"stats", "status_effects", "ai", "attacking", "physics"})
    self.camera = Camera(0, 0, CAMERA_ZOOM)
    self.particles = ParticleService()
    self.hud = HUD()
    self.noEnemyTimer = 0
    self.victory = false
    self.victoryPopupTime = 0
    self.squadChoices = nil
    self.timeSinceEnteredScene = 0

    local run = g.getRun()
    if self.sandbox then
        self.ecs:setBorder(500, 300)
    else
        encounters.startRandomEncounter(run.day, self.ecs)
    end
    local border = self.ecs.border
    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.camera:setPos(border[3] * 0.45, border[4] * 0.5)
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


function battle_scene:perSecondUpdate()
    g.call("perSecondUpdate", self.ecs)
end

function battle_scene:update(dt)
    self.timeSinceEnteredScene = self.timeSinceEnteredScene + dt

    local run = g.getRun()
    for _, squad in ipairs(run.squads) do
        local info = g.getSquadInfo(squad.squadId)
        squad.canAfford = not info.cost or g.canAffordMana(run._battleMana, info.cost)
    end

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
        if self.noEnemyTimer >= WIN_DELAY and (not self.victory) and (not self.sandbox) then
            self.victory = true
            -- choicePopupService.set("blessing")
            rewardPopupService.set({
                gold = 100,
                randomSquad = true

            })
            self.victoryPopupTime = 0
            run:winBattle()
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

    if self.timeSinceEnteredScene < INTRO_ZOOM_DURATION then
        local border = self.ecs.border
        local sw, sh = love.graphics.getDimensions()
        local fitZoom = math.min(sw / border[3], sh / border[4])
        local t = self.timeSinceEnteredScene / INTRO_ZOOM_DURATION
        t = t * t * (3 - 2 * t)
        cam:setZoom(fitZoom + (CAMERA_ZOOM - fitZoom) * t)
    else
        cam:setZoom(CAMERA_ZOOM)
    end

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
    local run = g.getRun()
    run:winBattle()
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
        if k == "r" then
            if rewardPopupService.getActive() then
                rewardPopupService.clear()
            else
                rewardPopupService.set({
                    gold = 123,
                    xp = 45,
                    randomBlessing = true,
                    randomSquad = true,
                })
            end
        end
    end
end


local _BATTLE_START_CTX = "An exciting bit of title-text that shows up before a battle. Meant to indicate a battle is starting and it's exciting"
local BATTLE_START = {
    loc("Start Battle!",{}, {context=_BATTLE_START_CTX}),
    loc("En Garde!",{}, {context=_BATTLE_START_CTX}),
    loc("Fight!",{}, {context=_BATTLE_START_CTX}),
    loc("Battle Begins!",{}, {context=_BATTLE_START_CTX}),
}


local dbg = function(r)
    if consts.DEV_MODE then lg.rectangle("line", r:get()) end
end

---@param self g.BattleScene
local function drawSandboxUI(self)
    local r = ui.getFullScreenRegion()
    local main, right = r:splitVertical(5,1)
    dbg(right)
end


function battle_scene:draw()
    self.camera:attach()
    love.graphics.clear(0.15, 0.15, 0.15)
    iml.pushTransform(self.camera:getTransform())

    local border = self.ecs.border
    love.graphics.rectangle("line", border[1], border[2], border[3], border[4])

    self.ecs:draw(self.camera:getTransform())

    local sw, sh = love.graphics.getDimensions()
    local x1, y1 = self.camera:toWorld(0, 0)
    local x2, y2 = self.camera:toWorld(sw, sh)
    local fogRegion = {
        x = math.min(x1, x2),
        y = math.min(y1, y2),
        w = math.abs(x2 - x1),
        h = math.abs(y2 - y1),
    }
    fogService.renderFog(fogRegion, function(x, y)
        return x < border[1] or x > border[1] + border[3] or y < border[2] or y > border[2] + border[4]
    end)

    if not self.victory then
        local entry = self.hud:getSelection()
        local mx, my = love.mouse.getPosition()
        local wx, wy = self.camera:toWorld(mx, my)
        if entry and not entry.deployed then
            local info = g.getSquadInfo(entry.squadId)
            local offsets = entry:getFormationOffsets()
            lg.setColor(0.2, 1, 0.3, 0.5)
            for i = 1, #offsets do
                local ox, oy = offsets[i].x, offsets[i].y
                g.drawUnit(info.entityId, wx + ox, wy + oy)
            end
            lg.setColor(1, 1, 1, 1)
        end
    end

    iml.popTransform()
    self.camera:detach()

    ui.startUI()

    local sw, sh = love.graphics.getDimensions()
    if not self.victory and iml.wasJustClicked(0, 0, sw, sh, 1, "deploy_click") then
        local entry = self.hud:getSelection()
        local mx, my = love.mouse.getPosition()
        local wx, wy = self.camera:toWorld(mx, my)
        if entry and not entry.deployed then
            local info = g.getSquadInfo(entry.squadId)
            if not info.cost or g.trySpendMana(g.getBattleManaCounts(), info.cost) then
                entry:spawn(wx, wy)
            end
        end
    end
    self.hud:drawUI({ battleScene = true })

    local anyPopupOpen = choicePopupService.getActive() or rewardPopupService.getActive()
    if self.victory and (not anyPopupOpen) then
        g.gotoScene("map_scene")
    end

    if self.timeSinceEnteredScene < INTRO_ZOOM_DURATION then
        local rr = ui.getScreenRegion()
        local font = g.getBigFont(16)
        local shrink = 1-math.min(1, self.timeSinceEnteredScene / 0.25)
        rr = rr:padRatio(shrink)
        local fade = 1-((self.timeSinceEnteredScene - (INTRO_ZOOM_DURATION - INTRO_ZOOM_TEXT_FADE_TIME)) / INTRO_ZOOM_TEXT_FADE_TIME)
        lg.setColor(1,1,1, fade)
        local txt = BATTLE_START[self.randomI % #BATTLE_START + 1]
        richtext.printRichContainedNoWrap("{o}{c r=0.7 g=0.1 b=0.2}"..txt, font, rr:padRatio(0.75):get())
    end
    ui.endUI()
end

return battle_scene
