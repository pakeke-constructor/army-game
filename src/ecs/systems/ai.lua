
--[[
AI SYSTEM:
==========
Finds targets for entities with an `ai` component.
Moves entities toward their targets based on attackRange.

Each frame:
1. Pick the best target (by priority, then distance).
2. If too far, move toward it. If close enough, stop.
3. Store the target on ent._aiTarget for the attack system to use.

Targeting is amortized: only ~5% of entities re-target per frame,
sorted by staleness (_lastTargetRefreshTime).

Entities need: ai, side, x, y, moveSpeed
]]

local table_clear = require("table.clear")

local aiSys = {}

local REFRESH_FRACTION = 0.05 -- re-target 5% of ents per frame
local STALE_DEFAULT = -1000   -- never-targeted ents sort first

local PATROL_RADIUS = 40
local PATROL_PAUSE_MIN = 1.5
local PATROL_PAUSE_MAX = 3.5
local PATROL_ARRIVE_DIST = 4

-- reused across frames
local _sortBuf = {}

-- returns squared distance
local function dist2(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return dx * dx + dy * dy
end

local function isValidTarget(ent)
    return g.isAlive(ent)
end

local function getOpposingSide(ent)
    if ent.ai.target == "enemy" then
        -- target the opposite side
        return ent.team == "ally" and "enemy" or "ally"
    else
        -- target same side (for healers etc)
        return ent.team
    end
end

local function zero(ent, c)
    return 0
end

local function missingHealthPriority(ent, c)
    local maxHealth = c.maxHealth or c.health or 0
    local missing = maxHealth - (c.health or 0)
    return math.max(0, missing)
end


-- Find the best target for `ent` from `candidates`
local function pickTarget(ent, candidates)
    local best, bestScore = nil, -math.huge
    local ai = ent.ai
    local curTarget = ent._aiTarget
    for i = 1, #candidates do
        local c = candidates[i]
        if isValidTarget(c) then
            local getPrio = ai.getPriority
            if not getPrio then
                if (ent.healPower or 0) > 0 then
                    getPrio = missingHealthPriority
                else
                    getPrio = zero
                end
            end
            local prio = getPrio(ent, c)
            -- tiebreak: closer is better (subtract tiny distance factor)
            local d2 = dist2(ent, c)
            -- deterministic per-pair noise for stable tie-breaking
            local noise = (helper.hashInteger(ent.id * 1000 + c.id) % 1000) / 1000 * 0.5
            local score = prio - d2 * 0.00001 + noise
            -- bias toward keeping current target
            if c == curTarget then
                score = score + 1
            end
            if score > bestScore then
                best, bestScore = c, score
            end
        end
    end
    return best
end

local function updatePatrol(ent, dt)
    if not ent._patrolInited then
        ent._patrolInited = true
        local t = (helper.hashInteger(ent.id) % 1000) / 1000
        ent._patrolPauseTime = t * PATROL_PAUSE_MAX
    end
    if ent._patrolPauseTime and ent._patrolPauseTime > 0 then
        ent._patrolPauseTime = ent._patrolPauseTime - dt
        ent.vx, ent.vy = 0, 0
        return
    end
    local tx, ty = ent._patrolTargetX, ent._patrolTargetY
    if not tx then
        local a = love.math.random() * math.pi * 2
        local r = love.math.random() * PATROL_RADIUS
        ent._patrolTargetX = ent.patrolX + math.cos(a) * r
        ent._patrolTargetY = ent.patrolY + math.sin(a) * r
        tx, ty = ent._patrolTargetX, ent._patrolTargetY
    end
    local dx, dy = tx - ent.x, ty - ent.y
    local dist = (dx * dx + dy * dy) ^ 0.5
    if dist < PATROL_ARRIVE_DIST then
        ent._patrolTargetX, ent._patrolTargetY = nil, nil
        ent._patrolPauseTime = PATROL_PAUSE_MIN + love.math.random() * (PATROL_PAUSE_MAX - PATROL_PAUSE_MIN)
        ent.vx, ent.vy = 0, 0
        return
    end
    local speed = (ent.moveSpeed or 60) * 0.6
    ent.vx = dx / dist * speed
    ent.vy = dy / dist * speed
end

local function staleSorter(a, b)
    return (a._lastTargetRefreshTime or STALE_DEFAULT) < (b._lastTargetRefreshTime or STALE_DEFAULT)
end

function aiSys.preUpdate(dt)
    local world = g.getECS()
    -- build side lists
    local allies, enemies = {}, {}
    for _, ent in world:iterate("team") do
        if isValidTarget(ent) then
            if ent.team == "ally" then
                allies[#allies + 1] = ent
            else
                enemies[#enemies + 1] = ent
            end
        end
    end

    -- collect ai ents, sort by staleness
    table_clear(_sortBuf)
    for _, ent in world:iterate("ai") do
        table.insert(_sortBuf, ent)
    end

    table.sort(_sortBuf, staleSorter)

    -- how many to re-target this frame
    local n = #_sortBuf
    local refreshCount = math.max(10, math.ceil(n * REFRESH_FRACTION))
    local now = love.timer.getTime()

    for i = 1, n do
        local ent = _sortBuf[i]

        -- re-target only the stalest entities
        if i <= refreshCount then
            local targetSide = getOpposingSide(ent)
            local candidates = targetSide == "ally" and allies or enemies
            ent._aiTarget = pickTarget(ent, candidates)
            ent._lastTargetRefreshTime = now
        end

        -- clear target if it died
        local targ = ent._aiTarget
        if targ and not isValidTarget(targ) then
            targ = nil
            ent._aiTarget = nil
        end

        if ent.taunt then
            local tauntEnt = ent.taunt.ent
            if tauntEnt and isValidTarget(tauntEnt) then
                targ = tauntEnt
                ent._aiTarget = tauntEnt
            end
        end

        -- frozen: can't move
        if ent.frozenTime and ent.frozenTime > 0 then
            ent.vx, ent.vy = 0, 0
            goto continue
        end

        if not targ then
            if ent.team == "enemy" and ent.patrolX then
                updatePatrol(ent, dt)
            else
                ent.vx, ent.vy = 0, 0
            end
            goto continue
        end

        local dx, dy = targ.x - ent.x, targ.y - ent.y
        local dist = (dx * dx + dy * dy) ^ 0.5
        local attackRange = ent.attackRange or 100
        local minRange = attackRange * 0.7
        local maxRange = attackRange

        local moving = ent._aiMoving

        -- hysteresis: start moving if beyond maxRange, stop if within minRange
        if dist > maxRange then
            moving = true
        elseif dist <= minRange then
            moving = false
        end
        ent._aiMoving = moving

        if moving and dist > 1 then
            local speed = ent.moveSpeed or 60
            local nx, ny = dx / dist, dy / dist
            ent.vx = nx * speed
            ent.vy = ny * speed
        else
            ent.vx, ent.vy = 0, 0
        end

        -- face toward target (covers both moving and attacking)
        local newFace = dx > 5 and -1 or dx < -5 and 1 or nil
        if newFace and newFace ~= ent.faceDir and now - (ent._faceDirTime or 0) > 1.5 then
            ent.faceDir = newFace
            ent._faceDirTime = now
        end

        ::continue::
    end
end

return aiSys
