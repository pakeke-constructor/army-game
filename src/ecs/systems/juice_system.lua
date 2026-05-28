local juice_system = {}

local MAX_SPARKS = 20
local HIT_DURATION = 0.16



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

function juice_system.onHitDamage(attacker, damage, target)
    if not target then return end

    local store = getStore()
    local active = store.activeSparks
    if #active >= MAX_SPARKS then return end

    local spark = acquireSpark(store)
    spark.x = target.x + love.math.random(-2, 2)
    spark.y = target.y + love.math.random(-2, 2) - 8
    spark.rot = love.math.random()*consts.TAU
    spark.time = 0
    active[#active + 1] = spark

    local hits = store.activeHits
    hits[#hits + 1] = {
        x = target.x + love.math.random(-1, 1),
        y = target.y + love.math.random(-1, 1) - 8,
        time = 0,
    }
end

function juice_system.postUpdate(dt)
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

    for i = 1, #active do
        local spark = active[i]
        for j = 0, 2 do
            local rot = (2 * math.pi * j) / 3
            helper.drawSpark(spark.x, spark.y, spark.time, spark.rot + rot, SPARK_ARGS)
        end
    end

    local frames = getHitFrames()
    local hits = store.activeHits
    for i = 1, #hits do
        local h = hits[i]
        local frame = frames[math.min(#frames, math.floor(h.time / HIT_DURATION * #frames) + 1)]
        local _, _, w, hh = frame:getViewport()
        lg.draw(g.getAtlas(), frame, h.x, h.y, 0, 1, 1, w/2, hh/2)
    end
end

return juice_system
