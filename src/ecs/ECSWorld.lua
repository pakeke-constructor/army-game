local objects = require("src.modules.objects.objects")
local table_clear = require("table.clear")

---@class ecs.ECSWorld: objects.Class
local ECSWorld = objects.Class("ecs:ECSWorld")

function ECSWorld:init(systemNames)
    self.entities = objects.BufferedSet()
    self.componentIndex = {} -- [componentName] -> {ent, ent, ...}

    -- Load systems (each system is a plain table of event/question handlers)
    self.systems = {}
    for _, name in ipairs(systemNames or {}) do
        self.systems[#self.systems + 1] = require("src.ecs.systems." .. name)
    end
end

function ECSWorld:addEntity(e)
    self.entities:addBuffered(e)
end

function ECSWorld:removeEntity(e)
    self.entities:removeBuffered(e)
end

function ECSWorld:_rebuildIndex()
    local idx = self.componentIndex
    -- clear existing lists but keep the tables
    for _, list in pairs(idx) do
        table_clear(list)
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
    end
end

function ECSWorld:addSystemHandlers()
    for i = 1, #self.systems do
        g.addHandler(self.systems[i])
    end
end

function ECSWorld:update(dt)
    self.entities:flush()
    self:_rebuildIndex()
    g.call("preUpdate", self, dt)
    for i = 1, self.entities.len do
        local e = self.entities[i]
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
    g.call("postUpdate", self, dt)
end

local function sortOrder(a, b)
    return (a.y + (a.drawOrder or 0)) < (b.y + (b.drawOrder or 0))
end

function ECSWorld:draw()
    g.call("preDraw", self)
    local list = {}
    for i = 1, self.entities.len do
        list[#list + 1] = self.entities[i]
    end
    table.sort(list, sortOrder)
    for i = 1, #list do
        local e = list[i]
        g.drawEntity(e, e.x, e.y)
    end
    g.call("postDraw", self)
end

function ECSWorld:iterate(component)
    local list = self.componentIndex[component]
    if not list then
        return ipairs({})
    end
    return ipairs(list)
end

return ECSWorld
