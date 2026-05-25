
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
    description = loc("20% chance for ranged units to fire 1 extra projectile."),
    image = "blessing_barrage",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        getProjectileCountModifier = function()
            if love.math.random() <= 0.2 then
                return 1
            end
        end,
    },
})



local function randomEnemy()
    local pool = {}
    g.iteratePartition("enemy", 0, 0, function(e)
        if g.isAlive(e) then pool[#pool+1] = e end
    end, 99999)
    if #pool == 0 then return nil end
    return pool[math.random(#pool)]
end


g.defineBlessing("golden_gamble", "Golden Gamble", {
    description = loc("When you enter a shop, your gold is randomized between 1 and 999."),
    image = "coin_icon",
    rarity = g.RARITIES.LEGENDARY,
    mana = "yellow",
    handlers = {
        shopEntered = function()
            local run = g.getRun()
            run.money = math.random(1, 999)
        end,
    },
})

g.defineBlessing("fuel", "Fuel", {
    description = loc("When applying burn to an enemy for the first time, apply 2 extra burn."),
    image = "coin_icon",
    rarity = g.RARITIES.UNCOMMON,
    mana = "red",
    handlers = {
        statusEffectApplied = function(ent, effectType, duration, source)
            if effectType ~= "burn" or ent.team == "ally" then return end
            g.applyBurn(ent, 2, source)
        end,
    },
})

g.defineBlessing("sadistic_flames", "Sadistic Flames", {
    description = loc("When an enemy receives burn, apply 1 extra burn per unique debuff on the target."),
    image = "coin_icon",
    rarity = g.RARITIES.LEGENDARY,
    mana = "red",
    handlers = {
        statusEffectApplied = function(ent, effectType, duration, source)
            if effectType ~= "burn" or ent.team == "ally" then return end
            local debuffs = 0
            if (ent.burnTime   or 0) > 0 then debuffs = debuffs + 1 end
            if (ent.poisonTime or 0) > 0 then debuffs = debuffs + 1 end
            if (ent.frozenTime or 0) > 0 then debuffs = debuffs + 1 end
            if debuffs > 0 then
                g.applyBurn(ent, debuffs, source)
            end
        end,
    },
})

g.defineBlessing("injection", "Injection", {
    description = loc("Every 2 seconds, apply 1 poison to a random enemy."),
    image = "coin_icon",
    rarity = g.RARITIES.COMMON,
    mana = "green",
    handlers = {
        perSecondUpdate = function(secondCount)
            if secondCount % 2 == 0 then
                local target = randomEnemy()
                if target then g.applyPoison(target, 1, nil) end
            end
        end,
    },
})

g.defineBlessing("firestarter", "Firestarter", {
    description = loc("Every 2 seconds, apply 4 burn to a random enemy."),
    image = "coin_icon",
    rarity = g.RARITIES.COMMON,
    mana = "red",
    handlers = {
        perSecondUpdate = function(secondCount)
            if secondCount % 2 == 0 then
                local target = randomEnemy()
                if target then g.applyBurn(target, 4, nil) end
            end
        end,
    },
})


g.defineBlessing("misfortune", "Misfortune", {
    description = loc("Every 2 seconds, deal 3 damage to a random enemy."),
    image = "coin_icon",
    rarity = g.RARITIES.COMMON,
    handlers = {
        perSecondUpdate = function(secondCount)
            if secondCount % 2 == 0 then
                local target = randomEnemy()
                if target then g.dealDamage(target, 3, nil) end
            end
        end,
    },
})

g.defineBlessing("chill", "Chill", {
    description = loc("Every 2 seconds, apply 1 freeze to a random enemy."),
    image = "coin_icon",
    rarity = g.RARITIES.COMMON,
    mana = "blue",
    handlers = {
        perSecondUpdate = function(secondCount)
            if secondCount % 2 == 0 then
                local target = randomEnemy()
                if target then g.applyFrozen(target, 1, nil) end
            end
        end,
    },
})


g.defineBlessing("pestilence", "Pestilence", {
    description = loc("Poison spreads to one nearby enemy when applied."),
    image = "blessing_pestilence",
    rarity = g.RARITIES.RARE,
    mana = "green",
    handlers = {
        statusEffectApplied = function(ent, effectType, duration, source)
            if effectType ~= "poison" then return end
            if ent._plagueSpread then
                ent._plagueSpread = nil
                return
            end
            local nearby = nil
            g.iteratePartition(ent.team, ent.x, ent.y, function(other)
                if nearby then return end
                if other ~= ent and g.isAlive(other) then
                    nearby = other
                end
            end, 80)
            if nearby then
                nearby._plagueSpread = true
                g.applyPoison(nearby, duration, source)
            end
        end,
    },
})
