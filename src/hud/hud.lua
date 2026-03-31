

---@class g.HUD: objects.Class
local HUD = objects.Class("g:HUD")



function HUD:init()
    self.selectedSquadIndex = 1
end



---@class g.hudArgs
---@field battleScene boolean?
---@field mapScene boolean?
local hudArgs



---@param sq g.Squad
---@param rr kirigami.Region
local function renderSquad(sq, rr)
    g.drawImageContained(sq.icon, rr:get())
end


---@param squads g.Squad[]
---@param r kirigami.Region
local function drawSquadSelect(squads, r)
    local len = #squads
    local rr = r:grid(consts.MAX_SQUAD_COUNT, 1)
    for i, sq in ipairs(squads)do
        renderSquad(sq, rr[i])
    end
end

---@param opt g.hudArgs
function HUD:drawUI(opt)
    local r = Kirigami(0,0, ui.getScaledUIDimensions())
    local a,_,b = r:splitVertical(1,11,2)

    local army = g.getArmy()
    -- if army has changed; make sure it's clamped
    self.selectedSquadIndex = helper.clamp(math.floor(self.selectedSquadIndex + 0.5), 1, #army)

    lg.setColor(0.3,0.3,0.4)
    ui.drawSingleColorPanel(a:padRatio(0.1):get())
    lg.setColor(0.3,0.3,0.4)
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

