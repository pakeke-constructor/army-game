
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

    local TPAD = 30
    local function drawPatch(x, y, count, variance)
        for i = 1, count do
            local image
            local color
            local var = variance
            local roll = love.math.random()
            if roll < 0.45 then
                image = "decor_big_" .. love.math.random(1, 4)
                color = darkcol
                var = var * 0.65
            elseif roll < 0.75 then
                image = "decor_splotch_" .. love.math.random(1, 5)
                color = darkcol
            else
                image = "decor_tex_" .. love.math.random(1, 5)
                color = lightcol
            end

            local px = math.floor(x + love.math.random(-var,var))
            local py = math.floor(y + love.math.random(-var,var))
            px = math.min(w - TPAD, math.max(TPAD, px))
            py = math.min(h - TPAD, math.max(TPAD, py))

            table.insert(decorations, {
                x = px,
                y = py,
                image = image,
                color = color
            })
        end
    end

    local noiseFreq = 0.01

    local function noise(xx,yy)
        return love.math.perlinNoise(xx*noiseFreq, yy*noiseFreq)
    end

    local patchCount = love.math.random(50,70)
    for i = 1, patchCount do
        local x = math.floor(helper.lerp(TPAD, w - TPAD, love.math.random()))
        local y = math.floor(helper.lerp(TPAD, h - TPAD, love.math.random()))
        local count = love.math.random(16, 22)
        local variance = love.math.random(38, 52)
        if noise(x, y) < 0.5 then
            drawPatch(x, y, count, variance)
        end
    end

    local grassCount = 1000
    for i = 1, grassCount do
        local x = math.floor(helper.lerp(TPAD, w - TPAD, love.math.random()))
        local y = math.floor(helper.lerp(TPAD, h - TPAD, love.math.random()))
        if noise(x, y) > 0.5 then
            local ent = g.spawnEntity("grass_decor_"..tostring(love.math.random(1,4)), x, y)
            ent.color = GRASS_COLOR
        end
    end

    for _, entry in ipairs(decorations) do
        local ent = g.spawnEntity(entry.image, entry.x, entry.y)
        ent.color = entry.color
    end
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
