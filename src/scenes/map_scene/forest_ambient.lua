local forestAmbient = {}

local INTENSITY = 1
local BASE_LEAF_COUNT = 36
local LEAF_MARGIN = 0.2
local LEAF_MIN_SPEED = 24
local LEAF_MAX_SPEED = 46
local LEAF_MIN_DRIFT = -12
local LEAF_MAX_DRIFT = 18
local LEAF_SWAY = 18
local LEAF_MIN_SCALE = 0.8
local LEAF_MAX_SCALE = 1.5
local LEAF_MIN_LIFETIME = 7
local LEAF_MAX_LIFETIME = 12

local LEAF_SPRITES = {
    "falling_leaves_green_1",
    "falling_leaves_green_2",
    "falling_leaves_green_3",
}

---@type forestAmbient.Leaf[]
local leaves = {}

local window = { x = 0, y = 0, w = 100, h = 100 }

---@class forestAmbient.Leaf
---@field x number
---@field y number
---@field vx number
---@field vy number
---@field r number
---@field vr number
---@field scale number
---@field sprite string
---@field sway number
---@field lifetime number
---@field maxLifetime number

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

---@param fromTop boolean?
---@return forestAmbient.Leaf
local function randomLeaf(fromTop)
    local mx = window.w * LEAF_MARGIN
    local my = window.h * LEAF_MARGIN
    local y1 = fromTop and (window.y - my) or (window.y - my)
    local y2 = fromTop and window.y or (window.y + window.h + my)

    return {
        x = helper.lerp(window.x - mx, window.x + window.w + mx, love.math.random()),
        y = helper.lerp(y1, y2, love.math.random()),
        vx = helper.lerp(LEAF_MIN_DRIFT, LEAF_MAX_DRIFT, love.math.random()),
        vy = helper.lerp(LEAF_MIN_SPEED, LEAF_MAX_SPEED, love.math.random()),
        r = love.math.random() * math.pi * 2,
        vr = helper.lerp(-1.2, 1.2, love.math.random()),
        scale = helper.lerp(LEAF_MIN_SCALE, LEAF_MAX_SCALE, love.math.random()),
        sprite = LEAF_SPRITES[love.math.random(1, #LEAF_SPRITES)],
        sway = love.math.random() * math.pi * 2,
        lifetime = 0,
        maxLifetime = helper.lerp(LEAF_MIN_LIFETIME, LEAF_MAX_LIFETIME, love.math.random()),
    }
end

local function targetLeafCount()
    return math.max(0, math.floor(BASE_LEAF_COUNT * INTENSITY))
end

---@param transform love.Transform
function forestAmbient.reInitialize(transform)
    windowFromTransform(transform)
    leaves = {}
    for i = 1, targetLeafCount() do
        leaves[i] = randomLeaf(false)
    end
end

---@param dt number
---@param transform love.Transform
function forestAmbient.update(dt, transform)
    windowFromTransform(transform)

    local target = targetLeafCount()
    for i = #leaves + 1, target do
        leaves[i] = randomLeaf(false)
    end
    for i = #leaves, target + 1, -1 do
        leaves[i] = nil
    end

    local mx = window.w * LEAF_MARGIN
    local my = window.h * LEAF_MARGIN
    for i, leaf in ipairs(leaves) do
        leaf.sway = leaf.sway + dt * 2
        leaf.x = leaf.x + (leaf.vx + math.sin(leaf.sway) * LEAF_SWAY) * dt
        leaf.y = leaf.y + leaf.vy * dt
        leaf.r = leaf.r + leaf.vr * dt
        leaf.lifetime = leaf.lifetime + dt

        local outside = leaf.y > window.y + window.h + my
            or leaf.x < window.x - mx
            or leaf.x > window.x + window.w + mx

        if outside or leaf.lifetime >= leaf.maxLifetime then
            leaves[i] = randomLeaf(true)
        end
    end
end

---@param transform love.Transform
function forestAmbient.draw(transform)
    if INTENSITY <= 0 then return end

    local lg = love.graphics
    lg.push("all")
    lg.applyTransform(transform)
    for _, leaf in ipairs(leaves) do
        local t = leaf.lifetime / leaf.maxLifetime
        local fade = math.min(t / 0.2, (1 - t) / 0.2, 1)
        lg.setColor(1, 1, 1, fade)
        g.drawImage(leaf.sprite, leaf.x, leaf.y, leaf.r, leaf.scale, leaf.scale)
    end
    lg.pop()
end

return forestAmbient
