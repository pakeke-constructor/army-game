
local hoverService = require("src.hud.hoverService")

local TRAIL_COUNT = {
    RARE = 3,
    LEGENDARY = 6
}

local RANGE_NAME = loc("Spell Range", {}, {
    context = "Name of spell range stat."})
local RANGE_DESC = loc("How far from the cursor the spell reaches.", {}, {
    context = "Description of spell range stat."})
local COOLDOWN_NAME = loc("Spell Cooldown", {}, {
    context = "Name of spell cooldown stat."})
local COOLDOWN_DESC = loc("Seconds before the spell can be cast again.", {}, {
    context = "Description of spell cooldown stat."})
local COOLDOWN_NUM = interp("%{cooldown}s", {
    context = "Spell cooldown text. Cooldown is in seconds."})

local TEXT_COLOR = {0.8, 0.8, 0.85} -- Note: This is not aligned to palette
local PANEL_TOP_COLOR = objects.Color(0.05, 0.05, 0.06, 0.9)

local SPELL_BG_MESH = love.graphics.newMesh({
    -- center
    {0.5, 0.5, 0.5, 0.5, 1, 1, 1, 1},
    -- Top Left
    {0, 0, 0, 0, 1, 1, 1, 1},
    -- Top Right
    {1, 0, 1, 0, 1, 1, 1, 1},
    -- Bottom Right
    {1, 1, 1, 1, 1, 1, 1, 1},
    -- Bottom Left
    {0, 1, 0, 1, 1, 1, 1, 1},
    -- Top Left (again)
    {0, 0, 0, 0, 1, 1, 1, 1},
}, "fan", "stream")

---@param spellId string
---@param region kirigami.Region
---@param index number
return function(spellId, region, index)
    ui.assertUIStarted()

    local info = g.getSpellInfo(spellId)
    local manaColor = info.color
    local frameDarkColor = manaColor:lerp(objects.Color.BLACK, 0.65)
    local frameLightColor = manaColor:lerp(objects.Color.WHITE, 0.25)
    local panelBottomColor = manaColor:lerp(objects.Color.BLACK, 0.65)

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

        SPELL_BG_MESH:setVertices({
            -- center
            {0.5, 0.5, 0.5, 0.5, frameDarkColor:getRGBA()},
            -- Top Left
            {0, 0, 0, 0, frameDarkColor:getRGBA()},
            -- Top Right
            {1, 0, 1, 0, PANEL_TOP_COLOR:getRGBA()},
            -- Bottom Right
            {1, 1, 1, 1, frameDarkColor:getRGBA()},
            -- Bottom Left
            {0, 1, 0, 1, PANEL_TOP_COLOR:getRGBA()},
            -- Top Left (again)
            {0, 0, 0, 0, frameDarkColor:getRGBA()},
        })

        love.graphics.setColor(0,0,0)
        ui.drawPanel(x-3,y-3, w+6,h+6)
        love.graphics.setColor(1,1,1)
        --helper.gradientRect("vertical", PANEL_TOP_COLOR, frameDarkColor, x,y,w,h)
        love.graphics.draw(SPELL_BG_MESH, x + 4, y + 4, 0, w - 8, h - 8)
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
            return math.max(iconSize, TITLE_FONT:getHeight() * 2)
        end,
        draw = function(ex, ey, ew, eh)
            -- icon
            love.graphics.setColor(1, 1, 1)
            g.renderSpellIcon(spellId, ex+16, ey+16)
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
        end,
    })

    box:addSpacing(6)

    -- Stats
    local spellStats = {
        {
            name = RANGE_NAME,
            desc = RANGE_DESC,
            icon = "range",
            color = g.snapToPalette(objects.Color(0.8, 0.5, 0.2)),
            value = g.formatNumber(g.getSpellRange(info)),
        },
        {
            name = COOLDOWN_NAME,
            desc = COOLDOWN_DESC,
            icon = "hourglass_icon",
            color = g.snapToPalette(objects.Color(0.95, 0.85, 0.3)),
            value = COOLDOWN_NUM({
                cooldown = g.formatNumber(g.getSpellCooldown(info))
            }),
        },
    }
    local statCellH = 22
    box:add({
        getHeight = function() return statCellH end,
        draw = function(ex, ey, ew, eh)
            local cellW = math.floor(ew / #spellStats)

            for i = 1, #spellStats do
                local stat = spellStats[i]
                local cx = ex + (i - 1) * cellW
                local cy = ey
                local cw = cellW - 2
                local ch = statCellH - 2
                local alpha = 1

                local px, py = iml.getTransformedPointer()
                local isStatHovered = px >= cx and py >= cy and px <= cx + cw and py <= cy + ch
                if isStatHovered then
                    alpha = 0.75
                    hoverService.requestHover(function(boxx, fonts)
                        local rr, gg, bb = stat.color.r, stat.color.g, stat.color.b
                        boxx:addText(string.format("{c r=%.3f g=%.3f b=%.3f}%s", rr, gg, bb, stat.name), fonts.title)
                        boxx:addText(stat.desc, fonts.body)
                    end)
                end

                local r, gg, b, a = panelBottomColor:getRGBA()
                love.graphics.setColor(r / 4, gg / 4, b / 4)
                ui.drawSingleColorPanel(cx - 3, cy - 3, cw + 6, ch + 6)
                love.graphics.setColor(r, gg, b, a * alpha)
                ui.drawSingleColorPanel(cx, cy, cw, ch)

                if g.isImage(stat.icon) then
                    love.graphics.setColor(1, 1, 1, alpha)
                    g.drawImageContained(stat.icon, cx + 2, cy + 2, ch - 4, ch - 4)
                end

                local sr, sg, sb, sa = stat.color:getRGBA()
                love.graphics.setColor(sr, sg, sb, sa * alpha)
                local textX = cx + ch
                local textY = cy + (ch - STAT_FONT:getHeight()) / 2
                helper.printTextOutline(stat.value, STAT_FONT, 1, textX, textY, cw - ch, "left")
            end
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

    return ret, box:render(x, y)
end
