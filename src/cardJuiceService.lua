---@class CardJuiceService
local cardJuiceService = {}

local FALL_GRAVITY = 900
local FALL_UP_VEL = -120

---@param t number interpolation time in range [0, 1]
---@param r kirigami.Region original region
---@param i integer Persistent number for "randomness"
---@param draw fun(r:kirigami.Region):... draw function with modified region
function cardJuiceService.drawUnselected(t, r, i, draw)
    local cx, cy = r:getCenter()
    local _, screenH = ui.getScaledUIDimensions()
    local dir = (i % 2 == 0) and 1 or -1
    local x = dir * (80 + (i % 3) * 24) * t
    local y = FALL_UP_VEL * t + (screenH + 0.5 * FALL_GRAVITY) * t * t
    local rot = dir * (2 + (i % 4)) * consts.TAU * 0.25 * t
    local centeredR = r:moveUnit(-cx, -cy)

    lg.push()
    lg.translate(cx + x, cy + y)
    lg.rotate(rot)
    local result = draw(centeredR)
    lg.pop()
    return result
end

---@param t number interpolation time in range [0, 1]
---@param r kirigami.Region original region
---@param i integer Persistent number for "randomness"
---@param draw fun(r:kirigami.Region):... draw function with modified region
---@param targetR kirigami.Region? Target region for transition?
function cardJuiceService.drawSelected(t, r, i, draw, targetR)
    local t1 = helper.EASINGS.sineInOut(t)
    local newR

    if targetR then
        newR = Kirigami(
            helper.lerp(r.x, targetR.x, t1),
            helper.lerp(r.y, targetR.y, t1),
            helper.lerp(r.w, targetR.w, t1),
            helper.lerp(r.h, targetR.h, t1)
        )
    else
        -- Selected goes to center for now
        local sx, sy = ui.getFullScreenRegion():getCenter()
        local x, y = r:getCenter()

        local dx = sx - x
        local dy = sy - y
        newR = r:moveUnit(dx * t1, dy * t1)
    end

    -- TODO: Probably some kind of glow/godrays here?
    return draw(newR)
end

return cardJuiceService
