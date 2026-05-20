



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




g.defineSquad("forest_sprite_squad", {
    name = loc("Forest Sprites"),
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "militia", -- no forest-sprite sprite; militia stand-in
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = {
            target = "enemy",
        },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "militia_sword",
            type = "sword",
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
        image = "longbowman", -- no druid sprite; longbowman stand-in
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
        weapon = {
            image = "longbow",
            type = "bow",
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
        image = "cook",
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
        weapon = {
            image = "chefs_dish",
            type = "bow",
        },
        isHealer = true,
        baseHealPower = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 60,
        baseMoveSpeed = 55,
        baseMaxHealth = 5,
    },
    unitCount = 4,
    icon = "cooks_uniticon",
    cost = {green = 1},
})




g.defineSquad("peasant_squad", {
    name = loc("Peasants"),
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "peasant",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = {
            target = "enemy",
        },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "peasant_pitchfork",
            type = "sword",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 60,
        baseMaxHealth = 8,
    },
    unitCount = 10,
    icon = "angrymob_uniticon",
    cost = {green = 1},
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
        weapon = {
            image = "militia", -- placeholder
            type = "sword",
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
        weapon = {
            image = "militia", -- placeholder
            type = "sword",
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
        weapon = {
            image = "militia", -- placeholder
            type = "sword",
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



g.defineSquad("friendly_giant_squad", {
    name = loc("Friendly Giant"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "treant",
        physics = { shape = "circle", radius = 14, ox = 0, oy = 0, mass = 3 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = {
            target = "enemy",
        },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "orc_battleaxe",
            type = "sword",
        },
        baseAttackDamage = 5,
        baseAttackSpeed = 0.5,
        baseAttackRange = 25,
        baseMoveSpeed = 35,
        baseMaxHealth = 300,
    },
    unitCount = 1,
    icon = "example_squad_icon",
    cost = {green = 2},
})



g.defineSquad("forest_sentry_squad", {
    name = loc("Forest Sentries"),
    rarity = g.RARITIES.RARE,
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
        weapon = {
            image = "longbow",
            type = "bow",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 220,
        baseMoveSpeed = 55,
        baseMaxHealth = 6,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"life_force"},
    cost = {green = 1},
})



g.defineSquad("arcane_blossom_squad", {
    name = loc("Arcane Blossoms"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "treant",
        physics = { shape = "circle", radius = 7, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
        baseAttackDamage = 2,
        baseAttackSpeed = 0.8,
        baseAttackRange = 20,
        baseMoveSpeed = 45,
        baseMaxHealth = 30,
        baseStartingArmor = 3,
    },
    unitCount = 3,
    icon = "treants_uniticon",
    perks = {"magnificence"},
    cost = {green = 1},
})




g.defineSquad("world_tree_squad", {
    name = loc("World Tree"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "treant",
        isBuilding = true,
        physics = { shape = "circle", radius = 16, ox = 0, oy = 0, mass = 1, isStatic = true },
        partitions = {"unit", "ally"},
        team = "ally",
        baseMaxHealth = 300,
        baseStartingArmor = 5,
    },
    unitCount = 1,
    icon = "example_squad_icon",
    perks = {"her_wrath"},
    cost = {green = 2},
})




g.defineSquad("hive_recycler_squad", {
    name = loc("Hive Recyclers"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "longbowman",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "ally" },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 250 },
        weapon = { image = "placeholder", type = "bow" },
        isHealer = true,
        baseHealPower = 2,
        baseAttackSpeed = 0.6,
        baseAttackRange = 55,
        baseMoveSpeed = 35,
        baseMaxHealth = 7,
    },
    unitCount = 2,
    icon = "example_squad_icon",
    perks = {"swarmsurge"},
    cost = {green = 1},
})


g.defineSquad("living_forest_squad", {
    name = loc("Living Forest"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "treant",
        physics = { shape = "circle", radius = 7, ox = 0, oy = 0, mass = 2 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.8,
        baseAttackRange = 22,
        baseMoveSpeed = 38,
        baseMaxHealth = 45,
        baseStartingArmor = 4,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"circle_of_life"},
    cost = {green = 1},
})



g.defineSquad("lifesmith_squad", {
    name = loc("Lifesmiths"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 2 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "ally" },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
        isHealer = true,
        baseHealPower = 2,
        baseAttackSpeed = 0.8,
        baseAttackRange = 22,
        baseMoveSpeed = 45,
        baseMaxHealth = 18,
        baseStartingArmor = 0,
    },
    unitCount = 6,
    icon = "example_squad_icon",
    perks = {"forge_life"},
    cost = {green = 1},
})



g.defineSquad("swarm_squad", {
    name = loc("The Swarm"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 4, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "melee" },
        weapon = { image = "placeholder", type = "sword" },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 70,
        baseMaxHealth = 3,
    },
    unitCount = 20,
    icon = "example_squad_icon",
    cost = {green = 2},
})


