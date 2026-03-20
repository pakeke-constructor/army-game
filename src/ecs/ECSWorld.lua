local objects = require("src.modules.objects.objects")

---@class ecs.ECSWorld: objects.Class
local ECSWorld = objects.Class("ecs:ECSWorld")

function ECSWorld:init()
    self.entities = objects.BufferedSet()
    self.componentIndex = {} -- [componentName] -> BufferedSet of entities
end

function ECSWorld:_getIndex(comp)
    local idx = self.componentIndex[comp]
    if not idx then
        idx = objects.BufferedSet()
        self.componentIndex[comp] = idx
    end
    return idx
end

function ECSWorld:_indexEntity(e)
    for k, v in pairs(e) do
        if type(k) == "string" and v ~= nil then
            self:_getIndex(k):add(e)
        end
    end
    local mt = getmetatable(e)
    local base = mt and rawget(mt, "__index")
    if type(base) == "table" then
        for k, v in pairs(base) do
            if type(k) == "string" and v ~= nil then
                self:_getIndex(k):add(e)
            end
        end
    end
end

function ECSWorld:_unindexEntity(e)
    for _, idx in pairs(self.componentIndex) do
        idx:remove(e)
    end
end

function ECSWorld:addEntity(e)
    self.entities:addBuffered(e)
end

function ECSWorld:removeEntity(e)
    self.entities:removeBuffered(e)
end

function ECSWorld:flush()
    local toAdd = {}
    for e in pairs(self.entities.addBuffer) do
        toAdd[#toAdd + 1] = e
    end
    for e in pairs(self.entities.remBuffer) do
        self:_unindexEntity(e)
    end
    self.entities:flush()
    for _, e in ipairs(toAdd) do
        self:_indexEntity(e)
        e._world = self
    end
end

function ECSWorld:update(dt)
    self:flush()
    for i = 1, self.entities.len do
        local e = self.entities[i]
        if e.update then
            e:update(dt)
        end
    end
end

function ECSWorld:onComponentAdded(e, k)
    self:_getIndex(k):add(e)
end

function ECSWorld:onComponentRemoved(e, k)
    local idx = self.componentIndex[k]
    if idx then
        idx:remove(e)
    end
end

function ECSWorld:iterate(component)
    local idx = self.componentIndex[component]
    if not idx then
        return ipairs({})
    end
    return ipairs(idx)
end

return ECSWorld
