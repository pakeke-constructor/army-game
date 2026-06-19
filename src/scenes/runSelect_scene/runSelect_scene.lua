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

local function drawCommanderList(icons)
    local list = g.getCommanderList()
    local cells = icons:columns(#list)
    for i, reg in ipairs(cells) do
        local id = list[i]
        local info = g.getCommanderInfo(id)
        local x, y, rw, rh = reg:padRatio(0.1):get()
        g.drawImageContained(info.image, x, y, rw, rh)

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
    local w, h = lg.getDimensions()

    lg.clear(0.05, 0.05, 0.07, 1)
    lg.setColor(1, 1, 1, 0.7)
    local mapw, maph = g.getImageSize("exampleBackgroundMap")
    local sx, sy = w/mapw, h/maph
    local midX, midY = mapw/2 * sx, maph/2 * sy
    g.drawImage("exampleBackgroundMap", midX, midY, 0, sx, sy)
    lg.setColor(0.05, 0.05, 0.07, 0.5)
    lg.rectangle("fill", 0, 0, w, h)


    local top, bottomHeader = root:splitVertical(4, 1)
    local icons, start = bottomHeader:splitHorizontal(8, 3)
    drawPlay(self, start)

    drawCommanderList(icons)

    if selectedCommander then
        local squadId = g.getCommanderInfo(selectedCommander).squadId
        if squadId then
            ui.startUI()
                local main = ui.getScreenRegion()
                local _, split1 = main:padRatio(0.1):splitHorizontal(2, 1)
                local left, _ = split1:splitVertical(4, 1)
                ui.drawSquadCard(squadId, left:padRatio(0.1), -999)
            ui.endUI()
        end
    end
end

return runSelect
