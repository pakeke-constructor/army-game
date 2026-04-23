

---@class g.RewardPanel: objects.Class
local RewardPanel = objects.Class("g:RewardPanel")



---@class g.Reward: objects.Class
---@field rType "squad"|"blessing"|"mana"
function RewardPanel:init(rType)
    self.rType = rType
    self.choices = {}

    if rType == "squad" then
        -- fill with random squads of the player's color "palette".
    elseif rType == "blessing" then
        -- fill with blessings of the player's mana "palette"
    end
end



function RewardPanel:draw()
    local r = ui.getFullScreenRegion()
    local cardArea = r:padRatio(0.05, 0.1)
    local regions = cardArea:grid(#self.choices, 1)
    for i,rr in ipairs(regions) do
        regions[i] = rr:padRatio(0.15)
    end

    for i = 1, #regions do
        local rew = self.choices[i]
        if rew then
            if ui.drawSquadCard(rew, regions[i]) then
                return true
            end
        end
    end
end




return RewardPanel


