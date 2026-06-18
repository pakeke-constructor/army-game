

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
src/scenes/shop_scene/*: Shop-scene. Enter via a shop-node

src/sound/bgm.lua: Background music. Plays/crossfades music tracks by priority. Higher priority wins.
src/sound/sfx.lua: Sound effects. Define sounds, then play them with random pitch/volume variation.

src/hud/*: HUD related stuff, used by multiple scenes

src/ecs/*: Entity-component-system stuff.
src/ecs/systems/*: ECS Systems, loaded into the ECS in battle_scene:
src/ecs/systems/ai.lua: Decides what each unit does. Picks a target to attack. Makes idle units patrol around.
src/ecs/systems/attacking.lua: Units attack their target. Spawns projectiles, deals damage, does AoE/explosions.
src/ecs/systems/stats.lua: Re-calculates every unit's stats (health, damage, etc) every frame. Buffs apply here.
src/ecs/systems/status_effects.lua: Handles fire, poison, and other effects. Draws their particles.
src/ecs/systems/physics.lua: Runs the Box2D physics world. Makes/destroys a physics body for each unit.
src/ecs/systems/blood_system.lua: Draws blood splotches on the ground when units get hit or die. Visual only.
src/ecs/systems/juice_system.lua: Visual "feel" effects. Hit sparks, heal sparkles, damage numbers, screen shake.
src/ecs/systems/shadows.lua: Draws a simple shadow blob under each unit. Visual only.
src/ecs/systems/ground_decor.lua: Spawns grass and other ground decoration at the start. Visual only.
src/ecs/systems/example_system.lua: A blank template showing the shape of a system. Copy this to make a new one.
src/ecs/components.lua: All component type-definitions

src/modules/*: Extra modules (analytics, lighting, richtext, typechecking). The most-used modules are listed below:
src/modules/objects/*: Core data-types. Class (OOP), Color, Enum, plus Array/Set/Grid/Heap etc. Global `objects`.
src/modules/richtext/*: Text rendering with {effect} tags and %{var} interpolation. Global `richtext`. Used everywhere.
src/modules/localization.lua: Translates text. Global `loc(txt, vars, ctx)`. MUST be called at load-time.
src/modules/reducers.lua: The reducer functions (ADD, MULTIPLY, OR, MIN...) used when defining questions.
src/modules/helper/helper.lua: Grab-bag of small utility functions. Global `helper`.
src/modules/Picker.lua: Weighted random picker. Pick a random item from a list with weights.

src/Run.lua: Represents a run. Stores squads, map-state, blessings etc. (can be serialized)
src/Squad.lua: Represents a Squad; list of units (+ perks)
src/consts.lua: Constants.
src/ev_q_defs.lua: Declares every event and question used in the game (the names you call/ask).
src/settings.lua: Saved player settings (fullscreen, language). Load/save to disk.
src/devcmd.lua: In-game dev console. Type commands to spawn units, give gold, teleport, etc. Dev-only.
src/t.lua: Agent testing helpers. Lets the agent enter battle, spawn things, and inspect the game.

src/content/*: All the actual game content (data). allies, enemies, blessings, perks, commanders, events, encounters.
src/entities/*: Non-unit entity definitions. Projectiles, decor, and misc entities.
src/ui/*: Reusable UI widgets. Cards (squad/blessing/spell), panels, boxes.

src/ambienceService.lua: Visual ambience. Used by battle + map scenes.
src/fogService.lua: Generic fog-system; draws dark fog-of-war. Used by battle + map scenes.
src/nodeEventService.lua: Runs map-node popups (shrine, fountain, feast, portal, random events).
src/juiceService.lua: Screen shake and hit-pause (brief slow-mo on impact). Anything can request some.
src/hud/fadeToBlackService.lua: Fade the screen to/from black. Used by map nodes to hide scene transitions.
src/hud/choicePopupService.lua: Popup that makes the player pick one of a few choices (squad, blessing, mana).
src/hud/rewardPopupService.lua: Popup that shows rewards after a battle or level-up, and lets the player take one.
src/hud/hoverService.lua: Draws a hover tooltip box next to the mouse. Anything can request one each frame.
src/hud/gameoverPopupService.lua: The "you lost" popup shown when the run ends.

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
- Before adding/removing handlers to ent.scopes, look for a g.* function first. If you are unsure in general, **you should just read g.lua;** there's a lot of stuff there.
</gotchas>

<event_question_bus>
Events and Questions are the core abstraction for decoupled game logic.
Pre-declared via g.defineEvent(name) / g.defineQuestion(name, reducer, default).

**Events** = dispatching information. Fire-and-forget, no return value.
  g.call("onUnitDeath", unit)
  "Something happened. React if you care."

**Questions** = gathering information. Returns a reduced value from all listeners.
  local dmg = g.ask("getAttackDamageModifier", unitEnt)
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
