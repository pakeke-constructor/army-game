
local fog_decor = {}

local function def(id, imageId, drawOrder)
    local idd = id
    if g.isImage(imageId) then
        g.defineEntity(id, {
            image = imageId,
            drawOrder = drawOrder,
            aboveFog = true,
        })
    end
end

local spawnedEnts = {}

-- local GRASS_COLOR = g.snapToPalette(objects.Color("FF2E442A"))


-- for i = 1, 5 do
--     def("decor_mega_", i, -250)
--     def("decor_big_", i, -200)
--     def("decor_splotch_", i, -120)
--     def("decor_tex_", i, -40)

--     def("grass_decor_", i, 0)
-- end

def("tree_decor_1", "tree_small_1", 0)

---@param world ecs.ECSWorld
local function spawnDecor(world)
    local w, h = world.boundingBox[3], world.boundingBox[4]

    local function spawnRandomPatch(x, y)
        local ent = g.spawnEntity("tree_decor_1", x, y)
        spawnedEnts[#spawnedEnts + 1] = ent
    end

    -- local function spawnBunch(cx, cy)
    --     local count = love.math.random(6, 10)
    --     for i = 1, count do
    --         local bestX, bestY
    --         local bestScore = math.huge
    --         for _ = 1, 3 do
    --             local a = love.math.random() * math.pi * 2
    --             local r = love.math.random() * love.math.random() * 110
    --             local x = cx + math.cos(a) * r
    --             local y = cy + math.sin(a) * r
    --             local score = world:getNumOverlappingShapes(x, y)
    --             if score < bestScore then
    --                 bestScore = score
    --                 bestX = x
    --                 bestY = y
    --             end
    --         end

    --         if world:isInsideShape(bestX, bestY) then
    --             local id = (love.math.random() < 0.28) and "rock" or "grass"
    --             g.spawnEntity(id, bestX, bestY)
    --         end
    --     end
    -- end

    local GRID = 30
    local SPAWN_CHANCE = 0.6
    for gx = GRID / 2, w, GRID do
        for gy = GRID / 2, h, GRID do
            if love.math.random() < SPAWN_CHANCE then
                local x = gx + love.math.random(-GRID / 2, GRID / 2)
                local y = gy + love.math.random(-GRID / 2, GRID / 2)
                if not world:isInsideShapeRounded(x, y, 140) then
                    spawnRandomPatch(x, y)
                end
            end
        end
    end

    -- local BUNCH_GRID = 220
    -- local BUNCH_SPAWN_CHANCE = 0.42
    -- for gx = BUNCH_GRID / 2, w, BUNCH_GRID do
    --     for gy = BUNCH_GRID / 2, h, BUNCH_GRID do
    --         if love.math.random() < BUNCH_SPAWN_CHANCE then
    --             local x = gx + love.math.random(-BUNCH_GRID / 3, BUNCH_GRID / 3)
    --             local y = gy + love.math.random(-BUNCH_GRID / 3, BUNCH_GRID / 3)
    --             if world:isInsideShape(x, y) then
    --                 spawnBunch(x, y)
    --             end
    --         end
    --     end
    -- end
end

function fog_decor.preUpdate()
    local world = g.getECS()
    if world.data.fogDecorSpawned then
        return
    end
    if not world.boundingBox then
        return
    end
    spawnDecor(world)
    world.data.fogDecorSpawned = true
end

function fog_decor.drawAboveFog()
    love.graphics.setColor(1,1,1)
    for i = 1, #spawnedEnts do
        local ent = spawnedEnts[i]
        g.drawEntity(ent, ent.x, ent.y)
    end
end

return fog_decor