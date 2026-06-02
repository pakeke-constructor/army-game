-- Screen-space drifting "wisps" / smoke debris for ambience.
local ambienceService = {}


local WISP_COUNT = 28
local WISP_MIN_SPEED = 12
local WISP_MAX_SPEED = 40
local WISP_MIN_SIZE = 5
local WISP_MAX_SIZE = 8
local WISP_MAX_LIFETIME = 14


local wisps = {}

local function randomWisp(sw, sh)
    local angle = -math.pi * 0.25 + (love.math.random() - 0.5) * 0.6
    local speed = WISP_MIN_SPEED + love.math.random() * (WISP_MAX_SPEED - WISP_MIN_SPEED)
    return {
        x = love.math.random() * sw,
        y = love.math.random() * sh,
        vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed,
        size = WISP_MIN_SIZE + love.math.random() * (WISP_MAX_SIZE - WISP_MIN_SIZE),
        alpha = 0.20 + love.math.random() * 0.15,
        wob = love.math.random() * math.pi * 2,
        lifetime = 0,
    }
end

function ambienceService.update(dt)
    local sw, sh = love.graphics.getDimensions()
    for i, w in ipairs(wisps) do
        w.wob = w.wob + dt
        w.x = w.x + (w.vx + math.sin(w.wob) * 6) * dt
        w.y = w.y + w.vy * dt
        w.lifetime = w.lifetime + dt
        if w.lifetime >= WISP_MAX_LIFETIME then
            wisps[i] = randomWisp(sw, sh)
        end
    end
end


function ambienceService.reInitialize()
    local sw, sh = love.graphics.getDimensions()
    wisps = {}
    for i = 1, WISP_COUNT do
        wisps[i] = randomWisp(sw, sh)
    end
end


function ambienceService.draw(x,y, w,h)
    if not wisps then return end
    local lg = love.graphics
    for _, w in ipairs(wisps) do
        local t = w.lifetime / WISP_MAX_LIFETIME
        local fade = math.min(t / 0.15, (1 - t) / 0.15, 1)
        lg.setColor(1, 1, 1, w.alpha * fade)
        lg.circle("fill", w.x, w.y, w.size)
    end
    lg.setColor(1, 1, 1, 1)
end

return ambienceService
