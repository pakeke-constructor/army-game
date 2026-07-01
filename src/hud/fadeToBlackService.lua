---@class g.fadeToBlackService
local fadeToBlackService = {}

---@class g.Fade
---@field alpha number
---@field startAlpha number
---@field targetAlpha number
---@field elapsed number
---@field duration number
---@field onDone fun()?
---@field done boolean

---@type g.Fade[]
local fades = {}

-- darkest alpha across all active fades
local function currentAlpha()
    local a = 0
    for _, f in ipairs(fades) do
        a = math.max(a, f.alpha)
    end
    return a
end

local function startFade(target, dur, whenDone)
    ---@type g.Fade
    local fade = {
        alpha = currentAlpha(),
        startAlpha = currentAlpha(),
        targetAlpha = target,
        elapsed = 0,
        duration = dur or 0,
        onDone = whenDone,
        done = false,
    }

    if fade.duration <= 0 then
        fade.alpha = target
        fade.done = true
        if whenDone then whenDone() end
        return fade
    end

    table.insert(fades, fade)
    return fade
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
    return #fades > 0
end

function fadeToBlackService.update(dt)
    for i = #fades, 1, -1 do
        local f = fades[i]
        f.elapsed = f.elapsed + dt
        local t = math.min(1, f.elapsed / f.duration)
        f.alpha = f.startAlpha + (f.targetAlpha - f.startAlpha) * t

        if t >= 1 then
            table.remove(fades, i)
            if f.onDone then f.onDone() end
        end
    end
end

function fadeToBlackService.draw()
    local alpha = currentAlpha()
    if alpha <= 0 then return end

    lg.setColor(0, 0, 0, alpha)
    lg.rectangle("fill", 0, 0, lg.getWidth(), lg.getHeight())
    lg.setColor(1, 1, 1, 1)
end

return fadeToBlackService
