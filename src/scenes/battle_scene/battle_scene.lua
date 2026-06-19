local ECSWorld = require("src.ecs.ECSWorld")
local encounters = require("src.scenes.battle_scene.encounters")
local Camera = require("lib.cam11")
local ParticleService = require(".particles.ParticleService")
local fogService = require("src.fogService")
local juiceService = require("src.juiceService")
local ambienceService = require("src.ambienceService")


local CAMERA_ZOOM = 2

local INTRO_ZOOM_TEXT_FADE_TIME = 0.4
local INTRO_ZOOM_DURATION = 1.6

local WIN_DELAY = 1.8
local VICTORY_FADE_IN = 0.25

local WIN_SHOCKWAVE_DURATION = 1.2
local WIN_SHOCKWAVE_LINE_WIDTH = 98

---@class g.BattleScene
---@field hud g.HUD
local battle_scene = {}



local function loseBattle(self)
    if self.defeated then return end
    self.defeated = true
    g.call("battleLost")
    -- todo: do other stuff here, like popup, etc etc
    gameoverPopupService.show()
end

local function spawnTestNeutralObjectives(self)
    local border = self.ecs.boundingBox
    local cx = border[1] + border[3] * 0.6
    local cy = border[2] + border[4] * 0.5
    local offsets = {
        {0, 0},
        {100, -70},
        {100, 70},
    }
    for _, off in ipairs(offsets) do
        g.spawnEntity("treasure_chest_objective", cx + off[1], cy + off[2])
    end
end


function battle_scene:init()
    self.victory = false
    self.defeated = false
    self.victoryPopupTime = 0
    self.shockwave = nil
    self.lastEnemyCount = 0
    self.allyDeathsThisBattle = 0
    ---@type ecs.Entity?
    self.commander = nil

    self.sandbox = false -- dev-mode sandbox
    self.devZoomOut = false
    self.devZoomOutApplied = false
    self.sandbox_squadPicker = false
    self.sandbox_squadLevelUpper = false
    self.sandbox_blessingScreen = false

    self.editingSquadLineup = false
end



function battle_scene:pollHandlers()
    self.ecs:addSystemHandlers()
    g.addBlessingAndEntityHandlers()

    local rageMul = 1 + (g.getRun().demonRage or 0) * 0.1
    g.addHandler({
        getAttackDamageMultiplier = function(ent)
            if ent and ent.team == "enemy" then
                return rageMul
            end
            return 1
        end,
        getMaxHealthMultiplier = function(ent)
            if ent and ent.team == "enemy" then
                return rageMul
            end
            return 1
        end,
    })

    g.addHandler({
        getSquadStatBuffModifier = function ()
            return math.floor(g.getWorldTime())
        end,
        postDraw = function()
            lg.setColor(1,1,1)
            self.particles:draw()
        end,
        entityDeath = function(ent)
            if ent == self.commander then
                loseBattle(self)
            end
            if ent.team == "ally" then
                self.ecs.allyDeathsThisBattle = self.ecs.allyDeathsThisBattle + 1
            end
            if ent.team == "enemy" then
                self.ecs.enemyDeathsThisBattle = self.ecs.enemyDeathsThisBattle + 1
                if self.lastEnemyCount == 1 then
                    self.shockwave = { time = 0, x = ent.x, y = ent.y }
                end
            end
        end
    })
end

function battle_scene:enter()
    -- /rb sets devZoomOut after gotoScene, so always reset here
    self.devZoomOut = false
    self.devZoomOutApplied = false
    local run = g.getRun()
    run:resetForBattle()
    juiceService.reset()

    self.editingSquadLineup = true

    self.randomI = love.math.random(1,1000) -- random integer, doesnt really matter

    ---@type ecs.ECSWorld
    self.ecs = ECSWorld({
        "stats", "status_effects", "ai", "attacking",
        "physics", "shadows", "ground_decor", "juice_system", "blood_system"
    })
    g.setCurrentECS(self.ecs)

    self.camera = Camera(0, 0, CAMERA_ZOOM)
    self.particles = ParticleService()
    self.hud = HUD()
    self.noEnemyTimer = 0
    self.victory = false
    self.defeated = false
    self.allyDeathsThisBattle = 0
    self.victoryPopupTime = 0
    self.shockwave = nil
    self.lastEnemyCount = 0
    self.squadChoices = nil
    self.timeSinceEnteredScene = 0
    self.commander = nil

    g.pollHandlers()

    if self.sandbox then
        self.ecs:setBounds(1900, 1100)
    else
        encounters.startRandomEncounter(run.day, self.ecs)
    end
    spawnTestNeutralObjectives(self)

    local border = self.ecs.boundingBox
    do
        local borderR = Kirigami(
            border[1],
            border[2],
            border[3],
            border[4]
        )
        local leftR,_,_ = borderR:splitHorizontal(1,2)
        local nx, ny = leftR:getCenter()
        local commanderInfo = g.getCommanderInfo(run.commander)
        local commanderSquad = g.getSquadFromArmy(commanderInfo.squadId)
        if commanderSquad then
            self.commander = commanderSquad:spawn(nx, ny)[1]
            self.commander.playerControlled = true
        end
    end

    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.camera:setPos(border[3] * 0.45, border[4] * 0.5)

    ambienceService.reInitialize(self.camera:getTransform())
end



function battle_scene:leave()
    if g.hasRun() then
        for _, squad in pairs(g.getRun().squads) do
            squad.deployed = false
        end
    end
    self.commander = nil
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


---@param secondCount integer
function battle_scene:perSecondUpdate(secondCount)
    g.setCurrentECS(self.ecs)
    g.call("perSecondUpdate", secondCount)
end

function battle_scene:update(dt)
    self.timeSinceEnteredScene = self.timeSinceEnteredScene + dt

    local run = g.getRun()
    for _, squad in pairs(run.squads) do
        local info = g.getSquadInfo(squad.squadId)
        squad.canAfford = not info.cost or g.canAffordMana(run._battleMana, info.cost)
    end

    self:updateCommanderInput()
    self:updateCamera(dt)
    juiceService.update(dt)
    ambienceService.update(dt, self.camera:getTransform())
    local timeScale = juiceService.consumeHitPause(dt)
    self.ecs:update(dt * timeScale)

    local enemyCount = countEnemies(self.ecs)
    self.lastEnemyCount = enemyCount

    if self.defeated then
        return
    end

    if not self.paused then
        self.particles:update(dt)
        -- track how long no enemies have existed
        if enemyCount == 0 then
            self.noEnemyTimer = self.noEnemyTimer + dt
        else
            self.noEnemyTimer = 0
        end
        if self.noEnemyTimer >= WIN_DELAY and (not self.victory) and (not self.sandbox) then
            self.victory = true
            -- choicePopupService.set("blessing")
            rewardPopupService.battleReward({
                gold = 100,
                randomSquad = true,

                randomBlessing = true,
                randomMana = true
                -- todo: remove this, blessings are obtained via other means
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

    if self.shockwave then
        self.shockwave.time = self.shockwave.time + dt
        if self.shockwave.time >= WIN_SHOCKWAVE_DURATION then
            self.shockwave = nil
        end
    end
end

local DEFAULT_COMMANDER_SPEED = 60


function battle_scene:updateCommanderInput()
    local ent = self.commander
    if not (ent and g.isAlive(ent)) then return end

    local mx, my = 0, 0
    -- TODO: Allow this to be configurable
    if love.keyboard.isScancodeDown("w") then my = my - 1 end
    if love.keyboard.isScancodeDown("a") then mx = mx - 1 end
    if love.keyboard.isScancodeDown("s") then my = my + 1 end
    if love.keyboard.isScancodeDown("d") then mx = mx + 1 end

    local moving = mx ~= 0 or my ~= 0
    ent._isMoving = moving
    if not moving then
        ent.vx, ent.vy = 0, 0
        return
    end

    -- Normalize
    local len = math.sqrt(mx * mx + my * my)
    if len > 0 then
        local speed = ent.moveSpeed or DEFAULT_COMMANDER_SPEED
        mx = mx * speed / len
        my = my * speed / len
    end

    ent.vx = mx
    ent.vy = my
    if mx < 0 then ent.faceDir = -1 end
    if mx > 0 then ent.faceDir = 1 end
end


function battle_scene:updateCamera(dt)
    local cam = self.camera
    cam:setViewport(0, 0, love.graphics.getDimensions())

    -- dev: free camera. Frame the whole battlefield once, then let the
    -- user pan/zoom freely (no intro zoom, no commander follow).
    if consts.DEV_MODE and self.devZoomOut then
        if not self.devZoomOutApplied then
            self.devZoomOutApplied = true
            local border = self.ecs.boundingBox
            local sw, sh = love.graphics.getDimensions()
            cam:setZoom(math.min(sw / border[3], sh / border[4]) * 0.8)
            cam:setPos(border[3] * 0.5, border[4] * 0.5)
        end
        return
    end

    if self.timeSinceEnteredScene < INTRO_ZOOM_DURATION then
        local border = self.ecs.boundingBox
        local sw, sh = love.graphics.getDimensions()
        local fitZoom = math.min(sw / border[3], sh / border[4])
        local t = self.timeSinceEnteredScene / INTRO_ZOOM_DURATION
        t = t * t * (3 - 2 * t)
        cam:setZoom(fitZoom + (CAMERA_ZOOM - fitZoom) * t)
    else
        cam:setZoom(CAMERA_ZOOM)
    end

    local ent = self.commander
    if ent and g.isAlive(ent) then
        cam:setPos(ent.x, ent.y)
    end
end

function battle_scene:mousemoved(x, y, dx, dy)
    if love.mouse.isDown(3) then
        local cx, cy = self.camera:getPos()
        local z = self.camera:getZoom()
        self.camera:setPos(cx - dx / z, cy - dy / z)
    end
end

function battle_scene:wheelmoved(dx, dy)
    if consts.DEV_MODE and self.devZoomOut then
        local z = self.camera:getZoom()
        self.camera:setZoom(math.max(0.1, z * (1 + dy * 0.1)))
        return
    end
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
    local n = tonumber(k)
    if n and n >= 1 and n <= 9 then
        self.hud:selectVisibleSlot(n)
    end

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
                rewardPopupService.battleReward({
                    gold = 123,
                    xp = 45,
                    randomBlessing = true,
                    randomSquad = true,
                    randomMana = true,
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


local CANT_AFFORD = interp("{c r=1 g=0.2 b=0.2}{o}Can't afford! (Need {c r=1 b=1 g=1}{%{manaType}}{/c})", {
    context = "Popup shown when player tries to deploy a squad but doesn't have enough mana. %{manaType} is a richtext icon for the mana type (e.g. red, blue, green, yellow)."
})

---@param cost g.ManaBundle
---@param counts g.ManaCounts
---@return g.ManaType?
local function findMissingMana(cost, counts)
    for _, mt in ipairs(g.getManaTypelist()) do
        if (cost[mt] or 0) > (counts[mt] or 0) then
            return mt
        end
    end
    return g.getManaTypelist()[1]
end


local dbg = function(r)
    if consts.DEV_MODE then lg.rectangle("line", r:get()) end
end
---@param self g.BattleScene
local function drawSandboxUI(self)
    local r = ui.getFullScreenRegion()
    local main, right = r:splitHorizontal(5,1)
    local regs = right:grid(1,9)
    local c = objects.Color
    local ii = 1
    local function button(txt, col)
        ii = ii + 1
        return ui.Button(txt, col, c.BLACK, regs[ii])
    end

    if button("Add Squad(s)", c.BLUE) then
        self.sandbox_squadPicker = true
    end
    if button("Level Up squad(s)", c.BLUE) then
        self.sandbox_squadLevelUpper = true
    end
    if button("Blessings", c.YELLOW) then
        self.sandbox_blessingScreen = true
    end
    if button("Spawn enemies", c.RED) then
        local b = self.ecs.boundingBox
        local cx, cy = b[1] + b[3] * 0.75 + math.random(-20,20), b[2] + b[4] * 0.5 + math.random(-20,20)
        for i = 1, 8 do
            local ox = love.math.random(-40, 40)
            local oy = love.math.random(-60, 60)
            g.spawnEntity("demon", cx + ox, cy + oy)
        end
        for i = 1, 4 do
            local ox = love.math.random(-30, 30)
            local oy = love.math.random(-60, 60)
            g.spawnEntity("archerdemon", cx + 40 + ox, cy + oy)
        end
    end
    if button("Clear/Reset", c.WHITE) then
        for _, ent in self.ecs:iterate("team") do
            self.ecs:removeEntity(ent)
        end
        for _, squad in ipairs(g.getSortedArmyList()) do
            squad.deployed = false
        end
        local run = g.getRun()
        run._battleMana = {}
        for mana, count in pairs(run.mana) do
            if count > 0 then
                run._battleMana[mana] = count
            end
        end
    end
    if button("Exit Sandbox", c.GRAY) then
        self.sandbox = false
        g.gotoScene("map_scene")
    end
    if button("RESTART!!", c.GREEN) then
        love.event.quit("restart")
    end

    if self.sandbox_squadPicker then
        local panel = r:padRatio(0.1)
        ui.drawDarkPanel(panel:get())
        local top, body = panel:padUnit(8):splitHorizontal(1, 10)
        if ui.Button("Close", c.GRAY, c.DARK_GRAY, top) then
            self.sandbox_squadPicker = false
        end
        local ids = g.getSquadList()
        local cols = 8
        local rows = math.ceil(#ids / cols)
        local cells = body:grid(cols, rows)
        for i, id in ipairs(ids) do
            local has = g.getSquadFromArmy(id)
            local info = g.getSquadInfo(id)
            local cell = cells[i]
            local cx, cy, cw, ch = cell:get()
            local idd = "sb_pick_"..id
            if iml.isHovered( cx, cy, cw, ch , idd) then
                lg.setColor(0.4,0.4,0.4)
                lg.rectangle("fill", cell:get())
            end
            lg.setColor(1,1,1)
            g.drawSquadIcon(id, cx + cw/2, cy + ch/2, true)
            richtext.printRich("{o}"..string.format("%.1f", info.powerIndex or 0), lg.getFont(), cx + cw * 0.62, cy + ch * 0.5, 100, "left")
            if iml.wasJustClicked(cx, cy, cw, ch, 1, idd) then
                if not g.getSquadFromArmy(id) then
                    g.addSquadToArmy(id)
                end
            end
            if has then
                lg.setColor(0,0,0,0.7)
                lg.rectangle("fill", cell:get())
            end
        end
    elseif self.sandbox_squadLevelUpper then
        local panel = r:padRatio(0.1)
        ui.drawDarkPanel(panel:get())
        local top, body = panel:padUnit(8):splitHorizontal(1, 10)
        if ui.Button("Close", c.GRAY, c.DARK_GRAY, top) then
            self.sandbox_squadLevelUpper = false
        end
        local army = g.getSortedArmyList()
        local cols = 8
        local rows = math.max(1, math.ceil(#army / cols))
        local cells = body:grid(cols, rows)
        for i, sq in ipairs(army) do
            local info = g.getSquadInfo(sq.squadId)
            local cell = cells[i]
            local cx, cy, cw, ch = cell:get()
            local idd = "sb_lvl_"..i
            if iml.isHovered(cx, cy, cw, ch, idd) then
                lg.setColor(0.4,0.4,0.4)
                lg.rectangle("fill", cell:get())
            end
            lg.setColor(1,1,1)
            g.drawSquadIcon(sq.squadId, cx + cw/2, cy + ch/2, true, sq.level)
            richtext.printRich("{o}"..string.format("%.1f", info.powerIndex or 0), lg.getFont(), cx + cw * 0.62, cy + ch * 0.5, 100, "left")
            if iml.wasJustClicked(cx, cy, cw, ch, 1, idd) then
                sq.level = sq.level + 1
            end
        end
    elseif self.sandbox_blessingScreen then
        local panel = r:padRatio(0.06)
        ui.drawDarkPanel(panel:get())
        local top, body = panel:padUnit(8):splitHorizontal(1, 12)
        if ui.Button("Close", c.GRAY, c.DARK_GRAY, top) then
            self.sandbox_blessingScreen = false
        end

        local ids = {}
        for _, id in ipairs(g.getBlessingList()) do
            ids[#ids + 1] = id
        end

        local rarityOrder = {
            COMMON = 1,
            UNCOMMON = 2,
            RARE = 3,
            LEGENDARY = 4,
            UNIQUE = 5,
        }
        table.sort(ids, function(a, b)
            local ar = (g.getBlessingInfo(a).rarity or g.RARITIES.COMMON).id
            local br = (g.getBlessingInfo(b).rarity or g.RARITIES.COMMON).id
            local av = rarityOrder[ar] or 999
            local bv = rarityOrder[br] or 999
            if av == bv then
                return a < b
            end
            return av < bv
        end)

        local gridReg, previewReg = body:splitHorizontal(4, 1)
        local cols = 10
        local rows = math.max(1, math.ceil(#ids / cols))
        local cells = gridReg:grid(cols, rows)
        local hoveredBlessing = nil
        for i, id in ipairs(ids) do
            local cell = cells[i]
            local cx, cy, cw, ch = cell:get()
            local uid = "sb_bless_" .. id
            if iml.isHovered(cx, cy, cw, ch, uid) then
                hoveredBlessing = id
                lg.setColor(1, 1, 1, 0.12)
                lg.rectangle("fill", cx, cy, cw, ch)
            end
            if iml.wasJustClicked(cx, cy, cw, ch, 1, uid) then
                g.addBlessing(id)
            end
            lg.setColor(1, 1, 1)
            g.drawBlessingIcon(id, cx + cw / 2, cy + ch / 2)
        end

        if hoveredBlessing then
            ui.drawBlessingCard(hoveredBlessing, previewReg:padUnit(6), 999)
        end
    end
end



local DEPLOY_RADIUS = 100

---@param self g.BattleScene
local function getCommanderDeployBasePos(self)
    if not self.commander then
        return 0, 0
    end

    local commoy = 0
    if self.commander.image then
        local _, h = g.getImageSize(self.commander.image)
        commoy = h/2
    end

    return self.commander.x, self.commander.y - commoy
end

---@param self g.BattleScene
---@param squad g.Squad
---@param wx number
---@param wy number
---@return number, number
local function getSnappedDeployPosition(self, squad, wx, wy)
    local commander = self.commander
    if (not commander) or (not g.isAlive(commander)) or g.ask("canDeployAnywhere", squad) or g.squadCanDeployAnywhere(squad) then
        return wx, wy
    end

    local commx, commy = getCommanderDeployBasePos(self)
    local dx, dy = wx - commx, wy - commy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist <= DEPLOY_RADIUS then
        return wx, wy
    end
    if dist <= 0 then
        return commx, commy
    end
    return commx + dx / dist * DEPLOY_RADIUS,
        commy + dy / dist * DEPLOY_RADIUS
end

local SQUAD_HOVER_COLOR = g.snapToPalette(0.2, 1, 0.3, 0.5)
local SQUAD_HOVER_COLOR_1 = g.snapToPalette(0.05,0.2,0.07, 0.25)
local SQUAD_HOVER_COLOR_2 = g.snapToPalette(0.1,0.7,0.3, 0.6)

---@param self g.BattleScene
---@param squad g.Squad
---@param wx number world x coord
---@param wy number world y coord
local function drawSquadHover(self, squad, wx, wy)
    local info = g.getSquadInfo(squad.squadId)
    local einfo = g.getEntityDef(info.entityId)
    local offsets = squad:getFormationOffsets()
    local sx, sy = getSnappedDeployPosition(self, squad, wx, wy)
    lg.setColor(SQUAD_HOVER_COLOR)

    local w,h = 10,10
    if einfo.image then
        w,h = g.getImageSize(einfo.image)
    end

    local minX, minY, maxX, maxY = math.huge,math.huge,0,0
    for i = 1, #offsets do
        local ox, oy = offsets[i].x, offsets[i].y
        g.drawUnitPreview(info.entityId, sx + ox, sy + oy)
        minX = math.min(minX, ox)
        minY = math.min(minY, oy)
        maxX = math.max(maxX, ox)
        maxY = math.max(maxY, oy)
    end
    if info.drawSquadHover then
        info.drawSquadHover(sx, sy)
    end

    do
    local ww, hh = maxX-minX, maxY-minY
    lg.setLineWidth(2)
    lg.setColor(SQUAD_HOVER_COLOR_1)
    lg.rectangle("fill", sx+minX-w/2, sy+minY-h/2, ww+w, hh+h)
    lg.setColor(SQUAD_HOVER_COLOR_2)
    lg.rectangle("line", sx+minX-w/2, sy+minY-h/2, ww+w, hh+h)
    end
    local smallFont = g.getSmallFont(16)
    lg.setColor(info.rarity.color)
    local yof2 = -24
    richtext.printRichCentered("{bob}{o}"..info.name, smallFont, sx, sy+minY+yof2, 1000, "left")
end



---@param cost g.ManaBundle
local function spawnManaIconPopups(cost)
    local umx, umy = ui.getMouse()
    for id,v in pairs(cost) do
        local minfo = g.getManaInfo(id)
        for i=1, v do
            local RR = 10
            local xx, yy = umx + love.math.random(-RR,RR), umy + love.math.random(-RR,RR) - 20
            g.addUITextPopup(xx, yy, "{" .. minfo.image .. "}", {
                duration = 0.9,
            })
        end
    end
end




local DEPLOY_REGION_INNER = g.snapToPalette(0.15, 0.8, 0.2, 0.05)
local DEPLOY_REGION_LINE = g.snapToPalette(0.2, 1, 0.3, 0.4)
local AUTO_ATTACK_RADIUS_SHOW = 2
local AUTO_ATTACK_RADIUS_FADE_END = 2.5
local AUTO_ATTACK_RADIUS_ALPHA = 0.09
local LINE_WIDTH = 3
local COMMANDER_TARGET_SPIN_SPEED = 4

local function drawCommanderTarget(self)
    local commander = self.commander
    if (not commander) or (not g.isAlive(commander)) then
        return
    end

    local target = commander._aiTarget
    if not (target and g.isAlive(target)) then
        return
    end

    local d2 = (target.x - commander.x) ^ 2 + (target.y - commander.y) ^ 2
    local inRange = d2 <= (commander.attackRange or 100) ^ 2
    local IMG="commander_target_3"
    if inRange then
        lg.setColor(1,1,1)
        g.drawImageOffset(IMG, target.x, target.y - 20, love.timer.getTime() * COMMANDER_TARGET_SPIN_SPEED, 1, 1, 0.5, 0.5)
    else
        local dist = helper.magnitude(target.x-commander.x, target.y-commander.y)
        local fade = helper.clamp((commander.attackRange*2) / dist, 0,1)
        lg.setColor(1, 1, 1, fade)
        g.drawImageOffset(IMG, target.x, target.y - 20, 0, 1, 1, 0.5, 0.5)
    end
end


local function drawCommanderRadius(self)
    local commander = self.commander
    if (not commander) or (not g.isAlive(commander)) then
        return
    end

    local pop = gsman.setLineWidth(LINE_WIDTH)
    local squad = self.hud:getSelection()
    if squad and (not squad.deployed) then
        local commx, commy = getCommanderDeployBasePos(self)
        local mx, my = love.mouse.getPosition()
        local wx, wy = self.camera:toWorld(mx, my)
        local snappedX, snappedY = getSnappedDeployPosition(self, squad, wx, wy)
        local snapped = (snappedX ~= wx) or (snappedY ~= wy)
        local opacityMult = snapped and 1 or 0.5
        local ir, ig, ib, ia = DEPLOY_REGION_INNER:getRGBA()
        local lr, lgc, lb, la = DEPLOY_REGION_LINE:getRGBA()

        lg.setColor(ir, ig, ib, ia * opacityMult)
        love.graphics.circle("fill", commx, commy, DEPLOY_RADIUS)
        lg.setColor(lr, lgc, lb, la * opacityMult)
        love.graphics.circle("line", commx, commy, DEPLOY_RADIUS)
    end

    local timeSinceAutoAttack = commander._timeSinceAutoAttacked
    if (not commander.attackRange) or (not timeSinceAutoAttack) or timeSinceAutoAttack >= AUTO_ATTACK_RADIUS_FADE_END then
        return
    end

    local alpha = AUTO_ATTACK_RADIUS_ALPHA
    if timeSinceAutoAttack > AUTO_ATTACK_RADIUS_SHOW then
        local t = (timeSinceAutoAttack - AUTO_ATTACK_RADIUS_SHOW) / (AUTO_ATTACK_RADIUS_FADE_END - AUTO_ATTACK_RADIUS_SHOW)
        alpha = alpha * (1 - t)
    end

    lg.setColor(1, 1, 1, alpha)
    love.graphics.circle("line", commander.x, commander.y, commander.attackRange)
    pop:pop()
end


function battle_scene:draw()
    local _cx, _cy = self.camera:getPos()
    local _sx, _sy = juiceService.getShakeOffset()
    if _sx ~= 0 or _sy ~= 0 then
        self.camera:setPos(_cx + _sx, _cy + _sy)
    end
    self.camera:attach()
    love.graphics.clear(g.COLORS.BATTLE_GROUND_COLOR:getRGBA())
    iml.pushTransform(self.camera:getTransform())

    lg.setColor(1, 1, 1, 1)

    drawCommanderRadius(self)

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
    local ecs = self.ecs
    fogService.renderFog(fogRegion, function(x, y)
        return not ecs:isInsideShape(x, y)
    end)

    if not self.victory then
        local squad = self.hud:getSelection()
        local mx, my = love.mouse.getPosition()
        local wx, wy = self.camera:toWorld(mx, my)
        if squad and not squad.deployed then
            drawSquadHover(self, squad, wx, wy)
            lg.setColor(1, 1, 1, 1)
        end
    end

    drawCommanderTarget(self)

    iml.popTransform()
    self.camera:detach()

    ambienceService.draw(self.camera:getTransform())

    ui.startUI()

    if (not self.victory) and (not self.defeated) and iml.wasJustPressed(0, 0, sw, sh, 1, "deploy_click") then
        local entry = self.hud:getSelection()
        local mx, my = love.mouse.getPosition()
        local wx, wy = self.camera:toWorld(mx, my)
        local sx, sy = wx, wy
        if entry then
            sx, sy = getSnappedDeployPosition(self, entry, wx, wy)
        end
        if entry and not entry.deployed then
            local info = g.getSquadInfo(entry.squadId)
            if not info.cost or g.trySpendMana(g.getBattleManaCounts(), info.cost) then
                entry:spawn(sx, sy)
                spawnManaIconPopups(info.cost)
            else
                local manaType = findMissingMana(info.cost, g.getBattleManaCounts())
                local umx, umy = ui.getMouse()
                g.addUITextPopup(umx, umy, CANT_AFFORD({manaType = manaType}), {
                    fadeIn = 0.15,
                    duration = 1.5,
                })
            end
        end
    end
    self.hud:drawUI({ battleScene = true })

    if self.victory and (not g.isAnyPopupOpen()) then
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
        richtext.printRichContainedNoWrap("{o}{c r=0.7 g=0.1 b=0.2}"..txt, font, rr:padRatio(0.85):get())
    end

    if self.sandbox and consts.SHOW_DEV_STUFF then
        drawSandboxUI(self)
    end
    ui.endUI()

    if self.shockwave and self.shockwave.time < WIN_SHOCKWAVE_DURATION then
        local sx, sy = self.camera:toScreen(self.shockwave.x, self.shockwave.y)
        local p = self.shockwave.time / WIN_SHOCKWAVE_DURATION
        local maxR = math.sqrt(sw * sw + sh * sh) * 1.2
        lg.setColor(0.03, 0.03, 0.03, 0.9 * (1 - p))
        lg.setLineWidth(WIN_SHOCKWAVE_LINE_WIDTH / 1200 * maxR)
        lg.circle("line", sx, sy, maxR * p)
        lg.setLineWidth(1)
        lg.setColor(1, 1, 1, 1)
    end

    if _sx ~= 0 or _sy ~= 0 then
        self.camera:setPos(_cx, _cy)
    end
end

return battle_scene
