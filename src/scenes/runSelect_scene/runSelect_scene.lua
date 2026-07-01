---@class g.runSelectScene
local runSelect = {}

local lg = love.graphics

function runSelect:init()
    ---@type string?
    self.selectedCommander = nil
end

function runSelect:enter()
    self.selectedCommander = nil
end

---@param commanderId string
function runSelect:start(commanderId)
    g.newRun({
        commander = commanderId,
        difficulty = 0
    })
    local dur = consts.DEV_MODE and consts.RUN_START_FADE_DEV or consts.RUN_START_FADE
    g.transitionTo("map_scene", {fadeOut = dur, fadeIn = dur})
end

---@param dt number
function runSelect:update(dt)
end

local riseLerps = {} -- id -> 0..1, how "risen" the icon is

---@param self g.runSelectScene
---@param icons kirigami.Region
local function drawCommanderList(self, icons)
    local list = g.getCommanderList()
    local cells = icons:grid(#list, 1)
    local dt = love.timer.getDelta()
    for i, reg in ipairs(cells) do
        local id = list[i]
        local info = g.getCommanderInfo(id)
        local selected = self.selectedCommander == id

        local target = selected and 1 or 0
        local t = helper.lerp(riseLerps[id] or 0, target, dt*30)
        riseLerps[id] = t
        t = helper.EASINGS.linear(t)

        -- icon takes half the cell; gap shifts top->bottom as it rises
        local gap = 1.7
        local _, iconReg = reg:splitVertical(gap*(1-t)+1, 4, gap*t+1)
        local x, y, rw, rh = iconReg:padRatio(0.1):get()
        -- ui.debugRegion(iconReg:padRatio(0.1))
        love.graphics.setColor(1,1,1,1)
        -- ui.drawPanel(x,y,rw,rh)
        local alpha = selected and 1 or 0.35
        local col = g.getManaBundleColor(info.squadDef.cost)
        local glowSize = selected and 100 or 80
        helper.drawGlow(x+rw/2, y+rh/2, {col.r, col.g, col.b, alpha}, glowSize)
        g.drawUnitPreview(info.squadDef.entityId, x, y, rw, rh)
        --g.drawImageContained(info.image, x, y, rw, rh)
        -- g.drawSquadIcon(id, x, y)

        if iml.wasJustClicked(x, y, rw, rh, 1, id) then
            self.selectedCommander = id
        end
    end
end


local PLAY_TEXT = loc("PLAY", nil, {
    context = "Button text that when clicked, enter the game"})

---@param self g.runSelectScene
---@param reg any
local function drawPlay(self, reg)
    local x, y, rw, rh = reg:padRatio(0.3):get()
    lg.setColor(1,1,1,1)
    local font = g.getBigFont(48)
    richtext.printRichContainedNoWrap(PLAY_TEXT, font, x,y,rw,rh)

    if iml.wasJustClicked(x, y, rw, rh, 1, "play") then
        self:start(self.selectedCommander)
    end
end

function runSelect:draw()
    ui.startUI()
    local main = ui.getScreenRegion()
    local x,y, w, h = main:get()

    lg.clear(0.05, 0.05, 0.07, 1)
    lg.setColor(1, 1, 1, 0.7)
    g.drawImageContained("exampleBackgroundMap", x,y,w,h)
    lg.setColor(0.05, 0.05, 0.07, 0.5)
    lg.rectangle("fill", 0, 0, w, h)


    local top, _, bottomHeader = main:padRatio(0.05):splitVertical(4, 0.2, 2.2)
    local _, icons = bottomHeader:splitHorizontal(1, 6, 1)

    icons = icons:padRatio(0.2)
    drawCommanderList(self, icons)

    local _, right = main:padRatio(0.2):splitHorizontal(4, 1)
    local _, start = right:splitVertical(2, 1, 2)
    -- ui.debugRegion(start)
    if self.selectedCommander then
        drawPlay(self, start)
    end

    if self.selectedCommander then
        local squadId = g.getCommanderInfo(self.selectedCommander).squadId
        if squadId then
            local _, left = top:splitHorizontal(1, 1, 1)
            ui.drawSquadCard(squadId, left:padRatio(0.1), -999)
        end
    end
    ui.endUI()
end

return runSelect
