




g.defineSquad("exo_soldier_squad", {
    name = "Exo-Soldiers",
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "exosoldiers_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "exosoldiers_arm",
            type = "sword",
            xOffset = 5
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
    name = "Prospectors",
    rarity = g.RARITIES.UNCOMMON,
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
    entityDef = {
        image = "greatfactory_unit",
        isBuilding = true,
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 1, isStatic = true },
        baseMaxHealth = 40,
    },
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
    entityDef = {
        image = "goldmine_unit",
        isBuilding = true,
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 1, isStatic = true },
        baseMaxHealth = 16,
    },
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
    entityDef = {
        image = "livinglaboratory",
        isBuilding = true,
        physics = { shape = "circle", radius = 14, ox = 0, oy = 0, mass = 1, isStatic = true },
        baseMaxHealth = 120,
        baseStartingArmor = 4,
    },
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
                    g.buffEntity(entAllies[i][1], stat, increase)
                end
            end,
        },
    }},
    cost = {yellow = 1},
})




g.defineSquad("endless_army_squad", {
    name = "The Endless Army",
    rarity = g.RARITIES.LEGENDARY,
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
