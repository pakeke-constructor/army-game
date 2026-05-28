local blood_system = {}

local MAX_SPLOTCHES = 200
local HIT_CHANCE = 0.15

local function getStore()
    local world = g.getECS()
    if not world.data.bloodSystem then
        world.data.bloodSystem = {
            splotches = objects.RingBuffer(MAX_SPLOTCHES),
        }
    end
    return world.data.bloodSystem
end

local function spawnSplotch(x, y)
    local store = getStore()
    store.splotches:push({
        x = x + love.math.random(-4, 4),
        y = y + love.math.random(-4, 4),
        rad = love.math.random(3, 7),
    })
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
    lg.setColor(0.35, 0.05, 0.05, 0.65)
    for _, s in store.splotches:iter() do
        lg.circle("fill", s.x, s.y, s.rad)
    end
    lg.setColor(1, 1, 1, 1)
end

return blood_system
