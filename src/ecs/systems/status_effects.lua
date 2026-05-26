
--[[
STATUS EFFECTS SYSTEM:
=====================
Ticks burnTime, frozenTime, poisonTime on entities.
Burn and poison deal damage over time. Frozen is handled by ai/attacking systems.
]]

local statusFx = {}


function statusFx.perSecondUpdate()
    local world = g.getECS()
    for _, ent in world:iterate("team") do
        ---@cast ent ecs.Entity
        if not ent.health then goto continue end

        -- Burn: high DPS
        if ent.burnTime and ent.burnTime > 0 then
            ent.burnTime = ent.burnTime - 1
            local burnDps = consts.BURN_DPS * g.ask("getBurnDPSMultiplier", ent)
            g.dealDamage(ent, burnDps, nil, true)
            if ent.burnTime <= 0 then ent.burnTime = nil end
        end

        -- Poison: constant DPS
        if ent.poisonAmount and ent.poisonAmount > 0 then
            g.dealDamage(ent, ent.poisonAmount, nil, true)
            if ent.poisonAmount <= 0 then ent.poisonAmount = nil end
        end

        -- Frozen: just tick down (movement/attack blocked in ai + attacking systems)
        if ent.frozenTime and ent.frozenTime > 0 then
            ent.frozenTime = ent.frozenTime - 1
            if ent.frozenTime <= 0 then ent.frozenTime = nil end
        end

        if ent.taunt then
            local tauntEnt = ent.taunt.ent
            if not tauntEnt or not g.isAlive(tauntEnt) then
                ent.taunt = nil
            else
                ent.taunt.duration = ent.taunt.duration - 1
                if ent.taunt.duration <= 0 then
                    ent.taunt = nil
                end
            end
        end

        if ent.fear then
            local fearEnt = ent.fear.ent
            if fearEnt and not g.isAlive(fearEnt) then
                ent.fear = nil
            else
                ent.fear.duration = ent.fear.duration - 1
                if ent.fear.duration <= 0 then
                    ent.fear = nil
                end
            end
        end

        ::continue::
    end
end


local FIRE_PARTICLE_RATE = 0.08
local POISON_PARTICLE_RATE = 0.04

function statusFx.postDraw()
    local world = g.getECS()
    for _, ent in world:iterate("team") do
        if ent.burnTime and ent.burnTime > 0 then
            if love.math.random() < FIRE_PARTICLE_RATE then
                g.spawnParticle("fire_particle", ent.x, ent.y, 1)
            end
        end
        if ent.poisonTime and ent.poisonTime > 0 then
            if love.math.random() < POISON_PARTICLE_RATE then
                g.spawnParticle("poison_particle", ent.x, ent.y, 1)
            end
        end
    end
end

return statusFx
