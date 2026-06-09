
local TITLE_FONT = nil
local DESC_FONT = nil

local BLESSING_CARD_BG = objects.Color("#111111")
local GRADIENT_CIRCLE = helper.gradientCircleMesh()

---Draw a blessing card in a kirigami region. Returns true if clicked.
---@param blessingId string
---@param region kirigami.Region
---@param index integer
---@return boolean
---@return number
---@return number
local function drawBlessingCard(blessingId, region, index)
    ui.assertUIStarted()

    local info = g.getBlessingInfo(blessingId)
    local rarity = info.rarity or g.RARITIES.COMMON
    local darkCol = rarity.darkColor
    local liteCol = rarity.color
    local bgCol1 = objects.Color(0.05, 0.05, 0.06)
    local uid = blessingId .. "_" .. index

    local x, y, w, h = region:get()
    local isHovered = false

    TITLE_FONT = TITLE_FONT or g.getBigFont(16)
    DESC_FONT = DESC_FONT or g.getSmallFont(16)


    local box = ui.Box({maxWidth = w, maxHeight = h, padding = 12, spacing = 6}, function(bx, by, bw, bh)
        iml.panel(bx,by,bw,bh, uid)
        isHovered = iml.isHovered(bx,by, bw,bh, uid)
        if isHovered then
            darkCol = darkCol:lerp(liteCol, 0.25)
        end
        love.graphics.setColor(BLESSING_CARD_BG)
        love.graphics.rectangle("fill", bx, by, bw, bh)
        love.graphics.setColor(liteCol[1], liteCol[2], liteCol[3], liteCol[4] * 0.67)
        love.graphics.draw(GRADIENT_CIRCLE, bx + bw / 2, by + bh / 2, 0, math.min(bw, bh))
        love.graphics.setColor(liteCol:getRGBA())
        ui.drawPanelThin(bx-3, by-3, bw+6, bh+6)
    end)

    -- Header: icon on left, name on right
    local iconSize = 24
    local iconGap = 10
    box:add({
        getHeight = function(innerW)
            return math.max(iconSize, TITLE_FONT:getHeight())
        end,
        draw = function(ex, ey, ew, eh)
            love.graphics.setColor(1, 1, 1)
            g.drawBlessingIcon(info.id, ex + iconSize / 2, ey + iconSize / 2)

            local textX = ex + iconSize + iconGap
            local textW = ew - iconSize - iconGap
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(TITLE_FONT)
            local name = "{c r=0.9 g=0.9 b=0.95}{wavy amp=0.5 freq=1}" .. info.name
            richtext.printRich(name, TITLE_FONT, textX, ey, textW, "left")
        end,
    })

    -- Description
    box:addText("{c r=0.85 g=0.85 b=0.9}" .. info.description, DESC_FONT)

    -- Spacer to fill remaining height so card is always full region height.
    box:addFill({
        getHeight = function() return 0 end,
        draw = function() end,
    })

    local ww,hh = box:render(x, y)

    if iml.wasJustClicked(x, y, w, h, 1, uid) then
        g.playUISound("ui_click_basic", 1.4, 0.8)
        return true, ww,hh
    end
    return false, ww,hh
end

return drawBlessingCard
