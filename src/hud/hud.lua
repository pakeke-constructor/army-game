

---@class g.HUD: objects.Class
local HUD = objects.Class("g:HUD")



function HUD:init()
    self.selectedSquadIndex = 1
end



---@class g.hudArgs
---@field battleScene boolean?
---@field mapScene boolean?
local hudArgs



local SQUAD_ICON_SIZE = 32
local SQUAD_PADDING = 4

---@param army g.Squad[]
---@param from integer
---@param dir integer -- +1 or -1
local function findNextUndeployed(army, from, dir)
    for i = from, dir > 0 and #army or 1, dir do
        if not army[i].deployed then return i end
    end
end

---@param sq g.Squad
---@param x number
---@param y number
---@param size number
---@param selected boolean
local function renderSquad(sq, x, y, size, selected)
    if selected then
        lg.setColor(1, 1, 1, 0.3)
        lg.rectangle("fill", x - 2, y - 2, size + 4, size + 4, 4, 4)
    end
    if sq.deployed then
        lg.setColor(1, 1, 1, 0.3)
    else
        lg.setColor(1, 1, 1)
    end
    local img = sq:getIcon()
    g.drawImageContained(img, x, y, size, size)
end

---@param opt g.hudArgs
function HUD:drawUI(opt)
    local sw, sh = ui.getScaledUIDimensions()

    local army = g.getArmy()
    -- if army has changed; make sure it's clamped
    self.selectedSquadIndex = helper.clamp(math.floor(self.selectedSquadIndex + 0.5), 1, #army)

    if opt.battleScene and #army > 0 then
        local count = #army
        local totalW = count * SQUAD_ICON_SIZE + (count - 1) * SQUAD_PADDING
        local startX = 20
        local baseY = sh - SQUAD_ICON_SIZE - 10
        for i, sq in ipairs(army) do
            local x = startX + (i - 1) * (SQUAD_ICON_SIZE + SQUAD_PADDING)
            local y = baseY
            local selected = (i == self.selectedSquadIndex)
            if selected then
                y = y - 6
            end
            renderSquad(sq, x, y, SQUAD_ICON_SIZE, selected)
            if not sq.deployed and iml.wasJustClicked(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, 1, i) then
                self.selectedSquadIndex = i
            end
            iml.panel(x, y, SQUAD_ICON_SIZE, SQUAD_ICON_SIZE, i)
        end
    end
end



function HUD:getSelectedArmy()
    local army = g.getArmy()
    -- find nearest undeployed, searching forward then backward
    local idx = findNextUndeployed(army, self.selectedSquadIndex, 1)
        or findNextUndeployed(army, self.selectedSquadIndex, -1)
    if not idx then return nil end
    self.selectedSquadIndex = idx
    return army[idx], idx
end



function HUD:wheelmoved(dx, dy)
    local army = g.getArmy()
    local dir = dy > 0 and 1 or -1
    local next = findNextUndeployed(army, self.selectedSquadIndex + dir, dir)
    if next then
        self.selectedSquadIndex = next
    end
end



return HUD

