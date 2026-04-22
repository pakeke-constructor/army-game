

g.defineCommander("sir_horse", "Sir Horse", {
    description = loc("Basic commander"),

    startMana = {
        red = 3,
        green = 3
    },

    onStart = function(run)
        g.addSquadToArmy(g.newSquad("militia_squad"))
        g.addSquadToArmy(g.newSquad("militia_squad"))
        g.addSquadToArmy(g.newSquad("militia_squad"))

        g.addSquadToArmy(g.newSquad("archer_squad"))
        g.addSquadToArmy(g.newSquad("archer_squad"))
    end
})

