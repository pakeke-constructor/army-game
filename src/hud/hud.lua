

---@class g.HUD: objects.Class
local HUD = objects.Class("g:HUD")



function HUD:init()
    self.selectedSquadIndex = 1
end



---@class g.hudArgs
---@field battleScene boolean?
---@field mapScene boolean?
local hudArgs


local function drawSquadSelect(squads, r)
    for _, sq in ipairs(squads)do
        
    end
end

---@param opt g.hudArgs
function HUD:drawUI(opt)
    local r = Kirigami(0,0, ui.getScaledUIDimensions())
    local a,_,b = r:splitVertical(1,11,2)

    local army = g.getArmy()
    -- if army has changed; make sure it's clamped
    self.selectedSquadIndex = helper.clamp(math.floor(self.selectedSquadIndex + 0.5), 1, #army)

    lg.setColor(1,1,1)
    ui.drawSingleColorPanel(a:padRatio(0.1):get())
    lg.setColor(1,1,1)
    ui.drawSingleColorPanel(b:padRatio(0.1):get())
end



function HUD:getSelectedArmy()
    local army = g.getArmy()
    local squad = army[self.selectedSquadIndex]
    if squad then
        return squad, self.selectedSquadIndex
    end
end



function HUD:wheelmoved(dx,dy)
    -- scroll to select a different army
    local army = g.getArmy()
    self.selectedSquadIndex = helper.clamp(math.floor(self.selectedSquadIndex + dy + 0.5), 1, #army)
end



return HUD

