
local EVENT_TYPES = require("src.content.events.events")


---@class g.nodeEventService
---@field _activeRandomEventPass g.RandomEventPass?
---@field _shrinePopup boolean?
---@field _fountainPopup boolean?
---@field _feastPopup boolean?
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

--- RandomEventPass
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
    return not not (
        nodeEventService._activeRandomEventPass
        or nodeEventService._shrinePopup
        or nodeEventService._fountainPopup
        or nodeEventService._feastPopup
    )
end



---@param node MapNode?
function nodeEventService.openShrinePopup(node)
    if nodeEventService.isActive() then return end

end




---@param node MapNode?
function nodeEventService.openFountainPopup(node)
    if nodeEventService.isActive() then return end

end



---@param node MapNode?
function nodeEventService.openFeastPopup(node)
    if nodeEventService.isActive() then return end

end


---@param ev g.RandomEventPass
local function drawRandomEvent(ev)
    local screen = ui.getFullScreenRegion()
    lg.setColor(1,1,1)
    iml.panel(screen:get())
    lg.setColor(0,0,0,.5)
    lg.rectangle("fill",screen:get())

    local _,window,_ = screen:splitHorizontal(1,5,1)
    window = window:padRatio(0.3)
    lg.setColor(1,1,1)
    ui.drawDarkPanel(window:get())

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



function nodeEventService.draw()
    local ev = nodeEventService._activeRandomEventPass
    if ev then
        return drawRandomEvent(ev)
    end

end


return nodeEventService
