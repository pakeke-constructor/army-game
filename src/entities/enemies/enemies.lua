


g.defineEntity("demon", {
    image = "demon",
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "enemy"},
    team = "enemy",
    ai = {
        target = "enemy",
        getPriority = function(selfEnt, targEnt)
            return 0
        end,
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 8,
    baseAttackSpeed = 1,
    baseAttackRange = 80,
    baseMoveSpeed = 50,
    baseMaxHealth = 40,
})

g.defineEntity("imp", {
    image = "archerdemon",
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "enemy"},
    team = "enemy",
    ai = {
        target = "enemy",
        getPriority = function(selfEnt, targEnt)
            return 0
        end,
    },
    attack = {
        attackType = "ranged",
        projectileType = "arrow",
        projectileSpeed = 200,
    },
    baseAttackDamage = 6,
    baseAttackSpeed = 0.7,
    baseAttackRange = 600,
    baseMoveSpeed = 45,
    baseMaxHealth = 25,
})

