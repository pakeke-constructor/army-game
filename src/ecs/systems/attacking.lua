
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
Moves projectile entities toward their target. On arrival, deals damage.

Entities need: attack, attackDamage, attackSpeed, attackRange, side, x, y
Projectile entities need: projectile component (targetEnt, damage, speed, ownerEnt)
]]

local atckSys = {}

local function dist2(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return dx * dx + dy * dy
end

local function isAlive(ent)
    return ent.health and ent.health > 0
end

local function dealDamage(attacker, target, damage)
    if not isAlive(target) then return end

    local reduction = g.ask("getDamageReduction", target)
    local finalDmg = math.max(0, damage - reduction)
    target.health = target.health - finalDmg

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

local function spawnProjectile(attacker, target)
    local atk = attacker.attack
    local projSpeed = atk.projectileSpeed or 300
    projSpeed = projSpeed * g.ask("getProjectileSpeedMultiplier", attacker)

    local count = 1 + g.ask("getProjectileCountModifier", attacker)
    local projType = atk.projectileType or "_projectile"

    for i = 1, count do
        local ent = g.spawnEntity(projType, attacker.x, attacker.y)
        ent.projectile = {
            targetEnt = target,
            damage = attacker.attackDamage or 0,
            speed = projSpeed,
            ownerEnt = attacker,
        }
    end

    g.call("entityShootsProjectile", attacker, target)
end

local function doAttack(attacker, target)
    if not isAlive(target) then return end

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


-- ATTACK SYSTEM
function atckSys.preUpdate(world, dt)
    for _, ent in world:iterate("attack") do
        if not isAlive(ent) then goto continue end

        local target = ent._aiTarget
        if not target or not isAlive(target) then
            goto continue
        end

        -- check range
        local range = ent.attackRange or 100
        local d2 = dist2(ent, target)
        if d2 > range * range then
            goto continue
        end

        -- tick cooldown
        local timer = ent._attackTimer or 0
        timer = timer - dt
        if timer <= 0 then
            doAttack(ent, target)
            local speed = ent.attackSpeed or 1 -- attacks per second
            timer = 1 / speed
        end
        ent._attackTimer = timer

        ::continue::
    end
end


-- PROJECTILE SYSTEM
function atckSys.postUpdate(world, dt)
    for _, ent in world:iterate("projectile") do
        local proj = ent.projectile
        local target = proj.targetEnt

        -- if target is dead, just remove projectile
        if not target or not isAlive(target) then
            world:removeEntity(ent)
            goto continue
        end

        local dx, dy = target.x - ent.x, target.y - ent.y
        local dist = (dx * dx + dy * dy) ^ 0.5
        local step = proj.speed * dt

        if dist <= step then
            -- hit!
            dealDamage(proj.ownerEnt, target, proj.damage)
            g.call("projectileHit", ent, target)
            world:removeEntity(ent)
        else
            -- move toward target
            ent.x = ent.x + (dx / dist) * step
            ent.y = ent.y + (dy / dist) * step
            -- face target
            ent.rot = math.atan2(dy, dx)
        end

        ::continue::
    end
end


return atckSys
