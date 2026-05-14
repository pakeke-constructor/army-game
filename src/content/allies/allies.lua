
/*

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

*/

g.defineEntity("pest", {
    image = "pest",
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "ally"},
    team = "ally",
    ai = {
        target = "enemy",
    },
    attack = {
        attackType = "melee",
    },
    isPest = true,
    baseAttackDamage = 1,
    baseAttackSpeed = 1,
    baseAttackRange = 18,
    baseMoveSpeed = 60,
    baseMaxHealth = 1,
})



g.defineSquad("diver_squad", {
    name = loc("Divers"),
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
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 8,
        baseArmor = 2,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"pressure"},
    cost = {blue = 1},
})



g.defineSquad("monk_squad", {
    name = loc("Monks"),
    rarity = g.RARITIES.COMMON,
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
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 8,
    },
    unitCount = 6,
    icon = "example_squad_icon",
    perks = {"healthy_spirit"},
    cost = {blue = 1},
})



g.defineSquad("forest_sprite_squad", {
    name = loc("Forest Sprites"),
    rarity = g.RARITIES.COMMON,
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
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 5,
    },
    unitCount = 6,
    icon = "example_squad_icon",
    perks = {"restore"},
    cost = {green = 1},
})



g.defineSquad("druid_squad", {
    name = loc("Druids"),
    rarity = g.RARITIES.COMMON,
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
        baseHealPower = 2,
        baseAttackSpeed = 0.5,
        baseAttackRange = 70,
        baseMoveSpeed = 50,
        baseMaxHealth = 7,
    },
    unitCount = 6,
    icon = "example_squad_icon",
    perks = {"vitalize"},
    cost = {green = 1},
})



g.defineSquad("cook_squad", {
    name = loc("Cooks"),
    rarity = g.RARITIES.COMMON,
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
        baseHealPower = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 60,
        baseMoveSpeed = 55,
        baseMaxHealth = 5,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    cost = {green = 1},
})



g.defineSquad("peasant_squad", {
    name = loc("Peasants"),
    rarity = g.RARITIES.COMMON,
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
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 60,
        baseMaxHealth = 8,
    },
    unitCount = 10,
    icon = "example_squad_icon",
    cost = {green = 1},
})



g.defineSquad("militia_squad", {
    name = loc("Militia"),
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
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 10,
        baseArmor = 5,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    cost = {blue = 2},
})



g.defineSquad("gremlin_technician_squad", {
    name = loc("Gremlin Technicians"),
    rarity = g.RARITIES.COMMON,
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
        baseAttackDamage = 3,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 60,
        baseMaxHealth = 6,
        baseArmor = 1,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"volatile"},
    cost = {red = 1},
})



g.defineSquad("barbarian_squad", {
    name = loc("Barbarians"),
    rarity = g.RARITIES.COMMON,
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
        baseAttackDamage = 3,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 65,
        baseMaxHealth = 6,
    },
    unitCount = 6,
    icon = "example_squad_icon",
    perks = {"bloodlust"},
    cost = {red = 1},
})



g.defineSquad("blade_thrower_squad", {
    name = loc("Blade Throwers"),
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "longbowman",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = {
            target = "enemy",
        },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 180,
        },
        baseAttackDamage = 3,
        baseAttackSpeed = 1,
        baseAttackRange = 70,
        baseMoveSpeed = 55,
        baseMaxHealth = 6,
    },
    unitCount = 6,
    icon = "example_squad_icon",
    cost = {red = 1},
})



g.defineSquad("archer_squad", {
    name = loc("Archers"),
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "longbowman",
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
        baseAttackSpeed = 1,
        baseAttackRange = 150,
        baseMoveSpeed = 55,
        baseMaxHealth = 5,
    },
    unitCount = 8,
    icon = "example_squad_icon",
    cost = {blue = 1},
})



g.defineSquad("orcball_player_squad", {
    name = loc("Orcball Players"),
    rarity = g.RARITIES.COMMON,
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
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 70,
        baseMaxHealth = 8,
        baseArmor = 4,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"body_slam"},
    cost = {blue = 1},
})



g.defineSquad("defender_squad", {
    name = loc("Defenders"),
    rarity = g.RARITIES.COMMON,
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
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 10,
        baseArmor = 2,
    },
    unitCount = 6,
    icon = "example_squad_icon",
    perks = {"knockback"},
    cost = {blue = 1},
})



g.defineSquad("brewer_squad", {
    name = loc("Brewers"),
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "brewer",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = {
            target = "enemy",
        },
        attack = {
            attackType = "melee",
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



g.defineSquad("aggravator_7000_squad", {
    name = loc("Aggravator 7000"),
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
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 40,
        baseArmor = 10,
    },
    unitCount = 1,
    icon = "example_squad_icon",
    perks = {"racket"},
    cost = {red = 1, blue = 1},
})



g.defineSquad("hog_squad", {
    name = loc("Hogs of War"),
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
        baseAttackDamage = 1,
        baseAttackSpeed = 1.5,
        baseAttackRange = 18,
        baseMoveSpeed = 70,
        baseMaxHealth = 14,
    },
    unitCount = 6,
    icon = "example_squad_icon",
    cost = {green = 1},
})



g.defineSquad("giant_toad_squad", {
    name = loc("Giant Toads"),
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
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 40,
        baseMaxHealth = 20,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    cost = {green = 1},
})



g.defineSquad("infested_squad", {
    name = loc("The Infested"),
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
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 60,
        baseMaxHealth = 6,
    },
    unitCount = 8,
    icon = "example_squad_icon",
    perks = {"infestation"},
    cost = {green = 1},
})



g.defineSquad("tribute_squad", {
    name = loc("Tributes"),
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
        baseAttackDamage = 1,
        baseAttackSpeed = 0.5,
        baseAttackRange = 18,
        baseMoveSpeed = 40,
        baseMaxHealth = 4,
    },
    unitCount = 10,
    icon = "example_squad_icon",
    perks = {"his_gratitude"},
    cost = {red = 1},
})



g.defineSquad("grime_executioner_squad", {
    name = loc("Grime Executioners"),
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
        baseAttackDamage = 6,
        baseAttackSpeed = 0.5,
        baseAttackRange = 18,
        baseMoveSpeed = 45,
        baseMaxHealth = 10,
    },
    unitCount = 6,
    icon = "example_squad_icon",
    cost = {red = 2},
})



g.defineSquad("berserker_squad", {
    name = loc("Berserkers"),
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
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 65,
        baseMaxHealth = 16,
    },
    unitCount = 6,
    icon = "example_squad_icon",
    perks = {"enrage"},
    cost = {red = 2},
})



g.defineSquad("exo_soldier_squad", {
    name = loc("Exo-Soldiers"),
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
        baseAttackDamage = 1,
        baseAttackSpeed = 1.5,
        baseAttackRange = 18,
        baseMoveSpeed = 85,
        baseMaxHealth = 6,
    },
    unitCount = 8,
    icon = "example_squad_icon",
    cost = {yellow = 1},
})



g.defineSquad("prospector_squad", {
    name = loc("Prospectors"),
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
        baseAttackDamage = 4,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 10,
        baseArmor = 2,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"strike_gold"},
    cost = {yellow = 2},
})



g.defineSquad("quartz_cannoneer_squad", {
    name = loc("Quartz Cannoneers"),
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "longbowman",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = {
            target = "enemy",
        },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 350,
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 450,
        baseMoveSpeed = 45,
        baseMaxHealth = 8,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"pinpoint"},
    cost = {blue = 1, red = 1},
})

