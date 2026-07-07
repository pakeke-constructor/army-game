
local sqhelper = {}


---@param manaType g.ManaType
function sqhelper.defineMilitiaAndArchers(manaType)
    g.defineSquad(manaType.."_militia_squad", {
        name = "Militia",
        rarity = g.RARITIES.UNCOMMON,
        -- tags: armor
        tags = {"armor"},
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
        cost = {[manaType] = 1},
    })

    g.defineSquad(manaType.."_archer_squad", {
        name = "Archers",
        rarity = g.RARITIES.COMMON,
        -- tags: ranged, projectile
        tags = {"ranged", "projectile"},
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
        unitCount = 4,
        icon = "archer_uniticon",
        cost = {[manaType] = 1},
    })
end




return sqhelper

