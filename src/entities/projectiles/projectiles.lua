

---@param id string
local function defineProjectile(id, etype)
    etype.drawOrder = etype.drawOrder or 10
    etype.floatingProjectile = etype.floatingProjectile or false
    etype.projectile = true-- component marker for ECS iterate
    etype.shadow = {opacity = 0.35}
    local partitions = helper.shallowCopy(etype.partitions or {})
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


defineProjectile("bread", {
    image = "bread"
})


defineProjectile("octopus_lazer", {
    image = "octopus_lazer"
})





defineProjectile("blazingbombardier_bomb", {
    image = "blazingbombardier_bomb",
    ---@param projEnt ecs.Entity
    projectileHit = function(projEnt)
        g.explosion(projEnt.x, projEnt.y, 3, 10, projEnt.projectile.ownerEnt)
    end
})


defineProjectile("incense_pan", {
    image = "incense_pan"
})



local FIRE_PROJECTILES_PER_SECOND = 4

defineProjectile("fire_projectile", {
    image = "null",
    floatingProjectile = true,
    onUpdate = function(ent, dt)
        if love.math.random() < FIRE_PROJECTILES_PER_SECOND*dt then
            g.spawnParticle("fire_particle", ent.x, ent.y - (ent.z or 0), 1)
        end
    end,
})


local DRUID_FIRE_PARTICLES_PER_SECOND = 35

defineProjectile("druid_fire", {
    image = "null",
    floatingProjectile = true,
    onUpdate = function(ent, dt)
        if love.math.random() < DRUID_FIRE_PARTICLES_PER_SECOND*dt then
            g.spawnParticle("fire_particle", ent.x, ent.y - (ent.z or 0), 1)
        end
    end,
    ---@param projEnt ecs.Entity
    ---@param hitEnt ecs.Entity?
    projectileHit = function(projEnt, hitEnt)
        if hitEnt then
            g.applyBurn(hitEnt, 3, projEnt.projectile.ownerEnt)
        end
    end,
})

