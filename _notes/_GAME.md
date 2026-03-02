

# ARMY GAME:

Essentially a roguelike RTS / deckbuilder game.
The player explores the different maps, building up an army, killing stronger and stronger enemies, (until they eventually die, or beat all the maps)

Runs last around 30 minutes, and have procedurally generated maps and encounters.



## Game loop:
MAP-LOCATION: Enter a map-node -> (Battles / Events / Shop-Phase / Altar)
MAP-NAVIGATION: Choose next node on map, plan route
(Repeat)


## Manage resources:
(Money, Army-health, Food, Mana)

Money: used at shops. Earned from battles/events
Army-health: depleted during combat. Is done on a per-soldier basis
Food: Costs food every time you move
Mana: Spells cost mana
Timer: The player has 8 more moves until they must fight the boss


## Zone-System:
After `Timer` runs out, (eg after 8 moves), the player is forced to fight a strong boss.
If they beat the boss, they increase the Zone.
This will generate a new map, increase the difficulty, etc.


## Blessings:
Blessings are like relics in STS. Global passives.
Each commander (starting-item) starts with unique blessings.
Blessing ideas:
- Courage: At the start of combat, revive 3 random units
- Cannibalism: When a unit dies, gain +2 food
- Cannibalism: When a unit dies, gain +2 food



## Squads:
Squads are like a collection of units. E.g. (5 x archer).
Squads consume `food` every time move on the map.

After winning an enemy-combat, the player get to choose 1 of 4 rewards:
- 2 rewards for a new squad (REQUIRES PLAYER HAS 50% FOOD FILLED)
- 2 rewards for an upgrade to an existing squad

IMPORTANT:
To avoid the player just spamming a huge army, make it so squads consume food.
Then; when food is below 50%, the player CANNOT attain new units. (soft-cap.)
UX-wise, this might be as simple as putting a red-cross over any new-unit buttons, alongside a tooltip: "You cannot get new units when you are below 50% food!"

PERKS: Squads can also have perks.
- Beefy: Consumes +2 food, has +40% health
- Strong: Consumes +2 food, deals +50% damage
- Lean: Consumes 1 less food

Some squads/units are economy-focused:
- Necromancer: if he survives to the end of a fight, revives a random dead unit
- Cleric: gives 1 mana on combat start and nothing else


## Armys:
An army is a list of squads.



