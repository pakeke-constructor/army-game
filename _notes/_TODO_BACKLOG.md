
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

- ~~blazing bombardiers: needs onHit system~~
- ~~demonic golith: onhit sys~~
- ~~hellHounds: onSpawn~~
- ~~charred-souls, needs perSecondUpdate to pass the second-count~~
- ~~barbs: need lifesteal~~
- ~~druids: need healEntity~~
- ~~blade/rock throwers:  need a way to customize the projectiles a bit more; speed, height, etc~~
- ~~fear-system:  Opposite of taunt system~~
- ~~Prospectors:  needs onKill system~~
- ~~Quartz cannoneers:  (deals x2 dmg to far away: TODO: this will work with onHit, right?)~~
- ~~Dynamic unit-counts: All squakds with at least 6 units gain +2 units.~~
- ~~Crystal golems:  Need a robust way for projectiles to duplicate themselves~~
- Pierce: Attack can pass through up to 5 enemies.
- EXPLOSIONS: needs a `team` field, so it doesnt deal dmg to everything
- Cleave: Attacks deal AOE.
- Soul Harvest: For every 10 allies that die nearby, this squad gains 1 DMG permanently.
- Add a HUD priority system, which sorts squads before playing (eg suicide-bombers first, melee next, ranged next, and buffers/onDeploy squads last)
- Weapons system: Make it so weapons can be held/used
- melee: swords + sword swinging
- ranged: bows, + bow pointing in direction they aim
- CLAUDE.MD: Tell agent to avoid setting stats directly (use actual example)
- remove iron-hide, remove tough perk
- Juice for placing units (deploy them sequentially so its satisfying?)
-- show name above unit when hovering it
-- units deploy sequentially, (stretched towards sky?)
- EX6: Remove aggressive RestrictedPython sandboxing for agents; let them free.
- Instead of referencing "ATK" and "ASPD" in descriptions; should populate with icon+colored text - so it's a bit more formalized. (E.g. `Gain 1 (ASPD)`, replaces with richtext.)
- In squad-card, Make stats panels better. Most important stats at top. Don't even show other panels.
- In squad-card, compress perks to 3 slots. printRichContained. hard limit of 3 perks / squad
- In squad-card, make it so unit-visual doesn't overflow
- Make squads easier to define
- Ground texture. rip from catx.
- earn gold when killing enemies
- txt popup after killing enemies
- Xp / level up system
- Explain demon-fury when hovering it.  "+10% demon damage, +10% demon health!"
- Wire up stuff in New Content.txt
- Add reroll to squad-select in ChoicePanel
- Juice for spending mana: Should pop up above the units as you spend them
- Juice for dealing damage (see leo gif)
- Fix ordered-rendering in map-scene. Draw images from their base (0.95h)
- Fix commander being drawn behind
- (IDEA: Make a 2 pass system, with `collectDrawables` or something)
- FIX performance issues w/ Blessings: `randomEnemy` is way too expensive
- key system
- Event system: random map events on empty nodes
- VIBE-COD: make it so enemies get yeeted offscreen on death
- Improvements to squad-card UI: make border colors better, the color of the mana, NOT the color of rarity
- Improvements to squad-card UI: remove "UPGRADE" crap when hovering normally
- fix health-increase overflow (cap it)




### OK:: what do we need for a minimum-playable game?


- fix shop

- fix max hp increase upgrades


- Change ranged-icon; it shouldnt be a sword, should be bow


- Shrine nodes UI:  [Choose to remove a squad, reducing demon-rage + gold, OR, upgrade a squad]
- Fountain nodes UI:  [Choose to reduce demon-rage, OR choose a blessing]


- Chest node + Chest-node UI


- PROCESS: Play through the game a couple times. Just get a feel, then *balance*
- IMPORTANT: FIX REMAINING PERKS / BLESSINGS / ETC.
- Fix balance for base squads




#### CUTOFF. EVERYTHING ABOVE THIS POINT IS 100% NECCESSARY.

- Juice for clicking on a map node

- Juice for breaking armor

- Juice for spending money in shop

- CLAUDE.MD: Should know "roughly" how much each stat is worth.


- Maybe when enemies die, leave a subtle gravestone sprite



- Make the battle-scene be a bit more interesting.... instead of a dull rectangle all the time.
- Maybe hardcode a few shapes?
- Peanut shape, Oval shape, multi-circle-shape




- Sound effects

- Music

- Balancing / Feedback screen, players can give UNSTRUCTURED feedback/feelings sent directly to our server and stored.



- RnD: If this survives to the end of the battle, Upgrade a random squad permanently. Needs upgrade UI
- (STATE) Ritual: On-spawn, gains 1 DMG per 2 allies that have died this combat.
- (STATE) “Deterrent”: On-deploy, your next squad gains the Volatile Perk for the battle, exploding in a large area On-death.




<scope_creep>


- "Terrain" for battle-scene 
--- trees
--- rocks
--- grass
--- BORDER: Trees + Rocks + Dark-Fog?


- Extra fancy terrain for battles:
--- swamp
--- lava-pit

