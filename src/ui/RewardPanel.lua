local newPicker = require("src.modules.Picker")

---@class g.RewardPanel: objects.Class
local RewardPanel = objects.Class("g:RewardPanel")

local NUM_CHOICES = 3

---@param rType "squad"|"blessing"|"mana"
---@param rarityMapping g.RarityMapping?
function RewardPanel:init(rType, rarityMapping)
    self.rType = rType
    self.choices = {}
    self.rarityMapping = rarityMapping or consts.DEFAULT_RARITY_MAPPING

    local manaCells = g.getRun().mana

    if rType == "squad" then
        local pool = g.getSquadsByMana(manaCells)
        self:_pickFromPool(pool, function(id) return g.getSquadInfo(id) end)
    elseif rType == "blessing" then
        local pool = g.getBlessingsByMana(manaCells)
        self:_pickFromPool(pool, function(id) return g.getBlessingInfo(id) end)
    end
end

---@private
function RewardPanel:_pickFromPool(pool, getInfo)
    if #pool == 0 then return end
    local weights = {}
    for i, id in ipairs(pool) do
        local info = getInfo(id)
        weights[i] = self.rarityMapping[info.rarity.id] or 0
    end
    local picker = newPicker(pool, weights)
    local seen = {}
    for _ = 1, NUM_CHOICES do
        local pick = picker:pick()
        -- avoid duplicates; try a few times
        for _ = 1, 20 do
            if not seen[pick] then break end
            pick = picker:pick()
        end
        seen[pick] = true
        self.choices[#self.choices + 1] = pick
    end
end


function RewardPanel:draw()
    local r = ui.getFullScreenRegion()
    local cardArea = r:padRatio(0.05, 0.1)
    local regions = cardArea:grid(#self.choices, 1)
    for i,rr in ipairs(regions) do
        regions[i] = rr:padRatio(0.15)
    end

    if self.rType == "squad" then
        for i = 1, #regions do
            local rew = self.choices[i]
            if rew and ui.drawSquadCard(rew, regions[i]) then
                return true
            end
        end
    elseif self.rType == "blessing" then
        for i = 1, #regions do
            local rew = self.choices[i]
            if rew and ui.drawBlessingCard(rew, regions[i]) then
                return true
            end
        end
    end
end




return RewardPanel

