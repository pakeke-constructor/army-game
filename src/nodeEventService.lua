
local EVENT_TYPES = require("src.content.events.events")


---@class g.nodeEventService
---@field _activeRandomEventPass g.RandomEventPass?
---@field _popup string?
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
    return not not (nodeEventService._activeRandomEventPass or nodeEventService._popup)
end



local SHRINE_TXT = loc("A bloodstained shrine hums. Offer a squad for coin and calmer demons, or empower your army.")
local SHRINE_SACRIFICE = loc("Sacrifice a squad.\n(-2 demon-rage, +30 gold)")
local SHRINE_NO_SAC = loc("No squad to sacrifice.")
local SHRINE_UPGRADE = loc("Upgrade a squad.")

local FOUNTAIN_TXT = loc("A serene fountain bubbles before you. Drink, and choose its gift.")
local FOUNTAIN_RAGE = loc("Calm the demons.\n(Reduce demon-rage)")
local FOUNTAIN_BLESSING = loc("Receive a blessing.")

local FEAST_TXT = loc("A grand feast is laid out for your troops.")
local FEAST_REWARD = loc("Feast.\n(+4 XP)")

local SACRIFICE_RAGE_REDUCTION = 2
local SACRIFICE_GOLD = 30
local FOUNTAIN_RAGE_REDUCTION = 2
local FEAST_XP = 4

local function closePopup()
    nodeEventService._popup = nil
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


---@return kirigami.Region
local function drawBasicWindow()
    local screen = ui.getFullScreenRegion()
    lg.setColor(1,1,1)
    iml.panel(0,0,screen:get())
    lg.setColor(0,0,0,.5)
    lg.rectangle("fill",screen:get())

    local _,window,_ = screen:splitHorizontal(1,5,1)
    window = window:padRatio(0.3)
    lg.setColor(1,1,1)
    ui.drawDarkPanel(window:get())
    return window
end


---@param popupName string
local function openPopup(popupName)
    if nodeEventService.isActive() then return end
    nodeEventService._popup = popupName
end

function nodeEventService.openShrinePopup() openPopup("shrine") end
function nodeEventService.openFountainPopup() openPopup("fountain") end
function nodeEventService.openFeastPopup() openPopup("feast") end




local function drawChoiceButton(reg, txt, font)
    reg = reg:padRatio(0.1)
    if iml.isHovered(reg:get()) then
        lg.setColor(0.6,0.6,0.6)
    else
        lg.setColor(1,1,1)
    end
    ui.drawDarkPanel(reg:get())
    richtext.printRichContained(txt, font, reg:padRatio(0.1):get())
    return iml.wasJustClicked(reg:get())
end


---@param txt string
---@return kirigami.Region buttonsR, table font
local function beginPopup(txt)
    local window = drawBasicWindow():padRatio(0.2)
    local font = g.getSmallFont(16)
    local txtR, buttonsR = window:splitVertical(2,1)
    richtext.printRichContained(txt, font, txtR:padRatio(0.2):get())
    return buttonsR, font
end


local function drawShrinePopup()
    local buttonsR, font = beginPopup(SHRINE_TXT)

    local leftR, rightR = buttonsR:splitHorizontal(1,1)
    local squads = getArmySquads()
    local hasSquad = #squads > 0
    local leftTxt = hasSquad and SHRINE_SACRIFICE or SHRINE_NO_SAC

    if drawChoiceButton(leftR, leftTxt, font) and hasSquad then
        g.removeSquadFromArmy(helper.randomChoice(squads))
        reduceDemonRage(SACRIFICE_RAGE_REDUCTION)
        closePopup()
        rewardPopupService.genericReward({ gold = SACRIFICE_GOLD })
    end

    if drawChoiceButton(rightR, SHRINE_UPGRADE, font) then
        closePopup()
        choicePopupService.set("squad", 0)
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


---@param ev g.RandomEventPass
local function drawRandomEvent(ev)
    local window = drawBasicWindow()

    local font = g.getSmallFont(16)
    local txtR, buttonsR = window:splitVertical(2,1)
    richtext.printRichContained(ev.text, font, txtR:padRatio(0.3):get())

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
        richtext.printRichContained(txt, font, txtReg:get())
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
}

function nodeEventService.draw()
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
