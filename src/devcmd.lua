local devcmd = {}

local cmdBuf = ""
local active = false
local LOG = {}
local logTime = 0
local FADE_AFTER = 3
local FADE_DUR = 1

local function addLog(msg)
    LOG[#LOG + 1] = msg
    if #LOG > 10 then table.remove(LOG, 1) end
    logTime = love.timer.getTime()
end

local COMMANDS = {}

COMMANDS.help = function()
    addLog("/get <squad_id> - add squad to army")
    addLog("/upgrade <perk_id> [idx] - add perk to squad")
    addLog("/spawn <ent_id> [count] - spawn at cursor")
    addLog("/gold <amount> - add gold")
    addLog("/tp - teleport to cursor (map)")
    addLog("/sb - reset & enter sandbox battle")
    addLog("/rb - reset battle & zoom out (map-gen test)")
    addLog("/vacuum - removes all fogs")
    addLog("/help - show this")
end

COMMANDS.sb = function()
    g.newRun({
        commander = consts.STARTING_COMMANDER,
        difficulty = 0
    })
    local battle = require("src.scenes.battle_scene.battle_scene")
    battle.sandbox = true
    g.gotoScene("battle_scene")
    addLog("sandbox mode")
end

COMMANDS.rb = function()
    if not g.hasRun() then
        g.newRun({ commander = consts.STARTING_COMMANDER, difficulty = 0 })
    end
    local battle = require("src.scenes.battle_scene.battle_scene")
    battle.sandbox = true
    g.gotoScene("battle_scene")
    battle.devZoomOut = true
    addLog("reset battle (zoomed out)")
end

COMMANDS.get = function(args)
    local squadId = args[1]
    if not squadId then return addLog("usage: /get <squad_id>") end
    if g.getSquadFromArmy(squadId) then return addLog("already have squad: " .. squadId) end
    g.addSquadToArmy(squadId)
    addLog("added squad: " .. squadId)
end

COMMANDS.upgrade = function(args)
    local perkId = args[1]
    if not perkId then return addLog("usage: /upgrade <perk_id> [idx]") end
    local army = g.getSortedArmyList()
    if #army == 0 then return addLog("no squads in army") end
    local idx = tonumber(args[2]) or 1
    local squad = army[idx]
    if not squad then return addLog("no squad at index " .. idx) end
    g.addPerkToSquad(squad, perkId)
    addLog("added perk " .. perkId .. " to squad #" .. idx)
end

COMMANDS.spawn = function(args)
    local entId = args[1]
    if not entId then return addLog("usage: /spawn <ent_id> [count]") end
    local count = tonumber(args[2]) or 1
    local mx, my = love.mouse.getPosition()
    for i = 1, count do
        g.spawnEntity(entId, mx + (i - 1) * 20, my)
    end
    addLog("spawned " .. count .. "x " .. entId)
end

COMMANDS.gold = function(args)
    local amt = tonumber(args[1])
    if not amt then return addLog("usage: /gold <amount>") end
    g.addGold(amt)
    local run = g.getRun()
    addLog("gold -> " .. run.money)
end

COMMANDS.xp = function(args)
    local amt = tonumber(args[1])
    if not amt then return addLog("usage: /xp <amount>") end
    g.addXP(amt)
    local run = g.getRun()
    addLog("xp -> " .. run.xp)
end

COMMANDS.tp = function()
    local scene, name = g.getCurrentScene()
    if name ~= "map_scene" then return addLog("/tp only works in map scene") end
    local run = g.getRun()
    local graph = run.mapGraph
    if not graph then return addLog("no map graph") end

    local mx, my = love.mouse.getPosition()
    local wx, wy = scene.camera:toWorld(mx, my)

    local best, bestD2
    graph:forEachNode(function(node)
        local nx, ny = graph:getDrawPos(node)
        local dx, dy = nx - wx, ny - wy
        local d2 = dx * dx + dy * dy
        if not bestD2 or d2 < bestD2 then
            best = node
            bestD2 = d2
        end
    end)

    if not best then return addLog("no node at cursor") end

    graph:setPlayerPosition(best.x, best.y)
    scene.traveling = nil
    scene.camX, scene.camY = graph:getDrawPos(best)
    if not best.visited then
        best.visited = true
        best:enter()
    end
    addLog("teleported")
end

COMMANDS.vacuum = function()
    local scene, name = g.getCurrentScene()
    if name ~= "map_scene" then return addLog("/vacuum only works in map scene") end
    ---@cast scene g.MapScene
    for _, node in ipairs(scene.nodeList) do
        node.seen = true
    end
    addLog("vacuumed all fogs")
end

COMMANDS.lua = function(args)
    local command = table.concat(args, " ")
    if #command == 0 then
        return addLog("Usage: /lua <lua>")
    end

    local l, msg = loadstring(command)
    if not l then
        return addLog("Error: "..msg)
    end

    local ok, bt = xpcall(l, debug.traceback)
    if not ok then
        return addLog(bt)
    end

    if bt ~= nil then
        return addLog(tostring(bt))
    else
        return addLog("Executed")
    end
end

local function execCmd(line)
    local parts = {}
    for w in line:gmatch("%S+") do parts[#parts + 1] = w end
    local name = parts[1]
    if not name then return end
    local cmd = COMMANDS[name]
    if not cmd then return addLog("unknown command: " .. name) end
    table.remove(parts, 1)
    local ok, err = pcall(cmd, parts)
    if not ok then addLog("ERROR: " .. tostring(err)) end
end

function devcmd.keypressed(key)
    if not consts.DEV_MODE then return end
    if key == "/" and not active then
        active = true
        cmdBuf = ""
        return true
    end
    if not active then return false end
    if key == "escape" then
        active = false
        cmdBuf = ""
        return true
    end
    if key == "return" then
        active = false
        execCmd(cmdBuf)
        cmdBuf = ""
        return true
    end
    if key == "backspace" then
        cmdBuf = cmdBuf:sub(1, -2)
        return true
    end
    return true
end

function devcmd.textinput(text)
    if not active then return false end
    if text == "/" then return true end
    cmdBuf = cmdBuf .. text
    return true
end

function devcmd.draw()
    if not consts.DEV_MODE then return end
    love.graphics.push()
    love.graphics.scale(2, 2)
    local font = love.graphics.getFont()
    local W = love.graphics.getWidth() / 2
    local y = love.graphics.getHeight() / 2 - 24
    if active then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, y, W, 24)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("/" .. cmdBuf .. "_", 4, y + 4)
    end
    -- draw log with fade
    local elapsed = love.timer.getTime() - logTime
    local alpha = 1
    if not active and elapsed > FADE_AFTER then
        alpha = 1 - math.min((elapsed - FADE_AFTER) / FADE_DUR, 1)
    end
    if alpha > 0 and #LOG > 0 then
        local logY = y - #LOG * 18
        for i, msg in ipairs(LOG) do
            love.graphics.setColor(0, 0, 0, 0.5 * alpha)
            love.graphics.rectangle("fill", 0, logY + (i - 1) * 18, font:getWidth(msg) + 8, 18)
            love.graphics.setColor(1, 1, 0.5, alpha)
            love.graphics.print(msg, 4, logY + (i - 1) * 18)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.pop()
end

return devcmd
