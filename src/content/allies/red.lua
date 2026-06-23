
local sqhelper = require(".squad_helper")


sqhelper.defineMilitiaAndArchers("red")


g.defineSquad("gremlin_technician_squad", {
    name = "Gremlin Technicians",
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "gremlintechnicians_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "gremlintechnicians_wrench",
            type = "sword",
        },
        baseAttackDamage = 3,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 60,
        baseMaxHealth = 6,
        baseStartingArmor = 1,
    },
    unitCount = 4,
    perks = {{
        name = "Volatile",
        description = loc("On-death, explodes in a large area."),
        image = "coin_icon",
        handlers = {
            entityDeath = function(ent, killer)
                g.explosion(ent.x, ent.y, 3, 80)
            end,
        },
    }},
    cost = {red = 1},
})




g.defineSquad("barbarian_squad", {
    name = "Barbarians",
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "barbarian",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "orc_battleaxe",
            type = "sword",
        },
        baseAttackDamage = 3,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 65,
        baseMaxHealth = 6,
    },
    unitCount = 6,
    icon = "barbarian_uniticon",
    perks = {{
        name = "Bloodlust",
        description = loc("This unit heals for 50% of damage dealt on each attack."),
        image = "coin_icon",
        handlers = {
            onAttack = function(ent, target)
                if ent.attackDamage and g.isAlive(ent) then
                    g.healEntity(ent, ent.attackDamage * 0.5)
                end
            end,
        },
    }},
    cost = {red = 1},
})



g.defineSquad("blade_thrower_squad", {
    name = "Blade Throwers",
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "bladethrowers_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "ranged",
            projectileType = "arrow", -- placeholder
            projectileSpeed = 300,
        },
        weapon = {
            image = "bladethrowers_ringblade",
            type = "bow",
        },
        baseAttackDamage = 3,
        baseAttackSpeed = 1,
        baseAttackRange = 70,
        baseMoveSpeed = 55,
        baseMaxHealth = 6,
    },
    unitCount = 6,
    cost = {red = 1},
})




g.defineSquad("brewer_squad", {
    name = "Brewers",
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "brewer",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "brewer_keg",
            type = "sword",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 5,
    },
    unitCount = 8,
    icon = "brewer_uniticon",
    perks = {{
        name = "Bolstering Brew",
        description = g.loc2("On-spawn, 2 nearby allies gain double (ASPD) for 10 seconds."),
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
    }},
    cost = {red = 1},
})



g.defineSquad("tribute_squad", {
    name = "Tributes",
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "tributes_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.5,
        baseAttackRange = 18,
        baseMoveSpeed = 40,
        baseMaxHealth = 4,
    },
    unitCount = 1,
    perks = {{
        name = "His Gratitude",
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
    }},
    cost = {red = 1},
})




g.defineSquad("executioner_squad", {
    name = "Executioners",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "executioners_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "executioners_axe",
            type = "sword",
        },
        baseAttackDamage = 6,
        baseAttackSpeed = 0.5,
        baseAttackRange = 18,
        baseMoveSpeed = 45,
        baseMaxHealth = 10,
    },
    unitCount = 6,
    cost = {red = 2},
})



g.defineSquad("berserker_squad", {
    name = "Berserkers",
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "berserkers_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "berserkers_sword",
            type = "sword",
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 65,
        baseMaxHealth = 16,
    },
    unitCount = 6,
    perks = {{
        name = "Enrage",
        description = g.loc2("The first time this unit takes damage, it gains 1.0 (ASPD)."),
        image = "coin_icon",
        handlers = {
            entityHurt = function(ent, damage, attacker)
                if not ent._enraged then
                    ent._enraged = true
                    g.buffEntity(ent, "attackSpeed", 1.0)
                end
            end,
        },
    }},
    cost = {red = 2},
})







g.defineSquad("dagger_bearer_squad", {
    name = "Dagger Bearers",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "daggerbearers_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "daggerbearers_dagger",
            type = "sword",
        },
        baseAttackDamage = 3,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 65,
        baseMaxHealth = 12,
    },
    unitCount = 4,
    squadOrder = 50,
    perks = {{
        name = "Ritual Sacrifice",
        description = g.loc2("On-spawn, kills a nearby ally to gain +4 (ATK) for the fight."),
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
    }},
    cost = {red = 1},
})



g.defineSquad("furnace_golems_squad", {
    name = "Furnace Golems",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "furnacegolems_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 45,
        baseMaxHealth = 35,
        baseStartingArmor = 3,
    },
    unitCount = 3,
    perks = {{
        name = "Conflagrate",
        description = g.loc2("On-attack, a nearby ally takes 1 damage and gains +1 (ATK) for the fight."),
        image = "coin_icon",
        handlers = {
            onAttack = function(ent)
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
    }},
    cost = {red = 1},
})


g.defineSquad("living_entropy_squad", {
    name = "Living Entropy",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "livingentropy_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 300 },
        baseAttackDamage = 6,
        baseAttackSpeed = 0.8,
        baseAttackRange = 150,
        baseMoveSpeed = 50,
        baseMaxHealth = 15,
    },
    unitCount = 2,
    perks = {{
        name = "Explosive",
        description = loc("Attacks cause explosions!"),
        image = "coin_icon",
        onHitDamage = function(attacker, _, target)
            g.explosion(target.x, target.y, attacker.attackDamage or 0, 70, attacker)
        end,
    }},
    cost = {red = 2},
})


g.defineSquad("his_manifestation_squad", {
    name = "His Manifestation",
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "hismanifestation",
        physics = { shape = "circle", radius = 10, ox = 0, oy = 0, mass = 3 },
        attack = { attackType = "melee" },
        baseAttackDamage = 6,
        baseAttackSpeed = 0.8,
        baseAttackRange = 22,
        baseMoveSpeed = 45,
        baseMaxHealth = 40,
    },
    unitCount = 1,
    perks = {{
        name = "Ritual",
        description = g.loc2("On-spawn, gains +1 (ATK) per 2 allies that have died this combat."),
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
    }},
    cost = {red = 2},
})



g.defineSquad("pain_elemental_squad", {
    name = "Pain Elementals",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "painelementals_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "melee" },
        baseAttackDamage = 5,
        baseAttackSpeed = 1.2,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 15,
    },
    unitCount = 2,
    perks = {{
        name = "Sadistic",
        description = g.loc2("When a nearby ally takes damage, gains 1 (ATK) for the battle."),
        image = "coin_icon",
        rawHandlers = {
            entityHurt = function(self, ent)
                if ent == self then return end
                if ent.team ~= "ally" then return end
                if not g.isAlive(self) then return end
                local dx, dy = self.x - ent.x, self.y - ent.y
                if dx*dx + dy*dy > 150*150 then return end
                g.buffEntity(self, "attackDamage", 1)
            end,
        },
    }},
    cost = {red = 1},
})


g.defineSquad("doom_herald_squad", {
    name = "Doom Heralds",
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "doomheralds_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        ai = { target = "ally" },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 250 },
        weapon = { image = "doomheralds_tome", type = "bow" },
        isHealer = true,
        baseHealPower = 3,
        baseAttackSpeed = 0.4,
        baseAttackRange = 200,
        baseMoveSpeed = 35,
        baseMaxHealth = 12,
    },
    unitCount = 2,
    perks = {{
        name = "Omen",
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
    }},
    cost = {red = 1},
})
