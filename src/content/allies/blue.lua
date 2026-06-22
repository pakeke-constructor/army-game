



local PURPLE_COLOR = objects.Color("#".."FFC339ED")


g.defineSquad("crystal_golems", {
    name = "Crystal golems",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "gargoyle", -- no crystal-golem sprite; gargoyle stand-in
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 2 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "dagger",
            type = "sword",
        },
        baseAttackDamage = 14,
        baseAttackSpeed = 0.8,
        baseAttackRange = 20,
        baseMoveSpeed = 45,
        baseMaxHealth = 180,
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
    icon = "gargoyles_uniticon", -- placeholder
    cost = {blue = 1},
})




g.defineSquad("diver_squad", {
    name = "Divers",
    rarity = g.RARITIES.RARE,
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
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 8,
        baseStartingArmor = 2,
    },
    unitCount = 4,
    perks = {{
        name = "Pressure",
        description = g.loc2("Has damage equal to your currently held (BLUE_MANA)."),
        image = "coin_icon",
        handlers = {
            getAttackDamageModifier = function(ent)
                return g.getBattleManaCounts().blue or 0
            end,
        },
    }},
    cost = {blue = 1},
})


g.defineSquad("test_subjects_squad", {
    name = "Test Subjects",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "testsubject",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "dagger",
            type = "sword",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 8,
    },
    unitCount = 4,
    perks = {{
        name = "Catalyze",
        description = g.loc2("When Transformed, gain +50% (HP) and (ASPD)."),
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
    }},
    cost = {blue = 1},
})




g.defineSquad("monk_squad", {
    name = "Monks",
    rarity = g.RARITIES.COMMON,
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
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 55,
        baseMaxHealth = 8,
    },
    unitCount = 6,
    perks = {{
        name = "Healthy Spirit",
        description = g.loc2("Heals to full HP whenever (BLUE_MANA) is spent."),
        image = "coin_icon",
        handlers = {
            manaSpent = function(ent, manaRequirement)
                if manaRequirement and (manaRequirement.blue or 0) > 0 then
                    g.healEntity(ent, ent.maxHealth or 999)
                end
            end,
        },
    }},
    cost = {blue = 1},
})



g.defineSquad("militia_squad", {
    name = "Militia",
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "militia_sword",
            type = "sword",
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 10,
        baseStartingArmor = 5,
    },
    unitCount = 4,
    icon = "militia_uniticon",
    cost = {blue = 2},
})



g.defineSquad("archer_squad", {
    name = "Archers",
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "longbowman",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 350,
        },
        weapon = {
            image = "longbow",
            type = "bow",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.5,
        baseAttackRange = 150,
        baseMoveSpeed = 55,
        baseMaxHealth = 5,
    },
    unitCount = 8,
    icon = "archer_uniticon",
    cost = {blue = 1},
})



g.defineSquad("orcball_player_squad", {
    name = "Orcball Players",
    rarity = g.RARITIES.COMMON,
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
        name = "Body Slam",
        description = g.loc2("Gains bonus (ATK) equal to current (ARMR). Loses 1 (ARMR) on each attack."),
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
    }},
    cost = {blue = 1},
})



g.defineSquad("defender_squad", {
    name = "Defenders",
    rarity = g.RARITIES.COMMON,
    entityDef = {
        image = "defenders_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "defenders_shield",
            type = "staff"
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
        name = "Knockback",
        description = loc("On-hit, pushes the target back."),
        image = "coin_icon",
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
        name = "Invigorate",
        description = g.loc2("Every 2 seconds, 5 nearby allies gain +50% (ASPD) for 4s."),
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
    }},
    cost = {blue = 2},
})



g.defineSquad("clay_troll_squad", {
    name = "Clay Trolls",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "claytrolls_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "militia_sword", -- placeholder
            type = "sword",
        },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.5,
        baseAttackRange = 18,
        baseMoveSpeed = 40,
        baseMaxHealth = 18,
    },
    unitCount = 4,
    perks = {{
        name = "Protective Coating",
        description = g.loc2("On-hurt, gives a random nearby ally 1 (ARMR). Only triggers on (HP) damage."),
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
    }},
    cost = {blue = 1},
})



g.defineSquad("war_elephant_squad", {
    name = "War Elephants",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "warelephants_unit",
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 2 },
        attack = { attackType = "melee" },
        --weapon = { image = "militia_sword", type = "sword" },
        baseAttackDamage = 4,
        baseAttackSpeed = 0.6,
        baseAttackRange = 22,
        baseMoveSpeed = 40,
        baseMaxHealth = 60,
        baseStartingArmor = 12,
    },
    unitCount = 2,
    perks = {{
        name = "Helmheart",
        description = g.loc2("Whenever a Blue unit spawns, gains 1 (ARMR)."),
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
    entityDef = {
        image = "magnetelemental_unit",
        physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 280 },
        -- weapon = { image = "placeholder", type = "bow" },
        baseAttackDamage = 2,
        baseAttackSpeed = 0.7,
        baseAttackRange = 120,
        baseMoveSpeed = 50,
        baseMaxHealth = 20,
        baseStartingArmor = 3,
    },
    unitCount = 2,
    perks = {{
        name = "Shrapnelmancy",
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
    }},
    cost = {blue = 1},
})




g.defineSquad("immortal_eye_squad", {
    name = "The Immortal Eye",
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "theimmortaleye_unit",
        isBuilding = true,
        physics = { shape = "circle", radius = 10, ox = 0, oy = 0, mass = 1, isStatic = true },
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 300 },
        -- weapon = { image = "placeholder", type = "bow" },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.8,
        baseAttackRange = 220,
        baseMaxHealth = 80,
        baseStartingArmor = 10,
    },
    perks = {{
        name = "Rebirth",
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
    }},
    cost = {blue = 2},
})



g.defineSquad("bell_creature_squad", {
    name = "Bell Creatures",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "bellman",
        physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
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
        name = "Reverberate",
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
    }},
    cost = {blue = 1},
})



g.defineSquad("laser_gunner_squad", {
    name = "Laser Gunners",
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "lasergunners_unit",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        -- TODO: Laser cannon attack rather than arrow?
        attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 380 },
        weapon = { image = "lasergunners_lasercannon", type = "bow" },
        baseAttackDamage = 1,
        baseAttackSpeed = 0.5,
        baseAttackRange = 120,
        baseMoveSpeed = 50,
        baseMaxHealth = 8,
    },
    unitCount = 4,
    perks = {{
        name = "Laser Focus",
        description = g.loc2("On-attack, this unit gains 0.1 (ASPD). Stacks up to 30 times."),
        image = "coin_icon",
        handlers = {
            onAttack = function(ent, target)
                ent._laserFocusStacks = ent._laserFocusStacks or 0
                if ent._laserFocusStacks >= 30 then return end
                ent._laserFocusStacks = ent._laserFocusStacks + 1
                g.buffEntity(ent, "attackSpeed", 0.1)
            end,
        },
    }},
    cost = {blue = 1},
})



g.defineEntity("living_mana", {
    name = "Living Mana",
    image = "mana_blue_large",
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 0.3 },
    attack = { attackType = "melee" },
    weapon = { image = "1x1", type = "object" },
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

    -- Part of Manaborn perk, supposedly
    entityDeath = function(ent)
        g.addMana("blue", 1, ent)
    end
})

g.defineSquad("anima_incubator_squad", {
    name = "Anima Incubator",
    rarity = g.RARITIES.RARE,
    entityId = "anima_incubator",
    entityDef = {
        image = "anima_incubator",
        isBuilding = true,
        physics = { shape = "circle", isStatic = true, radius = 20, ox = 0, oy = 0, mass = 5 },
        attack = { attackType = "melee" },
        weapon = { image = "1x1", type = "object" },

        baseAttackDamage = 1,
        baseAttackSpeed = 0.5,
        baseAttackRange = 120,
        baseMoveSpeed = 0,
        baseMaxHealth = 200,
    },
    unitCount = 1,
    perks = {{
        name = "Manaborn Legion",
        description = g.loc2("For every 5 seconds, consume 1 (BLUE_MANA) to summon a {BLUE_MANA_COLOR}Living Mana{/BLUE_MANA_COLOR}. {BLUE_MANA_COLOR}Living Mana{/BLUE_MANA_COLOR} gives 1 (BLUE_MANA) On-death."),
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
    }},
    cost = {blue = 1},
})

g.defineSquad("ice_mage_squad", {
    name = "Ice Mage",
    rarity = g.RARITIES.UNCOMMON,
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
        name = "Ice Touch",
        description = loc("On-hit, 25% chance to Freeze for 5s. {c r=0.388 g=0.388 b=0.388}Prioritizes unfrozen targets.{/c}"),
        image = "coin_icon",
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
