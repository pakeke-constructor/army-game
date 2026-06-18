


---@class ecs.components.AI
---@field public target "enemy"|"ally"
---@field public getPriority (fun(selfEnt: ecs.Entity, targEnt:ecs.Entity): number)?
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
---@field public projectileHoming boolean?
---@field public aoeRadius number?
---@field public aoeDamageMultiplier number?
local attack = {
    attackType = "melee",
    -- ranged attacks spawn a projectile entity type (e.g. "arrow")
    projectileType = "basic_arrow",
    projectileSpeed = 300, -- pixels/sec for projectiles
    projectileHoming = false, -- true or false

    aoeRadius = 50 or nil, -- defaults to 0  (no AOE)
    aoeDamageMultiplier = 0.8 or nil,
}


---@class ecs.components.Projectile
---@field public damage number
---@field public healing number
---@field public ownerEnt ecs.Entity?
---@field public team "ally"|"enemy"|"neutral"
---@field public targetTeam "ally"|"enemy"|"neutral"
---@field public pierceCount number
---@field public homing ecs.components.Projectile.Homing?
local projectile = {
    -- damage, ownerEnt, team, pierceCount are set on spawn
}

---@class ecs.components.Projectile.Homing
---@field public target ecs.Entity
---@field public time number
---@field public flightDuration number
---@field public zStart number
local homing = {}

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


---@class ecs.components.Weapon
---@field public image string
---@field public type "sword"|"spear"|"bow"|"staff"|"object"
---@field public swordSwingTime number?
---@field public swordStrikeTime number?
---@field public spearStrikeTime number?
---@field public bowRecoil number?
---@field public weaponBobbing number?
---@field public xOffset number?
local weapon = {
    image = "militia_sword",
    type = "sword",
    swordSwingTime = 0.6,
    swordStrikeTime = 0.2,
    bowRecoil = 0.1, -- 10% recoil
    weaponBobbing = 0.1, -- 10% bobbing
    xOffset = 10,
}

---@class ecs.components.Shadow
---@field public radius number?
---@field public opacity number?
local shadow = {
    radius = 3,
    opacity = 0.6,
}

---@class ecs.components.WalkAnimation
---@field public bounceHeight number
---@field public rotationAmount number
---@field public speed number

---@class ecs.Components
---@field public ai ecs.components.AI?
---@field public attack ecs.components.Attack?
---@field public projectile ecs.components.Projectile?
---@field public weapon ecs.components.Weapon?
---@field public shadow ecs.components.Shadow?
---@field public walkAnimation ecs.components.WalkAnimation?
---@field public _walkTime number?
---@field public _isMoving boolean? true while the entity is actively moving toward its target (drives walk animation)
---@field public faceDir integer?
---@field public taunt ecs.components.Taunt?
---@field public fear ecs.components.Fear?
---@field public team ("ally"|"enemy"|"neutral")?
---@field public color objects.Color?
---@field public alpha number? transparency
---@field public x number?
---@field public y number?
---@field public z number?
---@field public vx number?
---@field public vy number?
---@field public vz number?
---@field public rot number?
---@field public sx number?
---@field public sy number?
---@field public randomizeScaleX boolean? if true, sx is randomized to +abs(sx) or -abs(sx) on spawn
---@field public ox number?
---@field public oy number?
---@field public kx number?
---@field public ky number?
---@field public oyOverride number? oy (offsetY) defaults to 0.95, which is 95% of image, but you can override this here.
---@field public drawOrder number?
---@field public scale number?
---@field public health number?
---@field public isHealer boolean? true IFF entity is a healer, and will heal with it's attacks.
---@field public isRanged boolean? true IFF the entity is ranged attacker
---@field public isBuilding boolean? true IFF entity is a building, and MUST be assigned a static physics body
---@field public isCommander boolean? if this is true, entity is a commander
---@field public playerControlled boolean?
---@field public baseMaxHealth number?
---@field public baseStartingArmor number?
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
---@field public _projectileHits table<integer, boolean>?
---@field public _attackTimer number?
---@field public _isInAttackRange boolean?
---@field public _attackTarget ecs.Entity?
---@field public _knockVx number?
---@field public _knockVy number?
---@field public knockbackResistance number? -- +1 each knockback; reduces future knockback
---@field public _aiTarget ecs.Entity?
---@field public _lastTargetRefreshTime number?
---@field public _timeUntilRetarget number?
---@field public burnTime number? -- if nil, no burn
---@field public frozenTime number? -- if nil, not frozen
---@field public poisonAmount number? -- if nil, no poison
---@field public isPest boolean? true if this entity is a "pest"
---@field public _timeSinceDamaged number?
---@field public _timeSinceHealed number?
---@field public _timeSinceLostArmor number?
---@field public _timeSinceDeployed number?
---@field public _timeSinceAutoAttacked number?
---@field public _damageLagAmount number?
---@field public damageJolt number?
---@field public _landmark boolean? marked by the Landmark blessing: the first building placed this battle
---@field public onUpdate fun(ent:ecs.Entity, dt:number)?
---@field public onDraw fun(ent:ecs.Entity, x:number, y:number)?
---@field public onAttack fun(ent:ecs.Entity)?
---@field public entitySpawned fun(ent:ecs.Entity)?
---@field public entityDeath fun(ent:ecs.Entity, killer:ecs.Entity?)?
---@field public entityHurt fun(ent:ecs.Entity, damage:number, attacker:ecs.Entity?)?
---@field public entityHealed fun(ent:ecs.Entity, amount:number, healer:ecs.Entity?)?
---@field public armorIncreased fun(ecs.Entity, number)?
---@field public armorDecreased fun(ecs.Entity, number)?
---@field public entityBuffed fun(ecs.Entity, table, number?)?
---@field public onKill fun(ecs.Entity, ecs.Entity)?
---@field public entityShootsProjectile fun(ecs.Entity, ecs.Entity)?
---@field public statusEffectApplied fun(ecs.Entity, string, number, ecs.Entity?)?
---@field public physics ecs.components.Physics?
---@field public partitions string[]?
---@field public ___removed boolean?
---@field public ___dead boolean?
local ecs_Entity = {}


