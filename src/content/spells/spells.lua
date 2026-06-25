
g.defineSpell("heal_spell", {
    name = "Heal",
    rarity = g.RARITIES.COMMON,
    icon = "heal_spell",
    cost = {green = 1},
    description = loc("Heal allies near the target point."),

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

    cast = function(spellId, x, y)
        -- TODO: actual effect
    end
})

