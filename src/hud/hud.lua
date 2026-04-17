

local hoverService = require("src.hud.hoverService")

---@class g.HUD: objects.Class
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

local LOC_DEMON_RAGE = interp("{demon_pitchfork}Demon Rage: %{n}", {context="HUD top bar, shows current demon rage level"})
local LOC_GOLD = interp("{coin_icon} Coins: %{n}", {context="HUD top bar, shows player's coin currency"})
local LOC_DAYS = interp("%{n} days until {c r=1 g=0.3 b=0.3}attack", {context="HUD top bar, countdown to next demon incursion. 'attack' is richtext-colored red"})
local LOC_ZONE = loc("{c r=0.2 g=0.5 b=0.3}Zone 1 - Forest", {}, {context="HUD top bar, current zone name. Hardcoded stub"})
local LOC_PAUSE = loc("II", {}, {context="HUD top bar, pause button icon text"})

local LOC_MANA = interp("%{cur}/%{max}", {context="HUD bottom bar, mana display e.g. 30/30"})
local BOTTOM_BAR_FONT = g.getSmallFont(16)

local LOC_HOVER_RAGE = loc("Demon Rage increases over time, making enemies stronger.", {}, {context="Tooltip when hovering demon rage in HUD"})
local LOC_HOVER_GOLD = loc("Gold is used to buy items and upgrades at shops.", {}, {context="Tooltip when hovering gold in HUD"})
local LOC_HOVER_DAYS = loc("Days remaining until the next Incursion!", {}, {context="Tooltip when hovering days-till-incursion in HUD. After X number of days, players will be forced to fight a 'boss'"})

local TOP_BAR_FONT = g.getSmallFont(16)



--- ===== Squad / Spell selection:   =====
-- Unified slot system:
-- Squads and spells share a single selection index.
-- Slots 1..#army are squads, slots #army+1..#army+#spells are spells.
-- Scrolling/clicking wraps across both lists seamlessly.

--- Returns total number of selectable slots (squads + spells)

--- Returns total number of selectable slots (squads + spells)
---@return integer
local function getSlotCount()
    return #g.getArmy() + #g.getRun().spellList
end

--- Returns what a slot maps to.
---@param slot integer
---@return "squad"|"spell" type
---@return g.Squad|string entry -- squad object or spellId
---@return integer subIndex -- index within army or spells
local function getSlotInfo(slot)
    local army = g.getArmy()
    if slot <= #army then
        return "squad", army[slot], slot
    end
    local si = slot - #army
    return "spell", g.getRun().spellList[si], si
end

--- Returns whether a slot is currently available for selection.
---@param slot integer
---@return boolean
local function isSlotAvailable(slot)
    local typ, entry = getSlotInfo(slot)
    if typ == "squad" then
        return not entry.deployed
    else
        return g.getRun():getSpellCooldown(entry) == nil
    end
end

--- Returns the closest available slot to `from`, searching left first.
---@param from integer
---@return integer?
local function getClosestAvailableSlot(from)
    local total = getSlotCount()
    if total == 0 then return nil end
    from = helper.clamp(from, 1, total)
    for offset = 0, total - 1 do
        local left = from - offset
        if left >= 1 and isSlotAvailable(left) then return left end
        local right = from + offset
        if right <= total and isSlotAvailable(right) then return right end
    end
    return nil
end

--- Returns the selected slot index, snapped to nearest available.
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
---@param size number
---@param selected boolean
local function renderSquad(sq, x, y, size, selected)
    if selected then
        lg.setColor(1, 1, 1, 0.3)
        --lg.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 4, 4)
        ui.drawSingleColorPanel(x - 2, y - 2, size + 4, size + 4)
    end
    if sq.deployed then
        lg.setColor(1, 1, 1, 0.3)
    else
        lg.setColor(1, 1, 1)
    end
    g.drawSquadIcon(sq.squadId, x, y, size, size)
end



---@param self g.HUD
---@param region kirigami.Region
---@param currentSlot integer?
local function drawSquadBar(self, region, currentSlot)
    local army = g.getArmy()

    if #army <= 0 then
        return
    end
    local count = #army
    local EDGE_PAD = 20

    -- expand region if too small
    local neededW = count * SQUAD_ICON_SIZE + (count - 1) * SQUAD_PADDING + 2 * EDGE_PAD
    local neededH = SQUAD_ICON_SIZE + 2 * EDGE_PAD
    if region.w < neededW then
        region = region:set(nil, nil, neededW, nil)
    end
    if region.h < neededH then
        region = region:set(nil, nil, nil, neededH)
    end

    -- inner region after edge padding
    local inner = region:padUnit(EDGE_PAD)

    -- space squads evenly
    local spacing
    if count > 1 then
        spacing = (inner.w - count * SQUAD_ICON_SIZE) / (count - 1)
    else
        spacing = 0
    end
    local startX = inner.x
    if count == 1 then
        startX = inner.x + (inner.w - SQUAD_ICON_SIZE) / 2
    end
    local baseY = inner.y + (inner.h - SQUAD_ICON_SIZE) / 2

    for i, sq in ipairs(army) do
        local x = startX + (i - 1) * (SQUAD_ICON_SIZE + spacing)
        local y = baseY
        local selected = (i == currentSlot)
        if selected then
            y = y - 6
        end
        renderSquad(sq, x, y, SQUAD_ICON_SIZE, selected)
        if not sq.deployed and iml.wasJustClicked(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, 1, i) then
            self.selectedSlot = i
        end
        iml.panel(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, i)
        if iml.isHovered(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, i) then
            local info = g.getSquadInfo(sq.squadId)
            local mx, my = ui.getMouse()
            hoverService.requestHover(mx, my, function(box, fonts)
                box:addText("{c r=0.9 g=0.85 b=0.7}" .. info.name, fonts.title)
                box:addSpacing(2)
                box:addText("{c r=0.7 g=0.7 b=0.75}" .. info.count .. "x " .. info.entityId, fonts.body)
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
    end
end



local function drawTopBar()
    local r = ui.getScreenRegion()
    local topBar = r:splitVertical(0.1,0.9)

    -- 3 steps:

    local demonRage, gold, daysTillIncursion, zoneString, pausePanel = topBar:splitHorizontal(2,2,4,4,1)
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
    -- draw panels
    local run = g.getRun()
    local font = TOP_BAR_FONT
    local fh = font:getHeight()

    local function drawPanel(region, text, hoverText)
        local x, y, w, h = region:get()
        ui.drawDarkPanel(x, y, w, h)
        lg.setColor(1, 1, 1)
        richtext.printRich(text, font, x, y + h / 2 - fh / 2, w, "center")
        if hoverText and iml.isHovered(x, y, w, h, text) then
            local mx, my = ui.getMouse()
            hoverService.requestHover(mx, my, function(box, fonts)
                box:addText("{c r=0.7 g=0.7 b=0.75}" .. hoverText, fonts.body)
            end)
        end
    end

    drawPanel(demonRage, LOC_DEMON_RAGE({n = run.demonRage}), LOC_HOVER_RAGE)
    drawPanel(gold, LOC_GOLD({n = run.money}), LOC_HOVER_GOLD)

    -- days till incursion: slightly taller
    local dx, dy, dw, dh = daysTillIncursion:get()
    local extraH = dh * 0.05
    local dtiRegion = daysTillIncursion:padUnit(0, -extraH, 0, 0)
    drawPanel(dtiRegion, LOC_DAYS({n = run:getDaysUntilIncursion()}), LOC_HOVER_DAYS)

    drawPanel(zoneString, LOC_ZONE)

    drawPanel(pausePanel, LOC_PAUSE)
end




---@param self g.HUD
---@param spellId string
---@param cell kirigami.Region
---@param slot number
---@param selected boolean
local function drawSpell(self, spellId, cell, slot, selected)
    local info = g.getSpellInfo(spellId)
    cell = cell:padRatio(0.3)
    if selected then
        cell = cell:moveUnit(0, -6)
    end
    local _,iconRegion, costRegion,_ = cell:splitVertical(1, 3, 1, 1)
    local ix, iy = iconRegion:getCenter()
    local font = BOTTOM_BAR_FONT
    local fh = font:getHeight()
    local mc = g.COLORS.MANA
    if selected then
        lg.setColor(mc.r,mc.g,mc.b, 0.4)
        local r = math.min(iconRegion.w, iconRegion.h) * 0.6
        lg.circle("fill", ix, iy, r)
    end
    lg.setColor(1, 1, 1)
    g.drawImage(info.icon, ix, iy)
    local costText = tostring(info.manaCost)
    local costW = font:getWidth(costText)
    local ccx, ccy = costRegion:getCenter()
    lg.setColor(g.COLORS.MANA)
    lg.print(costText, font, ccx - costW / 2, ccy - fh / 2)
    local cx, cy, cw, ch = cell:get()
    if iml.isHovered(cx, cy, cw, ch) then
        local mx, my = ui.getMouse()
        hoverService.requestHover(mx, my, function(box, fonts)
            box:addText("{c r=0.9 g=0.85 b=0.7}" .. info.name, fonts.title)
            box:addSpacing(2)
            box:addText("{c r=0.6 g=0.6 b=0.65}" .. info.description, fonts.body)
        end)
    end
    if iml.wasJustClicked(cx, cy, cw, ch) then
        self.selectedSlot = slot
    end
end

---@param self g.HUD
---@param barHeight number
local function drawBottomBar(self, barHeight)
    -- bottom bar:

    local sw, sh = ui.getScaledUIDimensions()

    local run = g.getRun()
    local region = Kirigami(0, sh - barHeight, sw, barHeight)
    local squadBar, manaBox, blessingBox = region:splitHorizontal(2,1,1)

    local currentSlot = getSlotIndex(self)
    ui.drawDarkPanel(squadBar:get())
    drawSquadBar(self, squadBar:padUnit(6), currentSlot)

    -- mana-box:
    -- Spells layed out horizontally. Spell-icon, then mana-cost below the spell with g.COLORS.MANA color.
    -- above, (manaBar) there is a mana-bar, alongside a 30/30 mana count.
    -- CRUCIALLY: images should be drawn AS IS; no scaling with g.drawImageContained.
    lg.setColor(1,1,1)
    ui.drawDarkPanel(manaBox:get())
    local manaBar, spellBox = manaBox:padUnit(6):splitVertical(1, 3)

    -- mana bar
    local mbx, mby, mbw, mbh = manaBar:padRatio(0.3):get()
    local font = BOTTOM_BAR_FONT
    local fh = font:getHeight()
    lg.setColor(0.15, 0.15, 0.2, 0.8)
    lg.rectangle("fill", mbx, mby, mbw, mbh)
    local manaRatio = run.maxMana > 0 and (run.mana / run.maxMana) or 0
    local mc = g.COLORS.MANA
    lg.setColor(mc.r, mc.g, mc.b, 0.7)
    lg.rectangle("fill", mbx, mby, mbw * manaRatio, mbh)
    lg.setColor(1, 1, 1)
    local manaText = LOC_MANA({cur = math.floor(run.mana), max = math.floor(run.maxMana)})
    richtext.printRich(manaText, font, mbx, mby + mbh / 2 - fh / 2, mbw, "center")

    -- spells
    local spellIds = g.getRun().spellList
    if #spellIds > 0 then
        local cells = spellBox:grid(#spellIds, 1)
        for i, spellId in ipairs(spellIds) do
            local slot = #g.getArmy() + i
            drawSpell(self, spellId, cells[i], slot, slot == currentSlot)
        end
    end

    -- blessing box:
    -- a grid of blessings.  Use helper.getBestFitDimensions(numItems, widthRatio, heightRatio)
    -- Only show icons. when blessing is hovered, push a UI box. 
    -- (DONT IMPLEMENT HOVER FOR NOW, ITS TOO COMPLEX. JUST DO A STUB.)
    -- CRUCIALLY: images should be drawn AS IS; no scaling with g.drawImageContained.
    lg.setColor(1,1,1)
    ui.drawDarkPanel(blessingBox:get())
    local blessings = run.blessings
    if #blessings > 0 then
        local padded = blessingBox:padUnit(6)
        local cols, rows = helper.getBestFitDimensions(#blessings, padded.w, padded.h)
        local cells = padded:grid(cols, rows)
        for i, bId in ipairs(blessings) do
            local info = g.getBlessingInfo(bId)
            local cx, cy = cells[i]:getCenter()
            lg.setColor(1, 1, 1)
            g.drawImage(info.image, cx, cy)
        end
    end
end


---@param self g.HUD
local function drawBattleHUD(self)
    drawBottomBar(self, SQUAD_ICON_SIZE + 60)
end

---@param self g.HUD
local function drawMapHUD(self)
    local sw, sh = ui.getScaledUIDimensions()
    local region = Kirigami(0, sh - SQUAD_ICON_SIZE - 40, sw/2, SQUAD_ICON_SIZE + 40)
    drawSquadBar(self, region, getSlotIndex(self))
end



---@param opt g.hudArgs
function HUD:drawUI(opt)
    local sw, sh = ui.getScaledUIDimensions()

    drawTopBar()

    if opt.battleScene then
        drawBattleHUD(self)
    elseif opt.mapScene then
        drawMapHUD(self)
    end

    hoverService.draw()
end


--- Returns the type and entry of the current selection, snapping to nearest available.
---@return "squad"|"spell"|nil type
---@return g.Squad|string|nil entry
---@return integer|nil subIndex
function HUD:getSelection()
    local idx = getSlotIndex(self)
    if not idx then return nil end
    return getSlotInfo(idx)
end

---@return g.Squad? squad
---@return integer? armyIndex
function HUD:getSelectedSquad()
    local typ, entry, sub = self:getSelection()
    if typ == "squad" then return entry, sub end
    return nil
end

---@return string? spellId
---@return integer? spellIndex
function HUD:getSelectedSpell()
    local typ, entry, sub = self:getSelection()
    if typ == "spell" then return entry, sub end
    return nil
end

function HUD:wheelmoved(dx, dy)
    local dir = dy > 0 and 1 or -1
    local total = getSlotCount()
    local next = self.selectedSlot + dir
    if next >= 1 and next <= total then
        self.selectedSlot = next
    end
end



return HUD

