



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
        baseStartingArmor = 2,
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
        baseStartingArmor = 5,
    },
    unitCount = 4,
    icon = "militia_uniticon",
    cost = {blue = 2},
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
        baseStartingArmor = 4,
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
        baseStartingArmor = 2,
    },
    unitCount = 6,
    icon = "example_squad_icon",
    perks = {"knockback"},
    cost = {blue = 1},
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
        baseStartingArmor = 12,
    },
    unitCount = 2,
    icon = "example_squad_icon",
    perks = {"helmheart"},
    cost = {blue = 2},
})



-- perk was removed; this squad removed too.
------------
-- g.defineSquad("living_spell_squad", {
--     name = loc("Living Spells"),
--     rarity = g.RARITIES.RARE,
--     entityDef = {
--         image = "militia",
--         physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
--         partitions = {"unit", "ally"},
--         team = "ally",
--         ai = { target = "enemy" },
--         attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 250 },
--         weapon = { image = "placeholder", type = "bow" },
--         baseAttackDamage = 3,
--         baseAttackSpeed = 0.4,
--         baseAttackRange = 130,
--         baseMoveSpeed = 40,
--         baseMaxHealth = 12,
--     },
--     unitCount = 3,
--     icon = "example_squad_icon",
--     perks = {"sputter"},
--     cost = {blue = 1},
-- })



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
        baseStartingArmor = 3,
    },
    unitCount = 2,
    icon = "example_squad_icon",
    perks = {"shrapnelmancy"},
    cost = {blue = 1},
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
        baseStartingArmor = 10,
    },
    unitCount = 1,
    icon = "example_squad_icon",
    perks = {"rebirth"},
    cost = {blue = 2},
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
        baseStartingArmor = 5,
    },
    unitCount = 3,
    icon = "example_squad_icon",
    perks = {"reverberate"},
    cost = {blue = 1},
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

