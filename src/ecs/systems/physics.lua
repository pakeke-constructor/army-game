--[[
PHYSICS SYSTEM (love.physics):
==============================
Uses Box2D for collision resolution. Zero gravity (top-down).
AI sets ent.vx/vy -> we feed to Box2D -> Box2D resolves -> we read back positions.
ECSWorld skips manual vx/vy integration for entities with physics component.

Runtime state stored in world.data (not on the entity):
  world.data.physicsWorld   -- love.physics.World
  world.data.physicsBodies  -- weak {[ent] = Body}
  world.data.physicsFixtures -- weak {[ent] = Fixture}

ent.physics is pure config and can be shared across entities.
]]

local physicsSys = {}

---@class ecs.PhysicsData
---@field physicsWorld love.World
---@field physicsBodies table<ecs.Entity, love.Body>
---@field physicsFixtures table<ecs.Entity, love.Fixture>

--- Create a weak-keyed table
---@return table
local function weakTable()
    return setmetatable({}, {__mode = "k"})
end

---@param world ecs.ECSWorld
---@return ecs.PhysicsData
local function getData(world)
    return world.data --[[@as ecs.PhysicsData]]
end

function physicsSys.initECS(world)
    local d = getData(world)
    d.physicsWorld = love.physics.newWorld(0, 0, true)
    d.physicsBodies = weakTable()
    d.physicsFixtures = weakTable()
end

---@param ent ecs.Entity
---@param d ecs.PhysicsData
local function initBody(ent, d)
    local p = ent.physics
    local bodyType = p.isStatic and "static" or "dynamic"
    local body = love.physics.newBody(d.physicsWorld, ent.x + p.ox, ent.y + p.oy, bodyType)
    body:setFixedRotation(true)
    body:setLinearDamping(p.damping or 10)
    body:setUserData(ent)

    ---@type love.Shape
    local shape
    if p.shape == "rect" then
        shape = love.physics.newRectangleShape(p.w, p.h)
    else
        shape = love.physics.newCircleShape(p.radius or 10)
    end

    local fixture = love.physics.newFixture(body, shape)
    fixture:setRestitution(0)
    fixture:setFriction(0)

    if not p.isStatic then
        body:setMass(p.mass or 1)
    end

    d.physicsBodies[ent] = body
    d.physicsFixtures[ent] = fixture
end

---@param ent ecs.Entity
---@param d ecs.PhysicsData
local function destroyBody(ent, d)
    local body = d.physicsBodies[ent]
    if body and not body:isDestroyed() then
        body:destroy()
    end
    d.physicsBodies[ent] = nil
    d.physicsFixtures[ent] = nil
end

function physicsSys.preUpdate(world, dt)
    local d = getData(world)
    local bodies = d.physicsBodies

    -- init new bodies, sync velocities
    for _, ent in world:iterate("physics") do
        if not bodies[ent] then
            initBody(ent, d)
        end
        local body = bodies[ent]
        if not ent.physics.isStatic then
            local vx, vy = g.getVel(ent)
            body:setLinearVelocity(vx, vy)
        end
    end

    -- step Box2D
    d.physicsWorld:update(dt)

    -- read back positions
    for _, ent in world:iterate("physics") do
        if not ent.physics.isStatic then
            local body = bodies[ent]
            if body then
                local bx, by = body:getPosition()
                local p = ent.physics
                ent.x = bx - p.ox
                ent.y = by - p.oy
            end
        end
    end
end

function physicsSys.entityDeath(ent)
    local world = ent:getWorld()
    if world then
        destroyBody(ent, getData(world))
    end
end

return physicsSys
