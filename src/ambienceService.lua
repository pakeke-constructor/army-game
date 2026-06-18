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


local wisps = {}

local CLOUD_AMOUNT = 30

local clouds = {}

local canvas = nil

-- world-space window the player is looking at; wisps spawn within it
local window = { x = 0, y = 0, w = 100, h = 100 }

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
        alpha = 0.45 + love.math.random() * 0.2,
        wob = love.math.random() * math.pi * 2,
        lifetime = 0,
    }
end

local function randomCloud()
    return {
        x = window.x + love.math.random() * window.w,
        y = window.y + love.math.random() * window.h,
        alpha = 0.45 + love.math.random() * 0.2,
        r = love.math.random() * math.pi * 2,
        
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

    for i, cloud in ipairs(clouds) do
        cloud.x = cloud.x + 5 * dt
    end
end


---@param transform love.Transform camera transform
function ambienceService.reInitialize(transform)
    windowFromTransform(transform)
    wisps = {}
    for i = 1, WISP_COUNT do
        wisps[i] = randomWisp()
    end

    clouds = {}
    for i=1, CLOUD_AMOUNT do
        clouds[i] = randomCloud()
    end
end


---@param transform love.Transform camera transform (for pixel-perfect world-space rendering)
function ambienceService.draw(transform)
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

    for _, cloud in ipairs(clouds) do
        lg.setColor(1, 1, 1, cloud.alpha)
        g.drawImage("cloud1", cloud.x, cloud.y, cloud.r)
    end
    canvas:finish()
end

return ambienceService
