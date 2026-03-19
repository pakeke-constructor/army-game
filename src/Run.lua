local objects = require("src.modules.objects.objects")

---@class g.Run: objects.Class
local Run = objects.Class("g:Session")


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

end


function Run:deserialize()

end

return Run

