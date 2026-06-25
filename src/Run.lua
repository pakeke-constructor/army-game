
local objects = require("src.modules.objects.objects")
local Squad = require("src.Squad")
local MapGraph = require("src.scenes.map_scene.MapGraph")

---@class g.Run: objects.Class
---@field commander string
---@field difficulty integer
---@field squads {[string]: g.Squad}
---@field spells {[string]: boolean}
---@field spellsCast {[string]: boolean} which spells have been cast this battle (reset each battle)
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
    self.spells = {}
    self.spellsCast = {}
    self._sortedSquads = nil
    self._battleSquads = {}
    self.level = 1
    self.xp = 0
    self.money = 0
    self.keys = 0
    self.mana = {}
    self.blessings = {}
    self.day = 1
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



local DAYS_UNTIL_ATTACK = 20 -- todo: do this better in future
function Run:getDaysUntilIncursion()
    return math.max(0, DAYS_UNTIL_ATTACK - self.day)
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
    self.demonFury = self.demonFury + 1
    g.call("battleWon")
end


---@return {squads: table[], level: integer, xp: integer, money: number, mana: g.ManaCounts, _battleMana: g.ManaCounts, blessings: {[string]: any}, day: integer, demonFury: integer, mapGraph: table?}
function Run:serialize()
    local squads = {}
    for id, sq in pairs(self.squads) do
        squads[id] = sq:serialize()
    end
    local spells = {}
    for id in pairs(self.spells) do
        spells[id] = true
    end
    return {
        squads = squads,
        spells = spells,
        level = self.level,
        xp = self.xp,
        money = self.money,
        keys = self.keys,
        mana = self.mana,
        _battleMana = self._battleMana,
        blessings = self.blessings,
        day = self.day,
        demonFury = self.demonFury,
        mapGraph = self.mapGraph and self.mapGraph:serialize(),
        lastArmyLayout = self.lastArmyLayout,
    }
end

---@param data {squads: table[]?, level: integer?, xp: integer?, money: number?, mana: g.ManaCounts?, _battleMana: g.ManaCounts?, blessings: {[string]: any}?, day: integer?, demonFury: integer?, mapGraph: table?, keys:integer?, key:boolean?}?
---@return g.Run
function Run.deserialize(data)
    local run = Run()
    if not data then
        return run
    end
    run.squads = {}
    for id, sqData in pairs(data.squads or {}) do
        run.squads[id] = Squad.deserialize(sqData)
    end
    run.spells = {}
    for id in pairs(data.spells or {}) do
        run.spells[id] = true
    end
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
    run._battleMana = data._battleMana or {}
    run.blessings = data.blessings or {}
    run.day = data.day or run.day
    run.demonFury = data.demonFury or run.demonFury
    run.mapGraph = data.mapGraph and MapGraph.deserialize(data.mapGraph)
    run.lastArmyLayout = data.lastArmyLayout
    return run
end

return Run
