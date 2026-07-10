
local fog_decor = {}

local biomeDecoDef = {}

local function def(id, imageId, drawOrder)
    if not g.isImage(imageId) then
        error(imageId .. " is not an image")
    end
    g.defineEntity(id, {
        image = imageId,
        drawOrder = drawOrder,
        aboveFog = true,
    })
end

local function defineBiomeDeco(biomeId, t)
    biomeDecoDef[biomeId] = t
end


-- forest deco
-----

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


-- fall deco
-----

def("brownoak_large_decor_1", "brownoak_large_1", 0)
def("brownoak_small_decor_1", "brownoak_small_1", 0)

def("brownpine_large_decor_1", "brownpine_large_1", 0)
def("brownpine_small_decor_1", "brownpine_small_1", 0)


defineBiomeDeco("fall", {
    {grid=40, spawnChance = 0.15, ent={"brownoak_small_decor_1", "brownoak_large_decor_1"}},
    {grid=35, spawnChance = 0.4, ent={"brownpine_small_decor_1", "brownpine_large_decor_1"}},
    {grid=45, spawnChance = 0.35, ent={"mountain_decor_1", "mountain_decor_2"}},
    {grid=85, spawnChance = 0.15, ent={"mountainLarge_decor_1"}},
})


-- hell deco
-----

for i=1, 4 do
    def("hellTree_decor_" .. i, "burnedtree_" .. i, 0)
end

def("hellMountain_decor_1", "hell_mountain_small_1", 0)
def("hellMountain_decor_2", "hell_mountain_small_2", 0)

def("hellMountainLarge_decor_1", "hell_mountain_large_1", 0)

def("hellCrystal_decor_1", "redcrystal_large_1", 0)
def("hellCrystal_decor_2", "redcrystal_large_2", 0)
def("hellCrystal_decor_3", "redcrystal_medium_1", 0)
def("hellCrystal_decor_4", "redcrystal_small_1", 0)

def("hellDemonTree_decor_1", "demontree_1", 0)

defineBiomeDeco("hell", {
    {grid=40, spawnChance = 0.35, ent={"hellTree_decor_1", "hellTree_decor_2", "hellTree_decor_3", "hellTree_decor_4"}},
    {grid=45, spawnChance = 0.35, ent={"hellMountain_decor_1", "hellMountain_decor_2"}},
    {grid=75, spawnChance = 0.25, ent={"hellMountainLarge_decor_1", "hellDemonTree_decor_1"}},
    {grid=55, spawnChance = 0.3, ent={"hellCrystal_decor_1", "hellCrystal_decor_2", "hellCrystal_decor_3", "hellCrystal_decor_4"}},
})

---@param world ecs.ECSWorld
local function spawnFogDecorations(world)
    local decorations = {}
    local w, h = world.boundingBox[3], world.boundingBox[4]

    local map = g.getMapType()
    local zoneId = map.name or "forest"

    local function spawnRandomPatch(x, y, entId)
        decorations[#decorations + 1] = g.spawnEntity(entId, x, y)
    end

    local zone = biomeDecoDef[zoneId] -- forest is placeholder, later change it to the current zone
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

    table.sort(decorations, function (a, b)
        return a.y < b.y
    end)
    return decorations
end

function fog_decor.drawAboveFog()
    local world = g.getECS()
    if not world.boundingBox then
        return
    end

    world.data.fogEdgeDecorations = world.data.fogEdgeDecorations or spawnFogDecorations(world)

    love.graphics.setColor(1,1,1)
    for i = 1, #world.data.fogEdgeDecorations do
        local ent = world.data.fogEdgeDecorations[i]
        g.drawEntity(ent, ent.x, ent.y)
    end
end

return fog_decor