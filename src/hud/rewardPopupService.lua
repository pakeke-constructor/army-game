---@class g.rewardPopupService
local rewardPopupService = {}

local active = nil

function rewardPopupService.push(data)
    active = data
end

function rewardPopupService.pop()
    local data = active
    active = nil
    return data
end

function rewardPopupService.getActive()
    return active
end

function rewardPopupService.draw()
    if not active then return end
end

return rewardPopupService
