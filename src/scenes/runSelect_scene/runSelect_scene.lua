local runSelect = {}

local lg = love.graphics

local root

local selectedCommander

function runSelect:init()
    local w, h = lg.getDimensions()

    root = Kirigami(0, 0, w, h)
end

function runSelect:enter()
    -- temp
    g.newRun({
        commander = "sir_horse",
        difficulty = 0
    })
end

---@param sandbox boolean?
function runSelect:start(sandbox)
    -- if g.hasRun() then
    --     error("attempt to start with existing run??")
    -- end

    -- g.newRun({
    --     commander = "sir_horse",
    --     difficulty = 0
    -- })

    g.gotoScene("map_scene")
end


function runSelect:update(dt)
    local w, h = lg.getDimensions()
    root = Kirigami(0, 0, w, h)
end

-- splits reg into n square cells, laid in a row, spread evenly with equal gaps
local function squareCells(reg, n)
    local side = math.min(reg.w / n, reg.h)
    local gap = (reg.w - side * n) / (n + 1)
    local y = reg.y + (reg.h - side) / 2
    local cells = {}
    for i = 1, n do
        local x = reg.x + gap * i + side * (i - 1)
        cells[i] = reg:set(x, y, side, side)
    end
    return cells
end

local riseLerps = {} -- id -> 0..1, how "risen" the icon is

local function drawCommanderList(icons)
    local list = g.getCommanderList()
    local cells = squareCells(icons, #list)
    local dt = love.timer.getDelta()
    for i, reg in ipairs(cells) do
        local id = list[i]
        local info = g.getCommanderInfo(id)

        local target = (selectedCommander == id) and 1 or 0
        local t = helper.lerp(riseLerps[id] or 0, target, dt*30)
        riseLerps[id] = t
        t = helper.EASINGS.linear(t)

        -- icon takes half the cell; gap shifts top->bottom as it rises
        local gap = 0.5
        local _, iconReg = reg:splitVertical(gap*(1-t)+1, 4, gap*t+1)
        local x, y, rw, rh = iconReg:padRatio(0.1):get()
        -- ui.debugRegion(iconReg:padRatio(0.1))
        love.graphics.setColor(1,1,1,1)
        -- ui.drawPanel(x,y,rw,rh)
        local alpha = (selectedCommander == id) and 0.9 or 0.4
        local col = g.getManaBundleColor(info.squadDef.cost)
        helper.drawGlow(x+rw/2, y+rh/2, {col.r, col.g, col.b, alpha}, 80)
        g.drawImageContained(info.image, x, y, rw, rh)
        -- g.drawSquadIcon(id, x, y)

        if iml.wasJustClicked(x, y, rw, rh, 1, id) then
            selectedCommander = id
        end
    end
end

local function drawPlay(self, reg)
    local x, y, rw, rh = reg:padRatio(0.3):get()
    lg.setColor(1,1,1,1)
    local font = g.getBigFont(48)
    richtext.printRichContainedNoWrap("PLAY", font, x,y,rw,rh)

    if iml.wasJustClicked(x, y, rw, rh, 1, "play") then
        fadeToBlackService.fadeToFromBlack(0.3, function()
            self:start()
        end)
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
    drawCommanderList(icons)

    local _, right = main:padRatio(0.2):splitHorizontal(4, 1)
    local _, start = right:splitVertical(2, 1, 2)
    -- ui.debugRegion(start)
    if selectedCommander then
        drawPlay(self, start)
    end

    if selectedCommander then
        local squadId = g.getCommanderInfo(selectedCommander).squadId
        if squadId then
            local _, left = top:splitHorizontal(1, 1, 1)
            ui.drawSquadCard(squadId, left:padRatio(0.1), -999)
        end
    end
    ui.endUI()
end

return runSelect
