local Class = require("src.modules.objects.Class")

---@class g.DecorBuilder: objects.Class
local DecorBuilder = Class("g:DecorBuilder")

local function hash(x, y)
    return math.abs(math.sin(x * 12.9898 + y * 78.233) * 43758.5453)
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
function DecorBuilder:addImage(image, x, y, r, sx, opacity)
    self.items[#self.items + 1] = {
        kind = "image",
        image = image, x = x, y = y,
        r = r or 0, sx = sx, opacity = opacity or 1,
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
    table.sort(self.items, function(a, b)
        return ((a.drawOrder or 0) + a.y) < ((b.drawOrder or 0) + b.y)
    end)
    for _, it in ipairs(self.items) do
        if it.kind == "image" then
            local sx = it.sx
            if sx == nil then
                sx = (math.floor(hash(it.x, it.y)) % 2 == 0) and -1 or 1
            end
            love.graphics.setColor(1, 1, 1, it.opacity)
            g.drawImageOffset(it.image, it.x, it.y, it.r, sx, 1, 0.5, 0.95)
        else
            it.func(it.x, it.y)
        end
    end
end

return DecorBuilder
