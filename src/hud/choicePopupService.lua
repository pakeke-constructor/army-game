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
    local done = active:draw()
    if done then
        active = nil
        return true
    end
end

return choicePopupService
