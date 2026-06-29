
# tag string ids

- burn
- poison
- freeze
- crowd_control
- status_effect
- explosion
- ranged
- projectile
- attack_damage
- attack_speed
- health
- healing
- lifesteal
- armor
- buffing
- death_trigger
- transform
- pest (pest units are swarm-like units, like, tonnes of tiny 1/1 units.)
- mana_gain
- economy
- shop
- xp
- demon_fury
- deployment
- building
- squad_size (ONLY blessings that change the NUMBER of units in a squad, e.g. +50% units, double units. NOT flat stat buffs to all units.)
- color_synergy (interacts with a specific mana color: units/squads of that color)
- commander
- scaling (effect ACCUMULATES or stacks over a battle/run)


## Purpose
These tags exist so blessings/squads can be categorized in a consistent, queryable way.

This makes it easy during development to:
- filter/search blessings/squads by archetype quickly,
- spot archetypes that are over-supported or missing,
- identify gaps when adding new blessings/squads,
- balance content across core mechanics (for example demon_fury, mana, status_effects, economy).

The goal is faster content iteration and clearer coverage of blessing design space.

eg, we wanna quickly see:  "What blessings are related to burning?"
Or "what blessings interact with xp?"


## Prompt 0:
Work very slowly through all blessings in blessings.lua.
Assign tags to every blessing. Go through very slowly, assign "draft tags" to start with, as comments, and then do a 2nd pass, refining them.


## Prompt 1:
Read ARCHETYPE_TAGS.md. Then, read src/content/blessings.lua.
Work very slowly through all [red/blue/green/yellow] squads in blessings.lua.
Assign tags to every squad. Go through very slowly, assign "draft tags" to start with, as comments, and then do a 2nd pass, refining them.

Start with red squads.


## Prompt 2:
I want to create a 'whiteboard' scene, for development.
A whiteboard scene allows us, the devs, to visualize and mindmap all of the blessings/squads in the game, by displaying them all into a big grid.

Then, on the side, there should be like, small buttons that allow you to categorize by different stuff.
For now:
a toggle: toggle between showing a grid of blessings/squads
categorize buttons: what to categorize by:
    - rarity: sorts squads/blessings by rarity
    - tag: sorts squads/blessings by tag
    - mana: sorts squads/blessings by mana-type

read BLESSING_TAGS.md.

