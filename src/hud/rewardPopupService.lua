local RewardPanel = require("src.ui.RewardPanel")

---@class g.rewardPopupService
local rewardPopupService = {}

local active = nil

function rewardPopupService.set(args)
    active = RewardPanel(args)
end

function rewardPopupService.clear()
    active = nil
end

function rewardPopupService.getActive()
    return active
end

function rewardPopupService.draw()
    if not active then return end
    active:draw()

    if not active:hasAnyRewards() then
        -- auto-clear when no rewards left
        rewardPopupService.clear()
    end
end

return rewardPopupService
