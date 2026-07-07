-- World-space drifting "wisps" / smoke debris for ambience.
local PixelCanvas = require("src.modules.PixelCanvas")

local ambienceService = {}


local WISP_COUNT = 28
local WISP_MIN_SPEED = 3
local WISP_MAX_SPEED = 20
local WISP_WANDER = 40 -- how strongly direction drifts (accel per second)
local WISP_SPEED_LIMIT = 20 -- hard cap on speed
local WISP_MIN_SIZE = 2
local WISP_MAX_SIZE = 3
local WISP_MIN_LIFETIME = 3
local WISP_MAX_LIFETIME = 6

---@type ambientSetvice.randomWisp[]
local wisps = {}

local CLOUD_AMOUNT = 100
local CLOUD_SPEED = 5
local CLOUD_MARGIN = 0.25 -- band around the view (fraction of window) clouds live in
local CLOUD_FADE = 0.2    -- fade-in/out distance near the band edge (fraction of window)
local CLOUD_SCREEN_FADE_X = 0.3 -- fade-out distance near the left/right screen edge (fraction of screen width)
local CLOUD_SCREEN_FADE_Y = 0.4 -- fade-out distance near the top/bottom screen edge (fraction of screen height)

---@type ambientSetvice.randomCloud[]
local clouds = {}

local canvas = nil
local cloudCanvas = nil
local CLOUD_ALPHA = 0.05

-- world-space window the player is looking at; wisps spawn within it
local window = { x = 0, y = 0, w = 100, h = 100 }

local function getAdditionalAmbientService()
    local mapType = g.getMapType()
    return mapType and mapType.additionalAmbientService
end

---@class ambientSetvice.randomWisp
---@field x number
---@field y number
---@field vx number
---@field vy number
---@field maxLifetime number
---@field size number
---@field alpha number
---@field wob number
---@field lifetime number

---@return ambientSetvice.randomWisp
local function randomWisp()
    local angle = -math.pi * 0.25 + (love.math.random() - 0.5) * 0.6
    local speed = WISP_MIN_SPEED + love.math.random() * (WISP_MAX_SPEED - WISP_MIN_SPEED)
    return {
        x = window.x + love.math.random() * window.w,
        y = window.y + love.math.random() * window.h,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        maxLifetime = WISP_MIN_LIFETIME + love.math.random()*(WISP_MAX_LIFETIME-WISP_MIN_LIFETIME),
        size = WISP_MIN_SIZE + love.math.random() * (WISP_MAX_SIZE - WISP_MIN_SIZE),
        alpha = helper.lerp(0.45, 0.65, love.math.random()),
        wob = love.math.random() * consts.TAU,
        lifetime = 0,
    }
end

---@class ambientSetvice.randomCloud
---@field x number
---@field y number
---@field alpha number
---@field r number
---@field size number
---@field layer number
---@field sprite string
---@field fade number

---@param cloudSprites string[]
---@return ambientSetvice.randomCloud
local function randomCloud(cloudSprites)
    local sizeFactor = love.math.random(120, 150)/100
    local mx, my = window.w * CLOUD_MARGIN, window.h * CLOUD_MARGIN
    return {
        x = helper.lerp(window.x - mx, window.x + window.w + mx, love.math.random()),
        y = helper.lerp(window.y - my, window.y + window.h + my, love.math.random()),
        alpha = helper.lerp(0.35, 0.55, love.math.random()),
        r = love.math.random() * consts.TAU,
        size = sizeFactor,
        layer = (sizeFactor+1)/2,
        sprite = helper.randomChoice(cloudSprites),
        fade = 1,
    }
end

-- compute world-space window the player is looking at, from a camera transform
local function windowFromTransform(transform)
    local sw, sh = love.graphics.getDimensions()
    local x1, y1 = transform:inverseTransformPoint(0, 0)
    local x2, y2 = transform:inverseTransformPoint(sw, sh)
    window.x = math.min(x1, x2)
    window.y = math.min(y1, y2)
    window.w = math.abs(x2 - x1)
    window.h = math.abs(y2 - y1)
end

---@param transform love.Transform camera transform
function ambienceService.update(dt, transform)
    windowFromTransform(transform)

    local additionalAmbientService = getAdditionalAmbientService()
    if additionalAmbientService then
        additionalAmbientService.update(dt, transform)
    end

    for i, wisp in ipairs(wisps) do
        wisp.wob = wisp.wob + dt
        -- random wander: nudge velocity in a random direction each frame
        local a = love.math.random() * math.pi * 2
        wisp.vx = wisp.vx + math.cos(a) * WISP_WANDER * dt
        wisp.vy = wisp.vy + math.sin(a) * WISP_WANDER * dt
        -- clamp speed
        local spd = math.sqrt(wisp.vx * wisp.vx + wisp.vy * wisp.vy)
        if spd > WISP_SPEED_LIMIT then
            wisp.vx = wisp.vx / spd * WISP_SPEED_LIMIT
            wisp.vy = wisp.vy / spd * WISP_SPEED_LIMIT
        end
        wisp.x = wisp.x + wisp.vx * dt
        wisp.y = wisp.y + wisp.vy * dt
        wisp.lifetime = wisp.lifetime + dt
        if wisp.lifetime >= wisp.maxLifetime then
            wisps[i] = randomWisp()
        end
    end

    -- clouds drift, wrap to the opposite side when they leave the band, and
    -- fade out/in near the edges. Uses parallax-adjusted position (px/py).
    local sw, sh = love.graphics.getDimensions()
    local camX, camY = transform:inverseTransformPoint(sw/2, sh/2)
    local mx, my = window.w * CLOUD_MARGIN, window.h * CLOUD_MARGIN
    local l, r = window.x - mx, window.x + window.w + mx
    local top, bot = window.y - my, window.y + window.h + my

    for _, cloud in ipairs(clouds) do
        cloud.x = cloud.x + CLOUD_SPEED * dt

        local px = cloud.x + camX * (1 - cloud.layer)
        local py = cloud.y + camY * (1 - cloud.layer)
        if px > r then cloud.x = cloud.x - (r - l)
        elseif px < l then cloud.x = cloud.x + (r - l) end
        if py > bot then cloud.y = cloud.y - (bot - top)
        elseif py < top then cloud.y = cloud.y + (bot - top) end

        px = cloud.x + camX * (1 - cloud.layer)
        py = cloud.y + camY * (1 - cloud.layer)
        local dist = math.min(px - l, r - px, py - top, bot - py)
        cloud.fade = math.max(0, math.min(dist / (window.w * CLOUD_FADE), 1))
    end
end


---@param transform love.Transform camera transform
---@param cloudSprites string[]
function ambienceService.reInitialize(transform, cloudSprites)
    windowFromTransform(transform)

    local additionalAmbientService = getAdditionalAmbientService()
    if additionalAmbientService then
        additionalAmbientService.reInitialize(transform)
    end

    wisps = {}
    for i = 1, WISP_COUNT do
        wisps[i] = randomWisp()
    end

    clouds = {}
    for i=1, CLOUD_AMOUNT do
        clouds[i] = randomCloud(cloudSprites)
    end
end


---@param transform love.Transform camera transform (for pixel-perfect world-space rendering)
function ambienceService.draw(transform)
    local additionalAmbientService = getAdditionalAmbientService()
    if additionalAmbientService then
        additionalAmbientService.draw(transform)
    end

    ----
    -- WISP
    ----

    if not canvas then
        canvas = PixelCanvas.new(love.graphics.getDimensions())
    end
    canvas:resize(love.graphics.getDimensions())

    local lg = love.graphics
    canvas:start(transform)
    for _, wisp in ipairs(wisps) do
        local t = wisp.lifetime / wisp.maxLifetime
        local fade = math.min(t / 0.3, (1 - t) / 0.3, 1)
        lg.setColor(1, 1, 1, wisp.alpha * fade)
        lg.circle("fill", wisp.x, wisp.y, wisp.size)
    end
    lg.setColor(1, 1, 1, 1)
    canvas:finish()

    ----
    -- CLOUDS
    ----
    local sw, sh = love.graphics.getDimensions()
    if not cloudCanvas or cloudCanvas:getWidth() ~= sw or cloudCanvas:getHeight() ~= sh then
        cloudCanvas = lg.newCanvas(sw, sh)
    end
    local camX, camY = transform:inverseTransformPoint(sw/2, sh/2)

    lg.push("all")
    lg.setCanvas(cloudCanvas)
    lg.clear(0, 0, 0, 0)
    lg.applyTransform(transform)
    for _, cloud in ipairs(clouds) do
        local px = cloud.x + camX * (1 - cloud.layer)
        local py = cloud.y + camY * (1 - cloud.layer)
        local sx, sy = transform:transformPoint(px, py)
        local edgeDistX = math.min(sx, sw - sx)
        local edgeDistY = math.min(sy, sh - sy)
        local nearEdgeCoefficient = math.max(0, math.min(edgeDistX / (sw * CLOUD_SCREEN_FADE_X), edgeDistY / (sh * CLOUD_SCREEN_FADE_Y), 1))
        local alpha = cloud.fade * nearEdgeCoefficient
        lg.setColor(1, 1, 1, alpha)
        g.drawImage(cloud.sprite, px, py, cloud.r, cloud.size*2, cloud.size*2)
    end
    lg.pop()

    lg.setColor(1, 1, 1, CLOUD_ALPHA)
    lg.draw(cloudCanvas)
    lg.setColor(1, 1, 1, 1)
end

return ambienceService
