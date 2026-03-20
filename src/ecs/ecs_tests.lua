local ECSWorld = require("src.ecs.ECSWorld")
local Entity = require("src.ecs.Entity")

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        print("TEST PASSED: ECS " .. name)
    else
        error("FAILED " .. name .. ": " .. err)
    end
end

local function assert(condition, msg)
    if not condition then
        error(msg or "assertion failed")
    end
end

local function countIterate(world, comp)
    local n = 0
    for _ in world:iterate(comp) do n = n + 1 end
    return n
end

-- Helper: make an entity with a metatable (like g.defineEntityType does)
local function makeEntity(own, shared)
    shared = shared or {}
    shared.addComponent = Entity.addComponent
    shared.removeComponent = Entity.removeComponent
    local mt = {__index = shared, __newindex = Entity.__newindex}
    return setmetatable(own, mt)
end

test("add and iterate", function()
    local w = ECSWorld()
    local e = makeEntity({x = 1, y = 2, hp = 10})
    w:addEntity(e)
    w:flush()
    assert(countIterate(w, "hp") == 1)
    assert(countIterate(w, "x") == 1)
end)

test("remove entity", function()
    local w = ECSWorld()
    local e = makeEntity({x = 1, hp = 10})
    w:addEntity(e)
    w:flush()
    assert(countIterate(w, "hp") == 1)
    w:removeEntity(e)
    w:flush()
    assert(countIterate(w, "hp") == 0)
end)

test("shared component via __index", function()
    local w = ECSWorld()
    local e = makeEntity({x = 1}, {damage = 5})
    w:addEntity(e)
    w:flush()
    assert(countIterate(w, "damage") == 1, "should index shared components")
    assert(countIterate(w, "x") == 1)
end)

test("iterate empty component", function()
    local w = ECSWorld()
    assert(countIterate(w, "nonexistent") == 0)
end)

test("multiple entities", function()
    local w = ECSWorld()
    local e1 = makeEntity({hp = 10})
    local e2 = makeEntity({hp = 20, armor = 5})
    local e3 = makeEntity({armor = 3})
    w:addEntity(e1)
    w:addEntity(e2)
    w:addEntity(e3)
    w:flush()
    assert(countIterate(w, "hp") == 2)
    assert(countIterate(w, "armor") == 2)
end)

test("addComponent updates index", function()
    local w = ECSWorld()
    local e = makeEntity({x = 1})
    w:addEntity(e)
    w:flush()
    assert(countIterate(w, "poison") == 0)
    e:addComponent("poison", true)
    assert(countIterate(w, "poison") == 1)
end)

test("removeComponent updates index", function()
    local w = ECSWorld()
    local e = makeEntity({hp = 10, poison = true})
    w:addEntity(e)
    w:flush()
    assert(countIterate(w, "poison") == 1)
    e:removeComponent("poison")
    assert(countIterate(w, "poison") == 0)
end)

test("__newindex auto-indexes new component", function()
    local w = ECSWorld()
    local e = makeEntity({x = 1})
    w:addEntity(e)
    w:flush()
    assert(countIterate(w, "shield") == 0)
    e.shield = 5
    assert(countIterate(w, "shield") == 1)
end)

test("__newindex auto-unindexes nil component", function()
    local w = ECSWorld()
    local e = makeEntity({hp = 10, shield = 5})
    w:addEntity(e)
    w:flush()
    assert(countIterate(w, "shield") == 1)
    e.shield = nil
    assert(countIterate(w, "shield") == 0)
end)

test("__newindex overwrite does not double-index", function()
    local w = ECSWorld()
    local e = makeEntity({hp = 10})
    w:addEntity(e)
    w:flush()
    e.hp = 20 -- overwrite existing, should not add twice
    assert(countIterate(w, "hp") == 1)
end)

test("update calls entity update", function()
    local w = ECSWorld()
    local called = false
    local e = makeEntity({x = 0}, {update = function(self, dt) called = dt end})
    w:addEntity(e)
    w:update(0.16)
    assert(called == 0.16, "update should be called with dt")
end)

test("entity not in world ignores addComponent", function()
    local e = makeEntity({x = 1})
    -- should not error
    e:addComponent("foo", 1)
    assert(rawget(e, "foo") == 1)
end)

test("iterate returns correct entities", function()
    local w = ECSWorld()
    local e1 = makeEntity({hp = 10})
    local e2 = makeEntity({mp = 5})
    w:addEntity(e1)
    w:addEntity(e2)
    w:flush()
    local found = nil
    for _, e in w:iterate("hp") do
        found = e
    end
    assert(found == e1, "should find the entity with hp")
end)

print("All ECS tests passed!")
