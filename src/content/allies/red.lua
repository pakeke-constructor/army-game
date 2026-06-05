

g.defineSquad("gremlin_technician_squad", {
    name = loc("Gremlin Technicians"),
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "greenskin_assassin",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "dagger",
            type = "sword",
        },
        baseAttackDamage = 3,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 60,
        baseMaxHealth = 6,
        baseStartingArmor = 1,
    },
    unitCount = 4,
    perks = {"volatile"},
    cost = {red = 1},
})




g.defineSquad("barbarian_squad", {
    name = loc("Barbarians"),
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "barbarian",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "orc_battleaxe",
            type = "sword",
        },
        baseAttackDamage = 3,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 65,
        baseMaxHealth = 6,
    },
    unitCount = 6,
    icon = "barbarians_uniticon",
    perks = {"bloodlust"},
    cost = {red = 1},
})



g.defineSquad("blade_thrower_squad", {
    name = loc("Blade Throwers"),
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "longbowman",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 300,
        },
        weapon = {
            image = "dagger",
            type = "bow",
        },
        baseAttackDamage = 3,
        baseAttackSpeed = 1,
        baseAttackRange = 70,
        baseMoveSpeed = 55,
        baseMaxHealth = 6,
    },
    unitCount = 6,
    cost = {red = 1},
})




g.defineSquad("brewer_squad", {
    name = loc("Brewers"),
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "brewer",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "brewer_keg",
            type = "sword",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 5,
    },
    unitCount = 8,
    icon = "brewers_uniticon",
    perks = {"bolstering_brew"},
    cost = {red = 1},
})



g.defineSquad("tribute_squad", {
    name = loc("Tributes"),
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "peasant",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "peasant_pitchfork",
            type = "sword",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.5,
        baseAttackRange = 18,
        baseMoveSpeed = 40,
        baseMaxHealth = 4,
    },
    unitCount = 1,
    perks = {"his_gratitude"},
    cost = {red = 1},
})




g.defineSquad("grime_executioner_squad", {
    name = loc("Grime Executioners"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "barbarian",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "orc_battleaxe",
            type = "sword",
        },
        baseAttackDamage = 6,
        baseAttackSpeed = 0.5,
        baseAttackRange = 18,
        baseMoveSpeed = 45,
        baseMaxHealth = 10,
    },
    unitCount = 6,
    cost = {red = 2},
})



g.defineSquad("berserker_squad", {
    name = loc("Berserkers"),
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "war_hog",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "orc_battleaxe",
            type = "sword",
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 65,
        baseMaxHealth = 16,
    },
    unitCount = 6,
    perks = {"enrage"},
    cost = {red = 2},
})



g.defineSquad("dagger_bearer_squad", {
    name = loc("Dagger Bearers"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "greenskin_assassin",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "dagger",
            type = "sword",
        },
        baseAttackDamage = 3,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 65,
        baseMaxHealth = 12,
    },
    unitCount = 4,
    perks = {"ritual_sacrifice"},
    cost = {red = 1},
})



g.defineSquad("soul_furnace_squad", {
    name = loc("Soul Furnaces"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "charredsoul",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "speardemon_spear", -- placeholder
            type = "sword",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 45,
        baseMaxHealth = 35,
        baseStartingArmor = 3,
    },
    unitCount = 3,
    perks = {"conflagrate"},
    cost = {red = 1},
})


g.defineSquad("living_entropy_squad", {
    name = loc("Living Entropy"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "his_manifestation",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 300 },
        weapon = { image = "placeholder", type = "bow" },
        baseAttackDamage = 6,
        baseAttackSpeed = 0.8,
        baseAttackRange = 150,
        baseMoveSpeed = 50,
        baseMaxHealth = 15,
    },
    unitCount = 2,
    perks = {"explosive"},
    cost = {red = 2},
})



g.defineSquad("pain_elemental_squad", {
    name = loc("Pain Elementals"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "gargoyle",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
        baseAttackDamage = 5,
        baseAttackSpeed = 1.2,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 15,
    },
    unitCount = 2,
    perks = {"sadistic"},
    cost = {red = 1},
})


g.defineSquad("doom_herald_squad", {
    name = loc("Doom Heralds"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "longbowman",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        ai = { target = "ally" },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 250 },
        weapon = { image = "placeholder", type = "bow" },
        isHealer = true,
        baseHealPower = 3,
        baseAttackSpeed = 0.4,
        baseAttackRange = 200,
        baseMoveSpeed = 35,
        baseMaxHealth = 12,
    },
    unitCount = 2,
    perks = {"omen"},
    cost = {red = 1},
})

