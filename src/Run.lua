
local objects = require("src.modules.objects.objects")
local Squad = require("src.Squad")
local MapGraph = require("src.scenes.map_scene.MapGraph")

---@class g.Run: objects.Class
---@field commander string
---@field difficulty integer
---@field squads {[string]: g.Squad}
---@field spells objects.Set<string>
---@field spellsCast table<string, number> key = spell id, value = spell timeout in sec (reset on battle)
---@field _sortedSquads g.Squad[]?
---@field _battleSquads g.Squad[] temporary squads on the bench for the current fight only
---@field money number
---@field keys integer The player can have at most 3 keys
---@field mana g.ManaCounts
---@field _battleMana g.ManaCounts
---@field blessings {[string]: any}
---@field day integer
---@field demonFury integer
---@field mapGraph MapGraph
---@field lastArmyLayout {squadId:string, dx:number, dy:number}[]?
local Run = objects.Class("g:Run")


function Run:init()
    self.commander = nil -- string
    self.difficulty = 0

    self.squads = {}
    self.spells = objects.Set()
    self.spellsCast = {}
    self._sortedSquads = nil
    self._battleSquads = {}
    self.level = 1
    self.xp = 0
    self.money = 0
    self.keys = 0
    self.mana = {}
    self.blessings = {}
    self.day = 0
    self.daysUntilIncursion = 20 -- the idea is that this may different depending on current zone
    self.demonFury = 0
    self._battleWon = false
    self.mapGraph = nil
    self.lastArmyLayout = nil
end



function Run:update(dt)
end

function Run:getMaxSquads()
    return math.min(4 + self.level, 9)
end


function Run:getXpRequirement()
    return 10 -- TODO. implement properly.
end



function Run:getDaysUntilIncursion()
    return math.max(0, self.daysUntilIncursion - self.day)
end


function Run:resetForBattle()
    for _, squad in pairs(self.squads) do
        squad.deployed = false -- reset squads
        squad.deployDxFromCommander = nil
        squad.deployDyFromCommander = nil
    end

    -- reset spell-cast tracking for this battle
    self.spellsCast = {}

    -- clear temporary fight-only bench squads
    self._battleSquads = {}
    self._sortedSquads = nil
    self._battleWon = false

    -- and reset mana
    self._battleMana = {}
    for mana, count in pairs(self.mana) do
        if count > 0 then
            self._battleMana[mana] = count
        end
    end

    -- reset blessing data
    for id, _ in pairs(self.blessings) do
        local info = g.getBlessingInfo(id)
        if info.resetDataOnBattleStart then
            local d = info.startingData
            if d == nil then d = true end
            self.blessings[id] = d
        end
    end
end


function Run:winBattle()
    if self._battleWon then return end
    self._battleWon = true

    self._battleSquads = {}
    self._sortedSquads = nil
    g.call("battleWon")
end


function Run:serialize()
    local squads = {}
    for id, sq in pairs(self.squads) do
        squads[id] = sq:serialize()
    end
    return {
        commander = self.commander,
        difficulty = self.difficulty,
        squads = squads,
        spells = self.spells:totable(),
        level = self.level,
        xp = self.xp,
        money = self.money,
        keys = self.keys,
        mana = self.mana,
        blessings = self.blessings,
        day = self.day,
        daysUntilIncursion = self.daysUntilIncursion,
        demonFury = self.demonFury,
        mapGraph = self.mapGraph and self.mapGraph:serialize(),
        lastArmyLayout = self.lastArmyLayout,
    }
end

---@param data table (generic `table` type is intentional, format may change which is tedious to sync with LLS)
---@return g.Run
function Run.deserialize(data)
    local run = Run() --[[@as g.Run]]
    if not data then
        return run
    end
    run.commander = data.commander or run.commander
    run.difficulty = data.difficulty or run.difficulty
    run.squads = {}
    for id, sqData in pairs(data.squads or {}) do
        run.squads[id] = Squad.deserialize(sqData)
    end
    run.spells = objects.Set(data.spells or {})
    run.spellsCast = {}
    run.level = data.level or run.level
    run.xp = data.xp or run.xp
    run.money = data.money or run.money
    local keys = data.keys
    if keys == nil then
        keys = data.key and 1 or 0
    end
    run.keys = math.min(3, math.max(0, keys))
    run.mana = data.mana or {}
    run.blessings = data.blessings or {}
    run.day = data.day or run.day
    run.daysUntilIncursion = data.daysUntilIncursion or run.daysUntilIncursion
    run.demonFury = data.demonFury or run.demonFury
    run.mapGraph = data.mapGraph and MapGraph.deserialize(data.mapGraph)
    run.lastArmyLayout = data.lastArmyLayout
    return run
end

return Run
