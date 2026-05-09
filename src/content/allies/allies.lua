


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
    baseAttackDamage = 2,
    baseAttackSpeed = 1,
    baseAttackRange = 18,
    baseMoveSpeed = 60,
    baseMaxHealth = 12,
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
    baseAttackDamage = 2,
    baseAttackSpeed = 0.8,
    baseAttackRange = 200,
    baseMoveSpeed = 50,
    baseMaxHealth = 6,
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



g.defineEntity("hog", {
    image = "militia", -- placeholder
    physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 2 },
    partitions = {"unit", "ally"},
    team = "ally",
    ai = {
        target = "enemy",
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 1,
    baseAttackSpeed = 2.0,
    baseAttackRange = 20,
    baseMoveSpeed = 80,
    baseMaxHealth = 10,
})

g.defineSquad("hogs_of_war", {
    name = loc("Hogs of War"),
    entityId = "hog",
    rarity = g.RARITIES.UNCOMMON,
    count = 6,
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


g.defineEntity("toad", {
    image = "militia", -- placeholder
    physics = { shape = "circle", radius = 7, ox = 0, oy = 0, mass = 3 },
    partitions = {"unit", "ally"},
    team = "ally",
    ai = { target = "enemy" },
    attack = { attackType = "melee" },
    baseAttackDamage = 1,
    baseAttackSpeed = 0.8,
    baseAttackRange = 20,
    baseMoveSpeed = 40,
    baseMaxHealth = 25,
})

g.defineSquad("giant_toads", {
    name = loc("Giant Toads"),
    entityId = "toad",
    rarity = g.RARITIES.COMMON,
    count = 3,
    icon = "example_squad_icon",
    perks = {},
    cost = {green = 1},
})


g.defineEntity("peasant", {
    image = "militia", -- placeholder
    physics = { shape = "circle", radius = 4, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "ally"},
    team = "ally",
    ai = { target = "enemy" },
    attack = { attackType = "melee" },
    baseAttackDamage = 1,
    baseAttackSpeed = 1,
    baseAttackRange = 18,
    baseMoveSpeed = 60,
    baseMaxHealth = 5,
})

g.defineSquad("peasants", {
    name = loc("Peasants"),
    entityId = "peasant",
    rarity = g.RARITIES.COMMON,
    count = 8,
    icon = "example_squad_icon",
    perks = {},
    cost = {green = 1},
})


g.defineSquad("archers", {
    name = loc("Archers"),
    entityId = "archer",
    rarity = g.RARITIES.COMMON,
    count = 4,
    icon = "example_squad_icon",
    perks = {},
    cost = {blue = 1},
})


g.defineEntity("blade_thrower", {
    image = "militia", -- placeholder
    physics = { shape = "circle", radius = 4, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "ally"},
    team = "ally",
    ai = { target = "enemy" },
    attack = {
        attackType = "ranged",
        projectileType = "arrow",
        projectileSpeed = 300,
    },
    baseAttackDamage = 3,
    baseAttackSpeed = 0.8,
    baseAttackRange = 55,
    baseMoveSpeed = 50,
    baseMaxHealth = 5,
})

g.defineSquad("blade_throwers", {
    name = loc("Blade Throwers"),
    entityId = "blade_thrower",
    rarity = g.RARITIES.COMMON,
    count = 4,
    icon = "example_squad_icon",
    perks = {},
    cost = {red = 1},
})


g.defineEntity("grime_executioner", {
    image = "militia", -- placeholder
    physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 2 },
    partitions = {"unit", "ally"},
    team = "ally",
    ai = { target = "enemy" },
    attack = { attackType = "melee" },
    baseAttackDamage = 8,
    baseAttackSpeed = 0.3,
    baseAttackRange = 20,
    baseMoveSpeed = 40,
    baseMaxHealth = 15,
})

g.defineSquad("grime_executioners", {
    name = loc("Grime Executioners"),
    entityId = "grime_executioner",
    rarity = g.RARITIES.RARE,
    count = 3,
    icon = "example_squad_icon",
    perks = {},
    cost = {red = 2},
})


g.defineEntity("cannon_traption", {
    image = "militia", -- placeholder
    physics = { shape = "circle", radius = 10, ox = 0, oy = 0, mass = 5 },
    partitions = {"unit", "ally"},
    team = "ally",
    ai = { target = "enemy" },
    attack = {
        attackType = "ranged",
        projectileType = "arrow",
        projectileSpeed = 450,
    },
    baseAttackDamage = 6,
    baseAttackSpeed = 0.5,
    baseAttackRange = 280,
    baseMoveSpeed = 20,
    baseMaxHealth = 30,
})

g.defineSquad("cannon_traption", {
    name = loc("Cannon-Traption"),
    entityId = "cannon_traption",
    rarity = g.RARITIES.RARE,
    count = 1,
    icon = "example_squad_icon",
    perks = {},
    cost = {yellow = 2},
})


g.defineEntity("friendly_giant", {
    image = "militia", -- placeholder
    physics = { shape = "circle", radius = 12, ox = 0, oy = 0, mass = 6 },
    partitions = {"unit", "ally"},
    team = "ally",
    ai = { target = "enemy" },
    attack = { attackType = "melee" },
    baseAttackDamage = 2,
    baseAttackSpeed = 0.8,
    baseAttackRange = 25,
    baseMoveSpeed = 50,
    baseMaxHealth = 100,
})

g.defineSquad("friendly_giant", {
    name = loc("Friendly Giant"),
    entityId = "friendly_giant",
    rarity = g.RARITIES.RARE,
    count = 1,
    icon = "example_squad_icon",
    perks = {},
    cost = {green = 2},
})


g.defineEntity("swarm_bug", {
    image = "militia", -- placeholder
    physics = { shape = "circle", radius = 3, ox = 0, oy = 0, mass = 0.3 },
    partitions = {"unit", "ally"},
    team = "ally",
    ai = { target = "enemy" },
    attack = { attackType = "melee" },
    baseAttackDamage = 1,
    baseAttackSpeed = 1.5,
    baseAttackRange = 15,
    baseMoveSpeed = 85,
    baseMaxHealth = 2,
})

g.defineSquad("the_swarm", {
    name = loc("The Swarm"),
    entityId = "swarm_bug",
    rarity = g.RARITIES.LEGENDARY,
    count = 20,
    icon = "example_squad_icon",
    perks = {},
    cost = {green = 2},
})


