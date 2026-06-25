# Spell System Plan

Goal: simplest possible "spell" system. Mirrors Squad, but spells are played
DURING battle (after battle start), whereas squads are played BEFORE battle
(during the deploy/planning phase).

## Core difference vs squads
- Squad: deployed only while `battle_scene.deployPhase == true` (battle NOT started).
- Spell: usable only AFTER `deployPhase == false` (battle started).

## Data model (current, simplified)
- Spells are NOT objects. `Run.spells = {[spellId] = true}` (a set).
- `Run.spellsCast = {[spellId] = true}` tracks which spells were cast this battle.
  Reset in init / resetForBattle / deserialize.
- `g.defineSpell(id, spellDef)`: registers a spell def (load-time, like defineSquad).
- `g.addSpellToArmy(id)` / `g.hasSpell(id)`.
- `g.castSpell(id, x, y)`: marks spellsCast[id]=true, calls def.cast(id, x, y).
- `g.getSpellInfo(id)` returns the def.
- `g.renderSpellIcon(id, x, y, drawManaCost)` draws the icon (mirrors g.drawSquadIcon).

## SpellDef shape
- id (set by define)
- name (loc'd at define-time)
- rarity
- icon
- cost (g.ManaBundle)
- description?
- cast(spellId, x, y) -- effect (stub for now)

## HUD selection model (THE PLAN — simplify, no separate selectedSpell)

One big army bar the user can scroll across. It shows squads AND spells.
Selection is UNIFIED: exactly ONE thing is selected at a time.

Add a new arg to `HUD:drawUI` (and thread through): `battleStarted: boolean`.

Rules:
- battleScene + NOT battleStarted (deploy phase): only SQUADS are selectable.
- battleScene + battleStarted: only SPELLS are selectable.
- During battle, a valid spell XOR a valid squad is ALWAYS selected.
- If the currently-selected item can't be afforded, auto-pick the next
  closest affordable item (same logic as getClosestAvailableSlot today, but
  applied to whichever pool — squads pre-battle, spells mid-battle).

Implementation notes:
- DROP `selectedSpell`. Reuse the existing single-cursor approach
  (`selectedSlot` + getClosestAvailableSlot / getSlotIndex), but make the
  "pool" depend on phase:
    - pre-battle pool = visible squads
    - mid-battle pool = owned spells (not yet cast, affordable)
- `currentHover` stays unified (squad table OR spellId string) for tooltips.
- `HUD:getSelection()` returns (type, value): ("spell", spellId) | ("squad", g.Squad) | nil.
- Scroll wheel / number keys move the cursor within the active pool only.
- When phase flips (battle starts), cursor resets to first affordable spell.

This keeps ONE cursor, ONE selection. No XOR bugs, no two-state mess.

## Phases (the milestones)
1. [DONE] Data model: Run.spells set + Run.spellsCast. defineSpell registry.
2. [DONE] Content: heal_spell, poison_spell in src/content/spells/spells.lua.
3. [DONE] Casting: g.castSpell(id, x, y) -> calls def.cast. Consumes mana (battle_scene).
4. HUD: unify selection per the model above (battleStarted arg, one cursor).
   - Currently half-done with a separate selectedSpell — REPLACE with the
     phase-based single-cursor model.
5. Targeting: point-target only for now. (some spells may target units later.)
6. Rewards/shop: let player acquire spells (addSpellToArmy), like squads.

## Notes
- Keep it dead simple. No cooldowns, no upgrades, until asked.
- Spells reset per battle via spellsCast (a cast spell is "used up" for the fight).
