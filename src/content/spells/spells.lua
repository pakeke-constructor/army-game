
local function damageEnemiesInRadius(x, y, radius, dmg)
    local r2 = radius * radius
    g.iteratePartition("enemy", x, y, function(ent)
        if ent.health and g.isAlive(ent) then
            local dx = ent.x - x
            local dy = ent.y - y
            if dx * dx + dy * dy <= r2 then
                ent.health = ent.health - dmg
                ent._timeSinceDamaged = 0
                g.call("entityHurt", ent, dmg, nil)
                if ent.health <= 0 then
                    ent.health = 0
                    g.call("entityDeath", ent, nil)
                    ent:getWorld():removeEntity(ent)
                end
            end
        end
    end, radius)
end

local function healEnemiesInRadius(x, y, radius, amount)
    local r2 = radius * radius
    g.iteratePartition("enemy", x, y, function(ent)
        if ent.health and ent.maxHealth and g.isAlive(ent) then
            local dx = ent.x - x
            local dy = ent.y - y
            if dx * dx + dy * dy <= r2 then
                ent.health = math.min(ent.maxHealth, ent.health + amount)
            end
        end
    end, radius)
end

g.defineSpell("zap", {
    name = loc("Zap"),
    manaCost = 2,
    cooldown = 0,
    icon = "coin_icon",
    castSpell = function(x, y)
        damageEnemiesInRadius(x, y, 60, 12)
    end,
})

g.defineSpell("heal", {
    name = loc("Heal"),
    manaCost = 2,
    cooldown = 0,
    icon = "coin_icon",
    castSpell = function(x, y)
        healEnemiesInRadius(x, y, 60, 10)
    end,
})
