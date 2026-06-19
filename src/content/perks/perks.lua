

local loc2 = g.loc2


g.definePerk("healthy_spirit", "Healthy Spirit", {
    description = loc2("Heals to full HP whenever Blue mana is spent."),
    image = "coin_icon",
    handlers = {
        manaSpent = function(ent, manaRequirement)
            if manaRequirement and (manaRequirement.blue or 0) > 0 then
                g.healEntity(ent, ent.maxHealth or 999)
            end
        end,
    },
})

g.definePerk("volatile", "Volatile", {
    description = loc("On-death, explodes in a large area."),
    image = "coin_icon",
    handlers = {
        entityDeath = function(ent, killer)
            g.explosion(ent.x, ent.y, 3, 80)
        end,
    },
})

g.definePerk("racket", "Racket", {
    description = loc("On-attack, all enemies in a large area are Taunted to target this unit."),
    image = "coin_icon",
    handlers = {
        onAttack = function(ent, target)
            g.iteratePartition("enemy", ent.x, ent.y, function(other)
                if not g.isAlive(other) then return end
                other.taunt = { ent = ent }
            end, 200)
        end,
    },
})


g.definePerk("sharpshooter", "Sharpshooter", {
    description = loc("This unit fires 1 extra projectile."),
    image = "coin_icon",
    handlers = {
        getProjectileCountModifier = function(ent)
            return 1
        end,
    },
})

g.definePerk("berserker", "Berserker", {
    description = loc("This unit gains +5 attack when below 50% health."),
    image = "coin_icon",
    handlers = {
        getAttackDamageModifier = function(ent, attack)
            if ent.health and ent.maxHealth and ent.health < ent.maxHealth * 0.5 then
                return 5
            end
            return 0
        end,
    },
})

g.definePerk("bolstering_brew", "Bolstering Brew", {
    description = loc2("On-spawn, 2 nearby allies gain double (ASPD) for 10 seconds."),
    image = "coin_icon",
    handlers = {
        entitySpawned = function(ent)
            local buffed = 0
            g.iteratePartition("ally", ent.x, ent.y, function(other)
                if buffed >= 2 then return end
                if other == ent then return end
                if not g.isAlive(other) then return end
                g.addCustomEffect(other, {
                    getAttackSpeedMultiplier = function(e) return 1.5 end,
                    getAttackDamageModifier = function(e) return 1 end,
                }, 10)
                buffed = buffed + 1
            end, 120)
        end,
    },
})

g.definePerk("enrage", "Enrage", {
    description = loc2("The first time this unit takes damage, it gains 1.0 (ASPD)."),
    image = "coin_icon",
    handlers = {
        entityHurt = function(ent, damage, attacker)
            if not ent._enraged then
                ent._enraged = true
                g.buffEntity(ent, "attackSpeed", 1.0)
            end
        end,
    },
})

g.definePerk("infestation", "Infestation", {
    description = loc("On death, spawn a Pest."),
    image = "coin_icon",
    handlers = {
        entityDeath = function(ent, killer)
            g.spawnEntity("pest", ent.x, ent.y)
        end,
    },
})

g.definePerk("his_gratitude", "His Gratitude", {
    description = loc("On death, deal 10 damage to a random enemy."),
    image = "coin_icon",
    handlers = {
        entityDeath = function(ent, killer)
            local enemies = g.getECS():getEnemyList()
            if #enemies > 0 then
                g.dealDamage(enemies[math.random(#enemies)], 4)
            end
        end,
    },
})

g.definePerk("bloodlust", "Bloodlust", {
    description = loc("This unit heals for 50% of damage dealt on each attack."),
    image = "coin_icon",
    handlers = {
        onAttack = function(ent, target)
            if ent.attackDamage and g.isAlive(ent) then
                g.healEntity(ent, ent.attackDamage * 0.5)
            end
        end,
    },
})

g.definePerk("strike_gold", "Strike Gold", {
    description = loc("On-kill, gain 1 Coin."),
    image = "coin_icon",
    handlers = {
        onKill = function(ent, target)
            g.addGold(1)
        end,
    },
})

g.definePerk("extraction", "Extraction", {
    description = loc("When an enemy dies, gain 2 Coins."),
    image = "coin_icon",
    rawHandlers = {
        entityDeath = function(self, dead, killer)
            if dead and dead.team == "enemy" then
                g.addGold(2)
            end
        end,
    },
})

g.definePerk("consumption", "Consumption", {
    description = loc("On-kill, spawn a copy of this unit."),
    image = "coin_icon",
    handlers = {
        onKill = function(ent, target)
            if not g.isAlive(ent) then return end
            if ent.type then
                g.spawnEntity(ent.type, ent.x, ent.y)
            end
        end,
    },
})

g.definePerk("mass_production", "Mass-Production", {
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
})

g.definePerk("ritual_sacrifice", "Ritual Sacrifice", {
    description = loc2("On-spawn, kills a nearby ally to gain +4 (ATK) for the fight."),
    image = "coin_icon",
    handlers = {
        entitySpawned = function(ent)
            local victim = nil
            g.iteratePartition("ally", ent.x, ent.y, function(other)
                if other == ent then return end
                if not g.isAlive(other) then return end
                if other.isCommander then return end
                if (not victim) or (other.health < victim.health) then
                    victim = other
                end
            end, 120)
            if victim then
                g.killEntity(victim, ent)
                g.buffEntity(ent, "attackDamage", 4)
            end
        end,
    },
})

g.definePerk("ritual", "Ritual", {
    description = loc2("On-spawn, gains +1 (ATK) per 2 allies that have died this combat."),
    image = "coin_icon",
    handlers = {
        entitySpawned = function(ent)
            local ecs = g.getECS()
            local amount = math.floor(ecs.allyDeathsThisBattle / 2)
            if amount > 0 then
                g.buffEntity(ent, "attackDamage", amount)
            end
        end,
    },
})

g.definePerk("conflagrate", "Conflagrate", {
    description = loc2("On-attack, a nearby ally takes 1 damage and gains +1 (ATK) for the fight."),
    image = "coin_icon",
    handlers = {
        onAttack = function(ent, target)
            local found = nil
            g.iteratePartition("ally", ent.x, ent.y, function(other)
                if found then return end
                if other == ent then return end
                if not g.isAlive(other) then return end
                found = other
            end, 120)
            if found then
                g.dealDamage(found, 1)
                if g.isAlive(found) then
                    g.addCustomEffect(found, {
                        getAttackDamageModifier = function(e) return 1 end,
                    }, 9999)
                end
            end
        end,
    },
})

g.definePerk("pinpoint", "Pinpoint", {
    description = loc("Deals double damage to enemies beyond 350 units away."),
    image = "coin_icon",
    handlers = {
        onAttack = function(ent, target)
            if target then
                local dx, dy = ent.x - target.x, ent.y - target.y
                if dx*dx + dy*dy > 350*350 then
                    ent.attackDamage = (ent.attackDamage or 0) * 2
                end
            end
        end,
    },
})

--[[ DEFY (backburner - eternal_soldier_squad)
g.definePerk("defy", "Defy", {
    description = loc("For the first 15s of battle, on-death, summon a copy with +1 ATK."),
    image = "coin_icon",
})
]]

g.definePerk("explosive", "Explosive", {
    description = loc("Attacks cause explosions!"),
    image = "coin_icon",
    onHitDamage = function(attacker, dmg, target)
        g.explosion(target.x, target.y, attacker.attackDamage or 0, 70, attacker)
    end,
})


g.definePerk("sadistic", "Sadistic", {
    description = loc2("When a nearby ally takes damage, gains 1 (ATK) for the battle."),
    image = "coin_icon",
    rawHandlers = {
        entityHurt = function(self, ent, damage, attacker)
            if ent == self then return end
            if ent.team ~= "ally" then return end
            if not g.isAlive(self) then return end
            local dx, dy = self.x - ent.x, self.y - ent.y
            if dx*dx + dy*dy > 150*150 then return end
            g.buffEntity(self, "attackDamage", 1)
        end,
    },
})


g.definePerk("eureka", "Eureka", {
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
})

g.definePerk("golden_bulk", "Golden Bulk", {
    description = loc("When you gain Coins during battle, this unit gains an equal amount of armor."),
    image = "coin_icon",
    rawHandlers = {
        goldGained = function(self, amount)
            if not g.isAlive(self) then return end
            g.addArmor(self, amount)
        end,
    },
})

g.definePerk("omen", "Omen", {
    description = loc("Triggers ally's On-death effects without killing them."),
    image = "coin_icon",
    handlers = {
        onAttack = function(ent, target)
            if not ent.healPower then return end
            if not target or not g.isAlive(target) then return end
            if target.entityDeath then
                target.entityDeath(target, ent)
            end
            if target.scope then
                target.scope:call("entityDeath", target, ent)
            end
        end,
    },
})

-- The actual duplication logic lives in the squad's onDeploySquad hook, which is
-- guaranteed to run with the deployed squad fully set up. This perk is the label.
g.definePerk("duplication", "Duplication", {
    description = loc("On-deploy, add a copy of the deployed squad to your bench for the fight."),
    image = "coin_icon",
    handlers = {},
})

g.definePerk("vampiric", "Vampiric", {
    description = loc2("This unit heals for 3 (HP) on kill."),
    image = "coin_icon",
    handlers = {
        onKill = function(ent, target)
            g.healEntity(ent, 3, ent)
        end,
    },
})

