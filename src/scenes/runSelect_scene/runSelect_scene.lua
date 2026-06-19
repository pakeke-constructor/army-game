local runSelect = {}

local lg = love.graphics

local root

function runSelect:init()
    local w, h = lg.getDimensions()

    root = Kirigami(0, 0, w, h)

end

function runSelect:enter()

end


function runSelect:update(dt)

end


function runSelect:draw()
    local w, h = lg.getDimensions()

    lg.clear(0.05, 0.05, 0.07, 1)
    lg.setColor(1, 1, 1, 0.7)
    local mapw, maph = g.getImageSize("exampleBackgroundMap")
    local sx, sy = w/mapw, h/maph
    local x, y = mapw/2 * sx, maph/2 * sy
    g.drawImage("exampleBackgroundMap", x, y, 0, sx, sy)
    lg.setColor(0.05, 0.05, 0.07, 0.5)
    lg.rectangle("fill", 0, 0, w, h)


    local top, bottomHeader = root:splitVertical(4, 1)
    local icons, start = bottomHeader:splitHorizontal(8, 3)
    local x, y, rw, rh = start:get()
    lg.setColor(1,1,1,1)
    lg.rectangle("fill", x, y, rw, rh)
end

return runSelect
