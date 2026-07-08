local Picker = require("src.modules.Picker")
local cardJuiceService = require("src.cardJuiceService")

local ChoicePanelCommon = require(".common")

---@class g.ManaBlessingChoicePanel: g.ChoicePanelCommon
local ManaBlessingChoicePanel = objects.Class("g:ManaBlessingChoicePanel")

---@param rarityWeights g.RarityWeights?
function ManaBlessingChoicePanel:init(rarityWeights)
    ---@type {mana:string,blessing:string}[]
    self.choices = {}
    ---@type number[]
    self.choiceCreatedAt = {}
    self.rarityWeights = rarityWeights or consts.DEFAULT_RARITY_WEIGHTS
    self.createdAt = love.timer.getTime()
    ---@type integer|nil
    self.selected = nil
    self.cj = cardJuiceService.CardJuiceInstance()

    for _ = 1, ChoicePanelCommon.NUM_CHOICES do
        self.choiceCreatedAt[#self.choiceCreatedAt+1] = self.createdAt
    end

    self:_rollChoices()
end

if false then
    ---@param rarityWeights g.RarityWeights?
    ---@return g.ManaBlessingChoicePanel
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function ManaBlessingChoicePanel(rarityWeights) end
end


---@private
function ManaBlessingChoicePanel:_rollChoices()
    self.choices = {}

    local manaCells = g.getRun().mana

    local manaPool = {}
    for manaType in pairs(manaCells) do
        if manaType ~= g.WILDCARD_MANA then
            manaPool[#manaPool + 1] = manaType
        end
    end

    local seenBlessings = helper.shallowCopy(g.getRun().blessings)
    for _ = 1, ChoicePanelCommon.NUM_CHOICES do
        if #manaPool == 0 then
            break
        end

        local manaType = table.remove(manaPool, love.math.random(#manaPool))
        local blessingId = g.getRandomBlessingByMana(
            { [manaType] = 1 },
            self.rarityWeights,
            seenBlessings
        )

        if blessingId then
            seenBlessings[blessingId] = true
            self.choices[#self.choices + 1] = {
                mana = manaType,
                blessing = blessingId,
            }
        end
    end
end



local MANABLESSING_PICK_TXT = loc("Pick one blessing!")
local MANA_PLUS_TXT = loc("+1")
local BONUS_TEXT = interp("Bonus %{s}")

---@param reg kirigami.Region
---@param i integer
---@return kirigami.Region
local function getChoiceRegion(reg, i)
    local offX = helper.lerp(-0.15, 0.15, (i - 1) % 2)
    return reg:moveRatio(offX, -0.1)
end

---@param pair {mana:string,blessing:string}
---@param reg kirigami.Region
---@param i integer
---@return boolean
function ManaBlessingChoicePanel:_drawChoice(pair, reg, i)
    local cardR, infoR = reg:splitVertical(8, 3)
    local clicked = iml.wasJustClicked(reg:get())
    if iml.isHovered(reg:get()) then
        cardR = cardR:moveUnit(0, -3)
    end
    local clickedBlessing, _, cardH = ui.drawBlessingCard(pair.blessing, cardR:padRatio(0.02), i)

    local x, y, w, h = infoR:padRatio(0.08):get()
    local textY = y + h * 0.15 + math.max(cardH - cardR.h, 0)
    local manaFont = g.getBigFont(16)
    richtext.printRichContainedNoWrap(
        BONUS_TEXT({s = "{o}" .. MANA_PLUS_TXT .. " {" .. pair.mana .. "}"}),
        manaFont,
        x, textY, w, h * 0.7
    )

    return clicked or clickedBlessing
end

function ManaBlessingChoicePanel:draw()
    local r = ui.getFullScreenRegion()
    local cardArea = r

    if #self.choices == 0 then
        -- RIP in Pepperoni but safety handler must be done
        return true
    end

    iml.panel(r:get())
    cardArea = cardArea:padRatio(0.05, 0.1)

    -- Top text
    local titleFont = g.getBigFont(16)
    local titleR
    titleR, cardArea = cardArea:splitVertical(1,5)
    lg.setColor(1,1,1)
    cardArea = cardArea:padRatio(0.03, 0.02)
    titleR = titleR:padRatio(0.4)
    richtext.printRichContainedNoWrap("{o}{bob}" .. MANABLESSING_PICK_TXT, titleFont, titleR:get())

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
        rr = rr:padRatio(0.15):shrinkToAspectRatio(1,1)
        local targetCx = rr.x + rr.w / 2 + ox
        local targetCy = rr.y + rr.h / 2
        local animCx = cx + (targetCx - cx) * t
        local animCy = cy + (targetCy - cy) * t
        local dx = animCx - (rr.x + rr.w / 2)
        local dy = animCy - targetCy
        rr = rr:padRatio(1 - scale)
        regions[i] = rr:moveUnit(dx, dy)
    end

    if not self.selected then
        lg.setColor(1, 1, 1, 0.8)
        local lw = gsman.setLineWidth(4)
        for i = 1, #self.choices - 1 do
            local left = regions[i]
            local right = regions[i + 1]
            local x = (left.x + left.w + right.x) / 2
            local y1 = math.min(left.y, right.y)
            local y2 = math.max(left.y + left.h, right.y + right.h)
            lg.line(x, y1 - 30, x, y2 + 10)
        end
        lw:pop()
    end

    if not self.cj:hasAnimationBegun() then
        for i, pair in ipairs(self.choices) do
            ---@diagnostic disable-next-line: cast-type-mismatch
            ---@cast pair {mana:string,blessing:string}
            local choiceR = getChoiceRegion(regions[i], i)
            if self:_drawChoice(pair, choiceR, i) then
                g.playUISound("ui_click_basic", 1.4, 0.8)
                self.selected = i

                -- Spawn cards
                for j, otherPair in ipairs(self.choices) do
                    ---@diagnostic disable-next-line: cast-type-mismatch
                    ---@cast otherPair {mana:string,blessing:string}
                    local otherChoiceR = getChoiceRegion(regions[j], j)
                    if i ~= j then
                        self.cj:spawnCardUnselected(otherChoiceR, j, function(r)
                            return self:_drawChoice(otherPair, r, j)
                        end)
                    end
                end
                self.cj:spawnCardSelected(choiceR, i, function(r)
                    return self:_drawChoice(pair, r, i)
                end)
            end
        end
    end

    if self.cj:draw() then
        local pair = self.choices[self.selected]
        g.addBlessing(pair.blessing)
        g.addPermanentMana(pair.mana)
        return true
    end

    return false
end

return ManaBlessingChoicePanel
