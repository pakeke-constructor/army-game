local title_scene = {}

local buttons = {
    {name = "START", onClick = function ()
        g.gotoScene("runSelect_scene")
    end},
    {name = "SANDBOX", onClick = function ()
        g.newRun({
            commander = "sir_horse",
            difficulty = 0
        })

        local battle = require("src.scenes.battle_scene.battle_scene")
        battle.sandbox = true
        g.gotoScene("battle_scene")
    end, skipFade = true},
    {name = "EXIT", onClick = function ()
        love.event.quit()
    end}
}

local hoveredButton

local lg = love.graphics
local spawnX = 0 -- the left x of most of the buttons
local spawnY = 0
local gapPerButton = 70
local BUTTON_W = 300

local buttonCells -- one Kirigami region per button (shared by hit-test + draw)

function title_scene:init()
end

function title_scene:enter()
end

function title_scene:update(dt)
    local w, h = lg.getDimensions()
    spawnX = w * 1/6
    spawnY = h * 1/2

    -- one column of cells, vertically centered on the button list
    local col = Kirigami(spawnX, spawnY - gapPerButton/2, BUTTON_W, gapPerButton*#buttons)
    buttonCells = col:columns(#buttons)

    -- hoveredButton is set in :draw (iml only runs inside the draw frame)
    for i, button in ipairs(buttons) do
        local target = (i == hoveredButton) and 1 or 0
        local rate = (i == hoveredButton) and 5 or 14
        rate = rate * 2
        button.t = helper.lerp(button.t or 0, target, dt*rate)
        button.offsetX = helper.lerp(0, 30, helper.EASINGS.easeOutBack(button.t))
    end
end

function title_scene:draw()
    local w, h = lg.getDimensions()

    

    lg.clear(0.05, 0.05, 0.07, 1)

    local titleFont = g.getBigFont(48*3)
    local smallFont = g.getSmallFont(16*3)

    lg.setColor(1, 1, 1, 0.7)

    local mapw, maph = g.getImageSize("exampleBackgroundMap")
    local sx, sy = w/mapw, h/maph
    local x, y = mapw/2 * sx, maph/2 * sy
    g.drawImage("exampleBackgroundMap", x, y, 0, sx, sy)

    lg.setColor(0.05, 0.05, 0.07, 0.5)
    lg.rectangle("fill", 0, 0, w, h)



    lg.setColor(1, 1, 1, 1)

    local capw, caph = g.getImageSize("logo")
    g.drawImage("logo", spawnX+capw/2, spawnY - caph)
    

    
    hoveredButton = nil
    for i, button in ipairs(buttons) do
        local rx, ry, rw, rh = buttonCells[i]:get()
        if iml.isHovered(rx, ry, rw, rh, button) then
            hoveredButton = i
        end
        if iml.wasJustHovered(rx, ry, rw, rh, button) then
            g.playUISound("ui_tick")
        end
        if iml.wasJustClicked(rx, ry, rw, rh, 1, button) then
            if button.skipFade then
                button.onClick()
            else
                fadeToBlackService.fadeToFromBlack(0.3, function()
                    button.onClick()
                end)
            end
        end

        lg.setColor((i == hoveredButton) and {1,1,0.6,1} or {1,1,1,1})
        richtext.printRichContainedNoWrap(button.name, smallFont, rx + (button.offsetX or 0), ry, rw, rh, "left")
    end
end

return title_scene
