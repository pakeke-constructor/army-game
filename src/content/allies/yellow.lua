




g.defineSquad("exo_soldier_squad", {
    name = loc("Exo-Soldiers"),
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
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
        baseMoveSpeed = 85,
        baseMaxHealth = 6,
    },
    unitCount = 8,
    cost = {yellow = 1},
})




g.defineSquad("prospector_squad", {
    name = loc("Prospectors"),
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "dagger", -- placeholder
            type = "sword",
        },
        baseAttackDamage = 4,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 10,
        baseStartingArmor = 2,
    },
    unitCount = 4,
    perks = {"strike_gold"},
    cost = {yellow = 2},
})



g.defineSquad("the_great_factory_squad", {
    name = loc("The Great Factory"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "militia", -- placeholder
        isBuilding = true,
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 1, isStatic = true },
        baseMaxHealth = 40,
    },
    unitCount = 1,
    perks = {"duplication"},
    onDeploySquad = function(info, entities)
        local squad = entities[1] and entities[1].squad
        g.addBattleSquad(info.id, squad and squad.level or 1)
    end,
    cost = {yellow = 2},
})



g.defineSquad("gold_mine_squad", {
    name = loc("Gold Mine"),
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "militia", -- placeholder
        isBuilding = true,
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 1, isStatic = true },
        baseMaxHealth = 16,
    },
    unitCount = 1,
    perks = {"extraction"},
    cost = {yellow = 2},
})




g.defineSquad("endless_army_squad", {
    name = loc("The Endless Army"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 5,
        baseStartingArmor = 1,
    },
    unitCount = 1,
    perks = {"mass_production"},
    cost = {yellow = 1},
})


g.defineSquad("wealth_elemental_squad", {
    name = loc("Wealth Elementals"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "militia", -- placeholder
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 2 },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.6,
        baseAttackRange = 22,
        baseMoveSpeed = 38,
        baseMaxHealth = 80,
        baseStartingArmor = 8,
    },
    unitCount = 2,
    perks = {"golden_bulk"},
    cost = {yellow = 1},
})

