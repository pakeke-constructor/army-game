
g.defineBlessing("iron_hide", "Iron Hide", {
    description = loc("Allies take 3 less damage from attacks."),
    image = "coin_icon",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        getDamageReduction = function(ent)
            if ent.team == "ally" then
                return 3
            end
        end,
    },
})

g.defineBlessing("golden_coffers", "Golden Coffers", {
    description = loc("Gain 50% more money from all sources."),
    image = "coin_icon",
    rarity = g.RARITIES.RARE,
    handlers = {
        getMoneyMultiplier = function()
            return 1.5
        end,
    },
})

g.defineBlessing("blood_tithe", "Blood Tithe", {
    description = loc("Gain 5 gold after winning a battle."),
    image = "coin_icon",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        battleWon = function()
            local run = g.getRun()
            run.money = run.money + 5
        end,
    },
})

g.defineBlessing("barrage", "Barrage", {
    description = loc("All ranged units fire 1 extra projectile."),
    image = "coin_icon",
    rarity = g.RARITIES.LEGENDARY,
    handlers = {
        getProjectileCountModifier = function()
            return 1
        end,
    },
})
