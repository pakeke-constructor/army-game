local newPicker = require("src.modules.Picker")



---@class g.ChoicePanel: objects.Class
local ChoicePanel = objects.Class("g:ChoicePanel")


local NUM_CHOICES = 3


---@param rType "squad"|"blessing"|"mana"
---@param rarityWeights g.RarityWeights?
function ChoicePanel:init(rType, rarityWeights)
    self.rType = rType
    self.choices = {}
    self.rarityWeights = rarityWeights or consts.DEFAULT_RARITY_WEIGHTS
    self.selectedI = nil

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
function ChoicePanel:_pickFromPool(pool, getInfo)
    if #pool == 0 then return end
    local weights = {}
    for i, id in ipairs(pool) do
        local info = getInfo(id)
        weights[i] = self.rarityWeights[info.rarity.id] or 0
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



function ChoicePanel:draw()
    local r = ui.getFullScreenRegion()
    local cardArea = r:padRatio(0.05, 0.1)
    local regions = cardArea:grid(#self.choices, 1)
    for i,rr in ipairs(regions) do
        regions[i] = rr:padRatio(0.15)
    end

    ---@param i integer
    local function drawCard(i)
        local rew = self.choices[i]
        local f = self.rType == "squad" and ui.drawSquadCard or ui.drawBlessingCard
        local clicked, ww,hh = f(rew, regions[i], i)
        
        if clicked then
            self.selectedI = i
            return true
        end
    end

    for i = 1, #regions do
        if drawCard(i) then return true end
    end
end




return ChoicePanel

