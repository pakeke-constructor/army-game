

local function defineProjectile(id, etype)
    etype.drawOrder = etype.drawOrder or 10
    etype.projectile = true-- component marker for ECS iterate
    local partitions = helper.shallowCopy(etype.partitions)
    table.insert(partitions, "projectile")
    etype.partitions = partitions
    g.defineEntity(id, etype)
end


defineProjectile("_projectile", {
    image = "1x1", -- fallback; overridden by specific projectile types
})


defineProjectile("arrow", {
    image = "green_arrow",
})

