---@class g.fadeToBlackService
local fadeToBlackService = {}

local alpha = 0
local startAlpha = 0
local targetAlpha = 0
local elapsed = 0
local duration = 0
local animating = false
local onDone = nil

local function finishFade()
    if not onDone then return end
    local fn = onDone
    onDone = nil
    fn()
end

local function startFade(target, dur, done)
    startAlpha = alpha
    targetAlpha = target
    elapsed = 0
    duration = dur or 0
    onDone = done

    if duration <= 0 then
        alpha = targetAlpha
        animating = false
        finishFade()
        return
    end

    animating = true
end

function fadeToBlackService.fadeToBlack(dur, whenDone)
    startFade(1, dur, whenDone)
end

function fadeToBlackService.fadeFromBlack(dur, whenDone)
    startFade(0, dur, whenDone)
end

function fadeToBlackService.fadeToFromBlack(fadeInDur, whenDone, fadeOutDur)
    fadeToBlackService.fadeToBlack(fadeInDur, function()
        if whenDone then
            whenDone()
        end
        fadeToBlackService.fadeFromBlack(fadeOutDur or fadeInDur)
    end)
end

function fadeToBlackService.isAnimating()
    return animating
end

function fadeToBlackService.update(dt)
    if not animating then return end

    elapsed = elapsed + dt
    local t = math.min(1, elapsed / duration)
    alpha = startAlpha + (targetAlpha - startAlpha) * t

    if t >= 1 then
        animating = false
        finishFade()
    end
end

function fadeToBlackService.draw()
    if alpha <= 0 then return end

    lg.setColor(0, 0, 0, alpha)
    lg.rectangle("fill", 0, 0, lg.getWidth(), lg.getHeight())
    lg.setColor(1, 1, 1, 1)
end

return fadeToBlackService
