---@class CardJuiceService
local cardJuiceService = {}

---@param t number
---@param r kirigami.Region
---@param draw fun(r:kirigami.Region):...
local function drawUnselected(t, r, draw)
    -- Unselected just falls down for now
    local _, h = ui.getScaledUIDimensions()
    local t1 = helper.EASINGS.sineOut(t)
    return draw(r:moveUnit(0, h * t1))
end

---@param t number
---@param r kirigami.Region
---@param draw fun(r:kirigami.Region):...
local function drawSelected(t, r, draw)
    -- Selected goes to center for now
    local sx, sy = ui.getFullScreenRegion():getCenter()
    local x, y = r:getCenter()

    local dx = sx - x
    local dy = sy - y
    local t1 = helper.EASINGS.sineInOut(t)
    return draw(r:moveUnit(dx * t1, dy * t1))
    -- TODO: Probably some kind of glow/godrays here?
end


---@param t number interpolation time in range [0, 1]
---@param r kirigami.Region original region
---@param selected boolean
---@param draw fun(r:kirigami.Region):... draw function with modified region
function cardJuiceService.draw(t, r, selected, draw)
    if selected then
        return drawSelected(t, r, draw)
    else
        return drawUnselected(t, r, draw)
    end
end

return cardJuiceService
