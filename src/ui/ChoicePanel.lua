local newPicker = require("src.modules.Picker")



---@class g.ChoicePanel: objects.Class
local ChoicePanel = objects.Class("g:ChoicePanel")


local NUM_CHOICES = 3
local FAN_OUT_DURATION = 0.2


---@param rType "squad"|"blessing"|"mana"
---@param rarityWeights g.RarityWeights?
function ChoicePanel:init(rType, rarityWeights)
    self.rType = rType
    self.choices = {}
    self.rarityWeights = rarityWeights or consts.DEFAULT_RARITY_WEIGHTS
    self.createdAt = love.timer.getTime()

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
    local elapsed = love.timer.getTime() - self.createdAt
    local t = math.min(1, math.max(0, elapsed / FAN_OUT_DURATION))
    t = t * t * (3 - 2 * t)
    local cx = cardArea.x + cardArea.w / 2

    for i,rr in ipairs(regions) do
        rr = rr:padRatio(0.15)
        local targetCx = rr.x + rr.w / 2
        local animCx = cx + (targetCx - cx) * t
        regions[i] = rr:set(animCx - rr.w / 2, nil, nil, nil)
    end

    if self.rType == "squad" then
        for i = 1, #regions do
            local squadId = self.choices[i]
            local clicked = ui.drawSquadCard(squadId, regions[i], i)
            if clicked then
                g.addOrUpgradeSquad(squadId)
                return true
            end
        end
        return
    end

    if self.rType == "blessing" then
        for i = 1, #regions do
            local blessId = self.choices[i]
            local clicked = ui.drawBlessingCard(blessId, regions[i], i)
            if clicked then
                g.addOrUpgradeSquad(blessId)
                return true
            end
        end
    end
end




return ChoicePanel

