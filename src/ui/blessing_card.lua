
local TITLE_FONT = nil
local DESC_FONT = nil

---Draw a blessing card in a kirigami region. Returns true if clicked.
---@param blessingId string
---@param region kirigami.Region
---@return boolean
local function drawBlessingCard(blessingId, region)
    ui.assertUIStarted()

    local info = g.getBlessingInfo(blessingId)
    local rarity = info.rarity or g.RARITIES.COMMON
    local darkCol = rarity.darkColor
    local liteCol = rarity.color
    local bgCol1 = objects.Color(0.05, 0.05, 0.06, 0.7)

    local x, y, w, h = region:get()
    iml.panel(x, y, w, h, blessingId)

    TITLE_FONT = TITLE_FONT or g.getBigFont(16)
    DESC_FONT = DESC_FONT or g.getSmallFont(16)

    local box = ui.Box({maxWidth = w, padding = 12, spacing = 6}, function(bx, by, bw, bh)
        love.graphics.setColor(1, 1, 1)
        helper.gradientRect("vertical", bgCol1, darkCol, x, y, w, h)
        love.graphics.setColor(liteCol:getRGBA())
        ui.drawPanel(x, y, w, h)
    end)

    -- Header: icon on left, name on right
    local iconSize = 32
    local iconGap = 10
    box:add({
        getHeight = function(innerW)
            return math.max(iconSize, TITLE_FONT:getHeight())
        end,
        draw = function(ex, ey, ew, eh)
            love.graphics.setColor(1, 1, 1)
            g.drawImageContained(info.image, ex, ey, iconSize, iconSize)
            local textX = ex + iconSize + iconGap
            local textW = ew - iconSize - iconGap
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(TITLE_FONT)
            local name = "{c r=0.8 g=0.8 b=0.85}{wavy amp=0.5 freq=1}" .. info.name
            richtext.printRich(name, TITLE_FONT, textX, ey, textW, "left")
        end,
    })

    -- Description
    box:addText("{c r=0.7 g=0.7 b=0.75}" .. info.description, DESC_FONT)

    box:render(x, y)

    if iml.wasJustClicked(x, y, w, h, 1, blessingId) then
        g.playUISound("ui_click_basic", 1.4, 0.8)
        return true
    end
    return false
end

return drawBlessingCard
