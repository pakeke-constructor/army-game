


local encounters = {}


local enemyPool = {}

---@param difficulty integer
---@param spawn fun(es:g.EnemySpawner, ecs:ecs.ECSWorld)
function encounters.defineEnemyEncounter(difficulty, spawn)
    enemyPool[difficulty] = enemyPool[difficulty] or objects.Array()
    enemyPool[difficulty]:add(spawn)
end







---@class g.EnemySpawner: objects.Class
local EnemySpawner = objects.Class("g:EnemySpawner")

local SPACING = 25
local ROW_SIZE = 6

---@param ecs ecs.ECSWorld
---@param rng table
function EnemySpawner:init(ecs, rng)
    self._ecs = ecs
    self._rng = rng
    self._entries = {}
    -- spawn origin and facing direction
    self._x = nil
    self._y = nil
    self._dx = -1
    self._dy = 0
end


---@param id string entity type id
---@param count? number default 1
function EnemySpawner:add(id, count)
    count = count or 1
    for i = 1, count do
        self._entries[#self._entries + 1] = id
    end
end

function EnemySpawner:getECS()
    return self._ecs
end

function EnemySpawner:getRNG()
    return self._rng
end

---@param min? number
---@param max? number
function EnemySpawner:getRandom(min, max)
    if min and max then
        return self._rng:random(min, max)
    elseif min then
        return self._rng:random(min)
    end
    return self._rng:random()
end

function EnemySpawner:getSpawnPosition()
    return self._x, self._y
end

function EnemySpawner:getFaceDirection()
    return self._dx, self._dy
end

--- Spawns all queued enemies in formation.
--- Melee in front rows, ranged in back rows.
---@param ecs ecs.ECSWorld
function EnemySpawner:finalize(ecs)
    -- separate melee and ranged
    local melee, ranged = {}, {}
    for _, id in ipairs(self._entries) do
        local def = g.getEntityDef(id)
        if def and def.attack and def.attack.attackType == "ranged" then
            ranged[#ranged + 1] = id
        else
            melee[#melee + 1] = id
        end
    end

    -- melee first (closer to player), then ranged behind
    local ordered = {}
    for _, id in ipairs(melee) do ordered[#ordered + 1] = id end
    for _, id in ipairs(ranged) do ordered[#ordered + 1] = id end

    -- lay out in rows centered on spawn position. Sample random points inside
    -- the fog shape and pick the one furthest from the player's spawn (left-center).
    if not (self._x and self._y) then
        local bx, by, w, h = ecs.boundingBox[1], ecs.boundingBox[2], ecs.boundingBox[3], ecs.boundingBox[4]
        local playerX, playerY = bx + w / 4, by + h / 2
        local bestX, bestY, bestD
        for i = 1, 200 do
            local x = self._rng:random() * w + bx
            local y = self._rng:random() * h + by
            if ecs:isInsideShape(x, y) then
                local dx, dy = x - playerX, y - playerY
                local d = dx * dx + dy * dy
                if not bestD or d > bestD then
                    bestD, bestX, bestY = d, x, y
                end
            end
        end
        self._x = bestX or (bx + w * (2 / 3))
        self._y = bestY or (by + h * (2 / 5))
    end
    local ox, oy = self._x, self._y
    for i, id in ipairs(ordered) do
        local idx = i - 1
        local col = idx % ROW_SIZE
        local row = math.floor(idx / ROW_SIZE)
        local x = ox + (col - (ROW_SIZE - 1) / 2) * SPACING
        local y = oy + row * SPACING
        local ent = g.spawnEntity(id, x, y)
        ent.patrolX, ent.patrolY = x, y
    end

    self._entries = {}
end



---@param difficulty integer
---@param ecs ecs.ECSWorld
function encounters.startRandomEncounter(difficulty, ecs)
    local arr = enemyPool[difficulty]
    if not arr or #arr == 0 then
        arr = enemyPool[1]
    end
    local rng = love.math.newRandomGenerator(os.time())
    local spawn = arr[rng:random(1, #arr)]
    local es = EnemySpawner(ecs, rng)
    spawn(es, ecs)
    es:finalize(ecs)
end

return encounters


