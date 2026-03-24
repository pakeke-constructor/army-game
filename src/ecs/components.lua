


---@class ecs.components.AI
---@field public target "enemy"|"ally"
---@field public getPriority fun(selfEnt: ecs.Entity, targEnt:ecs.Entity): number
---@field public range [number,number]
local ai = {
    target = "enemy",
    getPriority = function(selfEnt, targEnt)
        -- higher priority = target earlier
        return 0
    end,

    range = {300, 400}, -- {min, max}
    -- this entity moves towards `enemy` units until it's within 300 units.
    -- then, if the enemy moves more than 400 units away, it moves again.
}



---@class ecs.components.Attack
---@field public attackType "melee"|"ranged"
---@field public projectileType string?
---@field public projectileSpeed number?
local attack = {
    attackType = "melee",
    -- ranged attacks spawn a projectile entity type (e.g. "arrow")
    projectileType = nil,
    projectileSpeed = 300, -- pixels/sec for projectiles
}


---@class ecs.components.Projectile
---@field public targetEnt ecs.Entity
---@field public damage number
---@field public speed number
---@field public ownerEnt ecs.Entity?
local projectile = {
    -- targetEnt, damage, speed are set on spawn
}


---@class ecs.Entity
---@field public ai ecs.components.AI?
---@field public attack ecs.components.Attack?
---@field public projectile ecs.components.Projectile?
---@field public side "ally"|"enemy"
---@field public color objects.Color?
---@field public x number
---@field public y number
---@field public z number?
---@field public vx number?
---@field public vy number?
---@field public vz number?
---@field public health number?
---@field public maxHealth number?
---@field public attackDamage number?
---@field public attackSpeed number?
---@field public attackRange number?
---@field public moveSpeed number?
---@field public image string?
---@field public squad g.Squad?
---@field public scope g.Scope?
---@field public _attackTimer number?
---@field public _attackTarget ecs.Entity?
---@field public onDeath fun(ecs.Entity)?
---@field public onSpawn fun(ecs.Entity)?
---@field public onUpdate fun(ecs.Entity, number)?
---@field public onDraw fun(ecs.Entity)?
---@field public onAttack fun(ecs.Entity)?
local ecs_Entity = {}


