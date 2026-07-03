
local fog_decor = {}

local biomeDecoDef = {}

local function def(id, imageId, drawOrder)
    if g.isImage(imageId) then
        g.defineEntity(id, {
            image = imageId,
            drawOrder = drawOrder,
            aboveFog = true,
        })
    end
end

local function defineBiomeDeco(biomeId, t)
    biomeDecoDef[biomeId] = t
end

local spawnedEnts = {}

def("tree_decor_1", "tree_small_1", 0)
def("tree_decor_2", "tree_large_1", 0)

def("mountain_decor_1", "mountain_small_1", 0)
def("mountain_decor_2", "mountain_small_2", 0)

def("mountainLarge_decor_1", "mountain_large_1", 0)

defineBiomeDeco("forest", {
    {grid=35, spawnChance = 0.5, ent={"tree_decor_1", "tree_decor_2"}},
    {grid=45, spawnChance = 0.35, ent={"mountain_decor_1", "mountain_decor_2"}},
    {grid=85, spawnChance = 0.15, ent={"mountainLarge_decor_1"}},
})

---@param world ecs.ECSWorld
local function spawnDecor(world)
    local w, h = world.boundingBox[3], world.boundingBox[4]

    local function spawnRandomPatch(x, y, entId)
        local ent = g.spawnEntity(entId, x, y)
        spawnedEnts[#spawnedEnts + 1] = ent
    end

    local zone = biomeDecoDef["forest"] -- forest is placeholder, later change it to the current zone
    for k, decoGroup in pairs(zone) do
        local GRID = decoGroup.grid
        local SPAWN_CHANCE = decoGroup.spawnChance
        for gx = GRID / 2, w, GRID do
            for gy = GRID / 2, h, GRID do
                if love.math.random() < SPAWN_CHANCE then
                    local x = gx + love.math.random(-GRID / 2, GRID / 2)
                    local y = gy + love.math.random(-GRID / 2, GRID / 2)
                    if not world:isInsideShapeRounded(x, y, 120) then
                        local randomEnt = decoGroup.ent[love.math.random(1, #decoGroup.ent)]
                        spawnRandomPatch(x, y, randomEnt)
                    end
                end
            end
        end
    end

    table.sort(spawnedEnts, function (a, b)
        return a.y < b.y
    end)
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