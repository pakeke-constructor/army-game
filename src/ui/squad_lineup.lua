local FONT = nil
local COST_FONT = nil


---@param squad g.Squad
---@param x number
---@param y number
---@param idSuffix string
---@return boolean
local function drawSquadEntry(squad, x,y, idSuffix)
    FONT = FONT or g.getBigFont(16)
    COST_FONT = COST_FONT or g.getSmallFont(16)

    local info = g.getSquadInfo(squad.squadId)
    local rarity = info.rarity or g.RARITIES.COMMON
    local col = rarity.color
    local darkCol = rarity.darkColor

    local id = squad.squadId .. idSuffix
    local SZ = 18
    local xx,yy,ww,hh = x-SZ/2, y-SZ/2, SZ, SZ
    iml.panel(xx,yy,ww,hh, id)

    local isHovered = iml.isHovered(xx,yy,ww,hh, id)
    local canAfford = squad.inLineup or g.canAffordSquad(squad)

    local alpha = (canAfford or squad.inLineup) and 1 or 0.35
    if isHovered and canAfford then
        darkCol = darkCol:lerp(col, 0.25)
    end

    -- icon
    local iconPad = 4
    local iconSize = math.min(ww - iconPad * 2, hh * 0.6)
    local ix = x + (ww - iconSize) / 2
    local iy = y + iconPad
    love.graphics.setColor(1, 1, 1, alpha)
    g.drawSquadIcon(squad.squadId, ix, iy)

    -- mana cost (bottom, same style as squad_card)
    local cost = info.cost
    if cost then
        local costStr = g.manaCostString(cost)
        if #costStr > 0 then
            local costW = richtext.getWidth(costStr, COST_FONT) + 8
            local costH = COST_FONT:getHeight() + 6
            local cx = math.floor(x + ww / 2 - costW / 2)
            local cy = math.floor(y + hh - costH / 2)
            local cr = Kirigami(cx, cy, costW, costH)
            love.graphics.setColor(1, 1, 1, alpha)
            ui.drawDarkPanel(cr:padUnit(-2, 0):get())
            love.graphics.setColor(1, 1, 1, alpha)
            richtext.printRich(costStr, COST_FONT, cr.x, cr.y + 3, costW, "left")
        end
    end

    if iml.wasJustClicked(xx,yy, ww, hh, 1, id) then
        return true
    end
    return false
end

local function drawManaBar(region)
    COST_FONT = COST_FONT or g.getSmallFont(16)
    local x, y, w, h = region:get()
    iml.panel(region:get())
    ui.drawDarkPanel(x, y, w, h)

    local manaTypes = g.getManaTypes()
    local visible = {}
    for _, mt in ipairs(manaTypes) do
        local maxMana, manaInfo = g.getManaInfo(mt)
        if maxMana > 0 then
            -- compute used
            local used = 0
            for _, sq in ipairs(g.getLineup()) do
                local cost = g.getSquadInfo(sq.squadId).cost
                if cost[mt] then used = used + cost[mt] end
            end
            visible[#visible + 1] = {used = used, max = maxMana, info = manaInfo, id = mt}
        end
    end

    if #visible == 0 then return end

    local cellW = math.floor(w / #visible)
    local font = COST_FONT
    local fh = font:getHeight()
    for i, v in ipairs(visible) do
        local cx = x + (i - 1) * cellW
        local iconSize = h - 4
        -- icon
        love.graphics.setColor(1, 1, 1)
        if v.info.image and g.isImage(v.info.image) then
            g.drawImageContained(v.info.image, cx + 4, y + 2, iconSize, iconSize)
        end
        -- text: used/max
        local textX = cx + iconSize + 8
        local textCol = v.info.color or objects.Color(1, 1, 1)
        local full = v.used >= v.max
        local colTag = full and "{c r=1 g=0.3 b=0.3}" or ("{c r=" .. textCol.r .. " g=" .. textCol.g .. " b=" .. textCol.b .. "}")
        local str = colTag .. v.used .. "/" .. v.max
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1)
        richtext.printRich(str, font, textX, y + h / 2 - fh / 2, cellW - iconSize - 12, "left")
    end
end

---@param region kirigami.Region
local function drawSquadLineUp(region)
    ui.assertUIStarted()

    local manaBar, lineup, bench = region:splitVertical(1, 3, 6)

    -- Top: current lineup
    local lineupSquads = g.getLineup()
    do
        local r = lineup:padUnit(4)
        ui.drawDarkPanel(r:get())
        if #lineupSquads > 0 then
            local cells = r:padUnit(4):grid(math.max(#lineupSquads, 1), 1)
            for i, squad in ipairs(lineupSquads) do
                local x,y = cells[i]:getCenter()
                if drawSquadEntry(squad, x,y, "_lineup_" .. i) then
                    g.setSquadActive(squad, false)
                end
            end
        end
    end

    -- Middle: mana budget
    drawManaBar(manaBar:padUnit(4))

    -- Bottom: bench (all non-lineup squads)
    local allSquads = g.getArmy()
    local benchSquads = {}
    for _, squad in ipairs(allSquads) do
        if not squad.inLineup then
            benchSquads[#benchSquads + 1] = squad
        end
    end
    do
        local r = bench:padUnit(4)
        ui.drawDarkPanel(r:get())
        if #benchSquads > 0 then
            local padded = r:padUnit(4)
            local cols, rows = helper.getBestFitDimensions(#benchSquads, padded.w, padded.h)
            local cells = padded:grid(cols, rows)
            for i, squad in ipairs(benchSquads) do
                local x,y = cells[i]:getCenter()
                if drawSquadEntry(squad, x,y, "_bench_" .. i) then
                    g.setSquadActive(squad, true)
                end
            end
        end
    end
end

return drawSquadLineUp
