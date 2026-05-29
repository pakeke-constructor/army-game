# Map-scene decor builder refactor

## Problem
- Currently `map_scene:draw()` sorts decor + nodes by y, then draws them in interleaved order.
- But each Node:draw also calls `g.drawImage` with arbitrary offsets (flags, demons, etc), bypassing y-sort.
- Result: inconsistent stacking (e.g. node flag rendered before a tree that should be in front).

## Solution
Replace `Node:draw(wx,wy)` with `Node:buildDecor(builder, wx, wy)`.
- Builder collects entries: {image, x, y, r, sx, sy}.
- Decor cell list also feeds builder (mountains/trees/grass).
- Builder finalize: sort all entries by y ascending, draw via `g.drawImageOffset(image, x, y, r, sx, 1, 0.5, 0.95)`.
- `oy = 0.95` is hardcoded inside builder draw — applies to ALL decor & node images consistently.
- sx flipping = if entry has `flip = true`, multiplied by -1. (Or builder stores `sx` directly; flipping is caller's choice.)
  Actually per request: "scaleX flipping should be implicit and automatic for all decor."
  → Builder draws each image with random/deterministic flip baked in. Caller doesn't pass sx; builder hashes (x,y) to flip 50%.
  → For Node images though, flipping was tied to `self.id%2`. We can use the same hash on (x,y) or pass a `noFlip` opt for things that shouldn't flip (combat ellipse circles — but those aren't images anyway).
  → Decision: builder always auto-flips by hash(x,y). Node:buildDecor adds via `builder:add(image, x, y)` — no sx arg.
  → Demons + flag also auto-flip.

## Non-image draws
Some nodes draw ellipses (BattleNode, EmptyNode). These don't need y-sorting beyond their wx,wy.
Approach: builder supports `builder:addCustom(y, func)` for arbitrary draws (rare), OR call them in a "ground" pass before decor.
Simpler: keep ellipse "ground" draws separate (drawn before sorted decor pass).
→ Add `Node:drawGround(wx, wy)` for the ellipse "shadow" stuff. Already similar to existing `Node:drawBelow`.
→ Rename `drawBelow` semantics to `drawGround` OR keep `drawBelow` and add `buildDecor`. Use `drawBelow` since it already exists but isn't used by anyone currently. Move ellipses into `drawBelow`.

## API
```lua
local DecorBuilder = Class("g:DecorBuilder")
function DecorBuilder:init()
    self.items = {}
end
function DecorBuilder:add(image, x, y, r, opacity)
    self.items[#self.items+1] = {image=image, x=x, y=y, r=r or 0, opacity=opacity or 1}
end
function DecorBuilder:finalize()
    table.sort(self.items, function(a,b) return a.y < b.y end)
    for _, it in ipairs(self.items) do
        local sx = (hash(it.x, it.y) % 2 == 0) and -1 or 1
        love.graphics.setColor(1,1,1,it.opacity)
        g.drawImageOffset(it.image, it.x, it.y, it.r, sx, 1, 0.5, 0.95)
    end
end
```

## Changes
1. Create `src/scenes/map_scene/DecorBuilder.lua` (small class, ~30 lines).
2. `nodes.lua`:
   - Remove `Node:draw`. Add `Node:buildDecor(builder, wx, wy)` (no-op default).
   - Move ellipse stuff to `Node:drawBelow(wx, wy)` (already exists).
   - BattleNode: drawBelow = ellipses; buildDecor = flag + demons.
   - FeastNode: buildDecor = banquet + demons.
   - FountainNode: buildDecor = fountain + demons.
   - EmptyNode: drawBelow = ellipses; no buildDecor.
   - ShopNode: buildDecor = town.
   - `tryDrawDemons` becomes `addDemons(node, builder, x, y)`.
3. `map_scene.lua draw()`:
   - Pass 1: edges (already drawn).
   - Pass 2: for each node, call drawBelow.
   - Pass 3: build a DecorBuilder. Add all map decor cells. Add all node buildDecor. Finalize.
   - Player-path hover still drawn after.

## Removing scaleX from caller
- FeastNode and ShopNode used `id%2` for flipping — that disappears, builder hashes by (x,y) instead.
- Town flips deterministically, fine.
- For images that should NEVER flip (e.g. if any), add `builder:addNoFlip(image, x, y, r)`. Don't add until needed.
