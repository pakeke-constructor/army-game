
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
- Make it so there is no `g.defineSquad + g.defineEntity` combination when defining squads; `g.defineSquad` CONTAINS the entity-def.
- Add new stat: `attackHeal`. Used by units that heal others
- Squads can have `onDeploy` effects, that affect the squads (Visuals for onDeploy effects (e.g. red circle?))
- Make it so entities are rendered from their base
- For systems in ECSWorld, remove passing ecs as first arg weirdly



### OK:: what do we need for a minimum-playable game?



- ~~blazing bombardiers: needs onHit system~~
- ~~demonic golith: onhit sys~~
- ~~hellHounds: onSpawn~~
- ~~charred-souls, needs perSecondUpdate to pass the second-count~~
- ~~barbs: need lifesteal~~

- druids: need healEntity
- blade/rock throwers:  need a way to customize the projectiles a bit more; speed, height, etc
- fear-system:  Opposite of taunt system
- Prospectors:  needs onKill system
- Quartz cannoneers:  (deals x2 dmg to far away: TODO: this will work with onHit, right?)
- Dynamic unit-counts: All squads with at least 6 units gain +2 units.
- Crystal golems:  Need a robust way for projectiles to duplicate themselves
- Pierce: Attack can pass through up to 5 enemies.
- Cleave: Attacks deal AOE.

- RnD: If this survives to the end of the battle, Upgrade a random squad permanently. Needs upgrade UI
- Soul Harvest: For every 10 allies that die nearby, this squad gains 1 DMG permanently.

- (STATE) Ritual: On-spawn, gains 1 DMG per 2 allies that have died this combat.
- (STATE) “Deterrent”: On-deploy, your next squad gains the Volatile Perk for the battle, exploding in a large area On-death.

- EXPLOSIONS: needs a `team` field, so it doesnt deal dmg to everything




- CLAUDE.MD: Should know "roughly" how much each stat is worth.



- Weapons system: Make it so weapons can be held/used
- melee: swords + sword swinging
- ranged: bows, + bow pointing in direction they aim


- Juice for placing units (deploy them sequentially so its satisfying?)
- Juice for spending mana: Should pop up above the units as you spend them
- Juice for spending money in shop

- Juice for breaking armor


- Explain demon-fury when hovering it.  "+20% demon damage, +10% demon health!"



- Event system: random map events on empty nodes

- Shrine nodes UI

- Special-nodes wired up


- Proper ordered-rendering for map-scene


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


<scope_creep>


- "Terrain" for battle-scene 
--- trees
--- rocks
--- grass
--- BORDER: Trees + Rocks + Dark-Fog?


- Extra fancy terrain for battles:
--- swamp
--- lava-pit

