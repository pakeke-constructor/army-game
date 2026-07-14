local Picker = require("src.modules.Picker")

local ChoicePanelCommon = require(".common")
local cardJuiceService = require("src.cardJuiceService")

---@class g.SquadChoicePanel: g.ChoicePanelCommon
local SquadChoicePanel = objects.Class("g:SquadChoicePanel"):implement(ChoicePanelCommon)

---@param rerolls integer?
---@param rarityWeights g.RarityWeights?
function SquadChoicePanel:init(rerolls, rarityWeights)
    ---@type integer[]
    self.rerolls = {}
    ---@type string[]
    self.choices = {}
    ---@type number[]
    self.choiceCreatedAt = {}
    self.rarityWeights = rarityWeights or consts.DEFAULT_RARITY_WEIGHTS
    self.createdAt = love.timer.getTime()
    ---@type integer|nil
    self.selected = nil
    self.cj = cardJuiceService.CardJuiceInstance()
    self.showReroll = (rerolls or 0) > 0

    for _ = 1, ChoicePanelCommon.NUM_CHOICES do
        self.rerolls[#self.rerolls+1] = rerolls or 0
        self.choiceCreatedAt[#self.choiceCreatedAt+1] = self.createdAt
    end

    self:_rollChoices()
end

if false then
    ---@param rerolls integer?
    ---@param rarityWeights g.RarityWeights?
    ---@return g.SquadChoicePanel
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function SquadChoicePanel(rerolls, rarityWeights) end
end

---@private
function SquadChoicePanel:_rollChoices()
    self.choices = {}

    local manaCells = g.getRun().mana

    local pool = g.getSquadsByMana(manaCells)
    self:_pickFromPool(pool)
end

---@param pool string[]
---@param out string[]?
---@param count integer?
---@private
function SquadChoicePanel:_pickFromPool(pool, out, count)
    if #pool == 0 then return end
    out = out or self.choices
    count = count or ChoicePanelCommon.NUM_CHOICES

    local weights = {}
    for i, id in ipairs(pool) do
        local info = g.getSquadInfo(id)
        weights[i] = self.rarityWeights[info.rarity.id] or 0
    end

    local picker = Picker(pool, weights)
    for _ = 1, count do
        local pick = picker:pickAndRemove(nil, 20)
        out[#out + 1] = pick
    end
end

---@param pool string[]
---@param seen table<string, true?>
---@private
function SquadChoicePanel:_pickOneFromPool(pool, seen)
    if #pool == 0 then return end

    local weights = {}
    for i, id in ipairs(pool) do
        local info = g.getSquadInfo(id)
        weights[i] = self.rarityWeights[info.rarity.id] or 0
    end

    local picker = Picker(pool, weights)
    local pick = picker:pickAndRemove(nil, 20)
    return pick
end

---@param index integer
---@private
function SquadChoicePanel:_rerollChoice(index)
    if (self.rerolls[index] or 0) <= 0 then return end

    local seen = {}
    for _, id in ipairs(self.choices) do
        seen[id] = true
    end

    local pick = self:_pickOneFromPool(g.getSquadsByMana(g.getRun().mana), seen)
    self.rerolls[index] = self.rerolls[index] - 1
    self.choices[index] = pick
    self.choiceCreatedAt[index] = love.timer.getTime()
end


local REROLL_GLOW_COL = objects.Color("#4d8c21")
local REROLL_GLOW_HOVER_COL = objects.Color("#7cc82a")

---@param region kirigami.Region
---@param index integer
---@param disabled boolean
local function drawRerollButton(region, index, disabled)
    local rerollR = Kirigami(0, 0, g.getImageSize("reroll_button_body"))
        :center(region)
    local uid = "choice_reroll_"..index
    local x, y, w, h = rerollR:get()
    local isHovered = not disabled and iml.isHovered(x, y, w, h, uid)

    if not disabled then
        helper.rotatingGlow(rerollR:padRatio(0.2), {
            count = 6,
            offset = index * 50,
            glowScale = 30,
            rps = 0.8,
            color = g.snapToPalette(isHovered and REROLL_GLOW_HOVER_COL or REROLL_GLOW_COL)
        })
    end

    local bodyImage = "reroll_button_body"
    if disabled then
        bodyImage = "reroll_button_body_gray"
    elseif isHovered then
        bodyImage = "reroll_button_body_hover"
    end

    lg.setColor(1, 1, 1)
    g.drawImageContained(bodyImage, rerollR:get())

    local iconImage = disabled and "shop_reroll_icon_gray" or "shop_reroll_icon"
    g.drawImage(iconImage, x + w / 2, y + h / 2)

    return iml.wasJustClicked(x, y, w, h, 1, uid)
end

function SquadChoicePanel:draw()
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
            local squadId = self.choices[self.selected]
            local hadSquad = g.getSquadFromArmy(squadId)
            g.addOrUpgradeSquad(squadId)
            if hadSquad then
                choicePopupService.set({type = "upgrade_stat", squadId = squadId})
            end
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
        rr = rr:padRatio(0.15)

        local targetCx = rr.x + rr.w / 2
        local targetCy = rr.y + rr.h / 2
        local animCx = cx + (targetCx - cx) * t
        local animCy = cy + (targetCy - cy) * t
        local dx = animCx - targetCx
        local dy = animCy - targetCy
        rr = rr:padRatio(1 - scale)
        regions[i] = rr:moveUnit(dx + ox, dy)
    end

    for i, squadId in ipairs(self.choices) do
        local cardR, _, rerollR = regions[i]:splitVertical(8, 1, 1)
        local function draw(r)
            return ui.drawSquadCard(squadId, r, i, true, true)
        end

        local clicked = draw(cardR)
        local rerollClicked = false
        if self.showReroll then
            rerollClicked = drawRerollButton(rerollR, i, (self.rerolls[i] or 0) <= 0)
        end

        if rerollClicked then
            self:_rerollChoice(i)
        elseif clicked then
            -- Delayed select
            self.selected = i

            -- Spawn cards
            for j, sqId in ipairs(self.choices) do
                if i ~= j then
                    local otherCardR = regions[j]:splitVertical(8, 1, 1)
                    self.cj:spawnCardUnselected(otherCardR, j, function(r)
                        return ui.drawSquadCard(sqId, r, j, true, true)
                    end)
                end
            end

            local targetR = nil
            if g.getSquadFromArmy(squadId) then
                -- This duplicates stat choice layouting
                local baseR = ui.getFullScreenRegion()
                local _, cardAreaBaseR = baseR:padRatio(0.05, 0.1):splitVertical(1, 5)
                local _, squadCardR = cardAreaBaseR:splitHorizontal(5, 2)
                targetR = squadCardR
            end
            self.cj:spawnCardSelected(cardR, i, function(r)
                return ui.drawSquadCard(squadId, r, i, true, true)
            end, targetR)
        end
    end

    return false
end

return SquadChoicePanel
