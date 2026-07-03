local fireAshAmbient = {}

local COUNT = 750
local MARGIN = 0.25
local WIND_MIN = -45
local WIND_MAX = 45
local WIND_CHANGE_MIN = 2.5
local WIND_CHANGE_MAX = 5.5
local WIND_LERP = 1.4

local EMBER_CHANCE = 0.35
local EMBER_ALPHA = {0.55, 0.85}
local EMBER_SCALE = {0.45, 0.8}
local EMBER_LIFETIME = {2, 4}
local EMBER_VX = {-8, 8}
local EMBER_VY = {-36, -18}

local ASH_ALPHA = {0.25, 0.66}
local ASH_SCALE = {0.7, 1.3}
local ASH_LIFETIME = {4, 8}
local ASH_VX = {-8, 8}
local ASH_VY = {-18, -4}

local PARTICLE_VROT = {-1.5, 1.5}

local SPRITES = {"particle_1", "particle_2", "particle_3", "particle_4"}
local EMBER_COLORS = {
    {1, 0.75, 0.12},
    {1, 0.32, 0.04},
    {0.8, 0.08, 0.02},
}
local ASH_COLORS = {
    {0.35, 0.32, 0.3},
    {0.48, 0.44, 0.4},
    {0.2, 0.18, 0.17},
}

---@class fireAshAmbient.Particle
---@field x number
---@field y number
---@field vx number
---@field vy number
---@field r number
---@field vr number
---@field scale number
---@field alpha number
---@field sway number
---@field lifetime number
---@field maxLifetime number
---@field sprite string
---@field color number[]

---@type fireAshAmbient.Particle[]
local particles = {}
local window = { x = 0, y = 0, w = 100, h = 100 }
local windX = 0
local targetWindX = 0
local windTimer = 0

---@param transform love.Transform
local function windowFromTransform(transform)
    local sw, sh = love.graphics.getDimensions()
    local x1, y1 = transform:inverseTransformPoint(0, 0)
    local x2, y2 = transform:inverseTransformPoint(sw, sh)
    window.x = math.min(x1, x2)
    window.y = math.min(y1, y2)
    window.w = math.abs(x2 - x1)
    window.h = math.abs(y2 - y1)
end

local function resetWind()
    targetWindX = helper.lerp(WIND_MIN, WIND_MAX, love.math.random())
    windTimer = helper.lerp(WIND_CHANGE_MIN, WIND_CHANGE_MAX, love.math.random())
end

---@type table<number[], objects.Color>
local snappedColors = {}

---@param fromBottom boolean?
---@return fireAshAmbient.Particle
local function randomParticle(fromBottom)
    local mx = window.w * MARGIN
    local my = window.h * MARGIN
    local isEmber = love.math.random() < EMBER_CHANCE
    local spriteIndex = isEmber and love.math.random(1, 3) or love.math.random(2, 4)
    local y1 = fromBottom and (window.y + window.h) or (window.y - my)
    local y2 = window.y + window.h + my

    local color = isEmber
        and helper.randomChoice(EMBER_COLORS)
        or helper.randomChoice(ASH_COLORS)
    local sc = snappedColors[color] or g.snapToPalette(color)
    snappedColors[color] = sc
    color = sc

    local scaleRange = isEmber and EMBER_SCALE or ASH_SCALE
    local alphaRange = isEmber and EMBER_ALPHA or ASH_ALPHA
    local lifetimeRange = isEmber and EMBER_LIFETIME or ASH_LIFETIME
    local vxRange = isEmber and EMBER_VX or ASH_VX
    local vyRange = isEmber and EMBER_VY or ASH_VY

    -- Note: Despite making 750 tables, this somehow doesn't break the sweat on Miku's laptop.
    -- So don't bother pooling for now until someone reported an issue on lower-end PCs.
    return {
        x = helper.lerp(window.x - mx, window.x + window.w + mx, love.math.random()),
        y = helper.lerp(y1, y2, love.math.random()),
        vx = helper.lerp(vxRange[1], vxRange[2], love.math.random()),
        vy = helper.lerp(vyRange[1], vyRange[2], love.math.random()),
        r = love.math.random() * consts.TAU,
        vr = helper.lerp(PARTICLE_VROT[1], PARTICLE_VROT[2], love.math.random()),
        scale = helper.lerp(scaleRange[1], scaleRange[2], love.math.random()),
        alpha = helper.lerp(alphaRange[1], alphaRange[2], love.math.random()),
        sway = love.math.random() * consts.TAU,
        lifetime = 0,
        maxLifetime = helper.lerp(lifetimeRange[1], lifetimeRange[2], love.math.random()),
        sprite = SPRITES[spriteIndex],
        color = color,
    }
end

---@param transform love.Transform
function fireAshAmbient.reInitialize(transform)
    windowFromTransform(transform)
    particles = {}
    windX = 0
    resetWind()

    for i = 1, COUNT do
        particles[i] = randomParticle(false)
    end
end

---@param dt number
---@param transform love.Transform
function fireAshAmbient.update(dt, transform)
    windowFromTransform(transform)

    windTimer = windTimer - dt
    if windTimer <= 0 then
        resetWind()
    end
    windX = helper.lerp(windX, targetWindX, math.min(dt * WIND_LERP, 1))

    local mx = window.w * MARGIN
    local my = window.h * MARGIN
    for i, particle in ipairs(particles) do
        particle.sway = particle.sway + dt * 2
        particle.x = particle.x + (particle.vx + windX + math.sin(particle.sway) * 8) * dt
        particle.y = particle.y + particle.vy * dt
        particle.r = particle.r + particle.vr * dt
        particle.lifetime = particle.lifetime + dt

        local outside = particle.y < window.y - my
            or particle.y > window.y + window.h + my
            or particle.x < window.x - mx
            or particle.x > window.x + window.w + mx

        if outside or particle.lifetime >= particle.maxLifetime then
            particles[i] = randomParticle(false)
        end
    end
end

---@param transform love.Transform
function fireAshAmbient.draw(transform)
    local lg = love.graphics

    lg.push("all")
    lg.applyTransform(transform)

    for _, particle in ipairs(particles) do
        local t = particle.lifetime / particle.maxLifetime
        local fade = math.min(t / 0.2, (1 - t) / 0.3, 1)
        lg.setColor(particle.color[1], particle.color[2], particle.color[3], particle.alpha * fade)
        g.drawImage(particle.sprite, particle.x, particle.y, particle.r, particle.scale, particle.scale)
    end

    lg.pop()
end

return fireAshAmbient
