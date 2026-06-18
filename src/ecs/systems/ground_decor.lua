
local ground_decor = {}

local function def(id, i, drawOrder)
    local idd = id .. tostring(i)
    if g.isImage(idd) then
        g.defineEntity(idd, {
            image = idd,
            drawOrder = drawOrder
        })
    end
end

local GRASS_COLOR = g.snapToPalette(objects.Color("FF2E442A"))


for i = 1, 5 do
    def("decor_big_", i, -200)
    def("decor_splotch_", i, -120)
    def("decor_tex_", i, -40)

    def("grass_decor_", i, 0)
end


---@param world ecs.ECSWorld
local function spawnDecor(world)
    local w, h = world.boundingBox[3], world.boundingBox[4]

    local noiseFreq = 0.01
    local function noise(xx, yy)
        return love.math.perlinNoise(xx * noiseFreq, yy * noiseFreq)
    end

    local function spawnRandomPatch(x, y)
        local id
        local dLight = 0
        local roll = love.math.random()
        if roll < 0.45 then
            id = "decor_big_" .. love.math.random(1, 4)
            dLight = 0.1
        elseif roll < 0.75 then
            id = "decor_splotch_" .. love.math.random(1, 5)
        else
            id = "decor_tex_" .. love.math.random(1, 5)
            dLight = -0.05
        end

        local ent = g.spawnEntity(id, x, y)
        local n = noise(x, y)
        ent.color = objects.Color.clone(objects.Color.BLACK)
        ent.color:lighten(n + dLight)
        ent.color.a = 0.1
    end

    local GRID = 40
    local SPAWN_CHANCE = 0.5
    for gx = GRID / 2, w, GRID do
        for gy = GRID / 2, h, GRID do
            if love.math.random() < SPAWN_CHANCE then
                local x = gx + love.math.random(-GRID / 2, GRID / 2)
                local y = gy + love.math.random(-GRID / 2, GRID / 2)
                if world:isInsideShape(x, y) then
                    spawnRandomPatch(x, y)
                end
            end
        end
    end
end

function ground_decor.preUpdate()
    local world = g.getECS()
    if world.data.groundDecorSpawned then
        return
    end
    if not world.boundingBox then
        return
    end
    spawnDecor(world)
    world.data.groundDecorSpawned = true
end

return ground_decor
