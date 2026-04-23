---@class g.choicePopupService
local choicePopupService = {}

local active = nil

function choicePopupService.push(data)
    active = data
end

function choicePopupService.pop()
    local data = active
    active = nil
    return data
end

function choicePopupService.getActive()
    return active
end

function choicePopupService.draw()
    if not active then return end
end

return choicePopupService
