
local EVENT_TYPES = require("src.content.events.events")



local eventService = {}




---@class g.EventPass: objects.Class
local EventPass = objects.Class("g:EventPass")

function EventPass:init()
    --todo
end

function EventPass:leave()
    --todo
end





function eventService.startRandomEvent()
    -- pick from pool, do event
    local buf = {}
    for evId, evType in pairs(EVENT_TYPES) do
        table.insert(buf, evId)
    end
    local idd = helper.randomChoice(buf)
    local evtype = EVENT_TYPES[idd]

    -- TODO: wire up event-pass here?

    -- and start event somehow?
end



function eventService.draw()
    -- called every frame (whilst in map scene)
    -- IMPORTANT: 
    local screen = ui.getFullScreenRegion()
    iml.panel(screen:get())
    lg.setColor(0,0,0,.5)
    lg.rectangle("fill",screen:get())

    -- draw event window.
    local window = screen:splitHorizontal(1,5,1)
    window = window:padRatio(0.3) -- todo, adjust this
    ui.drawDarkPanel(window:get())
end



return eventService



