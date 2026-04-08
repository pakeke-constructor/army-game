local objects = require("src.modules.objects.objects")
local Squad = require("src.Squad")
local MapGraph = require("src.scenes.map_scene.MapGraph")

---@class g.Run: objects.Class
---@field squads g.Squad[]
---@field money number
---@field food number
---@field mana number
---@field maxFood number
---@field maxMana number
---@field blessings string[]
---@field day integer
---@field mapGraph MapGraph
local Run = objects.Class("g:Run")


function Run:init()
    self.squads = {}
    self.money = 0
    self.food = 3
    self.mana = 3
    self.maxFood = 100
    self.maxMana = 30
    self.blessings = {}
    self.day = 1
    self.mapGraph = nil
end


---@return table
function Run:serialize()
    local squads = {}
    for i = 1, #self.squads do
        squads[i] = self.squads[i]:serialize()
    end
    return {
        squads = squads,
        money = self.money,
        food = self.food,
        mana = self.mana,
        maxFood = self.maxFood,
        maxMana = self.maxMana,
        blessings = self.blessings,
        day = self.day,
        mapGraph = self.mapGraph and self.mapGraph:serialize(),
    }
end

---@param data table?
---@return g.Run
function Run.deserialize(data)
    local run = Run()
    if not data then
        return run
    end
    run.squads = {}
    for i = 1, #(data.squads or {}) do
        run.squads[i] = Squad.deserialize(data.squads[i])
    end
    run.money = data.money or run.money
    run.food = data.food or run.food
    run.mana = data.mana or run.mana
    run.maxMana = data.maxMana
    run.maxFood = data.maxFood
    run.blessings = data.blessings or {}
    run.day = data.day or run.day
    run.mapGraph = data.mapGraph and MapGraph.deserialize(data.mapGraph)
    return run
end

return Run
