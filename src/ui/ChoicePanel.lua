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
local MANABLESSING_PICK_TXT = loc("Pick one blessing!")
local MANA_PLUS_TXT = loc("+1")
local BONUS_TEXT = interp("Bonus %{s}")

local REROLL_GLOW_COL = objects.Color("#4d8c21")
local REROLL_GLOW_HOVER_COL = objects.Color("#7cc82a")

---@param region kirigami.Region
---@param index integer
---@param disabled boolean
---@return boolean
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
    g.drawImageContained(bodyImage, rerollR:get())

    local iconImage = disabled and "shop_reroll_icon_gray" or "shop_reroll_icon"
    g.drawImage(iconImage, x + w / 2, y + h / 2)

    return iml.wasJustClicked(x, y, w, h, 1, uid)
end


---@param rType "squad"|"blessing"|"mana"|"upgrade_squad"|"mana_blessing"
---@param rerolls integer?
---@param rarityWeights g.RarityWeights?
function ChoicePanel:init(rType, rerolls, rarityWeights)
    self.rType = rType
    ---@type integer[]
    self.rerolls = {}
    ---@type string[]
    self.choices = {}
    ---@type number[]
    self.choiceCreatedAt = {}
    self.rarityWeights = rarityWeights or consts.DEFAULT_RARITY_WEIGHTS
    self.createdAt = love.timer.getTime()

    for _ = 1, NUM_CHOICES do
        self.rerolls[#self.rerolls+1] = rerolls or 0
        self.choiceCreatedAt[#self.choiceCreatedAt+1] = self.createdAt
    end

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
                -- FIXME: Sonehow limit this to 3 maybe in the future?
                self.choices[#self.choices + 1] = manaType
            end
        end
    elseif self.rType == "mana_blessing" then
        local manaPool = {}
        for manaType in pairs(manaCells) do
            if manaType ~= g.WILDCARD_MANA then
                manaPool[#manaPool + 1] = manaType
            end
        end

        local seenBlessings = helper.shallowCopy(g.getRun().blessings)
        for _ = 1, NUM_CHOICES do
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
    elseif self.rType == "upgrade_squad" then
        local pool = {}
        for k in pairs(g.getRun().squads) do
            local sqinfo = g.getSquadInfo(k)
            if not sqinfo.entityDef.isCommander then
                pool[#pool+1] = k
            end
        end

        -- No need for "_pickFromPool". We want no dupes.
        self.choices = {}
        for _ = 1, NUM_CHOICES do
            if #pool == 0 then
                break
            end

            self.choices[#self.choices+1] = table.remove(pool, love.math.random(#pool))
        end
    end
end


---@param pool string[]
---@param getInfo fun(id:string):{rarity:g.Rarity}
---@param seen table<string, true?>
---@return string?
---@private
function ChoicePanel:_pickOneFromPool(pool, getInfo, seen)
    if #pool == 0 then return end

    local weights = {}
    for i, id in ipairs(pool) do
        local info = getInfo(id)
        weights[i] = self.rarityWeights[info.rarity.id] or 0
    end

    local picker = newPicker(pool, weights)
    local pick = picker:pick()
    for _ = 1, 20 do
        if not seen[pick] then
            return pick
        end
        pick = picker:pick()
    end
    return pick
end


---@param index integer
---@private
function ChoicePanel:_rerollChoice(index)
    if self.rType ~= "squad" then return end
    if (self.rerolls[index] or 0) <= 0 then return end

    local seen = {}
    for _, id in ipairs(self.choices) do
        seen[id] = true
    end

    local pick = self:_pickOneFromPool(
        g.getSquadsByMana(g.getRun().mana),
        g.getSquadInfo,
        seen
    )
    if not pick then return end

    self.rerolls[index] = self.rerolls[index] - 1
    self.choices[index] = pick
    self.choiceCreatedAt[index] = love.timer.getTime()
end


---@param pool string[]
---@param getInfo fun(id:string):{rarity:g.Rarity}
---@param out string[]?
---@param count integer?
---@private
function ChoicePanel:_pickFromPool(pool, getInfo, out, count)
    if #pool == 0 then return end
    out = out or self.choices
    count = count or NUM_CHOICES

    local weights = {}
    for i, id in ipairs(pool) do
        local info = getInfo(id)
        weights[i] = self.rarityWeights[info.rarity.id] or 0
    end
    local picker = newPicker(pool, weights)
    ---@type table<string, true?>
    local seen = helper.shallowCopy(g.getRun().blessings)
    for _ = 1, count do
        local pick = picker:pick()
        -- avoid duplicates; try a few times
        for _ = 1, 20 do
            if not seen[pick] then break end
            pick = picker:pick()
        end
        seen[pick] = true
        out[#out + 1] = pick
    end
end



function ChoicePanel:draw()
    local r = ui.getFullScreenRegion()
    local cardArea = r

    if #self.choices == 0 then
        -- RIP in Pepperoni but safety handler must be done
        return true
    end

    iml.panel(r:get())
    cardArea = cardArea:padRatio(0.05, 0.1)
    if self.rType == "mana" then
        cardArea = r:padRatio(0.3, 0.35)
    elseif self.rType == "mana_blessing" then
        local titleFont = g.getBigFont(16)
        local titleR
        titleR, cardArea = cardArea:splitVertical(1,5)
        lg.setColor(1,1,1)
        cardArea = cardArea:padRatio(0.03, 0.02)
        titleR = titleR:padRatio(0.4)
        richtext.printRichContainedNoWrap("{o}{bob}" .. MANABLESSING_PICK_TXT, titleFont, titleR:get())
    end
    local regions = cardArea:grid(NUM_CHOICES, 1)
    local cx = cardArea.x + cardArea.w / 2
    local cy = cardArea.y + cardArea.h / 2

    local ox = regions[1].w * (NUM_CHOICES - #self.choices) / 2
    for i = 1, #self.choices do
        local elapsed = love.timer.getTime() - (self.choiceCreatedAt[i] or self.createdAt)
        local t = math.min(1, math.max(0, elapsed / FAN_OUT_DURATION))
        t = t * t * (3 - 2 * t)
        local scale = 0.5 + 0.5 * t
        local rr = regions[i]
        rr = rr:padRatio(0.15)
        if self.rType == "mana" then
            rr = rr:padRatio(0.3)
            rr = rr:shrinkToAspectRatio(1,1)
        elseif self.rType == "blessing" then
            rr = rr:shrinkToAspectRatio(3, 2)
        elseif self.rType == "mana_blessing" then
            rr = rr:shrinkToAspectRatio(1,1)
        end
        local targetCx = rr.x + rr.w / 2
        local targetCy = rr.y + rr.h / 2
        local animCx = cx + (targetCx - cx) * t
        local animCy = cy + (targetCy - cy) * t
        local dx = animCx - targetCx
        local dy = animCy - targetCy
        rr = rr:padRatio(1 - scale)
        regions[i] = rr:moveUnit(dx + ox, dy)
    end

    if self.rType == "mana_blessing" then
        lg.setColor(1, 1, 1, 0.8)
        lg.setLineWidth(4)
        for i = 1, #self.choices - 1 do
            local left = regions[i]
            local right = regions[i + 1]
            local x = (left.x + left.w + right.x) / 2
            local y1 = math.min(left.y, right.y)
            local y2 = math.max(left.y + left.h, right.y + right.h)
            lg.line(x, y1 - 30, x, y2 + 10)
        end
        lg.setLineWidth(1)
    end

    if self.rType == "squad" or self.rType == "upgrade_squad" then
        for i, squadId in ipairs(self.choices) do
            local cardR, _, rerollR = regions[i]:splitVertical(8, 1, 1)
            local clicked = ui.drawSquadCard(squadId, cardR, i, true, true)
            local rerollClicked = false
            if self.rType == "squad" then
                rerollClicked = drawRerollButton(rerollR, i, (self.rerolls[i] or 0) <= 0)
            end

            if rerollClicked then
                self:_rerollChoice(i)
            elseif clicked then
                g.addOrUpgradeSquad(squadId)
                return true
            end
        end
    elseif self.rType == "blessing" then
        for i, blessId in ipairs(self.choices) do
            local clicked = ui.drawBlessingCard(blessId, regions[i], i)
            if clicked then
                g.addBlessing(blessId)
                return true
            end
        end
    elseif self.rType == "mana" then
        for i, manaType in ipairs(self.choices) do
            if drawManaCard(manaType, regions[i], i) then
                g.addPermanentMana(manaType)
                return true
            end
        end
    elseif self.rType == "mana_blessing" then
        for i, pair in ipairs(self.choices) do
            ---@diagnostic disable-next-line: cast-type-mismatch
            ---@cast pair {mana:string,blessing:string}
            local offX = helper.lerp(-0.15, 0.15, (i - 1) % 2)
            local reg = regions[i]:moveRatio(offX, -0.1)
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

            if clicked or clickedBlessing then
                g.playUISound("ui_click_basic", 1.4, 0.8)
                g.addBlessing(pair.blessing)
                g.addPermanentMana(pair.mana)
                return true
            end
        end
    end

end




return ChoicePanel
