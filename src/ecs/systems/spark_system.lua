local spark_system = {}

local MAX_SPARKS = 20

---@type sparks.SparkArgs
local SPARK_ARGS = {
    duration = 0.11,
    startRadius = 4,
    endRadius = 9,
}

local DURATION = SPARK_ARGS.duration

local function getStore()
    local world = g.getECS()
    world.data.sparkSystem = world.data.sparkSystem or {
        active = {},
        pool = {},
    }
    return world.data.sparkSystem
end

local function acquireSpark(store)
    local pool = store.pool
    local spark = pool[#pool]
    if spark then
        pool[#pool] = nil
        return spark
    end
    return {}
end

function spark_system.onHitDamage(attacker, damage, target)
    if not target then return end

    local store = getStore()
    local active = store.active
    if #active >= MAX_SPARKS then return end

    local spark = acquireSpark(store)
    spark.x = target.x + love.math.random(-2, 2)
    spark.y = target.y + love.math.random(-2, 2) - 8
    spark.rot = love.math.random()*consts.TAU
    spark.time = 0
    active[#active + 1] = spark
end

function spark_system.postUpdate(dt)
    local store = getStore()
    local active = store.active
    local pool = store.pool

    for i = #active, 1, -1 do
        local spark = active[i]
        spark.time = spark.time + dt
        if spark.time > DURATION then
            active[i] = active[#active]
            active[#active] = nil
            pool[#pool + 1] = spark
        end
    end
end

function spark_system.postDraw()
    local store = getStore()
    local active = store.active

    for i = 1, #active do
        local spark = active[i]
        for j = 0, 2 do
            local rot = (2 * math.pi * j) / 3
            helper.drawSpark(spark.x, spark.y, spark.time, spark.rot + rot, SPARK_ARGS)
        end
    end
end

return spark_system
