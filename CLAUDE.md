

<project>
Army-Game is a 2d roguelike / RTS / deckbuilder game made in love2d with lua.
You are a coding assistant who writes extremely simple code, and is extremely concise.
</project>


<core_game_loop>
- Do battles with your army, fight demons, deploy your troops RTS-style. (Battles generally last 1-3 minutes)
    - During battles, players may click to deploy their "squads".
    - During battles, players may also cast spells, spending mana.
    - If all enemies are killed, player wins. If the player's "core nexus" is destroyed, player loses battle.
- Select a reward to improve your build.
- Travel via the procedurally generated map (node/graph based) to the next location
- Visit shop-nodes, chest-nodes, and battle-nodes.
- (REPEAT)

After 8 turns, the map is reset; and the player fights a boss.
</core_game_loop>


<high_level_concepts>
- Units: A singular Enemy or ally; e.g. a soldier that fights for you. ranged or melee.
- Squad: A bundle of Units that the player can click to deploy. (Traits and Perks are shared across every unit.)
- Blessings: A per-run buff that gives global benefits: e.g: "Gain +2 mana after battle". Use question/event buses.
- Spells: Spells can be cast during battle. Generally cost mana, and have a cooldown.
- Perks: Per-unit buffs/blessings. Use question/event buses. Eg: "This unit gains +2 damage"
- Traits: Keywords for units. Kinda like tags; they don't do anything on their own, but may interact with other systems. (Examples: Stoneskin, Townsfolk, Gremlin, Mancer, Beast, Alchemist, Wild)
</high_level_concepts>


<architecture>
src/g.lua: All core functions stored here, exposed via `g.*` namespace
src/scenes/*: All scenes defined here, in folders.
src/map/*: Map stuff goes here
src/modules/*: Extra modules (analytics, lighting, richtext, typechecking)
src/Run.lua: Represents a run. Stores health, food, squads,  (can be serialized)
src/BattleField.lua: Represents a battlefield. Stores entities. Discarded after battle.
src/consts.lua: Constants.

(^^^ NOTE: SOME OF THIS ISN'T COMPLETED YET.)
</architecture>


<event_question_bus>
Events and Questions are the core abstraction for decoupled game logic.
Defined via g.defineEvent / g.defineQuestion in advance.

**Events** = dispatching information. Fire-and-forget, no return value.
  g.call("onUnitDeath", unit)
  "Something happened. React if you care."

**Questions** = gathering information. Returns a reduced value from all listeners.
  local dmg = g.ask("getDamageReduction", unit)
  "I need to know something. Everyone contribute."

Questions use reducers (ADD, MULTIPLY, OR, AND, PRIORITY, etc) to combine answers.

Three levels of listeners, dispatched in order:
1. Scene-level handlers: added via g.addHandler({...}) every frame. Cleared each frame by g.clearHandlers(). Used by blessings, global systems.
2. Direct entity handler: ent[eventName] or ent[questionName]. Defined on entity def.
3. Entity handler list: ent.handlers = {{eventName=func}, ...}. Used by perks.

g.call/g.ask auto-dispatch to all three when arg1 is a table (entity).
</event_question_bus>


<catx11_reference>
- _catx11 (folder `_catx11/**`) is an older standalone game kept in this repo.
- It contains some patterns that are useful; hence why it's copied over.
- Use it as a reference if asked. It has a CLAUDE.md file that explains the project.
</catx11_reference>



<IMPORTANT-INSTRUCTIONS>
- IN ALL INTERACTIONS, BE EXTREMELY CONCISE, EVEN IF IT MEANS GRAMMATICAL INCORRECTNESS.
- You are working with an experienced engineer. Be terse; don't over-explain.
- Simple code > "correct" code. No unnecessary error handling, no overengineering for the sake of "best practices".
- No complex one-liners, no deep nesting, no clever abstractions.
- If a feature needs >300 new lines, stop and ask how to simplify.
</IMPORTANT-INSTRUCTIONS>

