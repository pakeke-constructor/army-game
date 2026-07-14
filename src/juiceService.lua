
local juiceService = {}

local TRAUMA_DECAY = 2.5
local SHAKE_MAX = 1 -- pixels
local SHAKE_FREQ = 30

-- pause resistance: each pause adds fatigue, which scales down subsequent pauses.
-- prevents huge armies from looking laggy due to spam of small pauses.
local PAUSE_FATIGUE_DECAY = 1.5 -- per second
local PAUSE_FATIGUE_PER_SEC = 8 -- how much fatigue 1s of pause adds

local ARC_SPEED = 360 -- pixels/sec
local ARC_HEIGHT = 0.1 -- arc lift as fraction of travel distance
local MAX_ARCS = 40 -- cap active arcs to prevent lag

local trauma = 0
local shakeT = 0
local shakeX = 0
local shakeY = 0
local hitPause = 0
local pauseFatigue = 0
local arcs = {}

function juiceService.reset()
    trauma = 0
    shakeT = 0
    shakeX = 0
    shakeY = 0
    hitPause = 0
    pauseFatigue = 0
    arcs = {}
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


function juiceService.spawnArc(color, x, y, targetX, targetY, targetEnt, onComplete, speed)
    if #arcs >= MAX_ARCS then
        return false
    end
    arcs[#arcs + 1] = {
        color = color,
        x = x,
        y = y,
        sx = x,
        sy = y,
        targetX = targetX,
        targetY = targetY,
        targetEnt = targetEnt,
        onComplete = onComplete,
        speed = speed or ARC_SPEED,
        t = 0,
        rot = math.atan2(targetY - y, targetX - x),
    }
    return true
end




function juiceService.update(dt)
    trauma = math.max(0, trauma - TRAUMA_DECAY * dt)
    pauseFatigue = math.max(0, pauseFatigue - PAUSE_FATIGUE_DECAY * dt)
    shakeT = shakeT + dt
    local s = trauma * trauma
    local mag = s * SHAKE_MAX
    shakeX = math.sin(shakeT * SHAKE_FREQ * 1.3) * mag * (love.math.random() * 0.5 + 0.75)
    shakeY = math.cos(shakeT * SHAKE_FREQ) * mag * (love.math.random() * 0.5 + 0.75)

    for i = #arcs, 1, -1 do
        local arc = arcs[i]
        if arc.targetEnt then
            if arc.targetEnt.___removed then
                arc.targetEnt = nil
            else
                arc.targetX = arc.targetEnt.x
                arc.targetY = arc.targetEnt.y - 16
            end
        end

        local dx = arc.targetX - arc.sx
        local dy = arc.targetY - arc.sy
        local dist = math.sqrt(dx * dx + dy * dy)
        local duration = math.max(0.001, dist / arc.speed)
        arc.t = arc.t + dt / duration

        if arc.t >= 1 then
            if arc.onComplete then arc.onComplete() end
            arcs[i] = arcs[#arcs]
            arcs[#arcs] = nil
        else
            local px, py = arc.x, arc.y
            arc.x = arc.sx + dx * arc.t
            local lift = math.sin(arc.t * math.pi) * dist * ARC_HEIGHT
            arc.y = arc.sy + dy * arc.t - lift
            arc.rot = math.atan2(arc.y - py, arc.x - px)
        end
    end
end




function juiceService.draw()
    prof_push("juiceService.draw")

    for i = 1, #arcs do
        local arc = arcs[i]
        local c = arc.color
        if c then
            lg.setColor(c[1], c[2], c[3], c[4] or 1)
        else
            lg.setColor(1, 1, 1, 1)
        end
        g.drawImage("arc_particle", arc.x, arc.y, arc.rot)
    end
    lg.setColor(1, 1, 1, 1)

    prof_pop() -- prof_push("juiceService.draw")
end

return juiceService
