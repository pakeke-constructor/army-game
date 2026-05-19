---
name: ecs
description: Use when working with entities, components, systems, spawning, physics, or the ECS world
---

Entities are plain tables with component fields. No class hierarchy — entity "type" comes from a metatable `__index` pointing to the def table. Components are just keys on the entity (e.g. `ent.physics`, `ent.ai`, `ent.attack`). ECSWorld holds all entities, rebuilds a component index every frame, and runs systems.

For component definitions and types, read `src/ecs/components.lua`. Combat stats have `base` prefixed versions (e.g. `baseMaxHealth`) — the stats system recomputes actual values from base + questions.


Defining entities:
`g.defineEntity(id, def)` registers an entity type. `def` is the prototype table (becomes `__index`). Reserved keys: `x`, `y`, `type`, `_world`. `image` defaults to `id` if omitted.
Gotcha: table-valued fields on the def (e.g. `traits`) are shared across all instances. Never mutate them at runtime.


Spawning:
- `g.spawnEntity(id, x, y, ...)` — creates entity from def, assigns unique `id`, adds to world, fires `entitySpawned`. Only works during battle.
- `g.spawnSquad(squad, x, y, ...)` — spawns all units in a squad with offset positions.


Entity base methods (defined in `src/ecs/Entity.lua`, mixed into all defs):
- `ent:getWorld()` — returns the ECSWorld.
- `ent:getDef()` — returns the prototype table.
- `ent:isOwn(key)` / `ent:isShared(key)` — whether a key is on the instance vs inherited from def.


ECSWorld API:
- `world:addEntity(e)` / `world:removeEntity(e)` — buffered add/remove, flushed during update.
- `world:iterate(componentName)` — iterate entities that have a given key. Returns `ipairs`-style iterator.
- `world:iteratePartition(partitionId, x, y, fn, range)` — spatial query. Partition ids: `unit`, `projectile`, `ally`, `enemy`.
- `world:setBorder(w, h)` — clamps entities with `team` inside bounds.
- `world.data` — shared data table (physics system stores Box2D world/bodies/fixtures here).


Update loop — `world:update(dt)` each frame:
1. Flush entity buffers, rebuild component index and spatial partitions.
2. Fire `preUpdate` event (systems run here: AI, attacking, physics, stats).
3. Integrate velocity for non-physics entities.
4. Apply knockback decay, gravity (`vz`), `_timeSinceDamaged` increment.
5. Call `ent:update(dt)` if it exists.
6. Decrement `ent.lifetime`; remove entity if expired.
7. Clamp entities inside border.
8. Fire `postUpdate` event.

Drawing — `world:draw()` sorts entities by `y - z/2 + (drawOrder or 0)`, then calls `g.drawEntity` for each.


Systems are plain tables of event/question handlers. Loaded by name in `ECSWorld:init({"ai", "attacking", "physics", "stats"})`. Scene calls `world:addSystemHandlers()` each frame to register them.

System hooks: `initECS`, `preUpdate`, `postUpdate`, `preDraw`, `postDraw`, `entityDeath`, `entitySpawned`, plus any custom event/question names.

Existing systems:
- ai — target selection, refreshed in batches.
- attacking — cooldowns, melee hits, projectile spawning. Contains `dealDamage` (blocks if ent has armor, fires `entityHurt`/`entityDeath`).
- physics — creates/destroys Box2D bodies, syncs positions each frame.
- stats — recomputes derived stats from base values via questions.


Physics: entities with a `physics` component get a Box2D body. Shape is `"circle"` (with `radius`) or `"rect"` (with `w`, `h`).

Gotcha: never set `ent.x`/`ent.y` directly on physics entities — the physics system overwrites them. Use `g.setPos(ent, x, y)` which syncs both the entity fields and the Box2D body.
- `g.setPos(ent, x, y)` — teleport entity (works for both physics and non-physics).
- `g.getVel(ent)` — returns effective velocity including knockback.


Scopes: `ent.scope` holds per-entity handlers/effects. Use `g.addCustomEffect(ent, handler, duration)` to add effects — it auto-promotes shared scopes so it only affects that entity.
