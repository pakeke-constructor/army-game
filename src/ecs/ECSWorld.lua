local objects = require("src.modules.objects.objects")
local table_clear = require("table.clear")
local PixelCanvas = require("src.modules.PixelCanvas")

---@class ecs.ECSWorld: objects.Class
---@field public data table<string, any>
local ECSWorld = objects.Class("ecs:ECSWorld")


---@class ecs.System
---@field public ecs ecs.ECSWorld


local PARTITION_CHUNKSIZE = 32

local ALLY_RECT_COLOR = g.snapToPalette(0.3, 1, 0.3)
local ENEMY_RECT_COLOR = g.snapToPalette(1, 0.3, 0.3)

function ECSWorld:init(systemNames)
    ---@type objects.BufferedSet<ecs.Entity>
    self.entities = objects.BufferedSet()

    self.data = {} -- system-storage

    self.backCanvas = PixelCanvas.new(love.graphics.getDimensions())
    self.frontCanvas = PixelCanvas.new(love.graphics.getDimensions())
    self.boundingBox = nil -- {x, y, w, h} or nil for no bounds
    self.allyRectangle = nil -- {x,y,w,h}: region allies may deploy into
    self.enemyRectangle = nil -- {x,y,w,h}: region enemies spawn into

    self.componentIndex = {} -- [componentName] -> {ent, ent, ...}
    self.trackedComponents = objects.Set()
    ---@type ecs.Entity[]
    self.allyList = {}
    ---@type ecs.Entity[]
    self.enemyList = {}
    ---@type table<string, objects.Partition<ecs.Entity>>
    self.partitions = {
        -- [partitionId] -> objects.Partition<ecs.Entity>
        unit = objects.Partition(PARTITION_CHUNKSIZE),
        neutral = objects.Partition(PARTITION_CHUNKSIZE),
        projectile = objects.Partition(PARTITION_CHUNKSIZE),
        ally = objects.Partition(PARTITION_CHUNKSIZE),
        enemy = objects.Partition(PARTITION_CHUNKSIZE)
    }

    ---@type ecs.Entity? cached commander, refreshed each update
    self._commander = nil

    self.allyDeathsThisBattle = 0
    self.enemyDeathsThisBattle = 0

    self.secondTimer = 0
    self.secondCount = 0

    -- Load systems (each system is a plain table of event/question handlers)
    self.systems = {}
    for _, name in ipairs(systemNames or {}) do
        self.systems[#self.systems + 1] = require("src.ecs.systems." .. name)
    end

    -- Call initECS directly on systems (before pollHandlers has run)
    for i = 1, #self.systems do
        if self.systems[i].initECS then
            self.systems[i].initECS(self)
        end
    end
end

---@param x number
---@param y number
---@param w number
---@param h number
function ECSWorld:setBounds(x, y, w, h)
    self.boundingBox = {x, y, w, h}
end

-- Bridging rect filling the horizontal gap between allyRectangle and
-- enemyRectangle (if any). nil if either is missing or they don't have a gap.
---@return {x:number,y:number,w:number,h:number}?
function ECSWorld:recalculateBridgeRectangle()
    local a, e = self.allyRectangle, self.enemyRectangle
    if not (a and e) then self.bridgeRectangle = nil; return nil end
    local midX = a.x + a.w
    local midW = e.x - midX
    if midW <= 0 then self.bridgeRectangle = nil; return nil end
    local midH = (a.h + e.h) / 2
    local midCY = ((a.y + a.h / 2) + (e.y + e.h / 2)) / 2
    self.bridgeRectangle = {x = midX, y = midCY - midH / 2, w = midW, h = midH}
    self._shape = nil -- invalidate cached shape
end

---@param x number
---@param y number
---@param w number
---@param h number
function ECSWorld:setAllyRectangle(x, y, w, h)
    self.allyRectangle = {x = x, y = y, w = w, h = h}
    self._shape = nil -- invalidate cached shape
    self:recalculateBridgeRectangle()
end

---@param x number
---@param y number
---@param w number
---@param h number
function ECSWorld:setEnemyRectangle(x, y, w, h)
    self.enemyRectangle = {x = x, y = y, w = w, h = h}
    self._shape = nil -- invalidate cached shape
    self:recalculateBridgeRectangle()
end

-- Bridging rect filling the horizontal gap between allyRectangle and
-- enemyRectangle (if any). nil if either is missing or they don't have a gap.
---@return {x:number,y:number,w:number,h:number}?
function ECSWorld:getBridgeRectangle()
    if not self.bridgeRectangle then
        self:recalculateBridgeRectangle()
    end
    return self.bridgeRectangle
end

-- The world's playable area: union of allyRectangle, enemyRectangle, and the
-- bridging rect between them.
---@return {x:number,y:number,w:number,h:number}[]
function ECSWorld:recalculateUnionShape()
    local shape = {}
    local n = 0
    local a, e = self.allyRectangle, self.enemyRectangle
    if a then n = n + 1; shape[n] = a end
    if e then n = n + 1; shape[n] = e end
    local mid = self:getBridgeRectangle()
    if mid then n = n + 1; shape[n] = mid end
    self._shape = shape
    return shape
end

-- The world's playable area: union of allyRectangle, enemyRectangle, and the
-- bridging rect between them.
---@return {x:number,y:number,w:number,h:number}[]
function ECSWorld:getShape()
    if self._shape == nil then
        self:recalculateUnionShape()
    end
    return self._shape
end

---@param r {x:number,y:number,w:number,h:number}
---@param margin? number grows the rect outward by this much (negative shrinks)
local function rectContains(r, x, y, margin)
    margin = margin or 0
    return x >= r.x - margin and x <= r.x + r.w + margin
        and y >= r.y - margin and y <= r.y + r.h + margin
end

---@param margin? number grows the shape outward by this much (negative shrinks)
---@return boolean
function ECSWorld:isInsideShape(x, y, margin)
    local shape = self:getShape()
    if #shape == 0 then return true end
    for i = 1, #shape do
        if rectContains(shape[i], x, y, margin) then return true end
    end
    return false
end

---@param r {x:number,y:number,w:number,h:number}
---@param margin number
---@return number cx, number cy, number rad
local function circleFromRect(r, margin)
    local cx, cy = r.x + r.w / 2, r.y + r.h / 2
    local rad = (r.w + r.h) / 4 + margin
    return cx, cy, rad
end

local function inCircle(x, y, cx, cy, rad)
    local dx, dy = x - cx, y - cy
    return dx * dx + dy * dy <= rad * rad
end

-- Same as isInsideShape, but blobby: ally/enemy/bridge rects are each
-- approximated by a circle at their center (radius = average of width/height
-- + margin). Two extra circles sit right on the ally-bridge and
-- bridge-enemy borders (radius = average of the two neighboring circles'
-- radii) so those seams round off too, instead of just each rect's own
-- center. Cheap: at most 5 dx*dx+dy*dy <= rad*rad checks, no sqrt.
-- Purely a visual softener (eg. fog edges) -- gameplay code should keep using
-- the sharp-cornered isInsideShape/clampToShape.
---@param margin? number grows every circle's radius by this much
---@return boolean
function ECSWorld:isInsideShapeRounded(x, y, margin)
    margin = margin or 0
    local a, e = self.allyRectangle, self.enemyRectangle
    if not a and not e then return true end

    local acx, acy, arad
    if a then
        acx, acy, arad = circleFromRect(a, margin)
        if inCircle(x, y, acx, acy, arad) then return true end
    end

    local ecx, ecy, erad
    if e then
        ecx, ecy, erad = circleFromRect(e, margin)
        if inCircle(x, y, ecx, ecy, erad) then return true end
    end

    local mid = self:getBridgeRectangle()
    if mid then
        local mcx, mcy, mrad = circleFromRect(mid, margin)
        if inCircle(x, y, mcx, mcy, mrad) then return true end

        -- ally-bridge border: circle centered exactly on the shared edge
        if inCircle(x, y, mid.x, (acy + mcy) / 2, (arad + mrad) / 2) then return true end
        -- bridge-enemy border: circle centered exactly on the shared edge
        if inCircle(x, y, mid.x + mid.w, (mcy + ecy) / 2, (mrad + erad) / 2) then return true end
    end

    return false
end

---@return integer
function ECSWorld:getNumOverlappingShapes(x, y)
    local shape = self:getShape()
    local count = 0
    for i = 1, #shape do
        if rectContains(shape[i], x, y) then count = count + 1 end
    end
    return count
end

-- Returns x,y clamped to the nearest point inside/on rect r.
---@param r {x:number,y:number,w:number,h:number}
function ECSWorld:clampToRect(r, x, y)
    return helper.clamp(x, r.x, r.x + r.w), helper.clamp(y, r.y, r.y + r.h)
end

-- Returns x,y clamped to the nearest point inside/on the shape.
function ECSWorld:clampToShape(x, y)
    local shape = self:getShape()
    if #shape == 0 or self:isInsideShape(x, y) then return x, y end
    local bestX, bestY, bestD
    for i = 1, #shape do
        local px, py = self:clampToRect(shape[i], x, y)
        local dist = (px - x) * (px - x) + (py - y) * (py - y)
        if not bestD or dist < bestD then
            bestD, bestX, bestY = dist, px, py
        end
    end
    return bestX, bestY
end

---@param e ecs.Entity
function ECSWorld:addEntity(e)
    self.entities:addBuffered(e)
end

---@param e ecs.Entity
function ECSWorld:removeEntity(e)
    e.___removed = true
    self.entities:removeBuffered(e)
end

---@param e ecs.Entity
local function entHas(e, k)
    if rawget(e, k) ~= nil then return true end
    local mt = getmetatable(e)
    local base = mt and rawget(mt, "__index")
    return type(base) == "table" and base[k] ~= nil
end

function ECSWorld:_rebuildComponentIndex()
    local idx = self.componentIndex
    for _, list in pairs(idx) do
        table_clear(list)
    end
    local tracked = self.trackedComponents
    for ti = 1, tracked.len do
        local k = tracked[ti]
        local list = idx[k]
        for i = 1, self.entities.len do
            local e = self.entities[i]
            if entHas(e, k) and not (e.___dead or e.___removed) then
                list[#list + 1] = e
            end
        end
    end
end

function ECSWorld:_rebuildPartitions()
    for _, part in pairs(self.partitions) do
        part:clear()
    end
    for i = 1, self.entities.len do
        local e = self.entities[i]
        local p = e.partitions
        if p then
            for j = 1, #p do
                local pid = p[j]
                local part = self.partitions[pid]
                if not part then
                    error("Unknown partition: " .. tostring(pid))
                end
                part:add(e, e.x, e.y)
            end
        end
    end
end

function ECSWorld:_rebuildTeamLists()
    table_clear(self.allyList)
    table_clear(self.enemyList)
    for i = 1, self.entities.len do
        local e = self.entities[i]
        if g.isAlive(e) then
            if e.team == "ally" then
                self.allyList[#self.allyList + 1] = e
            elseif e.team == "enemy" then
                self.enemyList[#self.enemyList + 1] = e
            end
        end
    end
end

function ECSWorld:addSystemHandlers()
    for i = 1, #self.systems do
        g.addHandler(self.systems[i])
    end
    g.addHandler({
        getEntityScale = function(ent)
            if ent.maxHealth and ent.baseMaxHealth then
                return (ent.maxHealth / ent.baseMaxHealth) ^ 0.35
            end
        end
    })
end

function ECSWorld:update(dt)
    g.setCurrentECS(self)
    self.entities:flush()
    self:_rebuildPartitions()
    self:_rebuildComponentIndex()
    self:_rebuildTeamLists()
    self:recalculateBridgeRectangle()
    self:recalculateUnionShape()
    g.call("preUpdate", dt)
    self._commander = nil
    for i = 1, self.entities.len do
        local e = self.entities[i]
        if e.isCommander then self._commander = e end
        if not e.physics then
            local vx, vy = g.getVel(e)
            if vx ~= 0 then e.x = e.x + vx * dt end
            if vy ~= 0 then e.y = e.y + vy * dt end
        end
        if e._knockVx then
            local decay = math.exp(-10 * dt)
            e._knockVx = e._knockVx * decay
            e._knockVy = e._knockVy * decay
            if math.abs(e._knockVx) < 0.5 and math.abs(e._knockVy) < 0.5 then
                e._knockVx, e._knockVy = nil, nil
            end
        end
        if e.health then
            if e.maxHealth and e.health > e.maxHealth then
                e.health = e.maxHealth
            end
            e._timeSinceDamaged = (e._timeSinceDamaged or 0xfffffffff) + dt
            e._timeSinceHealed = (e._timeSinceHealed or 0xfffffffff) + dt
            e._timeSinceLostArmor = (e._timeSinceLostArmor or 0xfffffffff) + dt
            if e._damageLagAmount and e._damageLagAmount > 0 then
                e._damageLagAmount = e._damageLagAmount * math.exp(-18 * dt)
                if e._damageLagAmount < 0.01 then
                    e._damageLagAmount = nil
                end
            end
        end
        if e._timeSinceAutoAttacked then
            e._timeSinceAutoAttacked = e._timeSinceAutoAttacked + dt
        end
        local tvx, tvy = g.getVel(e)
        local sameDir = (e.vx or 0) * tvx + (e.vy or 0) * tvy > 0
        if e._isMoving and sameDir then
            e._walkTime = (e._walkTime or 0) + dt
        else
            e._walkTime = 0
        end
        if e.vz and not e.floatingProjectile then
            e.vz = e.vz - consts.GRAVITY * dt
            e.z = math.max(0, (e.z or 0) + e.vz * dt)
        end
        if e.onUpdate then
            e:onUpdate(dt)
        end
        if e.lifetime then
            e.lifetime = e.lifetime - dt
            if e.lifetime <= 0 then
                self:removeEntity(e)
            end
        end
    end
    if self.allyRectangle or self.enemyRectangle then
        for i = 1, self.entities.len do
            local e = self.entities[i]
            if e.team then
                local cx, cy = self:clampToShape(e.x, e.y)
                if cx ~= e.x or cy ~= e.y then
                    g.setPos(e, cx, cy)
                end
            end
        end
    end
    g.call("postUpdate", dt)
    self.entities:flush()

    self.secondTimer = self.secondTimer + dt
    while self.secondTimer >= 1 do
        self.secondTimer = self.secondTimer - 1
        self.secondCount = self.secondCount + 1
        g.call("perSecondUpdate", self.secondCount)
    end
end

local function getDrawY(e)
    return e.y - (e.z or 0) / 2
end

local function sortOrder(a, b)
    local ya = getDrawY(a) + (a.drawOrder or 0)
    local yb = getDrawY(b) + (b.drawOrder or 0)
    if ya == yb then return a.id < b.id end
    return ya < yb
end

function ECSWorld:draw(transform)
    g.setCurrentECS(self)
    if transform then
        self.backCanvas:start(transform)
    end
    g.call("preDraw")
    if transform then
        self.backCanvas:finish()
    end

    local list = self._drawList
    if not list then
        list = {}
        self._drawList = list
    end
    local n = 0
    for i = 1, self.entities.len do
        local e = self.entities[i]
        if not e.aboveFog then
            n = n + 1
            list[n] = e
        end
    end
    for i = #list, n + 1, -1 do list[i] = nil end
    table.sort(list, sortOrder)
    for i = 1, #list do
        local e = list[i]
        g.drawEntity(e, e.x, getDrawY(e))
    end

    if transform then
        self.frontCanvas:start(transform)
    end
    g.call("postDraw")
    if consts.DEV_MODE then
        local b = self.boundingBox or {1,1,1,1}
        lg.setColor(1,1,1)
        lg.rectangle("line", b[1],b[2],b[3],b[4])
        if self.allyRectangle then
            local r = self.allyRectangle
            lg.setColor(ALLY_RECT_COLOR)
            lg.rectangle("line", r.x, r.y, r.w, r.h)
        end
        if self.enemyRectangle then
            local r = self.enemyRectangle
            lg.setColor(ENEMY_RECT_COLOR)
            lg.rectangle("line", r.x, r.y, r.w, r.h)
        end
    end
    if transform then
        self.frontCanvas:finish()
    end
end


---@param component string
---@return fun(table: ecs.Entity[], i?: integer):(integer,ecs.Entity)
---@return ecs.Entity[]
---@return integer
function ECSWorld:iterate(component)
    local list = self.componentIndex[component]
    if not list then
        list = {}
        self.componentIndex[component] = list
        self.trackedComponents:add(component)
        for i = 1, self.entities.len do
            local e = self.entities[i]
            if entHas(e, component) and not (e.___dead or e.___removed) then
                list[#list + 1] = e
            end
        end
    end
    return ipairs(list)
end



---@param partitionId string
---@param x number
---@param y number
---@param fn fun(ent: ecs.Entity)
---@param range number
function ECSWorld:iteratePartition(partitionId, x, y, fn, range)
    local part = self.partitions[partitionId]
    if part then
        part:query(x, y, fn, range)
    end
end

function ECSWorld:getAllyList()
    return self.allyList
end

function ECSWorld:getEnemyList()
    return self.enemyList
end

return ECSWorld
