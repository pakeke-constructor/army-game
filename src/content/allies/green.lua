

local sqhelper = require(".squad_helper")


sqhelper.defineMilitiaAndArchers("green")




g.defineSquad("forest_sprite_squad", {
    name = "Forest Sprites",
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
    perks = {{
        name = "Restore",
        description = g.loc2("On-spawn, nearby allies are healed to full (HP)."),
        image = "coin_icon",
        handlers = {
            entitySpawned = function(ent)
                g.iteratePartition("ally", ent.x, ent.y, function(other)
                    if other == ent then return end
                    if not g.isAlive(other) then return end
                    g.healEntity(other, other.maxHealth or 999)
                end, 150)
            end,
        },
    }},
    cost = {green = 1},
})



g.defineSquad("druid_squad", {
    name = "Druids",
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
        baseAttackSpeed = 0.3,
        baseAttackRange = 70,
        baseMoveSpeed = 50,
        baseMaxHealth = 7,
    },
    unitCount = 6,
    perks = {{
        name = "Vitalize",
        description = loc("On-heal, the target gains 1 max HP."),
        image = "coin_icon",
        handlers = {
            onAttack = function(ent, target)
                if ent.healPower and target and g.isAlive(target) then
                    g.buffEntity(target, "maxHealth", 1, ent)
                    target.health = target.health + 1
                end
            end,
        },
    }},
    cost = {green = 1},
})



g.defineSquad("cook_squad", {
    name = "Cooks",
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
    name = "Peasants",
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
    name = "Hogs of War",
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
    name = "Giant Toads",
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
    name = "Treants",
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
    perks = {{
        name = "Growth",
        description = loc("Permanently gains +1 Max HP for every 4 Green mana played this fight."),
        image = "mana_green_small",
        rawHandlers = {
            manaSpent = function(ent, manaRequirement)
                -- TODO: Need to discuss this perk further because it
                -- was ambiguos in certain ways.
            end,
        },
    }},
    cost = {green = 2},
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

g.defineSquad("infested_squad", {
    name = "The Infested",
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
    perks = {{
        name = "Infestation",
        description = loc("On death, spawn a {GREEN_MANA_COLOR}Pest{/GREEN_MANA_COLOR}."),
        image = "coin_icon",
        handlers = {
            entityDeath = function(ent)
                g.spawnEntity("pest", ent.x, ent.y)
            end,
        },
    }},
    cost = {green = 1},
})



g.defineSquad("friendly_giant_squad", {
    name = "Friendly Giant",
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
    name = "Forest Sentries",
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
    perks = {{
        name = "Life Force",
        description = g.loc2("Gain (ATK) equal to max (HP). Take 4 x as much damage."),
        image = "coin_icon",
        handlers = {
            getAttackDamageModifier = function(ent)
                return ent.maxHealth
            end,
            getDamageTakenMultiplier = function(ent)
                return 4
            end,
        },
    }},
    cost = {green = 1},
})




local function hasMagnificence(ent)
    if not ent.squad then return false end
    for _, p in ipairs(ent.squad.perks or {}) do
        if p == "magnificence" then return true end
    end
    return false
end

g.defineSquad("arcane_blossom_squad", {
    name = "Arcane Blossoms",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "arcaneblossom",
        physics = { shape = "circle", radius = 7, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "melee" },
        baseAttackDamage = 2,
        baseAttackSpeed = 0.8,
        baseAttackRange = 20,
        baseMoveSpeed = 45,
        baseMaxHealth = 30,
        baseStartingArmor = 3,
    },
    unitCount = 3,
    icon = "arcaneblossom_uniticon",
    perks = {{
        name = "Magnificence",
        description = g.loc2("When this unit heals or gains max HP, spread the effect to 3 random nearby allies without this perk."),
        image = "coin_icon",
        handlers = {
            entityHealed = function(ent, amount, healer)
                local nearby = {}
                g.iteratePartition("ally", ent.x, ent.y, function(other)
                    if other == ent then return end
                    if not g.isAlive(other) then return end
                    if hasMagnificence(other) then return end
                    nearby[#nearby + 1] = other
                end, 120)
                for i = 1, math.min(3, #nearby) do
                    local idx = math.random(i, #nearby)
                    nearby[i], nearby[idx] = nearby[idx], nearby[i]
                    g.healEntity(nearby[i], amount)
                end
            end,
            entityBuffed = function(ent, stat, increase)
                if stat ~= "maxHealth" or increase <= 0 then return end
                local nearby = {}
                g.iteratePartition("ally", ent.x, ent.y, function(other)
                    if other == ent then return end
                    if not g.isAlive(other) then return end
                    if hasMagnificence(other) then return end
                    nearby[#nearby + 1] = other
                end, 120)
                for i = 1, math.min(3, #nearby) do
                    local idx = math.random(i, #nearby)
                    nearby[i], nearby[idx] = nearby[idx], nearby[i]
                    g.buffEntity(nearby[i], "maxHealth", increase, ent)
                end
            end,
        },
    }},
    cost = {green = 1},
})




g.defineSquad("world_tree_squad", {
    name = "World Tree",
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "worldtree",
        isBuilding = true,
        physics = { shape = "circle", radius = 16, ox = 0, oy = 0, mass = 1, isStatic = true },
        baseMaxHealth = 300,
        baseStartingArmor = 5,
    },
    unitCount = 1,
    perks = {{
        name = "Her Wrath",
        description = loc("Whenever an ally heals, this building damages a random enemy equal to 100% of the heal value."),
        image = "coin_icon",
        rawHandlers = {
            entityHealed = function(self, ent, amount, healer)
                if not g.isAlive(self) then return end
                if not ent or ent.team ~= "ally" then return end
                if not amount or amount <= 0 then return end
                local enemies = g.getECS():getEnemyList()
                if #enemies > 0 then
                    g.dealDamage(enemies[math.random(#enemies)], amount)
                end
            end,
        },
    }},
    cost = {green = 2},
})




g.defineSquad("hive_recycler_squad", {
    name = "Hive Recyclers",
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "hiverecycler",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        ai = { target = "ally" },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 250 },
        isHealer = true,
        baseHealPower = 2,
        baseAttackSpeed = 0.6,
        baseAttackRange = 220,
        baseMoveSpeed = 35,
        baseMaxHealth = 7,
    },
    unitCount = 2,
    perks = {{
        name = "Swarmsurge",
        description = loc("Whenever any {GREEN_MANA_COLOR}Green unit{/GREEN_MANA_COLOR} dies, this unit summons a {GREEN_MANA_COLOR}Pest{/GREEN_MANA_COLOR}."),
        image = "coin_icon",
        rawHandlers = {
            entityDeath = function(self, ent, killer)
                if not g.isAlive(self) then return end
                local squadId = ent.type and ent.type:match("^(.-)_unit$")
                if not squadId then return end
                local ok, info = pcall(g.getSquadInfo, squadId)
                if not ok or not (info and info.cost and info.cost.green) then return end
                g.spawnEntity("pest", self.x, self.y)
            end,
        },
    }},
    cost = {green = 1},
})


g.defineSquad("living_forest_squad", {
    name = "Living Forest",
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "livingforest_body", -- TODO: Animate legs with `livingforest_legs`.
        physics = { shape = "circle", radius = 7, ox = 0, oy = 0, mass = 2 },
        attack = { attackType = "melee" },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.8,
        baseAttackRange = 22,
        baseMoveSpeed = 38,
        baseMaxHealth = 45,
        baseStartingArmor = 4,
    },
    unitCount = 4,
    icon = "livingforest_uniticon",
    perks = {{
        name = "Circle of Life",
        description = loc("On-death, all allies gain 10% of this unit's max HP."),
        image = "coin_icon",
        handlers = {
            entityDeath = function(ent, killer)
                local amount = (ent.maxHealth or 0) * 0.1
                if amount <= 0 then return end
                for _, other in ent:getWorld():iterate("team") do
                    if other.team == "ally" and g.isAlive(other) then
                        g.buffEntity(other, "maxHealth", amount, ent)
                        g.healEntity(other, amount)
                    end
                end
            end,
        },
    }},
    cost = {green = 1},
})



g.defineSquad("lifesmith_squad", {
    name = "Lifesmiths",
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "lifesmith",
        physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 2 },
        ai = { target = "ally" },
        attack = { attackType = "melee" },
        weapon = { image = "lifesmith_hammer", type = "sword" },
        isHealer = true,
        baseHealPower = 1,
        baseAttackSpeed = 0.4,
        baseAttackRange = 22,
        baseMoveSpeed = 45,
        baseMaxHealth = 18,
        baseStartingArmor = 0,
    },
    unitCount = 6,
    icon = "lifesmiths_uniticon",
    perks = {{
        name = "Forge Life",
        description = g.loc2("This unit has additional (HEAL) equal to its (ARMR)."),
        image = "coin_icon",
        handlers = {
            getHealPowerModifier = function(ent)
                return math.floor(ent.armor or 0)
            end,
        },
    }},
    cost = {green = 1},
})



g.defineSquad("swarm_squad", {
    name = "The Swarm",
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
