g.definePerk("pressure", "Pressure", {
    description = loc("Has damage equal to your currently held Blue mana."),
    image = "coin_icon",
    handlers = {
        getAttackDamageModifier = function(ent)
            return g.getBattleManaCounts().blue or 0
        end,
    },
})

g.definePerk("healthy_spirit", "Healthy Spirit", {
    description = loc("Heals to full HP whenever Blue mana is spent."),
    image = "coin_icon",
    handlers = {
        manaSpent = function(ent, manaRequirement)
            if manaRequirement and (manaRequirement.blue or 0) > 0 then
                g.healEntity(ent, ent.maxHealth or 999)
            end
        end,
    },
})

g.definePerk("restore", "Restore", {
    description = loc("On-spawn, nearby allies are healed to full HP."),
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

g.definePerk("body_slam", "Body Slam", {
    description = loc("Gains bonus ATK equal to current ARMR. Loses 1 ARMR on each attack."),
    image = "coin_icon",
    handlers = {
        getAttackDamageModifier = function(ent)
            return math.floor(ent.armor or 0)
        end,
        onAttack = function(ent, target)
            if (ent.armor or 0) > 0 then
                g.dealDamage(ent, 1)
            end
        end,
    },
})

g.definePerk("tough", "Tough", {
    description = loc("This unit takes 2 less damage from attacks."),
    image = "coin_icon",
    handlers = {
        getDamageReduction = function(ent)
            return 2
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
        onAttack = function(ent, attack)
            if ent.hp and ent.maxHp and ent.hp < ent.maxHp * 0.5 then
                attack.damage = attack.damage + 5
            end
        end,
    },
})

g.definePerk("bolstering_brew", "Bolstering Brew", {
    description = loc("On-spawn, 2 nearby allies gain +50% ASPD and +1 DMG for 10 seconds."),
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
    description = loc("The first time this unit takes damage, it gains 1.0 ASPD."),
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

g.definePerk("knockback", "Knockback", {
    description = loc("On-hit, pushes the target back."),
    image = "coin_icon",
    handlers = {
        onAttack = function(ent, target)
            if target and g.isAlive(target) then
                g.knockback(target, ent.x, ent.y, 100)
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
    description = loc("On death, deal massive damage to a random enemy."),
    image = "coin_icon",
    handlers = {
        entityDeath = function(ent, killer)
            local enemies = {}
            for _, other in ent:getWorld():iterate("team") do
                if other.team == "enemy" and g.isAlive(other) then
                    enemies[#enemies + 1] = other
                end
            end
            if #enemies > 0 then
                g.dealDamage(enemies[math.random(#enemies)], 4)
            end
        end,
    },
})

g.definePerk("vitalize", "Vitalize", {
    description = loc("On-heal, the target gains 1 max HP."),
    image = "coin_icon",
    handlers = {
        onAttack = function(ent, target)
            if ent.healPower and target and g.isAlive(target) then
                g.buffEntity(target, "maxHealth", 1)
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
        entityKillsEnemy = function(ent, target)
            g.addGold(1)
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

g.definePerk("vampiric", "Vampiric", {
    description = loc("This unit heals for 3 HP on kill."),
    image = "coin_icon",
    handlers = {
        entityKillsEnemy = function(ent, target)
            if ent.hp and ent.maxHp then
                ent.hp = math.min(ent.hp + 3, ent.maxHp)
            end
        end,
    },
})
