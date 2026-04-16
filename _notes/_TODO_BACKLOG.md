
# backlog:



- Make map-scene render nicely (trees, mountains, demons, etc)
- Add demon-rage system
- Add enemy-encounter system



### OK:: what do we need for a minimum-playable game?



- Add top UI (xp, demon-rage, gold, day-cycle, days-until-incursion)


- Add bottom UI (squads, mana-bar, spells, blessings)


- Add blessing-select UI


- Add spell storage and definitions
-- IDEAS: 
- spellinfo.manaCost: integer
- spellinfo.castSpell: func(x,y)
- spellinfo.drawSpellHover: func(x,y) -- called when the player is "holding" the spell, about to cast. (E.g. draws a circle or something, to show AOE area)



- Add spell-select UI


- Add spell casting system


- Add images to traits


- ~~Plan enemy encounter system.~~
- Add example enemy-encounter


- Make it so weapons can be held/used
- melee: swords + sword swinging
- ranged: bows, + bow pointing in direction they aim


- add push-ifs-up methodology (inside `_ex6/coding_style`)  https://gieseanw.wordpress.com/2024/06/24/dont-push-ifs-up-put-them-as-close-to-the-source-of-data-as-possible/



