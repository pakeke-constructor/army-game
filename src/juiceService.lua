
local juiceService = {}

local TRAUMA_DECAY = 2.5
local SHAKE_MAX = 1 -- pixels
local SHAKE_FREQ = 30

-- pause resistance: each pause adds fatigue, which scales down subsequent pauses.
-- prevents huge armies from looking laggy due to spam of small pauses.
local PAUSE_FATIGUE_DECAY = 1.5 -- per second
local PAUSE_FATIGUE_PER_SEC = 8 -- how much fatigue 1s of pause adds

local trauma = 0
local shakeT = 0
local shakeX = 0
local shakeY = 0
local hitPause = 0
local pauseFatigue = 0

function juiceService.reset()
    trauma = 0
    shakeT = 0
    shakeX = 0
    shakeY = 0
    hitPause = 0
    pauseFatigue = 0
end

function juiceService.addCameraShake(amount)
    trauma = math.min(1, trauma + amount)
end

function juiceService.addTimePause(duration)
    -- resistance: 1/(1+fatigue) scaling. lots of pauses -> tiny pauses.
    local scaled = duration / (1 + pauseFatigue)
    pauseFatigue = pauseFatigue + scaled * PAUSE_FATIGUE_PER_SEC
    if hitPause < scaled then
        hitPause = scaled
    end
end

function juiceService.getShakeOffset()
    return shakeX, shakeY
end

function juiceService.consumeHitPause(dt)
    if hitPause > 0 then
        hitPause = math.max(0, hitPause - dt)
        return 0.05
    end
    return 1
end

function juiceService.update(dt)
    trauma = math.max(0, trauma - TRAUMA_DECAY * dt)
    pauseFatigue = math.max(0, pauseFatigue - PAUSE_FATIGUE_DECAY * dt)
    shakeT = shakeT + dt
    local s = trauma * trauma
    local mag = s * SHAKE_MAX
    shakeX = math.sin(shakeT * SHAKE_FREQ * 1.3) * mag * (love.math.random() * 0.5 + 0.75)
    shakeY = math.cos(shakeT * SHAKE_FREQ) * mag * (love.math.random() * 0.5 + 0.75)
end

return juiceService
