


---@class ecs.components.AI
---@field public target "enemy"|"ally"
---@field public getPriority fun(selfEnt: ecs.Entity, targEnt:ecs.Entity): number
---@field public range [number,number]
local ai = {
    target = "enemy",
    getPriority = function(selfEnt, targEnt)
        -- higher priority = target earlier
        return 0
    end,

    range = {300, 400}, -- {min, max}
    -- this entity moves towards `enemy` units until it's within 300 units.
    -- then, if the enemy moves more than 400 units away, it moves again.
}

---@class ecs.Entity
---@field public ai ecs.components.AI?
---@field public color objects.Color?
local ecs_Entity = {}



