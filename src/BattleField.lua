local objects = require("src.modules.objects.objects")

---@class g.BattleField: objects.Class
local BattleField = objects.Class("g:BattleField")

function BattleField:init()
    self.entities = objects.BufferedSet()
end

local function sortOrder(a, b)
    return (a.y + (a.drawOrder or 0)) < (b.y + (b.drawOrder or 0))
end

function BattleField:draw()
    local list = {}
    for _, e in ipairs(self.entities) do
        list[#list + 1] = e
    end
    table.sort(list, sortOrder)
    for _, e in ipairs(list) do
        g.drawEntity(e, e.x, e.y)
    end
end

return BattleField
