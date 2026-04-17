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
---@field spells table<string, number>
---@field day integer
---@field demonRage integer
---@field mapGraph MapGraph
local Run = objects.Class("g:Run")


function Run:init()
    self.squads = {}
    self.level = 1
    self.xp = 0
    self.money = 0
    self.food = 3
    self.mana = 3
    self.maxFood = 100
    self.maxMana = 30
    self.blessings = {}
    self.spells = {}
    self.day = 1
    self.demonRage = 0
    self.mapGraph = nil

    if consts.DEV_MODE then
        -- populate test stuff.
        self.blessings = {
            "iron_hide", "golden_coffers", "swift_feet", "blood_tithe", "barrage",
            "iron_hide", "golden_coffers", "swift_feet", "blood_tithe", "barrage",
            "iron_hide", "golden_coffers", "swift_feet", "blood_tithe", "barrage",
        }
        self.spells = {zap = 0, heal = 0}
    end
end



function Run:update(dt)
    for spellId, cd in pairs(self.spells) do
        if cd > 0 then
            self.spells[spellId] = math.max(0, cd - dt)
        end
    end
end

function Run:getMaxSquads()
    return math.min(4 + self.level, 9)
end


function Run:getXpRequirement()
    return 100 -- TODO. implement properly.
end



local DAYS_UNTIL_ATTACK = 20 -- todo: do this better in future
function Run:getDaysUntilIncursion()
    return math.max(0, DAYS_UNTIL_ATTACK - self.day)
end


--- gets spell cooldown. Returns nil if 
---@param spellId string
---@return number?
function Run:getSpellCooldown(spellId)
    local cd = self.spells[spellId]
    if not cd or cd <= 0 then
        return nil
    end
    return cd
end


---@param spellId string
---@param cd number
function Run:setSpellCooldown(spellId, cd)
    self.spells[spellId] = math.max(0, cd or 0)
end

---@return table
function Run:serialize()
    local squads = {}
    for i = 1, #self.squads do
        squads[i] = self.squads[i]:serialize()
    end
    return {
        squads = squads,
        level = self.level,
        xp = self.xp,
        money = self.money,
        food = self.food,
        mana = self.mana,
        maxFood = self.maxFood,
        maxMana = self.maxMana,
        blessings = self.blessings,
        spells = self.spells,
        day = self.day,
        demonRage = self.demonRage,
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
    run.level = data.level or run.level
    run.xp = data.xp or run.xp
    run.money = data.money or run.money
    run.food = data.food or run.food
    run.mana = data.mana or run.mana
    run.maxMana = data.maxMana
    run.maxFood = data.maxFood
    run.blessings = data.blessings or {}
    run.spells = data.spells or {}
    run.day = data.day or run.day
    run.demonRage = data.demonRage or run.demonRage
    run.mapGraph = data.mapGraph and MapGraph.deserialize(data.mapGraph)
    return run
end

return Run
