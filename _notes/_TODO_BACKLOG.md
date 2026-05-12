
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
- New HUD (from leo)
- Add glow_lootreward.png to the rewards-screen
- Squad upgrade system
- Shop UI (from leo)
- Add smoke to fire-particles. smoke becomes bigger, gray/dark gray.
- In shop, when hovering a squad, display squad-card on right
- Set up leo w/ claude-code
- Map-scene improvements:
--- Commander movement for map-scene
--- Make the yellow-visual snap to thing to the closest mouse position
- Enter-animation for battle-scene.  Camera zoom-in when entering.  Show "battle start" text.
- Dark-fog rendering system.
- dark-fog for map
- dark-fog for battle-scene
- Write CLAUDE.md for Leo
- Status-effect system
- Add armor system
- Make demons/enemies walk around a bit randomly at the start of combat
- Make sandbox for Leo
- Squad upgrade UI
- When hovering squad-card, you can see the squad-upgrade
- When hovering squad-box, squad-card shows the upgrade.
- refactor: There currently exist 2 funcs, `g.addBuff  g.buffEntity`. Simplify this, have one of them be `g.addCustomEffect` or something.




### OK:: what do we need for a minimum-playable game?





- Make it so there is no `g.defineSquad + g.defineEntity` combination when defining squads; `g.defineSquad` CONTAINS the entity-def.



- Add new stat: `attackHeal`. Used by units that heal others



- Perks can have `onDeploy` effects, that affect the squads
--- Visuals for onDeploy effects (e.g. red circle?)



- Event system: random map events on empty nodes

- Shrine nodes UI

- Special-nodes wired up


- Proper ordered-rendering for map-scene


- Weapons system: Make it so weapons can be held/used
- melee: swords + sword swinging
- ranged: bows, + bow pointing in direction they aim




- "Terrain" for battle-scene 
--- trees
--- rocks
--- grass
--- BORDER: Trees + Rocks + Dark-Fog?




- Juice for placing units (deploy them sequentially so its satisfying?)
- Juice for spending mana: Should pop up above the units as you spend them
- Juice for spending money in shop

- Juice for breaking armor



- Extra fancy terrain for battles:
--- swamp
--- lava-pit


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

