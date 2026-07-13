
local hoverService = require("src.hud.hoverService")

local STAT_LIST = {
    "maxHealth",
    "DPS", -- special: calculated via (attackDamage x attackSpeed)
    "startingArmor",
    "moveSpeed",
    "attackRange",
    "magic",
}

local STAT_FONT = nil
local TITLE_FONT = nil

local PERK_DESC_FONT = nil


---@param text string
---@param font love.Font
---@param thickness number
---@param r kirigami.Region
---@param align love.AlignMode?
local function printTextOutlineContainedNoWrap(text, font, thickness, r, align)
    local x, y, w, h = r:get()
    local tw = font:getWidth(text)
    local th = font:getHeight()
    local scale = math.min(w/tw, h/th)
    local scaledTw = tw * scale
    local drawX
    align = align or "center"
    if align == "left" then
        drawX = x + scaledTw/2
    elseif align == "right" then
        drawX = x + w - scaledTw/2
    else -- center
        drawX = x + w/2
    end

    helper.printTextOutline(
        text, font, thickness,
        drawX, y + h/2,
        tw + 0.0001, "left",
        0, scale, scale, tw/2, th/2
    )
end

---@param amp number
---@param phase number?
local function getBob(amp, f, phase)
    return math.sin(2 * math.pi * 0.5 * (love.timer.getTime() + (phase or 0))) * amp
end


---@param region kirigami.Region
---@param perk g.PerkInfo?
---@param accentColor objects.Color
local function drawPerkSlot(region, perk, accentColor)
    if not perk then return end

    local x, y, w, h = region:get()

    PERK_DESC_FONT = PERK_DESC_FONT or g.getSmallFont(16)

    local r,g,b = accentColor:darken(0.8):getRGBA()
    lg.setColor(r, g, b)
    ui.drawSingleColorPanel(x, y, w, h)

    -- local r,g,b = accentColor:getRGBA()
    -- lg.setColor(r, g, b, 0.2)
    -- ui.drawSingleColorPanel(x, y, w, h)

    local r,g,b = accentColor:darken(0.9):getRGBA()

    lg.setColor(1,1,1)
    local colorChange = "{o r=" .. r .. " g=" .. g .. " b=" .. b .. "}"
    local title = "{" .. perk.image .. "}{o}" .. helper.wrapRichtextColor(accentColor, perk.name) .. "{/o}"
    local desc = "{c r=0.85 g=0.85 b=0.9}" .. colorChange .. perk.description .. "{/o}"
    local titleRegion = region:splitVertical(1,2):moveRatio(0,-0.5)
    local tx, ty, tw, th = titleRegion:get()
    richtext.printRichContained(title, PERK_DESC_FONT, tx, ty, tw, th, 1)
    local dx, dy, dw, dh = region:padUnit(4):get()
    richtext.printRichContained(desc, PERK_DESC_FONT, dx, dy, dw, dh, 1)
end



local HPS_NAME = loc("Healing per second", {}, {context = "The healing done per second for this unit"})
local HPS_DESC = interp("{healpower} Healing power: {c r=0.78 g=0.32 b=0.64}%{attackDamage}{/c}\n{atkspeed} Attack Speed: {c r=0.9 g=0.55 b=0.2}%{attackSpeed}{/c}\n{c r=0.78 g=0.32 b=0.64}%{attackDamage}{/c}{healpower} x {c r=0.9 g=0.55 b=0.2}%{attackSpeed}{/c}{atkspeed} = {c r=1 g=1 b=1}%{dps}{/c}", {
    context = "Shows healing-per-second calculation, e.g. for a unit that heals others."
})

local DPS_NAME = loc("Damage per second", {}, {context = "The damage done per second for this unit"})
local DPS_DESC = interp("{damage} Attack Damage: {c r=0.85 g=0.25 b=0.25}%{attackDamage}{/c}\n{atkspeed} Attack Speed: {c r=0.9 g=0.55 b=0.2}%{attackSpeed}{/c}\n{c r=0.85 g=0.25 b=0.25}%{attackDamage}{/c}{damage} x {c r=0.9 g=0.55 b=0.2}%{attackSpeed}{/c}{atkspeed} = {c r=1 g=1 b=1}%{dps}{/c}", {
    context = "Shows damage-per-second calculation."
})

local UPGRADE = loc("UPGRADE!", {}, {
    context = "Title, denoting that there is a squad upgrade."
})
local LEVEL = interp("Lv.%{level}", {context = "Abbreviated level text"})

local BONUS = interp("Bonus: %{value}", {
    context = "Tooltip line showing a stat bonus from squad buffs, e.g. 'Bonus: +5 (Health)'."
})

local UPGRADE_UNITS = interp("+%{n} Units", {
    context = "An upgrade where the units in a squad increases. e.g. More soldiers; `+5 units`."
})

local UPGRADE_COLOR_TAG = "{UPGRADE_COLOR}"

local TRAIL_COUNT = {
    RARE = 3,
    LEGENDARY = 6
}

local SWIPE = {
    LEGENDARY = "{swipe t=0.1}",
    UNIQUE = "{swipe r=0.208 g=0.490 b=0.824 t=0.1}",
    COMMANDER = "{swipe r=0.208 g=0.490 b=0.824 t=0.1}"
}


---Draw a single squad card in a kirigami region. Returns true if clicked.
---@param squadId string
---@param region kirigami.Region
---@param index number
---@param showUpgrade boolean?
---@param showLevel? integer|boolean
---@return boolean
---@return number
---@return number
local function drawSquadCard(squadId, region, index, showUpgrade, showLevel)
    ui.assertUIStarted()
    prof_push("drawSquadCard")

    local info = g.getSquadInfo(squadId)
    local def = g.getEntityDef(info.entityId)
    local isHealer = def.baseHealPower
    local manaColor = g.getManaBundleColor(info.cost)
    local frameDarkColor = manaColor:lerp(objects.Color.BLACK, 0.65)
    local panelBottomColor = manaColor:lerp(objects.Color.BLACK, 0.65)
    local frameLightColor = manaColor:lerp(objects.Color.WHITE, 0.25)
    local panelTopColor = objects.Color(0.05, 0.05, 0.06, 0.9)
    local canUpgrade = showUpgrade and g.getSquadFromArmy(squadId)
    local traits = info.startingTraits or {}
    local traitInfos = {}
    for i = 1, #traits do
        table.insert(traitInfos, (g.getTraitInfo(traits[i])))
    end
    local hasAnyTraits = #traitInfos > 0

    local x, y, w, h = region:get()
    local uid = squadId .. "_" .. index
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
        prof_push("squadbox")

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
        if canUpgrade then
            helper.drawEdgeTrailAnimation(region, manaColor, 0.25, 20)
            helper.drawEdgeTrailAnimation(region, manaColor, 0.75, 20)
        end
        love.graphics.setColor(0,0,0)
        ui.drawPanel(x-3,y-3, w+6,h+6)
        love.graphics.setColor(1,1,1)
        helper.gradientRect("vertical", panelTopColor, frameDarkColor, x,y,w,h)
        ui.drawPanel(x,y,w,h)
        helper.gradientRectStencil("vertical", frameLightColor, manaColor, x,y,w,h, function()
            ui.drawPanel(x,y,w,h)
        end)

        prof_pop() -- prof_push("squadbox")
    end)

    -- Header: icon on left, name on right
    local iconSize = 32
    local iconGap = 10
    local level = nil
    if showLevel then
        if type(showLevel) == "number" then
            level = showLevel
        else
            local sq = g.getSquadFromArmy(squadId)
            if sq then
                level = sq.level
            end
        end
    end
    box:add({
        getHeight = function(innerW)
            return math.max(iconSize, TITLE_FONT:getHeight())
        end,
        draw = function(ex, ey, ew, eh)
            prof_push("squadheader")

            -- icon
            prof_push("icon")
            love.graphics.setColor(1, 1, 1)
            g.drawSquadIcon(squadId, ex+16, ey+16, true, level)
            prof_pop() -- prof_push("icon")

            -- name to right of icon
            prof_push("name")
            local textX = ex + iconSize + iconGap
            local textW = ew - iconSize - iconGap

            local nameBob = getBob(0.5)
            love.graphics.setColor(0.8, 0.8, 0.85)
            printTextOutlineContainedNoWrap(
                info.name, TITLE_FONT, 1,
                Kirigami(textX, ey + nameBob, textW, TITLE_FONT:getHeight())
            )
            prof_pop() -- prof_push("name")

            -- Rarity
            prof_push("rarity")
            local rarity = info.rarity
            love.graphics.setColor(rarity.color)
            local rarityText = rarity.lightTextEffect..(SWIPE[rarity.id] or "")..rarity.name
            richtext.printRichContainedNoWrap("{o}" .. rarityText, STAT_FONT, textX, ey + 16, textW, STAT_FONT:getHeight(), "left")
            prof_pop() -- prof_push("rarity")

            prof_pop() -- prof_push("squadheader")
        end,
    })

    box:addSpacing(6)

    -- squad-units: Layed out in a flat horizontal line.
    local unitWidth, unitHeight = g.getUnitDrawSize(info.entityId)
    local maxUnitRowHeight = math.max(1, math.floor(h * 0.15))
    box:add({
        getHeight = function()
            return math.min(unitHeight + 4, maxUnitRowHeight)
        end,
        draw = function(ex, ey, ew, eh)
            if unitHeight == 0 then return end
            prof_push("squadunits")

            local count = g.getSquadUnitCount(squadId)
            local padX = count < 3 and 24 or 10
            local cells = Kirigami(ex + padX, ey, ew - padX * 2, eh):grid(count, 1)
            local r,gg,b,a = panelBottomColor:getRGBA()
            love.graphics.setColor(r/4,gg/4,b/4)
            ui.drawSingleColorPanel(ex-3,ey-3, ew+6,eh+6)
            love.graphics.setColor(r, gg, b, a * 0.6)
            ui.drawSingleColorPanel(ex, ey, ew, eh)
            love.graphics.setColor(1, 1, 1, 0.85)
            local t = g.getWorldTime() * 0.6
            local drawUnitHeight = math.max(1, math.min(unitHeight, eh - 4))
            for i = 1, count do
                local cx, cy, cw, ch = cells[i]:get()
                local ux = cx + (cw - unitWidth) / 2
                local uy = cy + (ch - drawUnitHeight) / 2 + math.sin(t + i * 0.9) * 1
                g.drawUnitPreview(info.entityId, ux, uy, unitWidth, drawUnitHeight)
            end

            prof_pop() -- prof_push("squadunits")
        end
    })

    -- Stats: 3 wide, 2 high grid. Sorted with important stats first.
    local hasDPS = def.baseAttackSpeed and (def.baseHealPower or def.baseAttackDamage)
    local sortedStats = {}
    for i = 1, #STAT_LIST do
        local s = STAT_LIST[i]
        if s ~= "DPS" or hasDPS then
            sortedStats[#sortedStats+1] = s
        end
    end
    do
        local origIdx = {}
        for i, s in ipairs(sortedStats) do origIdx[s] = i end
        table.sort(sortedStats, function(a, b)
            local ai = a == "DPS" or g.isStatImportant(a, info.entityId)
            local bi = b == "DPS" or g.isStatImportant(b, info.entityId)
            if ai ~= bi then return ai end
            return origIdx[a] < origIdx[b]
        end)
    end

    box:addSpacing(4)

    local statCellH = 22
    local statRows = 2
    local statCols = 3
    box:add({
        getHeight = function() return statCellH * statRows end,
        draw = function(ex, ey, ew, eh)
            prof_push("squadstats")

            local cellW = math.floor(ew / statCols)

            for i = 1, #sortedStats do
                local row = math.floor((i - 1) / statCols)
                local col = (i - 1) % statCols
                local cx = ex + col * cellW
                local cy = ey + row * statCellH
                local cw = cellW - 2
                local ch = statCellH - 2

                local value, icon, statColor, name, desc, bonus
                local statId = sortedStats[i]
                local isDPS = statId == "DPS"
                if isDPS then
                    -- its special! computed
                    local powerStat = isHealer and "healPower" or "attackDamage"
                    local baseSpeed = def.baseAttackSpeed or 0
                    local basePower = def.baseHealPower or def.baseAttackDamage or 0
                    local attackSpeed = baseSpeed + g.getSquadStatBuff(squadId, "attackSpeed")
                    local power = basePower + g.getSquadStatBuff(squadId, powerStat)
                    value = attackSpeed * power
                    bonus = value - (baseSpeed * basePower)
                    icon = isHealer and "healpower" or "damage"
                    statColor = isHealer and g.COLORS.HEAL or g.COLORS.DAMAGE
                    name = isHealer and HPS_NAME or DPS_NAME
                    desc = (isHealer and HPS_DESC or DPS_DESC)({
                        attackSpeed = g.formatNumber(attackSpeed),
                        attackDamage = g.formatNumber(power),
                        dps = g.formatNumber(value)
                    })
                else
                    local stat = g.getStatInfo(statId)
                    bonus = g.getSquadStatBuff(squadId, statId)
                    value = (def and def[stat.baseName] or 0) + bonus
                    icon = stat.icon
                    statColor = stat.color
                    name = stat.displayName
                    desc = stat.description
                end

                -- background
                local important = isDPS or g.isStatImportant(statId, info.entityId)
                local alpha = 0.4
                if important then
                    alpha = 1
                end

                local px, py = iml.getTransformedPointer()
                local isStatHovered = px >= cx and py >= cy and px <= cx+cw and py <= cy+ch
                if isStatHovered then
                    alpha = alpha * 0.75
                end
                do
                local r,g,b,a = panelBottomColor:getRGBA()
                love.graphics.setColor(r/4,g/4,b/4)
                ui.drawSingleColorPanel(cx-3,cy-3, cw+6,ch+6)
                love.graphics.setColor(r,g,b,a*alpha)
                ui.drawSingleColorPanel(cx, cy, cw, ch)
                end
                if isStatHovered then
                    -- print information about the stat
                    hoverService.requestHover(function (boxx, fonts)
                        local rr,gg,bb = statColor.r, statColor.g, statColor.b
                        boxx:addText(string.format("{c r=%.3f g=%.3f b=%.3f}%s", rr, gg, bb, name), fonts.title)
                        boxx:addText(desc, fonts.body)
                        if bonus and bonus ~= 0 then
                            boxx:addSpacing(10)
                            local valStr = string.format("{c r=%.3f g=%.3f b=%.3f}%s{/c}", rr, gg, bb, g.formatNumber(bonus))
                            boxx:addText(BONUS({value = valStr}), fonts.body)
                        end
                    end)
                end

                -- icon
                if icon and g.isImage(icon) then
                    love.graphics.setColor(1, 1, 1, alpha)
                    g.drawImageContained(icon, cx + 2, cy + 2, ch - 4, ch - 4)
                end

                -- text
                do
                local r,gg,b,a = statColor:getRGBA()
                love.graphics.setColor(r,gg,b,a*alpha)
                local textX = cx + ch
                local textY = cy + (ch - STAT_FONT:getHeight()) / 2
                helper.printTextOutline(g.formatNumber(value), STAT_FONT, 1, textX, textY, cw - ch, "left")
                end
            end

            prof_pop() -- prof_push("squadstats")
        end,
    })

    box:addSpacing(4)

    -- Traits:
    if hasAnyTraits then
        local H = 10
        local function drawTraitBox(traitInfo, xx, yy, ww, hh)
            if not traitInfo then return end
            xx,yy,ww,hh = Kirigami(xx,yy,ww,hh):padUnit(2,0,2,0):get()

            local px, py = iml.getTransformedPointer()
            local isHovered2 = px >= xx and py >= yy and px <= xx + ww and py <= yy + hh

            local r, gg, b, a = g.COLORS.DARK_UI:getRGBA()
            local pad = 1
            local dark = isHovered2 and 0.7 or 1
            love.graphics.setColor(r*dark, gg*dark, b*dark, isHovered2 and 0.9 or 0.75)
            ui.drawSingleColorPanel(xx, yy, ww, hh)

            love.graphics.setColor(traitInfo.color)
            richtext.printRichContainedNoWrap(traitInfo.name, STAT_FONT, xx + pad*2, yy, ww - pad*4, hh, "center")

            if isHovered2 then
                hoverService.requestHover(function(boxx, fonts)
                    boxx:addText(traitInfo.name, fonts.title)
                    boxx:addText(traitInfo.description, fonts.body)
                end)
            end
        end

        box:add({
            getHeight = function(w)
                return H
            end,
            draw = function(xx, yy, ww, hh)
                prof_push("squadtraits")

                lg.setColor(1,1,1)
                -- lg.circle("fill",xx,yy, 100)
                -- print(#traits)
                local reg = Kirigami(xx, yy, ww, hh)
                local a, b, c = reg:padRatio(0.1):splitHorizontal(1, 1, 1)
                if #traitInfos == 1 then
                    drawTraitBox(traitInfos[1], b:get())
                elseif #traitInfos == 2 then
                    drawTraitBox(traitInfos[1], a:get())
                    drawTraitBox(traitInfos[2], b:get())
                else
                    drawTraitBox(traitInfos[1], a:get())
                    drawTraitBox(traitInfos[2], b:get())
                    drawTraitBox(traitInfos[3], c:get())
                end

                prof_pop() -- prof_push("squadtraits")
            end
        })
    end

    -- Perks
    local perks = info.perks or {}
    box:addFill({
        getHeight = function() return 0 end,
        draw = function(ex, ey, ew, eh)
            prof_push("squadperks")

            local reg = Kirigami(ex, ey, ew, eh)
            if #perks == 1 then
                local perkInfo = perks[1] and g.getPerkInfo(perks[1])
                local _,reg1,_ = reg:splitVertical(1,2,1)
                drawPerkSlot(reg1, perkInfo, manaColor)
            elseif #perks == 2 then
                local reg1, reg2 = reg:splitHorizontal(1,1)
                local perkInfo1 = perks[1] and g.getPerkInfo(perks[1])
                local perkInfo2 = perks[2] and g.getPerkInfo(perks[2])
                drawPerkSlot(reg1:padUnit(4), perkInfo1, manaColor)
                drawPerkSlot(reg2:padUnit(4), perkInfo2, manaColor)
            else
                local perkRegs = {reg:splitVertical(1, 1, 1)}
                for i = 1, 3 do
                    local perkInfo = perks[i] and g.getPerkInfo(perks[i]) or nil
                    drawPerkSlot(perkRegs[i]:padUnit(2, 2), perkInfo, manaColor)
                end
            end

            prof_pop() -- prof_push("squadperks")
        end,
    })

    local ret = false
    if iml.wasJustClicked(hitX, hitY, w, h, 1, uid) then
        g.playUISound("ui_click_basic", 1.4, 0.8)
        ret = true
    end

    local ww,hh = box:render(x, y)

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

    if canUpgrade then
        prof_push("squadupgindicator")

        -- its an upgrade
        local r1, _ = region:splitVertical(1,8)
        local upgradeTextBob = getBob(0.3)
        love.graphics.setColor(g.COLORS.UPGRADE)
        printTextOutlineContainedNoWrap(
            UPGRADE, TITLE_FONT, 1,
            r1:moveRatio(0, -0.7):padRatio(0.3):moveUnit(0, upgradeTextBob),
            "center"
        )

        local buf = {}
        for statId, _ in pairs(info.statUpgradeScaling) do
            local statInfo = g.getStatInfo(statId)
            local base = def[statInfo.baseName] or 0
            local increase = base * info.statUpgradeScaling[statId]
            local incrtxt = helper.wrapRichtextColor(statInfo.color, " +%d")
            buf[#buf+1] = string.format("{%s}" .. incrtxt, statInfo.icon, math.floor(increase + 0.5))
        end

        if #buf > 0 then
            local str = table.concat(buf, "  ")
            local boxReg = Kirigami(x, y + h - 20, w, 40):padUnit(30, 0, 30, 0)
            local title, txtReg = boxReg:splitVertical(2,3)

            love.graphics.setColor(1,1,1)
            helper.drawEdgeTrailAnimation(boxReg, manaColor, 0)
            helper.drawEdgeTrailAnimation(boxReg, manaColor, 0.5)
            lg.setColor(1,1,1)
            ui.drawDarkPanel(boxReg:get())

            local font = g.getSmallFont(16)
            lg.setColor(g.COLORS.UPGRADE)
            printTextOutlineContainedNoWrap(
                LEVEL({level = canUpgrade.level + 1}),
                font, 1,
                title:padUnit(2,2):moveUnit(0, getBob(0.5))
            )
            lg.setColor(1, 1, 1)

            richtext.printRichContainedNoWrap(str, font, txtReg:padUnit(4,4):get())
        end

        prof_pop() -- prof_push("squadupgindicator")
    end

    prof_pop() -- prof_push("drawSquadCard")

    return ret, ww,hh
end

return drawSquadCard
