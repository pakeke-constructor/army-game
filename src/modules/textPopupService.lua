---@class textPopupService
local textPopups = {}

local popups = {}

-- x,y are screen coords
function textPopups.addPopup(x, y, richtxt, font, vely, duration)
    popups[#popups+1] = {
        x = x,
        y = y,
        font = font or love.graphics.getFont(),
        vely = vely or -10,
        duration = duration or 3,
        time = 0,
        txt = richtxt,
    }
end

function textPopups.update(dt)
    for i = #popups, 1, -1 do
        local p = popups[i]
        p.time = p.time + dt
        p.y = p.y + p.vely * dt
        if p.time >= p.duration then
            table.remove(popups, i)
        end
    end
end

function textPopups.draw()
    love.graphics.push()
    love.graphics.origin()
    for _, p in ipairs(popups) do
        local a = 1 - (p.time / p.duration)
        love.graphics.setColor(1, 1, 1, a)
        richtext.printRichCentered(p.txt, p.font, p.x, p.y, 1000, "left")
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return textPopups
