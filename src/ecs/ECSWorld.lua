local objects = require("src.modules.objects.objects")
local table_clear = require("table.clear")

---@class ecs.ECSWorld: objects.Class
local ECSWorld = objects.Class("ecs:ECSWorld")

function ECSWorld:init()
    self.entities = objects.BufferedSet()
    self.componentIndex = {} -- [componentName] -> {ent, ent, ...}
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

function ECSWorld:update(dt)
    self.entities:flush()
    self:_rebuildIndex()
    for i = 1, self.entities.len do
        local e = self.entities[i]
        if e.update then
            e:update(dt)
        end
    end
end

function ECSWorld:iterate(component)
    local list = self.componentIndex[component]
    if not list then
        return ipairs({})
    end
    return ipairs(list)
end

return ECSWorld
