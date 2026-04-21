
local TITLE_FONT = nil
local DESC_FONT = nil
local COST_FONT = nil

local LOC_CD = loc("CD: %{n}s", nil, {context = "Cooldown on spell card"})

---Draw a spell card in a kirigami region. Returns true if clicked.
---@param spellId string
---@param region kirigami.Region
---@return boolean
local function drawSpellCard(spellId, region)
    ui.assertUIStarted()

    local info = g.getSpellInfo(spellId)
    local darkCol = objects.Color(0.08, 0.1, 0.2, 0.9)
    local borderCol = objects.Color(0.3, 0.4, 0.8)
    local bgCol1 = objects.Color(0.05, 0.05, 0.1, 0.7)

    local x, y, w, h = region:get()
    iml.panel(x, y, w, h, spellId)

    TITLE_FONT = TITLE_FONT or g.getBigFont(16)
    DESC_FONT = DESC_FONT or g.getSmallFont(16)
    COST_FONT = COST_FONT or g.getSmallFont(16)

    local box = ui.Box({maxWidth = w, padding = 10, spacing = 6}, function(bx, by, bw, bh)
        love.graphics.setColor(1, 1, 1)
        helper.gradientRect("vertical", bgCol1, darkCol, x, y, w, h)
        love.graphics.setColor(borderCol:getRGBA())
        ui.drawPanel(x, y, w, h)
    end)

    -- Header: icon + name
    local iconSize = 28
    local iconGap = 8
    box:add({
        getHeight = function(innerW)
            return math.max(iconSize, TITLE_FONT:getHeight())
        end,
        draw = function(ex, ey, ew, eh)
            love.graphics.setColor(1, 1, 1)
            if info.icon and g.isImage(info.icon) then
                g.drawImageContained(info.icon, ex, ey, iconSize, iconSize)
            end
            local textX = ex + iconSize + iconGap
            local textW = ew - iconSize - iconGap
            love.graphics.setFont(TITLE_FONT)
            local name = "{c r=0.6 g=0.7 b=1}{wavy amp=0.5 freq=1}" .. info.name
            richtext.printRich(name, TITLE_FONT, textX, ey, textW, "left")
        end,
    })

    -- Mana cost + cooldown row
    box:add({
        getHeight = function() return COST_FONT:getHeight() end,
        draw = function(ex, ey, ew, eh)
            love.graphics.setFont(COST_FONT)
            love.graphics.setColor(1, 1, 1)
            g.drawManaCost(info.cost, ex + ew / 2, ey + eh / 2, ew)
            if info.cooldown and info.cooldown > 0 then
                local cdText = "{c r=0.7 g=0.7 b=0.7}" .. LOC_CD({n = info.cooldown})
                richtext.printRich(cdText, COST_FONT, ex, ey, ew, "center")
            end
        end,
    })

    -- Description
    box:addText("{c r=0.7 g=0.7 b=0.75}" .. info.description, DESC_FONT)

    box:render(x, y)

    if iml.wasJustClicked(x, y, w, h, 1, spellId) then
        g.playUISound("ui_click_basic", 1.4, 0.8)
        return true
    end
    return false
end

return drawSpellCard
