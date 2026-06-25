local objects = require("src.modules.objects.objects")

---@class g.Spell: objects.Class
---@field spellId string
---@field level integer
---@field icon string
local Spell = objects.Class("g:Spell")

local g

function Spell:init(spellId, def)
    self.spellId = spellId
    self.icon = nil
end

function Spell:getIcon()
    g = g or require("src.g")
    self.icon = self.icon or g.getSpellInfo(self.spellId).icon
    return self.icon
end

---@param x number
---@param y number
function Spell:cast(x, y)
    g = g or require("src.g")
    self.numCasts = self.numCasts + 1
    g.castSpell(self, x, y)
end

---@return table
function Spell:serialize()
    return {
        spellId = self.spellId,
        numCasts = self.numCasts
    }
end

---@param data table
---@return g.Spell
function Spell.deserialize(data)
    local sp = Spell(data.spellId)
    sp.numCasts = data.numCasts
    return sp
end

return Spell
