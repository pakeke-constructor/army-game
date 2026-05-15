


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

---@class ecs.components.Taunt
---@field public ent ecs.Entity
---@field public duration number
local taunt = {
    -- ent + duration are set when applied
}

---@class ecs.components.Fear
---@field public ent ecs.Entity?
---@field public duration number
local fear = {
    -- ent + duration are set when applied
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
---@field public taunt ecs.components.Taunt?
---@field public fear ecs.components.Fear?
---@field public team "ally"|"enemy"
---@field public color objects.Color?
---@field public x number
---@field public y number
---@field public z number?
---@field public vx number?
---@field public vy number?
---@field public vz number?
---@field public scale number?
---@field public health number?
---@field public isHealer boolean? if this is true, the entity is a healer, and will heal with it's attacks.
---@field public baseMaxHealth number?
---@field public baseArmor number?
---@field public baseAttackDamage number?
---@field public baseHealPower number?
---@field public baseAttackSpeed number?
---@field public baseLifesteal number?
---@field public baseAttackRange number?
---@field public baseMoveSpeed number?
---@field public baseProjectileAccuracy number?
---@field public maxHealth number?
---@field public armor number?
---@field public startingArmor number?
---@field public attackDamage number?
---@field public healPower number?
---@field public attackSpeed number?
---@field public lifesteal number?
---@field public attackRange number?
---@field public moveSpeed number?
---@field public projectileAccuracy number?
---@field public patrolX number?
---@field public patrolY number?
---@field public image string?
---@field public squad g.Squad?
---@field public scope g.Scope?
---@field public buffs {[string]: number}?
---@field public __cachedPerkHandler table<string, function>|false?
---@field public _projectileCloned boolean?
---@field public _attackTimer number?
---@field public _attackTarget ecs.Entity?
---@field public _knockVx number?
---@field public _knockVy number?
---@field public burnTime number? -- if nil, no burn
---@field public frozenTime number? -- if nil, not frozen
---@field public poisonAmount number? -- if nil, no poison
---@field public isPest number? returns true if this entity is a "pest"
---@field public _timeSinceDamaged number?
---@field public _timeSinceLostArmor number?
---@field public _damageLagAmount number?
---@field public onUpdate fun(ecs.Entity, number)?
---@field public onDraw fun(ecs.Entity)?
---@field public onAttack fun(ecs.Entity)?
---@field public entitySpawned fun(ecs.Entity)?
---@field public entityDeath fun(ecs.Entity, ecs.Entity?)?
---@field public entityHurt fun(ecs.Entity, number, ecs.Entity?)?
---@field public entityHealed fun(ecs.Entity, number, ecs.Entity?)?
---@field public armorIncreased fun(ecs.Entity, number)?
---@field public armorDecreased fun(ecs.Entity, number)?
---@field public entityBuffed fun(ecs.Entity, table, number?)?
---@field public entityKillsEnemy fun(ecs.Entity, ecs.Entity)?
---@field public entityShootsProjectile fun(ecs.Entity, ecs.Entity)?
---@field public drawEntity fun(ecs.Entity)?
---@field public statusEffectApplied fun(ecs.Entity, string, number, ecs.Entity?)?
---@field public physics ecs.components.Physics?
---@field public partitions string[]?
local ecs_Entity = {}


