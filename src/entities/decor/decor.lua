


g.defineEntity("tree_1", {
    image = "tree_large_1"
})


g.defineEntity("grass", {
    init = function (ent)
        ent.image = "grass_"..love.math.random(1,3)
    end,
    image = "grass_1"
})


