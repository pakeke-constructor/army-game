
--[[


=============================
STATS SYSTEM:
-------------------

Entity stats. Stuff like attackDamage, 

HOW ARE STATS COMPUTED?
- Stats are recomputed every frame. This makes stuff highly robust; SSOT.

COMPUTATION:
start with baseStat. eg baseSpeed, baseAttackDamage, etc.
Then, use question-buses (addition, multipliers) to modify the stat from there.
A stat called `attackDamage` will automatically generate 2 new questoins:
defineQuestion("getAttackDamageModifier", reducers.ADD)
defineQuestion("getAttackDamageMultiplier", reducers.MULT)

and then these questions can be tagged onto to modify stats.
Works for buffs, squads, anything really.

eg:

defineEntity("ent", {
    getMoveSpeedMultiplier = function(ent)
        if ent.health < ent.maxHealth * 0.2 then
            return 2 -- doubles speed when less than 20% health.
        end
    end
})

And since it's a pure-ish function, we can do anything really.
It's very elegant.



=============================

]]


defineStat("attackDamage", "baseAttackDamage")

---@class g.systems.stats: ecs.System
local stats = {}


function stats:preUpdate()
    for _, ent in self.ecs:iterate("stats") do
        -- recompute stats.
        for _, stat in ipairs(statlist) do
            if ent.stat then
                recomputeStat(ent, stat)
            end
        end
    end
end


return stats

