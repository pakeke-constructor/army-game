


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
        projectileSpeed = 200,
    },
    baseAttackDamage = 1,
    baseAttackSpeed = 0.7,
    baseAttackRange = 600,
    baseMoveSpeed = 45,
    baseMaxHealth = 5,
})

