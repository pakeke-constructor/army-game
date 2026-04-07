
--[[
ATTACKING SYSTEM:
=================
Handles attack logic for entities with an `attack` component.

Each frame:
1. Check if entity has a target (from AI system: ent._aiTarget).
2. Check if target is in attack range.
3. Tick attack cooldown. When ready, perform attack.
4. Melee: apply damage directly.
5. Ranged: spawn a projectile entity.

PROJECTILE SYSTEM (also in this file):
Projectiles fly with vx/vy velocity and a z arc (gravity).
Hit opposing units via spatial partitioning, or hit ground when z<=0.

Entities need: attack, attackDamage, attackSpeed, attackRange, team, x, y
Projectile entities need: projectile component (damage, ownerEnt, team), vx, vy, vz, z, gravity
]]

local atckSys = {}

---@param a ecs.Entity
---@param b ecs.Entity
---@return number
local function dist2(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return dx * dx + dy * dy
end


---@param ent ecs.Entity
---@return boolean
local function isValid(ent)
    return not not (ent.health and g.isAlive(ent))
end


---@param attacker ecs.Entity?
---@param target ecs.Entity
---@param damage number
local function dealDamage(attacker, target, damage)
    if not isValid(target) then return end

    local reduction = g.ask("getDamageReduction", target)
    local finalDmg = math.max(0, damage - reduction)

    target.health = target.health - finalDmg
    target._timeSinceDamaged = 0

    g.call("entityHurt", target, finalDmg, attacker)

    if target.health <= 0 then
        target.health = 0
        g.call("entityDeath", target, attacker)
        if attacker then
            g.call("entityKillsEnemy", attacker, target)
        end
        target:getWorld():removeEntity(target)
    end
end

local PROJ_HIT_RADIUS = 10
local PROJ_Z_MAX = 50 -- above this z, projectile doesn't hit anything

---@param attacker ecs.Entity
---@param target ecs.Entity
local function spawnProjectile(attacker, target)
    local atk = assert(attacker.attack)
    local projSpeed = atk.projectileSpeed or 300
    projSpeed = projSpeed * g.ask("getProjectileSpeedMultiplier", attacker)

    local count = 1 + g.ask("getProjectileCountModifier", attacker)
    local projType = atk.projectileType or "_projectile"

    local dx, dy = target.x - attacker.x, target.y - attacker.y
    local dist = (dx * dx + dy * dy) ^ 0.5
    if dist < 1 then dist = 1 end

    -- compute arc height: higher arc for longer distances
    local flightTime = dist / projSpeed
    local arcHeight = math.min(dist * 0.15, 40)
    -- vz such that projectile goes up then comes back to z=0 over flightTime
    -- z(t) = vz*t - 0.5*gravity*t^2, z(flightTime)=0 => vz = 0.5*gravity*flightTime
    -- peak = vz^2/(2*gravity) = arcHeight => gravity = vz^2/(2*arcHeight)
    -- combining: vz = 2*arcHeight/flightTime, gravity = 2*arcHeight/(flightTime^2)
    local vz = 2 * arcHeight / flightTime
    local gravity = 2 * arcHeight / (flightTime * flightTime)

    for i = 1, count do
        local spread = count > 1 and ((i - 1) / (count - 1) - 0.5) or 0
        local angle = math.atan2(dy, dx) + spread * 0.15
        local ent = g.spawnEntity(projType, attacker.x, attacker.y)
        ent.vx = math.cos(angle) * projSpeed
        ent.vy = math.sin(angle) * projSpeed
        ent.z = 1
        ent.vz = vz
        ent.gravity = gravity
        ent.projectile = {
            damage = attacker.attackDamage or 0,
            ownerEnt = attacker,
            team = attacker.team,
            pierceCount = 1,
            knockback = atk.projectileKnockback or 80,
        }
    end

    g.call("entityShootsProjectile", attacker, target)
end

---@param attacker ecs.Entity
---@param target ecs.Entity
local function doAttack(attacker, target)
    if not g.isAlive(target) then return end

    g.call("onAttack", attacker, target)

    local atk = attacker.attack
    if atk.attackType == "ranged" then
        spawnProjectile(attacker, target)
    else
        -- melee: direct damage
        local dmg = attacker.attackDamage or 0
        dealDamage(attacker, target, dmg)
    end
end


---@param ent ecs.Entity
---@param world ecs.ECSWorld
---@param range number
---@return ecs.Entity?
local function findNearbyTarget(ent, world, range)
    local opTeam = ent.team == "ally" and "enemy" or "ally"
    local best, bestD2 = nil, range * range
    for _, other in world:iterate("team") do
        if other.team == opTeam and isValid(other) then
            local d2 = dist2(ent, other)
            if d2 <= bestD2 then
                best, bestD2 = other, d2
            end
        end
    end
    return best
end

-- ATTACK SYSTEM
function atckSys.preUpdate(world, dt)
    for _, ent in world:iterate("attack") do
        if not isValid(ent) then goto continue end

        local target = ent._aiTarget
        if not target or not isValid(target) then
            goto continue
        end

        -- check range
        local range = ent.attackRange or 100
        local d2 = dist2(ent, target)
        if d2 > range * range then
            -- melee: try to find a nearby target we CAN hit
            if ent.attack.attackType ~= "ranged" then
                target = findNearbyTarget(ent, world, range)
            end
            if not target then goto continue end
        end

        -- tick cooldown
        local speed = ent.attackSpeed or 1
        local timer = ent._attackTimer or (math.random() * (1 / speed))
        timer = timer - dt
        if timer <= 0 then
            doAttack(ent, target)
            timer = 1 / speed
        end
        ent._attackTimer = timer

        ::continue::
    end
end


-- PROJECTILE SYSTEM
local function updateProjectile(world, ent, dt)
    local proj = ent.projectile

    -- face movement direction (account for z arc in visual rotation)
    local visualVy = ent.vy - (ent.vz or 0) / 2
    ent.rot = math.atan2(visualVy, ent.vx)

    -- hit ground (z is updated generically in ECSWorld:update)
    if (ent.z or 0) <= 0 then
        g.call("projectileHit", ent, nil)
        world:removeEntity(ent)
        return
    end

    -- check collision with units (only if z is low enough)
    if ent.z < PROJ_Z_MAX then
        local opTeam = proj.team == "ally" and "enemy" or "ally"
        local hitEnt = nil
        g.iteratePartition(opTeam, ent.x, ent.y, function(other)
            if hitEnt then return end
            if not isValid(other) then return end
            local dx, dy = other.x - ent.x, other.y - ent.y
            local d2 = dx * dx + dy * dy
            if d2 <= PROJ_HIT_RADIUS * PROJ_HIT_RADIUS then
                hitEnt = other
            end
        end, PROJ_HIT_RADIUS)
        if hitEnt then
            dealDamage(proj.ownerEnt, hitEnt, proj.damage)
            g.knockback(hitEnt, proj.ownerEnt.x, proj.ownerEnt.y, proj.knockback or 50)
            g.call("projectileHit", ent, hitEnt)
            proj.pierceCount = proj.pierceCount - 1
            if proj.pierceCount <= 0 then
                world:removeEntity(ent)
                return
            end
        end
    end
end

function atckSys.postUpdate(world, dt)
    for _, ent in world:iterate("projectile") do
        updateProjectile(world, ent, dt)
    end
end

return atckSys
