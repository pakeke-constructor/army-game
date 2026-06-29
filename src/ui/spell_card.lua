
local TRAIL_COUNT = {
    RARE = 3,
    LEGENDARY = 6
}

local RADIUS_TEXT = interp("{range}Range: {c r=0.773 g=0.188 b=0.239}%{spellRange}{/c}", {
    context = "The range of a spell.",
})
local TEXT_COLOR = {0.8, 0.8, 0.85} -- Note: This is not aligned to palette

---@param spellId string
---@param region kirigami.Region
---@param index number
return function(spellId, region, index)
    ui.assertUIStarted()

    local info = g.getSpellInfo(spellId)
    local manaColor = g.getManaBundleColor(info.cost)
    local frameDarkColor = manaColor:lerp(objects.Color.BLACK, 0.65)
    local panelBottomColor = manaColor:lerp(objects.Color.BLACK, 0.65)
    local frameLightColor = manaColor:lerp(objects.Color.WHITE, 0.25)
    local panelTopColor = objects.Color(0.05, 0.05, 0.06, 0.9)

    local x, y, w, h = region:get()
    local uid = spellId.."_"..index
    local hitX, hitY = x, y

    local isHovered = iml.isHovered(x,y,w,h, uid)
    if isHovered then
        frameDarkColor = frameDarkColor:lerp(manaColor, 0.10)
        y = y - 3
        region = region:moveUnit(0, -3)
    end
    iml.panel(hitX, hitY, w, h, uid)

    STAT_FONT = STAT_FONT or g.getSmallFont(16)
    TITLE_FONT = TITLE_FONT or g.getBigFont(16)

    local box = ui.Box({maxWidth = w, maxHeight = h, padding = 12, spacing = 0}, function(bx, by, bw, bh)
        if TRAIL_COUNT[info.rarity.id] then
            helper.rotatingGlow(region:padRatio(0.2), {
                count = TRAIL_COUNT[info.rarity.id],
                offset = (index - 1) * 1.37,
                glowScale = 100,
                rps = 1,
                wobbleFreq = 0.1,
                wobbleAmp = 10,
                color = info.rarity.color,
            })
        end

        love.graphics.setColor(0,0,0)
        ui.drawPanel(x-3,y-3, w+6,h+6)
        love.graphics.setColor(1,1,1)
        helper.gradientRect("vertical", panelTopColor, frameDarkColor, x,y,w,h)
        ui.drawPanel(x,y,w,h)
        helper.gradientRectStencil("vertical", frameLightColor, manaColor, x,y,w,h, function()
            ui.drawPanel(x,y,w,h)
        end)
    end)

    -- Header: icon on left, name on right
    local iconSize = 32
    local iconGap = 10
    box:add({
        getHeight = function(innerW)
            return math.max(iconSize, TITLE_FONT:getHeight() * 3)
        end,
        draw = function(ex, ey, ew, eh)
            -- icon
            love.graphics.setColor(1, 1, 1)
            g.renderSpellIcon(spellId, ex+16, ey+16, true)
            -- name to right of icon
            local textX = ex + iconSize + iconGap
            local textW = ew - iconSize - iconGap

            love.graphics.setColor(TEXT_COLOR)
            local name = "{bob amp=0.5}{o}"..info.name
            richtext.printRichContainedNoWrap(name, TITLE_FONT, textX, ey, textW, TITLE_FONT:getHeight(), "left")

            -- Rarity
            local rarity = info.rarity
            love.graphics.setColor(rarity.color)
            local rarityText = rarity.lightTextEffect..rarity.name
            richtext.printRichContainedNoWrap("{o}"..rarityText, STAT_FONT, textX, ey + 16, textW, STAT_FONT:getHeight(), "left")

            -- Radius
            love.graphics.setColor(TEXT_COLOR)
            local radiusText = RADIUS_TEXT(info)
            richtext.printRichContainedNoWrap("{o}"..radiusText, STAT_FONT, textX, ey + 32, textW, STAT_FONT:getHeight(), "left")
        end,
    })

    -- Description
    if info.description then
        box:addSpacing(8)
        box:addFill({
            getHeight = function() return 0 end,
            draw = function(ex, ey, ew, eh)
                richtext.printRichContained(
                    -- Note: Not aligned to palette
                    "{c r=0.85 g=0.85 b=0.9}"..info.description,
                    STAT_FONT,
                    ex, ey, ew, eh, 1, "left"
                )
            end,
        })
    end


    local ret = false
    if iml.wasJustClicked(hitX, hitY, w, h, 1, uid) then
        g.playUISound("ui_click_basic", 1.4, 0.8)
        ret = true
    end

    local ww, hh = box:render(x, y)

    -- Mana cost beads (bottom center)
    local cost = info.cost
    if cost then
        local rw, rh = region.w, region.h
        lg.setColor(1, 1, 1)
        local _, www = g.getManaCostWidth(cost)
        local H=30
        ui.drawDarkPanel(x+rw/2 - www/2 - 6, y+rh-H/2, www + 12,H)
        g.drawManaCostLarge(cost, x + rw / 2, y + rh, rw/2)
    end

    return ret, ww, hh
end
