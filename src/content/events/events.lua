

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

--- Gremlin Games
do

--[[
A group of rowdy gremlins invites you to play a game. You are led to a stone dial painted with black and gold stripes, and a glowing orb rolling around on top.

Bet: 50% gain 20 gold, 50% lose 20 gold.
(Repeat with doubled numbers)

PASS: “GOLD!” 
The goblins hand you a pile of coins, but you feel as though your work isn’t done…

FAIL: “BLACK!”
A large gremlin steps between you and the wheel. You have no choice but to give up the gold. Want to double it and try again?

Leave

You decide it would be best not to risk it.
]]

local EVENT_TXT = loc("A group of rowdy gremlins invites you to play a game. You are led to a stone dial painted with black and gold stripes, and a glowing orb rolling around on top.")

local EVENT_BET = interp("Bet: 50:50 gain/lose %{gold} {coin_icon}")
local EVENT_PASS = loc("The goblins hand you a pile of coins, but you feel as though your work isn't done...")
local EVENT_FAIL = loc("A large gremlin steps between you and the wheel. You have no choice but to give up the gold. Want to double it and try again?")
local EVENT_LEAVE = loc("You decide it would be best not to risk it.")
local EVENT_LEAVE_BTN = loc("Leave")
local EVENT_OK_BTN = loc("Ok")
local EVENT_NOMONEY = loc("You don't have enough money to bet!")

---@param evPass g.RandomEventPass
local function leave(evPass)
    evPass:changeText(EVENT_LEAVE)
    evPass:setOptions({{EVENT_OK_BTN, evPass.leave}})
end

---@param evPass g.RandomEventPass
---@param amount integer
local function bet(evPass, amount)
    if g.canAffordGold(amount) then
        local rng = love.math.random()
        if rng < 0.5 then
            -- success
            evPass:changeText(EVENT_PASS)
            g.addGold(amount)
        else
            -- fail
            evPass:changeText(EVENT_FAIL)
            assert(g.trySpendGold(amount))
        end

        evPass:setOptions({
            {EVENT_BET({gold = amount * 2}), function(evPass)
                return bet(evPass, amount * 2)
            end},
            {EVENT_LEAVE_BTN, leave}
        })
    else
        evPass:changeText(EVENT_NOMONEY)
        evPass:setOptions({{EVENT_OK_BTN, evPass.leave}})
    end
end


defineEventType("gremlin_games", EVENT_TXT, function(evPass)
    evPass:setOptions({
        {EVENT_BET({gold = 20}), function(evPass)
            return bet(evPass, 20)
        end},
        {EVENT_LEAVE_BTN, leave}
    })
end)

end


return EVENT_TYPES
