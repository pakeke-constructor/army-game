


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
-- how far behind its chosen melee squad a ranged squad sits
local RANGED_BACK_OFFSET = 80
-- vertical margin so squads don't spawn right on the edge
local VERTICAL_MARGIN = 60
-- horizontal inset of the enemy front line from the left edge of enemyRectangle
local HORIZONTAL_MARGIN = 60

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

--- Spawns one squad's units in a square grid centered on (cx, cy).
function EnemySpawner:_spawnSquad(squad, cx, cy)
    local cols, rows = helper.getBestFitDimensions(squad.count, 1, 1)
    for i = 1, squad.count do
        local idx = i - 1
        local col = idx % cols
        local row = math.floor(idx / cols)
        local x = cx + (col - (cols - 1) / 2) * SPACING
        local y = cy + (row - (rows - 1) / 2) * SPACING
        x, y = self._ecs:clampToShape(x, y)
        local ent = g.spawnEntity(squad.id, x, y)
        ent.faceDir = -1
        ent.patrolX, ent.patrolY = x, y
    end
end

--- Lays out all queued squads into formation and spawns them.
--- Enemies always spawn opposite the player, in the right two-thirds
--- of the battlefield (see battle_scene, which puts allies in the left third).
function EnemySpawner:finalize()
    local ecs = self._ecs
    if not ecs.boundingBox then ecs:setBounds(300, 200, 1300, 600) end -- encounter forgot to set bounds
    local bx, by, w, h = ecs.boundingBox[1], ecs.boundingBox[2], ecs.boundingBox[3], ecs.boundingBox[4]

    -- lay enemies out into the enemy rectangle battle_scene set up.
    local enemyR = ecs.enemyRectangle
    if not enemyR then
        error("Enemy rectangle not set before encounter starts")
    end

    -- vertical line the army lays out along, near the left edge of enemyR
    local enemyX = enemyR.x + HORIZONTAL_MARGIN
    local lineTop = enemyR.y + VERTICAL_MARGIN
    local lineBottom = enemyR.y + enemyR.h - VERTICAL_MARGIN

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

    local fury = g.getRun().demonFury or 0
    local cx, cy = bx + w / 2, by + h / 2
    for i = 1, fury do
        local angle = (i - 1) / fury * math.pi * 2
        g.spawnEntity("demon_head", cx + math.cos(angle) * 80, cy + math.sin(angle) * 80)
    end
end



--- Runs a chosen encounter's spawn fn against a fresh EnemySpawner.
---@param spawn fun(es:g.EnemySpawner, ecs:ecs.ECSWorld)
---@param ecs ecs.ECSWorld
---@param setupRectangles? fun(border:number[])
local function runEncounter(spawn, ecs, setupRectangles)
    local rng = love.math.newRandomGenerator(os.time())
    local es = EnemySpawner(ecs, rng)
    spawn(es, ecs) -- sets bounds + queues squads (no spawning yet)
    if setupRectangles then setupRectangles(ecs.boundingBox) end
    es:finalize() -- lays enemies out into ecs.enemyRectangle
end

---@param difficulty integer
---@param ecs ecs.ECSWorld
---@param setupRectangles? fun(border:number[]) called after bounds are set, before enemies spawn
function encounters.startRandomEncounter(difficulty, ecs, setupRectangles)
    local arr = enemyPool[difficulty]
    if not arr or #arr == 0 then
        arr = enemyPool[1]
    end
    runEncounter(arr[love.math.random(1, #arr)], ecs, setupRectangles)
end

--- Spawns one specific encounter (by definition order within its difficulty).
--- Dev/balancing only. Returns how many encounters exist at that difficulty.
---@param difficulty integer
---@param index integer 1-based, in file definition order
---@param ecs ecs.ECSWorld
---@param setupRectangles? fun(border:number[])
function encounters.startEncounterAt(difficulty, index, ecs, setupRectangles)
    local arr = enemyPool[difficulty]
    if not arr or #arr == 0 then error("no encounters at difficulty " .. tostring(difficulty)) end
    local spawn = arr[index]
    if not spawn then error("no encounter #" .. tostring(index) .. " at difficulty " .. tostring(difficulty)) end
    runEncounter(spawn, ecs, setupRectangles)
    return #arr
end

return encounters



