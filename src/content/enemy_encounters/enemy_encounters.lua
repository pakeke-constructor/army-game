

local encounters = require("src.scenes.battle_scene.encounters")


-- Simple front-to-back, archers + demon
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("archerdemon", 10)
    es:add("demon", 10)
    ecs:setBorder(800,400)
end)

-- Melee only
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("demon", 16)
    ecs:setBorder(800,400)
end)

-- Ranged only
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("archerdemon", 15)
    es:add("demon", 5)
    ecs:setBorder(800,400)
end)








-- Front to back
encounters.defineEnemyEncounter(2, function(es,ecs)
    es:add("archerdemon", 15)
    es:add("demon", 15)
    ecs:setBorder(1000,700)
end)








-- MELEE PIT
encounters.defineEnemyEncounter(3, function(es,ecs)
    es:add("demon", 55)
    ecs:setBorder(500,500)
end)







-- FUCKING HUGE ARMY
encounters.defineEnemyEncounter(4, function(es,ecs)
    es:add("archerdemon", 25)
    es:add("demon", 50)
end)


