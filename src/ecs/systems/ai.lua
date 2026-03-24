
--[[
AI SYSTEM:
==========
Finds targets for entities with an `ai` component.
Moves entities toward their targets based on ai.range.

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

-- reused across frames
local _sortBuf = {}

-- returns squared distance
local function dist2(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return dx * dx + dy * dy
end

local function isValidTarget(ent)
    return ent.health and ent.health > 0
end

local function getOpposingSide(ent)
    if ent.ai.target == "enemy" then
        -- target the opposite side
        return ent.side == "ally" and "enemy" or "ally"
    else
        -- target same side (for healers etc)
        return ent.side
    end
end

-- Find the best target for `ent` from `candidates`
local function pickTarget(ent, candidates)
    local best, bestScore = nil, -math.huge
    local ai = ent.ai
    for i = 1, #candidates do
        local c = candidates[i]
        if isValidTarget(c) then
            local prio = ai.getPriority(ent, c)
            -- tiebreak: closer is better (subtract tiny distance factor)
            local d2 = dist2(ent, c)
            local score = prio - d2 * 0.00001
            if score > bestScore then
                best, bestScore = c, score
            end
        end
    end
    return best
end

local function staleSorter(a, b)
    return (a._lastTargetRefreshTime or STALE_DEFAULT) < (b._lastTargetRefreshTime or STALE_DEFAULT)
end

function aiSys.preUpdate(world, dt)
    -- build side lists
    local allies, enemies = {}, {}
    for _, ent in world:iterate("side") do
        if isValidTarget(ent) then
            if ent.side == "ally" then
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

    -- how many to re-target this frame (at least 1)
    local n = #_sortBuf
    local refreshCount = math.max(1, math.ceil(n * REFRESH_FRACTION))
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

        if not targ then
            ent.vx, ent.vy = 0, 0
            goto continue
        end

        local dx, dy = targ.x - ent.x, targ.y - ent.y
        local dist = (dx * dx + dy * dy) ^ 0.5
        local ai = ent.ai
        local minRange, maxRange = ai.range[1], ai.range[2]

        -- use attackRange if available (stat system computes it)
        if ent.attackRange then
            minRange = ent.attackRange * 0.7
            maxRange = ent.attackRange * 1
        end

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

        ::continue::
    end
end

return aiSys
