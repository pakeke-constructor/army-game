

--[[

squad-card:
A representation of a squad, it's stats, traits + perks.


CARD UI: Vertical card. Title at top.
Border = same color as rarity.
Background = black with a small fade towards rarity-color; but mostly dark.

<CARD LAYOUT>
Icon (squad.icon), Title (white-text)
Layout of Traits (use ui.drawTraitBox). Should be DIRECTLY below title.

On it's own line: Unit count, x6, x4

A 3x2 grid of stats:
- health
- damage
- attackSpeed
- armor
- speed
- attackRange

List of perks below:
<perk>
perk title (+ rarity color)
perk description (richtext)
</perk>

<perk>
...
</perk>



</CARD LAYOUT>

]]


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

-- PSEUDOCODE:
-- 1. Read squad + entity def, pick rarity colors.
-- 2. Draw background + border, build padded content region.
-- 3. Split layout into header, traits, count, stats, perks.
-- 4. Draw icon/title, trait boxes, count line, stat grid, perks list.
-- 5. Handle click and return.
---Draw a single squad card in a kirigami region. Returns true if clicked.
---@param squadId string
---@param region kirigami.Region
---@return boolean
local function drawSquadCard(squadId, region)
    ui.assertUIStarted()

    local info = g.getSquadInfo(squadId)
    local def = g.getEntityDef(info.entityId)
    local rarity = g.RARITIES.COMMON
    local borderCol = rarity.color
    local bgCol1 = objects.Color(0.05, 0.05, 0.06)
    local bgCol2 = borderCol * 0.12

    local x, y, w, h = region:get()
    iml.panel(x, y, w, h, squadId)

    love.graphics.setColor(1, 1, 1)
    helper.gradientRect("vertical", bgCol1, bgCol2, x, y, w, h)
    love.graphics.setColor(borderCol:getRGBA())
    ui.drawPanel(x, y, w, h)

    local pad = 6
    local content = region:padUnit(pad)
    local header = content:splitVertical(0.22, 0.78)

    STAT_FONT = STAT_FONT or g.getSmallFont(16)
    TITLE_FONT = TITLE_FONT or g.getSmallFont(16)

    do
        local iconR, titleR = header:splitHorizontal(0.28, 0.72)
        local ix, iy, iw, ih = iconR:padRatio(0.2):get()
        g.drawImageContained(info.icon, ix, iy, iw, ih)

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(TITLE_FONT)
        local tx, ty, tw, th = titleR:get()
        richtext.printRich(squadId, TITLE_FONT, tx, ty + th / 2 - TITLE_FONT:getHeight() / 2, tw, "left")
    end

    local body = select(2, content:splitVertical(0.22, 0.78))
    local traitsR, countR, statsR, perksR = helper.splitRegionByExactSizes(body, "vertical", 18, 16, 54, 0)

    do
        local traits = info.traits or {}
        local tx = traitsR.x
        local ty = traitsR.y
        for i = 1, #traits do
            local trait = g.TRAITS[traits[i]]
            if trait then
                local w2, h2 = ui.drawTraitBox(trait, tx, ty)
                tx = tx + w2 + 4
            end
        end
    end

    do
        local font = STAT_FONT
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(font)
        local cx, cy, cw, ch = countR:get()
        local txt = "x" .. tostring(info.count)
        richtext.printRich(txt, font, cx, cy + ch / 2 - font:getHeight() / 2, cw, "left")
    end

    do
        local grid = statsR:grid(2, 3)
        for i = 1, #STAT_LIST do
            local cell = grid[i]
            local stat = g.getStatInfo(STAT_LIST[i].id)
            local value = def and def[stat.baseName] or 0
            local label = STAT_LIST[i].label

            local cx, cy, cw, ch = cell:get()
            local left = cell:padUnit(2)
            local iconR, textR = left:splitHorizontal(0.25, 0.75)
            if stat.icon and g.isImage(stat.icon) then
                local ix, iy, iw, ih = iconR:padRatio(0.2):get()
                love.graphics.setColor(1, 1, 1)
                g.drawImageContained(stat.icon, ix, iy, iw, ih)
            end
            love.graphics.setFont(STAT_FONT)
            love.graphics.setColor(1, 1, 1)
            local tx, ty, tw, th = textR:get()
            richtext.printRich(label .. " " .. tostring(value), STAT_FONT, tx, ty + th / 2 - STAT_FONT:getHeight() / 2, tw, "left")
        end
    end

    do
        local box = ui.Box({maxWidth = perksR.w, padding = 4, spacing = 2})
        local perks = info.perks or {}
        for i = 1, #perks do
            local perkInfo = g.getPerkInfo(perks[i])
            if perkInfo then
                local r, g2, b, a = borderCol:getRGBA()
                local title = string.format("{c r=%s g=%s b=%s a=%s}%s{/c}", r, g2, b, a, perkInfo.id)
                box:addText(title, TITLE_FONT)
                if perkInfo.desc then
                    box:addText(perkInfo.desc, STAT_FONT)
                end
                if i < #perks then
                    box:addSpacing(2)
                end
            end
        end
        if #perks > 0 then
            box:render(perksR.x, perksR.y)
        end
    end

    if iml.wasJustClicked(x, y, w, h, 1, squadId) then
        if g.playUISound then
            g.playUISound("ui_click_basic", 1.4, 0.8)
        end
        return true
    end
    return false
end

return drawSquadCard
