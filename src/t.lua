
--[[

t.lua: Agent testing functions.

The agent can write lua code to run code, test stuff, view UI, see the world, etc.
This essentially allows agents to test their own code.



PLANNING; WHAT DO WE WANT?
- we should probably have the agent call lua API directly. 
- Shouldn't have a tonne of custom-functions; keep it SUPER THIN.
IDEA:
```
t.enterBattle()
local e = g.spawnEntity("militia")
g.addPerk(e, ...)
t.wait(3)
t.inspectBattle()
```



```
t.enterBattle()
g.spawnEntity()
t.wait(3)
t.inspectBattle()
```
]]


---@class t
local t = {}



function t.enterBattle()
    -- starts an empty battle sandbox
end

function t.enterMap()
    -- enters map.
end



function t.inspectBattle()
    -- inspects battle; (prints data to context window)
end

function t.inspectEntity()
    -- inspects an entity; (prints a data to context window)
end




function t.inspectUI()
    -- inspects UI (returns a bunch of XML)
end

function t.clickUI(elementId)
    -- clicks UI (must have done `inspectUI` beforehand)
end

function t.hoverUI(elementId)
    -- hovers over UI (must have done `inspectUI` beforehand)
end






return t
