

local hoverService = require("src.hud.hoverService")

---@class g.HUD: objects.Class
local HUD = objects.Class("g:HUD")



function HUD:init()
    self.selectedSquadIndex = 1
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
local LOC_ZONE = loc("Zone 1 - Forest", {}, {context="HUD top bar, current zone name. Hardcoded stub"})
local LOC_PAUSE = loc("II", {}, {context="HUD top bar, pause button icon text"})

local LOC_HOVER_RAGE = loc("Demon Rage increases over time, making enemies stronger.", {}, {context="Tooltip when hovering demon rage in HUD"})
local LOC_HOVER_GOLD = loc("Gold is used to buy items and upgrades at shops.", {}, {context="Tooltip when hovering gold in HUD"})
local LOC_HOVER_DAYS = loc("Days remaining until the next Incursion!", {}, {context="Tooltip when hovering days-till-incursion in HUD. After X number of days, players will be forced to fight a 'boss'"})

local TOP_BAR_FONT = g.getSmallFont(16)

---@param army g.Squad[]
---@param from integer
---@param dir integer -- +1 or -1
local function findNextUndeployed(army, from, dir)
    for i = from, dir > 0 and #army or 1, dir do
        if not army[i].deployed then return i end
    end
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
local function drawArmyWidgets(self)
    local sw, sh = ui.getScaledUIDimensions()

    local army = g.getArmy()
    -- if army has changed; make sure it's clamped
    self.selectedSquadIndex = helper.clamp(math.floor(self.selectedSquadIndex + 0.5), 1, #army)

    if #army <= 0 then
        return
    end
    local count = #army
    local totalW = count * SQUAD_ICON_SIZE + (count - 1) * SQUAD_PADDING
    local startX = 20
    local baseY = sh - SQUAD_ICON_SIZE - 10
    for i, sq in ipairs(army) do
        local x = startX + (i - 1) * (SQUAD_ICON_SIZE + SQUAD_PADDING)
        local y = baseY
        local selected = (i == self.selectedSquadIndex)
        if selected then
            y = y - 6
        end
        renderSquad(sq, x, y, SQUAD_ICON_SIZE, selected)
        if not sq.deployed and iml.wasJustClicked(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, 1, i) then
            self.selectedSquadIndex = i
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
local function drawBattleHUD(self)
    drawArmyWidgets(self)
end

---@param self g.HUD
local function drawMapHUD(self)
    drawArmyWidgets(self)
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



function HUD:getSelectedSquad()
    local army = g.getArmy()
    -- find nearest undeployed, searching forward then backward
    local idx = findNextUndeployed(army, self.selectedSquadIndex, 1)
        or findNextUndeployed(army, self.selectedSquadIndex, -1)
    if not idx then return nil end
    self.selectedSquadIndex = idx
    return army[idx], idx
end



function HUD:wheelmoved(dx, dy)
    local army = g.getArmy()
    local dir = dy > 0 and 1 or -1
    local next = findNextUndeployed(army, self.selectedSquadIndex + dir, dir)
    if next then
        self.selectedSquadIndex = next
    end
end



return HUD

