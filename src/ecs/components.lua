


---@class ecs.components.AI
---@field public target "enemy"|"ally"
---@field public getPriority fun(selfEnt: ecs.Entity, targEnt:ecs.Entity): number
local ai = {
    target = "enemy",
    getPriority = function(selfEnt, targEnt)
        -- higher priority = target earlier
        return 0
    end,
}



---@class ecs.components.Attack
---@field public attackType "melee"|"ranged"
---@field public projectileType string?
---@field public projectileSpeed number?
local attack = {
    attackType = "melee",
    -- ranged attacks spawn a projectile entity type (e.g. "arrow")
    projectileType = "basic_arrow",
    projectileSpeed = 300, -- pixels/sec for projectiles
}


---@class ecs.components.Projectile
---@field public damage number
---@field public ownerEnt ecs.Entity?
---@field public team "ally"|"enemy"
---@field public pierceCount number
local projectile = {
    -- damage, ownerEnt, team, pierceCount are set on spawn
}


---@class ecs.components.Physics
---@field public shape "circle"|"rect"
---@field public radius number?
---@field public w number?
---@field public h number?
---@field public ox number
---@field public oy number
---@field public mass number
---@field public isStatic boolean?
---@field public damping number?
local physics = {
    shape = "circle",
    radius = 10,
    ox = 0,
    oy = 0,
    mass = 1,
    isStatic = false,
    damping = 10,
}


---@class ecs.Entity
---@field public id integer
---@field public ai ecs.components.AI?
---@field public attack ecs.components.Attack?
---@field public projectile ecs.components.Projectile?
---@field public team "ally"|"enemy"
---@field public color objects.Color?
---@field public x number
---@field public y number
---@field public z number?
---@field public vx number?
---@field public vy number?
---@field public vz number?
---@field public gravity number?
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
---@field public _knockVx number?
---@field public _knockVy number?
---@field public burnTime number? -- if nil, no burn
---@field public frozenTime number? -- if nil, not frozen
---@field public poisonTime number? -- if nil, no poison
---@field public _timeSinceDamaged number?
---@field public onDeath fun(ecs.Entity)?
---@field public onSpawn fun(ecs.Entity)?
---@field public onUpdate fun(ecs.Entity, number)?
---@field public onDraw fun(ecs.Entity)?
---@field public onAttack fun(ecs.Entity)?
---@field public physics ecs.components.Physics?
---@field public partitions string[]?
local ecs_Entity = {}


