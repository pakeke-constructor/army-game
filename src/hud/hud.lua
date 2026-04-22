
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

local LOC_DEMON_RAGE = interp("{demon_pitchfork}{c r=0.6 g=0.1 b=0} Rage: %{n}", {context="HUD top bar, shows current demon rage level"})
local LOC_GOLD = interp("{coin_icon} Coins: %{n}", {context="HUD top bar, shows player's coin currency"})
local LOC_DAYS = interp("%{n} days until {c r=1 g=0.3 b=0.3}attack", {context="HUD top bar, countdown to next demon incursion. 'attack' is richtext-colored red"})
local LOC_ZONE = loc("{c r=0.2 g=0.5 b=0.3}Zone 1 - Forest", {}, {context="HUD top bar, current zone name. Hardcoded stub"})
local LOC_PAUSE = loc("II", {}, {context="HUD top bar, pause button icon text"})

local LOC_HOVER_RAGE = loc("Demon Rage increases when you win a battle, making enemies stronger.", {}, {context="Tooltip when hovering demon rage in HUD"})
local LOC_HOVER_GOLD = loc("Gold is used to buy items and upgrades at shops.", {}, {context="Tooltip when hovering gold in HUD"})
local LOC_HOVER_DAYS = loc("Days remaining until the next Incursion!", {}, {context="Tooltip when hovering days-till-incursion in HUD. After X number of days, players will be forced to fight a 'boss'"})

local TOP_BAR_FONT = g.getSmallFont(16)

---@param slot integer
---@return boolean
local function isSlotAvailable(slot)
    local army = g.getArmy()
    local squad = army[slot]
    if (squad) and (not squad.deployed) and (squad.canAfford) then
        return true
    end
    return false
end

---@param from integer
---@return integer?
local function getClosestAvailableSlot(from)
    local army = g.getArmy()
    local total = #army
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
        ui.drawSingleColorPanel(x - 2, y - 2, size + 4, size + 4)
    end
    if sq.deployed then
        lg.setColor(0.15, 0.15, 0.15, 1)
    elseif (not sq.canAfford) then
        lg.setColor(1, 1, 1, 0.35)
    else
        lg.setColor(1, 1, 1)
    end
    g.drawSquadIcon(sq.squadId, x, y, size, size)
    local sqInfo = g.getSquadInfo(sq.squadId)
    if sqInfo then
        g.drawManaCost(sqInfo.cost, x+size/2,y, size + 6)
    end
end



---@param sq g.Squad
local function hoverSquad(sq)
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


---@param self g.HUD
---@param region kirigami.Region
local function drawSquadBar(self, region)
    local army = g.getArmy()
    if #army <= 0 then
        return
    end

    local currentSlot = getSlotIndex(self)
    local count = #army
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
    if count == 1 then
        startX = inner.x + (inner.w - SQUAD_ICON_SIZE) / 2
    end
    local baseY = inner.y + (inner.h - SQUAD_ICON_SIZE) / 2

    for i, sq in ipairs(army) do
        local x = startX + (i - 1) * step
        local y = baseY
        local selected = (i == currentSlot)
        if selected then
            y = y - 6
        end
        renderSquad(sq, x, y-4, SQUAD_ICON_SIZE, selected)
        if not sq.deployed and iml.wasJustClicked(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, 1, i) then
            self.selectedSlot = i
        end
        iml.panel(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, i)
        if iml.isHovered(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, i) then
            hoverSquad(sq)
        end
    end
end




---@param r kirigami.Region
local function drawLeftBlessingBar(r)
    local run = g.getRun()
    lg.setColor(1,1,1)
    ui.drawDarkPanel(r:get())
    local blessings = run.blessings
    if #blessings > 0 then
        local padded = r:padUnit(6)
        local cols, rows = helper.getBestFitDimensions(#blessings, padded.w, padded.h)
        local cells = padded:grid(cols, math.max(rows, 8))
        for i, bId in ipairs(blessings) do
            local info = g.getBlessingInfo(bId)
            local cx, cy = cells[i]:getCenter()
            lg.setColor(1, 1, 1)
            g.drawImage(info.image, cx, cy)
            local gx, gy, gw, gh = cells[i]:get()
            if iml.isHovered(gx, gy, gw, gh, "blessing" .. i) then
                local mx, my = ui.getMouse()
                hoverService.requestHover(mx, my, function(box, fonts)
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


local function drawManaBar(x,y, w,h, maxW)
    local run = g.getRun()
    local manaCells = run.mana
    local _, sceneName = g.getCurrentScene()
    if sceneName == "battle_scene" and run._battleMana then
        manaCells = run._battleMana
    end
    local cpy = helper.shallowCopy(manaCells) -- defensive copy before sorting
    table.sort(cpy)
    ---@cast cpy g.ManaCell[]

    local sf = g.getSmallFont(16)
    local txt
    if #manaCells > 0 then
        txt = "{wavy amp=0.4}" .. AVAILABLE_MANA
    else
        txt = "{c r=0.8 g=0.2 b=0.15}" .. NO_MANA
    end

    local WIDTH_PER_MANA = 20
    local hbox = ui.HBox({padding = 2, spacing = 2}, function(bx, by, bw, bh)
        lg.setColor(1,1,1)
        ui.drawDarkPanel(bx, by, bw, bh)
    end)
    hbox:addText(txt, sf)
    hbox:add({
        getWidth = function() return math.min(WIDTH_PER_MANA * #cpy, maxW) end,
        getHeight = function() return h end,
        draw = function(dx, dy, dw, dh)
            local grid = Kirigami(dx, dy, dw, dh):grid(#cpy, 1)
            lg.setColor(1,1,1)
            for i, mc in ipairs(cpy) do
                local rr = grid[i]
                g.drawManaCell(mc, rr.x + rr.w/2, rr.y + rr.h/2)
            end
        end,
    })
    local ww,hh = hbox:measure()
    local xx = (w - ww)/2
    hbox:render(x, y)
end




local function drawTopBar()
    local r = ui.getScreenRegion()
    local topBar, mainBar = r:splitVertical(0.1,0.9)

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

    local run = g.getRun()
    local font = TOP_BAR_FONT
    local fh = font:getHeight()

    local function drawPanel(region, text, hoverText)
        local x, y, w, h = region:get()
        lg.setColor(1, 1, 1)
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

    local _, _, _, dh = daysTillIncursion:get()
    local extraH = dh * 0.05
    local dtiRegion = daysTillIncursion:padUnit(0, -extraH, 0, 0)
    drawPanel(dtiRegion, LOC_DAYS({n = run:getDaysUntilIncursion()}), LOC_HOVER_DAYS)

    drawPanel(zoneString, LOC_ZONE)
    drawPanel(pausePanel, LOC_PAUSE)

    local leftBlessingBar = mainBar:splitVertical(0.7,0.3):splitHorizontal(0.06, 0.94)
    drawLeftBlessingBar(leftBlessingBar)
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

---@param self g.HUD
local function drawBattleHUD(self)
    drawBottomBar(self, SQUAD_ICON_SIZE + 30)
end

---@param self g.HUD
local function drawMapHUD(self)
    local sw, sh = ui.getScaledUIDimensions()
    local region = Kirigami(0, sh - SQUAD_ICON_SIZE - 40, sw/2, SQUAD_ICON_SIZE + 40)
    drawSquadBar(self, region)
end

---@param opt g.hudArgs
function HUD:drawUI(opt)
    drawTopBar()

    if opt.battleScene then
        drawBattleHUD(self)
    elseif opt.mapScene then
        drawMapHUD(self)
    end

    hoverService.draw()
end

---@return g.Squad? squad
function HUD:getSelection()
    local idx = getSlotIndex(self)
    if not idx then return nil end
    return g.getArmy()[idx]
end

function HUD:wheelmoved(dx, dy)
    local dir = dy > 0 and 1 or -1
    local total = #g.getArmy()
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
