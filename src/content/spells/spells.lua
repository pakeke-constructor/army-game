



g.defineSpell("heal_spell", {
    name = "Heal",
    rarity = g.RARITIES.COMMON,
    icon = "heal_spell",
    cost = {green = 1},
    description = loc("Heal allies in range!"),

    spellRange = 100,

    instantCast = {
        target = "ally",
        maxTargets = 10,
        apply = function(ent, castX, castY, spellId)
            g.healEntity(ent, 15, g.getCommanderEntity())
        end
    }
})


g.defineSpell("poison_spell", {
    name = "Poison Cloud",
    rarity = g.RARITIES.UNCOMMON,
    icon = "poison_spell",
    cost = {green = 1},
    description = loc("Poison enemies in range!"),

    spellRange = 100,

    instantCast = {
        target = "enemy",
        maxTargets = 20,
        apply = function(ent, castX, castY, spellId)
            g.applyPoison(ent, 2, g.getCommanderEntity())
        end
    }
})


--[[

g.defineSpell("ace_spell", {
    name = "Ace",
    rarity = g.RARITIES.COMMON,
    icon = "ace_spell",
    cost = {red = 1},
    spellRange = 100,
})


g.defineSpell("coin_spell", {
    name = "Coin",
    rarity = g.RARITIES.COMMON,
    icon = "coin_spell",
    cost = {blue = 1},
    spellRange = 100,
})


g.defineSpell("howl_spell", {
    name = "Howl",
    rarity = g.RARITIES.COMMON,
    icon = "howl_spell",
    cost = {green = 1},
    spellRange = 100,
})


g.defineSpell("ranged_spell", {
    name = "Ranged",
    rarity = g.RARITIES.COMMON,
    icon = "ranged_spell",
    cost = {yellow = 1},
    spellRange = 100,
})


g.defineSpell("skull_spell", {
    name = "Skull",
    rarity = g.RARITIES.COMMON,
    icon = "skull_spell",
    cost = {red = 1},
    spellRange = 100,
})

]]