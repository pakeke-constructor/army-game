
local objects = require("src.modules.objects.objects")

---@class g.Squad: objects.Class
---@field squadId string
---@field level integer
---@field icon string
---@field perks string[]
---@field formation "square"|"circle"|"horizontal"|"vertical"|"diamond"
---@field deployed boolean?
---@field canAfford boolean?
local Squad = objects.Class("g:Squad")

--- Formation functions: (n, spacing) -> {{x,y}, ...}
Squad.FORMATIONS = {}

Squad.FORMATIONS.square = function(n, spacing)
    local offsets = {}
    local cols = math.ceil(math.sqrt(n))
    local totalW = (cols - 1) * spacing
    local totalH = (math.ceil(n / cols) - 1) * spacing
    for i = 1, n do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        offsets[i] = {x = -totalW / 2 + col * spacing, y = -totalH / 2 + row * spacing}
    end
    return offsets
end

Squad.FORMATIONS.circle = function(n, spacing)
    if n == 1 then return {{x = 0, y = 0}} end
    local offsets = {}
    local r = spacing * math.max(1, n / 6)
    for i = 1, n do
        local angle = (i - 1) / n * math.pi * 2
        offsets[i] = {x = math.cos(angle) * r, y = math.sin(angle) * r}
    end
    return offsets
end

Squad.FORMATIONS.horizontal = function(n, spacing)
    local offsets = {}
    local totalW = (n - 1) * spacing
    for i = 1, n do
        offsets[i] = {x = -totalW / 2 + (i - 1) * spacing, y = 0}
    end
    return offsets
end

Squad.FORMATIONS.vertical = function(n, spacing)
    local offsets = {}
    local totalH = (n - 1) * spacing
    for i = 1, n do
        offsets[i] = {x = 0, y = -totalH / 2 + (i - 1) * spacing}
    end
    return offsets
end

Squad.FORMATIONS.diamond = function(n, spacing)
    if n == 1 then return {{x = 0, y = 0}} end
    local offsets = {}
    local r = spacing * math.max(1, n / 6)
    for i = 1, n do
        local t = (i - 1) / n * 4
        local x, y
        if t < 1 then     x, y =  t,      1 - t
        elseif t < 2 then x, y =  2 - t,  -(t - 1)
        elseif t < 3 then x, y =  -(t-2), -(3 - t)
        else              x, y =  -(4-t),  t - 3
        end
        offsets[i] = {x = x * r, y = y * r}
    end
    return offsets
end

local g

function Squad:init(squadId, def)
    self.squadId = squadId
    self.level = 1
    self.perks = def and {unpack(def.perks)} or {}
    self.formation = "square"
    self.deployed = false
    self.icon = nil
end

function Squad:getIcon()
    g = g or require("src.g")
    self.icon = self.icon or g.getSquadInfo(self.squadId).icon
    return self.icon
end


---@param x number
---@param y number
---@return ecs.Entity[]
function Squad:spawn(x, y)
    assert(not self.deployed, "Squad already deployed")
    g = g or require("src.g")
    local entities = g.spawnSquad(self, x, y)
    self.deployed = true
    return entities
end

---@return table[] offsets {{x,y}, ...}
function Squad:getFormationOffsets()
    g = g or require("src.g")
    local fn = Squad.FORMATIONS[self.formation] or Squad.FORMATIONS.square
    return fn(g.getSquadUnitCount(self.squadId), consts.SQUAD_SPACING)
end


---@return g.Squad
function Squad:serialize()
    return {
        squadId = self.squadId,
        level = self.level,
        perks = self.perks,
        formation = self.formation,
    }
end


---@param data table
---@return g.Squad
function Squad.deserialize(data)
    local sq = Squad(data.squadId)
    sq.level = data.level or 1
    sq.perks = data.perks or {}
    sq.formation = data.formation or "square"
    return sq
end

return Squad
