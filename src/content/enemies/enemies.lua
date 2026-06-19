
---@param id string
---@param def ecs.Components
local function defEnemy(id, def)
    def.team = "enemy"
    def.partitions = {"unit", "enemy"}
    return g.defineEntity(id, def)
end


defEnemy("demon", {
    image = "demon",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
        getPriority = function(selfEnt, targEnt)
            return 0
        end,
    },
    weapon = {
        type = "spear",
        image = "demon_pitchfork"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 2,
    baseAttackSpeed = 1,
    baseAttackRange = 80,
    baseMoveSpeed = 50,
    baseMaxHealth = 10,
})

defEnemy("archerdemon", {
    image = "archerdemon",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
        getPriority = function(selfEnt, targEnt)
            return 0
        end,
    },
    weapon = {
        type = "bow",
        image = "archerdemon_bow"
    },
    attack = {
        attackType = "ranged",
        projectileType = "arrow",
        projectileSpeed = 350,
    },
    baseAttackDamage = 0.6,
    baseAttackSpeed = 0.4,
    baseAttackRange = 600,
    baseMoveSpeed = 45,
    baseMaxHealth = 5,
})

-- FIXME: Balancing of this

defEnemy("blazingbombardier", {
    image = "blazingbombardier",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "bow",
        image = "blazingbombardier_bomb"
    },
    attack = {
        attackType = "ranged",
        projectileType = "blazingbombardier_bomb",
        projectileSpeed = 250,
    },
    baseAttackDamage = 1,
    baseAttackSpeed = 0.5,
    baseAttackRange = 350,
    baseMoveSpeed = 35,
    baseMaxHealth = 4,
})

defEnemy("brimstonecore", {
    image = "brimstonecore",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "object",
        image = "brimstonecore_shards"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 1,
    baseAttackSpeed = 1,
    baseAttackRange = 80,
    baseMoveSpeed = 50,
    baseMaxHealth = 16,

    onDraw = function(ent)
        local dir = ent.id % 2 * 2 - 1
        local t = love.timer.getTime()
        local rot = (dir * consts.TAU * t / 5) % consts.TAU
        local _, h = g.getImageSize(ent.image)
        g.drawImage("brimstonecore_shards", ent.x, ent.y - h / 2, rot)
    end,
    entityDeath = function(ent)
        g.explosion(ent.x, ent.y, 5, 17, ent)
    end,
})

defEnemy("charredsoul", {
    image = "charredsoul",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "object",
        image = "brimstonecore_shards"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 2,
    baseAttackSpeed = 0.5,
    baseAttackRange = 80,
    baseMoveSpeed = 50,
    baseMaxHealth = 6,

    entityUpdate = function(ent, dt)
        ent._nextBuffTime = (ent._nextBuffTime or 0) + dt
        while ent._nextBuffTime >= 3 do
            g.buffEntity(ent, "attackSpeed", 0.2)
            ent._nextBuffTime = ent._nextBuffTime - 3
        end
    end,
})

defEnemy("crimsongoliath", {
    image = "crimsongoliath_body",
    shadow = {},
    physics = { shape = "circle", radius = 32, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "object",
        image = "crimsongoliath_axe"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 6,
    baseAttackSpeed = 0.5,
    baseAttackRange = 80,
    baseMoveSpeed = 20,
    baseMaxHealth = 200,

    onDraw = function(ent)
        -- FIXME: Tweak this
        g.drawImage("crimsongoliath_heads", ent.x, ent.y - 50)
    end,
    -- TODO: This thing on the notes.
    -- Cleave: Also hits enemies in a small area in front of the target.
})

defEnemy("direhound", {
    image = "direhound",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "object",
        -- FIXME: Tweak
        image = "direhound_jaw"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 3,
    baseAttackSpeed = 1.5,
    baseAttackRange = 80,
    baseMoveSpeed = 60,
    baseMaxHealth = 35,

    onUpdate = function(ent, dt)
        ent._buffedTime = math.max((ent._buffedTime or 8) - dt, 0)
    end,
    getAttackDamageMultiplier = function(ent)
        return (ent._buffedTime or 0) > 0 and 2 or 1
    end,
    getAttackSpeedMultiplier = function(ent)
        return (ent._buffedTime or 0) > 0 and 2 or 1
    end,
})

defEnemy("greatbowdemon", { -- Hellfire Greatbowmen
    image = "greatbowdemon",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "bow",
        image = "greatbowdemon_bow"
    },
    attack = {
        attackType = "ranged",
        projectileType = "arrow",
        projectileSpeed = 350,
    },
    baseAttackDamage = 8,
    baseAttackSpeed = 0.5,
    baseAttackRange = 1000,
    baseMoveSpeed = 50,
    baseMaxHealth = 8,
})

defEnemy("hellbat", {
    -- TODO: Mark this as flying
    image = "hellbat",
    shadow = {},
    team = "enemy",
    ai = {
        target = "enemy",
        getPriority = function(selfEnt, targEnt)
            return 0
        end,
    },
    weapon = {
        type = "object",
        image = "1x1"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 1,
    baseAttackSpeed = 1.5,
    baseAttackRange = 80,
    baseMoveSpeed = 75,
    baseMaxHealth = 1,
})

defEnemy("hellbrute", {
    image = "hellbrute",
    shadow = {},
    physics = { shape = "circle", radius = 10, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "object",
        image = "hellbrute_mace"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 1,
    baseAttackSpeed = 1.5,
    baseAttackRange = 80,
    baseMoveSpeed = 75,
    baseMaxHealth = 1,
})

defEnemy("hellhound", {
    image = "hellhound",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "object",
        image = "1x1"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 1,
    baseAttackSpeed = 1.5,
    baseAttackRange = 80,
    baseMoveSpeed = 100,
    baseMaxHealth = 6,

    onUpdate = function(ent, dt)
        ent._buffedTime = math.max((ent._buffedTime or 8) - dt, 0)
    end,
    getAttackDamageMultiplier = function(ent)
        return (ent._buffedTime or 0) > 0 and 2 or 1
    end,
    getAttackSpeedMultiplier = function(ent)
        return (ent._buffedTime or 0) > 0 and 2 or 1
    end,
})

defEnemy("reaper", {
    image = "reaper",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
        getPriority = function(selfEnt, targEnt)
            return 0
        end,
    },
    weapon = {
        type = "object",
        image = "reaper_scythe"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 2,
    baseAttackSpeed = 1,
    baseAttackRange = 80,
    baseMoveSpeed = 50,
    baseMaxHealth = 40,

    -- FIXME: The way this "Death Touch" is implemented is ugly.
    entityHurt = function(ent, damage, attacker)
        -- Need that _dmgThroughDT to prevent infinite loop in EV-bus
        if attacker and not ent._dmgThroughDT then
            local mh = attacker.maxHealth or attacker.baseMaxHealth or 0
            if mh > 0 then
                ent._dmgThroughDT = true
                g.dealDamage(ent, mh, attacker)
                ent._dmgThroughDT = nil
            end
        end
    end
})

defEnemy("shielddemon", {
    image = "shielddemon",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "staff",
        image = "shielddemon_shield"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 1,
    baseAttackSpeed = 0.5,
    baseAttackRange = 80,
    baseMoveSpeed = 50,
    baseMaxHealth = 6,
    baseStartingArmor = 6,
})

defEnemy("soulfirebearer", {
    image = "soulfirebearer",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "staff",
        image = "soulfirebearer_torch"
    },
    attack = {
        -- FIXME: Pretty sure this one is ranged but I need to find projectile for this
        attackType = "melee",
    },
    -- TODO: Damage stats.
    baseAttackDamage = 1,
    baseAttackSpeed = 0.5,
    baseAttackRange = 80,
    baseMoveSpeed = 50,
    baseMaxHealth = 6,
})

defEnemy("speardemon", { -- Demon Spearmen
    image = "speardemon",
    shadow = {},
    physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
    ai = {
        target = "enemy",
    },
    weapon = {
        type = "spear",
        image = "speardemon_spear"
    },
    attack = {
        attackType = "melee",
    },
    baseAttackDamage = 2,
    baseAttackSpeed = 1,
    baseAttackRange = 120,
    baseMoveSpeed = 50,
    baseMaxHealth = 6,
})
