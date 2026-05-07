


g.defineEntity("militia", {
    image = "militia",
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "ally"},
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
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"sharpshooter"},
    cost = {red = 1},

    statUpgradeScaling = {maxHealth = 0.5},
})




g.defineSquad("militia_squad", {
    name = loc("Militia squad"),
    entityId = "militia",
    rarity = g.RARITIES.UNCOMMON,
    unitCount = 4,
    unitCountUpgradeScaling = 2,
    icon = "example_squad_icon",
    perks = {"tough"},
    cost = {green = 1},
})



g.defineSquad("militia_band", {
    name = loc("Militia beserkers"),
    entityId = "militia",
    rarity = g.RARITIES.RARE,
    unitCount = 6,
    icon = "example_squad_icon",
    perks = {"berserker"},
    cost = {green = 1, red=1},
})

