
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
Projectile entities need: projectile component (damage, ownerEnt, team), vx, vy, vz, z
]]

local juiceService = require("src.juiceService")

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

---@param ent ecs.Entity
local function getTargetTeam(ent)
    if ent.ai and ent.ai.target == "enemy" then
        return ent.team == "ally" and "enemy" or "ally"
    end
    return ent.team
end



local PROJ_HIT_RADIUS = 24
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

    -- arc so projectile lands at z=0 after flightTime under constant gravity
    -- z(t) = vz*t - 0.5*GRAVITY*t^2, z(T)=0 => vz = 0.5*GRAVITY*T
    local flightTime = dist / projSpeed
    local vz = 0.5 * consts.GRAVITY * flightTime

    -- shoot from body of sprite (70% up), not the feet
    local zStart = 1
    if attacker.image then
        local _, h = g.getImageSize(attacker.image)
        zStart = h * 0.7
    end

    local homingTarget = nil
    if atk.projectileHoming then
        ---@type ecs.components.Projectile.Homing
        homingTarget = {
            target = target,
            time = 0,
            flightDuration = flightTime,
            zStart = zStart,
        }
        -- We'll interpolate projectile manually later
        vz = 0
        projSpeed = 0
    end

    for i = 1, count do
        local spread = count > 1 and ((i - 1) / (count - 1) - 0.5) or 0
        local angle = math.atan2(dy, dx) + spread * 0.15
        local ent = g.spawnEntity(projType, attacker.x, attacker.y)
        ent.vx = math.cos(angle) * projSpeed
        ent.vy = math.sin(angle) * projSpeed
        ent.z = zStart
        ent.vz = vz
        ent.projectile = {
            damage = attacker.attackDamage or 0,
            healing = attacker.healPower or 0,
            ownerEnt = attacker,
            team = attacker.team,
            targetTeam = getTargetTeam(attacker),
            pierceCount = 1,
            knockback = atk.projectileKnockback or consts.DEFAULT_RANGED_KNOCKBACK,
            homing = homingTarget,
        }
    end

    g.playWorldSound("battle_arrowShoot", 1+love.math.random(-15, 15)/100)
    g.call("entityShootsProjectile", attacker, target)
end



---@param target ecs.Entity
---@param attacker ecs.Entity
---@param dmgOverride number?
local function dealDmg(target, attacker, dmgOverride)
    if attacker.healPower then
        g.healEntity(target, dmgOverride or attacker.healPower or 0, attacker)
    else
        g.dealDamage(target, dmgOverride or attacker.attackDamage or 0, attacker)
    end
end


---@param attacker ecs.Entity
---@return number, number
local function getAoeInfo(attacker)
    local atk = attacker.attack or {}
    local radius = (atk.aoeRadius or 0) + g.ask("getAoeRadius", attacker)
    local dmgMul = (atk.aoeDamageMultiplier or 1) * g.ask("getAoeDamageMultiplier", attacker)
    return radius, dmgMul
end


---@param attacker ecs.Entity
---@param centerEnt ecs.Entity
---@param baseAmount number
local function doAoe(attacker, centerEnt, baseAmount)
    local radius, dmgMul = getAoeInfo(attacker)
    if radius <= 0 then return end
    local amount = baseAmount * dmgMul
    if amount == 0 then return end

    local targetTeam = getTargetTeam(attacker)
    local radius2 = radius * radius
    g.iteratePartition(targetTeam, centerEnt.x, centerEnt.y, function(other)
        if other.id == centerEnt.id then return end
        if not isValid(other) then return end
        local dx = other.x - centerEnt.x
        local dy = other.y - centerEnt.y
        if dx * dx + dy * dy <= radius2 then
            dealDmg(other, attacker, amount)
        end
    end, radius)
end

---@param attacker ecs.Entity
---@param target ecs.Entity
local function doAttack(attacker, target)
    if not g.isAlive(target) then return end

    attacker._timeSinceAutoAttacked = 0
    g.call("onAttack", attacker, target)

    local atk = attacker.attack
    if atk.attackType == "ranged" then
        spawnProjectile(attacker, target)
    else
        -- melee: direct damage
        local amount = attacker.healPower or attacker.attackDamage or 0
        dealDmg(target, attacker, amount)
        g.knockback(target, attacker.x, attacker.y, atk.meleeKnockback or consts.DEFAULT_MELEE_KNOCKBACK)
        doAoe(attacker, target, amount)
    end
end


---@param ent ecs.Entity
---@param world ecs.ECSWorld
---@param range number
---@return ecs.Entity?
local function findNearbyTarget(ent, world, range)
    local targetTeam = getTargetTeam(ent)
    local best, bestD2 = nil, range * range
    for _, other in world:iterate("team") do
        if other ~= ent and other.team == targetTeam and isValid(other) then
            local d2 = dist2(ent, other)
            if d2 <= bestD2 then
                best, bestD2 = other, d2
            end
        end
    end
    return best
end

-- ATTACK SYSTEM
function atckSys.preUpdate(dt)
    local world = g.getECS()
    for _, ent in world:iterate("attack") do
        if not isValid(ent) then goto continue end
        if ent.frozenTime and ent.frozenTime > 0 then goto continue end

        local attackCooldown = g.getAttackCooldown(ent)
        ent._attackTimer = ent._attackTimer or (love.math.random() * attackCooldown)
        ent._attackTimer = math.max(0, ent._attackTimer - dt)
        ent._isInAttackRange = false

        local target = ent._aiTarget
        if not target or not isValid(target) then
            goto continue
        end

        -- check range
        local range = ent.attackRange or 100
        local d2 = dist2(ent, target)
        -- FIXME: A better AI for healer.
        -- Healer often targets other healer and they won't move.
        -- So this check just disable the range check for healer,
        -- ensuring the AI priority targetting checks all ally on
        -- battlefield.
        local isHealer = ent.ai and ent.ai.target == "ally"
        if d2 > range * range and not isHealer then
            target = findNearbyTarget(ent, world, range)
            if target then
                ent._aiTarget = target
            else
                goto continue
            end
        end

        ent._isInAttackRange = true

        -- tick cooldown
        if ent._attackTimer <= 0 then
            doAttack(ent, target)
            ent._attackTimer = attackCooldown
        end

        -- hammer: screen shake when the smash lands (must match SMASH in drawWeapon)
        if ent.weapon and ent.weapon.type == "hammer" then
            local phase, t = g.getAttackPhase(ent)
            local smashing = phase == "swing" and t >= 0.75
            if smashing and not ent._hammerSmashed then
                juiceService.addCameraShake(ent.weapon.smashShake or 0.2)
            end
            ent._hammerSmashed = smashing
        end

        ::continue::
    end
end


-- PROJECTILE SYSTEM
---@param world ecs.ECSWorld
---@param ent ecs.Entity
---@param dt number
local function updateProjectile(world, ent, dt)
    local proj = assert(ent.projectile)

    -- For homing projectile, re-compute x, y, and z manually
    local homing = proj.homing
    if homing then
        if homing.target.___removed then
            world:removeEntity(ent)
            return
        end

        homing.time = homing.time + dt
        local t = helper.clamp(homing.time / homing.flightDuration, 0, 1)

        if t >= 1 then
            -- Force collide (likely triggered in below codepath but just in case)
            g.call("projectileHit", ent, homing.target)
            world:removeEntity(ent)
            return
        end

        -- Update x,y,z
        local x = helper.lerp(proj.ownerEnt.x, homing.target.x, t)
        local y = helper.lerp(proj.ownerEnt.y, homing.target.y, t)
        local z = homing.zStart + 0.5 * consts.GRAVITY * (homing.flightDuration ^ 2) * t * (1 - t)
        local vx = x - ent.x
        local vy = y - ent.y
        local vz = z - ent.z
        ent.x, ent.y, ent.z = x, y, z
        -- face movement direction (account for z arc in visual rotation)
        -- uses vx,vy,vz computed from previous frame
        local visualVy = vy - (vz or 0) / 2
        ent.rot = math.atan2(visualVy, vx)
    else
        -- face movement direction (account for z arc in visual rotation)
        local visualVy = ent.vy - (ent.vz or 0) / 2
        ent.rot = math.atan2(visualVy, ent.vx)
    end

    -- hit ground (z is updated generically in ECSWorld:update)
    if (ent.z or 0) <= 0 then
        g.call("projectileHit", ent, nil)
        world:removeEntity(ent)
        return
    end

    -- check collision with units (only if z is low enough)
    if ent.z < PROJ_Z_MAX then
        local targetTeam = proj.targetTeam or (proj.team == "ally" and "enemy" or "ally")
        ---@type ecs.Entity?
        local hitEnt = nil
        local projHits = ent._projectileHits
        local function checkHit(other)
            if hitEnt then return end
            -- Need this check because projectile meant for ally collies
            -- with itself. However, a more sophisticated heurestic is
            -- probably necessary.
            -- There are 3 options:
            -- 1. Do not allow collide with owner entity.
            -- 2. Make it so healing-projectiles only collide with entities that have low/missing health.
            -- 3. Make it so healing-projectiles only collide with the entity that they were shot towards. This is currently used.
            if proj.ownerEnt == other then return end
            if proj.homing and proj.homing.target ~= other then return end
            if projHits and projHits[other.id] then return end
            if not isValid(other) then return end
            local dx, dy = other.x - ent.x, other.y - ent.y
            local d2 = dx * dx + dy * dy
            if d2 <= PROJ_HIT_RADIUS * PROJ_HIT_RADIUS then
                hitEnt = other
            end
        end
        g.iteratePartition(targetTeam, ent.x, ent.y, checkHit, PROJ_HIT_RADIUS)
        g.iteratePartition("neutral", ent.x, ent.y, checkHit, PROJ_HIT_RADIUS)
        if hitEnt then
            ent._projectileHits = ent._projectileHits or {}
            ent._projectileHits[hitEnt.id] = true
            local amount = math.max(proj.damage, proj.healing)
            dealDmg(hitEnt, proj.ownerEnt, amount)
            doAoe(proj.ownerEnt, hitEnt, amount)
            g.knockback(hitEnt, proj.ownerEnt.x, proj.ownerEnt.y, proj.knockback or consts.DEFAULT_RANGED_KNOCKBACK)
            g.call("projectileHit", ent, hitEnt)
            proj.pierceCount = proj.pierceCount - 1
            if proj.pierceCount <= 0 then
                world:removeEntity(ent)
                return
            end
        end
    end
end

function atckSys.postUpdate(dt)
    local world = g.getECS()
    for _, ent in world:iterate("projectile") do
        updateProjectile(world, ent, dt)
    end
end

return atckSys
