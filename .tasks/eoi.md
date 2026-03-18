# TASK: Add entity API to g.lua: defineEntityType, spawnEntity, drawEntity + storage/query

The army-roguelike needs an entity system. BattleField.lua already calls g.drawEntity. This task adds the entity definition/spawn/draw API to g.lua, modeled after catx11's pattern but simplified for the army game.
---

<plan>

Add a dead-simple entity API to src/g.lua, modeled after catx11's defineToken/defineEntity pattern.

CONTEXT:
- src/g.lua currently has empty stubs: g.defineUnit (line 145) and g.defineSquad (line 150).
- src/BattleField.lua already calls g.drawEntity(e, e.x, e.y) on line 21.
- BattleField stores entities in an objects.BufferedSet (line 7).
- objects.Partition exists for spatial queries (src/modules/objects/Partition.lua).
- catx11 pattern: defineEntity stores metatable in ENTITY_DEFS, spawnEntity creates table + setmetatable + calls init.

FILES TO MODIFY:
1. src/g.lua (main changes)
2. src/BattleField.lua (minor, add update loop + spatial query helpers)

STEP-BY-STEP FOR src/g.lua:

1. Add local storage tables after line 141 (after the 1x1 image block, before defineUnit):

   local ENTITY_DEFS = {}        -- type string -> metatable {__index=def}
   local ENTITY_LIST = {}        -- ordered list of type strings
   local currentEntityId = 0

2. Replace the empty g.defineUnit stub (lines 143-147) with g.defineEntityType:

   function g.defineEntityType(id, def)
       assert(not ENTITY_DEFS[id], "Duplicate entity type: " .. id)
       assert(def.x == nil and def.y == nil and def.type == nil, "x/y/type are reserved")
       def.type = id
       def.image = def.image or id
       local mt = {__index = def}
       ENTITY_DEFS[id] = mt
       ENTITY_LIST[#ENTITY_LIST+1] = id
   end

   Key fields on a def (all optional except what user provides):
   - image: string (defaults to id, used by drawEntity)
   - init: fun(ent, ...)
   - update: fun(ent, dt)
   - draw: fun(ent, x, y) -- custom draw override
   - drawOrder: number (for y-sorting in BattleField)
   - lifetime: number (if set, entity auto-removes when <= 0)
   - sx, sy, ox, oy, rot, alpha: draw params

3. Add g.spawnEntity right after defineEntityType:

   function g.spawnEntity(id, x, y, ...)
       local mt = ENTITY_DEFS[id]
       assert(mt, "Unknown entity type: " .. tostring(id))
       currentEntityId = currentEntityId + 1
       local ent = setmetatable({
           id = currentEntityId,
           x = x, y = y, type = id,
       }, mt)
       if ent.init then
           ent:init(...)
       end
       return ent
   end

   NOTE: spawnEntity does NOT auto-add to a battlefield. The caller does:
       local ent = g.spawnEntity("soldier", x, y)
       battlefield.entities:addBuffered(ent)
   This keeps it simple and decoupled.

4. Add g.drawEntity:

   function g.drawEntity(ent, x, y)
       local sx, sy = ent.sx or 1, ent.sy or 1
       if ent.draw then
           ent:draw(x, y)
           return
       end
       if ent.image then
           love.graphics.setColor(1, 1, 1, ent.alpha or 1)
           g.drawImage(ent.image, x + (ent.ox or 0), y + (ent.oy or 0), ent.rot or 0, sx, sy)
       end
   end

5. Add g.getEntityDef (for lookups):

   function g.getEntityDef(id)
       local mt = ENTITY_DEFS[id]
       return mt and mt.__index
   end

6. Remove or keep the empty g.defineUnit/g.defineSquad stubs. KEEP THEM for now
   since they may be used later. Just leave them as-is (lines 143-153).
   Insert the new entity code AFTER line 153 (after defineSquad).

STEP-BY-STEP FOR src/BattleField.lua:

1. Add an update method that handles lifetime + calls update:

   function BattleField:update(dt)
       for _, e in ipairs(self.entities) do
           if e.update then
               e:update(dt)
           end
           if e.lifetime then
               e.lifetime = e.lifetime - dt
               if e.lifetime <= 0 then
                   self.entities:removeBuffered(e)
               end
           end
       end
       self.entities:flush()
   end

2. Add entity spawn helper on BattleField:

   function BattleField:spawnEntity(id, x, y, ...)
       local ent = g.spawnEntity(id, x, y, ...)
       self.entities:addBuffered(ent)
       return ent
   end

3. Add entity removal helper:

   function BattleField:removeEntity(ent)
       self.entities:removeBuffered(ent)
   end

EDGE CASES / NOTES:
- g.drawEntity is called by BattleField:draw() already (line 21). The signature matches: g.drawEntity(e, e.x, e.y).
- No spatial partition in BattleField yet. Can add later if needed. Keep it simple for now.
- No g.isEntity needed yet. Can add trivially later.
- The defineUnit/defineSquad stubs stay untouched; they're separate concepts that may wrap defineEntityType later.

</plan>

<done_criteria>

1. search('function g.defineEntityType') matches in src/g.lua
2. search('function g.spawnEntity') matches in src/g.lua
3. search('function g.drawEntity') matches in src/g.lua
4. search('function g.getEntityDef') matches in src/g.lua
5. read_body('src/g.lua', 'g.defineEntityType') stores a metatable in ENTITY_DEFS keyed by id
6. read_body('src/g.lua', 'g.spawnEntity') calls setmetatable and calls init if present
7. read_body('src/g.lua', 'g.drawEntity') draws ent.image via g.drawImage OR calls ent:draw(x,y)
8. search('function BattleField:update') matches in src/BattleField.lua
9. read_body('src/BattleField.lua', 'BattleField:update') decrements e.lifetime and calls removeBuffered when <= 0
10. search('function BattleField:spawnEntity') matches in src/BattleField.lua
11. search('function BattleField:removeEntity') matches in src/BattleField.lua
12. read_body('src/BattleField.lua', 'BattleField:draw') still calls g.drawEntity(e, e.x, e.y)
13. g.defineUnit and g.defineSquad stubs still exist in src/g.lua: search('function g.defineUnit') matches

</done_criteria>

<log>
[2026-03-18T17:42:59Z] [CREATED] Add entity API to g.lua: defineEntityType, spawnEntity, drawEntity + storage/query
[2026-03-18T17:43:44Z] [PROGRESS] Plan written. 2 files: src/g.lua (add 4 functions), src/BattleField.lua (add 3 methods)
</log>


<meta>
status: open
created_at: 2026-03-18T17:42:59Z
</meta>
