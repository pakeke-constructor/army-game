# Lazy component indexing in ECSWorld

## Goal
Only index components that are actually queried via `world:iterate(component)`.
Drop the per-frame eager full-rebuild over every key on every entity.

## Current behavior
- `_rebuildIndex` clears all componentIndex lists every frame.
- Walks every entity, every string key (own + inherited), pushes into idx[k].
- Also rebuilds spatial partitions in the same pass.
- Called once per frame from `update` (after flush).

## New behavior
- `self.trackedComponents = objects.Set()` — components seen by `iterate(c)`.
- `self.componentIndex[c]` exists iff c is in trackedComponents.
- Per frame: rebuild only tracked components' lists (cheap: O(tracked * entities), but skip components an entity doesn't have).
  - Actually simpler: walk entities once, for each tracked component check if entity has it, append.
- `iterate(component)`:
  - If component is tracked → return ipairs of cached list (already up to date for this frame).
  - If not tracked → add to trackedComponents, build the list now (one-time scan), return ipairs.
  - Subsequent same-frame calls return the same list.

## Partitions
- Still rebuilt eagerly. Leave as-is — separate pass from component indexing.
- Split `_rebuildIndex` into `_rebuildComponentIndex` and `_rebuildPartitions`.

## Code changes (ECSWorld.lua only)
1. `init`: add `self.trackedComponents = objects.Set()`.
2. Split `_rebuildIndex`:
   - `_rebuildPartitions`: just the partition loop.
   - `_rebuildComponentIndex`: for each tracked component name, clear its list; walk entities; check own key or inherited key; append.
3. `iterate(component)`:
   - If `componentIndex[component]` exists → return ipairs.
   - Else: track it, build list now (single pass), return ipairs.
4. `update`: call both rebuild functions (order: partitions + component index, before preUpdate as before).

## Helper: "does entity e have component k?"
- `rawget(e, k) ~= nil` OR (check `__index` chain — mirror current logic).
- Make a tiny local function `entHas(e, k)` reused in both `_rebuildComponentIndex` and the lazy build path.

## Edge cases
- Boolean false values: current code uses `pairs(e)`, which sees `k=false_val` keys. `rawget(e,k) ~= nil` matches that. OK.
- Removed entities: `self.entities:flush()` already drops them before rebuild. OK.
- `iterate` called mid-frame after entity added: BufferedSet only flushes on update. Same as current behavior — added entities aren't visible until next frame. OK.

## Not changing
- `iteratePartition`, `draw`, `update` body.
- Any callsite (signature unchanged).

## Risk
- Low. Same semantics, just lazy. All current callers pass a component name.
