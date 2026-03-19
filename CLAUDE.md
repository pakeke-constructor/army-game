

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
- Squad: A bundle of Units that the player can deploy
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
src/world/*: Stuff to do with the world (used by harvest_scene)
src/Run.lua: Represents a run (can be serialized)
src/BattleField.lua: Represents a battlefield. Stores entities. Discarded after battle.
src/consts.lua: Constants.

(^^^ NOTE: SOME OF THIS ISN'T COMPLETED YET.)
</architecture>


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



<overarching_goals>
This is a brief list of stuff the user is working on right now, in a broad sense.
Don't treat it as a task-list; but rather as a guiding-force, helping you gain an understanding of the current objectives.

<epic core-systems>
A big part right now is getting the "core systems" set up.
Core systems include:
- Dead-simple ECS framework; entities are lua-tables, can have functions.
- Set up scene manager. (Import a lot of ideas from catx11.)
- UI system: Use `iml` from catx11
- Create title-scene; dead-simple START-RUN button
- Create Run object. Should contain current squads, health, money, food, blessings, map-position, and day-number.
</epic>

<epic event-question-buses>
We are working on getting the event bus and question bus system set up.
They'll be similar to catx11. 
In future, this will be used for basically all blessing/perk interactions.
Super important to get these correct; look at catx11 for inspiration.
</epic>

<epic agent-game-tools>
We are also working on the UI system, and crucially, alongside it, we are working on the Agent-game-tools.
Agent-game-tools are essentially a set of tools that the agent can use to "play" the game, inspect the current gamestate, view UI, edit and interact with the world.
The intention is for agents to be able to test the game themselves after implementing a feature, and also work through UI flows instead of having the human test it.
The idea is that the agent can spawn entities, inspect events, trace logs, track certain entities, etc.

API idea; the agent submits a "packet" of lua code, and it runs, interacting directly with the game engine.

The UI will obviously be harder for the LLM natively, since no image recognition. To accommodate this, the UI library spits out XML tags that mirror the shape of the UI, but in XML. The agent can then click through the UI, view any screen in XML, test whether it's happy with it, etc.
...
</epic>

</overarching_goals>
