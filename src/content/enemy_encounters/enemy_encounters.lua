
local encounters = require("src.scenes.battle_scene.encounters")


local DEFAULT_BOUNDS = {1300,600}

-- Simple front-to-back, archers + demon
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("archerdemon", 5)
    es:add("archerdemon", 5)
    es:add("demon", 5)
    es:add("demon", 5)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)

-- Melee only
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("demon", 4)
    es:add("demon", 4)
    es:add("demon", 4)
    es:add("demon", 4)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)

-- Ranged only
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("archerdemon", 5)
    es:add("archerdemon", 5)
    es:add("archerdemon", 5)
    es:add("demon", 3)
    es:add("demon", 2)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)

-- Spear wall
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("speardemon", 2)
    es:add("speardemon", 3)
    es:add("speardemon", 2)
    es:add("demon", 2)
    es:add("demon", 2)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)

-- Shield line with archer support
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("shielddemon", 4)
    es:add("shielddemon", 3)
    es:add("archerdemon", 4)
    es:add("archerdemon", 4)
    es:add("archerdemon", 4)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)

-- Hound rush (fast, fragile swarm)
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("hellhound", 4)
    es:add("hellhound", 4)
    es:add("hellhound", 4)
    es:add("hellhound", 3)
    es:add("hellhound", 3)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)








-- Front to back
encounters.defineEnemyEncounter(2, function(es,ecs)
    es:add("archerdemon", 5)
    es:add("archerdemon", 5)
    es:add("archerdemon", 5)
    es:add("demon", 5)
    es:add("demon", 5)
    es:add("demon", 5)
    ecs:setBounds(1000,700)
end)

-- Bombardiers behind exploding cores
encounters.defineEnemyEncounter(2, function(es,ecs)
    es:add("brimstonecore", 4)
    es:add("brimstonecore", 3)
    es:add("blazingbombardier", 4)
    es:add("blazingbombardier", 4)
    ecs:setBounds(1000,700)
end)

-- Spear company with archers
encounters.defineEnemyEncounter(2, function(es,ecs)
    es:add("speardemon", 4)
    es:add("speardemon", 4)
    es:add("speardemon", 4)
    es:add("archerdemon", 6)
    es:add("archerdemon", 6)
    ecs:setBounds(1000,700)
end)

-- Hound pack led by direhounds
encounters.defineEnemyEncounter(2, function(es,ecs)
    es:add("direhound", 3)
    es:add("direhound", 2)
    es:add("hellhound", 4)
    es:add("hellhound", 3)
    es:add("hellhound", 3)
    ecs:setBounds(1000,700)
end)








-- MELEE PIT
encounters.defineEnemyEncounter(3, function(es,ecs)
    es:add("demon", 11)
    es:add("demon", 11)
    es:add("demon", 11)
    es:add("demon", 11)
    es:add("demon", 11)
    ecs:setBounds(500,500)
end)

-- Snipers walled by shields
encounters.defineEnemyEncounter(3, function(es,ecs)
    es:add("greatbowdemon", 3)
    es:add("greatbowdemon", 3)
    es:add("shielddemon", 10)
    es:add("shielddemon", 10)
    es:add("demon", 8)
    es:add("demon", 8)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)

-- Charred horde (ramps up over time)
encounters.defineEnemyEncounter(3, function(es,ecs)
    es:add("charredsoul", 12)
    es:add("charredsoul", 13)
    es:add("demon", 8)
    es:add("demon", 8)
    es:add("demon", 8)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)

-- Reaper guard behind a spear wall
encounters.defineEnemyEncounter(3, function(es,ecs)
    es:add("reaper", 3)
    es:add("reaper", 2)
    es:add("speardemon", 7)
    es:add("speardemon", 7)
    es:add("speardemon", 7)
    es:add("archerdemon", 6)
    es:add("archerdemon", 6)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)







-- FUCKING HUGE ARMY
encounters.defineEnemyEncounter(4, function(es,ecs)
    es:add("archerdemon", 12)
    es:add("archerdemon", 13)
    es:add("demon", 12)
    es:add("demon", 13)
    es:add("demon", 12)
    es:add("demon", 13)
end)

-- Goliath with an escort
encounters.defineEnemyEncounter(4, function(es,ecs)
    es:add("crimsongoliath", 1)
    es:add("demon", 12)
    es:add("demon", 13)
    es:add("archerdemon", 9)
    es:add("archerdemon", 9)
end)

-- Bomber barrage with direhound vanguard
encounters.defineEnemyEncounter(4, function(es,ecs)
    es:add("blazingbombardier", 7)
    es:add("blazingbombardier", 8)
    es:add("brimstonecore", 7)
    es:add("brimstonecore", 8)
    es:add("direhound", 3)
    es:add("direhound", 2)
end)

-- Full legion (everything at once)
encounters.defineEnemyEncounter(4, function(es,ecs)
    es:add("speardemon", 12)
    es:add("speardemon", 13)
    es:add("greatbowdemon", 5)
    es:add("charredsoul", 10)
    es:add("hellhound", 9)
    es:add("hellhound", 9)
end)
