

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




