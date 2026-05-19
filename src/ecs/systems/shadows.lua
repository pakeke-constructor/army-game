local shadowSys = {}

local function getShadowRadius(ent)
    local shadow = ent.shadow
    if shadow.radius then
        return shadow.radius
    end
    if ent.image then
        local w = g.getImageSize(ent.image)
        return w * 0.5
    end
    return 3
end

function shadowSys.preDraw()
    local world = g.getECS()
    for _, ent in world:iterate("shadow") do
        local shadow = ent.shadow
        local alpha = shadow.opacity or 0.6
        lg.setColor(0, 0, 0, alpha)
        lg.circle("fill", ent.x, ent.y, getShadowRadius(ent))
    end
end

return shadowSys
