
# Event Bus / Question Bus API

```lua
-- Define events and questions at startup:
g.defineEvent("onDamage")
g.defineQuestion("getAttackDamageModifier", reducers.ADD, 0)


-- Scene-level handlers (ephemeral, re-added every frame):
function scene:preUpdate()
    g.addHandler({
        onDamage = function(ent, dmg) ... end,
        getAttackDamageModifier = function(ent) return 2 end,
    })
end
-- g.clearHandlers() is called once per frame to wipe these.


-- Entities can listen directly:
ent = {
    onDamage = function(self, dmg) ... end,
    getAttackDamageModifier = function(self) return 1 end,
}

-- Entities also have a handler list (for perks):
ent.handlers = {
    {getAttackDamageModifier = function(ent) return 2 end},  -- stoneskin perk
    {onDamage = function(ent, dmg) ... end},             -- vampiric perk
}


-- Dispatch:
g.call("onDamage", ent, dmg)
-- 1. scene-level handlers (frameHandlers)
-- 2. ent.onDamage (direct)
-- 3. ent.handlers list

local reduction = g.ask("getAttackDamageModifier", ent)
-- 1. scene-level handlers (frameHandlers), reduced
-- 2. ent.getAttackDamageModifier (direct), reduced
-- 3. ent.handlers list, reduced
```
