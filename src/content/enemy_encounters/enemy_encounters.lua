

local encounters = require("src.scenes.battle_scene.encounters")


-- Simple front-to-back, archers + demon
encounters.defineEnemyEncounter(1, function(es)
    es:add("archerdemon", 10)
    es:add("demon", 10)
end)

-- Melee only
encounters.defineEnemyEncounter(1, function(es)
    es:add("demon", 25)
end)

-- Ranged only
encounters.defineEnemyEncounter(1, function(es)
    es:add("archerdemon", 15)
    es:add("demon", 2)
end)








-- Front to back
encounters.defineEnemyEncounter(2, function(es)
    es:add("archerdemon", 15)
    es:add("demon", 20)
end)














-- MELEE PIT
encounters.defineEnemyEncounter(3, function(es)
    es:add("demon", 55)
end)







-- FUCKING HUGE ARMY
encounters.defineEnemyEncounter(4, function(es)
    es:add("archerdemon", 25)
    es:add("demon", 50)
end)

