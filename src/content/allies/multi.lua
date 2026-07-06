
--[[

g.defineSquad("archer_squad", {
    name = "Archer squad",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "longbowman", -- placeholder
        shadow = {},
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 350,
            aoeRadius = 1
        },
        shadow = {},
        weapon = {
            image = "longbow",
            type = "bow",
        },
        baseAttackDamage = 8,
        baseAttackSpeed = 0.8,
        baseAttackRange = 200,
        baseMoveSpeed = 50,
        baseMaxHealth = 30,
    },
    unitCount = 4,
    perks = {{
        name = "Sharpshooter",
        description = loc("This unit fires 1 extra projectile."),
        image = "coin_icon",
        handlers = {
            getProjectileCountModifier = function(ent)
                return 1
            end,
        },
    }},
    cost = {red = 1},

    statUpgradeScaling = {attackSpeed = 0.5},
})




g.defineSquad("healer_archer_squad", {
    name = "Healer archer squad",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "longbowman",
        shadow = {},
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        ai = {
            target = "ally",
        },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 250,
        },
        weapon = {
            image = "militia", -- placeholder
            type = "bow",
        },
        isHealer = true,
        baseHealPower = 10,
        baseAttackSpeed = 0.8,
        baseAttackRange = 200,
        baseMoveSpeed = 50,
        baseMaxHealth = 30,
    },
    unitCount = 4,
    cost = {red = 1},
})



g.defineSquad("militia_squad", {
    name = "Militia squad",
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "militia",
        shadow = {},
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "militia_sword",
            type = "sword",
        },
        baseAttackDamage = 10,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 60,
        baseMaxHealth = 120,
    },
    unitCount = 4,
    unitCountUpgradeScaling = 2,
    statUpgradeScaling = {
        maxHealth = 0.5
    },
    perks = {},
    cost = {green = 1},
})



g.defineSquad("militia_band", {
    name = "Militia beserkers",
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "militia",
        shadow = {},
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = "militia_sword",
            type = "sword",
        },
        baseAttackDamage = 10,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 60,
        baseMaxHealth = 120,
    },
    unitCount = 6,
    perks = {{
        name = "Berserker",
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
    }},
    cost = {green = 1, red=1},
})
]]




g.defineSquad("aggravator_7000_squad", {
    name = "Aggravator 7000",
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "melee",
        },
        weapon = {
            image = g.leo("aggravator_7000_sword", "dagger"), -- placeholder
            type = "sword",
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 50,
        baseMaxHealth = 40,
        baseStartingArmor = 10,
    },
    unitCount = 1,
    perks = {{
        name = "Racket",
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
    }},
    cost = {red = 1, blue = 1},
})



--[[ ETERNAL SOLDIERS (backburner)
do
    local function makeDefy()
        return {
            entityDeath = function(ent, killer)
                local sqScope = ent.scope and (ent.scope.shared and ent.scope or ent.scope.parent)
                local copy = g.spawnEntity(ent.type, ent.x, ent.y)
                copy.squad = ent.squad
                copy.scope = sqScope
                if ent.buffs then
                    for stat, amount in pairs(ent.buffs) do
                        g.buffEntity(copy, stat, amount)
                    end
                end
                g.buffEntity(copy, "attackDamage", 1)
                g.addCustomEffect(copy, makeDefy(), 15)
            end,
        }
    end

    g.defineSquad("eternal_soldier_squad", {
        name = "Eternal Soldiers",
        rarity = g.RARITIES.RARE,
        entityDef = {
            image = "barbarian",
            physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
            attack = { attackType = "melee" },
            weapon = { image = "orc_battleaxe", type = "sword" },
            baseAttackDamage = 4,
            baseAttackSpeed = 1.3,
            baseAttackRange = 18,
            baseMoveSpeed = 38,
            baseMaxHealth = 18,
        },
        unitCount = 3,
        perks = {{
            description = loc("For the first 15s of battle, on-death, summon a copy with +1 ATK."),
            image = "coin_icon",
        }},
        cost = {red = 1},
        onDeploySquad = function(info, entities)
            for _, ent in ipairs(entities) do
                g.addCustomEffect(ent, makeDefy(), 15)
            end
        end,
    })
end
]]


g.defineSquad("quartz_cannoneer_squad", {
    name = "Quartz Cannoneers",
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "longbowman",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 350,
        },
        weapon = {
            image = g.leo("quartz_cannoneer_cannon", "militia"), -- placeholder
            type = "bow",
        },
        baseAttackDamage = 2,
        baseAttackSpeed = 1,
        baseAttackRange = 450,
        baseMoveSpeed = 45,
        baseMaxHealth = 8,
    },
    unitCount = 4,
    perks = {{
        name = "Pinpoint",
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
    }},
    cost = {blue = 1, red = 1},
})



g.defineSquad("world_devourer_squad", {
    name = "World Devourers",
    rarity = g.RARITIES.LEGENDARY,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 6, ox = 0, oy = 0, mass = 1 },
        attack = { attackType = "melee" },
        weapon = { image = "militia_sword", type = "sword" },
        baseAttackDamage = 2,
        baseAttackSpeed = 1.5,
        baseAttackRange = 20,
        baseMoveSpeed = 55,
        baseMaxHealth = 20,
        baseStartingArmor = 0,
    },
    unitCount = 4,
    perks = {{
        name = "Consumption",
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
    }},
    cost = {green = 1, red = 1},
})




