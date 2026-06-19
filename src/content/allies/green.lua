



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
    perks = {"restore"},
    cost = {green = 1},
})



g.defineSquad("druid_squad", {
    name = loc("Druids"),
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "druids",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        ai = {
            target = "ally",
        },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 250,
        },
        weapon = {
            image = "druids_staff",
            type = "staff",
        },
        isHealer = true,
        baseHealPower = 2,
        baseAttackSpeed = 0.5,
        baseAttackRange = 70,
        baseMoveSpeed = 50,
        baseMaxHealth = 7,
    },
    unitCount = 6,
    perks = {"vitalize"},
    cost = {green = 1},
})



g.defineSquad("cook_squad", {
    name = loc("Cooks"),
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "cook",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        ai = {
            target = "ally",
        },
        attack = {
            attackType = "ranged",
            projectileType = "bread",
            projectileSpeed = 250,
            projectileHoming = true,
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
    icon = "cook_uniticon",
    cost = {green = 1},
})




g.defineSquad("peasant_squad", {
    name = loc("Peasants"),
    rarity = g.RARITIES.COMMON,
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
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 60,
        baseMaxHealth = 8,
    },
    unitCount = 10,
    icon = "peasant_uniticon",
    cost = {green = 1},
})




g.defineSquad("hog_squad", {
    name = loc("Hogs of War"),
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "warhog",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
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
    cost = {green = 1},
})



g.defineSquad("giant_toad_squad", {
    name = loc("Giant Toads"),
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "gianttoad",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
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
    cost = {green = 1},
})


g.defineSquad("treant_squad", {
    name = loc("Treants"),
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "treant",
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 2 },
        attack = {
            attackType = "melee",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.8,
        baseAttackRange = 24,
        baseMoveSpeed = 35,
        baseMaxHealth = 24,
        baseStartingArmor = 2,
    },
    unitCount = 5,
    icon = "treants_uniticon",
    perks = {"growth"},
    cost = {green = 2},
    ---@param info g.SquadInfo
    ---@param entities ecs.Entity[]
    onDeploySquad = function(info, entities)
        for _, ent in ipairs(entities) do
            ent._growthGreen = info.cost.green
        end
    end,
})




g.defineSquad("infested_squad", {
    name = loc("The Infested"),
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "the_infested",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
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
    icon = "theinfested_uniticon",
    perks = {"infestation"},
    cost = {green = 1},
})



g.defineSquad("friendly_giant_squad", {
    name = loc("Friendly Giant"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "friendlygiant",
        physics = { shape = "circle", radius = 14, ox = 0, oy = 0, mass = 3 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "friendlygiant_bigstick",
            type = "sword",
        },
        baseAttackDamage = 5,
        baseAttackSpeed = 0.5,
        baseAttackRange = 40,
        baseMoveSpeed = 35,
        baseMaxHealth = 300,
    },
    unitCount = 1,
    cost = {green = 2},
})



g.defineSquad("forest_sentry_squad", {
    name = loc("Forest Sentries"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "forestsentry",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 350,
        },
        weapon = {
            image = "forest_sentry_bow",
            type = "bow",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 220,
        baseMoveSpeed = 55,
        baseMaxHealth = 6,
    },
    unitCount = 4,
    icon = "forestsentries_uniticon",
    perks = {"life_force"},
    cost = {green = 1},
})



g.defineSquad("arcane_blossom_squad", {
    name = loc("Arcane Blossoms"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "arcaneblossom",
        physics = { shape = "circle", radius = 7, ox = 0, oy = 0, mass = 1 },
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
    icon = "arcaneblossom_uniticon",
    perks = {"magnificence"},
    cost = {green = 1},
})




g.defineSquad("world_tree_squad", {
    name = loc("World Tree"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "worldtree",
        isBuilding = true,
        physics = { shape = "circle", radius = 16, ox = 0, oy = 0, mass = 1, isStatic = true },
        baseMaxHealth = 300,
        baseStartingArmor = 5,
    },
    unitCount = 1,
    perks = {"her_wrath"},
    cost = {green = 2},
})




g.defineSquad("hive_recycler_squad", {
    name = loc("Hive Recyclers"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "hiverecycler",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
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
    perks = {"swarmsurge"},
    cost = {green = 1},
})


g.defineSquad("living_forest_squad", {
    name = loc("Living Forest"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "livingforest_body", -- TODO: Animate legs with `livingforest_legs`.
        physics = { shape = "circle", radius = 7, ox = 0, oy = 0, mass = 2 },
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
    icon = "livingforest_uniticon",
    perks = {"circle_of_life"},
    cost = {green = 1},
})



g.defineSquad("lifesmith_squad", {
    name = loc("Lifesmiths"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "lifesmith",
        physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 2 },
        ai = { target = "ally" },
        attack = { attackType = "melee" },
        weapon = { image = "lifesmith_hammer", type = "sword" },
        isHealer = true,
        baseHealPower = 2,
        baseAttackSpeed = 0.8,
        baseAttackRange = 22,
        baseMoveSpeed = 45,
        baseMaxHealth = 18,
        baseStartingArmor = 0,
    },
    unitCount = 6,
    icon = "lifesmiths_uniticon",
    perks = {"forge_life"},
    cost = {green = 1},
})



g.defineSquad("swarm_squad", {
    name = loc("The Swarm"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "theswarm",
        physics = { shape = "circle", radius = 4, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "melee" },
        weapon = { image = "theswarm_grassblade", type = "sword" },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 70,
        baseMaxHealth = 3,
    },
    unitCount = 20,
    icon = "theswarm_uniticon",
    cost = {green = 2},
})
