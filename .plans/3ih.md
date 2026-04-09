# Decor System — Refactor placement

## Current state
- MapGraph.generate step 8 places decor using decorDefs (type/count/radius per entry)
- map_scene passes decorDefs = {{ type="mountain", count=80, radius=40 }}
- defineDecor in map_scene only has id + drawFn

## New design

### Shared decor registry (new file: src/scenes/map_scene/decor_types.lua)
Move DECOR_TYPES + defineDecor out of map_scene into shared module.
MapGraph.generate and map_scene both require it.

defineDecor(id, {
    radius = 40,     -- exclusion radius
    chance = 0.05,   -- per-cell roll
    draw = func,     -- draw(wx, wy)
    image = nil,     -- if set, used instead of draw
})

### Placement algorithm (MapGraph.generate step 8)
- GenArgs.decorTypes = {"mountain", "tree", ...} — just a list of type names
- Lookup each from registry, sort by radius descending
- One fine grid (cellSize = sp / 8 roughly). Used for BOTH iteration and exclusion.
- Mark exclusion: nodes mark cells within nodeRadius. Edges sample points and mark cells within edgeRadius.
  Big decor (radius=40) marks many fine cells. Small decor (radius=10) marks few cells.
  This means small decor can squeeze into tight gaps between nodes/edges/big decor.
- Iterate every fine-grid cell:
  - For each type (biggest radius first):
    - Roll rng() < chance
    - Check all fine-grid cells within type's radius are clear
    - If clear: place decor, mark cells within radius as occupied, break to next cell
- Result: dense, messy map. Big stuff placed first claims space. Small stuff fills remaining gaps.

### map_scene changes
- Remove DECOR_TYPES / defineDecor from map_scene
- Require decor_types module
- defineDecor("mountain", ...) moves to decor_types.lua
- draw loop uses registry lookup for draw/image

### Changes needed

1. Create src/scenes/map_scene/decor_types.lua
   - DECOR_TYPES table, defineDecor, getDecorType, getDecorTypesSortedByRadius
   - defineDecor("mountain", { radius=40, chance=0.05, draw=func })

2. MapGraph.lua
   - Require decor_types
   - GenArgs: replace decorDefs with decorTypes (list of strings)
   - Step 8: new algorithm — single fine grid, iterate cells, roll per type biggest-first

3. map_scene.lua
   - Require decor_types
   - Remove local DECOR_TYPES/defineDecor/mountain def
   - enter: pass decorTypes = {"mountain"} instead of decorDefs
   - draw: use decor_types.get(d.decorType).draw(x,y)
