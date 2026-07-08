
---@class g.ChoicePanelCommon: objects.Class
local ChoicePanelCommon = objects.Class("g:ChoicePanelCommon")

ChoicePanelCommon.NUM_CHOICES = 3
ChoicePanelCommon.FAN_OUT_DURATION = 0.11
ChoicePanelCommon.SELECT_ANIM_DURATION = 0.4

---@return boolean
function ChoicePanelCommon:draw()
    return false
end

return ChoicePanelCommon
