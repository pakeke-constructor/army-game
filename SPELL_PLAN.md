# Spell System Plan

Goal: simplest possible "spell" system. Mirrors Squad, but spells are played
DURING battle (after battle start), whereas squads are played BEFORE battle
(during the deploy/planning phase).

## Core difference vs squads
- Squad: deployed only while `battle_scene.deployPhase == true`.
- Spell: usable only AFTER `deployPhase == false` (battle started).

## Concepts
- `g.defineSpell(id, spellDef)`: registers a spell def (load-time, like defineSquad).
- `Spell` object (src/Spell.lua): a runtime instance, like Squad.lua. Holds
  spellId, level, icon, statBuffs/storage if needed. Serializable.
- Run stores owned spells alongside squads (run.spells), serialized/deserialized.

## SpellDef shape (minimal shell)
- id (set by define)
- name (loc'd at define-time)
- rarity
- icon
- cost (g.ManaBundle)
- description?
- cast(spell, x, y) -- what the spell does when played (stub for now)

## Phases (the milestones)
1. [DONE - shell] Spell.lua object + g.defineSpell/getSpellInfo/newSpell registry.
   - SPELL_DEFS / SPELL_LIST in g.lua.
   - Run holds run.spells, serialize/deserialize.
2. Content: define a couple real spells in src/content/spells/spells.lua.
3. Casting: g.castSpell(spell, x, y) -> calls def.cast. Consumes mana.
4. HUD: show spell cards in battle (only when NOT deployPhase). Click to select,
   click battlefield to cast. Reuse squad-card UI patterns.
5. Targeting: some spells target a point, some target a unit. Keep simple first
   (point-target only).
6. Rewards/shop: let player acquire spells (addSpellToArmy), like squads.

## Notes
- Squads are reset each battle (deployed flag). Spells likely reset per battle
  too (cooldown / one-use?). Decide later; out of scope for shell.
- Keep it dead simple. No cooldowns, no upgrades beyond level field, until asked.

## This commit (shell only)
- src/Spell.lua
- g.defineSpell / g.getSpellInfo / g.newSpell / g.addSpellToArmy / g.getSpellFromArmy
- SPELL_DEFS / SPELL_LIST
- Run.spells field + serialize/deserialize
