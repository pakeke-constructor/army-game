local objects = require("src.modules.objects.objects")
local table_clear = require("table.clear")
local PixelCanvas = require("src.modules.PixelCanvas")

---@class ecs.ECSWorld: objects.Class
---@field public data table
local ECSWorld = objects.Class("ecs:ECSWorld")


---@class ecs.System
---@field public ecs ecs.ECSWorld


local PARTITION_CHUNKSIZE = 32

function ECSWorld:init(systemNames)
    self.entities = objects.BufferedSet()

    self.data = {}
    self.backCanvas = PixelCanvas.new(love.graphics.getDimensions())
    self.frontCanvas = PixelCanvas.new(love.graphics.getDimensions())
    self.border = nil -- {0, 0, w, h} or nil for no border

    self.componentIndex = {} -- [componentName] -> {ent, ent, ...}
    self.partitions = {
        -- [partitionId] -> objects.Partition
        unit = objects.Partition(PARTITION_CHUNKSIZE),
        projectile = objects.Partition(PARTITION_CHUNKSIZE),
        ally = objects.Partition(PARTITION_CHUNKSIZE),
        enemy = objects.Partition(PARTITION_CHUNKSIZE)
    }

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

function ECSWorld:setBorder(w, h)
    self.border = {0, 0, w, h}
end

function ECSWorld:addEntity(e)
    self.entities:addBuffered(e)
end

function ECSWorld:removeEntity(e)
    e.___removed = true
    self.entities:removeBuffered(e)
end

function ECSWorld:_rebuildIndex()
    local idx = self.componentIndex
    -- clear existing lists but keep the tables
    for _, list in pairs(idx) do
        table_clear(list)
    end
    for _, part in pairs(self.partitions) do
        part:clear()
    end
    for i = 1, self.entities.len do
        local e = self.entities[i]
        -- own keys
        for k in pairs(e) do
            if type(k) == "string" then
                local list = idx[k]
                if not list then list = {}; idx[k] = list end
                list[#list + 1] = e
            end
        end
        -- inherited keys via __index
        local mt = getmetatable(e)
        local base = mt and rawget(mt, "__index")
        if type(base) == "table" then
            for k in pairs(base) do
                if type(k) == "string" and rawget(e, k) == nil then
                    local list = idx[k]
                    if not list then list = {}; idx[k] = list end
                    list[#list + 1] = e
                end
            end
        end
        -- spatial partitions
        local p = e.partitions
        if p then
            for j = 1, #p do
                local pid = p[j]
                assert(self.partitions[pid], "Unknown partition: " .. tostring(pid))
                local part = self.partitions[pid]
                if not part then part = objects.Partition(64); self.partitions[pid] = part end
                part:add(e, e.x, e.y)
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
    self.entities:flush()
    self:_rebuildIndex()
    g.call("preUpdate", self, dt)
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
            e._timeSinceDamaged = (e._timeSinceDamaged or 0xfffffffff) + dt
        end
        if e.vz then
            if e.gravity then e.vz = e.vz - e.gravity * dt end
            e.z = math.max(0, (e.z or 0) + e.vz * dt)
        end
        if e.update then
            e:update(dt)
        end
        if e.lifetime then
            e.lifetime = e.lifetime - dt
            if e.lifetime <= 0 then
                self:removeEntity(e)
            end
        end
    end
    local border = self.border
    if border then
        for i = 1, self.entities.len do
            local e = self.entities[i]
            if e.team then
                local cx = math.min(math.max(e.x, border[1]), border[3])
                local cy = math.min(math.max(e.y, border[2]), border[4])
                if cx ~= e.x or cy ~= e.y then
                    g.setPos(e, cx, cy)
                end
            end
        end
    end
    g.call("postUpdate", self, dt)
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
    if transform then
        self.backCanvas:start(transform)
    end
    g.call("preDraw", self)
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
    g.call("postDraw", self)
    if transform then
        self.frontCanvas:finish()
    end
end


local EMPTY = {}

function ECSWorld:iterate(component)
    local list = self.componentIndex[component]
    if not list then
        return ipairs(EMPTY)
    end
    return ipairs(list)
end

function ECSWorld:iteratePartition(partitionId, x, y, fn, range)
    local part = self.partitions[partitionId]
    if part then
        part:query(x, y, fn, range)
    end
end

return ECSWorld
