local LOC_IRON_HIDE = loc("Iron Hide")
local LOC_IRON_HIDE_DESC = loc("All units take 3 less damage from attacks.")

local LOC_GOLDEN_COFFERS = loc("Golden Coffers")
local LOC_GOLDEN_COFFERS_DESC = loc("Gain 50% more money from all sources.")

local LOC_SWIFT_FEET = loc("Swift Feet")
local LOC_SWIFT_FEET_DESC = loc("All spells cool down 20% faster.")

local LOC_BLOOD_TITHE = loc("Blood Tithe")
local LOC_BLOOD_TITHE_DESC = loc("Gain 5 gold after winning a battle.")

local LOC_BARRAGE = loc("Barrage")
local LOC_BARRAGE_DESC = loc("All ranged units fire 1 extra projectile.")


g.defineBlessing("iron_hide", {
    name = LOC_IRON_HIDE,
    description = LOC_IRON_HIDE_DESC,
    image = "coin_icon",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        getDamageReduction = function(ent)
            return 3
        end,
    },
})

g.defineBlessing("golden_coffers", {
    name = LOC_GOLDEN_COFFERS,
    description = LOC_GOLDEN_COFFERS_DESC,
    image = "coin_icon",
    rarity = g.RARITIES.RARE,
    handlers = {
        getMoneyMultiplier = function()
            return 1.5
        end,
    },
})

g.defineBlessing("swift_feet", {
    name = LOC_SWIFT_FEET,
    description = LOC_SWIFT_FEET_DESC,
    image = "coin_icon",
    rarity = g.RARITIES.COMMON,
    handlers = {
        getCooldownMultiplier = function()
            return 0.8
        end,
    },
})

g.defineBlessing("blood_tithe", {
    name = LOC_BLOOD_TITHE,
    description = LOC_BLOOD_TITHE_DESC,
    image = "coin_icon",
    rarity = g.RARITIES.UNCOMMON,
    handlers = {
        battleWon = function()
            local run = g.getRun()
            run.money = run.money + 5
        end,
    },
})

g.defineBlessing("barrage", {
    name = LOC_BARRAGE,
    description = LOC_BARRAGE_DESC,
    image = "coin_icon",
    rarity = g.RARITIES.LEGENDARY,
    handlers = {
        getProjectileCountModifier = function()
            return 1
        end,
    },
})
