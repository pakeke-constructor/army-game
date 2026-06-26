
g.defineSpell("heal_spell", {
    name = "Heal",
    rarity = g.RARITIES.COMMON,
    icon = "heal_spell",
    cost = {green = 1},
    description = loc("Heal allies near the target point."),

    spellRange = 100,

    cast = function(spellId, x, y)
        -- TODO: actual effect
    end
})


g.defineSpell("poison_spell", {
    name = "Poison Cloud",
    rarity = g.RARITIES.UNCOMMON,
    icon = "poison_spell",
    cost = {green = 1},
    description = loc("Poison enemies near the target point."),

    spellArea = 100,
})


g.defineSpell("EXAMPLE_TEST_SPELL", {
    name = "Heal",
    rarity = g.RARITIES.COMMON,
    icon = "heal_spell",
    cost = {green = 1},
    description = loc("Give flying allies +10 health"),

    spellRange = 100,

    instantCast = {
        target = "ally", -- ally or enemy

        maxTargets = nil, -- can target many entities.
        -- (if maxTargets is set to N, that means the spell will only hit N entities.)

        filter = function(ent, castX,castY)
            return g.hasTrait(ent, "flying")
        end,
        apply = function(ent, castX,castY)

        end
    },
})


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
