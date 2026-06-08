local title_scene = {}

function title_scene:init()
end

function title_scene:enter()
end

function title_scene:update(dt)
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
    if sandbox then
        local battle = require("src.scenes.battle_scene.battle_scene")
        battle.sandbox = true
        g.gotoScene("battle_scene")
    else
        g.gotoScene("map_scene")
    end
end

function title_scene:mousepressed()
end

function title_scene:keypressed(k)
    if consts.DEV_MODE and k == "s" then
        self:start(true)
        return
    end
    self:start()
end

function title_scene:draw()
    local lg = love.graphics
    local w, h = lg.getDimensions()

    lg.clear(0.05, 0.05, 0.07, 1)

    lg.setColor(1, 1, 1, 1)

    local titleFont = g.getBigFont(48)
    local smallFont = g.getSmallFont(16)

    local titleText = "ARMY GAME"
    lg.setFont(titleFont)
    lg.setColor(1, 1, 1, 1)
    local SC=3
    lg.scale(SC)
    w,h = w/SC,h/SC
    lg.print(titleText, (w - titleFont:getWidth(titleText)) / 2, h * 0.3)

    lg.setFont(smallFont)
    local t = love.timer.getTime()
    if math.floor(t * 2) % 2 == 0 then
        local msg = "PRESS ANY KEY"
        lg.print(msg, (w - smallFont:getWidth(msg)) / 2, h * 0.55)
    end

    if consts.DEV_MODE then
        local msg = "(DEV_MODE: Press S to enter sandbox)"
        lg.setColor(objects.Color("FFFFEE00"))
        lg.print(msg, (w - smallFont:getWidth(msg)) / 2, h * 0.7)
    end
end

return title_scene
