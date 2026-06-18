1. Add base helper `g.getMouseTargetEntity(commander)` in `src/g.lua`.
   - Convert mouse screen->world.
   - Search nearby entities with `health` and `team`.
   - Prefer hovered neutral targets under cursor only when no enemy is near that neutral.
   - Otherwise prefer closest valid enemy near cursor (fallback).

2. Update `src/ecs/systems/ai.lua` for `playerControlled` entities.
   - Keep WASD movement behavior untouched.
   - For player-controlled entity, set `_aiTarget` from `g.getMouseTargetEntity(ent)` each frame.
   - Clear `_aiTarget` when no valid mouse target.

3. Verify no regressions.
   - Read updated functions.
   - Check `git diff` for minimal scoped changes only.
