


g.defineEntity("demon", {
    image = "demon",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "enemy"},
    team = "enemy",
    ai = {
        target = "enemy",
        getPriority = function(selfEnt, targEnt)
            return 0
        end,
    },
    weapon = {
        type = "spear",
        image = "demon_pitchfork"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 2,
    baseAttackSpeed = 1,
    baseAttackRange = 80,
    baseMoveSpeed = 50,
    baseMaxHealth = 10,
})

g.defineEntity("archerdemon", {
    image = "archerdemon",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "enemy"},
    team = "enemy",
    ai = {
        target = "enemy",
        getPriority = function(selfEnt, targEnt)
            return 0
        end,
    },
    weapon = {
        type = "bow",
        image = "archerdemon_bow"
    },
    attack = {
        attackType = "ranged",
        projectileType = "arrow",
        projectileSpeed = 350,
    },
    baseAttackDamage = 0.6,
    baseAttackSpeed = 0.4,
    baseAttackRange = 600,
    baseMoveSpeed = 45,
    baseMaxHealth = 5,
})

-- FIXME: Balancing of this

g.defineEntity("blazingbombardier", {
    image = "blazingbombardier",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "enemy"},
    team = "enemy",
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "bow",
        image = "blazingbombardier_bomb"
    },
    attack = {
        attackType = "ranged",
        projectileType = "blazingbombardier_bomb",
        projectileSpeed = 250,
    },
    baseAttackDamage = 1,
    baseAttackSpeed = 0.5,
    baseAttackRange = 350,
    baseMoveSpeed = 35,
    baseMaxHealth = 4,
})

g.defineEntity("brimstonecore", {
    image = "brimstonecore",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "enemy"},
    team = "enemy",
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "object",
        image = "brimstonecore_shards"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 1,
    baseAttackSpeed = 1,
    baseAttackRange = 80,
    baseMoveSpeed = 50,
    baseMaxHealth = 16,

    onDraw = function(ent)
        local dir = ent.id % 2 * 2 - 1
        local t = love.timer.getTime()
        local rot = (dir * consts.TAU * t / 5) % consts.TAU
        local _, h = g.getImageSize(ent.image)
        g.drawImage("brimstonecore_shards", ent.x, ent.y - h / 2, rot)
    end,
    entityDeath = function(ent)
        g.explosion(ent.x, ent.y, 5, 17, ent)
    end,
})

g.defineEntity("charredsoul", {
    image = "charredsoul",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "enemy"},
    team = "enemy",
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "object",
        image = "brimstonecore_shards"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 2,
    baseAttackSpeed = 0.5,
    baseAttackRange = 80,
    baseMoveSpeed = 50,
    baseMaxHealth = 6,

    entitySpawned = function(ent)
        ent._nextBuffTime = 0
    end,
    entityUpdate = function(ent, dt)
        ent._nextBuffTime = ent._nextBuffTime + dt
        while ent._nextBuffTime >= 3 do
            g.buffEntity(ent, "attackSpeed", 0.2)
            ent._nextBuffTime = ent._nextBuffTime - 3
        end
    end,
})
