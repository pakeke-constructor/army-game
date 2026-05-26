

local encounters = require("src.scenes.battle_scene.encounters")


local function spawnGrass(ecs, spacing)
    spacing = spacing or 40
    local b = ecs.border
    local x0, y0, x1, y1 = b[1], b[2], b[3], b[4]
    for x = x0, x1, spacing do
        for y = y0, y1, spacing do
            if love.math.random() < 0.7 then
                local ox = love.math.random() * spacing
                local oy = love.math.random() * spacing
                g.spawnEntity("grass", x + ox, y + oy)
            end
        end
    end
end


-- Simple front-to-back, archers + demon
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("archerdemon", 10)
    es:add("demon", 10)
    ecs:setBorder(800,400)
    spawnGrass(ecs)
end)

-- Melee only
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("demon", 25)
    ecs:setBorder(800,400)
    spawnGrass(ecs)
end)

-- Ranged only
encounters.defineEnemyEncounter(1, function(es,ecs)
    es:add("archerdemon", 15)
    es:add("demon", 2)
    ecs:setBorder(800,400)
    spawnGrass(ecs)
end)








-- Front to back
encounters.defineEnemyEncounter(2, function(es,ecs)
    es:add("archerdemon", 15)
    es:add("demon", 20)
    ecs:setBorder(1000,700)
    spawnGrass(ecs)
end)








-- MELEE PIT
encounters.defineEnemyEncounter(3, function(es,ecs)
    es:add("demon", 55)
    ecs:setBorder(500,500)
    spawnGrass(ecs)
end)







-- FUCKING HUGE ARMY
encounters.defineEnemyEncounter(4, function(es,ecs)
    es:add("archerdemon", 25)
    es:add("demon", 50)
    spawnGrass(ecs)
end)


