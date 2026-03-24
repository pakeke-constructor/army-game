

---@class g.systems.attacking: ecs.System
local atckSys = {}


local function doAttack(attackerEnt, targEnt)

end

--[[
make it so units can move + attack.
fields needed:
```

- range (DONE)
- attackDamage (DONE)
- attackProjectile = {projectile = ent-type, count = 1, onSpawnProjectile = func?}
- attackCallback

```
]]




function atckSys:preUpdate()
    for _, ent in self.ecs:iterate("ai") do
        -- set velocities so ents move towards targets
    end
end


return atckSys


