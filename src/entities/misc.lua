
-- Visual-only corpse that flies offscreen, used by juice_system on death.
g.defineEntity("body", {
    image = "placeholder",
    drawOrder = 100,
    lifetime = 1.6,
    init = function(ent, src)
        ent.image = src.image
        ent.faceDir = src.faceDir or 1
        ent.scale = src.scale or 1
        ent.color = src.color
        ent.rot = src.rot or 0
        local dir = love.math.random() < 0.5 and -1 or 1
        ent.vx = dir * love.math.random(80, 160)
        ent.vy = -love.math.random(220, 290)
        ent._vrot = dir * (love.math.random() * 6 + 2)
    end,
    onUpdate = function(ent, dt)
        ent.vy = ent.vy + 900 * dt
        ent.rot = ent.rot + ent._vrot * dt
    end,
})
