
local objects = require("src.modules.objects.objects")

---@class g.Squad: objects.Class
---@field squadId string
---@field level integer
---@field perks string[]
---@field unitCount integer?
local Squad = objects.Class("g:Squad")


---@param squadId string
function Squad:init(squadId)
    self.squadId = squadId
    self.level = 1
    self.perks = {}
    self.unitCount = nil -- nil means "use default from SquadInfo"
end


---@return table
function Squad:serialize()
    return {
        squadId = self.squadId,
        level = self.level,
        perks = self.perks,
        unitCount = self.unitCount,
    }
end


---@return integer
function Squad:getUnitCount()
    if self.unitCount then
        return self.unitCount
    end
    local info = g.getSquadInfo(self.squadId)
    return info.count or 1
end


function Squad:drawPreview()
    -- draws a preview of the units
    -- DONT IMPLEMENT YET.
end

function Squad:drawUI()
    -- draws UI for squad (description)
    -- DONT IMPLEMENT YET.
end



---@param data table
---@return g.Squad
function Squad.deserialize(data)
    local sq = Squad(data.squadId)
    sq.level = data.level or 1
    sq.perks = data.perks or {}
    sq.unitCount = data.unitCount
    return sq
end

return Squad
