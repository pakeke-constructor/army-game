
# backlog:



- Make map-scene render nicely (trees, mountains, demons, etc)
- Add demon-rage system
- Add enemy-encounter system
- Add top UI (xp, demon-rage, gold, day-cycle, days-until-incursion)
- Add bottom UI (squads, mana-bar, spells, blessings)
- Add example enemy-encounter
- Add spell ui hover
- Add spell selection and cast-hover
- Add spell-casting system
- Add blessing hover
- Store mana as a stat?  (Store as `globalStat` or something?)
- mana bundle support in `g.*`
- mana cost rendering (wrapper for printRich?)
- change squad-card to show mana-cost
- add a little helper to render squad-icon + mana-cost
- Remove trait system
- Bench / Active-squads system. (Squad lineup)
- Blessing reward/select UI
- Battle-reward-screen / Generic-reward-screen (STS inspired)
- Fix unit pathing; (make it so they "lock on" to targets; instead of jittering back/forth)
- fire-system
- frozen-system
- poison-system




### OK:: what do we need for a minimum-playable game?


- New HUD (from leo)

- Shop UI (from leo)
- Reroll system wired up in shop


- "Terrain" for battle-scene 
--- swamp
--- lava-pit
--- trees
--- rocks
--- grass
--- BORDER: Trees + Rocks + Dark-Fog?



- Special-nodes wired up


- Weapons system: Make it so weapons can be held/used
- melee: swords + sword swinging
- ranged: bows, + bow pointing in direction they aim


- Sound effects

- Music

- Balancing / Feedback screen, players can give UNSTRUCTURED feedback/feelings sent directly to our server and stored.



<agent_ideas>
improvements to main-agent system-prompt.
- Clearer defined workflow
- explanation for how to use `condense/checkpoint`



Set up omni-agent properly (maybe make an agent-creator helper in base-ex6?)



- Have an agent that audits changes (git diffs) and checks for issues.
That agent should utilize _ex6/coding_style.

- add push-ifs-up methodology (inside `_ex6/coding_style`)  https://gieseanw.wordpress.com/2024/06/24/dont-push-ifs-up-put-them-as-close-to-the-source-of-data-as-possible/

</agent_ideas>

