

g.defineCommander("sir_horse", "Sir Horse", {
    description = loc("Basic commander"),

    startMana = {
        [g.WILDCARD_MANA] = consts.DEV_MODE and 10 or 2,
        -- 10 for dev-mode, 2 for non-dev mode
        red = 2,
        green = 2
    },

    image = "basiccommander",

    onStart = function(run)
        g.addSquadToArmy("militia_squad")
        g.addSquadToArmy("archer_squad")
    end
})

