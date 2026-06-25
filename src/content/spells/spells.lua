
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

