



local sqhelper = require(".squad_helper")
local juiceService = require("src.juiceService")

local FROST_ARC_COLOR = objects.Color("#88CCFF")


sqhelper.defineMilitiaAndArchers("blue")


-- ============================================================
-- BASIC UNITS: Fish-folk (blue)
-- ============================================================

g.defineSquad("shield_fish_squad", {
    name = "Shield-Fish",
    rarity = g.RARITIES.COMMON,
    -- tags: armor (basic tank)love 
    tags = {"armor"},
    entityDef = {
        image = g.leo("shieldfish_unit", "defenders_unit"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = g.leo("shieldfish_shield", "defenders_shield"),
            type = "shield",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 14,
        baseStartingArmor = 3,
    },
    unitCount = 4,
    startingTraits = {"fishfolk"},
    cost = {blue = 1},
})

g.defineSquad("spear_fish_squad", {
    name = "Spear-Fish",
    rarity = g.RARITIES.COMMON,
    -- tags: attack_damage (long-reach melee dmg)
    tags = {"attack_damage"},
    entityDef = {
        image = g.leo("spearfish_unit", "divers_unit"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = g.leo("spearfish_spear", "divers_harpoon"),
            type = "spear",
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 32,
        baseMoveSpeed = 55,
        baseMaxHealth = 6,
    },
    unitCount = 4,
    startingTraits = {"fishfolk"},
    cost = {blue = 1},
})

g.defineSquad("arrow_fish_squad", {
    name = "Arrow-Fish",
    rarity = g.RARITIES.COMMON,
    -- tags: ranged, projectile (basic ranged)
    tags = {"ranged", "projectile"},
    entityDef = {
        image = g.leo("arrowfish_unit", "longbowman"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 350,
        },
        weapon = {
            image = g.leo("arrowfish_bow", "longbow"),
            type = "bow",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.6,
        baseAttackRange = 130,
        baseMoveSpeed = 55,
        baseMaxHealth = 5,
    },
    unitCount = 4,
    startingTraits = {"fishfolk"},
    cost = {blue = 1},
})


g.defineSquad("viking_squad", {
    name = "Vikings",
    rarity = g.RARITIES.COMMON,
    tags = {"attack_damage", "health", "freeze"},
    entityDef = {
        image = g.leo("viking", "barbarian"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = g.leo("viking_axe", "orc_battleaxe"),
            type = "sword",
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 10,
    },
    unitCount = 6,
    icon = g.leo("vikings_uniticon", "barbarian_uniticon"),
    perks = {{
        id = "perk_icebreaker",
        name = "Icebreaker",
        description = loc("Deals 3x damage to frozen enemies."),
        handlers = {
            onHitDamage = function(ent, damage, target, hitArmor)
                if not hitArmor and (target.frozenTime or 0) > 0 then
                    g.dealDamage(target, damage * 2, ent, true)
                end
            end,
        },
    }},
    cost = {blue = 1},
})



local PURPLE_COLOR = objects.Color("#".."FFC339ED")


g.defineSquad("prism_golems", {
    name = "Crystal golems",
    rarity = g.RARITIES.RARE,
    -- tags: projectile
    tags = {"projectile"},
    entityDef = {
        image = g.leo("prismgolems_unit"),
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 2 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "dagger",
            type = "sword",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.4,
        baseAttackRange = 20,
        baseMoveSpeed = 45,
        baseMaxHealth = 220,
        onUpdate = function(self)
            local radius = (self.physics and self.physics.radius or 8) + 4
            local radiusSq = radius * radius
            g.iteratePartition("projectile", self.x, self.y, function(projEnt)
                if projEnt == self then return end
                if projEnt._projectileCloned then return end
                if not projEnt.projectile then return end
                if projEnt.projectile.team ~= "ally" then return end
                local dx = projEnt.x - self.x
                local dy = projEnt.y - self.y
                if dx * dx + dy * dy > radiusSq then return end

                local clone = g.spawnEntity(projEnt.type, projEnt.x, projEnt.y)
                local DRIFT = 0.80
                clone.vx = (projEnt.vx or 0) * (1 + (love.math.random() - 0.5) * DRIFT)
                clone.vy = (projEnt.vy or 0) * (1 + (love.math.random() - 0.5) * DRIFT)
                clone.vz = projEnt.vz
                clone.z = projEnt.z
                clone.projectile = helper.shallowCopy(projEnt.projectile)

                clone.color = PURPLE_COLOR
                clone.scale = 2
                projEnt.color = PURPLE_COLOR
                projEnt.scale = 2

                projEnt._projectileCloned = true
                clone._projectileCloned = true
            end, radius)
        end,
    },
    unitCount = 2,
    icon = g.leo("prismgolems_uniticon"),
    cost = {blue = 2},
})




g.defineSquad("diver_squad", {
    name = "Divers",
    rarity = g.RARITIES.RARE,
    -- tags: attack_damage, buffing
    tags = {"attack_damage", "buffing"},
    entityDef = {
        image = "divers_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "divers_harpoon",
            type = "spear",
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 8,
        baseStartingArmor = 2,
    },
    unitCount = 3,
    startingTraits = {"fishfolk"},
    perks = {{
        id = "perk_reefrally",
        name = "Reef Rally",
        description = g.loc2("At the start of battle, give a random Fishfolk unit +4 (ATK)."),
        rawHandlers = {
            battleStarted = function(self)
                if not g.isAlive(self) then return end
                local fishfolk = {}
                for _, other in ipairs(g.getAllyList()) do
                    if g.isAlive(other) and g.hasTrait(other, "fishfolk") then
                        fishfolk[#fishfolk + 1] = other
                    end
                end
                if #fishfolk > 0 then
                    g.buffEntity(fishfolk[math.random(#fishfolk)], "attackDamage", 4)
                end
            end,
        },
    }},
    cost = {blue = 1},
})


g.defineSquad("test_subjects_squad", {
    name = "Test Subjects",
    rarity = g.RARITIES.RARE,
    -- tags: transform, health, attack_speed
    tags = {"transform", "health", "attack_speed"},
    entityDef = {
        image = "testsubject",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 8,
    },
    unitCount = 4,
    perks = {{
        id = "perk_catalyze",
        name = "Catalyze",
        description = g.loc2("Gain 4 (HP) and 2 (ATK) per (MAGK) on this unit."),
        handlers = {
            getMaxHealthModifier = function(ent)
                return (ent.magic or 0) * 4
            end,
            getAttackDamageModifier = function(ent)
                return (ent.magic or 0) * 2
            end,
        },
    }},
    cost = {blue = 1},
})




g.defineSquad("monk_squad", {
    name = "Monks",
    rarity = g.RARITIES.COMMON,
    -- tags: attack_damage, magic
    tags = {"attack_damage", "magic"},
    entityDef = {
        image = "monks_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "monks_staff",
            type = "staff",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1.5,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 8,
        baseMagic = 1,
    },
    unitCount = 4,
    perks = {{
        id = "perk_innerfocus",
        name = "Inner Focus",
        description = g.loc2("Deals bonus damage equal to (MAGK)."),
        handlers = {
            getAttackDamageModifier = function(ent)
                return ent.magic or 0
            end,
        },
    }},
    cost = {blue = 1},
})

g.defineSquad("ethereal_archer_squad", {
    name = "Ethereal Archers",
    rarity = g.RARITIES.UNCOMMON,
    tags = {"ranged", "projectile", "attack_damage", "magic"},
    entityDef = {
        image = g.leo("etherealarchers_unit", "longbowman"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 350,
        },
        weapon = {
            image = g.leo("etherealarchers_bow", "longbow"),
            type = "bow",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 150,
        baseMoveSpeed = 55,
        baseMaxHealth = 5,
        baseMagic = 1,
    },
    unitCount = 4,
    icon = g.leo("etherealarchers_uniticon", "archer_uniticon"),
    perks = {{
        id = "perk_arcanearrows",
        name = "Arcane Arrows",
        description = g.loc2("Deals bonus damage equal to (MAGK)."),
        handlers = {
            getAttackDamageModifier = function(ent)
                return ent.magic or 0
            end,
        },
    }},
    cost = {blue = 1},
})


g.defineSquad("enchantress_squad", {
    name = "Enchantress",
    rarity = g.RARITIES.RARE,
    tags = {"healing", "buffing", "magic"},
    entityDef = {
        image = g.leo("enchantress_unit", "icemage"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        ai = { target = "ally" },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 250,
        },
        weapon = {
            image = g.leo("enchantress_staff", "icemage_staff"),
            type = "staff",
        },
        isHealer = true,
        baseHealPower = 2,
        baseAttackSpeed = 0.5,
        baseAttackRange = 120,
        baseMoveSpeed = 50,
        baseMaxHealth = 8,
        baseMagic = 1,
    },
    statUpgradeScaling = {magic = 0.25},
    unitCount = 1,
    icon = g.leo("enchantress_uniticon", "icemage_uniticon"),
    perks = {{
        id = "perk_arcanegift",
        name = "Arcane Gift",
        description = g.loc2("Every second, give the ally with the lowest (MAGK) +1 (MAGK)."),
        rawHandlers = {
            perSecondUpdate = function(ent)
                if not g.isAlive(ent) then return end
                local target
                for _, ally in ipairs(g.getAllyList()) do
                    if g.isAlive(ally) and (not target or (ally.magic or 0) < (target.magic or 0)) then
                        target = ally
                    end
                end
                if target then
                    g.buffEntity(target, "magic", 1, ent)
                end
            end,
        },
    }},
    cost = {blue = 2},
})

g.defineSquad("orcball_player_squad", {
    name = "Orcball Players",
    rarity = g.RARITIES.COMMON,
    -- tags: armor, attack_damage
    tags = {"armor", "attack_damage"},
    entityDef = {
        image = "orcballplayers_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "orcballplayers_orcball",
            type = "sword",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 70,
        baseMaxHealth = 8,
        baseStartingArmor = 4,
    },
    unitCount = 4,
    perks = {{
        id = "perk_bodyslam",
        name = "Body Slam",
        description = g.loc2("Gains bonus (ATK) equal to current (ARMR). Loses 1 (ARMR) on each attack."),
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
    }},
    cost = {blue = 1},
})



g.defineSquad("defender_squad", {
    name = "Defenders",
    rarity = g.RARITIES.COMMON,
    -- tags: crowd_control, armor
    tags = {"crowd_control", "armor"},
    entityDef = {
        image = "defenders_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "defenders_shield",
            type = "shield"
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 10,
        baseStartingArmor = 2,
    },
    unitCount = 6,
    perks = {{
        id = "perk_knockback",
        name = "Knockback",
        description = loc("On-hit, pushes the target back."),
        handlers = {
            onAttack = function(ent, target)
                if target and g.isAlive(target) then
                    g.knockback(target, ent.x, ent.y, 100)
                end
            end,
        },
    }},
    cost = {blue = 1},
})


g.defineSquad("incense_holder_squad", {
    name = "Incense Holders",
    rarity = g.RARITIES.RARE,
    -- tags: healing, ranged, projectile, buffing, attack_speed
    tags = {"healing", "ranged", "projectile", "buffing", "attack_speed"},
    entityDef = {
        image = "incense_priest",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        ai = {
            target = "ally",
        },
        attack = {
            attackType = "ranged",
            projectileType = "incense_pan",
            projectileSpeed = 350,
            projectileHoming = true,
        },
        weapon = {
            image = "incense_pan",
            type = "bow",
        },
        isHealer = true,
        baseHealPower = 3,
        baseAttackSpeed = 0.5,
        baseAttackRange = 300,
        baseMoveSpeed = 45,
        baseMaxHealth = 7,
    },
    unitCount = 4,
    icon = "incenseholder_uniticon",
    perks = {{
        id = "perk_invigorate",
        name = "Invigorate",
        description = g.loc2("Every 2 seconds, 5 nearby allies gain +50% (ASPD) for 4s."),
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
    }},
    cost = {blue = 2},
})



g.defineSquad("clay_troll_squad", {
    name = "Clay Trolls",
    rarity = g.RARITIES.RARE,
    -- tags: armor, buffing
    tags = {"armor", "buffing"},
    entityDef = {
        image = "claytrolls_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.5,
        baseAttackRange = 18,
        baseMoveSpeed = 40,
        baseMaxHealth = 18,
    },
    unitCount = 4,
    perks = {{
        id = "perk_protectivecoating",
        name = "Protective Coating",
        description = g.loc2("On-hurt, gives a random nearby ally 1 (ARMR). Only triggers on (HP) damage."),
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
    }},
    cost = {blue = 1},
})



g.defineSquad("ice_elephant_squad", {
    name = "Ice Elephants",
    rarity = g.RARITIES.RARE,
    -- tags: armor, freeze, crowd_control, scaling
    tags = {"armor", "freeze", "crowd_control", "scaling"},
    entityDef = {
        image = "iceelephants_unit",
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 2 },
        attack = { attackType = "melee" },
        baseAttackDamage = 4,
        baseAttackSpeed = 0.6,
        baseAttackRange = 22,
        baseMoveSpeed = 40,
        baseMaxHealth = 60,
        baseStartingArmor = 12,
    },
    unitCount = 2,
    perks = {{
        id = "perk_frosthide",
        name = "Frost Hide",
        description = g.loc2("When hit, 10% chance to Freeze the attacker for 3s."),
        handlers = {
            entityHurt = function(ent, damage, attacker)
                if attacker and g.isAlive(attacker) and love.math.random() < 0.1 then
                    g.applyFrozen(attacker, 3, ent)
                end
            end,
        },
    }},
    cost = {blue = 2},
})



-- perk was removed; this squad removed too.
------------
-- g.defineSquad("living_spell_squad", {
--     name = "Living Spells",
--     rarity = g.RARITIES.RARE,
--     entityDef = {
--         image = "militia",
--         physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
--         attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 250 },
--         weapon = { image = "placeholder", type = "bow" },
--         baseAttackDamage = 3,
--         baseAttackSpeed = 0.4,
--         baseAttackRange = 130,
--         baseMoveSpeed = 40,
--         baseMaxHealth = 12,
--     },
--     unitCount = 3,
--     cost = {blue = 1},
-- })



g.defineSquad("magnet_elemental_squad", {
    name = "Magnet Elementals",
    rarity = g.RARITIES.RARE,
    -- tags: ranged, projectile, armor
    tags = {"ranged", "projectile", "armor"},
    entityDef = {
        image = "magnetelemental_unit",
        physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 280 },
        baseAttackDamage = 2,
        baseAttackSpeed = 0.7,
        baseAttackRange = 120,
        baseMoveSpeed = 50,
        baseMaxHealth = 20,
        baseStartingArmor = 3,
    },
    unitCount = 2,
    perks = {{
        id = "perk_shrapnelmancy",
        name = "Shrapnelmancy",
        description = loc("When any ally loses armor, this unit deals 1 damage to a random nearby enemy."),
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
    }},
    cost = {blue = 1},
})




g.defineSquad("immortal_eye_squad", {
    name = "The Immortal Eye",
    rarity = g.RARITIES.LEGENDARY,
    -- tags: building, ranged, projectile, freeze, poison
    tags = {"building", "ranged", "projectile", "freeze", "poison"},
    entityDef = {
        image = "theimmortaleye_unit",
        isBuilding = true,
        physics = { shape = "circle", radius = 10, ox = 0, oy = 0, mass = 1, isStatic = true },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 300 },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.8,
        baseAttackRange = 220,
        baseMaxHealth = 80,
        baseStartingArmor = 10,
    },
    perks = {{
        id = "perk_frostblight",
        name = "Frostblight",
        description = g.loc2("Every second, apply (1 POISON) to all frozen enemies."),
        rawHandlers = {
            perSecondUpdate = function(self)
                if not g.isAlive(self) then return end
                for _, other in ipairs(g.getEnemyList()) do
                    if g.isAlive(other) and (other.frozenTime or 0) > 0 then
                        g.applyPoison(other, 1, self)
                    end
                end
            end,
        },
    }},
    cost = {blue = 2},
})



g.defineSquad("bell_creature_squad", {
    name = "Bell Creatures",
    rarity = g.RARITIES.RARE,
    -- tags: buffing, armor
    tags = {"buffing", "armor"},
    entityDef = {
        image = "bellman",
        physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "melee" },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.8,
        baseAttackRange = 20,
        baseMoveSpeed = 40,
        baseMaxHealth = 20,
        baseStartingArmor = 5,
    },
    unitCount = 3,
    icon = "bellcreature_uniticon",
    perks = {{
        id = "perk_reverberate",
        name = "Reverberate",
        description = loc("When this unit is Buffed, deals 1 damage to all nearby enemies."),
        handlers = {
            entityBuffed = function(ent, stat, increase)
                if increase <= 0 then return end
                g.iteratePartition("enemy", ent.x, ent.y, function(other)
                    if not g.isAlive(other) then return end
                    g.dealDamage(other, 1)
                end, 120)
            end,
        },
    }},
    cost = {blue = 1},
})




g.defineEntity("living_mana", {
    name = "Anima",
    image = "mana_blue_large",
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 0.3 },
    attack = { attackType = "melee" },
    partitions = {"unit", "ally"},
    team = "ally",
    ai = { target = "enemy" },
    isPest = true,
    walkAnimation = { bounceHeight = 0, rotationAmount = 0, speed = 0 },

    baseAttackDamage = 1,
    baseAttackSpeed = 0.5,
    baseAttackRange = 80,
    baseMoveSpeed = 100,
    baseMaxHealth = 8,
})

g.defineSquad("anima_incubator_squad", {
    name = "Anima Incubator",
    rarity = g.RARITIES.RARE,
    -- tags: building, pest
    tags = {"building", "pest"},
    entityId = "anima_incubator",
    entityDef = {
        image = "anima_incubator",
        isBuilding = true,
        physics = { shape = "circle", isStatic = true, radius = 20, ox = 0, oy = 0, mass = 5 },
        attack = { attackType = "melee" },

        baseAttackDamage = 1,
        baseAttackSpeed = 0.5,
        baseAttackRange = 120,
        baseMoveSpeed = 0,
        baseMaxHealth = 200,
    },
    unitCount = 1,
    perks = {{
        id = "perk_animaspawner",
        name = "Anima Spawner",
        description = g.loc2("Every 5 seconds, summons an {BLUE_MANA_COLOR}Anima{/BLUE_MANA_COLOR}."),
        image = "mana_blue_small",
        rawHandlers = {
            perSecondUpdate = function(ent)
                if ent:getTypename() ~= "anima_incubator" then
                    return
                end

                ent._animaSpawnTimer = (ent._animaSpawnTimer or 0) + 1
                if ent._animaSpawnTimer >= 5 then
                    local SPAWN_RADIUS = 20
                    local a = math.random() * consts.TAU
                    local ox = math.cos(a) * SPAWN_RADIUS
                    local oy = math.sin(a) * SPAWN_RADIUS
                    g.spawnEntity("living_mana", ent.x + ox, ent.y + oy)
                    ent._animaSpawnTimer = 0
                end
            end
        }
    }},
    cost = {blue = 1},
})

g.defineSquad("mini_ice_golem_squad", {
    name = "Mini Ice Golems",
    rarity = g.RARITIES.UNCOMMON,
    tags = {"freeze", "crowd_control", "death_trigger", "health"},
    entityDef = {
        image = g.leo("miniicegolems_unit", "iceelephants_unit"),
        physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 2 },
        attack = {
            attackType = "melee",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.6,
        baseAttackRange = 20,
        baseMoveSpeed = 40,
        baseMaxHealth = 26,
        baseStartingArmor = 4,
    },
    unitCount = 4,
    perks = {{
        id = "perk_shatter",
        name = "Shatter",
        description = g.loc2("When killed, Freeze nearby enemies for 4s."),
        handlers = {
            entityDeath = function(ent)
                g.iteratePartition("enemy", ent.x, ent.y, function(other)
                    if g.isAlive(other) then
                        g.applyFrozen(other, 4, ent)
                    end
                end, 100)
            end,
        },
    }},
    cost = {blue = 1},
})


g.defineSquad("lightning_wizard_squad", {
    name = "Lightning Wizard",
    rarity = g.RARITIES.RARE,
    tags = {"lightning", "ranged", "projectile", "attack_damage", "magic"},
    entityDef = {
        image = g.leo("lightningwizard_unit", "icemage"),
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 400,
        },
        weapon = {
            image = g.leo("lightningwizard_staff", "icemage_staff"),
            type = "staff",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.65,
        baseAttackRange = 230,
        baseMoveSpeed = 50,
        baseMaxHealth = 12,
        baseMagic = 8,
    },
    unitCount = 1,
    icon = g.leo("lightningwizard_uniticon", "icemage_uniticon"),
    perks = {{
        id = "perk_chainlightning",
        name = "Chain Lightning",
        description = loc("On-hit, emit lightning dealing damage equal to (MAGK)."),
        handlers = {
            onHitDamage = function(ent, damage, target)
                if target and g.isAlive(target) then
                    g.lightning(target.x, target.y, ent.magic or 0, ent, 5)
                end
            end,
        },
    }},
    cost = {blue = 2},
})


g.defineSquad("frost_warden_squad", {
    name = "Frost Warden",
    rarity = g.RARITIES.RARE,
    tags = {"freeze", "crowd_control", "health", "armor"},
    entityDef = {
        image = g.leo("frostwarden_unit", "iceelephants_unit"),
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 2 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = g.leo("frostwarden_scepter", "ice_scepter"),
            type = "staff",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.6,
        baseAttackRange = 24,
        baseMoveSpeed = 40,
        baseMaxHealth = 140,
        baseStartingArmor = 10,
    },
    unitCount = 1,
    icon = g.leo("frostwarden_uniticon", "iceelephants_uniticon"),
    perks = {{
        id = "perk_frostward",
        name = "Frost Ward",
        description = loc("When a spell is cast, Freeze surrounding enemies for 2s."),
        rawHandlers = {
            spellCast = function(ent)
                g.iteratePartition("enemy", ent.x, ent.y, function(enemy)
                    if g.isAlive(enemy) then
                        g.applyFrozen(enemy, 2, ent)
                        juiceService.spawnArc(FROST_ARC_COLOR, ent.x, ent.y, enemy.x, enemy.y, enemy)
                    end
                end, 130)
            end,
        },
    }},
    cost = {blue = 2},
})



g.defineSquad("ice_mage_squad", {
    name = "Ice Mage",
    rarity = g.RARITIES.UNCOMMON,
    -- tags: freeze, crowd_control, ranged, projectile
    tags = {"freeze", "crowd_control", "ranged", "projectile"},
    entityDef = {
        image = "icemage",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "ranged",
            projectileType = "arrow", -- placeholder
            projectileSpeed = 300
        },
        weapon = {
            image = "icemage_staff",
            type = "staff"
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.5,
        baseAttackRange = 120,
        baseMoveSpeed = 50,
        baseMaxHealth = 12,
    },
    unitCount = 4,
    perks = {{
        id = "perk_icetouch",
        name = "Ice Touch",
        description = loc("On-hit, 25% chance to Freeze for 5s. {c r=0.388 g=0.388 b=0.388}Prioritizes unfrozen targets.{/c}"),
        handlers = {
            getAITargetPriorityModifier = function(selfEnt, targEnt)
                return (targEnt.frozenTime or 0) > 0 and 1000 or 0
            end,
            onHitDamage = function(ent, damage, target)
                if target and love.math.random() < 0.25 then
                    g.applyFrozen(target, 5, ent)
                end
            end,
        },
    }},
    cost = {blue = 1},
})
