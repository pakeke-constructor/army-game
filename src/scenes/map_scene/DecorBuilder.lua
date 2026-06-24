local Class = require("src.modules.objects.Class")

---@class g.DecorBuilder: objects.Class
local DecorBuilder = Class("g:DecorBuilder")

local function hash(x, y)
    return math.floor(math.sin(x * 12.9898 + y * 78.233) * 43758.5453 + 0.5)
end

function DecorBuilder:init()
    self.items = {}
end

---@param image string|love.Quad
---@param x number
---@param y number
---@param r number?
---@param sx number? if nil, hashed from (x,y) to -1 or 1
---@param opacity number?
---@param transformMod? fun(id:integer):(number,number,number,number,number,number,number) function that returns 7 numbers: offX, offY, rot, scaleX, scaleY, shearX, shearY
function DecorBuilder:addImage(image, x, y, r, sx, opacity, transformMod)
    self.items[#self.items + 1] = {
        kind = "image",
        image = image, x = x, y = y,
        r = r or 0, sx = sx, opacity = opacity or 1,
        transformMod = transformMod,
    }
end

---@param x number
---@param y number
---@param func fun(x:number, y:number)
---@param drawOrder number?
function DecorBuilder:addDrawable(x, y, func, drawOrder)
    self.items[#self.items + 1] = {
        kind = "drawable",
        x = x, y = y, func = func, drawOrder = drawOrder,
    }
end

function DecorBuilder:finalize()
    for i, it in ipairs(self.items) do
        it._order = i
    end
    table.sort(self.items, function(a, b)
        local ka = (a.drawOrder or 0) + a.y
        local kb = (b.drawOrder or 0) + b.y
        if ka == kb then
            return a._order < b._order
        end
        return ka < kb
    end)
    for _, it in ipairs(self.items) do
        local col = gsman.setColor(1, 1, 1, it.opacity)

        if it.kind == "image" then
            local sx = it.sx
            local id = hash(it.x, it.y)
            if sx == nil then
                sx = (math.floor(id) % 2 == 0) and -1 or 1
            end

            local offx, offy, rot, scx, scy, kx, ky = 0, 0, 0, 1, 1, 0, 0
            if it.transformMod then
                offx, offy, rot, scx, scy, kx, ky = it.transformMod(id)
            end

            g.drawImageOffset(
                it.image,
                it.x + offx, it.y + offy,
                it.r + rot,
                sx * scx, scy,
                0.5, 0.95,
                kx, ky
            )
        else
            it.func(it.x, it.y)
        end

        col:pop()
    end
end

return DecorBuilder
