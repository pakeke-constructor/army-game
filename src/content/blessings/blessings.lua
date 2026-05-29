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
    image = "placeholder",
    rarity = g.RARITIES.RARE,
    handlers = {
        getMoneyMultiplier = function()
            return 1.5
        end,
    },
})

g.defineBlessing("blood_tithe", "Blood Tithe", {
    description = loc("Gain 5 gold after winning a battle."),
    image = "placeholder",
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
    local pool = g.getECS():getEnemyList()
    if #pool == 0 then return nil end
    return pool[math.random(#pool)]
end


g.defineBlessing("golden_gamble", "Golden Gamble", {
    description = loc("When you enter a shop, your gold is randomized between 1 and 777."),
    image = "blessing_goldengamble",
    rarity = g.RARITIES.LEGENDARY,
    mana = "yellow",
    handlers = {
        shopEntered = function()
            local run = g.getRun()
            run.money = math.random(1, 777)
        end,
    },
})

g.defineBlessing("fuel", "Fuel", {
    description = loc("When applying burn to an enemy for the first time, apply 2 extra burn."),
    image = "placeholder",
    rarity = g.RARITIES.UNCOMMON,
    mana = "red",
    handlers = {
        statusEffectApplied = function(ent, effectType, duration, source)
            if effectType ~= "burn" or ent.team == "ally" then return end
            g.applyBurn(ent, 2, source)
        end,
    },
})

g.defineBlessing("corrosive_compounds", "Corrosive Compounds", {
    description = loc("When an enemy receives burn, apply 1 extra burn per unique debuff on the target."),
    image = "placeholder",
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
    image = "placeholder",
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
    image = "placeholder",
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
    image = "placeholder",
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
    image = "placeholder",
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


g.defineBlessing("infection", "Infection", {
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
    description = loc2("Ranged units have +25% (RANGE)."),
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

g.defineBlessing("electrocute", "Electrocute", {
    description = loc("On-hit, your units have a 25% chance to deal 3 extra damage."),
    image = "blessing_electrocute",
    rarity = g.RARITIES.UNCOMMON,
    mana = "blue",
    handlers = {
        -- nil attacker on the bonus hit so it doesn't re-trigger onHitDamage.
        onHitDamage = function(attacker, damage, target)
            if attacker.team ~= "ally" then return end
            if love.math.random() <= 0.25 then
                g.dealDamage(target, 3, nil)
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

g.defineBlessing("group_hug", "Group Hug", {
    description = loc("Buffs have 20% chance to spread to nearest ally, recursively."),
    image = "blessing_grouphug",
    rarity = g.RARITIES.RARE,
    handlers = {
        -- Re-buffing fires entityBuffed again, so spreading is naturally recursive.
        entityBuffed = function(ent, stat, increase)
            if ent.team ~= "ally" or increase <= 0 then return end
            if love.math.random() > 0.2 then return end
            local closest, bestDist = nil, math.huge
            g.iteratePartition("ally", ent.x, ent.y, function(other)
                if other == ent or not g.isAlive(other) then return end
                local dx, dy = other.x - ent.x, other.y - ent.y
                local d = dx * dx + dy * dy
                if d < bestDist then bestDist, closest = d, other end
            end, 120)
            if closest then g.buffEntity(closest, stat, increase) end
        end,
    },
})

g.defineBlessing("water_cycle", "Water Cycle", {
    description = loc("Each battle, for every 8 blue mana you spend, gain 1 blue mana."),
    image = "blessing_watercycle",
    rarity = g.RARITIES.UNCOMMON,
    mana = "blue",
    startingData = 0,            -- tracks blue mana spent this battle
    resetDataOnBattleStart = true,
    handlers = {
        manaSpent = function(manaRequirement)
            local blue = manaRequirement and manaRequirement.blue or 0
            if blue <= 0 then return end
            local acc = g.getBlessingData("water_cycle") + blue
            while acc >= 8 do
                acc = acc - 8
                g.addMana("blue", 1)
            end
            g.setBlessingData("water_cycle", acc)
        end,
    },
})

g.defineBlessing("overpower", "Overpower", {
    description = loc2("Your units deal +25% damage to enemies with less max (HP) than them."),
    image = "blessing_overpower",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        -- Dispatched as g.ask("getDamageTakenMultiplier", target, attacker).
        getDamageTakenMultiplier = function(target, attacker)
            if not attacker or attacker.team ~= "ally" then return end
            if attacker.maxHealth > target.maxHealth then return 1.25 end
        end,
    },
})

g.defineBlessing("trickster", "Trickster", {
    description = loc("The first time you Transform a unit each combat, gain 2 blue mana."),
    image = "blessing_trickster",
    rarity = g.RARITIES.UNCOMMON,
    mana = "blue",
    startingData = false,        -- have we triggered this combat?
    resetDataOnBattleStart = true,
    handlers = {
        entityTransformed = function(oldEnt, newEnt)
            if oldEnt.team ~= "ally" then return end
            if g.getBlessingData("trickster") then return end
            g.setBlessingData("trickster", true)
            g.addMana("blue", 2)
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


g.defineBlessing("bodybuilding", "Bodybuilding", {
    description = loc2("When your units Heal, they also gain 1 max (HP) for the battle."),
    image = "blessing_bodybuilding",
    rarity = g.RARITIES.RARE,
    handlers = {
        entityHealed = function(ent, amount, healer)
            if ent.team ~= "ally" then return end
            g.buffEntity(ent, "maxHealth", 1)
        end,
    },
})

g.defineBlessing("pestilence", "Pestilence", {
    description = loc2("Pests have +1 (ASPD) and +1 (ATK)."),
    image = "blessing_pestilence",
    rarity = g.RARITIES.RARE,
    mana = "green",
    handlers = {
        getAttackSpeedModifier = function(ent)
            if ent.isPest then return 1 end
        end,
        getAttackDamageModifier = function(ent)
            if ent.isPest then return 1 end
        end,
    },
})

g.defineBlessing("fortify", "Fortify", {
    description = loc2("50% chance to double (ARMR) gained during battle."),
    image = "blessing_fortify",
    rarity = g.RARITIES.RARE,
    handlers = {
        -- Bump ent.armor directly (not g.addArmor) so we don't re-fire
        -- armorIncreased and double again recursively.
        armorIncreased = function(ent, amount)
            if ent.team ~= "ally" then return end
            if love.math.random() <= 0.5 then
                ent.armor = (ent.armor or 0) + amount
            end
        end,
    },
})

g.defineBlessing("fireball", "Fireball", {
    description = loc("When applying burn, create a medium explosion for 4 damage."),
    image = "blessing_fireball",
    rarity = g.RARITIES.RARE,
    mana = "red",
    handlers = {
        statusEffectApplied = function(ent, effectType, duration, source)
            if effectType ~= "burn" or ent.team == "ally" then return end
            if source then
                g.explosion(ent.x, ent.y, 4, 70, source)
            end
        end,
    },
})

g.defineBlessing("stomp", "Stomp", {
    description = loc2("On-spawn, your units deal area damage equal to 25% max (HP)."),
    image = "blessing_stomp",
    rarity = g.RARITIES.RARE,
    handlers = {
        entitySpawned = function(ent)
            if ent.team ~= "ally" or not ent.squad then return end
            g.explosion(ent.x, ent.y, ent.maxHealth * 0.25, 70, ent)
        end,
    },
})

g.defineBlessing("upscaling", "Upscaling", {
    description = loc("Max level squads gain +50% units."),
    image = "blessing_upscaling",
    rarity = g.RARITIES.COMMON,
    handlers = {
        getSquadUnitCountModifier = function(squadId)
            local squad = g.getSquadFromArmy(squadId)
            if not squad or squad.level < consts.MAX_SQUAD_LEVEL then return end
            local base = g.getSquadInfo(squadId).unitCount
            return math.floor(base * 0.5 + 0.5)
        end,
    },
})

g.defineBlessing("ubergrades", "Ubergrades", {
    description = loc2("Squads gain +0.1 (ASPD) and +1 (ARMR) each time they're upgraded."),
    image = "blessing_ubergrades",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        -- level 1 = no upgrades; each level past 1 is one upgrade.
        getAttackSpeedModifier = function(ent)
            if ent.squad and ent.team == "ally" then
                return (ent.squad.level - 1) * 0.1
            end
        end,
        entitySpawned = function(ent)
            if not ent.squad or ent.team ~= "ally" then return end
            g.addArmor(ent, ent.squad.level - 1)
        end,
    },
})

g.defineBlessing("cursed_banquet", "Cursed Banquet", {
    description = loc("Gain 2 XP the first time you kill a friendly unit each battle."),
    image = "blessing_cursedbanquet",
    rarity = g.RARITIES.UNCOMMON,
    startingData = false,        -- triggered this battle?
    resetDataOnBattleStart = true,
    handlers = {
        onKill = function(killer, victim)
            if killer.team ~= "ally" or victim.team ~= "ally" then return end
            if g.getBlessingData("cursed_banquet") then return end
            g.setBlessingData("cursed_banquet", true)
            g.addXP(2)
        end,
    },
})

g.defineBlessing("wildfire", "Wildfire", {
    description = loc("On-spawn, your units gain 5 burn and apply 10 burn to a random enemy."),
    image = "blessing_wildfire",
    rarity = g.RARITIES.RARE,
    mana = "red",
    handlers = {
        entitySpawned = function(ent)
            if ent.team ~= "ally" then return end
            g.applyBurn(ent, 5, nil)
            local target = randomEnemy()
            if target then g.applyBurn(target, 10, ent) end
        end,
    },
})

g.defineBlessing("goliath", "Goliath", {
    description = loc2("Your units have +1 (ATK) per 10 max (HP)."),
    image = "blessing_goliath",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        getAttackDamageModifier = function(ent)
            if ent.team == "ally" then
                return math.floor((ent.maxHealth or 0) / 10)
            end
        end,
    },
})

g.defineBlessing("evolution", "Evolution", {
    description = loc2("When Transformed, your units gain 5 max (HP) for the battle, stackable."),
    image = "blessing_evolution",
    rarity = g.RARITIES.UNCOMMON,
    mana = "blue",
    handlers = {
        entityTransformed = function(oldEnt, newEnt)
            if newEnt.team ~= "ally" then return end
            g.buffEntity(newEnt, "maxHealth", 5)
        end,
    },
})

g.defineBlessing("burning_restoration", "Burning Restoration", {
    description = loc2("When any burning unit dies, the nearest ally heals 5 (HP)."),
    image = "blessing_cauterize",
    rarity = g.RARITIES.RARE,
    mana = "red",
    handlers = {
        entityDeath = function(ent, killer)
            if (ent.burnTime or 0) <= 0 then return end
            local closest, bestDist = nil, math.huge
            for _, other in g.getECS():iterate("team") do
                if other ~= ent and other.team == "ally" and g.isAlive(other) then
                    local dx, dy = other.x - ent.x, other.y - ent.y
                    local d = dx * dx + dy * dy
                    if d < bestDist then bestDist, closest = d, other end
                end
            end
            if closest then g.healEntity(closest, 5) end
        end,
    },
})

g.defineBlessing("bulk_pheromones", "Bulk Pheromones", {
    description = loc2("When a Green unit dies, ALL pests gain +1 max (HP)."),
    image = "blessing_bulkpheremones",
    rarity = g.RARITIES.RARE,
    mana = "green",
    handlers = {
        entityDeath = function(ent, killer)
            if ent.team ~= "ally" or not ent.squad then return end
            local cost = g.getSquadInfo(ent.squad.squadId).cost
            if not (cost and cost.green and cost.green > 0) then return end
            for _, other in g.getECS():iterate("team") do
                if other.team == "ally" and other.isPest and g.isAlive(other) then
                    g.buffEntity(other, "maxHealth", 1)
                end
            end
        end,
    },
})


g.defineBlessing("arcane_appetite", "Arcane Appetite", {
    description = loc("Gain +2 blue mana. Your commander starts the battle poisoned."),
    image = "blessing_arcaneappetite",
    rarity = g.RARITIES.UNCOMMON,
    mana = "blue",
    onAdd = function()
        g.addPermanentMana("blue")
        g.addPermanentMana("blue")
    end,
    handlers = {
        -- Commander is deployed by the player, so poison it when it spawns.
        -- Poison is constant DPS (never decays), so keep the amount small.
        entitySpawned = function(ent)
            if ent.isCommander then
                g.applyPoison(ent, 2, nil)
            end
        end,
    },
})

g.defineBlessing("meditation", "Meditation", {
    description = loc("The first time you place a squad each battle, regain blue mana equal to its cost."),
    image = "blessing_meditation",
    rarity = g.RARITIES.UNCOMMON,
    mana = "blue",
    startingData = false,        -- have we refunded this battle?
    resetDataOnBattleStart = true,
    handlers = {
        -- manaSpent only fires on squad deploy, so this = "first squad placed".
        manaSpent = function(manaRequirement)
            if g.getBlessingData("meditation") then return end
            g.setBlessingData("meditation", true)
            local total = 0
            for _, v in pairs(manaRequirement) do total = total + v end
            if total > 0 then g.addMana("blue", total) end
        end,
    },
})

g.defineBlessing("demonic_steed", "Demonic Steed", {
    description = loc2("Your commander gains +5 (ATK), and fears enemies on-hit."),
    image = "blessing_demonicsteed",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        getAttackDamageModifier = function(ent)
            if ent.isCommander then return 5 end
        end,
        -- onHitDamage's first arg is the attacker. Make the hit enemy flee the commander.
        onHitDamage = function(attacker, damage, target)
            if attacker.isCommander and target.team == "enemy" then
                g.applyFear(target, attacker, 2)
            end
        end,
    },
})

g.defineBlessing("radiant_gift", "Radiant Gift", {
    description = loc("Gain 1 Wildcard Mana when you acquire this blessing."),
    image = "blessing_radiantgift",
    rarity = g.RARITIES.RARE,
    onAdd = function()
        g.addPermanentMana(g.WILDCARD_MANA)
    end,
})

g.defineBlessing("one_man_army", "One Man Army", {
    description = loc2("If only one of your units is alive, it gains double (ATK) and (ASPD)."),
    image = "blessing_onemanarmy",
    rarity = g.RARITIES.RARE,
    startingData = false,        -- is exactly one ally unit alive?
    resetDataOnBattleStart = true,
    handlers = {
        -- Recompute the count ONCE per frame here (not inside the per-entity
        -- multipliers below), so the hot-path stays a cheap data lookup.
        postUpdate = function()
            local ecs = g.tryGetECS()
            if not ecs then return end
            local count = 0
            for _, ent in ecs:iterate("squad") do
                if ent.team == "ally" and g.isAlive(ent) then
                    count = count + 1
                    if count > 1 then break end
                end
            end
            g.setBlessingData("one_man_army", count == 1)
        end,
        getAttackDamageMultiplier = function(ent)
            if ent.squad and ent.team == "ally" and g.getBlessingData("one_man_army") then
                return 2
            end
        end,
        getAttackSpeedMultiplier = function(ent)
            if ent.squad and ent.team == "ally" and g.getBlessingData("one_man_army") then
                return 2
            end
        end,
    },
})

g.defineBlessing("infiltration", "Infiltration", {
    description = loc("Red squads can be deployed anywhere, even behind enemy lines."),
    image = "blessing_infiltration",
    rarity = g.RARITIES.RARE,
    mana = "red",
    handlers = {
        -- Asked with the squad as 1st arg when working out deploy placement.
        -- Returning true skips region-snapping, so the squad goes wherever clicked.
        canDeployAnywhere = function(squad)
            local cost = squad and g.getSquadInfo(squad.squadId).cost
            if cost and (cost.red or 0) > 0 then return true end
        end,
    },
})

g.defineBlessing("landmark", "Landmark", {
    description = loc2("The first building you place each fight has triple max (HP)."),
    image = "blessing_landmark",
    rarity = g.RARITIES.RARE,
    startingData = false,        -- have we marked this battle's landmark yet?
    resetDataOnBattleStart = true,
    handlers = {
        entitySpawned = function(ent)
            if ent.team ~= "ally" or not ent.isBuilding then return end
            if g.getBlessingData("landmark") then return end
            g.setBlessingData("landmark", true)
            ent._landmark = true
        end,
        getMaxHealthMultiplier = function(ent)
            if ent._landmark then return 3 end
        end,
    },
})

g.defineBlessing("crystallize", "Crystallize", {
    description = loc2("When an ally is healed to full (HP), it gains 2 (ARMR)."),
    image = "blessing_crystallize",
    rarity = g.RARITIES.RARE,
    handlers = {
        -- entityHealed only fires when real healing happened; ending at max HP
        -- means the heal topped the ally off, i.e. "healed to full".
        entityHealed = function(ent, amount, healer)
            if ent.team ~= "ally" then return end
            if ent.health and ent.maxHealth and ent.health >= ent.maxHealth then
                g.addArmor(ent, 2)
            end
        end,
    },
})

g.defineBlessing("iron_exosuits", "Iron Exosuits", {
    description = loc2("For every (ARMR) your units have, they gain +8% (ASPD)."),
    image = "blessing_ironexosuits",
    rarity = g.RARITIES.RARE,
    handlers = {
        getAttackSpeedMultiplier = function(ent)
            if ent.team == "ally" and ent.armor and ent.armor > 0 then
                return 1 + 0.08 * ent.armor
            end
        end,
    },
})

g.defineBlessing("grand_finale", "Grand Finale", {
    description = loc("Your explosions have +20% area. This increases by 2% for the fight whenever an explosion is triggered."),
    image = "blessing_grandfinale",
    rarity = g.RARITIES.LEGENDARY,
    mana = "red",
    startingData = 0,            -- explosions triggered this fight
    resetDataOnBattleStart = true,
    handlers = {
        explosion = function(x, y, damage, radius, fromEntity)
            if not fromEntity or fromEntity.team ~= "ally" then return end
            g.setBlessingData("grand_finale", g.getBlessingData("grand_finale") + 1)
        end,
        getExplosionSizeMultiplier = function(ent)
            if not ent or ent.team ~= "ally" then return end
            return 1.2 + 0.02 * g.getBlessingData("grand_finale")
        end,
    },
})

g.defineBlessing("hard_carapaces", "Hard Carapaces", {
    description = loc2("Green units and Pests have +2 (ARMR)."),
    image = "placeholder", -- PLACEHOLDER: name ends with *, no sprite yet
    rarity = g.RARITIES.LEGENDARY,
    mana = "green",
    handlers = {
        entitySpawned = function(ent)
            if ent.team ~= "ally" then return end
            local isGreen = false
            if ent.squad then
                local cost = g.getSquadInfo(ent.squad.squadId).cost
                isGreen = cost and cost.green and cost.green > 0
            end
            if isGreen or ent.isPest then
                g.addArmor(ent, 2)
            end
        end,
    },
})

g.defineBlessing("dark_inspiration", "Dark Inspiration", {
    description = loc2("After 10 friendly units die, your units gain 100% (LIFESTEAL) for the rest of the battle."),
    image = "blessing_darkinspiration",
    rarity = g.RARITIES.LEGENDARY,
    startingData = 0,            -- friendly deaths this battle
    resetDataOnBattleStart = true,
    handlers = {
        entityDeath = function(ent, killer)
            if ent.team ~= "ally" then return end
            local c = g.getBlessingData("dark_inspiration")
            if c < 10 then g.setBlessingData("dark_inspiration", c + 1) end
        end,
        getLifestealModifier = function(ent)
            if ent.team == "ally" and g.getBlessingData("dark_inspiration") >= 10 then
                return 1
            end
        end,
    },
})

g.defineBlessing("meat_grinder", "Meat Grinder", {
    description = loc("Gain 4 colorless mana after 40 allied units die."),
    image = "blessing_meatgrinder",
    rarity = g.RARITIES.LEGENDARY,
    startingData = 0,            -- allied deaths this battle
    resetDataOnBattleStart = true,
    handlers = {
        entityDeath = function(ent, killer)
            if ent.team ~= "ally" then return end
            local c = g.getBlessingData("meat_grinder")
            if c >= 40 then return end
            c = c + 1
            g.setBlessingData("meat_grinder", c)
            if c == 40 then g.addMana(g.WILDCARD_MANA, 4) end
        end,
    },
})

g.defineBlessing("unbreakable", "Unbreakable", {
    description = loc2("When units gain (ARMR) in battle, gain an equal amount of max (HP) for the fight."),
    image = "placeholder", -- PLACEHOLDER: name ends with *, no sprite yet
    rarity = g.RARITIES.LEGENDARY,
    handlers = {
        -- armorIncreased fires from g.addArmor. buffEntity(maxHealth) doesn't add
        -- armor, so no recursion.
        armorIncreased = function(ent, amount)
            if ent.team ~= "ally" then return end
            g.buffEntity(ent, "maxHealth", amount)
        end,
    },
})

-- =====================================================================
-- Soul / legendary blessings
-- =====================================================================

-- up to n distinct alive enemies, picked at random (partial shuffle)
local function randomEnemies(n)
    local pool = {}
    g.iteratePartition("enemy", 0, 0, function(e)
        if g.isAlive(e) then pool[#pool+1] = e end
    end, 99999)
    for i = 1, math.min(n, #pool) do
        local j = math.random(i, #pool)
        pool[i], pool[j] = pool[j], pool[i]
    end
    local out = {}
    for i = 1, math.min(n, #pool) do out[i] = pool[i] end
    return out
end

-- {color=true} set of a squad's (non-wildcard) mana colors
local function squadColors(squad)
    local colors = {}
    if not squad then return colors end
    local cost = g.getSquadInfo(squad.squadId).cost
    if cost then
        for color, amt in pairs(cost) do
            if color ~= g.WILDCARD_MANA and (amt or 0) > 0 then
                colors[color] = true
            end
        end
    end
    return colors
end

-- does the squad share any color in the given set? (no allocation)
local function squadSharesColor(squad, colorSet)
    if not squad then return false end
    local cost = g.getSquadInfo(squad.squadId).cost
    if not cost then return false end
    for color, amt in pairs(cost) do
        if color ~= g.WILDCARD_MANA and (amt or 0) > 0 and colorSet[color] then
            return true
        end
    end
    return false
end

g.defineBlessing("soul_split", "Soul Split", {
    description = loc2("Your squads have double units, but -50% max (HP). Buildings unaffected."),
    image = "blessing_soulsplit",
    rarity = g.RARITIES.LEGENDARY,
    handlers = {
        -- ADD reducer: returning the base count again = double total units.
        getSquadUnitCountModifier = function(squadId)
            local def = g.getSquadInfo(squadId).entityDef
            if def.isBuilding or def.isCommander then return end
            return g.getSquadInfo(squadId).unitCount
        end,
        getMaxHealthMultiplier = function(ent)
            if ent.squad and ent.team == "ally" and not ent.isBuilding then
                return 0.5
            end
        end,
    },
})

g.defineBlessing("explosive_mutation", "Explosive Mutation", {
    description = loc2("Your Pests cause a devastating explosion on-death."),
    image = "blessing_explosivemutation",
    rarity = g.RARITIES.LEGENDARY,
    mana = "green",
    handlers = {
        entityDeath = function(ent, killer)
            if ent.team ~= "ally" or not ent.isPest then return end
            g.explosion(ent.x, ent.y, 10, 90, ent)
        end,
    },
})

g.defineBlessing("cryomana", "Cryomana", {
    description = loc2("Whenever you gain mana during combat, freeze 10 random enemies for 5s."),
    image = "blessing_cryomana",
    rarity = g.RARITIES.LEGENDARY,
    mana = "blue",
    handlers = {
        -- freezing doesn't add mana, so no recursion. Guard on ECS = "in combat".
        manaAdded = function(manaType, count, sourceEnt)
            if not g.tryGetECS() then return end
            for _, e in ipairs(randomEnemies(10)) do
                g.applyFrozen(e, 5, nil)
            end
        end,
    },
})

g.defineBlessing("vengeance", "Vengeance", {
    description = loc2("Your units gain +1 (ATK) for 5s when an allied unit of the same color dies."),
    image = "blessing_vengeance",
    rarity = g.RARITIES.LEGENDARY,
    handlers = {
        entityDeath = function(ent, killer)
            if ent.team ~= "ally" or not ent.squad then return end
            local colors = squadColors(ent.squad)
            if not next(colors) then return end
            for _, other in g.getECS():iterate("squad") do
                if other ~= ent and other.team == "ally" and g.isAlive(other)
                    and squadSharesColor(other.squad, colors) then
                    g.addCustomEffect(other, {
                        getAttackDamageModifier = function(e) return 1 end,
                    }, 5)
                end
            end
        end,
    },
})

g.defineBlessing("wrathful_souls", "Wrathful Souls", {
    description = loc2("When an ally dies, deal 2x it's (ATK) to a nearby enemy."),
    image = "blessing_wrathfulsouls",
    rarity = g.RARITIES.LEGENDARY,
    handlers = {
        entityDeath = function(ent, killer)
            if ent.team ~= "ally" then return end
            local dmg = (ent.attackDamage or 0) * 2
            if dmg <= 0 then return end
            local closest, bestDist = nil, math.huge
            g.iteratePartition("enemy", ent.x, ent.y, function(other)
                if not g.isAlive(other) then return end
                local dx, dy = other.x - ent.x, other.y - ent.y
                local d = dx * dx + dy * dy
                if d < bestDist then bestDist, closest = d, other end
            end, 160)
            if closest then g.dealDamage(closest, dmg, ent) end
        end,
    },
})

g.defineBlessing("overload", "Overload", {
    description = loc2("When an enemy gains more burn than its max HP, instantly kill it and apply 20% of the burn to nearby enemies."),
    image = "blessing_overload",
    rarity = g.RARITIES.LEGENDARY,
    mana = "red",
    handlers = {
        -- Checked once per second (off the per-frame hot path). Burn "amount" is
        -- burnTime * BURN_DPS; if that exceeds maxHealth, overload the enemy.
        perSecondUpdate = function()
            for _, ent in g.getECS():iterate("team") do
                if ent.team == "enemy" and g.isAlive(ent) and (ent.burnTime or 0) > 0
                    and ent.burnTime * consts.BURN_DPS > (ent.maxHealth or 0) then
                    local spread, ox, oy = ent.burnTime * 0.2, ent.x, ent.y
                    g.killEntity(ent)
                    g.iteratePartition("enemy", ox, oy, function(other)
                        if other ~= ent and g.isAlive(other) then g.applyBurn(other, spread) end
                    end, 160)
                end
            end
        end,
    },
})

g.defineBlessing("black_flames", "Black Flames", {
    description = loc2("Burn deals double damage to enemies."),
    image = "blessing_blackflames",
    rarity = g.RARITIES.LEGENDARY,
    mana = "red",
    handlers = {
        getBurnDPSMultiplier = function(ent)
            if ent.team == "enemy" then return 2 end
        end,
    },
})
