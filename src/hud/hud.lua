
local hoverService = require("src.hud.hoverService")
local settingsPopupService = require("src.hud.settings")

---@class g.HUD: objects.Class
---@field hoveredSquad g.Squad|nil hovered squad object
---@field hoveredSpell string|nil hovered spellId
---@field selectedIndex integer? index into the active selection list (see getActiveList)
---@field battleStarted boolean cached each frame; false = squads selectable, true = spells selectable
local HUD = objects.Class("g:HUD")

function HUD:init()
    self.selectedIndex = 1
    self.battleStarted = false
end

---@class g.hudArgs.hoverSquad
---@field id string
---@field showUpgrade boolean?

---@class g.hudArgs
---@field battleScene boolean?
---@field mapScene boolean?
---@field battleStarted boolean?
---@field hoverSquad g.hudArgs.hoverSquad?

local SQUAD_ICON_SIZE = 32
local SQUAD_PADDING = 4

local LOC_DAYS = interp("%{n} days until {c r=1 g=0.3 b=0.3}attack", {context="HUD top bar, countdown to next demon incursion. 'attack' is richtext-colored red"})
local LOC_ZONE = loc("Zone 1 - Forest", {}, {context="HUD top bar, current zone name. Hardcoded stub"})
local LOC_PAUSE = loc("II", {}, {context="HUD top bar, pause button icon text"})

local LOC_HOVER_FURY = interp("+%{pct}% demon damage, +%{pct}% demon health!", {context="Tooltip when hovering Demon Fury in HUD"})
local LOC_HOVER_FURY_ZERO = loc("Demon Fury increases whenever you win a battle. The higher the Demon Fury, the stronger the enemies", {}, {context="Tooltip when hovering Demon Fury in HUD when fury is zero"})
local LOC_HOVER_GOLD = loc("Gold is used to buy items and upgrades at shops.", {}, {context="Tooltip when hovering gold in HUD"})
local LOC_HOVER_DAYS = loc("Days remaining until the next Incursion!", {}, {context="Tooltip when hovering days-till-incursion in HUD. After X number of days, players will be forced to fight a 'boss'"})
local LOC_HOVER_MANA = loc(" mana is used to deploy squads in battle.", {}, {context="Tooltip when hovering normal mana in HUD. Prefixed with hovered mana type icon/text at runtime."})
local LOC_HOVER_WILDCARD_MANA = loc("Wildcard mana can be spent to deploy ANY squad.", {}, {context="Tooltip when hovering wildcard mana in HUD."})

local LOC_HOVER_KEYS = loc("Keys are used to unlock things.", {}, {context="Tooltip when hovering HUD"})
local LOC_HOVER_NO_KEYS = loc("Keys are used to unlock things. (You have no keys!)", {}, {context="Tooltip when hovering HUD"})



---@param sq g.Squad
---@return boolean
local function isSquadVisible(sq)
    local _, scName = g.getCurrentScene()
    return scName ~= "battle_scene" or not sq.deployed
end

--- Whether spells (vs squads) are the active selectable pool.
---@param self g.HUD
local function spellsAreActive(self)
    local _, scName = g.getCurrentScene()
    return scName == "battle_scene" and self.battleStarted
end

--- Owned spellIds, sorted for stable order.
---@return string[]
local function getVisibleSpells()
    local run = g.getRun()
    local spells = {}
    for spellId in pairs(run.spells) do
        if not run.spellsCast[spellId] then
            spells[#spells + 1] = spellId
        end
    end
    table.sort(spells)
    return spells
end

---@param spellId string
---@return boolean
local function isSpellAffordable(spellId)
    local info = g.getSpellInfo(spellId)
    return (not info.cost) or g.canAffordMana(g.getBattleManaCounts(), info.cost)
end

--- The ordered list of currently-selectable items: spellIds (battle started) or
--- visible squad objects (otherwise). Draw order matches this order, so the
--- list index doubles as the on-screen index.
---@param self g.HUD
---@return (g.Squad|string)[]
local function getActiveList(self)
    if spellsAreActive(self) then
        return getVisibleSpells()
    end
    local squads = {}
    for _, sq in ipairs(g.getSortedArmyList()) do
        if isSquadVisible(sq) then
            squads[#squads + 1] = sq
        end
    end
    return squads
end

--- Is the item at the given list index usable (affordable / castable) right now?
---@param self g.HUD
---@param item g.Squad|string
---@return boolean
local function isItemUsable(self, item)
    if type(item) == "string" then
        local run = g.getRun()
        if run.spellsCast[item] then return false end
        local mx, my = love.mouse.getPosition()
        local wx, wy = g.screenToWorld(mx, my)
        return g.canCastSpell(wx, wy, item)
    end
    return item.canAfford or false
end

--- Resolves selectedIndex to a valid index into the active list, mutating
--- self.selectedIndex. Prefers the nearest usable item; never out of range.
---@param self g.HUD
---@return (g.Squad|string)[] list
---@return integer? idx valid index, or nil if list empty
local function getValidSelection(self)
    local list = getActiveList(self)
    if #list == 0 then
        self.selectedIndex = nil
        return list, nil
    end
    local from = helper.clamp(self.selectedIndex or 1, 1, #list)
    local idx = from
    if not isItemUsable(self, list[from]) then
        for offset = 1, #list do
            for _, j in ipairs({from - offset, from + offset}) do
                if j >= 1 and j <= #list and isItemUsable(self, list[j]) then
                    idx = j
                    break
                end
            end
            if idx ~= from then break end
        end
    end
    self.selectedIndex = idx
    return list, idx
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



---@param spellId string
---@param x number
---@param y number
---@param selected boolean
---@param affordable boolean spell can be afforded right now
local function renderSpell(spellId, x, y, selected, affordable)
    local size = SQUAD_ICON_SIZE
    if selected then
        lg.setColor(1, 1, 1, 0.3)
        ui.drawSingleColorPanel(x - 2, y - 2, size + 4, size + 4)
    end
    if not affordable then
        lg.setColor(1, 1, 1, 0.35)
    else
        lg.setColor(1, 1, 1)
    end
    g.renderSpellIcon(spellId, x+size/2, y+size/2, true)
end






--- Lays out icons evenly across a region.
---@param region kirigami.Region
---@param count integer
---@return number startX, number baseY, number step
local function layoutIcons(region, count)
    local EDGE_PAD = 14
    local inner = region:padUnit(EDGE_PAD)
    local step = SQUAD_ICON_SIZE + SQUAD_PADDING
    if count > 1 then
        step = math.min(step, (inner.w - SQUAD_ICON_SIZE) / (count - 1))
    end
    return inner.x, inner.y + (inner.h - SQUAD_ICON_SIZE) / 2, step
end


--- Draws the visible squad icons. selIdx is the active selection (into the
--- visible list), or nil when squads aren't the active pool.
---@param self g.HUD
---@param region kirigami.Region
---@param selIdx integer?
local function drawSquadsSection(self, region, selIdx)
    local visible = {}
    for _, sq in ipairs(g.getSortedArmyList()) do
        if isSquadVisible(sq) then
            visible[#visible + 1] = sq
        end
    end
    if #visible <= 0 then return end

    local startX, baseY, step = layoutIcons(region, #visible)

    local _, scName = g.getCurrentScene()
    local isBattle = scName == "battle_scene"

    for i, sq in ipairs(visible) do
        local x = startX + (i - 1) * step
        local y = baseY
        local selected = (i == selIdx)
        if isBattle and selected then
            y = y - 6
        end
        renderSquad(sq, x, y-4, selected)
        if selIdx and iml.wasJustClicked(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, 1, i) then
            self.selectedIndex = i
        end
        iml.panel(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, i)
        if iml.isHovered(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, i) then
            self.hoveredSquad = sq
        end
    end
end


--- Draws the spell icons. selIdx is the active selection (into the spell list),
--- or nil when spells aren't the active pool (pre-battle).
---@param self g.HUD
---@param region kirigami.Region
---@param selIdx integer?
local function drawSpellsSection(self, region, selIdx)
    local spells = getVisibleSpells()
    if #spells <= 0 then return end

    local startX, baseY, step = layoutIcons(region, #spells)

    for i, spellId in ipairs(spells) do
        local affordable = (selIdx == nil) or isSpellAffordable(spellId)
        local usable = (selIdx ~= nil) and affordable and isItemUsable(self, spellId)
        local x = startX + (i - 1) * step
        local y = baseY
        local selected = (i == selIdx)
        if selected then
            y = y - 6
        end
        renderSpell(spellId, x, y-4, selected, affordable)
        local id = "spell" .. i
        if usable and iml.wasJustClicked(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, 1, id) then
            self.selectedIndex = i
        end
        iml.panel(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, id)
        if iml.isHovered(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, id) then
            self.hoveredSpell = spellId
        end
    end
end




---@param self g.HUD
---@param opt g.hudArgs
---@param region kirigami.Region
local function drawArmyBar(self, opt, region)
    self.hoveredSquad = nil
    self.hoveredSpell = nil
    local _, idx = getValidSelection(self)
    local spellsActive = spellsAreActive(self)

    local squadRegion, _, spellRegion

    if opt.battleScene then
        if opt.battleStarted then
            -- spells should control the space
            squadRegion, _, spellRegion = region:splitHorizontal(0.3, 0.05, 0.65)
        else
            -- else, should show mainly squads.
            squadRegion, _, spellRegion = region:splitHorizontal(0.65, 0.05, 0.3)
        end
    else
        squadRegion, _, spellRegion = region:splitHorizontal(0.65, 0.05, 0.3)
    end
    drawSquadsSection(self, squadRegion, (not spellsActive) and idx or nil)
    drawSpellsSection(self, spellRegion, spellsActive and idx or nil)
end








---@param r kirigami.Region
local function drawBlessingBar(r)
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
    lg.setColor(objects.Color("FF145914"))

    do
    local xpW = (xp/xpReq) * xpBar.w
    local stencilReg = xpBar:shrinkTo(xpW, xpBar.h)
    lg.setStencilMode("draw", 1)
    local sh = gsman.setShader(helper.alphaTestShader)
    ui.drawSingleColorPanel(stencilReg:get())
    sh:pop()
    lg.setStencilMode("test", 1)
    local ox = math.sin(love.timer.getTime() * 0.3) * 8
    local oy = math.cos(love.timer.getTime() * 0.21) * 4
    lg.setColor(1, 1, 1)
    -- Need to tile this otherwise it won't extend through the whole bar
    local bgBarW = g.getImageSize("army_healthbar_background")
    g.drawImageOffset("army_healthbar_background", xpBar.x + ox, xpBar.y + xpBar.h/2 + oy, 0, nil, nil, 0.5, 0.5)
    g.drawImageOffset("army_healthbar_background", xpBar.x + ox + bgBarW, xpBar.y + xpBar.h/2 + oy, 0, nil, nil, 0.5, 0.5)
    lg.setStencilMode()
    lg.clear(false, true)
    end

    -- draw xp text
    local txt1 = helper.wrapRichtextColor(objects.Color("FF80BD51"),("%d"):format(xp))
    local txt2 = helper.wrapRichtextColor(objects.Color("FF1F6525"), ("/%d"):format(xpReq))
    richtext.printRichContainedNoWrap(txt1..txt2, smallFont, rightTop:get())
end




local function drawTopBar()
    local r = ui.getScreenRegion()
    local topBar, mainBar = r:splitVertical(0.1,0.9)
    iml.panel(topBar:get())

    local xp, demonFury, gold, keys, daysTillIncursion, zoneString, pausePanel = topBar:splitHorizontal(4, 2,2,2, 4,4,1)
    --[[
    each of these ^^^ are panels.

    demonFury: shows current Demon Fury. When hovered, explains what Demon Fury is (use hoverService) 
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

    local function drawPanel(region, text, hoverText)
        local x, y, w, h = region:get()
        local txtR = region:padRatio(0.6)
        lg.setColor(1, 1, 1)
        local DY = 30
        ui.drawDarkPanel(x, y-DY, w, h+DY)
        lg.setColor(1, 1, 1)
        richtext.printRichContainedNoWrap(text, font, txtR:get())
        if hoverText and iml.isHovered(x, y, w, h, text) then
            hoverService.requestHover(function(box, fonts)
                box:addText("{c r=0.7 g=0.7 b=0.75}" .. hoverText, fonts.body)
            end)
        end
    end

    drawXpBar(xp)

    local furyHover = run.demonFury <= 0 and LOC_HOVER_FURY_ZERO or LOC_HOVER_FURY({pct = run.demonFury * 10})
    drawPanel(demonFury, "{demonfury_icon}{c r=0.6 g=0.1 b=0}  " .. tostring(run.demonFury), furyHover)
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
    local px, py, pw, ph = pausePanel:get()
    if iml.wasJustClicked(px, py, pw, ph, 1, "pause_button") then
        settingsPopupService.show()
    end
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
---@param noDraw boolean?
local function drawManaBox(self, noDraw)
    local img = "hud_bottom_left_mana_box"
    local w,h = g.getImageSize(img)
    if noDraw then
        return w,h
    end
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
        local y = cy + (r.h/4) * math.cos(t + i*rdiff)
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
---@param opt g.hudArgs
local function drawBottomBar(self, opt, barHeight)
    local w,h = drawManaBox(self, true)

    local sw, sh = ui.getScaledUIDimensions()
    local run = g.getRun()
    local region = Kirigami(0, sh - barHeight, sw, barHeight)

    iml.panel(region:get())

    local manaBox, rest = region:splitHorizontal(w,sw-w)
    local squadBar,blessingBar = rest:splitHorizontal(2,1)

    -- Squad box
    ui.drawDarkPanel(squadBar:get())
    drawArmyBar(self, opt, squadBar:padUnit(6))

    -- Blessing box
    ui.drawDarkPanel(blessingBar:get())
    drawBlessingBar(blessingBar)

    drawManaBox(self, false)
end



--- Returns the largest centered square in the area the HUD doesn't cover.
---@return kirigami.Region
function HUD:getFreeArea()
    local barHeight = SQUAD_ICON_SIZE + 30
    local _, mainBar = ui.getScreenRegion():splitVertical(0.1, 0.9)
    local middle = mainBar:splitVerticalExact(0, barHeight)
    return middle
end

---@param opt g.hudArgs
function HUD:drawUI(opt)
    self.battleStarted = opt.battleStarted or false
    drawTopBar()

    drawBottomBar(self, opt, SQUAD_ICON_SIZE + 30)

    local hoveredSquadId = (opt.hoverSquad and opt.hoverSquad.id) or (self.hoveredSquad and self.hoveredSquad.squadId)
    if hoveredSquadId then
        local main = ui.getScreenRegion()
        local _, left = main:padRatio(0.2):splitHorizontal(2, 1)
        local showUpgrade = not not (opt.hoverSquad and opt.hoverSquad.showUpgrade)
        ui.drawSquadCard(hoveredSquadId, left:padRatio(0.1), -999, showUpgrade, true)
    elseif self.hoveredSpell then
        local main = ui.getScreenRegion()
        local _, left = main:padRatio(0.2):splitHorizontal(2, 1)
        ui.drawSpellCard(self.hoveredSpell, left:padRatio(0.1), -999)
    end

    rewardPopupService.draw()
    choicePopupService.draw()
    nodeEventService.draw()
    gameoverPopupService.draw()
    hoverService.draw()
end

--- Returns the current selection: either a spell or a squad.
--- ("spell", spellId) | ("squad", g.Squad) | nil
---@return ("spell"|"squad")? type
---@return string|g.Squad|nil selection
function HUD:getSelection()
    local list, idx = getValidSelection(self)
    if not idx then return nil end
    local item = list[idx]
    if type(item) == "string" then
        return "spell", item
    end
    return "squad", item
end

---@param visibleIndex integer 1..9, position among items shown in the active pool
function HUD:selectVisibleSlot(visibleIndex)
    local list = getActiveList(self)
    if visibleIndex >= 1 and visibleIndex <= #list then
        self.selectedIndex = visibleIndex
    end
end

function HUD:wheelmoved(dx, dy)
    local dir = dy > 0 and -1 or 1
    local list = getValidSelection(self)
    local total = #list
    if total == 0 then return end
    local from = self.selectedIndex or 1
    for offset = 1, total do
        local j = from + offset * dir
        if j >= 1 and j <= total and isItemUsable(self, list[j]) then
            self.selectedIndex = j
            return
        end
    end
end

return HUD
