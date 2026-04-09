# Decor System — Mountains (and future trees, grass, etc.)

## Current state (partially applied stubs already in code)
Already present:
- MapGraph: self.decor = {} in init, decor field annotation, deleteNodesInRadius, forEachDecor, decor in ser/deser
- map_scene: DECOR_TYPES table, defineDecor function (empty mountain def)
NOT yet changed:
- MapGraph.generate step 4 still uses nodePruneChance (random node pruning)
- map_scene:enter still passes nodePruneChance, no decorList building
- map_scene:draw has no decor rendering

## Design
- MapGraph.generate keeps nodePruneChance for random node pruning (unchanged)
- After generation, decor is placed separately: scatter decor candidates randomly
- Use a spatial partition (grid) to reject decor that overlaps with:
  - Other decor (min spacing)
  - Nodes (buffer radius)
  - Edges (distance-to-segment check)
- Decor "slots into gaps" automatically — no node deletion, no decorPasses
- MapGraph stores decor as plain tables: {x, y, ox, oy, decorType} in self.decor (list)
- map_scene has a local DECOR_TYPES registry: decorType string -> draw function

## Changes needed

### MapGraph.lua
1. GenArgs: add decorDefs (list of {type, count, radius}) — radius = exclusion size for spatial check
2. generate: keep step 4 nodePruneChance as-is
3. generate: new step after pruning — place decor:
   - Build spatial grid from existing nodes + edges
   - For each decorDef, attempt to place `count` items randomly
   - Reject if spatial grid says too close to node, edge, or other decor
   - Accept → insert into self.decor and mark grid cell occupied
4. (already done: deleteNodesInRadius, forEachDecor, decor in init/ser/deser)

### map_scene.lua
1. (already done: DECOR_TYPES + defineDecor stub)
2. Fill in mountain defineDecor with placeholder draw
3. enter: pass decorDefs arg, build self.decorList from graph:forEachDecor, precompute world positions, sort by wy
4. draw: render decorList before edges
5. leave: clear self.decorList
