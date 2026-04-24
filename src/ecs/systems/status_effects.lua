
--[[
STATUS EFFECTS SYSTEM:
=====================
Ticks burnTime, frozenTime, poisonTime on entities.
Burn and poison deal damage over time. Frozen is handled by ai/attacking systems.
]]

local statusFx = {}

function statusFx.preUpdate(world, dt)
    for _, ent in world:iterate("team") do
        if not ent.health then goto continue end

        -- Burn: high DPS
        if ent.burnTime and ent.burnTime > 0 then
            ent.burnTime = ent.burnTime - dt
            g.dealDamage(ent, consts.BURN_DPS * dt)
            if ent.burnTime <= 0 then ent.burnTime = nil end
        end

        -- Poison: low DPS
        if ent.poisonTime and ent.poisonTime > 0 then
            ent.poisonTime = ent.poisonTime - dt
            g.dealDamage(ent, consts.POISON_DPS * dt)
            if ent.poisonTime <= 0 then ent.poisonTime = nil end
        end

        -- Frozen: just tick down (movement/attack blocked in ai + attacking systems)
        if ent.frozenTime and ent.frozenTime > 0 then
            ent.frozenTime = ent.frozenTime - dt
            if ent.frozenTime <= 0 then ent.frozenTime = nil end
        end

        ::continue::
    end
end

return statusFx
