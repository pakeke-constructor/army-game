

local loc2 = g.loc2

g.definePerk("pressure", "Pressure", {
    description = loc2("Has damage equal to your currently held Blue mana."),
    image = "coin_icon",
    handlers = {
        getAttackDamageModifier = function(ent)
            return g.getBattleManaCounts().blue or 0
        end,
    },
})

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
    description = loc2("Gains bonus (ATK) equal to current (ARMR). Loses 1 (ARMR) on each attack."),
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

g.definePerk("swarmsurge", "Swarmsurge", {
    description = loc("Whenever any Green unit dies, this unit summons a Pest."),
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
})

g.definePerk("growth", "Growth", {
    description = loc("Permanently gains +1 Max HP for every 4 Green mana played this fight."),
    image = "mana_green_small",
    rawHandlers = {
        manaSpent = function(ent, manaRequirement)
            local green = manaRequirement and manaRequirement.green or 0
            if green <= 0 then return end
            ent._growthGreen = (ent._growthGreen or 0) + green
            local stacks = math.floor(ent._growthGreen / 4)
            if stacks <= 0 then return end
            ent._growthGreen = ent._growthGreen - stacks * 4
            g.buffEntity(ent, "maxHealth", stacks)
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

g.definePerk("invigorate", "Invigorate", {
    description = loc2("Every 2 seconds, 5 nearby allies gain +50% (ASPD) for 4s."),
    image = "coin_icon",
    rawHandlers = {
        perSecondUpdate = function(self, secondCount)
            if secondCount % 2 ~= 0 then return end
            if not g.isAlive(self) then return end
            local buffed = 0
            g.iteratePartition("ally", self.x, self.y, function(other)
                if buffed >= 5 then return end
                if other == self then return end
                if not g.isAlive(other) then return end
                g.addCustomEffect(other, {
                    getAttackSpeedMultiplier = function(e) return 1.5 end,
                }, 4)
                buffed = buffed + 1
            end, 200)
        end,
    },
})

g.definePerk("protective_coating", "Protective Coating", {
    description = loc("On-hurt, gives a random nearby ally 1 ARMR. Only triggers on HP damage."),
    image = "coin_icon",
    handlers = {
        entityHurt = function(ent, damage)
            local nearby = {}
            g.iteratePartition("ally", ent.x, ent.y, function(other)
                if other == ent then return end
                if not g.isAlive(other) then return end
                nearby[#nearby + 1] = other
            end, 120)
            if #nearby > 0 then
                g.addArmor(nearby[math.random(#nearby)], 1)
            end
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
            local amount = math.floor(ecs.deathAllies / 2)
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

g.definePerk("life_force", "Life Force", {
    description = loc2("Gain (ATK) equal to max (HP). Take 4 x as much damage."),
    image = "coin_icon",
    handlers = {
        getAttackDamageModifier = function(ent)
            return ent.maxHealth
        end,
        getDamageTakenMultiplier = function(ent)
            return 4
        end,
    },
})

g.definePerk("explosive", "Explosive", {
    description = loc("Attacks cause explosions!"),
    image = "coin_icon",
    onHitDamage = function(attacker, dmg, target)
        g.explosion(target.x, target.y, attacker.attackDamage or 0, 70, attacker)
    end,
})

g.definePerk("helmheart", "Helmheart", {
    description = loc("Whenever a Blue unit spawns, gains 1 ARMR."),
    image = "coin_icon",
    rawHandlers = {
        entitySpawned = function(self, ent)
            if not g.isAlive(self) then return end
            local squadId = ent.type and ent.type:match("^(.-)_unit$")
            if not squadId then return end
            local ok, info = pcall(g.getSquadInfo, squadId)
            if not ok or not (info and info.cost and info.cost.blue) then return end
            g.addArmor(self, 1)
        end,
    },
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


g.definePerk("shrapnelmancy", "Shrapnelmancy", {
    description = loc("When any ally loses armor, this unit deals 1 damage to a random nearby enemy."),
    image = "coin_icon",
    rawHandlers = {
        armorDecreased = function(self, ent, removed)
            if ent.team ~= "ally" then return end
            if not g.isAlive(self) then return end
            local enemies = {}
            g.iteratePartition("enemy", self.x, self.y, function(other)
                if not g.isAlive(other) then return end
                enemies[#enemies + 1] = other
            end, 150)
            if #enemies > 0 then
                g.dealDamage(enemies[math.random(#enemies)], 1)
            end
        end,
    },
})

local function hasMagnificence(ent)
    if not ent.squad then return false end
    for _, p in ipairs(ent.squad.perks or {}) do
        if p == "magnificence" then return true end
    end
    return false
end

g.definePerk("magnificence", "Magnificence", {
    description = loc("When this unit heals or gains max HP, spread the effect to 3 random nearby allies without this perk."),
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
                g.buffEntity(nearby[i], "maxHealth", increase)
            end
        end,
    },
})

g.definePerk("reverberate", "Reverberate", {
    description = loc("When this unit is Buffed, deals 1 damage to all nearby enemies."),
    image = "coin_icon",
    handlers = {
        entityBuffed = function(ent, stat, increase)
            if increase <= 0 then return end
            g.iteratePartition("enemy", ent.x, ent.y, function(other)
                if not g.isAlive(other) then return end
                g.dealDamage(other, 1)
            end, 120)
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

g.definePerk("laser_focus", "Laser Focus", {
    description = loc2("On-attack, this unit gains 0.1 (ASPD). Stacks up to 30 times."),
    image = "coin_icon",
    handlers = {
        onAttack = function(ent, target)
            ent._laserFocusStacks = ent._laserFocusStacks or 0
            if ent._laserFocusStacks >= 30 then return end
            ent._laserFocusStacks = ent._laserFocusStacks + 1
            g.buffEntity(ent, "attackSpeed", 0.1)
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

g.definePerk("circle_of_life", "Circle of Life", {
    description = loc("On-death, all allies gain 10% of this unit's max HP."),
    image = "coin_icon",
    handlers = {
        entityDeath = function(ent, killer)
            local amount = (ent.maxHealth or 0) * 0.1
            if amount <= 0 then return end
            for _, other in ent:getWorld():iterate("team") do
                if other.team == "ally" and g.isAlive(other) then
                    g.buffEntity(other, "maxHealth", amount)
                    g.healEntity(other, amount)
                end
            end
        end,
    },
})

g.definePerk("her_wrath", "Her Wrath", {
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
})

g.definePerk("forge_life", "Forge Life", {
    description = loc2("This unit has additional (HEAL) equal to its (ARMR)."),
    image = "coin_icon",
    handlers = {
        getHealPowerModifier = function(ent)
            return math.floor(ent.armor or 0)
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

g.definePerk("rebirth", "Rebirth", {
    description = loc("When you spend Blue mana, trigger the On-spawn effects of all allied units in a large radius around this building."),
    image = "coin_icon",
    handlers = {
        manaSpent = function(ent, manaRequirement)
            if not (manaRequirement and (manaRequirement.blue or 0) > 0) then return end
            if not g.isAlive(ent) then return end
            g.iteratePartition("ally", ent.x, ent.y, function(other)
                if not g.isAlive(other) then return end
                -- Re-fire the entity's own On-spawn effects: its entityDef hook
                -- and its perk handlers, without re-triggering scene-level listeners.
                if other.entitySpawned then
                    other.entitySpawned(other)
                end
                if other.scope then
                    other.scope:call("entitySpawned", other)
                end
            end, 250)
        end,
    },
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

g.definePerk("manaborn", "Manaborn Legion", {
    -- FIXME: Do proper BLUE_MANA registration on loc2 for this.
    description = loc2("For every 5 seconds, consume 1 {blue} Blue Mana to summon a {c r=0.11 g=0.49 b=0.72}Living Mana{/c}. {c r=0.11 g=0.49 b=0.72}Living Mana{/c} gives 1 {blue} Blue Mana On-death."),
    image = "mana_blue_small",
    rawHandlers = {
        perSecondUpdate = function(ent)
            if ent:getTypename() ~= "anima_incubator" then
                return
            end

            ent._livingManaSpawnTimer = (ent._livingManaSpawnTimer or 0) + 1
            if ent._livingManaSpawnTimer >= 5 then
                if g.trySpendMana(g.getBattleManaCounts(), {blue = 1}) then
                    local SPAWN_RADIUS = 20
                    local a = math.random() * consts.TAU
                    local ox = math.cos(a) * SPAWN_RADIUS
                    local oy = math.sin(a) * SPAWN_RADIUS
                    g.spawnEntity("living_mana", ent.x + ox, ent.y + oy)
                    ent._livingManaSpawnTimer = 0
                end
            end
        end
    }
})

g.definePerk("ice_touch", "Ice Touch", {
    description = loc("On-hit, 25% chance to Freeze for 5s. {c r=0.388 g=0.388 b=0.388}Prioritizes unfrozen targets.{/c}"),
    image = "coin_icon",
    handlers = {
        entitySpawned = function(ent)
            if not ent.ai then return end
            local oldGetPriority = ent.ai.getPriority
            ent.ai = {
                target = ent.ai.target,
                getPriority = function(selfEnt, targEnt)
                    local prio = oldGetPriority and oldGetPriority(selfEnt, targEnt) or 0
                    if (targEnt.frozenTime or 0) <= 0 then
                        prio = prio + 1000
                    end
                    return prio
                end,
            }
        end,
        onHitDamage = function(ent, damage, target)
            if target and love.math.random() < 0.25 then
                g.applyFrozen(target, 5, ent)
            end
        end,
    },
})

g.definePerk("catalyze", "Catalyze", {
    description = loc2("When Transformed, gain +50% (HP) and (ASPD)."),
    image = "coin_icon",
    rawHandlers = {
        entityTransformed = function(self, oldEnt, newEnt)
            if self ~= oldEnt then return end
            local hp = (newEnt.maxHealth or 0) * 0.5
            local aspd = (newEnt.attackSpeed or 0) * 0.5
            g.buffEntity(newEnt, "maxHealth", hp)
            newEnt.maxHealth = (newEnt.maxHealth or 0) + hp
            g.healEntity(newEnt, hp, self)
            g.buffEntity(newEnt, "attackSpeed", aspd)
        end,
    },
})
