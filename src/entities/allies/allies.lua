


g.defineEntity("militia", {
    image = "militia",
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "ally"},
    traits = {g.TRAITS.TOWNSFOLK, g.TRAITS.ARTIFICE},
    team = "ally",
    ai = {
        target = "enemy",
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 10,
    baseAttackSpeed = 1,
    baseAttackRange = 18,
    baseMoveSpeed = 60,
    baseMaxHealth = 120,
})


g.defineEntity("archer", {
    image = "longbowman", -- placeholder
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "ally"},
    traits = {g.TRAITS.TOWNSFOLK},
    team = "ally",
    ai = {
        target = "enemy",
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
})

g.defineSquad("archer_squad", {
    name = loc("Archer squad"),
    rarity = g.RARITIES.RARE,
    entityId = "archer",
    count = 4,
    icon = "squadborder_gold",
})




g.defineSquad("militia_squad", {
    name = loc("Militia squad"),
    entityId = "militia",
    rarity = g.RARITIES.UNCOMMON,
    count = 4,
    icon = "squadborder_gold",
})
