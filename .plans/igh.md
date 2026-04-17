
## drawArmyWidgets region refactor

### Current behavior (lines 69-114):
- startX = 20 (hardcoded)
- baseY = sh - SQUAD_ICON_SIZE - 10 (bottom of screen)
- Icons at fixed SQUAD_ICON_SIZE (32), SQUAD_PADDING (4) between them
- totalW computed but unused

### New behavior: drawArmyWidgets(self, region)
- region is a kirigami Region (has .x, .y, .w, .h)
- Icons stay at SQUAD_ICON_SIZE (no scaling)
- Compute needed width: count * SQUAD_ICON_SIZE + (count-1) * SQUAD_PADDING + 2*SQUAD_PADDING
- Compute needed height: SQUAD_ICON_SIZE + 2*SQUAD_PADDING
- If region.w < neededW, expand: region = region:set(nil, nil, neededW, nil)
- If region.h < neededH, expand: region = region:set(nil, nil, nil, neededH)
- Pad region by SQUAD_PADDING (the 20px padding around edges)
  Wait - user said "Ensure 20 padding around edges. use SQUAD_PADDING variable."
  SQUAD_PADDING is 4. That's not 20. Re-read: "Ensure 20 padding around edges."
  Hmm, they said use SQUAD_PADDING variable but also 20 padding. Maybe they want me to change SQUAD_PADDING to 20? Or use a separate pad value?
  I think they mean: pad the region by 20px on all sides, and use SQUAD_PADDING for spacing between squads.
  Actually re-reading: "Ensure 20 padding around edges. use SQUAD_PADDING variable." - maybe they want to use SQUAD_PADDING for the edge padding too. But SQUAD_PADDING=4, and they said 20. I'll just use 20 as a literal or a new constant, and SQUAD_PADDING between items.
  
  Actually wait - maybe they want me to rename/reuse SQUAD_PADDING. Let me just use a local `edgePad = 20` and SQUAD_PADDING between squads. Or maybe they want SQUAD_PADDING for both. I'll ask... no, let me just use 20 for edge padding. They said "use SQUAD_PADDING variable" so maybe they want SQUAD_PADDING for the inter-squad spacing only, and 20 is a literal for the edge. I'll keep it simple.

### Layout:
- After expanding region if needed, pad by 20 on all sides
- Space squads evenly within padded region:
  - Available width after padding = inner.w
  - Each squad occupies SQUAD_ICON_SIZE width
  - Spacing = (inner.w - count * SQUAD_ICON_SIZE) / (count - 1) if count > 1, else center
  - OR: evenly = distribute across inner width
  - y = vertically center in inner region

### Callers (lines 174, 179):
- drawBattleHUD and drawMapHUD call drawArmyWidgets(self) with no region
- Need to pass a region. For now, construct a region at bottom-left matching old behavior, or require callers to pass one.

### Steps:
1. [x] Modify drawArmyWidgets signature to accept region
2. [x] Compute needed size, expand region if too small  
3. [x] Apply 20px edge padding
4. [x] Layout squads evenly within padded region
5. [x] Update callers to pass a region
