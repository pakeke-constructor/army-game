local RewardPanel = require("src.ui.RewardPanel")

---@class g.rewardPopupService
local rewardPopupService = {}

local active = nil


function rewardPopupService.battleReward(args)
    active = RewardPanel("battle", args)
end

function rewardPopupService.levelUpReward(args)
    active = RewardPanel("levelup", args)
end


function rewardPopupService.clear()
    active = nil
end

function rewardPopupService.getActive()
    return active
end

function rewardPopupService.draw()
    if not active then return end
    lg.setColor(0,0,0,0.7)
    lg.rectangle("fill", -1000,-1000, 9000,9000)
    active:draw()

    if not active:hasAnyRewards() then
        -- auto-clear when no rewards left
        rewardPopupService.clear()
    end
end

return rewardPopupService
