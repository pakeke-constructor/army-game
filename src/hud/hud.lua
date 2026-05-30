
local hoverService = require("src.hud.hoverService")

---@class g.HUD: objects.Class
---@field hoveredSquad g.Squad?
local HUD = objects.Class("g:HUD")

function HUD:init()
    self.selectedSlot = 1
end

---@class g.hudArgs
---@field battleScene boolean?
---@field mapScene boolean?
local hudArgs

local SQUAD_ICON_SIZE = 32
local SQUAD_PADDING = 4

local LOC_DAYS = interp("%{n} days until {c r=1 g=0.3 b=0.3}attack", {context="HUD top bar, countdown to next demon incursion. 'attack' is richtext-colored red"})
local LOC_ZONE = loc("Zone 1 - Forest", {}, {context="HUD top bar, current zone name. Hardcoded stub"})
local LOC_PAUSE = loc("II", {}, {context="HUD top bar, pause button icon text"})

local LOC_HOVER_RAGE = interp("+%{pct}% demon damage, +%{pct}% demon health!", {context="Tooltip when hovering demon rage in HUD"})
local LOC_HOVER_RAGE_ZERO = loc("demon-rage increases whenever you win a battle. The higher the demon-rage, the stronger the enemies", {}, {context="Tooltip when hovering demon rage in HUD when rage is zero"})
local LOC_HOVER_GOLD = loc("Gold is used to buy items and upgrades at shops.", {}, {context="Tooltip when hovering gold in HUD"})
local LOC_HOVER_DAYS = loc("Days remaining until the next Incursion!", {}, {context="Tooltip when hovering days-till-incursion in HUD. After X number of days, players will be forced to fight a 'boss'"})
local LOC_HOVER_MANA = loc(" mana is used to deploy squads in battle.", {}, {context="Tooltip when hovering normal mana in HUD. Prefixed with hovered mana type icon/text at runtime."})
local LOC_HOVER_WILDCARD_MANA = loc("Wildcard mana can be spent to deploy ANY squad.", {}, {context="Tooltip when hovering wildcard mana in HUD."})

local LOC_HOVER_KEYS = loc("Keys are used to unlock things.", {}, {context="Tooltip when hovering HUD"})
local LOC_HOVER_NO_KEYS = loc("Keys are used to unlock things. (You have no keys!)", {}, {context="Tooltip when hovering HUD"})



---@param slot integer
---@return boolean
local function isSlotAvailable(slot)
    local army = g.getSortedArmyList()
    local squad = army[slot]
    return squad and (not squad.deployed) or false
end

---@param from integer
---@return integer?
local function getClosestAvailableSlot(from)
    local army = g.getSortedArmyList()
    local total = #army
    if total == 0 then return nil end
    from = helper.clamp(from, 1, total)
    local fallback
    for offset = 0, total - 1 do
        for _, slot in ipairs({from - offset, from + offset}) do
            if slot >= 1 and slot <= total then
                local sq = army[slot]
                if sq and not sq.deployed then
                    if sq.canAfford then return slot end
                    fallback = fallback or slot
                end
            end
        end
    end
    return fallback
end

---@param self g.HUD
---@return integer?
local function getSlotIndex(self)
    local idx = getClosestAvailableSlot(self.selectedSlot)
    if idx then self.selectedSlot = idx end
    return idx
end

---@param sq g.Squad
---@param x number
---@param y number
---@param selected boolean
local function renderSquad(sq, x, y, selected)
    local _, scName = g.getCurrentScene()
    local isBattle = scName == "battle_scene"
    local size = SQUAD_ICON_SIZE
    if isBattle and selected then
        lg.setColor(1, 1, 1, 0.3)
        ui.drawSingleColorPanel(x - 2, y - 2, size + 4, size + 4)
    end
    if isBattle and sq.deployed then
        lg.setColor(0.15, 0.15, 0.15, 1)
    elseif isBattle and (not sq.canAfford) then
        lg.setColor(1, 1, 1, 0.35)
    else
        lg.setColor(1, 1, 1)
    end
    g.drawSquadIcon(sq.squadId, x+size/2, y+size/2, true, sq.level)
end



---@param sq g.Squad
local function hoverSquad(sq)
    local info = g.getSquadInfo(sq.squadId)
    hoverService.requestHover(function(box, fonts)
        box:addText("{c r=0.9 g=0.85 b=0.7}" .. info.name, fonts.title)
        box:addSpacing(2)
        box:addText("{c r=0.7 g=0.7 b=0.75}" .. g.getSquadUnitCount(sq.squadId) .. "x " .. info.entityId, fonts.body)
        local perks = sq.perks
        if perks and #perks > 0 then
            for _, pId in ipairs(perks) do
                local p = g.getPerkInfo(pId)
                box:addSpacing(2)
                box:addText("{c r=0.85 g=0.8 b=0.6}" .. p.name, fonts.body)
                box:addText("{c r=0.6 g=0.6 b=0.65}" .. p.description, fonts.body)
            end
        end
    end)
end


---@param self g.HUD
---@param region kirigami.Region
local function drawSquadBar(self, region)
    local army = g.getSortedArmyList()
    self.hoveredSquad = nil
    if #army <= 0 then
        return
    end

    local currentSlot = getSlotIndex(self)

    local trueArmy = {}
    for i, sq in ipairs(army) do
        if not sq.deployed then
            table.insert(trueArmy, {sq = sq, idx = i})
        end
    end

    local count = #trueArmy
    local EDGE_PAD = 14

    local neededH = SQUAD_ICON_SIZE + 2 * EDGE_PAD
    if region.h < neededH then
        region = region:set(nil, nil, nil, neededH)
    end

    local inner = region:padUnit(EDGE_PAD)

    local step = SQUAD_ICON_SIZE + SQUAD_PADDING
    if count > 1 then
        step = math.min(step, (inner.w - SQUAD_ICON_SIZE) / (count - 1))
    end

    local startX = inner.x
    local baseY = inner.y + (inner.h - SQUAD_ICON_SIZE) / 2

    local _, scName = g.getCurrentScene()
    local isBattle = scName == "battle_scene"

    for i, entry in ipairs(trueArmy) do
        local sq = entry.sq
        local armyIdx = entry.idx
        local x = startX + (i - 1) * step
        local y = baseY
        local selected = (armyIdx == currentSlot)
        if isBattle and selected then
            y = y - 6
        end
        renderSquad(sq, x, y-4, selected)
        if iml.wasJustClicked(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, 1, i) then
            self.selectedSlot = armyIdx
        end
        iml.panel(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, i)
        if iml.isHovered(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, i) then
            self.hoveredSquad = sq
            hoverSquad(sq)
        end
    end
end





---@param r kirigami.Region
local function drawLeftBlessingBar(r)
    local run = g.getRun()
    lg.setColor(1,1,1)
    ui.drawDarkPanel(r:get())
    local blessings = {}
    for bId, _ in pairs(run.blessings) do
        blessings[#blessings + 1] = bId
    end
    table.sort(blessings)
    if #blessings > 0 then
        local padded = r:padUnit(6)
        local cols, rows = helper.getBestFitDimensions(#blessings, padded.w, padded.h)
        local cells = padded:grid(cols, rows)
        for i, bId in ipairs(blessings) do
            local cx, cy = cells[i]:getCenter()
            g.drawBlessingIcon(bId,cx,cy)
            local info = g.getBlessingInfo(bId)
            local gx, gy, gw, gh = cells[i]:get()
            if iml.isHovered(gx, gy, gw, gh, "blessing" .. i) then
                hoverService.requestHover(function(box, fonts)
                    box:addText("{c r=0.9 g=0.85 b=0.7}" .. info.name, fonts.title)
                    box:addSpacing(2)
                    box:addText("{c r=0.6 g=0.6 b=0.65}" .. info.description, fonts.body)
                end)
            end
        end
    end
end



local AVAILABLE_MANA = loc("Available Mana: ", {}, {
    context = "To the right of this text, it shows what mana is available. 'Mana' is an abstract concept, comes in different colors, like red,blue,green etc."
})

local NO_MANA = loc("No Mana!", {}, {
    context = "When player runs out of mana. 'Mana' is an abstract concept, comes in different colors, like red,blue,green etc."
})



local function dbg(r)
    if consts.DEV_MODE then
        lg.rectangle("line",r:get())
    end
end


---@param reg kirigami.Region
local function drawXpBar(reg)
    ui.drawDarkPanel(reg:get())
    local left, right = reg:splitHorizontal(1, 4)

    local run = g.getRun()
    local smallFont = g.getSmallFont(16)
    local level = run.level
    local leftTop, leftBot = left:padRatio(0.2):splitVertical(1,1)
    lg.setColor(1,1,1)
    g.drawImage("xp_icon", leftTop:getCenter())
    lg.setColor(objects.Color("FF33873E"))
    richtext.printRichContainedNoWrap("{o}Lv "..tostring(level).."{/o}", smallFont, leftBot:get())

    -- draw xp bar
    local _, rightTop, rightBot = right:splitVertical(1,2,2)
    local xp, xpReq = run.xp, run:getXpRequirement()
    -- local xpBar = rightBot:padUnit(8, 10, 8, 6)
    local xpBar = rightBot:padUnit(6, 2, 6, 6)
    lg.setColor(g.COLORS.DARK_UI)
    lg.setColor(objects.Color("FF2E2C3C"))
    ui.drawSingleColorPanel(xpBar:get())
    lg.setColor(objects.Color("FF33873E"))

    local xpW = (xp/xpReq) * xpBar.w
    local fillReg = xpBar:shrinkTo(xpW, xpBar.h)
    ui.drawSingleColorPanel(fillReg:get())

    -- draw xp text
    local txt1 = helper.wrapRichtextColor(objects.Color("FF80BD51"),("%d"):format(xp))
    local txt2 = helper.wrapRichtextColor(objects.Color("FF1F6525"), ("/%d"):format(xpReq))
    richtext.printRichContainedNoWrap(txt1..txt2, smallFont, rightTop:get())
end




local function drawTopBar()
    local r = ui.getScreenRegion()
    local topBar, mainBar = r:splitVertical(0.1,0.9)

    local xp, demonRage, gold, keys, daysTillIncursion, zoneString, pausePanel = topBar:splitHorizontal(4, 2,2,2, 4,4,1)
    --[[
    each of these ^^^ are panels.

    demonRage: shows current demon-rage. When hovered, explains what demonRage is (use hoverService) 
    gold: shows gold-text. When hovered, simple explanation explains what gold is (used to buy stuff)
    days till incursion: shows text. When hovered, simple explanation explains stuff about incursion (TODO; stub for now)
        - {day_icon} {white}20{/white}{gray} days until {/gray}{red}attack{/red}
    zoneString: eg. "Zone 1 - Forest" (just hardcode for now)
    pausePanel: Pause-button (stub for now.)

    (days-till-incursion should be a *slightly* taller panel than others, maybe 5% higher h.)

    AGENT INSTRUCTIONS: KEEP THESE COMMENTS; DONT REMOVE.
    ]]

    local run = g.getRun()
    local font = g.getSmallFont(16)
    local fh = font:getHeight()

    local function drawPanel(region, text, hoverText)
        local x, y, w, h = region:get()
        lg.setColor(1, 1, 1)
        local DY = 30
        ui.drawDarkPanel(x, y-DY, w, h+DY)
        lg.setColor(1, 1, 1)
        richtext.printRich(text, font, x, y + h / 2 - fh / 2, w, "center")
        if hoverText and iml.isHovered(x, y, w, h, text) then
            hoverService.requestHover(function(box, fonts)
                box:addText("{c r=0.7 g=0.7 b=0.75}" .. hoverText, fonts.body)
            end)
        end
    end

    drawXpBar(xp)

    local rageHover = run.demonRage <= 0 and LOC_HOVER_RAGE_ZERO or LOC_HOVER_RAGE({pct = run.demonRage * 10})
    drawPanel(demonRage, "{demon_pitchfork}{c r=0.6 g=0.1 b=0} " .. tostring(run.demonRage), rageHover)
    drawPanel(gold, "{coin_icon} {GOLD_COLOR}" .. tostring(run.money), LOC_HOVER_GOLD)

    local hasKeys = (run.keys or 0) > 0
    --local append = hasKeys and "" or "{c r=0.2 g=0.2 b=0.2}"
    local keyStr = tostring(run.keys).."/3"
    local locHover = hasKeys and LOC_HOVER_KEYS or LOC_HOVER_NO_KEYS
    drawPanel(keys, "{key_icon}".."{c r=0.54 g=0.5 b=0.5} "..keyStr, locHover)

    local _, _, _, dh = daysTillIncursion:get()
    local extraH = dh * 0.05
    local dtiRegion = daysTillIncursion:padUnit(0, -extraH, 0, 0)
    drawPanel(dtiRegion, LOC_DAYS({n = run:getDaysUntilIncursion()}), LOC_HOVER_DAYS)

    drawPanel(zoneString, "{c r=0.2 g=0.5 b=0.3}{wavy freq=0.5}" .. LOC_ZONE)
    drawPanel(pausePanel, LOC_PAUSE)
end




---@param self g.HUD
---@param barHeight number
local function drawBottomBar(self, barHeight)
    local sw, sh = ui.getScaledUIDimensions()
    local run = g.getRun()
    local region = Kirigami(0, sh - barHeight, sw, barHeight)
    local squadBar, _, blessingBox = region:splitHorizontal(2, 1, 1)

    ui.drawDarkPanel(squadBar:get())
    iml.panel(squadBar:get()) -- dont a
    drawSquadBar(self, squadBar:padUnit(6))

    local mH=20
    drawManaBar(0, squadBar.y - mH, squadBar.w, mH,  squadBar.w/2)
end


---@return g.ManaCounts
local function getManaCounts()
    local sc, scName = g.getCurrentScene()
    if scName == "battle_scene" then
        return g.getBattleManaCounts()
    end
    return g.getPermanentManaCounts()
end


---@param self g.HUD
local function drawManaBox(self)
    local img = "hud_bottom_left_mana_box"
    local w,h = g.getImageSize(img)
    local r = Kirigami(0,0,w,h)
    local sr = ui.getFullScreenRegion()
    r = r:attachToBottomOf(sr):clampInside(sr)
    lg.setColor(1,1,1)
    g.drawImage(img, r:getCenter())

    local availableManaCounts = g.getPermanentManaCounts()
    local manaCounts = getManaCounts()
    local ct=0
    for _ in pairs(availableManaCounts) do
        ct = ct + 1
    end

    local font = g.getSmallFont(16)
    local rdiff = (math.pi*2) / ct
    local cx,cy = r:getCenter()
    local t = 0--love.timer.getTime()
    local hoveredManaType = nil
    local function drawMana(mtype, i, manaImg)
        local x = cx + (r.w/3) * math.sin(t + i*rdiff)
        local y = cy + (r.h/3) * math.cos(t + i*rdiff)
        if ct <= 1 then
            -- just center it:
            x,y = cx,cy
        end
        local minfo = g.getManaInfo(mtype)
        manaImg = manaImg or (minfo and minfo.imageLarge)
        local count = manaCounts[mtype] or 0
        lg.setColor(1,1,1)
        if count <= 0 then
            lg.setColor(0.3,0.3,0.3)
        end
        g.drawImage(manaImg, x-10,y)
        local color = (minfo and minfo.color) or objects.Color.WHITE
        lg.setColor(color)
        if count <= 0 then
            lg.setColor(0.3,0.3,0.3)
        end
        richtext.printRich(tostring(count), font, x+4,y-8, 100, "left")
        if iml.isHovered(x-16, y-16, 36, 36, "hud_mana_" .. mtype) then
            hoveredManaType = mtype
        end
    end
    if ct > 0 then
        local i = 0
        for _,mtype in ipairs(g.getManaTypelist())do
            if availableManaCounts[mtype] then
                drawMana(mtype, i)
                i = i + 1
            end
        end
        drawMana(g.WILDCARD_MANA, i, "mana_colorless_large")
    end

    if hoveredManaType then
        hoverService.requestHover(function(box, fonts)
            if hoveredManaType == g.WILDCARD_MANA then
                box:addText("{c r=0.7 g=0.7 b=0.75}" .. LOC_HOVER_WILDCARD_MANA, fonts.body)
            else
                local manaTypeText = "{" .. hoveredManaType .. "}"
                box:addText("{c r=0.7 g=0.7 b=0.75}" .. manaTypeText .. LOC_HOVER_MANA, fonts.body)
            end
        end)
    end

    return w,h
end


---@param self g.HUD
local function drawBottomBar(self, barHeight)
    local w,h = drawManaBox(self)

    local sw, sh = ui.getScaledUIDimensions()
    local run = g.getRun()
    local region = Kirigami(0, sh - barHeight, sw, barHeight)

    local manaBox, rest = region:splitHorizontal(w,sw-w)
    local squadBar,blessingBar = rest:splitHorizontal(2,1)

    -- Squad box
    ui.drawDarkPanel(squadBar:get())
    drawSquadBar(self, squadBar:padUnit(6))

    -- Blessing box
    ui.drawDarkPanel(blessingBar:get())
    drawLeftBlessingBar(blessingBar)
end



---@param opt g.hudArgs
function HUD:drawUI(opt)
    drawTopBar()

    drawBottomBar(self, SQUAD_ICON_SIZE + 30)

    if self.hoveredSquad then
        local main = ui.getScreenRegion()
        local _, left = main:padRatio(0.2):splitHorizontal(2, 1)
        ui.drawSquadCard(self.hoveredSquad.squadId, left:padRatio(0.1), -999)
    end

    rewardPopupService.draw()
    choicePopupService.draw()
    randomEventService.draw()
    hoverService.draw()
end

---@return g.Squad? squad
function HUD:getSelection()
    local idx = getSlotIndex(self)
    if not idx then return nil end
    return g.getSortedArmyList()[idx]
end

---@param visibleIndex integer 1..9, position among non-deployed squads as shown in HUD
function HUD:selectVisibleSlot(visibleIndex)
    local army = g.getSortedArmyList()
    local seen = 0
    for i, sq in ipairs(army) do
        if not sq.deployed then
            seen = seen + 1
            if seen == visibleIndex then
                self.selectedSlot = i
                return
            end
        end
    end
end

function HUD:wheelmoved(dx, dy)
    local dir = dy > 0 and 1 or -1
    local total = #g.getSortedArmyList()
    local next = self.selectedSlot + dir
    for i=0, 8 do
        local j = next + i*dir
        if next >= 1 and next <= total and isSlotAvailable(j) then
            self.selectedSlot = j
            return
        end
    end
end

return HUD
