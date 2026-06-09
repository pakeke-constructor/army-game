local newPicker = require("src.modules.Picker")


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



---@class g.ChoicePanel: objects.Class
local ChoicePanel = objects.Class("g:ChoicePanel")


local NUM_CHOICES = 3
local FAN_OUT_DURATION = 0.11
local REROLL_TXT = interp("Reroll (%{n})")


---@param rType "squad"|"blessing"|"mana"
---@param rerolls integer?
---@param rarityWeights g.RarityWeights?
function ChoicePanel:init(rType, rerolls, rarityWeights)
    self.rType = rType
    self.rerolls = rerolls or 0
    self.choices = {}
    self.rarityWeights = rarityWeights or consts.DEFAULT_RARITY_WEIGHTS
    self.createdAt = love.timer.getTime()

    self:_rollChoices()
end


---@private
function ChoicePanel:_rollChoices()
    self.choices = {}

    local manaCells = g.getRun().mana

    if self.rType == "squad" then
        local pool = g.getSquadsByMana(manaCells)
        self:_pickFromPool(pool, g.getSquadInfo)
    elseif self.rType == "blessing" then
        local pool = g.getBlessingsByMana(manaCells)
        self:_pickFromPool(pool, g.getBlessingInfo)
    elseif self.rType == "mana" then
        for manaType in pairs(manaCells) do
            if manaType ~= g.WILDCARD_MANA then
                self.choices[#self.choices + 1] = manaType
            end
        end
    end
end


---@param pool string[]
---@param getInfo fun(id:string):{rarity:g.Rarity}
---@private
function ChoicePanel:_pickFromPool(pool, getInfo)
    if #pool == 0 then return end
    local weights = {}
    for i, id in ipairs(pool) do
        local info = getInfo(id)
        weights[i] = self.rarityWeights[info.rarity.id] or 0
    end
    local picker = newPicker(pool, weights)
    ---@type table<string, true?>
    local seen = helper.shallowCopy(g.getRun().blessings)
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
    local bot, cardArea = r, r
    if self.rerolls > 0 then
        cardArea, bot = r:splitVertical(8,1)
    end

    iml.panel(r:get())
    cardArea = cardArea:padRatio(0.05, 0.1)
    if self.rType == "mana" then
        cardArea = r:padRatio(0.3, 0.35)
    end
    local regions = cardArea:grid(#self.choices, 1)
    local elapsed = love.timer.getTime() - self.createdAt
    local t = math.min(1, math.max(0, elapsed / FAN_OUT_DURATION))
    t = t * t * (3 - 2 * t)
    local cx = cardArea.x + cardArea.w / 2
    local cy = cardArea.y + cardArea.h / 2
    local scale = 0.5 + 0.5 * t

    for i,rr in ipairs(regions) do
        rr = rr:padRatio(0.15)
        if self.rType == "mana" then
            rr = rr:padRatio(0.3)
            rr = rr:shrinkToAspectRatio(1,1)
        elseif self.rType == "blessing" then
            rr = rr:shrinkToAspectRatio(3, 2)
        end
        local targetCx = rr.x + rr.w / 2
        local targetCy = rr.y + rr.h / 2
        local animCx = cx + (targetCx - cx) * t
        local animCy = cy + (targetCy - cy) * t
        local dx = animCx - targetCx
        local dy = animCy - targetCy
        rr = rr:padRatio(1 - scale)
        regions[i] = rr:moveUnit(dx, dy)
    end

    if self.rType == "squad" then
        for i = 1, #regions do
            local squadId = self.choices[i]
            local clicked = ui.drawSquadCard(squadId, regions[i], i, true)
            if clicked then
                g.addOrUpgradeSquad(squadId)
                return true
            end
        end
    elseif self.rType == "blessing" then
        for i = 1, #regions do
            local blessId = self.choices[i]
            local clicked = ui.drawBlessingCard(blessId, regions[i], i)
            if clicked then
                g.addBlessing(blessId)
                return true
            end
        end
    elseif self.rType == "mana" then
        for i = 1, #regions do
            local manaType = self.choices[i]
            if drawManaCard(manaType, regions[i], i) then
                g.addPermanentMana(manaType)
                return true
            end
        end
    end

    if self.rerolls > 0 then
        local _, rerollR, _ = bot:splitHorizontal(2, 1, 2)
        rerollR = rerollR:moveRatio(0, -0.3)
        if iml.isHovered(rerollR:get()) then
            lg.setColor(0.5,0.5,0.5)
        else
            lg.setColor(1,1,1)
        end

        local IMG = "reroll_button_body"
        g.drawImageContained(IMG, rerollR:get())

        local font = g.getSmallFont(16)
        richtext.printRichContained(
            "{shop_reroll_icon} " .. REROLL_TXT({n = self.rerolls}),
            font,
            rerollR:padRatio(0.6):get()
        )

        if iml.wasJustClicked(rerollR:get()) then
            self.rerolls = self.rerolls - 1
            self.createdAt = love.timer.getTime()
            self:_rollChoices()
        end
    end
end




return ChoicePanel

