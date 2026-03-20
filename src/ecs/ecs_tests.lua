local ECSWorld = require("src.ecs.ECSWorld")
require("src.ev_q_defs")

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

local function makeEntity(own, shared)
    if not shared then return own end
    return setmetatable(own, {__index = shared})
end

test("add and iterate", function()
    local w = ECSWorld()
    local e = makeEntity({x = 1, y = 2, hp = 10})
    w:addEntity(e)
    w:update(0)
    assert(countIterate(w, "hp") == 1)
    assert(countIterate(w, "x") == 1)
end)

test("remove entity", function()
    local w = ECSWorld()
    local e = makeEntity({hp = 10})
    w:addEntity(e)
    w:update(0)
    assert(countIterate(w, "hp") == 1)
    w:removeEntity(e)
    w:update(0)
    assert(countIterate(w, "hp") == 0)
end)

test("shared component via __index", function()
    local w = ECSWorld()
    local e = makeEntity({x = 1}, {damage = 5})
    w:addEntity(e)
    w:update(0)
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
    w:update(0)
    assert(countIterate(w, "hp") == 2)
    assert(countIterate(w, "armor") == 2)
end)

test("dynamic component add", function()
    local w = ECSWorld()
    local e = makeEntity({x = 1})
    w:addEntity(e)
    w:update(0)
    assert(countIterate(w, "poison") == 0)
    e.poison = true
    w:update(0) -- rebuild picks it up
    assert(countIterate(w, "poison") == 1)
end)

test("dynamic component remove", function()
    local w = ECSWorld()
    local e = makeEntity({hp = 10, poison = true})
    w:addEntity(e)
    w:update(0)
    assert(countIterate(w, "poison") == 1)
    e.poison = nil
    w:update(0)
    assert(countIterate(w, "poison") == 0)
end)

test("update calls entity update", function()
    local w = ECSWorld()
    local called = false
    local e = makeEntity({x = 0}, {update = function(self, dt) called = dt end})
    w:addEntity(e)
    w:update(0.16)
    assert(called == 0.16, "update should be called with dt")
end)

test("iterate returns correct entities", function()
    local w = ECSWorld()
    local e1 = makeEntity({hp = 10})
    local e2 = makeEntity({mp = 5})
    w:addEntity(e1)
    w:addEntity(e2)
    w:update(0)
    local found = nil
    for _, e in w:iterate("hp") do
        found = e
    end
    assert(found == e1)
end)

test("shared and own keys dont duplicate", function()
    local w = ECSWorld()
    local e = makeEntity({damage = 99}, {damage = 5})
    w:addEntity(e)
    w:update(0)
    assert(countIterate(w, "damage") == 1)
end)

print("All ECS tests passed!")
