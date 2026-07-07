local ChoicePanelCommon = require(".common")

local TITLE_FONT = nil

local STAT_CARD_BG = objects.Color("#111111")
local GRADIENT_CIRCLE = helper.gradientCircleMesh()
local CHOOSE_SQUAD_UPGRADE = loc("Choose a Squad Upgrade")

---@class StatChoicePanel.Tier
---@field rarity g.ValidRarities
---@field weight integer
---@field upscaleRange [number, number]
---@field downgradeChance number?
---@field downgradeScale [number, number]?

---@type StatChoicePanel.Tier[]
local TIERS = {
    {
        rarity = "COMMON",
        weight = 10,
        upscaleRange = {0.05, 0.1}
    },
    {
        rarity = "UNCOMMON",
        weight = 6,
        upscaleRange = {0.12, 0.2}
    },
    {
        rarity = "RARE",
        weight = 3,
        upscaleRange = {0.25, 0.4},
        downgradeChance = 0.55,
        downgradeScale = {0.15, 0.25},
    },
    {
        rarity = "LEGENDARY",
        weight = 1,
        upscaleRange = {0.5, 0.8},
        downgradeChance = 0.9,
        downgradeScale = {0.3, 0.6},
    },
}

---@type [integer, integer][]
local TIERS_AND_WEIGHTS = {}
for i, v in ipairs(TIERS) do
    TIERS_AND_WEIGHTS[#TIERS_AND_WEIGHTS+1] = {i, v.weight}
end

---@class g.StatChoicePanel.Upgrade
---@field tierIndex integer
---@field positive [string,number]
---@field negative [string,number]?

---@class g.StatChoicePanel: g.ChoicePanelCommon
local StatChoicePanel = objects.Class("g:StatChoicePanel"):implement(ChoicePanelCommon)

---@param squadId string
function StatChoicePanel:init(squadId)
    ---@type g.StatChoicePanel.Upgrade[]
    self.statChoices = {}
    ---@type number[]
    self.choiceCreatedAt = {}
    ---@type string
    self.squadId = assert(squadId)
    self.createdAt = love.timer.getTime()

    for _ = 1, ChoicePanelCommon.NUM_CHOICES do
        self.choiceCreatedAt[#self.choiceCreatedAt+1] = self.createdAt
    end

    self:_rollStats()
end

if false then
    ---@param squadId string
    ---@return g.StatChoicePanel
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function StatChoicePanel(squadId) end
end

---@private
function StatChoicePanel:_resetAnim()
    self.createdAt = love.timer.getTime()
    self.choiceCreatedAt = {}
    for _ = 1, ChoicePanelCommon.NUM_CHOICES do
        self.choiceCreatedAt[#self.choiceCreatedAt+1] = self.createdAt
    end
end

---@param squadId string
---@return string[]
---@private
function StatChoicePanel:_getAvailableStats(squadId)
    local info = g.getSquadInfo(squadId)
    local stats = {}
    for _, stat in ipairs(g.getStatList()) do
        local base = info.entityDef[stat.baseName]
        if base and base ~= 0 then
            stats[#stats+1] = stat.id
        end
    end
    return stats
end

---@param statId string
---@param scale number
---@return number
---@private
function StatChoicePanel:_getScaledAmount(statId, scale)
    local info = g.getSquadInfo(assert(self.squadId))
    local stat = g.getStatInfo(statId)
    local base = info.entityDef[stat.baseName] or 0
    return base * scale
end

---@private
function StatChoicePanel:_rollStats()
    local pool = self:_getAvailableStats(assert(self.squadId))
    self.statChoices = {}
    if #pool == 0 then
        self:_resetAnim()
        return
    end

    ---@param except string?
    local function roll(except)
        if not except then
            return helper.randomChoice(pool)
        end
        if #pool <= 1 then
            return nil
        end

        local rolled = helper.randomChoice(pool)
        while rolled == except do
            rolled = helper.randomChoice(pool)
        end
        return rolled
    end

    for i = 1, 3 do
        local tierIndex = helper.pickWeighted(TIERS_AND_WEIGHTS)
        local tier = TIERS[tierIndex]
        local positiveStatId = roll()
        local positiveScale = helper.lerp(tier.upscaleRange[1], tier.upscaleRange[2], love.math.random())
        local positive = {positiveStatId, self:_getScaledAmount(positiveStatId, positiveScale)}
        local negative = nil

        if tier.downgradeChance and tier.downgradeScale and love.math.random() <= tier.downgradeChance then
            local negativeStatId = roll(positiveStatId)
            if negativeStatId then
                local negativeScale = helper.lerp(tier.downgradeScale[1], tier.downgradeScale[2], love.math.random())
                negative = {negativeStatId, -self:_getScaledAmount(negativeStatId, negativeScale)}
            end
        end

        self.statChoices[#self.statChoices+1] = {
            tierIndex = tierIndex,
            positive = positive,
            negative = negative,
        }
    end
    self:_resetAnim()
end

---@param region kirigami.Region
---@private
function StatChoicePanel:_layoutCards(region)
    local cx = region.x + region.w / 2
    local cy = region.y + region.h * 0.55
    local radius = math.min(region.w, region.h) * 0.28
    local cardW = region.w * 0.3
    local cardH = region.h * 0.25
    local spots = {
        {x = cx, y = cy - radius},
        {x = cx - radius * 1.15, y = cy + radius * 0.65},
        {x = cx + radius * 1.15, y = cy + radius * 0.65},
    }
    assert(#spots == ChoicePanelCommon.NUM_CHOICES)

    local regions = {}
    for i = 1, #self.statChoices do
        local elapsed = love.timer.getTime() - (self.choiceCreatedAt[i] or self.createdAt)
        local t = math.min(1, math.max(0, elapsed / ChoicePanelCommon.FAN_OUT_DURATION))
        t = t * t * (3 - 2 * t)
        local scale = 0.5 + 0.5 * t

        local spot = spots[i] or spots[((i - 1) % #spots) + 1]
        local targetCx = spot.x
        local targetCy = spot.y
        local animCx = cx + (targetCx - cx) * t
        local animCy = cy + (targetCy - cy) * t
        regions[i] = Kirigami(animCx - cardW * scale / 2, animCy - cardH * scale / 2, cardW, cardH)
    end

    return regions
end

---@param choice g.StatChoicePanel.Upgrade
---@param region kirigami.Region
---@param index integer
---@private
function StatChoicePanel:_drawStatCard(choice, region, index)
    ui.assertUIStarted()

    local tier = TIERS[choice.tierIndex]
    local liteCol = g.RARITIES[tier.rarity].color
    local darkCol = g.RARITIES[tier.rarity].darkColor
    local uid = "stat_upgrade_" .. choice.tierIndex .. "_" .. index

    local x, y, w, h = region:get()
    local hitX, hitY = x, y
    if iml.isHovered(x, y, w, h, uid) then
        y = y - 3
    end

    TITLE_FONT = TITLE_FONT or g.getBigFont(16)

    local box = ui.Box({maxWidth = w, maxHeight = h, padding = 12, spacing = 6}, function(bx, by, bw, bh)
        helper.rotatingGlow(Kirigami(bx, by, bw, bh):padRatio(0.25), {
            count = 3,
            offset = (index - 1) * 1.37,
            glowScale = 100,
            rps = 1,
            wobbleFreq = 0.1,
            wobbleAmp = 10,
            color = {liteCol[1], liteCol[2], liteCol[3]},
        })

        local isHovered = iml.isHovered(bx, by, bw, bh, uid)
        love.graphics.setColor(isHovered and darkCol or STAT_CARD_BG)
        love.graphics.rectangle("fill", bx, by, bw, bh)
        love.graphics.setColor(liteCol[1], liteCol[2], liteCol[3], liteCol[4] * 0.5)
        love.graphics.draw(GRADIENT_CIRCLE, bx + bw / 2, by + bh / 2, 0, math.min(bw, bh))
        love.graphics.setColor(liteCol:getRGBA())
        ui.drawPanelThin(bx-3, by-3, bw+6, bh+6)
    end)

    box:addFill({
        getHeight = function() return 0 end,
        draw = function(ex, ey, ew, eh)
            lg.setColor(1, 1, 1)

            local positiveStat = g.getStatInfo(choice.positive[1])
            local parts = {
                string.format(
                    "{o}{c r=0.486 g=0.784 b=0.165}+%s{/c}%s{/o}",
                    g.formatNumber(choice.positive[2]),
                    positiveStat.richText
                )
            }
            if choice.negative then
                local negativeStat = g.getStatInfo(choice.negative[1])
                parts[#parts+1] = string.format(
                    "{o}{c r=0.773 g=0.188 b=0.239}%s{/c}%s{/o}",
                    g.formatNumber(choice.negative[2]),
                    negativeStat.richText
                )
            end

            richtext.printRichContained(table.concat(parts, "\n"), TITLE_FONT, ex, ey, ew, eh, 1, "center")
        end,
    })

    local ww, hh = box:render(x, y)

    if iml.wasJustClicked(hitX, hitY, w, h, 1, uid) then
        g.playUISound("ui_click_basic", 1.4, 0.8)
        return true, ww, hh
    end
    return false, ww, hh
end

function StatChoicePanel:draw()
    local r = ui.getFullScreenRegion()

    iml.panel(r:get())

    local headerR, cardAreaBaseR = r:padRatio(0.05, 0.1):splitVertical(1, 5)
    local cardAreaR, squadCardR = cardAreaBaseR:splitHorizontal(5, 2)
    local titleR, iconR = headerR:splitVertical(1, 1)

    TITLE_FONT = TITLE_FONT or g.getBigFont(16)
    lg.setColor(1, 1, 1)
    richtext.printRichContainedNoWrap("{o}{bob}" .. CHOOSE_SQUAD_UPGRADE, TITLE_FONT, titleR:padRatio(0.25):get())

    local squad = g.getSquadFromArmy(self.squadId)
    local iconX, iconY = iconR:getCenter()
    g.drawSquadIcon(self.squadId, iconX, iconY, false, squad and squad.level)

    local regions = self:_layoutCards(cardAreaR)

    if #self.statChoices == 0 then
        -- RIP in Pepperoni
        return true
    end

    ui.drawSquadCard(self.squadId, squadCardR, -999, false, true)

    for i, choice in ipairs(self.statChoices) do
        if self:_drawStatCard(choice, regions[i], i) and squad then
            g.buffSquadPermanently(squad, choice.positive[1], choice.positive[2])
            if choice.negative then
                g.buffSquadPermanently(squad, choice.negative[1], choice.negative[2])
            end
            return true
        end
    end

    return false
end

return StatChoicePanel
