Squad Card — Draw Function

Implement `ui.drawSquadCard(squadId, region)` in `src/ui/squad_card.lua`.
Draw a single squad card in a kirigami region. Returns true if clicked.

## What exists
- `src/ui/squad_card.lua`: Layout spec (comments only, no code yet)
- `g.RARITIES`, `g.TRAITS`: Rarity colors, trait boxes
- `ui.drawTraitBox`, `ui.drawPanel`, `ui.drawSingleColorPanel`, `ui.Box`: UI primitives
- `g.drawImageContained(name, x,y,w,h)`: Draw image fitted to rect
- `g.getEntityDef(entityId)`: Get base stats from entity def
- `g.getSquadInfo(id)`: Registry of all squad definitions
- Kirigami for layout regions; `iml` for click detection

## Layout (vertical, top to bottom)
- Icon + Title row (icon from squad def, title = squadId for now)
- Trait boxes row (from squad def — NOTE: squads don't have traits yet, skip for now or add field)
- Unit count line ("x4", "x6")
- 2x3 stat grid: (2 width, 3 height.) health, damage, attackSpeed, armor, speed, attackRange (pull from entity def via `g.getEntityDef(info.entityId)`)
- Perk list (squad.perks → g.getPerkInfo each, show name)

## Visual style
- Border color = rarity color (squads don't have rarity yet — use COMMON for now)
- Dark background with slight rarity-color tint
- Use `ui.drawPanel` for border, `ui.gradientRect` or gradient for bg
