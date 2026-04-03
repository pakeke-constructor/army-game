
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

local function addPerk(box, perk)
    -- TODO: fill in later
end

---Draw a single squad card in a kirigami region. Returns true if clicked.
---@param squadId string
---@param region kirigami.Region
---@return boolean
local function drawSquadCard(squadId, region)
    ui.assertUIStarted()

    local info = g.getSquadInfo(squadId)
    local def = g.getEntityDef(info.entityId)
    local rarity = info.rarity or g.RARITIES.COMMON
    local darkCol = rarity.darkColor
    local liteCol = rarity.color
    local bgCol1 = objects.Color(0.05, 0.05, 0.06, 0.7)

    local x, y, w, h = region:get()
    iml.panel(x, y, w, h, squadId)

    STAT_FONT = STAT_FONT or g.getSmallFont(16)
    TITLE_FONT = TITLE_FONT or g.getBigFont(16)

    local box = ui.Box({maxWidth = w, padding = 12, spacing = 4}, function(bx, by, bw, bh)
        love.graphics.setColor(1, 1, 1)
        helper.gradientRect("vertical", bgCol1, darkCol, x, y, w, h)
        love.graphics.setColor(liteCol:getRGBA())
        ui.drawPanel(x, y, w, h)
    end)

    -- Header: icon + name + traits
    local iconSize = 32
    box:add({
        getHeight = function() return iconSize end,
        draw = function(ex, ey, ew, eh)
            -- icon
            love.graphics.setColor(1, 1, 1)
            g.drawImageContained(info.icon, ex, ey, iconSize, iconSize)
            -- name
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(TITLE_FONT)
            local nameX = ex + iconSize + 10
            local name = "{wavy amp=0.5 freq=1}" .. info.name
            richtext.printRich(name, TITLE_FONT, nameX, ey + eh / 2 - TITLE_FONT:getHeight() / 2, ew - iconSize - 4, "left")
        end,
    })

    -- Traits row
    local traits = def.traits or {}
    if #traits > 0 then
        box:add({
            getHeight = function() return STAT_FONT:getHeight() + 8 end,
            draw = function(ex, ey, ew, eh)
                local tx = ex
                for i, trait in ipairs(traits)do
                    local tw, th = ui.drawTraitBox(trait, tx, ey)
                    tx = tx + tw + 4
                end
            end,
        })
    end

    -- Count line
    box:add({
        getHeight = function() return STAT_FONT:getHeight() end,
        draw = function(ex, ey, ew, eh)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(STAT_FONT)
            richtext.printRich("x" .. tostring(info.count), STAT_FONT, ex, ey, ew, "left")
        end,
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

    box:render(x, y)

    if iml.wasJustClicked(x, y, w, h, 1, squadId) then
        g.playUISound("ui_click_basic", 1.4, 0.8)
        return true
    end
    return false
end

return drawSquadCard
