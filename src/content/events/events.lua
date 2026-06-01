

---@class g.RandomEventType
---@field id string
---@field description string
---@field run fun(eventPass: g.RandomEventPass)

---@type table<string, g.RandomEventType>
local EVENT_TYPES = {}

---@param id string
---@param desc string
---@param func fun(eventPass: g.RandomEventPass)
local function defineEventType(id, desc, func)
    EVENT_TYPES[id] = {
        id = id,
        description = desc,
        run = func,
    }
end




-- just as an example: Rock event
do
local EVENT_TXT = loc("There's a suspicious rock sitting on a path... what do you do?")

local PICKUP = loc("Pick up the rock")
local PICKUP_AFTER = loc("You pick up the rock, and are showered with gold! (Earn 20 gold)")

local LEAVE = loc("Leave the rock.")

---@param eventPass g.RandomEventPass
defineEventType("rock_event", EVENT_TXT, function(eventPass)
    eventPass:setOptions({
        {PICKUP, function(evPass)
            -- pick up the rock
            g.addGold(20)
            evPass:changeText(PICKUP_AFTER)
            evPass:deleteThisOption()
        end},
        {LEAVE, function(evPass)
            evPass:leave()
        end}
    })
end)
end


return EVENT_TYPES
