local Entity = {}

function Entity:isOwn(key)
    return rawget(self, key) ~= nil
end

function Entity:isShared(key)
    if rawget(self, key) ~= nil then return false end
    local mt = getmetatable(self)
    local def = mt and rawget(mt, "__index")
    if type(def) == "table" then
        return def[key] ~= nil
    end
    return false
end

function Entity:getDef()
    local mt = getmetatable(self)
    return mt and rawget(mt, "__index")
end

function Entity:getWorld()
    return self._world
end

return Entity
