
local BODY_LIFETIME = 1
local BODY_FADETIME = 0.3

-- Visual-only corpse that flies offscreen, used by juice_system on death.
g.defineEntity("body", {
    image = "placeholder",
    drawOrder = 100,
    oyOverride = 0.5,
    lifetime = BODY_LIFETIME,
    init = function(ent, src)
        ent.image = src.image
        ent.faceDir = src.faceDir or 1
        ent.scale = src.scale or 1
        ent.color = src.color
        ent.rot = src.rot or 0
        ent._age = 0
        local dir = love.math.random() < 0.5 and -1 or 1
        ent.vx = dir * love.math.random(80, 160)
        ent.vy = -love.math.random(220, 290)
        ent._vrot = dir * (love.math.random() * 6 + 2)
    end,
    onUpdate = function(ent, dt)
        ent._age = ent._age + dt
        ent.vy = ent.vy + 900 * dt
        ent.rot = ent.rot + ent._vrot * dt
        local t = (BODY_LIFETIME - ent._age) / BODY_FADETIME
        ent.alpha = math.min(1, math.max(0, t))
    end,
})



g.defineEntity("nexus", {
    image = "placeholder",

    -- "nexus" is an object that spawns at the start of every battle.
    -- it has health; if destroyed, you lose the game.

    -- nexus also shoots arrows at the nearest enemy too.

    isBuilding = true,
    team = "ally",
    partitions = {"unit", "ally"},
    physics = { shape = "circle", radius = 12, ox = 0, oy = 0, mass = 1, isStatic = true },
    ai = { target = "enemy" },
    attack = { attackType = "ranged", projectileType = "arrow", projectileSpeed = 300 },
    weapon = { image = "placeholder", type = "bow" },
    baseAttackDamage = 3,
    baseAttackSpeed = 0.8,
    baseAttackRange = 250,
    baseMaxHealth = 200,
})


