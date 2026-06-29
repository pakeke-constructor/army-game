# Whiteboard dev scene

Goal: dev-only scene to visualize all squads & blessings in a grid, with side buttons to categorize.

## Scene location
- New folder: src/scenes/whiteboard_scene/whiteboard_scene.lua
- Auto-loaded by sceneManager (scans folders). Has init/enter/draw/keypressed.
- Entry: add devcmd command `/wb` to goto scene. Also allow Escape -> title.

## Data
- Squads: g.getSquadList() -> ids; g.getSquadInfo(id) -> {rarity, tags, cost(mana bundle)}
- Blessings: g.getBlessingList() -> ids; g.getBlessingInfo(id) -> {rarity, tags, mana(single string)}
- Rarities: g.RARITIES (COMMON/UNCOMMON/RARE/LEGENDARY...). info.rarity is the rarity table (has .id, .name, .color).
- Mana types: g.getManaTypelist() = {red,blue,green,yellow}. squad cost is bundle; blessing has .mana (may be nil).
- Icons: g.drawSquadIcon(id,x,y,drawManaCost) ; g.drawBlessingIcon(id,x,y). Both ~32px, centered.

## UI layout (ui.startUI / kirigami)
- Left sidebar: buttons.
  - Toggle button: SQUADS <-> BLESSINGS (self.mode)
  - Category buttons: RARITY / TAG / MANA (self.categorize)
- Main area: grouped grid.
  - Group items by chosen category into ordered groups.
  - For each group: draw a label (richtext) then a wrapped row of icons.
  - Icons drawn with g.drawSquadIcon / g.drawBlessingIcon.

## Grouping logic
- by rarity: group key = info.rarity.id, label = rarity name, ordered COMMON..LEGENDARY..
- by mana:
  - squads: derive mana color from cost bundle (first mana type in cost), or "colorless"
  - blessings: info.mana or "any"
- by tag: each item may have multiple tags -> appears once per tag group. Iterate tags; group label = tag. Items with no tags -> "untagged" group.

## Hover
- On icon hover use hoverService to show name (+rarity/tags). Keep simple: name + tags.

## Scrolling
- Likely many items. Support wheelmoved scroll offset on main area. Clamp.

## Notes
- pollHandlers: blessing/squad icon draw shouldn't need run handlers. Keep none, or just no pollHandlers.
- Keep everything simple, plain icons grid.
