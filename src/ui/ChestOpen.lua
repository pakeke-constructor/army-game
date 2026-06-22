local particles = require("src.modules.particles.particles")
local godrays = require("src.modules.godrays.godrays")

local lg = love.graphics

local REEL_SIZE = 50
local REEL_DURATION = 8.0
local RAY_COLOR = objects.Color("#FFEFC52C")
local NUM_PARTICLES = 30


local function getReelIndex(elapsed, reelSize)
    local t = math.min(elapsed / REEL_DURATION, 1)
    local curve = 1 - (1 - t)^3
    return math.floor(1 + curve * (reelSize - 1) + 0.5)
end


local function buildReel(resultBlessingId)
    local all = g.getBlessingList()
    local reel = {}
    for i = 1, REEL_SIZE - 1 do
        reel[i] = all[love.math.random(#all)]
    end
    reel[REEL_SIZE] = resultBlessingId
    return reel
end


local function drawGodrays(rx, ry, scale, color)
    local t2 = love.timer.getTime() / 2
    godrays.drawRays(rx, ry, t2/2.5, {rayCount=3, divisions=100, color=color, startWidth=8*scale, length=600*scale, fadeTo=0, growRate=0.6})
    godrays.drawRays(rx, ry, -t2/1.5, {rayCount=5, divisions=100, color=color, startWidth=9*scale, length=150*scale, fadeTo=0, growRate=1.6})
    godrays.drawRays(rx, ry, t2, {rayCount=6, divisions=100, color=color, startWidth=10*scale, length=200*scale, fadeTo=0, growRate=2.6})
    godrays.drawRays(rx, ry, -t2, {rayCount=5, divisions=100, color=color, startWidth=10*scale, length=300*scale, fadeTo=0, growRate=2.6})
end


local function newChestParticles()
    return particles.newParticlesWorld({
        gravity = 80,
        drawParticle = function(p)
            local t = love.timer.getTime()
            local sx = math.sin(t*10 + p.id*1.77)*2
            g.drawImage("coin_icon", p.x, p.y, 0, sx, 2)
        end,
        getParticleDuration = function(p)
            return 1.5 + (p.id % 4) * 0.3
        end
    })
end



---@class g.ChestOpen: objects.Class
---@field blessingId string
---@field reel string[]
---@field spinStart number
---@field done boolean
local ChestOpen = objects.Class("g:ChestOpen")

---@param blessingId string the reward the reel lands on
function ChestOpen:init(blessingId)
    self.blessingId = blessingId
    self.reel = buildReel(blessingId)
    self.spinStart = love.timer.getTime()
    self.done = false
    -- self.particles = newChestParticles()
    self.lastReelIndex = 0
    self.settledTime = nil
    g.playUISound("ui_click_basic", 1.5, 0.5)
end

function ChestOpen:isDone()
    return self.done
end

function ChestOpen:update(dt)
    -- self.particles:update(dt)
end


local NEW_ITEM = "{rainbow}{wavy}{o thickness=3}" .. loc("YOU GOT A NEW BLESSING!", {
    context = "A popup that tells the player they got a new blessing from a chest"
})
local CLICK_TO_CLOSE = "{wavy}{o}{c r=0.5 g=0.7 b=1}" .. loc("Click anywhere to close", {
    context = "Prompt to dismiss the chest opening popup"
})


function ChestOpen:draw()
    if self.done then return end
    -- self.particles:update(love.timer.getDelta())

    local r = ui.getFullScreenRegion()
    local rx, ry = r:getCenter()
    local t = love.timer.getTime()

    lg.setColor(0, 0, 0, 0.8)
    lg.rectangle("fill", r:get())

    local elapsed = t - self.spinStart
    local reelIndex = getReelIndex(elapsed, #self.reel)
    local settled = reelIndex >= #self.reel

    -- tick / finalize sounds
    if reelIndex ~= self.lastReelIndex then
        self.lastReelIndex = reelIndex
        if settled then
            g.playUISound("ui_click_basic", 1.5, 0.7)
            self.settledTime = t
        else
            g.playUISound("ui_tick", 0.8 + reelIndex/#self.reel * 0.4, 0.4)
        end
    end

    -- converging ring
    if reelIndex < #self.reel then
        local ratio = (#self.reel - reelIndex) / #self.reel
        local sze = (r.w / 4) + ratio*r.w
        lg.setColor(1, 0.84, 0.2, ratio * 0.5)
        local lw = lg.getLineWidth()
        lg.setLineWidth(r.h / 20)
        lg.circle("line", rx, ry, sze/1.5)
        lg.setLineWidth(lw)
    end

    -- expanding shockwave
    do
        local lw = lg.getLineWidth()
        lg.setColor(1, 0.84, 0.2)
        lg.setLineWidth(r.h / 10)
        lg.circle("line", rx, ry, 20 + elapsed * 550)
        lg.setLineWidth(lw)
    end

    -- on settle, lerp the icon/godrays from center to 2/5 of the screen width over 1s
    local SETTLE_LERP = 1.0
    local settleK = settled and math.min((t - self.settledTime) / SETTLE_LERP, 1) or 0
    local ease = 1 - (1 - settleK)^3
    local cx = rx + ((r.x + r.w * 0.4) - rx) * ease

    local currentInfo = g.getBlessingInfo(self.reel[reelIndex])
    -- local rarCol = settled and RAY_COLOR or (currentInfo.rarity or g.RARITIES.COMMON).color
    local rarCol = objects.Color.CRIMSON
    local progress = elapsed / REEL_DURATION
    drawGodrays(cx, ry, math.min(progress + 0.3, 1.3), rarCol)

    lg.setColor(1, 1, 1)
    -- self.particles:draw()
    -- if self.particles:getParticleCount() < NUM_PARTICLES then
    --     local a = love.math.random() * math.pi * 2
    --     local mag = 150 + love.math.random() * 80
    --     self.particles:spawnParticle(rx, ry, math.cos(a)*mag, math.sin(a)*mag)
    -- end

    local ICON = 80
    if settled then
        -- golden finalize shockwave
        local st = t - self.settledTime
        local lw = lg.getLineWidth()
        lg.setColor(1, 0.84, 0.2)
        lg.setLineWidth(30 + st * 60)
        lg.circle("line", cx, ry, 20 + st * 400)
        lg.setLineWidth(lw)

        if iml.wasJustClicked(r:get()) then
            self.done = true
            return
        end

        local info = g.getBlessingInfo(self.blessingId)
        lg.setColor(1, 1, 1)
        g.drawImageContained(info.image, cx - ICON/2, ry - ICON/2, ICON, ICON)
        helper.printTextOutline(info.name, g.getSmallFont(32), 2, cx, ry + 60, r.w, "center", 0, 1, 1, r.w / 2)

        -- once shifted, pop the description in beside the icon
        if settleK >= 1 then
            local popT = math.min((st - SETTLE_LERP) / 0.25, 1)
            local slide = (1 - popT) * 20
            local descX = cx + ICON/2 + 24
            richtext.printRichContained("{o}{c r=0.85 g=0.85 b=0.9}" .. info.description, g.getSmallFont(16), descX, ry - 50 + slide, r.w/3, 120)
            richtext.printRichContained(CLICK_TO_CLOSE, g.getSmallFont(32), rx - r.w/2, ry + 100, r.w, 40)
        end
        richtext.printRichContained(NEW_ITEM, g.getSmallFont(48), rx - r.w/2, ry - 160, r.w, 60)
    else
        lg.setColor(1, 1, 1)
        g.drawImageContained(currentInfo.image, cx - ICON/2, ry - ICON/2, ICON, ICON)
        helper.printTextOutline(currentInfo.name, g.getSmallFont(32), 2, cx, ry + 60, r.w, "center", 0, 1, 1, r.w / 2)
    end
end


return ChestOpen
