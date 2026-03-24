

g.defineEntity("_projectile", {
    image = "1x1", -- fallback; overridden by specific projectile types
    drawOrder = 10,
    projectile = true, -- component marker for ECS iterate
})

g.defineEntity("arrow", {
    image = "green_arrow",
    drawOrder = 10,
    projectile = true,
})

