

g.defineCommander("sir_horse", "Sir Horse", {
    description = loc("Basic commander"),

    startMana = {
        [g.WILDCARD_MANA] = 2,
        -- 10 for dev-mode, 2 for non-dev mode
        red = 2,
        green = 2
    },

    image = "sir_horse",

    squadDef = {
        rarity = g.RARITIES.UNIQUE,
        unitCount = 1,
        cost = {red = 1, green = 1},
        statUpgradeScaling = {
            maxHealth = 0.25,
        },
        entityDef = {
            image = "sir_horse",
            isCommander = true,
            weapon = {
                type = "spear",
                image = "sir_horse_spear"
            },
            attack = {
                attackType = "melee",
            },
            baseAttackDamage = 10,
            baseAttackSpeed = 0.8,
            baseAttackRange = 85,
            baseMoveSpeed = 75,
            baseMaxHealth = 120,
        },
    },

    onStart = function(run)
        g.addSquadToArmy("red_militia_squad")
        g.addSquadToArmy("red_archer_squad")

        if consts.DEV_MODE then
            g.addSpellToArmy("ace_spell")
            g.addSpellToArmy("coin_spell")
            g.addSpellToArmy("heal_spell")
            g.addSpellToArmy("howl_spell")
            g.addSpellToArmy("poison_spell")
            g.addSpellToArmy("ranged_spell")
            g.addSpellToArmy("skull_spell")
        end
    end
})



g.defineCommander("druidcommander", "Druid Lady", {
    description = loc("Master of the Great Forest"),

    startMana = {
        [g.WILDCARD_MANA] = 2,
        red = 2,
        green = 2
    },

    image = "druidcommander",

    squadDef = {
        rarity = g.RARITIES.UNIQUE,
        unitCount = 1,
        cost = {red = 1, green = 1},
        statUpgradeScaling = {
            maxHealth = 0.25,
        },
        entityDef = {
            image = "druidcommander",
            isCommander = true,
            weapon = {
                type = "staff",
                image = "druidcommander_staff"
            },
            attack = {
                attackType = "melee",
            },
            baseAttackDamage = 9,
            baseAttackSpeed = 1.2,
            baseAttackRange = 80,
            baseMoveSpeed = 85,
            baseMaxHealth = 100,
        },
        perks = {{
            name = "Breath of Life",
            description = g.loc2("Your squads have +10% Max (HP)."),
            image = "coin_icon",
            rawHandlers = {
                ---@param ent ecs.Entity
                getMaxHealthMultiplier = function(_, ent)
                    return ent.team == "ally" and 1.1 or 1
                end
            }
        }}
    },

    onStart = function(run)
        g.addSquadToArmy("green_militia_squad")
        g.addSquadToArmy("green_archer_squad")
    end
})



g.defineCommander("mechcommander", "Mech Guy", {
    description = loc("Battle-Engineer."),

    startMana = {
        [g.WILDCARD_MANA] = 2,
        yellow = 2,
        green = 2
    },

    image = "mechcommander",

    squadDef = {
        rarity = g.RARITIES.UNIQUE,
        unitCount = 1,
        cost = {yellow = 1, green = 1},
        statUpgradeScaling = {
            maxHealth = 0.25,
        },
        entityDef = {
            onHitDamage = function(ent, damage, target)
                g.lightning(target.x, target.y, damage * 0.5, nil, 5)
            end,
            image = "mechcommander",
            isCommander = true,
            weapon = {
                type = "sword",
                image = "mechcommander_arm",
                drawBehind = true,
                xOffset = 10,
                yOffset = 10,
            },
            attack = {
                attackType = "melee",
            },
            baseAttackDamage = 8,
            baseAttackSpeed = 1,
            baseAttackRange = 70,
            baseMoveSpeed = 80,
            baseMaxHealth = 100,
        },
        -- TODO Perk: Progress: Gain 20 gold when you upgrade a squad.
    },

    onStart = function(run)
        g.addSquadToArmy("green_militia_squad")
        g.addSquadToArmy("green_archer_squad")
    end
})



g.defineCommander("lizardcommander", "Lizard Lord", {
    description = loc("King of the great lizard clan."),

    startMana = {
        [g.WILDCARD_MANA] = 2,
        red = 2,
        blue = 2
    },

    image = "lizardcommander",

    squadDef = {
        rarity = g.RARITIES.UNIQUE,
        unitCount = 1,
        cost = {red = 1, blue = 1},
        statUpgradeScaling = {
            maxHealth = 0.25,
        },
        entityDef = {
            image = "lizardcommander",
            isCommander = true,
            weapon = {
                type = "sword",
                image = "lizardcommander_axe",
            },
            attack = {
                attackType = "melee",
            },
            baseAttackDamage = 15,
            baseAttackSpeed = 1,
            baseAttackRange = 80,
            baseMoveSpeed = 90,
            baseMaxHealth = 110,
        },
        -- TODO Perk: Military Force: Enemy armies are more common. +1 day when defeating a tier 3 army.
    },

    onStart = function(run)
        g.addSquadToArmy("red_militia_squad")
        g.addSquadToArmy("blue_archer_squad")
    end
})



g.defineCommander("octopuscommander", "Octopus Tank", {
    description = loc("Aquatic Genius."),

    startMana = {
        [g.WILDCARD_MANA] = 2,
        blue = 2,
        yellow = 2
    },

    image = "octopuscommander",

    squadDef = {
        rarity = g.RARITIES.UNIQUE,
        unitCount = 1,
        cost = {blue = 1, yellow = 1},
        statUpgradeScaling = {
            maxHealth = 0.25,
        },
        entityDef = {
            image = "octopuscommander",
            isCommander = true,
            physics = { shape = "circle", radius = 20, ox = 0, oy = 0, mass = 7 },
            attack = {
                attackType = "ranged",
                projectileType = "octopus_lazer",
                projectileSpeed = 800,
            },
            baseAttackDamage = 8,
            baseAttackSpeed = 1.6,
            baseAttackRange = 800, -- unlimited range basically
            baseMoveSpeed = 35, -- but very slow
            baseMaxHealth = 250,
        }
    },

    onStart = function(run)
        g.addSquadToArmy("blue_militia_squad")
        g.addSquadToArmy("blue_archer_squad")
    end
})
