local BASIC_SQUADS = {
    red = {
        tank = "gremlin_brute_squad",
        bruiser = "gremlin_berserker_squad",
        ranged = "gremlin_slinger_squad",
    },
    green = {
        tank = "human_protector_squad",
        bruiser = "human_lumberjack_squad",
        ranged = "green_archer_squad",
    },
    blue = {
        tank = "shield_fish_squad",
        bruiser = "spear_fish_squad",
        ranged = "arrow_fish_squad",
    },
    yellow = {
        tank = "protect_bot_squad",
        bruiser = "angry_bot_squad",
        ranged = "gun_bot_squad",
    },
}

---@param colors string[]
---@param role string
local function addBasicSquad(colors, role)
    local run = g.getRun()
    local options = {}

    for _, color in ipairs(colors) do
        local squadId = BASIC_SQUADS[color][role]
        if not run.squads[squadId] then
            options[#options + 1] = squadId
        end
    end

    if #options == 0 then return end
    g.addSquadToArmy(options[love.math.random(#options)])
end


local function validate()
    if not consts.DEV_MODE then return end

    for color, roles in pairs(BASIC_SQUADS) do
        g.getSquadInfo(color .. "_militia_squad")
        for _, squadId in pairs(roles) do
            g.getSquadInfo(squadId)
        end
    end
end

g.postLoad(validate)


---@param colors string[]
local function addBasicStartingSquads(colors)
    local color = colors[love.math.random(#colors)]
    g.addSquadToArmy(color .. "_militia_squad")

    addBasicSquad(colors, "tank")
    addBasicSquad(colors, "bruiser")
    addBasicSquad(colors, "ranged")
end


g.defineCommander("sir_horse", "Sir Horse", {
    description = loc("Basic commander"),

    startMana = {
        [g.WILDCARD_MANA] = 2,
        -- 10 for dev-mode, 2 for non-dev mode
        red = 2,
        green = 2
    },

    image = "sirhorse",

    squadDef = {
        rarity = g.RARITIES.COMMANDER,
        unitCount = 1,
        cost = {red = 1, green = 1},
        icon = g.leo"sirhorse_uniticon",
        entityDef = {
            image = "sirhorse",
            isCommander = true,
            weapon = {
                type = "spear",
                image = "sirhorse_spear"
            },
            attack = {
                attackType = "melee",
            },
            baseAttackDamage = 7,
            baseAttackSpeed = 2,
            baseAttackRange = 85,
            baseMoveSpeed = 120,
            baseMaxHealth = 120,
        },
    },

    onStart = function(run)
        addBasicStartingSquads({"red", "green"})
    end
})



g.defineCommander("druidcommander", "Druid Lady", {
    description = loc("Master of the Great Forest"),

    startMana = {
        [g.WILDCARD_MANA] = 2,
        red = 2,
        green = 2
    },

    image = "druidcommander",

    squadDef = {
        rarity = g.RARITIES.COMMANDER,
        unitCount = 1,
        cost = {red = 1, green = 1},
        icon = g.leo"druidcommander_uniticon",
        entityDef = {
            image = "druidcommander",
            isCommander = true,
            walkAnimation = { bounceHeight = 1.8, rotationAmount = 0.09 },
            weapon = {
                type = "staff",
                image = "druidcommander_staff"
            },
            attack = {
                attackType = "ranged",
                projectileType = "druid_fire",
                projectileSpeed = 240, -- slow-moving fire
            },
            baseAttackDamage = 1,
            baseAttackSpeed = 0.45,
            baseAttackRange = 700, -- slightly less than octopus commander
            baseMoveSpeed = 85,
            baseMaxHealth = 160,
        },
        perks = {{
            id = "perk_breathoflife",
            name = "Breath of Life",
            description = g.loc2("Your squads have +25% Max (HP)."),
            rawHandlers = {
                ---@param ent ecs.Entity
                getMaxHealthMultiplier = function(_, ent)
                    return ent.team == "ally" and 1.25 or 1
                end
            }
        }}
    },

    onStart = function(run)
        addBasicStartingSquads({"red", "green"})
    end
})



g.defineCommander("mechcommander", "The Mech Goblin", {
    description = loc("Battle-Engineer."),

    startMana = {
        [g.WILDCARD_MANA] = 2,
        yellow = 2,
        green = 2
    },

    image = "mechcommander",

    squadDef = {
        rarity = g.RARITIES.COMMANDER,
        unitCount = 1,
        cost = {yellow = 1, green = 1},
        icon = g.leo"mechcommander_uniticon",
        entityDef = {
            onHitDamage = function(ent, damage, target)
                g.lightning(target.x, target.y, damage * 0.5, nil, 5)
            end,
            image = "mechcommander",
            isCommander = true,
            walkAnimation = { bounceHeight = 1, rotationAmount = 0.05 },
            weapon = {
                type = "sword",
                image = "mechcommander_arm",
                drawBehind = true,
                xOffset = 10,
                yOffset = 10,
            },
            attack = {
                attackType = "melee",
            },
            baseAttackDamage = 12,
            baseAttackSpeed = 0.5,
            baseAttackRange = 70,
            baseMoveSpeed = 80,
            baseMaxHealth = 100,
        },
        -- TODO Perk: Progress: Gain 20 gold when you upgrade a squad.
    },

    onStart = function(run)
        addBasicStartingSquads({"yellow", "green"})
    end
})



g.defineCommander("lizardcommander", "Lizard Lord", {
    description = loc("King of the great lizard clan."),

    startMana = {
        [g.WILDCARD_MANA] = 2,
        red = 2,
        blue = 2
    },

    image = "lizardcommander",

    squadDef = {
        rarity = g.RARITIES.COMMANDER,
        unitCount = 1,
        cost = {red = 1, blue = 1},
        icon = g.leo"lizardcommander_uniticon",
        entityDef = {
            image = "lizardcommander",
            isCommander = true,
            walkAnimation = { bounceHeight = 2, rotationAmount = 0.10 },
            weapon = {
                type = "sword",
                image = "lizardcommander_axe",
            },
            attack = {
                attackType = "melee",
            },
            baseAttackDamage = 15,
            baseAttackSpeed = 0.85,
            baseAttackRange = 80,
            baseMoveSpeed = 90,
            baseMaxHealth = 100,
        },
        -- TODO Perk: Military Force: Enemy armies are more common. +1 day when defeating a tier 3 army.
    },

    onStart = function(run)
        addBasicStartingSquads({"red", "blue"})
    end
})



g.defineCommander("octopuscommander", "Octopus Tank", {
    description = loc("Aquatic Genius."),

    startMana = {
        [g.WILDCARD_MANA] = 2,
        blue = 2,
        yellow = 2
    },

    image = "octopuscommander",

    squadDef = {
        rarity = g.RARITIES.COMMANDER,
        unitCount = 1,
        cost = {blue = 1, yellow = 1},
        icon = g.leo("octopuscommander_icon"),
        entityDef = {
            image = "octopuscommander",
            isCommander = true,
            -- heavy: barely bounces while walking
            walkAnimation = { bounceHeight = 0.8, rotationAmount = 0.03 },
            physics = { shape = "circle", radius = 20, ox = 0, oy = 0, mass = 7 },
            attack = {
                attackType = "ranged",
                projectileType = "octopus_lazer",
                projectileSpeed = 800,
            },
            baseAttackDamage = 3,
            baseAttackSpeed = 2,
            baseAttackRange = 800, -- unlimited range basically
            baseMoveSpeed = 35, -- but very slow
            baseMaxHealth = 200,
        }
    },

    onStart = function(run)
        addBasicStartingSquads({"blue", "yellow"})
    end
})
