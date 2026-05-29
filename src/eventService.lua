
local EVENT_TYPES = require("src.content.events.events")


---@class g.randomEventService
---@field _activeEventPass g.EventPass?
local randomEventService = {}


---@class g.EventOption
---@field [1] string
---@field [2] fun(evPass: g.EventPass)

---@class g.EventPass: objects.Class
---@field id string
---@field eventType g.RandomEventType
---@field text string
---@field options g.EventOption[]
---@field _selectedOption integer?
local EventPass = objects.Class("g:EventPass")

---@param id string
---@param evType g.RandomEventType
function EventPass:init(id, evType)
    self.id = id
    self.eventType = evType
    self.text = evType.description
    self.options = {}
    self._selectedOption = nil
end

---@param options g.EventOption[]?
function EventPass:setOptions(options)
    self.options = options or {}
end

---@param txt string
function EventPass:changeText(txt)
    self.text = txt
end

function EventPass:deleteThisOption()
    if not self._selectedOption then return end
    table.remove(self.options, self._selectedOption)
    self._selectedOption = nil
end

function EventPass:leave()
    if randomEventService._activeEventPass == self then
        randomEventService._activeEventPass = nil
    end
end

---@param eventId string
---@return g.EventPass?
function randomEventService.startEvent(eventId)
    local evType = EVENT_TYPES[eventId]
    if not evType then return nil end

    local pass = EventPass(eventId, evType)
    randomEventService._activeEventPass = pass
    evType.run(pass)
    return pass
end

---@return g.EventPass?
function randomEventService.startRandomEvent()
    ---@type string[]
    local buf = {}
    for evId in pairs(EVENT_TYPES) do
        table.insert(buf, evId)
    end
    if #buf == 0 then return nil end

    local idd = helper.randomChoice(buf)
    return randomEventService.startEvent(idd)
end

---@return g.EventPass?
function randomEventService.getActiveEvent()
    return randomEventService._activeEventPass
end

function randomEventService.draw()
    local ev = randomEventService._activeEventPass
    if not ev then return end

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
    ---@param func fun(evPass: g.EventPass)
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


return randomEventService
