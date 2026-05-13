


g.defineSquad("archer_squad", {
    name = loc("Archer squad"),
    rarity = g.RARITIES.RARE,
    entityDef = {
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
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"sharpshooter"},
    cost = {red = 1},

    statUpgradeScaling = {maxHealth = 0.5},
})



g.defineSquad("healer_archer_squad", {
    name = loc("Healer archer squad"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "longbowman",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = {
            target = "ally",
        },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 250,
        },
        isHealer = true,
        baseHealPower = 10,
        baseAttackSpeed = 0.8,
        baseAttackRange = 200,
        baseMoveSpeed = 50,
        baseMaxHealth = 30,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    cost = {red = 1},
})



g.defineSquad("militia_squad", {
    name = loc("Militia squad"),
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
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
    },
    unitCount = 4,
    unitCountUpgradeScaling = 2,
    statUpgradeScaling = {
        maxHealth = 0.5
    },
    icon = "example_squad_icon",
    perks = {"tough"},
    cost = {green = 1},
})



g.defineSquad("militia_band", {
    name = loc("Militia beserkers"),
    rarity = g.RARITIES.RARE,
    entityDef = {
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
    },
    unitCount = 6,
    icon = "example_squad_icon",
    perks = {"berserker"},
    cost = {green = 1, red=1},
})

