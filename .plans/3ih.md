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
- Build exclusion grid from nodes + edges (same as now)
- Iteration grid: cellSize / 8 resolution (fine grid)
- For each fine-grid cell:
  - For each type (biggest first):
    - Roll rng() < chance
    - If passes, check exclusion grid clear for that type's radius
    - If clear: place, mark occupied, break to next cell
- Result: big stuff placed first, small stuff fills remaining gaps, density emergent

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
   - Step 8: new algorithm (iterate fine grid, roll per type biggest-first)

3. map_scene.lua
   - Require decor_types
   - Remove local DECOR_TYPES/defineDecor/mountain def
   - enter: pass decorTypes = {"mountain"} instead of decorDefs
   - draw: use decor_types.get(d.decorType).draw(x,y)
