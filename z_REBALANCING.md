

# Rebalancing + adding more content


## GOALS:
Kapathia underwent a big change to core systems recently.
As such, we are doing a massive overhaul of existing squads/blessings.


## MANA COLOR ARCHETYPES:
RED: Aggressive, damage-focused, unit sacrifice, Burn.
Red theme: Gremlins, fire, demons.

GOLD: Economy, squad-upgrades, buildings, spawners, buffs, Lightning.
Gold theme: Robots, electricity, buildings, metal

GREEN: Healing, max-health, swarms, stat conversion, Poison.
Green theme: Nature, trees, humans

BLUE: Armor, MAGK, Spells, Freeze.
Blue theme: Fish, magic, ice, wizardry




## CONTENT TO REMOVE / REPLACE:
Kapathia underwent a big refactor recently:
Instead of deploying troops whilst the battle is running, players deploy all their troops during a "planning" phase.

The issue with this, is that a lot of old content revolved around gaining mana during battle, and deploying troops during battle. So all these blessings/perks need to be refactored/changed.

- Remove all content revolving around adding/removing mana during battle.
    - NOTE: This includes units like divers, and units like monk; since these abilities primarily work with mana-changes during battle
- Remove all on-spawn effects (stomp, beserkers, etc)
- There are too many squads/blessings that interact with attack-speed. (ASPD)
- There are *NOT ENOUGH* squads/blessings that interact with magic (MAGK.)

## Squads to remove: (the OLD effects are listed here; these squads will be refactored, but we will reuse their art.)
BLUE:
- Divers: damage scales with held blue mana
- Monks: heals to full when blue mana spent
- War Elephants: gains armor whenever a blue unit spawns
- The Immortal Eye: re-triggers all allies' on-spawn effects when blue mana spent
- Anima Incubator: spends mana during battle to spawn units

GREEN: (none)
YELLOW: (none)

RED:
- Brewers: on-spawn, buffs 2 nearby allies' ASPD
- Dagger Bearers: on-spawn, kills a nearby ally for +ATK
- His Manifestation: on-spawn, gains ATK based on ally deaths this battle


## Blessings to remove:
MANA-DURING-BATTLE:
- Water Cycle: gains blue mana during battle (per 8 blue spent)
- Trickster: gains blue mana during battle (on transform)
- Meditation: refunds blue mana during battle (first squad placed)
- Meat Grinder: gains mana during battle (after 40 ally deaths)
- Cryomana: reacts to mana gained during battle (freezes enemies)

ON-SPAWN EFFECTS:
- Mana Shield: on-spawn, gives armor if squad cost >= 2
- Stomp: on-spawn, AOE damage equal to 25% max HP
- Ubergrades: on-spawn, gives armor based on squad level (also has ASPD part, only spawn part needs removing)
- Wildfire: on-spawn, self-burn + burns random enemy
- Arcane Appetite: on-spawn, poisons commander (mana-gain part on pickup is fine, keep that)
- Landmark: on-spawn, flags first building for triple HP
- Hard Carapaces: on-spawn, gives armor to green/pest units
- etc




## REFACTORED/REUSED CONTENT:
BLUE SQUADS:
- [x] Divers x 3: Start of battle: Give a random `fishfolk` unit +4 damage
- [x] Monks x 4: Deals bonus damage equal to MAGK. (Monk starts with 1 MAGK, and has high ASPD)
- [x] Ice Elephants x 2: When hit, 10% chance to freeze the attacker
- [x] The Immortal Eye: Every second, apply 1 poison to ALL frozen enemies
- [x] Anima Incubator: BUILDING: Spawns anima-units.
RED SQUADS:
- [x] Brewers x 2: on-death, double the ASPD of 2 random allies
- [x] Dagger Bearers x 4: Has triple damage for the first 10 seconds of the fight
- [x] His Manifestation: When an ally dies, gains +1 ATK


## ADDITIONAL CONTENT: (Don't have art yet, use g.lua)
SPELLS: 
[x] Insectify: for every ally unit in range, spawns 1 Pest
[x] Freeze: freeze every enemy in range for 5 seconds
[x] Dark ritual: Deal 2 damage to allies. Give +2 MAGK to allies that were damaged.
[x] Bonereap: Trigger on-death effects on all allies without killing them
[x] Harrier: Give +70% range to all ranged units

SQUADS:
[ ] Possessor: Healer, slow moving, tanky health. Every 3 seconds: Spawn an infested human. (infested entity)
[x] Dart spitters x 4: Ranged, Apply 1 poison on hit
[x] Giant toads x 2: Tanky, Takes 50% less damage from poisoned enemies
[x] Mini toads x 4: Apply 1 poison on hit
[x] Fire golems x 2: When hit, apply 1 burn to the attacker
[x] Fire archers x 4: Ranged, Apply 2 burn on hit
[x] Hunter x 1: Medium Range, (Crossbow,) Very fast fire-rate, good damage. (use crossbow as weapon, under `bow` weapon type)
[x] Inferno beast: Hits deal AOE damage, setting enemies ablaze (+1 burn)
[x] Lightning-wizard: Emit lightning on attack, dealing damage equal to MAGK
[x] Mini ice golems: When killed, freeze all enemies in a radius
[ ] Frost mage: When a spell is cast, freeze the nearest 4 enemies for 4 seconds.
[ ] Vikings: Deal 3x damage to frozen enemies
[ ] Ethereal archers: Deal bonus damage equal to MAGK
[x] Spark-bots: When killed, emit lightning, dealing damage equal to it's current level.
[ ] Engineers: If there's 2 buildings alive, this unit gains triple speed and damage
[ ] Clanker factory: Produces 1 bot per second (2hp / 2atk)
[X] Treant: Every second, heal (HP) equal to (MAGK)

RARE SQUADS:
[ ] Muffinplants: (4x tanky melee) When killed, heal ALL allies equal to this unit's MAGK
[ ] Enchantress: (1-unit healer) Every second, give the ally with the lowest MAGK +1 MAGK



BLESSINGS:
[ ] Zeus' Wrath: Whenever an enemy is killed, spawn a chain of lightning
[ ] Thunderboom: Lightning deals double damage
[ ] Protectify: At the start of battle, gives +ARMR to each unit equal to the unit's MAGK



BASIC UNITS:
We want some "stock standard", basic units.
This pads out the unit-pool a bit, and makes the game slightly more grounded
The idea is that each mana-color will have 1 class of each: tank, damage, and ranged.
Within the class, there should be good thematic cohesion.

<basic_units>
Green units are humans: (has `human` trait)
- Human protector (human w/ wooden shield)
- Human lumberjack (damage + hp)
- Human archers (ranged)

Red units are gremlins:
- Gremlin brutes (tank)
- Gremlin beserkers (melee dmg, low range)
- Gremline slingers (range)

Blue units are fish-folk: (has `fishfolk` trait)
(ie guys with fish-heads maybe? This could be super cool. I'm envisioning it working well with the octopus guy. I'll send a picture below to explain further what I mean)
- Shield-fish  (tank)
- Spear-fish (melee dmg, higher range)
- Arrow-fish (ranged unit)

Yellow units are robots: (has `bot` trait)
- Protect-bot (tanky)
- Angry-bot (bruiser, decent hp and decent dmg)
- Gun-bot (ranged)
</basic_units>



IMPORTANT NOTE FOR IMAGES:
you should wrap EVERY image in `image = g.leo("image_name")`.
g.leo is a function that we use to alert our artist if an image is unavailable. (If the image is undefined, falls back to a placeholder.)

