local ChoicePanelCommon = require(".common")
local cardJuiceService = require("src.cardJuiceService")

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
        downgradeChance = 1,
        downgradeScale = {0.15, 0.25},
    },
    {
        rarity = "LEGENDARY",
        weight = 1,
        upscaleRange = {0.5, 0.8},
        downgradeChance = 1,
        downgradeScale = {0.3, 0.6},
    },
}



---@class StatChoicePanel.NamedStat
---@field name string
---@field positive string (stat name)
---@field negative string (stat name)

---@type StatChoicePanel.NamedStat[]
local NAMED_STAT = {
    {
        name = loc("Ironskin"),
        positive = "startingArmor",
        negative = "maxHealth",
    },
    {
        name = loc("Reckless"),
        positive = "attackDamage",
        negative = "maxHealth",
    },
    {
        name = loc("Precise"),
        positive = "attackRange",
        negative = "attackSpeed",
    },
    {
        name = loc("Heavy"),
        positive = "maxHealth",
        negative = "moveSpeed",
    },
    {
        name = loc("Armor"),
        positive = "startingArmor",
        negative = "moveSpeed",
    },
    {
        name = loc("Beserk"),
        positive = "attackSpeed",
        negative = "maxHealth",
    },
    {
        name = loc("Defensive"),
        positive = "maxHealth",
        negative = "attackSpeed",
    },
    {
        name = loc("Pacify"),
        positive = "magic",
        negative = "attackDamage",
    },
    {
        name = loc("Primitive"),
        positive = "attackDamage",
        negative = "magic",
    },
    {
        name = loc("Turtle"),
        positive = "startingArmor",
        negative = "attackSpeed",
    },
    {
        name = loc("Bravery"),
        positive = "attackDamage",
        negative = "attackRange",
    },
}

---@type [integer, integer][]
local TIERS_AND_WEIGHTS = {}
for i, v in ipairs(TIERS) do
    TIERS_AND_WEIGHTS[#TIERS_AND_WEIGHTS+1] = {i, v.weight}
end



---@param n number
local function statNumFmt(n)
    local nnum = math.abs(n)

    if nnum < 3 then
        -- round to 1dp
        nnum = math.floor(nnum*10 + 0.5) / 10
    else
        -- otherwise, round it to a whole number
        nnum = math.floor(nnum + 0.5)
    end

    return (n < 0 and "-" or "+")..tostring(nnum)
end




---@class g.StatChoicePanel.Upgrade
---@field tierIndex integer
---@field positive [string,number]
---@field negative [string,number]?
---@field name string?

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
    ---@type integer|nil
    self.selected = nil
    self.cj = cardJuiceService.CardJuiceInstance()

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
    self.selected = nil
    self.cj = cardJuiceService.CardJuiceInstance()
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
        if g.isStatImportant(stat.id, info.entityDef) then
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

        local rolled = helper.randomChoice(pool)
        while rolled == except do
            rolled = helper.randomChoice(pool)
        end
        return rolled
    end

    local info = g.getSquadInfo(assert(self.squadId))

    for _ = 1, 3 do
        local tierIndex = helper.pickWeighted(TIERS_AND_WEIGHTS)
        local tier = TIERS[tierIndex]
        local positive = nil
        local negative = nil
        local statName = nil

        if tier.downgradeChance and tier.downgradeScale and love.math.random() <= tier.downgradeChance then
            -- Roll named
            ---@type StatChoicePanel.NamedStat[]
            local possibleNamed = {}
            for _, v in ipairs(NAMED_STAT) do
                if g.isStatImportant(v.positive, info.entityDef) and g.isStatImportant(v.negative, info.entityDef) then
                    possibleNamed[#possibleNamed+1] = v
                end
            end

            if #possibleNamed > 0 then
                local namedStat = helper.randomChoice(possibleNamed)
                positive = {
                    namedStat.positive,
                    self:_getScaledAmount(
                        namedStat.positive,
                        helper.lerp(tier.upscaleRange[1], tier.upscaleRange[2], love.math.random()))
                }
                negative = {
                    namedStat.negative,
                    -self:_getScaledAmount(
                        namedStat.negative,
                        helper.lerp(tier.downgradeScale[1], tier.downgradeScale[2], love.math.random()))
                }
                statName = namedStat.name
            end
        end

        if not positive then
            -- Roll individual
            local positiveStatId = roll()
            local positiveScale = helper.lerp(tier.upscaleRange[1], tier.upscaleRange[2], love.math.random())
            positive = {positiveStatId, self:_getScaledAmount(positiveStatId, positiveScale)}
        end

        self.statChoices[#self.statChoices+1] = {
            tierIndex = tierIndex,
            positive = positive,
            negative = negative,
            name = statName
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

    local font = g.getBigFont(16)

    local box = ui.Box({maxWidth = w, maxHeight = h, padding = 4, spacing = 0}, function(bx, by, bw, bh)
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

    if choice.name then
        box:add({
            getHeight = function()
                return font:getHeight()
            end,
            draw = function(ex, ey, ew, eh)
                local rarity = g.RARITIES[TIERS[choice.tierIndex].rarity]
                lg.setColor(rarity.lightColor)
                richtext.printRich("{o}"..choice.name.."{/o}", font, ex, ey, ew, "center")
            end
        })
    end

    box:addFill({
        getHeight = function() return 0 end,
        draw = function(ex, ey, ew, eh)
            lg.setColor(1, 1, 1)
            local positiveStat = g.getStatInfo(choice.positive[1])

            if choice.negative then
                -- Positive and negative
                local leftR, rightR = Kirigami(ex, ey, ew, eh):splitHorizontal(1, 1)
                -- Positive
                local leftText = string.format(
                    "{o}%s\n%s{/o}",
                    positiveStat.richText,
                    helper.wrapRichtextColor(positiveStat.color, statNumFmt(choice.positive[2]))
                )
                local x, y, w, h = leftR:get()
                richtext.printRichContained(leftText, font, x, y, w, h, 1, "center")
                -- Negative
                local negativeStat = g.getStatInfo(choice.negative[1])
                local rightText = string.format(
                    "{o}%s\n{c r=0.773 g=0.188 b=0.239}%s{/c}{/o}",
                    negativeStat.richText,
                    statNumFmt(choice.negative[2])
                )
                x, y, w, h = rightR:get()
                richtext.printRichContained(rightText, font, x, y, w, h, 1, "center")
            else
                -- Positive only
                local text = string.format(
                    "{o}%s\n%s{/o}",
                    positiveStat.richText,
                    helper.wrapRichtextColor(positiveStat.color, statNumFmt(choice.positive[2]))
                )
                richtext.printRichContained(text, font, ex, ey, ew, eh, 1, "center")
            end
        end,
    })

    local ww, hh = box:render(x, y)

    if iml.wasJustClicked(hitX, hitY, w, h, 1, uid) then
        g.playUISound("ui_click_basic", 1.4, 0.8)
        return true, ww, hh
    end
    return false, ww, hh
end




---@param cardR kirigami.Region
---@param cardAreaR kirigami.Region
---@return kirigami.Region
---@private
local function _getSelectedTarget(cardR, cardAreaR)
    local cx = cardAreaR.x + cardAreaR.w / 2
    local cy = cardAreaR.y + cardAreaR.h * 0.55
    return Kirigami(cx - cardR.w / 2, cy - cardR.h / 2, cardR.w, cardR.h)
end

function StatChoicePanel:draw()
    local r = ui.getFullScreenRegion()

    iml.panel(r:get())

    local headerR, cardAreaBaseR = r:padRatio(0.05, 0.1):splitVertical(1, 5)
    local cardAreaR, squadCardR = cardAreaBaseR:splitHorizontal(5, 2)
    local titleR = headerR:splitVertical(1, 1)

    TITLE_FONT = TITLE_FONT or g.getBigFont(16)
    lg.setColor(1, 1, 1)
    richtext.printRichContainedNoWrap("{o}{bob}" .. CHOOSE_SQUAD_UPGRADE, TITLE_FONT, titleR:padRatio(0.25):get())

    local regions = self:_layoutCards(cardAreaR)

    if #self.statChoices == 0 then
        -- RIP in Pepperoni
        return true
    end

    if not self.cj:hasAnimationBegun() then
        for i, choice in ipairs(self.statChoices) do
            if self:_drawStatCard(choice, regions[i], i) then
                g.playUISound("ui_click_basic", 1.4, 0.8)
                self.selected = i

                -- Spawn cards
                for j, otherChoice in ipairs(self.statChoices) do
                    if i ~= j then
                        self.cj:spawnCardUnselected(regions[j], j, function(r)
                            return self:_drawStatCard(otherChoice, r, j)
                        end)
                    end
                end

                local targetR = _getSelectedTarget(regions[i], cardAreaR)
                self.cj:spawnCardSelected(regions[i], i, function(r)
                    return self:_drawStatCard(choice, r, i)
                end, targetR)
            end
        end
    end

    local cardJuiceFinished = self.cj:draw()
    ui.drawSquadCard(self.squadId, squadCardR, -999, false, true)

    if cardJuiceFinished then
        local choice = self.statChoices[self.selected]
        local squad = g.getSquadFromArmy(self.squadId)
        if squad then
            g.buffSquadPermanently(squad, choice.positive[1], choice.positive[2])
            if choice.negative then
                g.buffSquadPermanently(squad, choice.negative[1], choice.negative[2])
            end
        end

        return true
    end

    return false
end

return StatChoicePanel
