local ChoicePanelCommon = require(".common")

---@class g.UpgradeSquadChoicePanel: g.ChoicePanelCommon
local UpgradeSquadChoicePanel = objects.Class("g:UpgradeSquadChoicePanel"):implement(ChoicePanelCommon)

function UpgradeSquadChoicePanel:init()
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
    ---@return g.UpgradeSquadChoicePanel
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function UpgradeSquadChoicePanel() end
end

---@private
function UpgradeSquadChoicePanel:_rollChoices()
    local pool = {}
    for k in pairs(g.getRun().squads) do
        local sqinfo = g.getSquadInfo(k)
        if not sqinfo.entityDef.isCommander then
            pool[#pool+1] = k
        end
    end

    self.choices = {}
    for _ = 1, ChoicePanelCommon.NUM_CHOICES do
        if #pool == 0 then
            break
        end

        self.choices[#self.choices+1] = table.remove(pool, love.math.random(#pool))
    end
end

function UpgradeSquadChoicePanel:draw()
    local r = ui.getFullScreenRegion()
    local cardArea = r

    if #self.choices == 0 then
        -- RIP in Pepperoni but safety handler must be done
        return true
    end

    iml.panel(r:get())
    cardArea = cardArea:padRatio(0.05, 0.1)
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
        local cardR = regions[i]:splitVertical(8, 1, 1)
        local clicked = ui.drawSquadCard(squadId, cardR, i, true, true)

        if clicked then
            g.addOrUpgradeSquad(squadId)
            return true
        end
    end

    return false
end

return UpgradeSquadChoicePanel
