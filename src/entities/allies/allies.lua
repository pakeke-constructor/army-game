


g.defineEntity("militia", {
    image = "militia",
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "ally"},
    team = "ally",
    ai = {
        target = "enemy",
        getPriority = function(selfEnt, targEnt)
            return 0
        end,
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 10,
    baseAttackSpeed = 1,
    baseAttackRange = 18,
    baseMoveSpeed = 60,
    baseMaxHealth = 50,
    onDraw = function (ent)
        love.graphics.circle("line", ent.x,ent.y, ent.attackRange)
    end
})


g.defineEntity("archer", {
    image = "longbowman", -- placeholder
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "ally"},
    team = "ally",
    ai = {
        target = "enemy",
        getPriority = function(selfEnt, targEnt)
            return 0
        end,
    },
    attack = {
        attackType = "ranged",
        projectileType = "arrow",
        projectileSpeed = 250,
    },
    baseAttackDamage = 8,
    baseAttackSpeed = 0.8,
    baseAttackRange = 200,
    baseMoveSpeed = 50,
    baseMaxHealth = 30,
    onDraw = function (ent)
        love.graphics.circle("line", ent.x,ent.y, ent.attackRange)
    end
})


g.defineSquad("militia_squad", {
    entityId = "militia",
    count = 4,
    icon = "squadborder_gold",
})

g.defineSquad("archer_squad", {
    entityId = "archer",
    count = 4,
    icon = "squadborder_gold",
})


