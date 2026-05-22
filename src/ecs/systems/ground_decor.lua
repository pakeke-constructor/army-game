
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

for i = 1, 5 do
    def("decor_big_", i, -40)
    def("decor_splotch_", i, -39)
    def("decor_tex_", i, -38)
end


---@param world ecs.ECSWorld
local function spawnDecor(world)
    local SIZE_MULT = 1
    local decorations = {}

    local w, h = world.border[3], world.border[4]

    local darkcol = objects.Color("FF342D2D")
    local lightcol = objects.Color("FF5A5252")

    local BIGPAD = 30
    for i = 1, 40 * SIZE_MULT do
        table.insert(decorations, {
            x = math.floor(helper.lerp(BIGPAD, w - BIGPAD, love.math.random())),
            y = math.floor(helper.lerp(BIGPAD, h - BIGPAD, love.math.random())),
            image = "decor_big_" .. love.math.random(1, 4),
            color = darkcol
        })
    end

    local PAD = 12
    for i = 1, 60 * SIZE_MULT do
        table.insert(decorations, {
            x = math.floor(helper.lerp(PAD, w - PAD * 2, love.math.random())),
            y = math.floor(helper.lerp(PAD, h - PAD * 2, love.math.random())),
            image = "decor_splotch_" .. love.math.random(1, 5),
            color = darkcol
        })
    end

    local TPAD = 30
    for i = 1, 30 * SIZE_MULT do
        table.insert(decorations, {
            x = math.floor(helper.lerp(TPAD, w - TPAD * 2, love.math.random())),
            y = math.floor(helper.lerp(TPAD, h - TPAD * 2, love.math.random())),
            image = "decor_tex_" .. love.math.random(1, 5),
            color = lightcol
        })
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
