local SquadChoicePanel = require("src.ui.choicepanels.SquadChoicePanel")
local BlessingChoicePanel = require("src.ui.choicepanels.BlessingChoicePanel")
local ManaChoicePanel = require("src.ui.choicepanels.ManaChoicePanel")
local UpgradeSquadChoicePanel = require("src.ui.choicepanels.UpgradeSquadChoicePanel")
local ManaBlessingChoicePanel = require("src.ui.choicepanels.ManaBlessingChoicePanel")

---@class g.choicePopupService
local choicePopupService = {}

---@type g.ChoicePanelCommon?
local active = nil

---@param rType "squad"|"blessing"|"mana"|"upgrade_squad"|"mana_blessing"
---@param rerolls integer?
---@param rarityWeights g.RarityWeights?
function choicePopupService.set(rType, rerolls, rarityWeights)
    if rType == "squad" then
        active = SquadChoicePanel(rerolls or 0, rarityWeights)
    elseif rType == "blessing" then
        active = BlessingChoicePanel(rarityWeights)
    elseif rType == "mana" then
        active = ManaChoicePanel()
    elseif rType == "upgrade_squad" then
        active = UpgradeSquadChoicePanel()
    elseif rType == "mana_blessing" then
        active = ManaBlessingChoicePanel(rarityWeights)
    else
        error("Unknown choice panel type: "..tostring(rType))
    end
end

function choicePopupService.clear()
    active = nil
end

function choicePopupService.getActive()
    return active
end

function choicePopupService.draw()
    if not active then return end
    prof_push("choicePopupService.draw")
    lg.setColor(0,0,0,0.7)
    lg.rectangle("fill", -1000,-1000, 9000,9000)
    local done = active:draw()
    if done then
        active = nil
        prof_pop() -- prof_push("choicePopupService.draw")
        return true
    end
    prof_pop() -- prof_push("choicePopupService.draw")
end

return choicePopupService
