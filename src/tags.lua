local LIST = {
    "burn", -- burn dmg over time
    "poison", -- poison dmg over time
    "freeze", -- freeze/slow
    "crowd_control", -- stun/slow/disable
    "status_effect", -- status effect mechanics
    "explosion", -- blast/aoe burst
    "ranged", -- ranged attacks
    "projectile", -- projectile-based
    "attack_damage", -- damage scaling
    "attack_speed", -- speed scaling
    "health", -- max hp/tankiness
    "healing", -- healing effects
    "lifesteal", -- damage -> heal
    "armor", -- armor effects
    "buffing", -- ally stat buffs
    "death_trigger", -- on-death effects
    "transform", -- morph/evolve
    "swarm", -- many cheap units
    "pest", -- tiny disposable units
    "mana_gain", -- gain mana
    "economy", -- gain/spend gold value
    "shop", -- shop interaction
    "xp", -- xp/level effects
    "demon_fury", -- demon fury effects
    "deployment", -- deploy-time effects
    "building", -- building/static units
    "squad_size", -- changes unit count
    "color_synergy", -- mana color synergy
    "commander", -- commander-focused
    "scaling", -- stacks over time
}

local SET = {}
for _, tag in ipairs(LIST) do
    assert(not SET[tag], "Duplicate official tag: " .. tag)
    SET[tag] = true
end

return {
    LIST = LIST,
    SET = SET,
}
