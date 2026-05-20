
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
        baseStartingArmor = 10,
    },
    unitCount = 1,
    icon = "example_squad_icon",
    perks = {"racket"},
    cost = {red = 1, blue = 1},
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
        baseStartingArmor = 0,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"consumption"},
    cost = {green = 1, red = 1},
})




