local juiceService = require("src.juiceService")

local juice_system = {}

local MAX_SPARKS = 20
local MAX_HEALS = 25
local HIT_DURATION = 0.16
local HEAL_DURATION = 0.75
local HEAL_SPARKLE = {
    {"heal_sparkle_1", g.snapToPalette(objects.Color("FFAA2CCA"))},
    {"heal_sparkle_2", g.snapToPalette(objects.Color.WHITE)},
}



local HIT_ANIMATION

local function getHitFrames()
    if not HIT_ANIMATION then
        local quad = g.getImageQuad("hit_generic")
        HIT_ANIMATION = HIT_ANIMATION or helper.splitQuadHorizontally(quad, 2)
    end
    return HIT_ANIMATION
end


---@type sparks.SparkArgs
local SPARK_ARGS = {
    duration = 0.09,
    startRadius = 4,
    endRadius = 10,
}

local DURATION = SPARK_ARGS.duration

local function getStore()
    local world = g.getECS()
    world.data.juiceSystem = world.data.juiceSystem or {
        activeSparks = {},
        sparkPool = {},
        activeHits = {},
        activeHeals = {},
    }
    return world.data.juiceSystem
end

local function acquireSpark(store)
    local pool = store.sparkPool
    local spark = pool[#pool]
    if spark then
        pool[#pool] = nil
        return spark
    end
    return {}
end

local function spawnSpark(store, x, y)
    local active = store.activeSparks
    if #active >= MAX_SPARKS then return end
    local spark = acquireSpark(store)
    spark.x = x + love.math.random(-2, 2)
    spark.y = y + love.math.random(-2, 2)
    spark.rot = love.math.random()*consts.TAU
    spark.time = 0
    active[#active + 1] = spark
end

local function spawnHit(store, x, y)
    local hits = store.activeHits
    hits[#hits + 1] = {
        x = x + love.math.random(-1, 1),
        y = y + love.math.random(-1, 1),
        time = 0,
    }
end

---@param ent ecs.Entity
local function spawnHeal(store, ent)
    if ent.___removed then
        return
    end

    local heals = store.activeHeals
    local t = love.timer.getTime()
    local heal = nil

    for _, h in ipairs(heals) do
        if t > h.expire or h.target.___removed then
            heal = h
            break
        end
    end

    if not heal then
        if #heals >= MAX_HEALS then
            return
        end
        heal = {}
        heals[#heals+1] = heal
    end

    heal.expire = t + HEAL_DURATION
    heal.target = ent
    heal.seed = love.math.random(0, 65535)
end

function juice_system.onHitDamage(attacker, damage, target, isArmorHit)
    if not target then return end
    local store = getStore()

    if isArmorHit or (attacker and attacker.isRanged) then
        spawnSpark(store, target.x, target.y - 8)
    elseif attacker then
        local mx = attacker.x * 0.2 + target.x * 0.8
        local my = attacker.y * 0.2 + target.y * 0.8 - 8
        spawnHit(store, mx, my)
    end
end

local JOLT_DECAY = 8
local JOLT_MAX = 0.3

function juice_system.entityHurt(ent, damage, attacker)
    local maxHp = ent.maxHealth or 1
    local pct = math.min(1, (damage + 50) / maxHp)
    local sign = love.math.random() < 0.5 and -1 or 1
    local newJolt = pct * JOLT_MAX * sign
    if math.abs(ent.damageJolt or 0) < 2 * math.abs(newJolt) then
        ent.damageJolt = newJolt
    end

    -- damage number popup
    if damage >= 1 then
        local dmgPct = damage / maxHp
        local big = dmgPct > 0.25
        local prefix = big and "{w amp=1.5 freq=4 k=0.6}{c r=1 g=0.7 b=0.2}" or "{c r=1 g=1 b=1}"
        g.addWorldTextPopup(ent.x + love.math.random(-4, 4), ent.y - 14,
            prefix .. tostring(math.floor(damage + 0.5)), {
                vely = -55,
                velDamping = 0.985,
                duration = big and 0.7 or 0.45,
                fadeIn = 0.06,
            })
        juiceService.addCameraShake(math.min(0.35, dmgPct * 0.5))
    end
end


---@param ent ecs.Entity
---@param killer ecs.Entity
function juice_system.entityDeath(ent, killer)
    if not ent then return end
    if not ent.isPest then
        juiceService.addCameraShake(0.25)
        juiceService.addTimePause(0.03)
    end
    -- death burst: ring of sparks
    local store = getStore()
    for i = 1, 5 do
        local ang = (i / 5) * consts.TAU + love.math.random() * 0.3
        spawnSpark(store, ent.x + math.cos(ang) * 6, ent.y + math.sin(ang) * 6 - 6)
    end
    -- flying corpse
    if ent.image and not ent.isPest then
        g.spawnEntity("body", ent.x, ent.y, ent)
    end
end

local HEALING_TEXT = g.snapToPalette(objects.Color("FF2BC66E"))

---@param unitEnt ecs.Entity
---@param addHealth number
function juice_system.entityHealed(unitEnt, addHealth)
    -- Spawn heal particle
    local store = getStore()
    spawnHeal(store, unitEnt)

    -- Add "Heal" text
    local offy = 0
    if unitEnt.image then
        local _, ih = g.getImageSize(unitEnt.image)
        offy = -ih
    end
    local healText = helper.wrapRichtextColor(HEALING_TEXT, string.format("%d", addHealth))
    g.addWorldTextPopup(
        unitEnt.x, unitEnt.y + offy,
        healText.."{health}",
        {duration = 1}
    )
end

---@param ent ecs.Entity
---@param stat string
---@param increase number?
function juice_system.entityBuffed(ent, stat, increase)
    local statInfo = g.getStatInfo(stat)
    local prefix = increase > 0 and "+" or ""
    local text = helper.wrapRichtextColor(statInfo.color, string.format("%s%d", prefix, increase))
    local offy = 0
    if ent.image then
        local _, ih = g.getImageSize(ent.image)
        offy = -ih * 0.9
    end
    g.addWorldTextPopup(
        ent.x, ent.y + offy,
        text.."{"..statInfo.icon.."}",
        {duration = 1}
    )
end

function juice_system.explosion(x, y, damage, radius)
    juiceService.addCameraShake(math.min(0.6, 0.2 + (radius or 60) / 300))
    juiceService.addTimePause(0.05)
end

function juice_system.battleStarted()
    juiceService.addCameraShake(0.4)
end


function juice_system.postUpdate(dt)
    local world = g.getECS()
    local decay = math.exp(-JOLT_DECAY * dt)
    for _, ent in world:iterate("damageJolt") do
        ent.damageJolt = ent.damageJolt * decay
        if math.abs(ent.damageJolt) < 0.001 then
            ent.damageJolt = nil
        end
    end

    local store = getStore()
    local active = store.activeSparks
    local pool = store.sparkPool

    for i = #active, 1, -1 do
        local spark = active[i]
        spark.time = spark.time + dt
        if spark.time > DURATION then
            active[i] = active[#active]
            active[#active] = nil
            pool[#pool + 1] = spark
        end
    end

    local hits = store.activeHits
    for i = #hits, 1, -1 do
        hits[i].time = hits[i].time + dt
        if hits[i].time > HIT_DURATION then
            hits[i] = hits[#hits]
            hits[#hits] = nil
        end
    end
end

function juice_system.postDraw()
    local store = getStore()
    local active = store.activeSparks

    lg.setColor(1,1,1)
    for i = 1, #active do
        local spark = active[i]
        for j = 0, 2 do
            local rot = (2 * math.pi * j) / 3
            helper.drawSpark(spark.x, spark.y, spark.time, spark.rot + rot, SPARK_ARGS)
        end
    end

    lg.setColor(1,1,1)
    local frames = getHitFrames()
    local hits = store.activeHits
    for i = 1, #hits do
        local h = hits[i]
        local frame = frames[math.min(#frames, math.floor(h.time / HIT_DURATION * #frames) + 1)]
        local _, _, w, hh = frame:getViewport()
        lg.draw(g.getAtlas(), frame, h.x, h.y, 0, 1, 1, w/2, hh/2)
    end

    local t = love.timer.getTime()
    local c = gsman.setColor(1, 1, 1)
    for _, h in ipairs(store.activeHeals) do
        local remaining = h.expire - t
        if remaining > 0 and not h.target.___removed then
            local offY = 0
            local radiusX, radiusY = 15, 15
            if h.target.image then
                local iw, ih = g.getImageSize(h.target.image)
                offY = ih / 2
                radiusX = iw / 2
                radiusY = ih / 2
            end

            local state = helper.hashInteger(h.seed) * 65536
            for i = 1, 4 do
                -- These hash integers provides consistent PRNG number using single
                -- state/seed value without the overhead of RNG object.
                local angle = state / 4294967296 * consts.TAU
                state = helper.hashInteger(state) * 65536
                local radiusMul = state / 4294967296
                state = helper.hashInteger(state) * 65536

                local imgindex = math.floor(remaining * 8 + i) % 2 + 1
                local imginfo = HEAL_SPARKLE[imgindex]
                local x = math.cos(angle) * radiusX * radiusMul + h.target.x
                local y = math.sin(angle) * radiusY * radiusMul + h.target.y + remaining * 10 - offY
                lg.setColor(imginfo[2])
                g.drawImage(imginfo[1], x, y)
            end
        end
    end
    c:pop()
end

return juice_system
