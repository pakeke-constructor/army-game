
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
    local decorations = {}

    local w, h = world.border[3], world.border[4]

    local darkcol = objects.Color("FF312B2B")
    local lightcol = objects.Color("FF3C3434")

    local noiseFreq = 0.01

    local function noise(xx,yy)
        return love.math.perlinNoise(xx*noiseFreq, yy*noiseFreq)
    end

    local TPAD = 30
    local function spawnRandomPatch(x, y)
        local id
        local color
        local roll = love.math.random()
        local dLight = 0
        if roll < 0.45 then
            id = "decor_big_" .. love.math.random(1, 4)
            dLight = 0.1
        elseif roll < 0.75 then
            id = "decor_splotch_" .. love.math.random(1, 5)
        else
            id = "decor_tex_" .. love.math.random(1, 5)
            dLight = -0.05
        end

        local ent = g.spawnEntity(id, x,y)
        local n = noise(x,y)
        ent.color = objects.Color.clone(objects.Color.BLACK)
        ent.color:lighten(n + dLight)
        ent.color.a = 0.1
    end

    local patchCount = 100
    for i = 1, patchCount do
        local x = math.floor(helper.lerp(TPAD, w - TPAD, love.math.random()))
        local y = math.floor(helper.lerp(TPAD, h - TPAD, love.math.random()))
        if world:isInsideShape(x, y) then
            spawnRandomPatch(x,y)
        end
    end

    -- local grassCount = 1000
    -- for i = 1, grassCount do
    --     local x = math.floor(helper.lerp(TPAD, w - TPAD, love.math.random()))
    --     local y = math.floor(helper.lerp(TPAD, h - TPAD, love.math.random()))
    --     if noise(x, y) > 0.5 then
    --         local ent = g.spawnEntity("grass_decor_"..tostring(love.math.random(1,4)), x, y)
    --         ent.color = GRASS_COLOR
    --     end
    -- end

    -- for _, entry in ipairs(decorations) do
    --     local ent = g.spawnEntity(entry.image, entry.x, entry.y)
    --     ent.color = entry.color
    -- end
end

function ground_decor.preUpdate()
    local world = g.getECS()
    if world.data.groundDecorSpawned then
        return
    end
    if not world.border then
        return
    end
    spawnDecor(world)
    world.data.groundDecorSpawned = true
end

return ground_decor
