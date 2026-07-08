local StatChoicePanel = require("src.ui.choicepanels.StatChoicePanel")

---@class g.statUpgradePopupService
local statUpgradePopupService = {}

---@type g.StatChoicePanel?
local active = nil

---@param squadOrId g.Squad|string
function statUpgradePopupService.set(squadOrId)
    local squadId = type(squadOrId) == "string" and squadOrId or squadOrId.squadId
    active = StatChoicePanel(squadId)
end

function statUpgradePopupService.clear()
    active = nil
end

---@return g.StatChoicePanel?
function statUpgradePopupService.getActive()
    return active
end

function statUpgradePopupService.draw()
    if not active then return end
    lg.setColor(0,0,0,0.7)
    lg.rectangle("fill", -1000,-1000, 9000,9000)
    local done = active:draw()
    if done then
        active = nil
        return true
    end
end

return statUpgradePopupService
