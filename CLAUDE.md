

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
- Traits: Keywords for units. Kinda like tags; they don't do anything on their own, but may interact with other systems. (Examples: Stoneskin, Townsfolk, Gremlin, Mancer)
</high_level_concepts>


<architecture>
src/g.lua: All core functions stored here, exposed via `g.*` namespace
src/scenes/*: All scenes defined here, in folders.
src/ecs/*: Entity-component-system stuff.
src/ecs/systems/*: ECS Systems. (projectile, ent movement, pathing, etc)
src/ecs/components.lua: All component type-definitions
src/modules/*: Extra modules (analytics, lighting, richtext, typechecking)
src/Run.lua: Represents a run. Stores health, food, squads, (can be serialized)
src/BattleField.lua: Represents a battlefield. Holds an ECS-World. Discarded after battle.
src/map/*: Map stuff. Holds an ECS-World.
src/consts.lua: Constants.

(^^^ NOTE: SOME OF THIS ISN'T COMPLETED YET.)
</architecture>


<event_question_bus>
Events and Questions are the core abstraction for decoupled game logic.
Pre-declared via g.defineEvent(name) / g.defineQuestion(name, reducer, default).

**Events** = dispatching information. Fire-and-forget, no return value.
  g.call("onUnitDeath", unit)
  "Something happened. React if you care."

**Questions** = gathering information. Returns a reduced value from all listeners.
  local dmg = g.ask("getDamageReduction", unit)
  "I need to know something. Everyone contribute."
  Reducers: ADD, MULTIPLY, OR, AND, MIN, MAX, PRIORITY, etc.

Handlers: A handler is a table mapping event/question names to functions: {onUnitDeath = func, getDmg = func2}
g.addHandler(handler) registers a global handler; g.clearHandlers() wipes all. Called every frame for robustness (add handlers in scene:preUpdate, clear in main loop). Since they are cleared per-frame, there's no need to remove them, lifecycle is robust.
If a handler has keys that are NOT an event/question; throws an error.

Scopes: essentially a collection of handlers, (with parent inheritance.)
- Entities can own a scope, which allows you to add effects/behaviour to entities.
- Add handlers to scopes via `ent.scope:addHandler({my_event = func, my_question = func2})`
- Handlers can auto-expire via optional duration arg, via `:addHandler(handler, duration)`. (how temporary buffs work.)
- Squad spawn creates a shared scope for all units. g.addBuff(ent, handler, duration) layers a per-entity scope on top (with the shared scope as parent), so buffs stay per-entity.
- If the scope has a parent (ent.scope = Scope(parent)) then the parent's handlers are called too. This is useful when we have a scope shared between entities, but we want to add a buff for just ONE entity; we create a new scope, and have it inherit from the old one.

EXAMPLE:
- g.call("my_event", arg1, arg2, ...)
- g.ask("my_question", arg1, arg2, ...)

There are 3 "places" where events/questions can be dispatched to:
- Scene-level: g.addHandler handlers. Used by blessings, ECS systems.
- On the entity/table itself: If arg1 is an entity (table), g.call/g.ask auto-dispatch to that entity's handlers too. So g.call("onHit", ent) hits ent.onHit.
- Entity scope: If arg1.scope is a Scope object, calls arg1.scope:call or arg1.scope:ask. Used by perks/buffs.

If you ever need clarification about any of this, launch an explore agent and ask it to be brief.
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

