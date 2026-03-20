local title_scene = {}

function title_scene:init()
    self.started = false
end

function title_scene:enter()
    self.startTime = love.timer.getTime()
end

function title_scene:update(dt)
end

function title_scene:start()
    if self.started then
        return
    end
    self.started = true
    g.newRun()
end

function title_scene:mousepressed()
    self:start()
end

function title_scene:keypressed()
    self:start()
end

function title_scene:draw()
    local lg = love.graphics
    local w, h = lg.getDimensions()

    lg.clear(0.05, 0.05, 0.07, 1)

    local titleFont = g.getBigFont(48)
    local smallFont = g.getSmallFont(16)

    local titleText = "ARMY GAME"
    lg.setFont(titleFont)
    lg.setColor(1, 1, 1, 1)
    lg.print(titleText, (w - titleFont:getWidth(titleText)) / 2, h * 0.3)

    lg.setFont(smallFont)
    if self.started then
        local msg = "STARTED (TODO: NEXT SCENE)"
        lg.print(msg, (w - smallFont:getWidth(msg)) / 2, h * 0.55)
    else
        local t = love.timer.getTime() - self.startTime
        if math.floor(t * 2) % 2 == 0 then
            local msg = "PRESS ANY KEY"
            lg.print(msg, (w - smallFont:getWidth(msg)) / 2, h * 0.55)
        end
    end
end

return title_scene
