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
    local SZ = 24
    local xx,yy,ww,hh = x-SZ/2, y-SZ/2, SZ,SZ
    iml.panel(xx,yy,ww,hh, id)

    local isHovered = iml.isHovered(xx,yy,ww,hh, id)
    if isHovered then
        darkCol = darkCol:lerp(col, 0.25)
    end

    -- icon
    local iconPad = 4
    local iconSize = math.min(ww - iconPad * 2, hh * 0.6)
    love.graphics.setColor(1, 1, 1)
    g.drawSquadIcon(squad.squadId, x, y)

    -- mana cost beads (bottom center)
    local cost = info.cost
    if cost then
        love.graphics.setColor(1, 1, 1)
        g.drawManaCost(cost, xx + ww / 2, yy + hh + 4, SZ*2)
    end

    if iml.wasJustClicked(xx,yy, ww, hh, 1, id) then
        return true
    end
    return false
end



---@param region kirigami.Region
local function drawSquadLineUp(region)
    ui.assertUIStarted()

    -- draw faded bg:
    lg.setColor(0.1,0.1,0.2,0.7)
    lg.rectangle("fill", region:padRatio(-1):get())
    lg.setColor(1,1,1)
    iml.panel(region:get())

    local lineup, bench = region:splitVertical(3, 6)

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
