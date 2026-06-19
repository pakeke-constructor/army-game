local title_scene = {}

local buttons = {
    {name = "START", onClick = function ()
        g.gotoScene("map_scene")
    end},
    {name = "SANDBOX", onClick = function ()
        local battle = require("src.scenes.battle_scene.battle_scene")
        battle.sandbox = true
        g.gotoScene("battle_scene")
    end},
    {name = "EXIT", onClick = function ()
        love.event.quit()
    end}
}

local hoveredButton

local lg = love.graphics
local spawnX = 0 -- the left x of most of the buttons
local spawnY = 0
local gapPerButton = 80

function title_scene:init()
end

function title_scene:enter()
end

local BUTTON_W = 200

-- the hit-rect for button i (matches the drawn text region)
local function buttonRect(i)
    return spawnX-30, spawnY+gapPerButton*(i-1-0.5), BUTTON_W, gapPerButton
end

function title_scene:update(dt)
    local w, h = lg.getDimensions()
    spawnX = w * 1/6
    spawnY = h * 1/2

    -- hoveredButton is set in :draw (iml only runs inside the draw frame)
    for i, button in ipairs(buttons) do
        local target = (i == hoveredButton) and 30 or 0
        button.offsetX = helper.lerp(button.offsetX or 0, target, dt * 12)
    end
end


---@param sandbox boolean?
function title_scene:start(sandbox)
    if g.hasRun() then
        error("attempt to start with existing run??")
    end

    g.newRun({
        commander = "sir_horse",
        difficulty = 0
    })
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

    local capw, caph = g.getImageSize("smallcapsule")
    g.drawImage("smallcapsule", spawnX+capw/2, spawnY - caph)
    

    lg.setFont(smallFont)
    hoveredButton = nil
    for i, button in ipairs(buttons) do
        local rx, ry, rw, rh = buttonRect(i)
        if iml.isHovered(rx, ry, rw, rh, button) then
            hoveredButton = i
        end
        if iml.wasJustClicked(rx, ry, rw, rh, 1, button) then
            self:start()
            button.onClick()
        end

        local msg = button.name
        local x = spawnX + (button.offsetX or 0)
        lg.setColor((i == hoveredButton) and {1,1,0.6,1} or {1,1,1,1})
        lg.print(msg, x, spawnY + (i-1)*gapPerButton - smallFont:getHeight()/2)
    end
end

return title_scene
