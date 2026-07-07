local ChoicePanelCommon = require(".common")

---@class g.ManaChoicePanel: g.ChoicePanelCommon
local ManaChoicePanel = objects.Class("g:ManaChoicePanel"):implement(ChoicePanelCommon)

function ManaChoicePanel:init()
    ---@type string[]
    self.choices = {}
    ---@type number[]
    self.choiceCreatedAt = {}
    self.createdAt = love.timer.getTime()

    for _ = 1, ChoicePanelCommon.NUM_CHOICES do
        self.choiceCreatedAt[#self.choiceCreatedAt+1] = self.createdAt
    end

    self:_rollChoices()
end

if false then
    ---@return g.ManaChoicePanel
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function ManaChoicePanel() end
end

---@private
function ManaChoicePanel:_rollChoices()
    self.choices = {}

    for manaType in pairs(g.getRun().mana) do
        if manaType ~= g.WILDCARD_MANA then
            -- FIXME: Sonehow limit this to 3 maybe in the future?
            self.choices[#self.choices + 1] = manaType
        end
    end
end

---@param manaType g.ManaType
---@param region kirigami.Region
---@param index integer
local function drawManaCard(manaType, region, index)
    local info = g.getManaInfo(manaType)
    local col = info.color
    local darkCol = col:lerp(objects.Color(0,0,0,1), 0.6)
    local bgCol1 = objects.Color(0.05, 0.05, 0.06, 0.7)
    local uid = "mana_" .. manaType .. "_" .. index

    local x, y, w, h = region:get()
    iml.panel(x, y, w, h, uid)
    local isHovered = iml.isHovered(x, y, w, h, uid)
    if isHovered then darkCol = darkCol:lerp(col, 0.3) end

    love.graphics.setColor(1, 1, 1)
    helper.gradientRect("vertical", bgCol1, darkCol, x, y, w, h)
    love.graphics.setColor(col:getRGBA())
    ui.drawPanel(x-3, y-3, w+6, h+6)

    local iconR, textR = region:padRatio(0.1):splitVertical(0.7, 0.3)
    love.graphics.setColor(1,1,1)
    g.drawImageContained(info.imageLarge, iconR:padRatio(0.4):get())

    local font = g.getBigFont(16)
    richtext.printRichContainedNoWrap("{o}(+1 {" .. manaType .. "})", font, textR:get())

    if iml.wasJustClicked(x, y, w, h, 1, uid) then
        g.playUISound("ui_click_basic", 1.4, 0.8)
        return true
    end
    return false
end

function ManaChoicePanel:draw()
    local r = ui.getFullScreenRegion()
    local cardArea = r

    if #self.choices == 0 then
        -- RIP in Pepperoni but safety handler must be done
        return true
    end

    iml.panel(r:get())
    cardArea = r:padRatio(0.3, 0.35)
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
        rr = rr:padRatio(0.15):padRatio(0.3):shrinkToAspectRatio(1,1)

        local targetCx = rr.x + rr.w / 2
        local targetCy = rr.y + rr.h / 2
        local animCx = cx + (targetCx - cx) * t
        local animCy = cy + (targetCy - cy) * t
        local dx = animCx - targetCx
        local dy = animCy - targetCy
        rr = rr:padRatio(1 - scale)
        regions[i] = rr:moveUnit(dx + ox, dy)
    end

    for i, manaType in ipairs(self.choices) do
        if drawManaCard(manaType, regions[i], i) then
            g.addPermanentMana(manaType)
            return true
        end
    end

    return false
end

return ManaChoicePanel
