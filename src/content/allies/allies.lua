


g.defineSquad("archer_squad", {
    name = loc("Archer squad"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "longbowman", -- placeholder
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = {
            target = "enemy",
        },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 350,
        },
        baseAttackDamage = 8,
        baseAttackSpeed = 0.8,
        baseAttackRange = 200,
        baseMoveSpeed = 50,
        baseMaxHealth = 30,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    perks = {"sharpshooter"},
    cost = {red = 1},

    statUpgradeScaling = {maxHealth = 0.5},
})



g.defineSquad("healer_archer_squad", {
    name = loc("Healer archer squad"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "longbowman",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = {
            target = "ally",
        },
        attack = {
            attackType = "ranged",
            projectileType = "arrow",
            projectileSpeed = 250,
        },
        isHealer = true,
        baseHealPower = 10,
        baseAttackSpeed = 0.8,
        baseAttackRange = 200,
        baseMoveSpeed = 50,
        baseMaxHealth = 30,
    },
    unitCount = 4,
    icon = "example_squad_icon",
    cost = {red = 1},
})



g.defineSquad("militia_squad", {
    name = loc("Militia squad"),
    rarity = g.RARITIES.UNCOMMON,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = {
            target = "enemy",
        },
        attack = {
            attackType = "melee",
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
    icon = "example_squad_icon",
    perks = {"tough"},
    cost = {green = 1},
})



g.defineSquad("militia_band", {
    name = loc("Militia beserkers"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "militia",
        physics = { shape = "circle", radius = 5, ox = 0, oy = 0, mass = 1 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = {
            target = "enemy",
        },
        attack = {
            attackType = "melee",
        },
        baseAttackDamage = 10,
        baseAttackSpeed = 1,
        baseAttackRange = 18,
        baseMoveSpeed = 60,
        baseMaxHealth = 120,
    },
    unitCount = 6,
    icon = "example_squad_icon",
    perks = {"berserker"},
    cost = {green = 1, red=1},
})




g.defineSquad("crystal_golems", {
    name = loc("Crystal golems"),
    rarity = g.RARITIES.RARE,
    entityDef = {
        image = "militia", -- TODO: change to crystal golems
        physics = { shape = "circle", radius = 8, ox = 0, oy = 0, mass = 2 },
        partitions = {"unit", "ally"},
        team = "ally",
        ai = {
            target = "enemy",
        },
        attack = {
            attackType = "melee",
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
                clone.vx = (projEnt.vx or 0) * (1 + (love.math.random() - 0.5) * 0.04)
                clone.vy = (projEnt.vy or 0) * (1 + (love.math.random() - 0.5) * 0.04)
                clone.vz = projEnt.vz
                clone.z = projEnt.z
                clone.projectile = helper.deepCopy(projEnt.projectile)
                clone.color = objects.Color.PURPLE

                projEnt._projectileCloned = true
                clone._projectileCloned = true
            end, radius)
        end,
    },
    unitCount = 2,
    icon = "example_squad_icon",
    cost = {blue = 1},
})

