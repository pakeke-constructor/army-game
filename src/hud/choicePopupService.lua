local ChoicePanel = require("src.ui.ChoicePanel")

---@class g.choicePopupService
local choicePopupService = {}

local active = nil

function choicePopupService.set(rType, rarityMapping)
    active = ChoicePanel(rType, rarityMapping)
end

function choicePopupService.clear()
    active = nil
end

function choicePopupService.getActive()
    return active
end

function choicePopupService.draw()
    if not active then return end
    lg.setColor(0,0,0,0.7)
    lg.rectangle("fill", -1000,-1000, 9000,9000)
    local done = active:draw()
    if done then
        active = nil
        return true
    end
end

return choicePopupService
