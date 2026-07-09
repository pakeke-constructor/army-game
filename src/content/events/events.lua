

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
local PICKUP_AFTER = interp("You pick up the rock, and are showered with gold! (Earn %{gold} {coin_icon})")
local PICKUP_FAIL = loc("You pick up the rock, and there's nothing there.")

local LEAVE = loc("Leave the rock.")

---@param eventPass g.RandomEventPass
defineEventType("rock_event", EVENT_TXT, function(eventPass)
    eventPass:setOptions({
        {PICKUP, function(evPass)
            -- pick up the rock
            if love.math.random() < 0.5 then
                local gold = math.floor(helper.lerp(20, 50, love.math.random()))
                g.addGold(gold)
                evPass:changeText(PICKUP_AFTER({gold = gold}))
            else
                evPass:changeText(PICKUP_FAIL)
            end
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

PASS: "GOLD!" 
The goblins hand you a pile of coins, but you feel as though your work isn't done...

FAIL: "BLACK!"
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
local EVENT_REACH = loc("+1 Demon Fury. Gain a Common blessing.")
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
                local run = g.getRun()
                run.demonFury = run.demonFury + 1
                rewardPopupService.genericReward({
                    {type = "blessing", rarityWeights = {COMMON = 1}},
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




-- Clock Tower
do
--[[
You notice a lonely clock tower ticking away in the middle of a large clearing. When you climb to the top, you are surprised to find an old man inside, hand-cranking the gears of the tower. He doesn't seem to notice you.

Stop the Clock: +2 days
You pull against the motion of the gears, briefly grinding them to a halt. The man finally lets go of the device, and looks at you.
You decide it would be wise to leave.

Help Him: -2 days. Gain Random Rare/Legendary blessing.
You reach into the mechanisms of the clock and heave, helping the strange man turn the gears for a few minutes...

...Or was it days?

]]

local EVENT_TXT = loc("You notice a lonely clock tower ticking away in the middle of a large clearing. When you climb to the top, you are surprised to find an old man inside, hand-cranking the gears of the tower. He doesn't seem to notice you.")

local EVENT_STOP_TXT = loc("Stop the Clock")
local EVENT_STOP = loc("+2 days\n\nYou pull against the motion of the gears, briefly grinding them to a halt. The man finally lets go of the device, and looks at you.\n\nYou decide it would be wise to leave.")

local EVENT_HELP_TXT = loc("Help Him")
local EVENT_HELP = loc("-2 days. Gain Random Rare/Legendary blessing.\n\nYou reach into the mechanisms of the clock and heave, helping the strange man turn the gears for a few minutes...\n\n...Or was it days?")

local EVENT_OK_TXT = loc("Ok")

defineEventType("clock_tower", EVENT_TXT, function(evPass)
    evPass:setOptions({
        {EVENT_STOP_TXT, function(evPass)
            g.decrementDays(2)
            evPass:changeText(EVENT_STOP)
            evPass:setOptions({{EVENT_OK_TXT, evPass.leave}})
        end},
        {EVENT_HELP_TXT, function(evPass)
            g.incrementDays(2)
            evPass:changeText(EVENT_HELP)
            evPass:setOptions({{EVENT_OK_TXT, function(evPass)
                rewardPopupService.genericReward({
                    {type = "blessing", rarityWeights = {RARE = 4, LEGENDARY = 3}}
                })
                evPass:leave()
            end}})
        end},
    })
end)

end


return EVENT_TYPES
