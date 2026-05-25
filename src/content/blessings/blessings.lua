local loc2 = g.locRich

g.defineBlessing("anger", "Anger", {
    description = loc2("+1 (ATK) to allied units with at least 3 (ATK)."),
    image = "blessing_anger",
    rarity = g.RARITIES.COMMON,
    handlers = {
        getAttackDamageModifier = function(ent)
            if ent.team == "ally" and (ent.attackDamage or 0) >= 3 then
                return 1
            end
        end,
    },
})

g.defineBlessing("heart", "Heart", {
    description = loc2("+1 max (HP) to allied squads."),
    image = "blessing_hearty",
    rarity = g.RARITIES.COMMON,
    handlers = {
        getMaxHealthModifier = function(ent)
            if ent.squad and ent.team == "ally" then
                return 1
            end
        end,
    },
})

g.defineBlessing("naturalist", "Naturalist", {
    description = loc2("+4 max (HP) to allied squads."),
    image = "blessing_naturalist",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        getMaxHealthModifier = function(ent)
            if ent.squad and ent.team == "ally" then
                return 4
            end
        end,
    },
})

g.defineBlessing("helpfulness", "Helpfulness", {
    description = loc2("+1 (HEAL) to allied squads."),
    image = "blessing_helpfulness",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        getHealPowerModifier = function(ent)
            if ent.squad and ent.team == "ally" then
                return 1
            end
        end,
    },
})

g.defineBlessing("luxury", "Luxury", {
    description = loc2("Squads that are at least level 3 gain +10% (ASPD)."),
    image = "placeholder", -- PLACEHOLDER: no "luxury" sprite exists yet
    rarity = g.RARITIES.COMMON,
    handlers = {
        getAttackSpeedMultiplier = function(ent)
            if ent.squad and (ent.squad.level or 1) >= 3 then
                return 1.1
            end
        end,
    },
})

g.defineBlessing("overclock", "Overclock", {
    description = loc2("Your squads gain +50% (ASPD) but lose 2 max (HP)."),
    image = "blessing_overclock",
    rarity = g.RARITIES.COMMON,
    handlers = {
        getAttackSpeedMultiplier = function(ent)
            if ent.squad then return 1.5 end
        end,
        getMaxHealthModifier = function(ent)
            if ent.squad then return -2 end
        end,
    },
})

g.defineBlessing("haste", "Haste", {
    description = loc2("+0.2 (ASPD) to allied squads."),
    image = "blessing_haste",
    rarity = g.RARITIES.COMMON,
    handlers = {
        getAttackSpeedModifier = function(ent)
            if ent.squad then return 0.2 end
        end,
    },
})

g.defineBlessing("mana_shield", "Mana Shield", {
    description = loc2("+2 (ARMR) to squads that cost at least 2 mana."),
    image = "blessing_manashield",
    rarity = g.RARITIES.COMMON,
    handlers = {
        entitySpawned = function(ent)
            local squad = ent.squad
            if not squad then return end
            local cost = g.getSquadInfo(squad.squadId).cost
            local total = 0
            if cost then
                for _, v in pairs(cost) do total = total + v end
            end
            if total >= 2 then
                g.addArmor(ent, 2)
            end
        end,
    },
})

g.defineBlessing("torment", "Torment", {
    description = loc2("On-hurt, enemies have a 10% chance to take 1 additional damage."),
    image = "blessing_torment",
    rarity = g.RARITIES.COMMON,
    handlers = {
        entityHurt = function(ent, damage, attacker)
            if ent.team ~= "enemy" then return end
            if love.math.random() <= 0.1 then
                g.dealDamage(ent, 1, attacker)
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

g.defineBlessing("scavenge", "Scavenge", {
    description = loc("Gain 5 gold when travelling to empty nodes."),
    image = "blessing_scavenge",
    rarity = g.RARITIES.COMMON,
    handlers = {
        arrivedAtNode = function(nodeType, node)
            if nodeType ~= "empty" or node.visited then return end
            local run = g.getRun()
            run.money = run.money + 5
        end,
    },
})

g.defineBlessing("valuable_lesson", "Valuable Lesson", {
    description = loc("Gain 3 XP when you acquire this blessing."),
    image = "blessing_valuablelesson",
    rarity = g.RARITIES.COMMON,
    onAdd = function()
        g.addXP(3)
    end,
})

g.defineBlessing("grace", "Grace", {
    description = loc("Reduce demon-rage by 2 when you acquire this blessing."),
    image = "placeholder", -- PLACEHOLDER: no "grace" sprite exists yet
    rarity = g.RARITIES.COMMON,
    onAdd = function()
        local run = g.getRun()
        run.demonRage = math.max(0, run.demonRage - 2)
    end,
})

g.defineBlessing("lucky_sack", "Lucky Sack", {
    description = loc("Gain between 50 and 200 gold when acquired."),
    image = "blessing_luckysack",
    rarity = g.RARITIES.UNCOMMON,
    onAdd = function()
        g.addGold(math.random(50, 200))
    end,
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

g.defineBlessing("wither", "Wither", {
    description = loc2("Poisoned enemies have -40% (ASPD)."),
    image = "blessing_wither",
    rarity = g.RARITIES.UNCOMMON,
    mana = "green",
    handlers = {
        getAttackSpeedMultiplier = function(ent)
            if ent.team == "enemy" and (ent.poisonTime or 0) > 0 then
                return 0.6
            end
        end,
    },
})

g.defineBlessing("volley", "Volley", {
    description = loc2("Ranged units have +25% (RNG)."),
    image = "blessing_volley",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        getAttackRangeMultiplier = function(ent)
            if ent.attack and ent.attack.attackType == "ranged" then
                return 1.25
            end
        end,
    },
})

g.defineBlessing("gunpowder_mules", "Gunpowder Mules", {
    description = loc("Your explosions gain +50% size."),
    image = "blessing_gunpowdermules",
    rarity = g.RARITIES.UNCOMMON,
    mana = "red",
    handlers = {
        getExplosionSizeMultiplier = function(ent)
            if ent and ent.team == "ally" then
                return 1.5
            end
        end,
    },
})

g.defineBlessing("disintegration", "Disintegration", {
    description = loc("Burning enemies take 1 extra damage from unit attacks."),
    image = "blessing_disintegration",
    rarity = g.RARITIES.UNCOMMON,
    mana = "red",
    handlers = {
        -- onHitDamage only fires for unit attacks (attacker present), never for
        -- burn/poison ticks or explosions. Deal the bonus with a nil attacker so
        -- it doesn't re-trigger onHitDamage (no recursion).
        onHitDamage = function(attacker, damage, target)
            if target.team == "enemy" and (target.burnTime or 0) > 0 then
                g.dealDamage(target, 1, nil)
            end
        end,
    },
})

g.defineBlessing("alchemy_license", "Alchemy License", {
    description = loc("When applying burn or poison, 50% chance to apply again."),
    image = "blessing_alchemylicense",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        statusEffectApplied = function(ent, effectType, x, source)
            if ent.team == "ally" then return end
            if love.math.random()<0.5 then return end
            if effectType == "burn" then
                ent.burnTime = (ent.burnTime or 0) + x
            elseif effectType == "poison" then
                ent.poisonAmount = (ent.poisonAmount or 0) + x
            end
        end,
    },
})

g.defineBlessing("compress", "Compress", {
    description = loc2("On-hurt, allies have a 10% chance to gain 1 (ARMR)."),
    image = "blessing_compress",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        entityHurt = function(ent, damage, attacker)
            if ent.team ~= "ally" then return end
            if love.math.random() <= 0.1 then
                g.addArmor(ent, 1)
            end
        end,
    },
})

g.defineBlessing("bloodbath", "Bloodbath", {
    description = loc2("Your units have +25% (LIFESTEAL) when below half (HP)."),
    image = "blessing_bloodbath",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        getLifestealModifier = function(ent)
            if ent.team == "ally" and ent.health and ent.maxHealth
                and ent.health < ent.maxHealth * 0.5 then
                return 0.25
            end
        end,
    },
})

g.defineBlessing("profits", "Profits", {
    description = loc("Gain 5 gold per Yellow squad when entering a market."),
    image = "blessing_profits",
    rarity = g.RARITIES.UNCOMMON,
    mana = "yellow",
    handlers = {
        shopEntered = function()
            local count = 0
            for _, sq in pairs(g.getRun().squads) do
                local cost = g.getSquadInfo(sq.squadId).cost
                if cost and cost.yellow then count = count + 1 end
            end
            g.addGold(count * 5)
        end,
    },
})
