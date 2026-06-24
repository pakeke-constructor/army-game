
local EVENT_TYPES = require("src.content.events.events")
local ChestOpen = require("src.ui.ChestOpen")


---@class g.nodeEventService
---@field _activeRandomEventPass g.RandomEventPass?
---@field _popup string?
---@field _popupData any
---@field _chest g.ChestOpen?
local nodeEventService = {}


---@class g.EventOption
---@field [1] string
---@field [2] fun(evPass: g.RandomEventPass)

---@class g.RandomEventPass: objects.Class
---@field id string
---@field eventType g.RandomEventType
---@field text string
---@field options g.EventOption[]
---@field _selectedOption integer?
local RandomEventPass = objects.Class("g:RandomEventPass")

-- RandomEventPass
do
---@param id string
---@param evType g.RandomEventType
function RandomEventPass:init(id, evType)
    self.id = id
    self.eventType = evType
    self.text = evType.description
    self.options = {}
    self._selectedOption = nil
end

---@param options g.EventOption[]?
function RandomEventPass:setOptions(options)
    self.options = options or {}
end

---@param txt string
function RandomEventPass:changeText(txt)
    self.text = txt
end

function RandomEventPass:deleteThisOption()
    if not self._selectedOption then return end
    table.remove(self.options, self._selectedOption)
    self._selectedOption = nil
end

function RandomEventPass:leave()
    if nodeEventService._activeRandomEventPass == self then
        nodeEventService._activeRandomEventPass = nil
    end
end

end



---@return g.RandomEventPass?
function nodeEventService.startRandomEvent()
    if nodeEventService.isActive() then return end

    ---@type string[]
    local buf = {}
    for evId in pairs(EVENT_TYPES) do
        table.insert(buf, evId)
    end
    if #buf == 0 then return nil end

    local eventId = helper.randomChoice(buf)
    local evType = EVENT_TYPES[eventId]
    if not evType then return nil end

    local pass = RandomEventPass(eventId, evType)
    nodeEventService._activeRandomEventPass = pass
    evType.run(pass)
    return pass
end



---@return boolean
function nodeEventService.isActive()
    return not not (nodeEventService._activeRandomEventPass or nodeEventService._popup or nodeEventService._chest)
end



local SHRINE_TXT = loc("A bloodstained shrine hums. Offer a squad for coin and calmer demons, or empower your army.")
local SHRINE_SACRIFICE = interp("Sacrifice %{squadName}.\n(-3 demon-rage)", {
    context = "Shrine popup option text. %{squadName} is exact squad that will be removed"
})
local SHRINE_NO_SAC = loc("No squad to sacrifice.")
local SHRINE_UPGRADE = loc("Upgrade a squad.")

local FOUNTAIN_TXT = loc("A serene fountain bubbles before you. Drink, and choose its gift.")
local FOUNTAIN_RAGE = loc("Calm the demons.\n(Reduce demon-rage)")
local FOUNTAIN_BLESSING = loc("Receive a blessing.")

local FEAST_TXT = loc("A grand feast is laid out for your troops.")
local FEAST_REWARD = loc("Feast.\n(+4 {xp_icon})")

local PORTAL_TXT = loc("Mysterious Gateway\nTravel to a random node.")
local PORTAL_ENTER = loc("Enter Portal")
local PORTAL_LEAVE = loc("Leave")

local SACRIFICE_RAGE_REDUCTION = 3
local FOUNTAIN_RAGE_REDUCTION = 2
local FEAST_XP = 4

local CHEST_TXT = loc("A big chest mmmm.")
local CHEST_OPEN = loc("Open it!")  -- load-time, like the others

local function closePopup()
    nodeEventService._popup = nil
    nodeEventService._popupData = nil
end

local function reduceDemonRage(amount)
    local run = g.getRun()
    run.demonRage = math.max(0, run.demonRage - amount)
end

---@return g.Squad[]
local function getArmySquads()
    local out = {}
    for _, squad in pairs(g.getRun().squads) do
        out[#out + 1] = squad
    end
    return out
end


---@param squad g.Squad
---@return number
local function getShrineSacrificeValue(squad)
    local info = g.getSquadInfo(squad.squadId)
    local value = squad.level or 1
    if info.entityDef and info.entityDef.isCommander then
        value = value + 1000
    end
    return value
end


---@return g.Squad?
local function pickShrineSacrificeSquad()
    local squads = getArmySquads()
    table.sort(squads, function(a, b)
        local va = getShrineSacrificeValue(a)
        local vb = getShrineSacrificeValue(b)
        if va ~= vb then return va < vb end
        return a.squadId < b.squadId
    end)
    return squads[1]
end


---@return kirigami.Region
local function drawBasicWindow()
    local screen = ui.getFullScreenRegion()
    lg.setColor(1,1,1)
    iml.panel(screen:get())
    lg.setColor(0,0,0,.5)
    lg.rectangle("fill",screen:get())

    local _,window,_ = screen:splitHorizontal(1,5,1)
    window = window:padRatio(0.3)
    lg.setColor(1,1,1)
    ui.drawDarkPanel(window:get())
    return window
end


---@param popupName string
---@param popupData any
local function openPopup(popupName, popupData)
    if nodeEventService.isActive() then return end
    nodeEventService._popup = popupName
    nodeEventService._popupData = popupData
end

function nodeEventService.openShrinePopup()
    local squad = pickShrineSacrificeSquad()
    openPopup("shrine", squad and squad.squadId or nil)
end
function nodeEventService.openFountainPopup()
    openPopup("fountain")
end
function nodeEventService.openFeastPopup()
    openPopup("feast")
end
---@param node MapNode.PortalNode
function nodeEventService.openPortalPopup(node)
    if not (node and node.active) then return end
    openPopup("portal", node)
end
---@param node MapNode.ChestNode
function nodeEventService.openChestPopup(node)
    openPopup("chest")
end




local function drawChoiceButton(reg, txt, font)
    reg = reg:padRatio(0.1)
    if iml.isHovered(reg:get()) then
        lg.setColor(0.6,0.6,0.6)
    else
        lg.setColor(1,1,1)
    end
    ui.drawDarkPanel(reg:get())
    local x,y,w,h = reg:padRatio(0.1):get()
    richtext.printRichContained(txt, font, x,y,w,h, 1)
    return iml.wasJustClicked(reg:get())
end

local function drawButtonWithImage(reg, txt, image, font)
    reg = reg:padRatio(0.1)
    if iml.isHovered(reg:get()) then
        lg.setColor(0.6,0.6,0.6)
    else
        lg.setColor(1,1,1)
    end
    ui.drawDarkPanel(reg:get())

    local iconR, txtR = reg:padRatio(0.1):splitHorizontal(1, 4)
    lg.setColor(1,1,1)
    g.drawImage(image, iconR:getCenter())

    local x,y,w,h = txtR:padRatio(0.1):get()
    richtext.printRichContained(txt, font, x,y,w,h, 1)
    return iml.wasJustClicked(reg:get())
end


---@param txt string
---@return kirigami.Region buttonsR, table font
local function beginPopup(txt)
    local window = drawBasicWindow():padRatio(0.2)
    local font = g.getSmallFont(16)
    local txtR, buttonsR = window:splitVertical(2,1)

    local x,y,w,h = txtR:padRatio(0.2):get()
    richtext.printRichContained(txt, font, x,y,w,h, 1)
    return buttonsR, font
end


local function drawShrinePopup()
    local buttonsR, font = beginPopup(SHRINE_TXT)

    local leftR, rightR = buttonsR:splitHorizontal(1,1)
    local squadId = nodeEventService._popupData
    local squad = squadId and g.getRun().squads[squadId] or nil
    local hasSquad = squad ~= nil
    local leftTxt = hasSquad and SHRINE_SACRIFICE({ squadName = g.getSquadInfo(squadId).name }) or SHRINE_NO_SAC

    local squadInfo = hasSquad and g.getSquadInfo(squadId) or nil
    if drawButtonWithImage(leftR, leftTxt, squadInfo and squadInfo.icon or "example_squad_icon", font) and hasSquad then
        g.removeSquadFromArmy(squad)
        reduceDemonRage(SACRIFICE_RAGE_REDUCTION)
        closePopup()
    end

    if drawChoiceButton(rightR, SHRINE_UPGRADE, font) then
        closePopup()
        choicePopupService.set("upgrade_squad", 0)
    end
end


local function drawFountainPopup()
    local buttonsR, font = beginPopup(FOUNTAIN_TXT)

    local leftR, rightR = buttonsR:splitHorizontal(1,1)
    if drawChoiceButton(leftR, FOUNTAIN_RAGE, font) then
        reduceDemonRage(FOUNTAIN_RAGE_REDUCTION)
        closePopup()
    end
    if drawChoiceButton(rightR, FOUNTAIN_BLESSING, font) then
        closePopup()
        rewardPopupService.genericReward({ randomBlessing = true })
    end
end


local function drawFeastPopup()
    local buttonR, font = beginPopup(FEAST_TXT)

    if drawChoiceButton(buttonR, FEAST_REWARD, font) then
        closePopup()
        g.addXP(FEAST_XP)
    end
end

local function drawPortalPopup()
    local buttonsR, font = beginPopup(PORTAL_TXT)

    local leftR, rightR = buttonsR:splitHorizontal(1,1)
    if drawChoiceButton(leftR, PORTAL_ENTER, font) then
        closePopup()
        local scene, name = g.getCurrentScene()
        if name == "map_scene" then
            scene:_buildMap(true)
        end
    end
    if drawChoiceButton(rightR, PORTAL_LEAVE, font) then
        local node = nodeEventService._popupData
        if node then
            node.visited = false
        end
        closePopup()
    end
end


local function drawChestPopup()
    local buttonR, font = beginPopup(CHEST_TXT)  -- draws window + text, returns buttons region

    if drawChoiceButton(buttonR, CHEST_OPEN, font) then
        closePopup()
        local owned = g.getRun().blessings
        local pool = {}
        for _, id in ipairs(g.getBlessingList()) do
            if not owned[id] then pool[#pool + 1] = id end
        end
        if #pool == 0 then pool = g.getBlessingList() end -- all owned: fall back
        nodeEventService._chest = ChestOpen(helper.randomChoice(pool))
    end
end

---@param ev g.RandomEventPass
local function drawRandomEvent(ev)
    local window = drawBasicWindow()

    local font = g.getSmallFont(16)
    local txtR, buttonsR = window:splitVertical(2,1)
    local x,y,w,h = txtR:padRatio(0.3):get()
    richtext.printRichContained(ev.text, font, x,y,w,h, 1)

    local N = 4
    local buttons = buttonsR:grid(1, N)
    local i = N

    ---@param txt string
    ---@param func fun(evPass: g.RandomEventPass)
    local function button(txt, func)
        i = i - 1
        local reg = buttons[i]:padRatio(0.1)
        local txtReg = reg:padRatio(0.1)
        if iml.isHovered(reg:get()) then
            lg.setColor(0.6,0.6,0.6)
        else
            lg.setColor(1,1,1)
        end
        ui.drawDarkPanel(reg:get())
        local x,y,w,h = txtReg:get()
        richtext.printRichContained(txt, font, x,y,w,h, 1)
        if iml.wasJustClicked(reg:get()) then
            func(ev)
        end
    end

    for ii,b in ipairs(ev.options) do
        ev._selectedOption = ii
        button(b[1],b[2])
    end

end



local POPUP_DRAWERS = {
    shrine = drawShrinePopup,
    fountain = drawFountainPopup,
    feast = drawFeastPopup,
    portal = drawPortalPopup,
    chest = drawChestPopup,
}

function nodeEventService.draw()
    local chest = nodeEventService._chest
    if chest then
        chest:draw()
        if chest:isDone() then
            nodeEventService._chest = nil
            g.addBlessing(chest.blessingId)
        end
        return
    end

    local ev = nodeEventService._activeRandomEventPass
    if ev then
        return drawRandomEvent(ev)
    end
    local drawer = POPUP_DRAWERS[nodeEventService._popup]
    if drawer then
        return drawer()
    end
end


return nodeEventService
