
local STAT_LIST = {
    {id = "maxHealth", label = "HP"},
    {id = "attackDamage", label = "DMG"},
    {id = "attackSpeed", label = "AS"},
    {id = "armor", label = "ARM"},
    {id = "moveSpeed", label = "SPD"},
    {id = "attackRange", label = "RNG"},
}

local STAT_FONT = nil
local TITLE_FONT = nil

local PERK_FONT = nil
local PERK_DESC_FONT = nil

local function addPerk(box, perk)
    PERK_FONT = PERK_FONT or g.getBigFont(16)
    PERK_DESC_FONT = PERK_DESC_FONT or g.getSmallFont(16)
    local iconSize = 20
    local gap = 6
    -- icon + title row (centered)
    box:add({
        getHeight = function() return iconSize end,
        draw = function(ex, ey, ew, eh)
            local textW = PERK_FONT:getWidth(perk.name)
            local totalW = iconSize + gap + textW
            local sx = ex + (ew - totalW) / 2
            love.graphics.setColor(1, 1, 1)
            if perk.image and g.isImage(perk.image) then
                g.drawImageContained(perk.image, sx, ey, iconSize, iconSize)
            end
            love.graphics.setFont(PERK_FONT)
            love.graphics.setColor(0.9, 0.85, 0.6)
            love.graphics.print(perk.name, sx + iconSize + gap, ey + iconSize / 2 - PERK_FONT:getHeight() / 2)
        end,
    })
    -- description row
    box:add({
        getHeight = function(innerW)
            love.graphics.setFont(PERK_DESC_FONT)
            local _, lines = PERK_DESC_FONT:getWrap(perk.description, innerW)
            return #lines * PERK_DESC_FONT:getHeight()
        end,
        draw = function(ex, ey, ew, eh)
            love.graphics.setFont(PERK_DESC_FONT)
            love.graphics.setColor(0.7, 0.7, 0.75)
            love.graphics.printf(perk.description, ex, ey, ew, "center")
        end,
    })
end

---Draw a single squad card in a kirigami region. Returns true if clicked.
---@param squadId string
---@param region kirigami.Region
---@param index number
---@return boolean
---@return number
---@return number
local function drawSquadCard(squadId, region, index)
    ui.assertUIStarted()

    local info = g.getSquadInfo(squadId)
    local def = g.getEntityDef(info.entityId)
    local rarity = info.rarity or g.RARITIES.COMMON
    local darkCol = rarity.darkColor
    local liteCol = rarity.lightColor
    local col = rarity.color
    local bgCol1 = objects.Color(0.05, 0.05, 0.06, 0.7)

    local x, y, w, h = region:get()
    local uid = squadId .. "_" .. index
    iml.panel(x, y, w, h, uid)

    local isHovered = iml.isHovered(x,y,w,h, uid)
    if isHovered then
        darkCol = darkCol:lerp(col, 0.25)
    end

    STAT_FONT = STAT_FONT or g.getSmallFont(16)
    TITLE_FONT = TITLE_FONT or g.getBigFont(16)

    local box = ui.Box({maxWidth = w, padding = 12, spacing = 8}, function(bx, by, bw, bh)
        love.graphics.setColor(0,0,0)
        ui.drawPanel(x-3,y-3, w+6,h+6)
        love.graphics.setColor(1,1,1)
        helper.gradientRect("vertical", bgCol1, darkCol, x,y,w,h)
        ui.drawPanel(x,y,w,h)
        helper.gradientRectStencil("vertical", liteCol, col, x,y,w,h, function()
            ui.drawPanel(x,y,w,h)
        end)
    end)

    -- Header: icon on left, name on right
    local iconSize = 32
    local iconGap = 10
    box:add({
        getHeight = function(innerW)
            return math.max(iconSize, TITLE_FONT:getHeight())
        end,
        draw = function(ex, ey, ew, eh)
            -- icon
            love.graphics.setColor(1, 1, 1)
            g.drawSquadIcon(squadId, ex, ey, iconSize, iconSize)
            -- name to right of icon
            local textX = ex + iconSize + iconGap
            local textW = ew - iconSize - iconGap

            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(TITLE_FONT)
            local name = "{c r=0.8 g=0.8 b=0.85}{wavy amp=0.5 freq=1}" .. info.name
            richtext.printRich(name, TITLE_FONT, textX, ey, textW, "left")
        end,
    })

    -- squad-units: Layed out in a flat horizontal line.
    local unitGap = 2
    local unitWidth, unitHeight = g.getUnitDrawSize(info.entityId)
    box:add({
        getHeight = function() return unitHeight + 4 end,
        draw = function(ex, ey, ew, eh)
            if unitHeight == 0 then return end
            local count = info.count or 1
            local totalW = count * unitWidth + (count - 1) * unitGap
            local startX = ex + (ew - totalW) / 2
            local r,gg,b,a = darkCol:getRGBA()
            love.graphics.setColor(r, gg, b, a * 0.6)
            ui.drawSingleColorPanel(startX - 4, ey, totalW + 8, eh)
            love.graphics.setColor(1, 1, 1, 0.85)
            for i = 1, count do
                local ux = startX + (i - 1) * (unitWidth + unitGap)
                g.drawUnit(info.entityId, ux, ey + 2, unitWidth, unitHeight)
            end
        end
    })

    -- Stats: 3 wide, 2 high grid
    local statCellH = 22
    local statRows = 2
    local statCols = 3
    box:add({
        getHeight = function() return statCellH * statRows end,
        draw = function(ex, ey, ew, eh)
            local cellW = math.floor(ew / statCols)
            for i = 1, #STAT_LIST do
                local row = math.floor((i - 1) / statCols)
                local col = (i - 1) % statCols
                local cx = ex + col * cellW
                local cy = ey + row * statCellH
                local cw = cellW - 2
                local ch = statCellH - 2

                local statId = STAT_LIST[i].id
                local stat = g.getStatInfo(statId)
                local value = def and def[stat.baseName] or 0

                -- background
                local important = g.isStatImportant(statId, info.entityId)
                local alpha = 0.3
                if important then
                    alpha = 1
                end

                do
                local r,g,b,a = darkCol:getRGBA()
                love.graphics.setColor(r,g,b,a*alpha)
                ui.drawSingleColorPanel(cx, cy, cw, ch)
                end

                -- icon
                if stat.icon and g.isImage(stat.icon) then
                    love.graphics.setColor(1, 1, 1, alpha)
                    g.drawImageContained(stat.icon, cx + 2, cy + 2, ch - 4, ch - 4)
                end

                -- text
                do
                love.graphics.setFont(STAT_FONT)
                local r,g,b,a = stat.color:getRGBA()
                love.graphics.setColor(r,g,b,a*alpha)
                local textX = cx + ch
                richtext.printRich(tostring(value), STAT_FONT, textX, cy + ch / 2 - STAT_FONT:getHeight() / 2, cw - ch, "left")
                end
            end
        end,
    })

    -- Perks
    local perks = info.perks or {}
    for i = 1, #perks do
        local perkInfo = g.getPerkInfo(perks[i])
        if perkInfo then
            addPerk(box, perkInfo)
        end
    end

    local ww,hh = box:render(x, y)

    -- Mana cost beads (bottom center)
    local cost = info.cost
    if cost then
        local rw, rh = region.w, region.h
        lg.setColor(1, 1, 1)
        local www = g.getManaCostWidth(cost)
        local H=30
        ui.drawDarkPanel(x+rw/2 - www/2 - 6, y+rh-H/2, www + 12,H)
        g.drawManaCost(cost, x + rw / 2, y + rh, rw/2)
    end

    if iml.wasJustClicked(x, y, w, h, 1, uid) then
        g.playUISound("ui_click_basic", 1.4, 0.8)
        return true, ww,hh
    end
    return false, ww,hh
end

return drawSquadCard
