

local encounters = require("src.scenes.battle_scene.encounters")


local DEFAULT_BOUNDS = {1300,600}

-- Simple front-to-back, archers + demon
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("archerdemon", 10)
    es:add("demon", 10)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)

-- Melee only
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("demon", 16)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)

-- Ranged only
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("archerdemon", 15)
    es:add("demon", 5)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)








-- Front to back
encounters.defineEnemyEncounter(2, function(es,ecs)
    es:add("archerdemon", 15)
    es:add("demon", 15)
    ecs:setBounds(1000,700)
end)








-- MELEE PIT
encounters.defineEnemyEncounter(3, function(es,ecs)
    es:add("demon", 55)
    ecs:setBounds(500,500)
end)







-- FUCKING HUGE ARMY
encounters.defineEnemyEncounter(4, function(es,ecs)
    es:add("archerdemon", 25)
    es:add("demon", 50)
end)


