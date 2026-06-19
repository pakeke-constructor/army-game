local shadowSys = {}

local function getShadowRadius(ent)
    local shadow = ent.shadow
    if shadow.radius then
        return shadow.radius
    end
    if ent.image then
        local w = g.getImageSize(ent.image)
        return w * 0.4
    end
    return 3
end

local function getShadowY(ent)
    if ent.image and g.hasTrait(ent, "flying") then
        local _, h = g.getImageSize(ent.image)
        return ent.y + h * 0.2
    end
    return ent.y
end

function shadowSys.preDraw()
    local world = g.getECS()
    for _, ent in world:iterate("shadow") do
        local shadow = ent.shadow
        local alpha = shadow.opacity or 0.4
        lg.setColor(0, 0, 0, alpha)
        lg.circle("fill", ent.x, getShadowY(ent), getShadowRadius(ent))
    end
end

return shadowSys
