local ECSWorld = require("src.ecs.ECSWorld")
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


local function test()
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
end

function battle_scene:pollHandlers()
    self.ecs:addSystemHandlers()
    g.addBlessingHandlers()
end

function battle_scene:enter()
    self.ecs = ECSWorld({"stats", "ai", "attacking", "physics"})
    local b = consts.BATTLE_BORDER
    self.ecs:setBorder(b * 2, b * 2)
    local run = g.getRun()
    for _, squad in ipairs(run.squads) do
        squad.deployed = false
    end
    self.camera = Camera(0, 0, CAMERA_ZOOM)
    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.particles = ParticleService()
    self.hud = HUD()
    self.noEnemyTimer = 0
    self.victoryPopup = false
    self.victoryPopupTime = 0
    self.squadChoices = nil

    spawnTestEnemies()
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
            g.call("entityDeath", ent, nil)
            ent:getWorld():removeEntity(ent)
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
        if k == "q" then
            test()
        end
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

local VICTORY_COL1 = objects.Color(0.12, 0.08, 0.20)
local VICTORY_COL2 = objects.Color(0.06, 0.04, 0.14)

local function victoryPopup(self)
    local r = ui.getScreenRegion()
    iml.panel(r:get())

    local progress = math.min(1, self.victoryPopupTime / VICTORY_FADE_IN)

    -- darken background
    love.graphics.setColor(0, 0, 0, 0.6 * progress)
    love.graphics.rectangle("fill", r:get())

    -- popup area
    local popup = r:padRatio(0.15 + (1 - progress) * 0.1)
    local panelArea = popup

    -- panel background
    love.graphics.setColor(1, 1, 1)
    helper.gradientRect("horizontal", VICTORY_COL1, VICTORY_COL2, panelArea:get())
    ui.drawSingleColorPanel(panelArea:get())

    -- title text
    love.graphics.setColor(1, 1, 1)
    local font = g.getSmallFont(16)
    love.graphics.setFont(font)
    local titleArea, cardsArea = panelArea:splitVertical(0.2, 0.8)
    local tx, ty, tw, th = titleArea:padRatio(0.3):get()
    love.graphics.printf("Victory!", tx, ty + th / 2 - font:getHeight() / 2, tw, "center")

    local cardArea = cardsArea:padRatio(0.05, 0.1)
    local c1, c2, c3 = cardArea:splitHorizontal(1, 1, 1)
    local choices = self.squadChoices or {}
    local regions = {c1, c2, c3}
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



---@param self g.BattleScene
local function drawCardSelect(self)
    do return victoryPopup(self) end
    local lg = love.graphics
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

    self.ecs:draw()
    self.particles:draw()

    if not self.victoryPopup then
        local sq = self.hud:getSelectedSquad()
        if sq and not sq.deployed then
            local mx, my = love.mouse.getPosition()
            local wx, wy = self.camera:toWorld(mx, my)
            local info = g.getSquadInfo(sq.squadId)
            local offsets = sq:getFormationOffsets()
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

    if self.victoryPopup then
        drawCardSelect(self)
    end

    local sw, sh = love.graphics.getDimensions()
    if not self.victoryPopup and iml.wasJustClicked(0, 0, sw, sh, 1, "deploy_click") then
        local sq = self.hud:getSelectedSquad()
        if sq and not sq.deployed then
            local mx, my = love.mouse.getPosition()
            local wx, wy = self.camera:toWorld(mx, my)
            sq:spawn(wx, wy)
        end
    end
    self.hud:drawUI({ battleScene = true })
    if self.victoryPopup then
        --victoryPopup(self)
    end
    ui.endUI()
end

return battle_scene
