local Picker = require("src.modules.Picker")
local cardJuiceService = require("src.cardJuiceService")

local ChoicePanelCommon = require(".common")

---@class g.BlessingChoicePanel: g.ChoicePanelCommon
local BlessingChoicePanel = objects.Class("g:BlessingChoicePanel"):implement(ChoicePanelCommon)


---@param rarityWeights g.RarityWeights
---@return picker.Picker<string>
local function buildPicker(rarityWeights)
    local pool = g.getBlessingsByMana(g.getRun().mana)
    local weights = {}
    for i, id in ipairs(pool) do
        local info = g.getBlessingInfo(id)
        weights[i] = rarityWeights[info.rarity.id] or 0
    end

    return Picker(pool, weights)
end


---@param rarityWeights g.RarityWeights?
function BlessingChoicePanel:init(rarityWeights)
    ---@type string[]
    self.choices = {}
    ---@type number[]
    self.choiceCreatedAt = {}
    self.createdAt = love.timer.getTime()
    ---@type integer|nil
    self.selected = nil
    self.cj = cardJuiceService.CardJuiceInstance()

    -- Roll directly
    local picker = buildPicker(rarityWeights or consts.DEFAULT_RARITY_WEIGHTS)

    for _ = 1, ChoicePanelCommon.NUM_CHOICES do
        self.choices[#self.choices+1] = picker:pickAndRemove(nil, 20)
        self.choiceCreatedAt[#self.choiceCreatedAt+1] = self.createdAt
    end
end

if false then
    ---@param rarityWeights g.RarityWeights?
    ---@return g.BlessingChoicePanel
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function BlessingChoicePanel(rarityWeights) end
end


function BlessingChoicePanel:draw()
    local r = ui.getFullScreenRegion()

    if #self.choices == 0 then
        -- RIP in Pepperoni but safety handler must be done
        return true
    end

    iml.panel(r:get())

    if self.cj:hasAnimationBegun() then
        self.cj:draw()

        if self.cj:isAnimationFinished() then
            -- Actually apply
            local blessId = self.choices[self.selected]
            g.addBlessing(blessId)
            return true
        end

        return false
    end

    local cardArea = r:padRatio(0.05, 0.1)
    local regions = cardArea:grid(ChoicePanelCommon.NUM_CHOICES, 1)
    local cx = cardArea.x + cardArea.w / 2
    local cy = cardArea.y + cardArea.h / 2

    local ox = regions[1].w * (ChoicePanelCommon.NUM_CHOICES - #self.choices) / 2
    for i = 1, #self.choices do
        local elapsed = love.timer.getTime() - (self.choiceCreatedAt[i] or self.createdAt)
        local t = math.min(1, math.max(0, elapsed / ChoicePanelCommon.FAN_OUT_DURATION))
        t = t * t * (3 - 2 * t)
        local scale = 0.5 + 0.5 * t
        local rr = regions[i]
        rr = rr:padRatio(0.15):shrinkToAspectRatio(3, 2)

        local targetCx = rr.x + rr.w / 2
        local targetCy = rr.y + rr.h / 2
        local animCx = cx + (targetCx - cx) * t
        local animCy = cy + (targetCy - cy) * t
        local dx = animCx - targetCx
        local dy = animCy - targetCy
        rr = rr:padRatio(1 - scale)
        regions[i] = rr:moveUnit(dx + ox, dy)
    end

    for i, blessId in ipairs(self.choices) do
        local clicked = ui.drawBlessingCard(blessId, regions[i], i)
        if clicked then
            -- Delayed select
            self.selected = i

            -- Spawn cards
            for j, otherBlessId in ipairs(self.choices) do
                if i ~= j then
                    self.cj:spawnCardUnselected(regions[j], j, function(r)
                        return ui.drawBlessingCard(otherBlessId, r, j)
                    end)
                end
            end
            self.cj:spawnCardSelected(regions[i], i, function(r)
                return ui.drawBlessingCard(blessId, r, i)
            end)
        end
    end

    return false
end

return BlessingChoicePanel
