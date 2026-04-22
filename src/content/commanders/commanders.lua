

g.defineCommander("sir_horse", "Sir Horse", {
    description = loc("Basic commander"),

    startMana = {
        [g.WILDCARD_MANA] = 20,
        red = 2,
        green = 2
    },

    onStart = function(run)
        g.addSquadToArmy(g.newSquad("militia_squad"))
        g.addSquadToArmy(g.newSquad("militia_squad"))
        g.addSquadToArmy(g.newSquad("militia_squad"))
        g.addSquadToArmy(g.newSquad("archer_squad"))
        g.addSquadToArmy(g.newSquad("archer_squad"))
        g.addSquadToArmy(g.newSquad("archer_squad"))
        g.addSquadToArmy(g.newSquad("archer_squad"))
        g.addSquadToArmy(g.newSquad("archer_squad"))
        g.addSquadToArmy(g.newSquad("archer_squad"))

        g.addSquadToArmy(g.newSquad("archer_squad"))
        g.addSquadToArmy(g.newSquad("archer_squad"))
    end
})

