
local sqhelper = require(".squad_helper")


sqhelper.defineMilitiaAndArchers("red")


-- ============================================================
-- BASIC UNITS: Gremlins (red)
-- ============================================================

g.defineSquad("gremlin_brute_squad", {
    name = "Gremlin Brutes",
    rarity = g.RARITIES.COMMON,
    -- tags: armor (basic tank)
    tags = {"armor"},
    entityDef = {
        image = g.leo("gremlin_brute_unit", "barbarian"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = g.leo("gremlin_shield", "orc_battleaxe"),
            type = "sword",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 14,
        baseStartingArmor = 3,
    },
    unitCount = 4,
    cost = {red = 1},
})

g.defineSquad("gremlin_berserker_squad", {
    name = "Gremlin Berserkers",
    rarity = g.RARITIES.COMMON,
    -- tags: attack_damage (short-range melee dmg)
    tags = {"attack_damage"},
    entityDef = {
        image = g.leo("gremlin_berserker_unit", "berserkers_unit"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = g.leo("gremlin_cleaver", "daggerbearers_dagger"),
            type = "sword",
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 16,
        baseMoveSpeed = 65,
        baseMaxHealth = 6,
    },
    unitCount = 4,
    cost = {red = 1},
})

g.defineSquad("gremlin_slinger_squad", {
    name = "Gremlin Slingers",
    rarity = g.RARITIES.COMMON,
    -- tags: ranged, projectile (basic ranged)
    tags = {"ranged", "projectile"},
    entityDef = {
        image = g.leo("gremlin_slinger_unit", "bladethrowers_unit"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 300,
        },
        weapon = {
            image = g.leo("gremlin_sling", "longbow"),
            type = "bow",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.6,
        baseAttackRange = 130,
        baseMoveSpeed = 55,
        baseMaxHealth = 5,
    },
    unitCount = 4,
    cost = {red = 1},
})


g.defineSquad("gremlin_technician_squad", {
    name = "Gremlin Technicians",
    rarity = g.RARITIES.COMMON,
    -- tags: explosion, death_trigger
    tags = {"explosion", "death_trigger"},
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
    -- tags: lifesteal
    tags = {"lifesteal"},
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
    -- tags: ranged, projectile
    tags = {"ranged", "projectile"},
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
    -- tags: buffing, attack_speed, death_trigger
    tags = {"buffing", "attack_speed", "death_trigger"},
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
    unitCount = 2,
    icon = "brewer_uniticon",
    perks = {{
        name = "Last Brew",
        description = g.loc2("On-death, double the (ASPD) of 2 random allies."),
        image = "coin_icon",
        handlers = {
            entityDeath = function(ent)
                local buffed = 0
                for _, other in ipairs(g.getAllyList()) do
                    if buffed >= 2 then break end
                    if other ~= ent and g.isAlive(other) then
                        g.addCustomEffect(other, {
                            getAttackSpeedMultiplier = function(e) return 2 end,
                        }, 9999)
                        buffed = buffed + 1
                    end
                end
            end,
        },
    }},
    cost = {red = 1},
})



g.defineSquad("tribute_squad", {
    name = "Tributes",
    rarity = g.RARITIES.UNCOMMON,
    -- tags: death_trigger
    tags = {"death_trigger"},
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
    statUpgradeScaling = {attackSpeed = 0.35},
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
    -- tags: attack_damage
    tags = {"attack_damage"},
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
    -- tags: attack_speed
    tags = {"attack_speed"},
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
    -- tags: attack_damage, death_trigger
    tags = {"attack_damage", "death_trigger"},
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
    perks = {{
        name = "Frenzied Start",
        description = g.loc2("Has triple (ATK) for the first 10 seconds of the fight."),
        image = "coin_icon",
        handlers = {
            getAttackDamageMultiplier = function(ent)
                local ecs = g.tryGetECS()
                if ecs and ecs.secondCount < 10 then
                    return 3
                end
            end,
        },
    }},
    cost = {red = 1},
})



g.defineSquad("furnace_golems_squad", {
    name = "Furnace Golems",
    rarity = g.RARITIES.RARE,
    -- tags: buffing, attack_damage, scaling
    tags = {"buffing", "attack_damage", "scaling"},
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



g.defineSquad("fire_golem_squad", {
    name = "Fire Golems",
    rarity = g.RARITIES.UNCOMMON,
    -- tags: armor, burn
    tags = {"armor", "burn"},
    entityDef = {
        image = g.leo("firegolems_unit", "furnacegolems_unit"), -- no art yet
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 2 },
        attack = { attackType = "melee" },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.7,
        baseAttackRange = 22,
        baseMoveSpeed = 40,
        baseMaxHealth = 95,
        baseStartingArmor = 3,
    },
    unitCount = 2,
    perks = {{
        name = "Molten Skin",
        description = loc("When hit, apply 1 Burn to the attacker."),
        image = "coin_icon",
        handlers = {
            entityHurt = function(ent, damage, attacker)
                if attacker and g.isAlive(attacker) then
                    g.applyBurn(attacker, 1, ent)
                end
            end,
        },
    }},
    cost = {red = 2},
})


g.defineSquad("fire_archer_squad", {
    name = "Fire Archers",
    rarity = g.RARITIES.UNCOMMON,
    -- tags: ranged, projectile, burn
    tags = {"ranged", "projectile", "burn"},
    entityDef = {
        image = g.leo("firearchers_unit", "bladethrowers_unit"), -- no art yet
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 300 },
        weapon = { image = g.leo("firearchers_bow", "bow"), type = "bow" },
        baseAttackDamage = 3,
        baseAttackSpeed = 1,
        baseAttackRange = 70,
        baseMoveSpeed = 55,
        baseMaxHealth = 6,
    },
    unitCount = 4,
    perks = {{
        name = "Flaming Arrows",
        description = loc("Apply 2 Burn on hit."),
        image = "coin_icon",
        handlers = {
            onHitDamage = function(ent, damage, target)
                g.applyBurn(target, 2, ent)
            end,
        },
    }},
    cost = {red = 1},
})


g.defineSquad("living_entropy_squad", {
    name = "Living Entropy",
    rarity = g.RARITIES.RARE,
    -- tags: ranged, projectile, explosion
    tags = {"ranged", "projectile", "explosion"},
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
    statUpgradeScaling = {attackDamage = 0.2},
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
    -- tags: attack_damage, death_trigger, scaling
    tags = {"attack_damage", "death_trigger", "scaling"},
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
    statUpgradeScaling = {attackDamage = 0.1},
    unitCount = 1,
    perks = {{
        name = "Feed on Death",
        description = g.loc2("When an ally dies, gains +1 (ATK)."),
        image = "coin_icon",
        rawHandlers = {
            entityDeath = function(self, ent)
                if ent == self then return end
                if ent.team ~= "ally" then return end
                if not g.isAlive(self) then return end
                g.buffEntity(self, "attackDamage", 1)
            end,
        },
    }},
    cost = {red = 2},
})



g.defineSquad("pain_elemental_squad", {
    name = "Pain Elementals",
    rarity = g.RARITIES.RARE,
    -- tags: attack_damage, scaling
    tags = {"attack_damage", "scaling"},
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
    statUpgradeScaling = {attackSpeed = 0.2},
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
    -- tags: healing, death_trigger
    tags = {"healing", "death_trigger"},
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
    statUpgradeScaling = {healPower = 0.2},
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
