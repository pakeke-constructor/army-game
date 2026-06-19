local objects = require("src.modules.objects.objects")
local table_clear = require("table.clear")
local PixelCanvas = require("src.modules.PixelCanvas")

---@class ecs.ECSWorld: objects.Class
---@field public data table<string, any>
local ECSWorld = objects.Class("ecs:ECSWorld")


---@class ecs.System
---@field public ecs ecs.ECSWorld


local PARTITION_CHUNKSIZE = 32

function ECSWorld:init(systemNames)
    ---@type objects.BufferedSet<ecs.Entity>
    self.entities = objects.BufferedSet()

    self.data = {} -- system-storage

    self.backCanvas = PixelCanvas.new(love.graphics.getDimensions())
    self.frontCanvas = PixelCanvas.new(love.graphics.getDimensions())
    self.boundingBox = nil -- {0, 0, w, h} or nil for no bounds
    self.shape = nil -- list of ellipses {cx,cy,rx,ry}; world is union of them

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
    self.deathAllies = 0

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

-- Generate a "world shape" as a union of scattered ellipses covering the
-- bounding box. Non-uniform blobs make it feel like a scrappy battlefield.
-- Fog is cleared inside the shape, and entities are clamped inside it.
local function generateShape(w, h)
    local cy = h / 2
    local shape = {}
    local n = love.math.random(4, 6)
    shape[1] = {
        cx = w/2, cy = h/2,
        rx = w/4, ry = h/4
    }
    for i = 1, n do
        local t = (i - 1) / (n - 1)
        local rx = math.min(w, h) * (love.math.random(40, 50) / 100) * (14 / (10+n))
        local ry = rx * love.math.random(100, 130) / 100
        -- cap radii + clamp center so the whole oval stays inside the bounding box
        rx = math.min(rx, w / 2)
        ry = math.min(ry, h / 2)
        local cx = helper.lerp(w * 0.2, w * 0.8, t) + love.math.random(-50, 50)
        local cyy = cy + love.math.random(-h * 0.3, h * 0.3)
        cx = helper.clamp(cx, rx, w - rx)
        cyy = helper.clamp(cyy, ry, h - ry)
        table.insert(shape, {
            cx = cx,
            cy = cyy,
            rx = rx,
            ry = ry,
        })
    end
    return shape
end



function ECSWorld:setBounds(w, h)
    self.boundingBox = {0, 0, w, h}
    self.shape = generateShape(w, h)
end

---@return boolean
function ECSWorld:isInsideShape(x, y)
    local shape = self.shape
    if not shape then return true end
    for i = 1, #shape do
        local e = shape[i]
        local dx, dy = (x - e.cx) / e.rx, (y - e.cy) / e.ry
        if dx * dx + dy * dy <= 1 then
            return true
        end
    end
    return false
end

---@return integer
function ECSWorld:getNumOverlappingShapes(x, y)
    local shape = self.shape
    if not shape then return 0 end
    local count = 0
    for i = 1, #shape do
        local e = shape[i]
        local dx, dy = (x - e.cx) / e.rx, (y - e.cy) / e.ry
        if dx * dx + dy * dy <= 1 then
            count = count + 1
        end
    end
    return count
end

-- Returns x,y clamped to the nearest point inside/on the shape.
function ECSWorld:clampToShape(x, y)
    local shape = self.shape
    if not shape or self:isInsideShape(x, y) then return x, y end
    local bestX, bestY, bestD
    for i = 1, #shape do
        local e = shape[i]
        local dx, dy = (x - e.cx) / e.rx, (y - e.cy) / e.ry
        local d = math.sqrt(dx * dx + dy * dy)
        if d == 0 then d = 1e-6 end
        local px = e.cx + (dx / d) * e.rx
        local py = e.cy + (dy / d) * e.ry
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
    g.call("preUpdate", dt)
    for i = 1, self.entities.len do
        local e = self.entities[i]
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
        if e._timeSinceDeployed then
            e._timeSinceDeployed = e._timeSinceDeployed + dt
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
        if e.vz then
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
    if self.shape then
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

    local list = {}
    for i = 1, self.entities.len do
        list[#list + 1] = self.entities[i]
    end
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
