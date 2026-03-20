--[[
Entity base metatable helpers for ECS.

Entity:addComponent(k, v) - adds component + updates world index
Entity:removeComponent(k) - removes component + updates world index

__newindex is set so that `ent.foo = bar` auto-updates the world index.
]]

local Entity = {}

function Entity.addComponent(self, k, v)
    rawset(self, k, v)
    local world = rawget(self, "_world")
    if world and type(k) == "string" then
        world:onComponentAdded(self, k)
    end
end

function Entity.removeComponent(self, k)
    rawset(self, k, nil)
    local world = rawget(self, "_world")
    if world and type(k) == "string" then
        world:onComponentRemoved(self, k)
    end
end

-- __newindex handler: auto-index on component add/remove
function Entity.__newindex(self, k, v)
    local old = rawget(self, k)
    rawset(self, k, v)
    local world = rawget(self, "_world")
    if not world or type(k) ~= "string" then return end
    if v ~= nil and old == nil then
        world:onComponentAdded(self, k)
    elseif v == nil and old ~= nil then
        world:onComponentRemoved(self, k)
    end
end

return Entity
