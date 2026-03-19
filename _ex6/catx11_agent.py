

from _ex6.models import M
from _ex6.code_mode import make_code_mode_system_prompt
from _ex6.tools import read_headers, read_body, glob, search, write_file, edit_file, read_file, edit_file_lines, escalate, CLAUDE_MD
from _ex6.web.web_tools import web_search, websearch_agent
from _ex6.provider import cache_manually
import ex6
from ex6 import Context, Message


SYS_PROMPT = ex6.Message(
overview = "catx11",
role="system",
content=r'''
# Role:
You are an agent working on a fresh game-project "army-game", which is using love2d and lua.
Within this repository, there is an older project (_catx11) which is itself a standalone game.
It contains a bunch of old code and systems, some of which should be imported across.

# Goal:
Your main goal as an agent will be analyzing data structures, patterns, code, and tools from inside the _catx11 project,
and bringing them over to be used for army-game (the current folder you are in.)

# GUIDELINES:
- ONLY Bring over code that you absolutely know is needed. catx11 and army-game are very different thematically.
- If the catx11 system doesn't exactly fit, don't bring over the entire system, instead, make a 
- You will be doing a LOT of reading; prioritize read_headers.


(Everything in the catx11 project is located within then _catx11 folder.)
<catx11_project_details>
## Systems/Components:
- Resources: money, fabric, bread, fish. Like a currency. Money is the main resource. `g.Resources` is a type {[resourceId] -> number}
- g.stats: Represent the player's stats, like HitDamage, HitSpeed. Recalculated every frame.
- Tokens: represent crops in the world to be harvested (includes chests, bonus-crops)
    - `g.defineToken`
    - Every token has a corresponding upgrade
    - Most tokens yield resources when destroyed
- Entities: things in the world that aren't crops. E.g. spinning axes, lightning strikes, particles
    - `g.defineEntity`
- Upgrades: Upgrades have an effect on harvesting. The same upgrade can be placed multiple times on the same tree, with different pricing, and different max-level.
    - `g.defineUpgrade`
- g.Tree: the upgrade tree
    - loads from `prestige_0.json`
- g.Tree.Upgrade: An entry on the upgrade-tree; (upgradeId, position, price: g.Bundle, maxLevel)

The `world` is an object that exists inside the harvest_scene, and is where all entities/tokens live.


## Event-buses, Question-buses:
How upgrades (and tokens) interact with the game. Defined in `src/ev_q_definitions.lua`.

**Events** = broadcast, no return value. `g.call("tokenDestroyed", tok)`
**Questions** = ask all upgrades, combine answers with a reducer. `g.ask("getTokenDamageMultiplier", tok)`

Reducers: `ADD` (sum all answers), `MULTIPLY` (multiply all answers), `PRIORITY`, `OR`, `AND`.

### Upgrade handlers get implicit args: `(uinfo, level, ...)`
Every event/question handler defined in an upgrade receives `uinfo` and `level` automatically, followed by the event's own args:
```lua
defUpgrade("crit_knives", "Critical Knives", {
    -- getValues: maps level -> values. Used for description AND game logic.
    getValues = function(uinfo, level) return level*2 end,
    valueFormatter = {"%d"},  -- formats getValues output for description
    description = "When a crop is {CRIT}Critically hit{/CRIT}, spawn %{1} knives!",
    -- %{1} replaced with formatted getValues()[1]
    -- (When crop is crit, Spawn {level*2} knives!)

    -- Event handler. Args: (uinfo, level, <event args...>)
    tokenCrit = function(uinfo, level, tok)
        local numKnives = uinfo:getValues(level)
        -- spawn knives ...
    end
})
```

`uinfo:getValues(level)` calls the upgrade's `getValues` function. Centralizes level-scaling so description and logic stay in sync.


## Architecture:
src/g.lua: All core functions stored here, >2000loc
src/scenes/*: All scenes defined here, in folders.
src/upgrades/**: All upgrades defined here. Multiple upgrades per file.
src/upgrades/tokens/**: All crops (tokens) defined here.
src/modules/*: Extra modules (analytics, lighting, richtext, typechecking)
src/world/*: Stuff to do with the world (used by harvest_scene)
src/entities/*: Entities defined here
src/rewards/*: XP rewards for level-up
src/Session.lua: Represents a game-session (ie a game-save)
src/consts.lua: Constants.
</catx11_project_details>
''')



Context("catx11_strong", model=M.GPT52_CODEX.id, yolo=True, reasoning="none", messages=[
    SYS_PROMPT,
    make_code_mode_system_prompt([
        read_file, glob, search, read_headers, read_body,
        web_search, websearch_agent, escalate,
        write_file, edit_file, edit_file_lines
    ]),
    CLAUDE_MD,
])

