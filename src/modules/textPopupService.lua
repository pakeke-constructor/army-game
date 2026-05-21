---@class textPopupService
local textPopups = {}

local popups = {}

---@class textPopupService.args
---@field font love.Font?
---@field vely number?
---@field duration number?
---@field fadeIn number?

-- x,y are screen coords
---@param x number
---@param y number
---@param richtxt any
---@param args textPopupService.args?
function textPopups.addPopup(x, y, richtxt, args)
    args = args or {}
    popups[#popups+1] = {
        x = x,
        y = y,
        font = args.font or love.graphics.getFont(),
        vely = args.vely or -10,
        duration = args.duration or 3,
        fadeIn = args.fadeIn or 0,
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
        local scale = 1
        if p.fadeIn > 0 then
            scale = math.min(1, p.time / p.fadeIn)
        end
        richtext.printRichCentered(p.txt, p.font, p.x, p.y, 1000, "left", 0, scale, scale)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return textPopups
