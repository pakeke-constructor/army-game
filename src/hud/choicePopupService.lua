local SquadChoicePanel = require("src.ui.choicepanels.SquadChoicePanel")
local UpgradeSquadChoicePanel = require("src.ui.choicepanels.UpgradeSquadChoicePanel")
local BlessingChoicePanel = require("src.ui.choicepanels.BlessingChoicePanel")
local ManaChoicePanel = require("src.ui.choicepanels.ManaChoicePanel")
local ManaBlessingChoicePanel = require("src.ui.choicepanels.ManaBlessingChoicePanel")
local SpellChoicePanel = require("src.ui.choicepanels.SpellChoicePanel")
local SpellDiscardChoicePanel = require("src.ui.choicepanels.SpellDiscardChoicePanel")
local StatChoicePanel = require("src.ui.choicepanels.StatChoicePanel")

---@class g.choicePopupService
local choicePopupService = {}

---@type g.ChoicePanelCommon?
local active = nil

---@class g.SquadChoicePanelParam
---@field type "squad"
---@field rerolls integer?
---@field rarityWeights g.RarityWeights?

---@class g.BlessingChoicePanelParam
---@field type "blessing"
---@field rarityWeights g.RarityWeights?

---@class g.ManaChoicePanelParam
---@field type "mana"

---@class g.UpgradeSquadChoicePanelParam
---@field type "upgrade_squad"

---@class g.ManaBlessingChoicePanelParam
---@field type "mana_blessing"
---@field rarityWeights g.RarityWeights?

---@class g.SpellChoicePanelParam
---@field type "spell"
---@field rerolls integer?
---@field rarityWeights g.RarityWeights?

---@class g.SpellDiscardPanelParam
---@field type "spell_discard"
---@field spellId string?

---@class g.StatChoicePanelParam
---@field type "upgrade_stat"
---@field squadId string

---@alias g.ChoicePopupParam
---| g.SquadChoicePanelParam
---| g.UpgradeSquadChoicePanelParam
---| g.BlessingChoicePanelParam
---| g.ManaChoicePanelParam
---| g.ManaBlessingChoicePanelParam
---| g.SpellChoicePanelParam
---| g.SpellDiscardPanelParam
---| g.StatChoicePanelParam

---@param param g.ChoicePopupParam
function choicePopupService.set(param)
    local rType = param.type
    if rType == "squad" then
        ---@cast param g.SquadChoicePanelParam
        active = SquadChoicePanel(param.rerolls, param.rarityWeights)
    elseif rType == "upgrade_squad" then
        active = UpgradeSquadChoicePanel()
    elseif rType == "blessing" then
        active = BlessingChoicePanel(param.rarityWeights)
    elseif rType == "mana" then
        active = ManaChoicePanel()
    elseif rType == "mana_blessing" then
        ---@cast param g.ManaBlessingChoicePanelParam
        active = ManaBlessingChoicePanel(param.rarityWeights)
    elseif rType == "spell" then
        ---@cast param g.SpellChoicePanelParam
        active = SpellChoicePanel(param.rerolls, param.rarityWeights)
    elseif rType == "spell_discard" then
        ---@cast param g.SpellDiscardPanelParam
        active = SpellDiscardChoicePanel(param.spellId)
    elseif rType == "upgrade_stat" then
        ---@cast param g.StatChoicePanelParam
        active = StatChoicePanel(param.squadId)
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
    local curActive = active
    local done = active:draw()
    local finish = false
    if done then
        if curActive == active then
            active = nil
            finish = true
        end
    end
    prof_pop() -- prof_push("choicePopupService.draw")
    return finish
end

return choicePopupService
