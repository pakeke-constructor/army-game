local objects = require("src.modules.objects.objects")

---@class g.Run: objects.Class
local Run = objects.Class("g:Run")


function Run:init()
    self.squads = {}      -- list of squad ids
    self.health = 20
    self.maxHealth = 20
    self.money = 0
    self.food = 3
    self.mana = 3
    self.blessings = {}   -- list of blessing ids
    self.day = 1
    self.mapPosition = nil -- current node on map
end


function Run:serialize()
    return {
        squads = self.squads,
        health = self.health,
        maxHealth = self.maxHealth,
        money = self.money,
        food = self.food,
        mana = self.mana,
        blessings = self.blessings,
        day = self.day,
        mapPosition = self.mapPosition,
    }
end

function Run.deserialize(data)
    local run = Run()
    if not data then
        return run
    end
    run.squads = data.squads or {}
    run.health = data.health or run.health
    run.maxHealth = data.maxHealth or run.maxHealth
    run.money = data.money or run.money
    run.food = data.food or run.food
    run.mana = data.mana or run.mana
    run.blessings = data.blessings or {}
    run.day = data.day or run.day
    run.mapPosition = data.mapPosition
    return run
end

return Run

