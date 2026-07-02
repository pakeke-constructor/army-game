

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



-- Blood Pool
do
--[[
A blood red pool sits there, shimmering with demon magic.
It seems hungry.

Reach into the shallows: +1 Demon Fury. Gain a Common blessing.

Send a squad in: <A random squad> is permanently removed from your army. Gain a Rare blessing.

Avoid
]]

local EVENT_TXT = loc("A blood red pool sits there, shimmering with demon magic. It seems hungry.")
local EVENT_REACH_TXT = loc("Reach into the shallows")
local EVENT_REACH = loc("+%{demon_fury} Demon Fury. Gain a Common blessing.", {demon_fury = 1})
local EVENT_SQUAD_TXT = loc("Send a squad in")
local EVENT_SQUAD = interp("%{squadName} is gone from your squads. Gain a Rare blessing.")
local EVENT_AVOID_TXT = loc("Avoid")
local EVENT_OK_BTN = loc("Ok")

defineEventType("blood_pool", EVENT_TXT, function(evPass)
    -- Pick squad to sacrifice 😭
    ---@type string[]
    local pool = {}
    for k in pairs(g.getRun().squads) do
        local sqinfo = g.getSquadInfo(k)
        if not (sqinfo.entityDef.isCommander or sqinfo.entityDef.isBuilding) then
            pool[#pool+1] = k
        end
    end
    local selectedSquad = nil
    if #pool > 0 then
        selectedSquad = g.getSquadFromArmy(helper.randomChoice(pool))
    end

    ---@type g.EventOption[]
    local opts = {
        {EVENT_REACH_TXT, function(evPass)
            evPass:changeText(EVENT_REACH)
            evPass:setOptions({{EVENT_OK_BTN, function(evPass)
                rewardPopupService.genericReward({
                    {type = "blessing", rarityWeights = {COMMON = 1}},
                    {type = "demon_fury", amount = 1}
                })
                evPass:leave()
            end}})
        end}
    }
    if selectedSquad then
        local squadName = g.getSquadInfo(selectedSquad.squadId).name

        opts[#opts+1] = {EVENT_SQUAD_TXT, function(evPass)
            g.removeSquadFromArmy(selectedSquad)
            evPass:changeText(EVENT_SQUAD({squadName = squadName}))
            evPass:setOptions({{EVENT_OK_BTN, function(evPass)
                rewardPopupService.genericReward({
                    {type = "blessing", rarityWeights = {RARE = 1}}
                })
                evPass:leave()
            end}})
        end}
    end

    opts[#opts+1] = {EVENT_AVOID_TXT, function(evPass)
        evPass:leave()
    end}

    evPass:setOptions(opts)
end)

end


return EVENT_TYPES
