# Two-grid decor placement

## What
Split single `occupied` grid into two independent grids:
- `nodeGrid`: nodes + edges only (never changes during decor placement)
- `decorGrid`: decor exclusion zones only (grows as decor is placed)

A decor is placed only if BOTH grids are clear at its position.

## decor_types.lua changes
- Rename `radius` field to `nodeRadius` (clearance from nodes/edges)
- Add `decorRadius` field (clearance from other decor)
- Update all 3 defines: mountain_large, tree_large_1, tree_small_1
- (decorRadius can be small for trees → bunching. nodeRadius stays large → no overlap with paths)

## MapGraph.lua step 8 changes (lines 271-356)

Replace single `occupied` grid with `nodeGrid` and `decorGrid`.
Replace single `markRadius`/`isRadiusClear` with grid-parameterized versions:
```
local function markGrid(grid, wx, wy, r) ... end
local function isGridClear(grid, wx, wy, r) ... end
```

- Mark nodes/edges into `nodeGrid` (same as now)
- `decorGrid` starts empty
- Placement check: `isGridClear(nodeGrid, wx, wy, dtype.nodeRadius) and isGridClear(decorGrid, wx, wy, dtype.decorRadius)`
- On place: `markGrid(decorGrid, wx, wy, dtype.decorRadius)` (nodeGrid untouched)

## getSortedByRadius
- Sort by `nodeRadius` descending (biggest nodeRadius first)

## Result
- Trees with small decorRadius bunch together (forest clumps)
- Trees with large nodeRadius still avoid nodes/edges
- Mountains with large both stay sparse and away from everything
