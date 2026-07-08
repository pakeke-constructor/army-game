---@class CardJuiceService
local cardJuiceService = {}

local FALL_GRAVITY = 900
local FALL_UP_VEL = -400
local SELECT_ANIM_DURATION = 0.4

---@param x number
---@param y number
local function parabolic(x, y)
    return 4 * y * x * (1.0 - x)
end

---@class CardJuiceInstance: objects.Class
local CardJuiceInstance = objects.Class("g:CardJuiceInstance")

---@class _CardJuiceInstance.Card
---@field draw fun(r:kirigami.Region)
---@field i integer
---@field selected boolean
---@field startRegion kirigami.Region
---@field targetRegion kirigami.Region?

function CardJuiceInstance:init()
    ---@type _CardJuiceInstance.Card[]
    self.cards = {}
    ---@type number?
    self.begin = nil
end

if false then
    ---@return CardJuiceInstance
    ---@diagnostic disable-next-line: cast-local-type, missing-return
    function CardJuiceInstance() end
end

---@param r kirigami.Region original region
---@param i integer Persistent number for "randomness"
---@param draw fun(r:kirigami.Region):... draw function with modified region
function CardJuiceInstance:spawnCardUnselected(r, i, draw)
    self.cards[#self.cards+1] = {
        i = i,
        draw = draw,
        selected = false,
        startRegion = r,
        targetRegion = nil,
    }
end

---@param r kirigami.Region original region
---@param i integer Persistent number for "randomness"
---@param draw fun(r:kirigami.Region):... draw function with modified region
---@param transition kirigami.Region?
function CardJuiceInstance:spawnCardSelected(r, i, draw, transition)
    self.cards[#self.cards+1] = {
        i = i,
        draw = draw,
        selected = true,
        startRegion = r,
        targetRegion = transition,
    }
    self.begin = love.timer.getTime()
end

function CardJuiceInstance:hasAnimationBegun()
    return not not self.begin
end

function CardJuiceInstance:draw()
    if not self.begin then
        return false
    end
    local t = helper.clamp((love.timer.getTime() - self.begin) / SELECT_ANIM_DURATION, 0, 1)

    for _, card in ipairs(self.cards) do
        if card.selected then
            local t0 = helper.clamp(t * 1.5, 0, 1)
            local t1 = helper.EASINGS.easeOutCubic(helper.clamp(t0, 0, 1))
            local newR

            if card.targetRegion then
                newR = Kirigami(
                    helper.lerp(card.startRegion.x, card.targetRegion.x, t1),
                    helper.lerp(card.startRegion.y, card.targetRegion.y - parabolic(t0, card.startRegion.w) * 0.2, t1),
                    helper.lerp(card.startRegion.w, card.targetRegion.w, t1),
                    helper.lerp(card.startRegion.h, card.targetRegion.h, t1)
                )
            else
                -- Selected goes to center for now
                local sx, sy = ui.getFullScreenRegion():getCenter()
                local x, y = card.startRegion:getCenter()

                local dx = sx - x
                local dy = sy - y
                newR = card.startRegion:moveUnit(dx * t1, dy * t1 - parabolic(t0, card.startRegion.w) * 0.2)
            end

            -- TODO: Probably some kind of glow/godrays here?
            card.draw(newR)
        else
            local cx, cy = card.startRegion:getCenter()
            local _, screenH = ui.getScaledUIDimensions()
            local dir = (card.i % 2 == 0) and 1 or -1
            local x = dir * (80 + (card.i % 3) * 24) * t
            local y = FALL_UP_VEL * t + (screenH + 0.5 * FALL_GRAVITY) * t * t
            local rot = dir * (2 + (card.i % 4)) * consts.TAU * 0.25 * t
            local centeredR = card.startRegion:moveUnit(-cx, -cy)

            lg.push()
            lg.translate(cx + x, cy + y)
            lg.rotate(rot)
            lg.scale(1 - t)
            card.draw(centeredR)
            lg.pop()
        end
    end

    return t >= 1
end

---@param t number interpolation time in range [0, 1]
---@param r kirigami.Region original region
---@param i integer Persistent number for "randomness"
---@param draw fun(r:kirigami.Region):... draw function with modified region
function cardJuiceService.drawUnselected(t, r, i, draw)
    t = helper.clamp(t, 0, 1)
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
    lg.scale(1 - t)
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
    t = helper.clamp(t * 1.5, 0, 1)
    local t1 = helper.EASINGS.easeOutCubic(helper.clamp(t, 0, 1))
    local newR

    if targetR then
        newR = Kirigami(
            helper.lerp(r.x, targetR.x, t1),
            helper.lerp(r.y, targetR.y - parabolic(t, targetR.w) * 0.2, t1),
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

cardJuiceService.CardJuiceInstance = CardJuiceInstance

return cardJuiceService
