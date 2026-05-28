local blood_system = {}

local MAX_SPLOTCHES = 200
local HIT_CHANCE = 0.15

local function getStore()
    local world = g.getECS()
    world.data.bloodSystem = world.data.bloodSystem or {
        splotches = {},
    }
    return world.data.bloodSystem
end

local function spawnSplotch(x, y)
    local store = getStore()
    local list = store.splotches
    if #list >= MAX_SPLOTCHES then
        table.remove(list, 1)
    end
    list[#list + 1] = {
        x = x + love.math.random(-4, 4),
        y = y + love.math.random(-4, 4),
        rad = love.math.random(3, 7),
    }
end

function blood_system.entityDeath(ent, killer)
    if not ent then return end
    local count = love.math.random(2, 4)
    for i = 1, count do
        spawnSplotch(ent.x, ent.y)
    end
end

function blood_system.onHitDamage(attacker, damage, target, isArmorHit)
    if not target then return end
    if isArmorHit then return end
    if love.math.random() < HIT_CHANCE then
        spawnSplotch(target.x, target.y)
    end
end

function blood_system.preDraw()
    local store = getStore()
    local list = store.splotches
    lg.setColor(0.35, 0.05, 0.05, 0.65)
    for i = 1, #list do
        local s = list[i]
        lg.circle("fill", s.x, s.y, s.rad)
    end
    lg.setColor(1, 1, 1, 1)
end

return blood_system
