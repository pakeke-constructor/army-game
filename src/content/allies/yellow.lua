
local sqhelper = require(".squad_helper")


sqhelper.defineMilitiaAndArchers("yellow")


-- ============================================================
-- BASIC UNITS: Robots (yellow)
-- ============================================================

g.defineSquad("protect_bot_squad", {
    name = "Protect-Bots",
    rarity = g.RARITIES.COMMON,
    -- tags: armor (basic tank)
    tags = {"armor"},
    entityDef = {
        image = g.leo("protectbot_unit", "exosoldiers_unit"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = g.leo("protectbot_shield", "defenders_shield"),
            type = "shield",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 14,
        baseStartingArmor = 3,
    },
    unitCount = 4,
    startingTraits = {"bot"},
    cost = {yellow = 1},
})

g.defineSquad("angry_bot_squad", {
    name = "Angry-Bots",
    rarity = g.RARITIES.COMMON,
    -- tags: attack_damage, health (basic bruiser)
    tags = {"attack_damage", "health"},
    entityDef = {
        image = g.leo("angrybot_unit", "exosoldiers_unit"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = g.leo("angrybot_sword", "exosoldiers_arm"),
            type = "sword",
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 12,
    },
    unitCount = 4,
    startingTraits = {"bot"},
    cost = {yellow = 1},
})

g.defineSquad("gun_bot_squad", {
    name = "Gun-Bots",
    rarity = g.RARITIES.COMMON,
    -- tags: ranged, projectile (basic ranged)
    tags = {"ranged", "projectile"},
    entityDef = {
        image = g.leo("gunbot_unit", "longbowman"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 350,
        },
        weapon = {
            image = g.leo("gunbot_gun", "longbow"),
            type = "bow",
            yOffset = 6
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.6,
        baseAttackRange = 130,
        baseMoveSpeed = 55,
        baseMaxHealth = 5,
    },
    unitCount = 4,
    startingTraits = {"bot"},
    cost = {yellow = 1},
})


g.defineSquad("exo_soldier_squad", {
    name = "Exo-Soldiers",
    rarity = g.RARITIES.UNCOMMON,
    tags = {"swarm"},
    entityDef = {
        image = "exosoldiers_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "exosoldiers_arm",
            type = "sword",
            xOffset = 5,
            drawBehind = true
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




g.defineSquad("spark_bot_squad", {
    name = "Spark-Bots",
    rarity = g.RARITIES.UNCOMMON,
    tags = {"lightning", "death_trigger"},
    entityDef = {
        image = g.leo("sparkbots_unit", "exosoldiers_unit"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 60,
        baseMaxHealth = 8,
    },
    unitCount = 6,
    startingTraits = {"bot"},
    perks = {{
        name = "Overload",
        description = g.loc2("On-death, emit lightning dealing damage equal to level."),
        image = "coin_icon",
        handlers = {
            entityDeath = function(ent)
                local level = (ent.squad and ent.squad.level) or 1
                g.lightning(ent.x, ent.y, level, ent)
            end,
        },
    }},
    cost = {yellow = 1},
})



g.defineSquad("engineer_squad", {
    name = "Engineers",
    rarity = g.RARITIES.UNCOMMON,
    tags = {"building", "attack_damage"},
    entityDef = {
        image = g.leo("engineers_unit", "prospectors_unit"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "melee" },
        weapon = {
            image = g.leo("engineers_wrench", "prospectors_pickaxe"),
            type = "sword",
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 8,
    },
    unitCount = 4,
    startingTraits = {"bot"},
    perks = {{
        name = "Industrial Momentum",
        description = g.loc2("While 2 buildings are alive, this unit has triple (ATK) and movement speed."),
        image = g.leo("engineers_perk", "coin_icon"),
        handlers = {
            getAttackDamageMultiplier = function(ent)
                local buildings = 0
                for _, ally in ipairs(g.getAllyList()) do
                    if g.isAlive(ally) and ally.isBuilding then
                        buildings = buildings + 1
                    end
                end
                if buildings >= 2 then return 3 end
            end,
            getMoveSpeedMultiplier = function(ent)
                local buildings = 0
                for _, ally in ipairs(g.getAllyList()) do
                    if g.isAlive(ally) and ally.isBuilding then
                        buildings = buildings + 1
                    end
                end
                if buildings >= 2 then return 3 end
            end,
        },
    }},
    cost = {yellow = 1},
})


g.defineEntity("clanker_bot", {
    image = g.leo("clankerbot_unit", "angrybot_unit"),
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    partitions = {"unit", "ally"},
    team = "ally",
    ai = { target = "enemy" },
    attack = { attackType = "melee" },
    baseAttackDamage = 2,
    baseAttackSpeed = 1,
    baseAttackRange = 18,
    baseMoveSpeed = 55,
    baseMaxHealth = 2,
})


g.defineSquad("clanker_factory_squad", {
    name = "Clanker Factory",
    rarity = g.RARITIES.RARE,
    tags = {"building", "swarm"},
    entityDef = {
        image = g.leo("clankerfactory_unit", "greatfactory_unit"),
        isBuilding = true,
        physics = { shape = "circle", radius = 12, ox = 0, oy = 0, mass = 1, isStatic = true },
        baseMaxHealth = 40,
    },
    statUpgradeScaling = {maxHealth = 0.2},
    unitCount = 1,
    perks = {{
        name = "Assembly Line",
        description = g.loc2("Produces 1 Clanker-Bot per second. 2 (HP), 2 (ATK)"),
        image = g.leo("clankerfactory_perk", "coin_icon"),
        rawHandlers = {
            perSecondUpdate = function(ent)
                if not g.isAlive(ent) then return end
                local bot = g.spawnEntity("clanker_bot", ent.x, ent.y + 16)
                g.addTrait(bot, "bot")
            end,
        },
    }},
    cost = {yellow = 2},
})

g.defineSquad("prospector_squad", {
    name = "Prospectors",
    rarity = g.RARITIES.UNCOMMON,
    tags = {"economy", "armor"},
    entityDef = {
        image = "prospectors_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "prospectors_pickaxe",
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
    perks = {{
        name = "Strike Gold",
        description = g.loc2("On-kill, gain 1 (COIN)."),
        image = "coin_icon",
        handlers = {
            onKill = function(ent, target)
                g.addGold(1)
            end,
        },
    }},
    cost = {yellow = 2},
})



g.defineSquad("the_great_factory_squad", {
    name = "The Great Factory",
    rarity = g.RARITIES.LEGENDARY,
    tags = {"building", "deployment"},
    entityDef = {
        image = "greatfactory_unit",
        isBuilding = true,
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 1, isStatic = true },
        baseMaxHealth = 40,
    },
    statUpgradeScaling = {maxHealth = 0.2},
    unitCount = 1,
    icon = "greatfactory_uniticon",
    perks = {{
        -- Label purpose only
        name = "Duplication",
        description = loc("On-deploy, add a copy of the deployed squad to your bench for the fight."),
        image = "coin_icon",
    }},
    onDeploySquad = function(info, entities)
        local squad = entities[1] and entities[1].squad
        g.addBattleSquad(info.id, squad and squad.level or 1)
    end,
    cost = {yellow = 2},
})



g.defineSquad("gold_mine_squad", {
    name = "Gold Mine",
    rarity = g.RARITIES.UNCOMMON,
    tags = {"building", "economy", "death_trigger"},
    entityDef = {
        image = "goldmine_unit",
        isBuilding = true,
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 1, isStatic = true },
        baseMaxHealth = 16,
    },
    statUpgradeScaling = {maxHealth = 0.15},
    unitCount = 1,
    perks = {{
        name = "Extraction",
        description = g.loc2("When an enemy dies, gain 2 (COIN)."),
        image = "coin_icon",
        rawHandlers = {
            ---@param dead ecs.Entity
            entityDeath = function(_, dead)
                if dead and dead.team == "enemy" then
                    g.addGold(2)
                end
            end,
        },
    }},
    cost = {yellow = 2},
})


g.defineSquad("living_laboratory_squad", {
    name = "Living Laboratory",
    rarity = g.RARITIES.RARE,
    tags = {"building", "buffing"},
    entityDef = {
        image = "livinglaboratory",
        isBuilding = true,
        physics = { shape = "circle", radius = 14, ox = 0, oy = 0, mass = 1, isStatic = true },
        baseMaxHealth = 120,
        baseStartingArmor = 4,
    },
    statUpgradeScaling = {startingArmor = 0.2, maxHealth = 0.1},
    unitCount = 1,
    perks = {{
        name = "Eureka",
        description = loc("When this unit is Buffed, spreads the buff to 6 nearby allies."),
        image = "coin_icon",
        handlers = {
            entityBuffed = function(ent, stat, increase)
                ---@type [ecs.Entity,number][]
                local entAllies = {}
                g.iteratePartition("ally", ent.x, ent.y, function(other)
                    if g.isAlive(other) and other:getTypename() ~= ent:getTypename() then
                        entAllies[#entAllies+1] = {other, helper.magnitude(other.x - ent.x, other.y - ent.y)}
                    end
                end, 160)

                -- Sort by closest
                table.sort(entAllies, function(a, b)
                    return a[2] < b[2]
                end)

                -- Buff them
                for i = 1, math.min(#entAllies, 6) do
                    g.buffEntity(entAllies[i][1], stat, increase, ent)
                end
            end,
        },
    }},
    cost = {yellow = 1},
})




g.defineSquad("endless_army_squad", {
    name = "The Endless Army",
    rarity = g.RARITIES.LEGENDARY,
    tags = {"swarm", "scaling"},
    entityDef = {
        image = "endlessarmy_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "melee" },
        weapon = { image = "endlessarmy_sword", type = "sword" },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 10,
        baseStartingArmor = 1,
    },
    statUpgradeScaling = {maxHealth = 0.2},
    unitCount = 1,
    perks = {{
        name = "Mass-Production",
        description = loc("Has extra units equal to the total levels of all squads in your army."),
        image = "coin_icon",
        armyHandlers = {
            getSquadUnitCountModifier = function(ownerSquad, squadId)
                if squadId ~= ownerSquad.squadId then return 0 end
                local total = 0
                for _, sq in pairs(g.getRun().squads) do
                    total = total + (sq.level or 1)
                end
                return total
            end,
        },
    }},
    cost = {yellow = 1},
})


g.defineSquad("wealth_elemental_squad", {
    name = "Wealth Elementals",
    rarity = g.RARITIES.LEGENDARY,
    tags = {"economy", "armor", "scaling"},
    entityDef = {
        image = "wealthelementals_unit",
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 2 },
        attack = { attackType = "melee" },
        weapon = { image = "wealthelementals_shield", type = "sword" },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.6,
        baseAttackRange = 22,
        baseMoveSpeed = 38,
        baseMaxHealth = 80,
        baseStartingArmor = 8,
    },
    statUpgradeScaling = {maxHealth = 0.2},
    unitCount = 2,
    perks = {{
        name = "Golden Bulk",
        description = g.loc2("When you gain (COIN) during battle, this unit gains an equal amount of (ARMR)."),
        image = "coin_icon",
        rawHandlers = {
            ---@param amount number
            goldGained = function(self, amount)
                if not g.isAlive(self) then return end
                g.addArmor(self, amount)
            end,
        },
    }},
    cost = {yellow = 1},
})
