
--[[

g.defineSquad("archer_squad", {
    name = loc("Archer squad"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "longbowman", -- placeholder
        shadow = {},
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
            aoeRadius = 1
        },
        shadow = {},
        weapon = {
            image = "longbow",
            type = "bow",
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

    statUpgradeScaling = {attackSpeed = 0.5},
})




g.defineSquad("healer_archer_squad", {
    name = loc("Healer archer squad"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "longbowman",
        shadow = {},
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
            image = "militia", -- placeholder
            type = "bow",
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
        shadow = {},
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
    perks = {},
    cost = {green = 1},
})



g.defineSquad("militia_band", {
    name = loc("Militia beserkers"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "militia",
        shadow = {},
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
]]


local PURPLE_COLOR = objects.Color("#".."FFC339ED")


g.defineSquad("crystal_golems", {
    name = loc("Crystal golems"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "gargoyle", -- no crystal-golem sprite; gargoyle stand-in
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 2 },
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
        baseAttackDamage = 14,
        baseAttackSpeed = 0.8,
        baseAttackRange = 20,
        baseMoveSpeed = 45,
        baseMaxHealth = 180,
        onUpdate = function(self)
            local radius = (self.physics and self.physics.radius or 8) + 4
            local radiusSq = radius * radius
            g.iteratePartition("projectile", self.x, self.y, function(projEnt)
                if projEnt == self then return end
                if projEnt._projectileCloned then return end
                if not projEnt.projectile then return end
                if projEnt.projectile.team ~= "ally" then return end
                local dx = projEnt.x - self.x
                local dy = projEnt.y - self.y
                if dx * dx + dy * dy > radiusSq then return end

                local clone = g.spawnEntity(projEnt.type, projEnt.x, projEnt.y)
                local DRIFT = 0.80
                clone.vx = (projEnt.vx or 0) * (1 + (love.math.random() - 0.5) * DRIFT)
                clone.vy = (projEnt.vy or 0) * (1 + (love.math.random() - 0.5) * DRIFT)
                clone.vz = projEnt.vz
                clone.z = projEnt.z
                clone.projectile = helper.shallowCopy(projEnt.projectile)

                clone.color = PURPLE_COLOR
                clone.scale = 2
                projEnt.color = PURPLE_COLOR
                projEnt.scale = 2

                projEnt._projectileCloned = true
                clone._projectileCloned = true
            end, radius)
        end,
    },
    unitCount = 2,
    icon = "gargoyles_uniticon",
    cost = {blue = 1},
})

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
        image = "militia", -- no diver sprite; militia stand-in
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
        image = "incense_priest",
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
        weapon = {
            image = "militia_sword",
            type = "sword",
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 10,
        baseArmor = 5,
    },
    unitCount = 4,
    icon = "militia_uniticon",
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
        weapon = {
            image = "militia_sword",
            type = "sword",
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
        image = "barbarian",
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
        weapon = {
            image = "longbow",
            type = "bow",
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 150,
        baseMoveSpeed = 55,
        baseMaxHealth = 5,
    },
    unitCount = 8,
    icon = "archers_uniticon",
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
        weapon = {
            image = "militia_sword",
            type = "sword",
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
        weapon = {
            image = "militia_sword",
            type = "sword",
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
        weapon = {
            image = "militia", -- placeholder
            type = "sword",
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
        weapon = {
            image = "militia", -- placeholder
            type = "sword",
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
        weapon = {
            image = "militia", -- placeholder
            type = "sword",
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
        weapon = {
            image = "militia", -- placeholder
            type = "sword",
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
        weapon = {
            image = "militia", -- placeholder
            type = "sword",
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



g.defineSquad("incense_holder_squad", {
    name = loc("Incense Holders"),
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
        weapon = {
            image = "militia", -- placeholder
            type = "bow",
        },
        isHealer = true,
        baseHealPower = 3,
        baseAttackSpeed = 0.5,
        baseAttackRange = 300,
        baseMoveSpeed = 45,
        baseMaxHealth = 7,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"invigorate"},
    cost = {blue = 2},
})



g.defineSquad("clay_troll_squad", {
    name = loc("Clay Trolls"),
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
        weapon = {
            image = "militia", -- placeholder
            type = "sword",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.5,
        baseAttackRange = 18,
        baseMoveSpeed = 40,
        baseMaxHealth = 18,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"protective_coating"},
    cost = {blue = 1},
})



g.defineSquad("dagger_bearer_squad", {
    name = loc("Dagger Bearers"),
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
        weapon = {
            image = "militia", -- placeholder
            type = "sword",
        },
        baseAttackDamage = 3,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 65,
        baseMaxHealth = 12,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"ritual_sacrifice"},
    cost = {red = 1},
})



g.defineSquad("soul_furnace_squad", {
    name = loc("Soul Furnaces"),
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
        weapon = {
            image = "militia", -- placeholder
            type = "sword",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 45,
        baseMaxHealth = 35,
        baseArmor = 3,
    },
    unitCount = 3,
    icon = "example_squad_icon",
    perks = {"conflagrate"},
    cost = {red = 1},
})



--[[ ETERNAL SOLDIERS (backburner)
do
    local function makeDefy()
        return {
            entityDeath = function(ent, killer)
                local sqScope = ent.scope and (ent.scope.shared and ent.scope or ent.scope.parent)
                local copy = g.spawnEntity(ent.type, ent.x, ent.y)
                copy.squad = ent.squad
                copy.scope = sqScope
                if ent.buffs then
                    for stat, amount in pairs(ent.buffs) do
                        g.buffEntity(copy, stat, amount)
                    end
                end
                g.buffEntity(copy, "attackDamage", 1)
                g.addCustomEffect(copy, makeDefy(), 15)
            end,
        }
    end

    g.defineSquad("eternal_soldier_squad", {
        name = loc("Eternal Soldiers"),
        rarity = g.RARITIES.RARE,
        entityDef = {
            image = "barbarian",
            physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
            partitions = {"unit", "ally"},
            team = "ally",
            ai = { target = "enemy" },
            attack = { attackType = "melee" },
            weapon = { image = "orc_battleaxe", type = "sword" },
            baseAttackDamage = 4,
            baseAttackSpeed = 1.3,
            baseAttackRange = 18,
            baseMoveSpeed = 38,
            baseMaxHealth = 18,
        },
        unitCount = 3,
        icon = "example_squad_icon",
        perks = {"defy"},
        cost = {red = 1},
        onDeploySquad = function(info, entities)
            for _, ent in ipairs(entities) do
                g.addCustomEffect(ent, makeDefy(), 15)
            end
        end,
    })
end
]]



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
        weapon = {
            image = "militia", -- placeholder
            type = "bow",
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



g.defineSquad("living_entropy_squad", {
    name = loc("Living Entropy"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "his_manifestation",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 300 },
        weapon = { image = "placeholder", type = "bow" },
        baseAttackDamage = 6,
        baseAttackSpeed = 0.8,
        baseAttackRange = 150,
        baseMoveSpeed = 50,
        baseMaxHealth = 15,
    },
    unitCount = 2,
    icon = "example_squad_icon",
    perks = {"explosive"},
    cost = {red = 2},
})



g.defineSquad("war_elephant_squad", {
    name = loc("War Elephants"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "war_hog",
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 2 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
        baseAttackDamage = 4,
        baseAttackSpeed = 0.6,
        baseAttackRange = 22,
        baseMoveSpeed = 40,
        baseMaxHealth = 60,
        baseArmor = 12,
    },
    unitCount = 2,
    icon = "example_squad_icon",
    perks = {"helmheart"},
    cost = {blue = 2},
})



g.defineSquad("pain_elemental_squad", {
    name = loc("Pain Elementals"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
        baseAttackDamage = 5,
        baseAttackSpeed = 1.2,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 15,
    },
    unitCount = 2,
    icon = "example_squad_icon",
    perks = {"sadistic"},
    cost = {red = 1},
})



g.defineSquad("living_spell_squad", {
    name = loc("Living Spells"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 250 },
        weapon = { image = "placeholder", type = "bow" },
        baseAttackDamage = 3,
        baseAttackSpeed = 0.4,
        baseAttackRange = 130,
        baseMoveSpeed = 40,
        baseMaxHealth = 12,
    },
    unitCount = 3,
    icon = "example_squad_icon",
    perks = {"sputter"},
    cost = {blue = 1},
})



g.defineSquad("magnet_elemental_squad", {
    name = loc("Magnet Elementals"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "gargoyle",
        physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 280 },
        weapon = { image = "placeholder", type = "bow" },
        baseAttackDamage = 2,
        baseAttackSpeed = 0.7,
        baseAttackRange = 120,
        baseMoveSpeed = 50,
        baseMaxHealth = 20,
        baseArmor = 3,
    },
    unitCount = 2,
    icon = "example_squad_icon",
    perks = {"shrapnelmancy"},
    cost = {blue = 1},
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
        baseArmor = 3,
    },
    unitCount = 3,
    icon = "treants_uniticon",
    perks = {"magnificence"},
    cost = {green = 1},
})



g.defineSquad("bell_creature_squad", {
    name = loc("Bell Creatures"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "militia", -- placeholder
        physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.8,
        baseAttackRange = 20,
        baseMoveSpeed = 40,
        baseMaxHealth = 20,
        baseArmor = 5,
    },
    unitCount = 3,
    icon = "example_squad_icon",
    perks = {"reverberate"},
    cost = {blue = 1},
})



g.defineSquad("gold_mine_squad", {
    name = loc("Gold Mine"),
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "militia", -- placeholder
        isBuilding = true,
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 1, isStatic = true },
        partitions = {"unit", "ally"},
        team = "ally",
        baseMaxHealth = 16,
    },
    unitCount = 1,
    icon = "example_squad_icon",
    perks = {"extraction"},
    cost = {yellow = 2},
})



g.defineSquad("the_great_factory_squad", {
    name = loc("The Great Factory"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "militia", -- placeholder
        isBuilding = true,
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 1, isStatic = true },
        partitions = {"unit", "ally"},
        team = "ally",
        baseMaxHealth = 40,
    },
    unitCount = 1,
    icon = "example_squad_icon",
    perks = {"duplication"},
    cost = {yellow = 2},
    onDeploySquad = function(info, entities)
        local squad = entities[1] and entities[1].squad
        g.addBattleSquad(info.id, squad and squad.level or 1)
    end,
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
        baseArmor = 5,
    },
    unitCount = 1,
    icon = "example_squad_icon",
    perks = {"her_wrath"},
    cost = {green = 2},
})



g.defineSquad("immortal_eye_squad", {
    name = loc("The Immortal Eye"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "militia", -- placeholder
        isBuilding = true,
        physics = { shape = "circle", radius = 10, ox = 0, oy = 0, mass = 1, isStatic = true },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 300 },
        weapon = { image = "placeholder", type = "bow" },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.8,
        baseAttackRange = 220,
        baseMaxHealth = 80,
        baseArmor = 10,
    },
    unitCount = 1,
    icon = "example_squad_icon",
    perks = {"rebirth"},
    cost = {blue = 2},
})



g.defineSquad("laser_gunner_squad", {
    name = loc("Laser Gunners"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "longbowman",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 280 },
        weapon = { image = "placeholder", type = "bow" },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.5,
        baseAttackRange = 120,
        baseMoveSpeed = 50,
        baseMaxHealth = 8,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"laser_focus"},
    cost = {blue = 1},
})



g.defineSquad("endless_army_squad", {
    name = loc("The Endless Army"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 5,
        baseArmor = 1,
    },
    unitCount = 1,
    icon = "example_squad_icon",
    perks = {"mass_production"},
    cost = {yellow = 1},
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



g.defineSquad("world_devourer_squad", {
    name = loc("World Devourers"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
        baseAttackDamage = 2,
        baseAttackSpeed = 1.5,
        baseAttackRange = 20,
        baseMoveSpeed = 55,
        baseMaxHealth = 20,
        baseArmor = 0,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"consumption"},
    cost = {green = 1, red = 1},
})



g.defineSquad("doom_herald_squad", {
    name = loc("Doom Heralds"),
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
        baseHealPower = 3,
        baseAttackSpeed = 0.4,
        baseAttackRange = 200,
        baseMoveSpeed = 35,
        baseMaxHealth = 12,
    },
    unitCount = 2,
    icon = "example_squad_icon",
    perks = {"omen"},
    cost = {red = 1},
})



g.defineSquad("wealth_elemental_squad", {
    name = loc("Wealth Elementals"),
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "militia", -- placeholder
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 2 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = { target = "enemy" },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.6,
        baseAttackRange = 22,
        baseMoveSpeed = 38,
        baseMaxHealth = 80,
        baseArmor = 8,
    },
    unitCount = 2,
    icon = "example_squad_icon",
    perks = {"golden_bulk"},
    cost = {yellow = 1},
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
        baseArmor = 4,
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
        baseArmor = 0,
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
