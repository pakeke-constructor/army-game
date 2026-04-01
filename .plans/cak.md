Squad Card Pick — Victory Select Screen

After winning a battle, player picks 1 of 3 squad cards to add to their army.

## What exists
- `ui.drawSquadCard(squadId, region)`: Squad card draw function (from plan wcm)
- `victoryPopup()` in `battle_scene.lua`: Current "Victory! OK" popup → goes to map_scene
- `g.newSquad(id)` / `g.addSquadToArmy(squad)`: Creates and adds squads to run
- `g.getSquadList()`: Registry of all squad definitions

## Steps

### 1. Modify `victoryPopup` in `battle_scene.lua`
Replace the current "Victory! OK" flow with a squad-pick flow:

- On victory, generate 3 random squad IDs (from `g.getSquadList()`, shuffled, pick 3)
- Store in `self.victoryChoices = {id1, id2, id3}`
- In draw: show "Victory!" title, then 3 squad cards side by side (split region horizontally into 3)
- Each card is clickable. Clicking one calls `g.addSquadToArmy(g.newSquad(chosenId))` then `g.gotoScene("map_scene")`

### 2. Wire up in battle_scene:enter / update
- `self.victoryChoices = nil` in enter
- When `self.victoryPopup` triggers, also generate `self.victoryChoices` if nil

### 3. Add `rarity` and `traits` fields to squad defs (optional/future)
Not blocking. Use COMMON rarity and empty traits for now.
