

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

-- Spear wall
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("speardemon", 12)
    es:add("demon", 4)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)

-- Shield line with archer support
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("shielddemon", 7)
    es:add("archerdemon", 12)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)

-- Hound rush (fast, fragile swarm)
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("hellhound", 18)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)








-- Front to back
encounters.defineEnemyEncounter(2, function(es,ecs)
    es:add("archerdemon", 15)
    es:add("demon", 15)
    ecs:setBounds(1000,700)
end)

-- Bombardiers behind exploding cores
encounters.defineEnemyEncounter(2, function(es,ecs)
    es:add("brimstonecore", 7)
    es:add("blazingbombardier", 8)
    ecs:setBounds(1000,700)
end)

-- Spear company with archers
encounters.defineEnemyEncounter(2, function(es,ecs)
    es:add("speardemon", 18)
    es:add("archerdemon", 12)
    ecs:setBounds(1000,700)
end)

-- Hound pack led by direhounds
encounters.defineEnemyEncounter(2, function(es,ecs)
    es:add("direhound", 5)
    es:add("hellhound", 10)
    ecs:setBounds(1000,700)
end)








-- MELEE PIT
encounters.defineEnemyEncounter(3, function(es,ecs)
    es:add("demon", 55)
    ecs:setBounds(500,500)
end)

-- Snipers walled by shields
encounters.defineEnemyEncounter(3, function(es,ecs)
    es:add("greatbowdemon", 6)
    es:add("shielddemon", 20)
    es:add("demon", 16)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)

-- Charred horde (ramps up over time)
encounters.defineEnemyEncounter(3, function(es,ecs)
    es:add("charredsoul", 25)
    es:add("demon", 24)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)

-- Reaper guard behind a spear wall
encounters.defineEnemyEncounter(3, function(es,ecs)
    es:add("reaper", 5)
    es:add("speardemon", 30)
    es:add("archerdemon", 12)
    ecs:setBounds(DEFAULT_BOUNDS[1], DEFAULT_BOUNDS[2])
end)







-- FUCKING HUGE ARMY
encounters.defineEnemyEncounter(4, function(es,ecs)
    es:add("archerdemon", 25)
    es:add("demon", 50)
end)

-- Goliath with an escort
encounters.defineEnemyEncounter(4, function(es,ecs)
    es:add("crimsongoliath", 1)
    es:add("demon", 25)
    es:add("archerdemon", 18)
end)

-- Bomber barrage with direhound vanguard
encounters.defineEnemyEncounter(4, function(es,ecs)
    es:add("blazingbombardier", 15)
    es:add("brimstonecore", 15)
    es:add("direhound", 5)
end)

-- Full legion (everything at once)
encounters.defineEnemyEncounter(4, function(es,ecs)
    es:add("speardemon", 25)
    es:add("greatbowdemon", 5)
    es:add("charredsoul", 10)
    es:add("hellhound", 18)
end)
