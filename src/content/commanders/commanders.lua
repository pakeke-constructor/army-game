

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
            baseMaxHealth = 220,
        },
    },

    onStart = function(run)
        g.addSquadToArmy("red_militia_squad")
        g.addSquadToArmy("red_archer_squad")
    end
})

