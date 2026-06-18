
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

    local function spawnBunch(cx, cy)
        local count = love.math.random(8, 16)
        for i = 1, count do
            local bestX, bestY
            local bestScore = math.huge
            for _ = 1, 3 do
                local a = love.math.random() * math.pi * 2
                local r = love.math.random() * love.math.random() * 110
                local x = cx + math.cos(a) * r
                local y = cy + math.sin(a) * r
                local score = world:getNumOverlappingShapes(x, y)
                if score < bestScore then
                    bestScore = score
                    bestX = x
                    bestY = y
                end
            end

            if world:isInsideShape(bestX, bestY) then
                local id = (love.math.random() < 0.28) and "rock" or "grass"
                g.spawnEntity(id, bestX, bestY)
            end
        end
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

    local BUNCH_GRID = 220
    local BUNCH_SPAWN_CHANCE = 0.42
    for gx = BUNCH_GRID / 2, w, BUNCH_GRID do
        for gy = BUNCH_GRID / 2, h, BUNCH_GRID do
            if love.math.random() < BUNCH_SPAWN_CHANCE then
                local x = gx + love.math.random(-BUNCH_GRID / 3, BUNCH_GRID / 3)
                local y = gy + love.math.random(-BUNCH_GRID / 3, BUNCH_GRID / 3)
                if world:isInsideShape(x, y) then
                    spawnBunch(x, y)
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
