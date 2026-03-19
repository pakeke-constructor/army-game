local objects = require("src.modules.objects.objects")

---@class g.Session: objects.Class
local Session = objects.Class("g:Session")

function Session:init()
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

return Session
