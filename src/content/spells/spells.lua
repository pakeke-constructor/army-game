
local RED = g.snapToPalette(objects.Color("FFB42430"))
local BLUE = g.snapToPalette(objects.Color("FF1C7CB7"))
local GREEN = g.snapToPalette(objects.Color("FF52B225"))
local YELLOW = g.snapToPalette(objects.Color("FFD0D31F"))




g.defineSpell("heal_spell", {
    name = "Heal",
    rarity = g.RARITIES.COMMON,
    icon = "heal_spell",
    color = GREEN,
    description = loc("Heal allies in range!"),

    range = 100,
    cooldown = 10,

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
    color = GREEN,
    description = loc("Poison enemies in range!"),

    range = 100,
    cooldown = 10,

    instantCast = {
        target = "enemy",
        maxTargets = 20,
        apply = function(ent, castX, castY, spellId)
            g.applyPoison(ent, 2, g.getCommanderEntity())
        end
    }
})


g.defineSpell("ace_spell", {
    name = "Ace",
    rarity = g.RARITIES.COMMON,
    icon = "ace_spell",
    color = RED,
    range = 100,
    cooldown = 10,
})


g.defineSpell("coin_spell", {
    name = "Coin",
    rarity = g.RARITIES.COMMON,
    icon = "coin_spell",
    color = BLUE,
    range = 100,
    cooldown = 10,
})


g.defineSpell("howl_spell", {
    name = "Howl",
    rarity = g.RARITIES.COMMON,
    icon = "howl_spell",
    color = GREEN,
    range = 100,
    cooldown = 10,
})


g.defineSpell("ranged_spell", {
    name = "Ranged",
    rarity = g.RARITIES.COMMON,
    icon = "ranged_spell",
    color = YELLOW,
    range = 100,
    cooldown = 10,
})




g.defineSpell("insectify_spell", {
    name = "Insectify",
    rarity = g.RARITIES.UNCOMMON,
    icon = "spell_insectify",
    color = GREEN,
    description = loc("Spawn a Pest for every ally in range!"),

    range = 100,
    cooldown = 10,

    instantCast = {
        target = "ally",
        maxTargets = 20,
        apply = function(ent, castX, castY, spellId)
            g.spawnEntity("pest", ent.x, ent.y)
        end
    }
})


g.defineSpell("freeze_spell", {
    name = "Freeze",
    rarity = g.RARITIES.UNCOMMON,
    icon = "freeze_spell",
    color = BLUE,
    description = loc("Freeze enemies in range for 5s!"),

    range = 100,
    cooldown = 10,

    instantCast = {
        target = "enemy",
        maxTargets = 20,
        apply = function(ent, castX, castY, spellId)
            g.applyFrozen(ent, 5, g.getCommanderEntity())
        end
    }
})


g.defineSpell("dark_ritual_spell", {
    name = "Dark Ritual",
    rarity = g.RARITIES.UNCOMMON,
    icon = "dark_ritual_spell",
    color = RED,
    description = g.loc2("Deal 2 damage to allies. Damaged allies gain +2 (MAGK)."),

    range = 100,
    cooldown = 10,

    instantCast = {
        target = "ally",
        maxTargets = 20,
        apply = function(ent, castX, castY, spellId)
            local commander = g.getCommanderEntity()
            local healthBefore = ent.health
            g.dealDamage(ent, 2, commander)
            if g.isAlive(ent) and ent.health < healthBefore then
                g.buffEntity(ent, "magic", 2, commander)
            end
        end
    }
})


g.defineSpell("bonereap_spell", {
    name = "Bonereap",
    rarity = g.RARITIES.RARE,
    icon = "skull_spell",
    color = RED,
    description = loc("Trigger on-death effects on all allies in range, without killing them."),

    range = 100,
    cooldown = 10,

    instantCast = {
        target = "ally",
        maxTargets = 20,
        apply = function(ent, castX, castY, spellId)
            if not ent.isCommander then
                -- dont call entityDeath on commander; since that'll end the game
                g.call("entityDeath", ent)
            end
        end
    }
})


g.defineSpell("harrier_spell", {
    name = "Harrier",
    rarity = g.RARITIES.UNCOMMON,
    icon = "harrier_spell",
    color = YELLOW,
    description = g.loc2("Ranged allies in range gain +70% (RANGE)."),

    range = 100,
    cooldown = 10,

    instantCast = {
        target = "ally",
        maxTargets = 20,
        filter = function(ent, castX, castY, spellId)
            return ent.attack and ent.attack.attackType == "ranged"
        end,
        apply = function(ent, castX, castY, spellId)
            g.addCustomEffect(ent, {
                getAttackRangeMultiplier = function() return 1.7 end,
            }, 15)
        end
    }
})
