---@class g.runSelectScene
local runSelect = {}

local lg = love.graphics

function runSelect:init()
    ---@type string?
    self.selectedCommander = nil
end

function runSelect:enter()
    self.selectedCommander = nil
    self.lastHoveredCommander = nil
end

---@param commanderId string
function runSelect:start(commanderId)
    g.newRun({
        commander = commanderId,
        difficulty = 0
    })
    local dur = consts.DEV_MODE and consts.RUN_START_FADE_DEV or consts.RUN_START_FADE
    g.transitionTo("map_scene", {fadeOut = dur, fadeIn = dur})
    g.playUISound("ui_embark")
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
    local hoveredId = nil
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
        local _, iconRegBaseR = reg:splitVertical(gap*(1-t)+1, 4, gap*t+1)
        local iconRegR = iconRegBaseR:padRatio(0.1)
        local x, y, rw, rh = iconRegR:get()
        -- ui.debugRegion(iconRegR)
        love.graphics.setColor(1,1,1,1)
        -- ui.drawPanel(x,y,rw,rh)
        local alpha = selected and 0.4 or 0.15
        local isHovered = iml.isHovered(x, y, rw, rh, id)
        if isHovered then hoveredId = id end
        local dy = (isHovered and (not selected)) and -6 or 0

        -- Draw all the glows
        ---@type objects.Color[]
        local glows = {}
        -- Cannot use g.getManaBundleColor here because it stops on first match.
        -- We want ALL of the mana colors!
        for _,mc in ipairs(g.getManaTypelist()) do
            if info.squadDef.cost[mc] then
                local minfo = g.getManaInfo(mc)
                glows[#glows+1] = minfo.color
            end
        end

        local glowSize = selected and 100 or 80
        if #glows == 1 then
            local col = glows[1]
            helper.drawGlow(x+rw/2, y+rh/2 + dy, {col.r, col.g, col.b, alpha}, glowSize)
        elseif #glows > 1 then
            -- Draw multiple glows. Start at top left
            local glowSepDist = math.min(iconRegR.w, iconRegR.h) * 0.4 * t

            for j, col in ipairs(glows) do
                -- offset by 105 degrees for top-left
                local a = -math.pi * 3 / 4 + (j - 1) * consts.TAU / #glows
                local ox = x + rw/2 + glowSepDist * math.cos(a)
                local oy = y + rh/2 + dy + glowSepDist * math.sin(a)
                helper.drawGlow(ox, oy, {col.r, col.g, col.b, alpha}, glowSize)
            end
        end
        g.drawUnitPreview(info.squadDef.entityId, x, y + dy, rw, rh)

        if iml.wasJustClicked(x, y, rw, rh, 1, id) then
            self.selectedCommander = id
            g.playUISound("ui_click_satisfying")
        end
    end

    if hoveredId ~= self.lastHoveredCommander then
        if hoveredId then g.playUISound("ui_mouse_hover") end
        self.lastHoveredCommander = hoveredId
    end
end


local PLAY_TEXT = loc("PLAY", nil, {
    context = "Button text that when clicked, enter the game"})

---@param self g.runSelectScene
---@param reg any
local function drawPlay(self, reg)
    local x, y, rw, rh = reg:padRatio(0.3):get()
    local font = g.getBigFont(48)
    local isHovered = iml.isHovered(x, y, rw, rh, "play")
    local dy = isHovered and math.sin(love.timer.getTime() * 10) / 6 or 0

    lg.setColor(1,1,1,1)
    if isHovered then
        lg.setColor(g.snapToPalette(objects.Color.RED))
    end

    richtext.printRichContainedNoWrap(PLAY_TEXT, font, x, y+dy, rw, rh)

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
