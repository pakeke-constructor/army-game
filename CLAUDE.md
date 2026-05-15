

<project>
Army-Game is a 2d roguelike / RTS / deckbuilder game made in love2d with lua.
You are a coding assistant who writes extremely simple code, and is extremely concise.
</project>

<core_game_loop>
- Do battles with your army, fight demons, deploy your troops RTS-style. (Battles generally last 1-3 minutes)
    - During battles, players may click to deploy their "squads".
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
- Perks: Per-unit buffs/blessings. Use question/event buses. Eg: "This unit gains +2 damage"
- Mana: Red, Green, Blue, Wildcard. Squads cost mana to play.
</high_level_concepts>

<architecture>
main.lua: Entrypoint.
src/g.lua: All core functions stored here, exposed via `g.*` namespace
src/scenes/*: All scenes defined here, in folders.
src/scenes/map_scene/*: Map-scene stuff. Has a graph of nodes for players to navigate
src/scenes/battle_scene/*: Battle-scene stuff. Contains an ECS. Nodes on the map may trigger battles.
src/hud/*: HUD related stuff, used by multiple scenes
src/ecs/*: Entity-component-system stuff.
src/ecs/systems/*: ECS Systems. (projectile, ent movement, pathing, etc)
src/ecs/components.lua: All component type-definitions
src/modules/*: Extra modules (analytics, lighting, richtext, typechecking)
src/Run.lua: Represents a run. Stores food, squads, map-state, blessings etc. (can be serialized)
src/Squad.lua: Represents a Squad; list of units (+ perks)
src/consts.lua: Constants.

(^^^ NOTE: SOME OF THIS ISN'T COMPLETED YET.)
</architecture>

<gotchas>
A bunch of common pitfalls/traps to look out for:

- This project uses love2d version 12, which is new and has breaking changes.
- Don't set ent.x/ent.y directly on entities with a .physics component; use g.setPos(ent, x, y) which syncs the Box2D body.
- For `localize(txt)` calls, you MUST NOT localize text at runtime. It must be done at load-time. The idiomatic way is to have constants at the top, like `LOC_TXT = loc("...")`
- Pretty much ALL text in the game uses `richtext`, which has `{effect}` formatting tags, and `%{variable:.2f}` for interpolation.
- Don't add buffs to entities directly. Use g.buffEntity (stat buffs) or g.addCustomEffect (handler-based effects).
- table-valued fields on the def are shared across all entities of that type. Mutating them (e.g. `table.insert(ent.tags, ...)`) affects every entity. 
- Before adding/removing handlers to ent.scopes, look for a g.* function first.
</gotchas>

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
- Scopes contain handlers, which is just a table of functions: `handler: {my_event = func, my_question = func2}`
- Handlers can auto-expire via optional duration arg, via `:addHandler(handler, duration)`. (how temporary buffs work.)
- Squad spawn creates a shared scope for all units. g.addCustomEffect(ent, handler, duration) layers a per-entity scope on top (with the shared scope as parent), so effects stay per-entity.
- If the scope has a parent (ent.scope = Scope(parent)) then the parent's handlers are called too. This is useful when we have a scope shared between entities, but we want to add a buff for just ONE entity; we create a new scope, and have it inherit from the old one.

EXAMPLE:
- g.call("my_event", arg1, arg2, ...)
- g.ask("my_question", arg1, arg2, ...)

There are 3 places where events/questions can be dispatched to:
- Scene-level: g.addHandler handlers. Used by blessings, ECS systems.
- On the entity/table itself: If arg1 is an entity (table), g.call/g.ask auto-dispatch to that entity's handlers too. So g.call("onHit", ent) calls ent.onHit.
- Entity scope: If arg1.scope is a Scope object, calls arg1.scope:call or arg1.scope:ask. Used by perks/buffs.
</event_question_bus>

<perks>
Defined via `g.definePerk(id, name, info)`. Info has two handler tables:

- `handlers`: per-entity. Fires only when an event is dispatched AT this entity
  (eg `g.call("onHit", ent)`). Cheap; default.
- `rawHandlers`: scene-level. Fires on EVERY global dispatch. Entity passed as 1st arg:
    `rawHandlers.onAllyHurt = function(self, ally, dmg) ... end`
  Use only when listening to things not happening to the entity itself (eg "any ally hurt").
</perks>

<stats>
Entity stats, eg ent.attackDamage, ent.maxHealth, ent.attackSpeed, etc are handled in `stats.lua`.
When modifying stats:
- BAD: `ent.attackDamage = ent.attackDamage + 5`. This WON'T WORK, because stats are recalculated every frame.
- GOOD: `g.buffEntity(ent, "attackDamage", 5) -- permanent buff until ent dies
- GOOD 2: Alternatively, hook into the question-bus for the stat. (E.g. getMaxHealthModifier/Multiplier)
</perks>

<localization>
Do NOT add text to entities, blessings, or UI without wrapping it in a `loc()` call.
Use `loc(txt, variables, context)` to translate text.
Example:
```lua
BUTTON = loc("Pole button %{n}", {n = 5}, {
  context = "As in, a button at the south pole"
})
```
loc MUST be called at load-time, before the draw/update loop begins.
</localization>

<IMPORTANT-INSTRUCTIONS>
- IN ALL INTERACTIONS, BE EXTREMELY CONCISE, EVEN IF IT MEANS GRAMMATICAL INCORRECTNESS.
- You are working with an experienced engineer. Be terse; don't over-explain.
- Simple code > "correct" code. No unnecessary error handling, no overengineering for the sake of "best practices".
- No complex one-liners, no deep nesting, no clever abstractions.
- If a feature needs >300 new lines, stop and ask how to simplify.
</IMPORTANT-INSTRUCTIONS>

<FINAL-IMPORTANT-DETAILS>
You are working alongside an artist/designer to design content for army-game. The artist you are working alongside is NOT very technical.

Your tasks will involve one (or more) of the following things:
- Defining squads
- Defining enemies
- Defining perks
- Defining blessings
- (Defining anything else in `content/` folder.)

General guidelines:
- Avoid working on features that require changes to internal systems, instead, try to work within the existing systems; the main functions you will need live in `g.lua`.
- If you are reaching into internals, like `ent._target`, then it's probably a sign that the systems are not ready yet. So you should tell the user that "there isn't really a proper way to do this yet".
- You should tell the user what they are doing, and why you are doing it, keeping in mind that they are not fully technical.
- If you want to do "when this squad is deployed" effects, the MUST have a corresponding visual to go alongside it, via `drawHoverSquad`. (This could show the circle it affects, or something.)
- You MUST check that image-files exist before using them. Every image inside of `content/*`, `assets/sprites/*` is loaded by filename as a string, eg file.png -> "file".
- You MUST look at examples inside `content/` before starting. This will give you a better understanding.
- You may help the user with git issues, but NEVER EVER push directly to master.
- Do NOT use globals. If you need to store data for blessings, use `g.setBlessingData` and `g.getBlessingData`. If you need to store information on the entity you may define a field on the entity, prefixed with _; but only use this as a last-resort, and you MUST define the component as part of the `@class ecs.Entity` definition.
- IMPORTANT: Whenever you tag onto an event/question, e.g. in blessings-handler, you MUST reason about how frequently the event will be called. If it's called frequently, e.g. postUpdate, getEntityScale, then it's a hot-path, you MUST avoid allocating tables in the path, you MUST avoid iterating over every entity, you MUST avoid recursive calls. 
</FINAL-IMPORTANT-DETAILS>

