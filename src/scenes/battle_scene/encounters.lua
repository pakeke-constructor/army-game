


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
local ROW_SIZE = 5
-- how far behind its chosen melee squad a ranged squad sits
local RANGED_BACK_OFFSET = 80
-- vertical margin so squads don't spawn right on the edge
local VERTICAL_MARGIN = 60

---@param ecs ecs.ECSWorld
---@param rng table
function EnemySpawner:init(ecs, rng)
    self._ecs = ecs
    self._rng = rng
    ---@type {id:string, count:integer, kind:string}[]
    self._squads = {}
end


--- Queues a squad of `count` enemies of type `id`.
---@param id string entity type id
---@param count? number default 1
function EnemySpawner:add(id, count)
    count = count or 1
    local def = g.getEntityDef(id)
    local kind = "melee"
    if def and def.attack and def.attack.attackType == "ranged" then
        kind = "ranged"
    end
    -- TODO: detect buildings and set kind = "building"
    self._squads[#self._squads + 1] = {id = id, count = count, kind = kind}
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

--- Spawns one squad's units clumped around (cx, cy).
function EnemySpawner:_spawnSquad(squad, cx, cy)
    for i = 1, squad.count do
        local idx = i - 1
        local col = idx % ROW_SIZE
        local row = math.floor(idx / ROW_SIZE)
        local x = cx + (col - (ROW_SIZE - 1) / 2) * SPACING
        local y = cy + (row - 0.5) * SPACING
        x, y = self._ecs:clampToShape(x, y)
        local ent = g.spawnEntity(squad.id, x, y)
        ent.patrolX, ent.patrolY = x, y
    end
end

--- Lays out all queued squads into formation and spawns them.
--- Enemies always spawn opposite the player, on a vertical line
--- ENEMY_ARMY_HORIZONTAL_SPAWN_DISTANCE units to the right of the player spawn.
function EnemySpawner:finalize()
    local ecs = self._ecs
    local bx, by, w, h = ecs.boundingBox[1], ecs.boundingBox[2], ecs.boundingBox[3], ecs.boundingBox[4]

    -- player spawns at left-center (see battle_scene)
    local playerX = bx + w / 4
    local enemyX = playerX + consts.ENEMY_ARMY_HORIZONTAL_SPAWN_DISTANCE

    -- vertical line the army lays out along
    local lineTop = by + VERTICAL_MARGIN
    local lineBottom = by + h - VERTICAL_MARGIN

    -- split squads by role
    local melee, ranged, buildings = {}, {}, {}
    for _, sq in ipairs(self._squads) do
        if sq.kind == "ranged" then
            ranged[#ranged + 1] = sq
        elseif sq.kind == "building" then
            buildings[#buildings + 1] = sq
        else
            melee[#melee + 1] = sq
        end
    end

    -- melee squads: each gets a random spot on the vertical line
    for _, sq in ipairs(melee) do
        sq.x = enemyX
        sq.y = lineTop + self._rng:random() * (lineBottom - lineTop)
        self:_spawnSquad(sq, sq.x, sq.y)
    end

    -- ranged squads: sit behind a random melee squad (further from player)
    for _, sq in ipairs(ranged) do
        local cx, cy
        if #melee > 0 then
            local host = melee[self._rng:random(1, #melee)]
            cx = host.x + RANGED_BACK_OFFSET
            cy = host.y
        else
            cx = enemyX
            cy = lineTop + self._rng:random() * (lineBottom - lineTop)
        end
        self:_spawnSquad(sq, cx, cy)
    end

    -- TODO: place buildings at the very back of the formation
    for _, sq in ipairs(buildings) do
        self:_spawnSquad(sq, enemyX + RANGED_BACK_OFFSET * 2, lineTop + self._rng:random() * (lineBottom - lineTop))
    end

    self._squads = {}
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
    es:finalize()
end

return encounters



