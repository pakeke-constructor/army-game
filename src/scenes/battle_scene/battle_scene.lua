local ECSWorld = require("src.ecs.ECSWorld")
local encounters = require("src.scenes.battle_scene.encounters")
local Camera = require("lib.cam11")
local ParticleService = require(".particles.ParticleService")
local fogService = require("src.fogService")


local CAMERA_SPEED = 400
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



function battle_scene:init()
    self.victory = false
    self.victoryPopupTime = 0
    self.shockwave = nil
    self.lastEnemyCount = 0

    self.sandbox = false -- dev-mode sandbox
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
        postDraw = function()
            lg.setColor(1,1,1)
            self.particles:draw()
        end,
        entityDeath = function(ent)
            if ent.team ~= "enemy" then return end
            if self.lastEnemyCount ~= 1 then return end
            self.shockwave = { time = 0, x = ent.x, y = ent.y }
        end
    })
end


function battle_scene:enter()
    local run = g.getRun()
    run:resetForBattle()

    self.editingSquadLineup = true

    self.randomI = love.math.random(1,1000) -- random integer, doesnt really matter

    self.ecs = ECSWorld({
        "stats", "status_effects", "ai", "attacking",
        "physics", "shadows", "ground_decor", "juice_system"
    })
    self.camera = Camera(0, 0, CAMERA_ZOOM)
    self.particles = ParticleService()
    self.hud = HUD()
    self.noEnemyTimer = 0
    self.victory = false
    self.victoryPopupTime = 0
    self.shockwave = nil
    self.lastEnemyCount = 0
    self.squadChoices = nil
    self.timeSinceEnteredScene = 0

    local run = g.getRun()
    if self.sandbox then
        self.ecs:setBorder(500, 300)
    else
        g.setCurrentECS(self.ecs)
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

    self:updateCamera(dt)
    self.ecs:update(dt)

    local enemyCount = countEnemies(self.ecs)
    self.lastEnemyCount = enemyCount

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
        local b = self.ecs.border
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
            local cell = cells[i]
            local cx, cy, cw, ch = cell:get()
            local idd = "sb_pick_"..id
            if iml.isHovered( cx, cy, cw, ch , idd) then
                lg.setColor(0.4,0.4,0.4)
                lg.rectangle("fill", cell:get())
            end
            lg.setColor(1,1,1)
            g.drawSquadIcon(id, cx + cw/2, cy + ch/2, true)
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
            local cell = cells[i]
            local cx, cy, cw, ch = cell:get()
            local idd = "sb_lvl_"..i
            if iml.isHovered(cx, cy, cw, ch, idd) then
                lg.setColor(0.4,0.4,0.4)
                lg.rectangle("fill", cell:get())
            end
            lg.setColor(1,1,1)
            g.drawSquadIcon(sq.squadId, cx + cw/2, cy + ch/2, true, sq.level)
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
            lg.setColor(1, 1, 1)
            g.drawBlessingIcon(id, cx + cw / 2, cy + ch / 2)
        end

        if hoveredBlessing then
            ui.drawBlessingCard(hoveredBlessing, previewReg:padUnit(6), 999)
        end
    end
end



local function getSnappedDeployPosition(squad, wx, wy, region)
    if true then return wx,wy end
    if (not region) or g.ask("canDeployAnywhere", squad) then
        return wx, wy
    end

    local sx = math.max(region.x, math.min(region.x + region.w, wx))
    local sy = math.max(region.y, math.min(region.y + region.h, wy))
    return sx, sy
end

---@param squad g.Squad
---@param wx number world x coord
---@param wy number world y coord
local function drawSquadHover(squad, wx, wy)
    local info = g.getSquadInfo(squad.squadId)
    local einfo = g.getEntityDef(info.entityId)
    local offsets = squad:getFormationOffsets()
    local deployRegion = g.getSquadDeployRegion()
    local sx, sy = getSnappedDeployPosition(squad, wx, wy, deployRegion)
    lg.setColor(0.2, 1, 0.3, 0.5)

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
    lg.setColor(0.05,0.2,0.07, 0.25)
    lg.rectangle("fill", sx+minX-w/2, sy+minY-h/2, ww+w, hh+h)
    lg.setColor(0.1,0.7,0.3, 0.6)
    lg.rectangle("line", sx+minX-w/2, sy+minY-h/2, ww+w, hh+h)
    end
    local smallFont = g.getSmallFont(16)
    lg.setColor(info.rarity.color)
    local yof2 = -24
    richtext.printRichCentered("{wavy}{o}"..info.name, smallFont, sx, sy+minY+yof2, 1000, "left")
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




function battle_scene:draw()
    self.camera:attach()
    love.graphics.clear(g.COLORS.BATTLE_GROUND_COLOR:getRGBA())
    iml.pushTransform(self.camera:getTransform())

    local border = self.ecs.border
    lg.setColor(1, 1, 1, 1)
    love.graphics.rectangle("line", border[1], border[2], border[3], border[4])

    local deployRegion = g.getSquadDeployRegion()
    if deployRegion then
        lg.setColor(g.snapToPalette(0.15, 0.8, 0.2, 0.05))
        love.graphics.rectangle("fill", deployRegion.x, deployRegion.y, deployRegion.w, deployRegion.h)
        lg.setColor(g.snapToPalette(0.2, 1, 0.3, 0.4))
        love.graphics.rectangle("line", deployRegion.x, deployRegion.y, deployRegion.w, deployRegion.h)
    end

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
        local squad = self.hud:getSelection()
        local mx, my = love.mouse.getPosition()
        local wx, wy = self.camera:toWorld(mx, my)
        if squad and not squad.deployed then
            drawSquadHover(squad, wx, wy)
            lg.setColor(1, 1, 1, 1)
        end
    end

    iml.popTransform()
    self.camera:detach()

    ui.startUI()

    local sw, sh = love.graphics.getDimensions()
    if not self.victory and iml.wasJustPressed(0, 0, sw, sh, 1, "deploy_click") then
        local entry = self.hud:getSelection()
        local mx, my = love.mouse.getPosition()
        local wx, wy = self.camera:toWorld(mx, my)
        local deployRegion = g.getSquadDeployRegion()
        local sx, sy = wx, wy
        if entry then
            sx, sy = getSnappedDeployPosition(entry, wx, wy, deployRegion)
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

    if self.sandbox then
        drawSandboxUI(self)
    end
    ui.endUI()

    if self.shockwave and self.shockwave.time < WIN_SHOCKWAVE_DURATION then
        local sw, sh = love.graphics.getDimensions()
        local sx, sy = self.camera:toScreen(self.shockwave.x, self.shockwave.y)
        local p = self.shockwave.time / WIN_SHOCKWAVE_DURATION
        local maxR = math.sqrt(sw * sw + sh * sh) * 1.2
        lg.setColor(0.03, 0.03, 0.03, 0.9 * (1 - p))
        lg.setLineWidth(WIN_SHOCKWAVE_LINE_WIDTH / 1200 * maxR)
        lg.circle("line", sx, sy, maxR * p)
        lg.setLineWidth(1)
        lg.setColor(1, 1, 1, 1)
    end
end

return battle_scene
