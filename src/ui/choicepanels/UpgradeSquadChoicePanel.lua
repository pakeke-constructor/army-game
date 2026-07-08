local ChoicePanelCommon = require(".common")
local cardJuiceService = require("src.cardJuiceService")

---@class g.UpgradeSquadChoicePanel: g.ChoicePanelCommon
local UpgradeSquadChoicePanel = objects.Class("g:UpgradeSquadChoicePanel"):implement(ChoicePanelCommon)

function UpgradeSquadChoicePanel:init()
    ---@type string[]
    self.choices = {}
    ---@type number[]
    self.choiceCreatedAt = {}
    self.createdAt = love.timer.getTime()
    ---@type [integer,number]|nil
    self.selected = nil

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

---@param regions kirigami.Region[]
---@return boolean
function UpgradeSquadChoicePanel:_drawCards(regions)
    local t = love.timer.getTime()
    for i, squadId in ipairs(self.choices) do
        local cardR = regions[i]:splitVertical(8, 1, 1)

        if self.selected then
            local t1 = (t - self.selected[2]) / ChoicePanelCommon.SELECT_ANIM_DURATION
            local function draw(r)
                return ui.drawSquadCard(squadId, r, i, true, true)
            end

            if self.selected[1] == i then
                -- Copied from stat choice panel
                local r = ui.getFullScreenRegion()
                local _, cardAreaBaseR = r:padRatio(0.05, 0.1):splitVertical(1, 5)
                local _, squadCardR = cardAreaBaseR:splitHorizontal(5, 2)
                cardJuiceService.drawSelected(t1, cardR, i, draw, squadCardR)
            else
                cardJuiceService.drawUnselected(t1, cardR, i, draw)
            end
        else
            local clicked = ui.drawSquadCard(squadId, cardR, i, true, true)

            if clicked then
                -- Delayed select
                self.selected = {i, t}
            end
        end
    end

    if self.selected and (t - self.selected[2]) >= ChoicePanelCommon.SELECT_ANIM_DURATION then
        -- Actually apply
        local squadId = self.choices[self.selected[1]]
        g.addOrUpgradeSquad(squadId)
        statUpgradePopupService.set(squadId)
        return true
    end

    return false
end

function UpgradeSquadChoicePanel:draw()
    local r = ui.getFullScreenRegion()

    if #self.choices == 0 then
        -- RIP in Pepperoni but safety handler must be done
        return true
    end

    iml.panel(r:get())
    r = r:padRatio(0.05, 0.1)
    local regions = r:grid(ChoicePanelCommon.NUM_CHOICES, 1)
    local cx = r.x + r.w / 2
    local cy = r.y + r.h / 2

    local ox = regions[1].w * (ChoicePanelCommon.NUM_CHOICES - #self.choices) / 2
    for i = 1, #self.choices do
        local elapsed = love.timer.getTime() - (self.choiceCreatedAt[i] or self.createdAt)
        local t = math.min(1, math.max(0, elapsed / ChoicePanelCommon.FAN_OUT_DURATION))
        t = t * t * (3 - 2 * t)
        local scale = 0.5 + 0.5 * t
        local rr = regions[i]
        rr = rr:padRatio(0.15)

        local targetCx = rr.x + rr.w / 2 + ox
        local targetCy = rr.y + rr.h / 2
        local animCx = cx + (targetCx - cx) * t
        local animCy = cy + (targetCy - cy) * t
        local dx = animCx - (rr.x + rr.w / 2)
        local dy = animCy - targetCy
        rr = rr:padRatio(1 - scale)
        regions[i] = rr:moveUnit(dx, dy)
    end

    return self:_drawCards(regions)
end

return UpgradeSquadChoicePanel
