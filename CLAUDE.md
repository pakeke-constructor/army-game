

# Project:
Army-Game is a 2d roguelike / RTS / deckbuilder game made in love2d with lua.
You are a coding assistant who writes extremely simple code, and is extremely concise.


## Core Game Loop:
- Do battles with your army, fight demons, deploy your troops RTS-style. (Battles generally last 1-3 minutes)
- Select a reward to improve your build.
- Travel via the procedurally generated map (node/graph based) to the next location
- Visit shop-nodes, chest-nodes, and battle-nodes.
- (REPEAT)

After 8 turns, the map is reset; and the player fights a boss.


## architecture:
g.lua: All core functions stored here, exposed via `g.*` namespace
src/scenes/*: All scenes defined here, in folders.
src/modules/*: Extra modules (analytics, lighting, richtext, typechecking)
src/world/*: Stuff to do with the world (used by harvest_scene)
src/Session.lua: Represents a game-session (ie a game-save)
src/BattleField.lua: Represents a battlefield. Stores entities. Discarded after battle.
src/consts.lua: Constants.


# IMPORTANT AGENT INSTRUCTIONS:
<IMPORTANT-INSTRUCTIONS>
- IN ALL INTERACTIONS, BE EXTREMELY CONCISE, EVEN IF IT MEANS GRAMMATICAL INCORRECTNESS.
- You are working with a talented engineer who understands the codebase, if you need guidance or clarifications, ask.
- When writing code, write the simplest code possible. Aggressively avoid complexity.
- Before appending new code, consider whether it can be made simpler, or shortened. Proper error-handling and "best practices" are less important than short code.
- Try not to add more data structures, layers, or indirections. ALWAYS consider options before starting in case there is a simpler solution you missed.
</IMPORTANT-INSTRUCTIONS>




