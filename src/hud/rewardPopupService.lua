local RewardPanel = require("src.ui.RewardPanel")

---@class g.rewardPopupService
local rewardPopupService = {}

---@type g.RewardPanel?
local active = nil


---@param args g.RewardPanel.Rewards
function rewardPopupService.battleReward(args)
    active = RewardPanel("battle", args)
end

---@param args g.RewardPanel.Rewards
function rewardPopupService.levelUpReward(args)
    active = RewardPanel("levelup", args)
end

---@param args g.RewardPanel.Rewards
function rewardPopupService.genericReward(args)
    active = RewardPanel("other", args)
end


function rewardPopupService.clear()
    active = nil
end

---@return g.RewardPanel?
function rewardPopupService.getActive()
    return active
end

function rewardPopupService.draw()
    if not active then return end
    prof_push("rewardPopupService.draw")
    lg.setColor(0,0,0,0.7)
    lg.rectangle("fill", -1000,-1000, 9000,9000)
    active:draw()

    if not active:hasAnyRewards() then
        -- auto-clear when no rewards left
        rewardPopupService.clear()
    end
    prof_pop() -- prof_push("rewardPopupService.draw")
end

return rewardPopupService
