local ChoicePanelCommon = require(".common")
local cardJuiceService = require("src.cardJuiceService")

local CHOOSE_SPELL_DISCARD = loc("Choose a Spell to Discard")
local REROLL_GAP = 8

---@class g.SpellDiscardChoicePanel: g.ChoicePanelCommon
local SpellDiscardChoicePanel = objects.Class("g:SpellDiscardChoicePanel"):implement(ChoicePanelCommon)

---@param spellId string?
function SpellDiscardChoicePanel:init(spellId)
    self.toBeAddedSpell = spellId
    ---@type string[]
    self.choices = g.getRun().spells:totable()
    table.sort(self.choices)

    if spellId then
        self.choices[#self.choices+1] = spellId
    end
    ---@type number[]
    self.choiceCreatedAt = {}
    self.createdAt = love.timer.getTime()
    ---@type integer|nil
    self.selected = nil
    self.cj = cardJuiceService.CardJuiceInstance()

    for _ = 1, ChoicePanelCommon.NUM_CHOICES do
        self.choiceCreatedAt[#self.choiceCreatedAt+1] = self.createdAt
    end
end

if false then
    ---@param spellId string
    ---@return g.SpellDiscardChoicePanel
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function SpellDiscardChoicePanel(spellId) end
end

---@param region kirigami.Region
---@return kirigami.Region cardR
---@return kirigami.Region rerollR
local function getCardRegions(region)
    local cardBaseR = region:splitVertical(9, 1)
    local cardR = cardBaseR:splitVertical(3, 2):center(cardBaseR)
    local _, rerollH = g.getImageSize("reroll_button_body")
    local rerollR = Kirigami(cardR.x, cardR.y + cardR.h + REROLL_GAP, cardR.w, rerollH)
    return cardR, rerollR
end

function SpellDiscardChoicePanel:draw()
    local r = ui.getFullScreenRegion()

    if #self.choices == 0 then
        return true
    end

    iml.panel(r:get())
    local cardArea = r:padRatio(0.05, 0.1)
    local titleR
    titleR, cardArea = cardArea:splitVertical(1, 5)
    cardArea = cardArea:padRatio(0.03, 0.02)
    titleR = titleR:padRatio(0.4)

    local titleFont = g.getBigFont(16)
    lg.setColor(1, 1, 1)
    richtext.printRichContainedNoWrap("{o}{bob}" .. CHOOSE_SPELL_DISCARD, titleFont, titleR:get())
    cardArea = r:padRatio(0.05, 0.1)

    if self.cj:hasAnimationBegun() then
        self.cj:draw()

        if self.cj:isAnimationFinished() then
            if self.selected and self.selected < ChoicePanelCommon.NUM_CHOICES then
                local spell = self.choices[self.selected]
                if spell ~= self.toBeAddedSpell then
                    g.removeSpellFromArmy(spell)

                    if self.toBeAddedSpell then
                        g.addSpellToArmy(self.toBeAddedSpell)
                    end
                end
            end

            return true
        end

        return false
    end

    local regions = cardArea:grid(ChoicePanelCommon.NUM_CHOICES, 1)
    local cx = cardArea.x + cardArea.w / 2
    local cy = cardArea.y + cardArea.h / 2

    for i = 1, #self.choices do
        local elapsed = love.timer.getTime() - (self.choiceCreatedAt[i] or self.createdAt)
        local t = math.min(1, math.max(0, elapsed / ChoicePanelCommon.FAN_OUT_DURATION))
        t = t * t * (3 - 2 * t)
        local scale = 0.5 + 0.5 * t
        local rr = regions[i]:padRatio(0.15)

        local targetCx = rr.x + rr.w / 2
        local targetCy = rr.y + rr.h / 2
        local animCx = cx + (targetCx - cx) * t
        local animCy = cy + (targetCy - cy) * t
        local dx = animCx - targetCx
        local dy = animCy - targetCy
        rr = rr:padRatio(1 - scale)
        regions[i] = rr:moveUnit(dx, dy)
    end

    for i, spellId in ipairs(self.choices) do
        local cardR = getCardRegions(regions[i])
        local function draw(reg)
            return ui.drawSpellCard(spellId, reg, i)
        end

        if draw(cardR) then
            self.selected = i

            for j, otherSpellId in ipairs(self.choices) do
                if i ~= j then
                    local otherCardR = getCardRegions(regions[j])
                    self.cj:spawnCardUnselected(otherCardR, j, function(reg)
                        return ui.drawSpellCard(otherSpellId, reg, j)
                    end)
                end
            end

            self.cj:spawnCardSelected(cardR, i, function(reg)
                return ui.drawSpellCard(spellId, reg, i)
            end)
        end
    end

    return false
end

return SpellDiscardChoicePanel
