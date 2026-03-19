
# Event Bus / Question Bus API

```lua
-- Define events and questions at startup:
g.defineEvent("onDamage")
g.defineQuestion("getDamageReduction", reducers.ADD, 0)


-- Scene-level handlers (ephemeral, re-added every frame):
function scene:preUpdate()
    g.addHandler({
        onDamage = function(ent, dmg) ... end,
        getDamageReduction = function(ent) return 2 end,
    })
end
-- g.clearHandlers() is called once per frame to wipe these.


-- Entities can listen directly:
ent = {
    onDamage = function(self, dmg) ... end,
    getDamageReduction = function(self) return 1 end,
}

-- Entities also have a handler list (for perks):
ent.handlers = {
    {getDamageReduction = function(ent) return 2 end},  -- stoneskin perk
    {onDamage = function(ent, dmg) ... end},             -- vampiric perk
}


-- Dispatch:
g.call("onDamage", ent, dmg)
-- 1. scene-level handlers (frameHandlers)
-- 2. ent.onDamage (direct)
-- 3. ent.handlers list

local reduction = g.ask("getDamageReduction", ent)
-- 1. scene-level handlers (frameHandlers), reduced
-- 2. ent.getDamageReduction (direct), reduced
-- 3. ent.handlers list, reduced
```
