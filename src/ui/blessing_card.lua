
local TITLE_FONT = nil
local DESC_FONT = nil

local BLESSING_CARD_BG = objects.Color("#111111")
local GRADIENT_CIRCLE = helper.gradientCircleMesh()

---@class blessingCard.rotatingGlow.args
---@field count integer?
---@field offset number?
---@field glowScale number?
---@field rps number?
---@field wobbleFreq number?
---@field wobbleAmp number?
---@field color [number, number, number]?

---@param reg kirigami.Region
---@param args blessingCard.rotatingGlow.args?
local function rotatingGlow(reg, args)
    local offset = args and args.offset or 0
    local glowScale = args and args.glowScale or 1
    local rps = args and args.rps or math.pi / 4
    local wobbleFreq = args and args.wobbleFreq or 0
    local wobbleAmp = args and args.wobbleAmp or 0
    local glowCount = args and args.count or 4
    local color = args and args.color or {1, 1, 1}

    local x,y,w,h = reg:get()
    local cx,cy = x + w/2, y + h/2
    local t = love.timer.getTime()

    local rx = w / 2
    local ry = h / 2

    for i = 1, glowCount do
        local phase = ((i - 1) / glowCount) * consts.TAU + offset
        local wobble = math.sin(t * wobbleFreq + phase) * wobbleAmp
        local angle = t * rps * (0.6 + offset * 0.1) + phase

        local px = cx + rx * math.cos(angle)
        local py = cy + ry * math.sin(angle)
        local tx = -rx * math.sin(angle)
        local ty = ry * math.cos(angle)
        local tl = helper.magnitude(tx, ty)

        px = px + ty / tl * wobble
        py = py - tx / tl * wobble

        helper.drawGlow(px, py, color, glowScale, {
            pulseFrequency = consts.TAU / 3,
            pulseAmplitude = glowScale * 0.1,
            pulseOffset = offset,
        })
    end
end

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
    local uid = blessingId .. "_" .. index

    local x, y, w, h = region:get()

    TITLE_FONT = TITLE_FONT or g.getBigFont(16)
    DESC_FONT = DESC_FONT or g.getSmallFont(16)


    local box = ui.Box({maxWidth = w, maxHeight = h, padding = 12, spacing = 6}, function(bx, by, bw, bh)
        --iml.panel(bx,by,bw,bh, uid)
        local rc = rarity.color
        rotatingGlow(Kirigami(bx, by, bw, bh):padRatio(0.25), {
            count = 3,
            offset = (index - 1) * 1.37,
            glowScale = 100,
            rps = 1,
            wobbleFreq = 0.1,
            wobbleAmp = 10,
            color = {rc[1], rc[2], rc[3]},
        })

        local isHovered = iml.isHovered(bx,by, bw,bh, uid)
        love.graphics.setColor(isHovered and darkCol:darken(0.3) or BLESSING_CARD_BG)
        love.graphics.rectangle("fill", bx, by, bw, bh)
        love.graphics.setColor(liteCol[1], liteCol[2], liteCol[3], liteCol[4] * 0.5)
        love.graphics.draw(GRADIENT_CIRCLE, bx + bw / 2, by + bh / 2, 0, math.min(bw, bh))
        love.graphics.setColor(liteCol:getRGBA())
        ui.drawPanelThin(bx-3, by-3, bw+6, bh+6)
    end)

    -- Header: icon on left, name on right
    local iconSize = 24
    local iconGap = 4
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
            local name = "{c r=0.9 g=0.9 b=0.95}{bob amp=0.5 freq=1}" .. info.name
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
