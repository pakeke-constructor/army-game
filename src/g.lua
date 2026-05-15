

---@class g.BlessingInfo
---@field id string
---@field image string
---@field startingData any?
---@field resetDataOnBattleStart boolean?
---@field description string
---@field name string
---@field rarity g.Rarity
---@field mana g.ManaType?
---@field handlers table<string, function>


---@class g.PerkInfo
---@field id string
---@field description string
---@field image string
---@field handlers table<string, fun(ent: ecs.Entity, ...): any> Scoped to the entity. Only fires when the event/question is dispatched AT this entity (eg g.call("onHit", ent)). Cheap; default choice.
---@field rawHandlers table<string, fun(ent: ecs.Entity, ...): any>? Scene-level. Fires for EVERY dispatch of that event globally, regardless of target. Use when the perk needs to listen to things happening elsewhere (eg "when any ally is hurt"). More expensive; use only when `handlers` can't express it.


---@class g.RarityWeights
---@field COMMON number
---@field UNCOMMON number
---@field RARE number
---@field LEGENDARY number


---@class g
local g = {}

local AutoAtlas = require("lib.AutoAtlas.AutoAtlas")

local atlas = AutoAtlas(2048, 2048)

local nameToQuad = {}

local richtext = require("src.modules.richtext.exports")

local sceneManager = require("src.scenes.sceneManager")

local Run = require("src.Run")
local Squad = require("src.Squad")
local Entity = require("src.ecs.Entity")

local bgm = require("src.sound.bgm")
local sfx = require("src.sound.sfx")



local postLoadCallbacks = {}

function g.postLoad(func)
    table.insert(postLoadCallbacks, func)
end

function g._runPostLoad()
    for _, func in ipairs(postLoadCallbacks) do
        func()
    end
    postLoadCallbacks = {}
end



---@class g.CommanderInfo
---@field id string
---@field name string
---@field description string
---@field image string
---@field startMana g.ManaBundle
---@field onStart (fun(run: g.Run))?

local COMMANDERS = {}
local COMMANDER_LIST = {}

---@param id string
---@param name string
---@param info g.CommanderInfo|{id:nil}|{name:nil}
function g.defineCommander(id, name, info)
    assert(not COMMANDERS[id], "Duplicate commander: " .. id)
    info.name = loc(name, {}, {
        context = "The name of a commander"
    })
    info.id = id
    assert(info.image,"commanders need images")
    COMMANDERS[id] = info
    COMMANDER_LIST[#COMMANDER_LIST + 1] = id
end

---@return g.CommanderInfo
function g.getCommanderInfo(id)
    return assert(COMMANDERS[id], "Unknown commander: " .. tostring(id))
end

---@return string[]
function g.getCommanderList()
    return COMMANDER_LIST
end




local currentRun

---@class g.LaunchOptions
---@field commander string
---@field difficulty integer

---@param lopt g.LaunchOptions
function g.newRun(lopt)
    currentRun = Run()

    lopt = lopt or {
        commander = consts.STARTING_COMMANDER,
        difficulty = 0
    }

    currentRun.commander = lopt.commander
    currentRun.difficulty = lopt.difficulty

    local cmdInfo = g.getCommanderInfo(lopt.commander)
    if cmdInfo.startMana then
        for manaType, count in pairs(cmdInfo.startMana) do
            for _ = 1, count do
                g.addPermanentMana(manaType)
            end
        end
    end
    if cmdInfo.onStart then
        cmdInfo.onStart(currentRun)
    end

    return currentRun
end



function g.newTestRun()
    assert(consts.DEV_MODE)

    g.newRun({
        commander = "sir_horse",
        difficulty = 0
    })

    if consts.DEV_MODE then
        -- populate test stuff.
        currentRun.blessings = {
            iron_hide = true, golden_coffers = true, blood_tithe = true, barrage = true,
        }
        currentRun.money = 1000
    end

end


function g.iteratePartition(partitionId, x, y, fn, range)
    local ecs = g.getECS()
    ecs:iteratePartition(partitionId, x, y, fn, range)
end

---@param x number
---@param y number
---@param damage number
---@param radius number?
---@param fromEntity ecs.Entity?
function g.explosion(x, y, damage, radius, fromEntity)
    radius = radius or 60
    local radiusSq = radius * radius
    -- todo: make particles here
    g.iteratePartition("unit", x, y, function(ent)
        local dx = ent.x - x
        local dy = ent.y - y
        if dx * dx + dy * dy <= radiusSq and (not fromEntity or ent.team ~= fromEntity.team) then
            g.knockback(ent, x, y, 200)
            g.dealDamage(ent, damage)
        end
    end, radius)
end


function g.hasRun()
    return currentRun ~= nil
end

---@return g.Run
function g.getRun()
    return assert(currentRun, "run not loaded")
end

local currentECS
---@return ecs.ECSWorld
function g.getECS()
    return assert(currentECS, "ecs not active")
end

---@param ecs ecs.ECSWorld
function g.setCurrentECS(ecs)
    currentECS = ecs
end

---@param amount number
function g.addGold(amount)
    local run = g.getRun()
    run.money = run.money + amount
end

---@param amount number
---@return boolean
function g.canAffordGold(amount)
    return g.getRun().money >= amount
end

---@param amount number
---@return boolean
function g.trySpendGold(amount)
    if not g.canAffordGold(amount) then
        return false
    end
    local run = g.getRun()
    run.money = run.money - amount
    return true
end

---@param amount number
function g.addXP(amount)
    local run = g.getRun()
    run.xp = run.xp + amount
end

function g.delRun()
    currentRun = nil
end

function g.saveRun()
    if not currentRun or not currentRun.serialize then
        return
    end
    local data = currentRun:serialize()
    local contents = json.encode(data)
    love.filesystem.write("saves/run1.json", contents)
end

function g.loadRun(path)
    local contents = assert(love.filesystem.read(path))
    local data = json.decode(contents)
    currentRun = Run.deserialize(data)
end

function g.saveAndInvalidateRun()
    if not currentRun or not currentRun.serialize then
        return
    end
    g.saveRun()
    g.delRun()
end


---@return love.Texture
function g.getAtlas()
    return atlas:getTexture()
end

---@param imageName string
function g.getImageQuad(imageName)
    local quad = nameToQuad[imageName]
    if not quad then
        error("Invalid quad: " .. tostring(imageName))
    end
    return quad
end


---@param imageName string
---@return number w
---@return number h
function g.getImageSize(imageName)
    local quad = g.getImageQuad(imageName)
    local _, _, w, h = quad:getViewport()
    return w, h
end

---@param imageName any
---@return boolean
function g.isImage(imageName)
    return (nameToQuad[imageName] and true) or false
end

---@param imageName string|love.Quad
---@param x number
---@param y number
---@param r number?
---@param sx number?
---@param sy number?
---@param kx number?
---@param ky number?
function g.drawImage(imageName, x, y, r, sx, sy, kx, ky)
    return g.drawImageOffset(imageName, x, y, r, sx, sy, 0.5, 0.5, kx, ky)
end

---@param manaCell g.ManaCell
---@param x number
---@param y number
---@param r number?
---@param sx number?
---@param sy number?
---@param kx number?
---@param ky number?
function g.drawManaCell(manaCell, x, y, r, sx, sy, kx, ky)
    local quadName
    if manaCell == g.WILDCARD_MANA then
        quadName = "white_mana"
    end

    quadName = quadName or manaCell .. "_mana"
    if not nameToQuad[quadName] then
        -- just render red for now, simple
        log.error("unknown manaCell type", manaCell)
        quadName = "red_mana"
    end
    return g.drawImage(quadName, x, y, r, sx, sy, kx, ky)
end



---@param imageName string|love.Quad
---@param x number
---@param y number
---@param r number?
---@param sx number?
---@param sy number?
---@param ox number?
---@param oy number?
---@param kx number?
---@param ky number?
function g.drawImageOffset(imageName, x, y, r, sx, sy, ox, oy, kx, ky)
    local quad
    if type(imageName) == "string" then
        quad = g.getImageQuad(imageName)
    else
        if not (imageName.typeOf and imageName:typeOf("Quad")) then
            error("Expected quad, got: " .. type(imageName) .. " " .. tostring(imageName))
        end
        quad = imageName
    end
    local _,_,w,h = quad:getViewport()
    atlas:draw(quad, x, y, r, sx, sy, (ox or 0.5) * w, (oy or 0.5) * h, kx, ky)
end

---@param imageName string
---@param x number
---@param y number
---@param w number
---@param h number
---@param rot number?
function g.drawImageContained(imageName, x, y, w, h, rot)
    local quad = g.getImageQuad(imageName)
    local _,_,qw,qh = quad:getViewport()
    local scaleX = w / qw
    local scaleY = h / qh
    local scale = math.min(scaleX, scaleY)
    local scaledW = qw * scale
    local scaledH = qh * scale
    local centerX = x + (w - scaledW) / 2
    local centerY = y + (h - scaledH) / 2
    atlas:draw(quad, centerX + scaledW/2, centerY + scaledH/2, rot or 0, scale, scale, qw/2, qh/2)
end



---@param bundle g.ManaBundle
function g.getManaBundleColor(bundle)
    for _,mc in ipairs(g.getManaTypelist()) do
        if bundle[mc] then
            local minfo = g.getManaInfo(mc)
            return minfo.color
        end
    end
    return objects.Color.WHITE
end


---@param squadId string
---@param x number
---@param y number
---@param drawManaCost boolean?
---@param drawLevel integer?
function g.drawSquadIcon(squadId, x, y, drawManaCost, drawLevel)
    local info = g.getSquadInfo(squadId)
    --local rarityColor = (info.rarity or g.RARITIES.COMMON).color
    local col = g.getManaBundleColor(info.cost)
    local c = gsman.mulColor(1, 1, 1)
    g.drawImage(info.icon, x, y)
    c:pop()
    c = gsman.mulColor(col)
    g.drawImage("squadicon_border", x, y)
    c:pop()

    local size = 32 -- hacky hardcode
    if drawManaCost then
        g.drawManaCost(info.cost, x,y-size/2, size + 6)
    end
    if drawLevel then
        -- draw level:
        local lvReg = Kirigami(x, y+2, size/2-4, size/2-4)
        local font = g.getSmallFont(16)
        lg.setColor(0.6,0.6,0.6,0.6)
        richtext.printRichContainedNoWrap("Lv "..tostring(drawLevel), font, lvReg:get())
    end
end



---@param blessingId string
---@param x number
---@param y number
function g.drawBlessingIcon(blessingId, x, y)
    local binfo = g.getBlessingInfo(blessingId)
    local rarityColor = (binfo.rarity or g.RARITIES.COMMON)
    x = math.floor(x)
    y = math.floor(y)

    local img = "blessingborder_white_middle"
    local w,h = g.getImageSize(img)
    helper.gradientRectStencil("vertical", objects.Color.WHITE, rarityColor.color, x-w/2,y-h/2,w,h, function()
        g.drawImage(img, x,y)
    end)
    lg.setColor(1,1,1)
    g.drawImage("blessingborder_white_outline", x,y)

    -- draw blessing icon
    -- Constrain both of them to the 
    lg.setColor(1,1,1)
    g.drawImage(binfo.image, x,y)
end




---@param path string
---@param func fun(path: string)
function g.walkDirectory(path, func)
    local info = love.filesystem.getInfo(path)
    if not info then return end

    if info.type == "file" then
        func(path)
    elseif info.type == "directory" then
        local dirItems = love.filesystem.getDirectoryItems(path)
        for _, pth in ipairs(dirItems) do
            g.walkDirectory(path .. "/" .. pth, func)
        end
    end
end

local validImgExtensions = {
    [".png"] = true,
    [".jpg"] = true,
}

local function loadImage(path)
    local ext = path:sub(-4):lower()
    if validImgExtensions[ext] then
        local name = path:match("([^/]+)%.%w+$")
        local quad = atlas:add(love.image.newImageData(path))
        if nameToQuad[name] then
            error("Duplicate image: " .. name)
        end
        nameToQuad[name] = quad
        if richtext and richtext.defineImage then
            pcall(richtext.defineImage, name, atlas:getTexture(), quad)
        end
    end
end

function g.loadImagesFrom(path)
    g.walkDirectory(path, loadImage)
end


-- Define 1x1 white image
do
    -- Add padding around to prevent bleeding
    local id = love.image.newImageData(3, 3, "rgba8")
    id:mapPixel(function() return 1, 1, 1, 0 end) -- fill transparent white
    id:setPixel(1, 1, 1, 1, 1, 1) -- set middle pixel
    local q = assert(atlas:add(id))
    local x, y = q:getViewport()
    -- Now define it to be 1x1 instead of 3x3
    q:setViewport(x + 1, y + 1, 1, 1, g.getAtlas():getDimensions())
    nameToQuad["1x1"] = q
end




-- g.playWorldSound
-- g.playUISound
do

----------
-- SFXs --
----------

---@param soundname string
---@param pitch number? (defaults to 1)
---@param volume number? (defaults to 1)
---@param pitchVar number? (pitch variance, default 0)
---@param volumeVar number? (volume variance, default 0)
function g.playWorldSound(soundname, pitch, volume, pitchVar, volumeVar)
    if love.audio.getActiveSourceCount() > consts.MAX_PLAYING_SOURCES then
        return false
    end
    if select(2, sceneManager.getCurrentScene()) == "harvest_scene" then
        return sfx.play(soundname, pitch, volume, pitchVar, volumeVar)
    end
    return false
end


---@param soundname string
---@param pitch number? (defaults to 1)
---@param volume number? (defaults to 1)
---@param pitchVar number? (pitch variance, default 0)
---@param volumeVar number? (volume variance, default 0)
function g.playUISound(soundname, pitch, volume, pitchVar, volumeVar)
    return sfx.play(soundname, pitch, volume, pitchVar, volumeVar)
end


local validExtensions = {
    wav = true,
    mp3 = true,
    ogg = true,
    flac = true
}

---@param path string
local function loadSound(path)
    local pathrev = path:reverse()
    local ext = pathrev:sub(1, (pathrev:find(".", 1, true) or 1) - 1):reverse():lower()

    if validExtensions[ext] then
        local basename = pathrev:sub(1, pathrev:find("/", 1, true)-1):reverse()

        if #basename > 0 then
            local name = basename:sub(1, -#ext - 2)
            if name:sub(1,1) ~= "_" then
                sfx.defineSound(name, path)
            end
        end
    end
end

g.walkDirectory("assets/sfx", loadSound)


----------
-- BGMs --
----------

-- Higher number means higher priority.
g.BGMID = {
    TITLE = 999, -- Title and settings
    MAP = 1, -- Map scene
    AMBIENT = 2, -- Harvest scene / Upgrade scene
    CUSTOMIZATION = 3, -- Customization scene
    BOSS = 100, -- Boss theme
}


---@param path string
---@param prio integer
---@param isAmbient boolean?
local function registerBGMFromDirectories(path, prio, isAmbient)
    ---@type string[]
    local files = {}

    g.walkDirectory(path, function(filename)
        local pathrev = filename:reverse()
        local ext = pathrev:sub(1, (pathrev:find(".", 1, true) or 1) - 1):reverse():lower()

        if validExtensions[ext] then
            local basename = pathrev:sub(1, pathrev:find("/", 1, true)-1):reverse()

            if #basename > 0 then
                local name = basename:sub(1, -#ext - 2)
                if name:sub(1,1) ~= "_" then
                    files[#files+1] = filename
                end
            end
        end
    end)

    if #files == 0 then
        error("no bgm files in "..path)
    end

    return bgm.register(prio, files, isAmbient)
end

-- We cannot use g.walkDirectory because we need all the files first then register
-- the BGM in one go using `bgm.register`.
--[[
registerBGMFromDirectories("assets/bgm/boss", g.BGMID.BOSS, false)
registerBGMFromDirectories("assets/bgm/customization", g.BGMID.CUSTOMIZATION, true)
registerBGMFromDirectories("assets/bgm/ambient", g.BGMID.AMBIENT, true)
registerBGMFromDirectories("assets/bgm/map", g.BGMID.MAP, true)
registerBGMFromDirectories("assets/bgm/ambient", g.BGMID.TITLE, true)
]]


---Request playing specific BGM ID
---@param id integer BGM ID. Use `g.BGMID` for the fixed constants.
function g.requestBGM(id)
    return bgm.request(id)
end


end





-- Forward-declare perk tables (used by both squad and perk systems below)
local PERK_DEFS = {}
local PERK_LIST = {}

-- Squad system
local SQUAD_DEFS = {}
local SQUAD_LIST = {}

-- entity type defs
local ENTITY_DEFS = {}
local ENTITY_LIST = {}
local currentEntityId = 0


---@class g.SquadInfo
---@field id string
---@field entityId string
---@field entityDef table
---@field rarity g.Rarity
---@field unitCount integer
---@field statUpgradeScaling table<string, number> { [statName] -> number }
---@field unitCountUpgradeScaling integer?
---@field name string
---@field icon string
---@field perks string[]
---@field cost g.ManaBundle
---@field onDeploySquad (fun(squad: g.SquadInfo, entities: ecs.Entity[], x: number, y:number))?
---@field drawSquadHover fun(x:number, y:number)?



---@param id string
---@param info g.SquadInfo|{id:nil}|{perks:nil}
function g.defineSquad(id, info)
    assert(not SQUAD_DEFS[id], "Duplicate squad: " .. id)
    info.id = id
    info.perks = info.perks or {}
    info.unitCount = info.unitCount or 1
    info.name = assert(info.name)
    info.rarity = assert(info.rarity)
    info.unitCountUpgradeScaling = info.unitCountUpgradeScaling or 0
    info.statUpgradeScaling = info.statUpgradeScaling or {}
    info.entityId = info.entityId or (id .. "_unit")
    assert(info.entityDef, "Missing entityDef for squad: " .. id)
    if not ENTITY_DEFS[info.entityId] then
        g.defineEntity(info.entityId, info.entityDef)
    end
    assert(type(info.unitCountUpgradeScaling) == "number")
    for stat,scaling in pairs(info.statUpgradeScaling)do
        assert(g.getStatInfo(stat), "?")
        assert(scaling < 1, "Per-level stat scaling shouldn't be more than 100%. Must be number between (0,1)")
    end
    assert(info.icon)
    SQUAD_DEFS[id] = info
    SQUAD_LIST[#SQUAD_LIST + 1] = id
end


---@param squadId string
---@return g.Squad
function g.newSquad(squadId)
    local def = assert(SQUAD_DEFS[squadId], "Unknown squad: " .. tostring(squadId))
    return Squad(squadId, def)
end

---@param squadId string
function g.addSquadToArmy(squadId)
    local run = g.getRun()
    assert(not run.squads[squadId], "Squad already in army: " .. squadId)
    run.squads[squadId] = g.newSquad(squadId)
    run._sortedSquads = nil
end

---@param squadId string
function g.addOrUpgradeSquad(squadId)
    local run = g.getRun()
    local squad = run.squads[squadId]
    if squad then
        squad.level = squad.level + 1
    else
        run.squads[squadId] = g.newSquad(squadId)
        run._sortedSquads = nil
    end
end

---@param squad g.Squad
---@return boolean
function g.removeSquadFromArmy(squad)
    local run = g.getRun()
    if run.squads[squad.squadId] then
        run.squads[squad.squadId] = nil
        run._sortedSquads = nil
        return true
    end
    return false
end

---@param squadId string
---@return g.Squad?
function g.getSquadFromArmy(squadId)
    return g.getRun().squads[squadId]
end

---@return g.Squad[]
function g.getSortedArmyList()
    local run = g.getRun()
    if run._sortedSquads then
        return run._sortedSquads
    end
    local list = {}
    for _, sq in pairs(run.squads) do
        list[#list + 1] = sq
    end
    table.sort(list, function(a, b) return a.squadId < b.squadId end)
    run._sortedSquads = list
    return list
end



---@param id string
---@return g.SquadInfo
function g.getSquadInfo(id)
    return assert(SQUAD_DEFS[id], "Unknown squad: " .. tostring(id))
end

---@return string[]
function g.getSquadList()
    return SQUAD_LIST
end

---returns all squad ids whose mana cost can be satisfied by the given mana cells (excluding wildcard)
---@param manaCells g.ManaCounts
---@return string[]
function g.getSquadsByMana(manaCells)
    local available = {}
    for cell, count in pairs(manaCells or {}) do
        if cell ~= g.WILDCARD_MANA and (count or 0) > 0 then
            available[cell] = true
        end
    end
    ---@type g.SquadInfo[]
    local result = {}
    for _, squadId in ipairs(SQUAD_LIST) do
        local info = SQUAD_DEFS[squadId]
        local ok = true
        for manaType, _ in pairs(info.cost) do
            if not available[manaType] then
                ok = false
                break
            end
        end
        if ok then
            result[#result + 1] = squadId
        end
    end
    return result
end

---@param squad g.Squad
---@param perkId string
function g.addPerkToSquad(squad, perkId)
    assert(PERK_DEFS[perkId], "Unknown perk: " .. tostring(perkId))
    squad.perks[#squad.perks + 1] = perkId
end

---@param squad g.Squad
---@param perkId string
---@return boolean
function g.removePerkFromSquad(squad, perkId)
    for i = #squad.perks, 1, -1 do
        if squad.perks[i] == perkId then
            table.remove(squad.perks, i)
            return true
        end
    end
    return false
end

---@param squad g.Squad
---@param x number
---@param y number
---@return ecs.Entity[]
function g.spawnSquad(squad, x, y, ...)
    local info = assert(SQUAD_DEFS[squad.squadId], "Unknown squad: " .. tostring(squad.squadId))
    local squadScope = g.newScope()
    squadScope.shared = true
    for j = 1, #squad.perks do
        local perkInfo = g.getPerkInfo(squad.perks[j])
        squadScope:addHandler(perkInfo.handlers)
    end
    local offsets = squad:getFormationOffsets()
    local entities = {}
    for i = 1, #offsets do
        local ent = g.spawnEntity(info.entityId, x + offsets[i].x, y + offsets[i].y, ...)
        ent.scope = squadScope
        ent.squad = squad
        entities[i] = ent
    end
    if info.onDeploySquad then
        info.onDeploySquad(info, entities)
    end
    return entities
end


-- Blessing system
local BLESSING_DEFS = {}
local BLESSING_LIST = {}

---@param id string
---@param name string
---@param info g.BlessingInfo|{id:nil,name:nil}
function g.defineBlessing(id, name, info)
    assert(not BLESSING_DEFS[id], "Duplicate blessing: " .. id)
    info.name = loc(name, {}, {
        context = "The name of a blessing"
    })
    info.id = id
    BLESSING_DEFS[id] = info
    BLESSING_LIST[#BLESSING_LIST + 1] = id
end

---@return g.BlessingInfo
function g.getBlessingInfo(id)
    return assert(BLESSING_DEFS[id], "Unknown blessing: " .. tostring(id))
end

function g.getBlessingList()
    return BLESSING_LIST
end

---returns all blessing ids available for the given mana cells (excluding wildcard)
---blessings with no mana field are always included
---@param manaCells g.ManaCounts
---@return string[]
function g.getBlessingsByMana(manaCells)
    local available = {}
    for cell, count in pairs(manaCells or {}) do
        if cell ~= g.WILDCARD_MANA and (count or 0) > 0 then
            available[cell] = true
        end
    end
    local result = {}
    for _, blessingId in ipairs(BLESSING_LIST) do
        local info = BLESSING_DEFS[blessingId]
        if not info.mana or available[info.mana] then
            result[#result + 1] = blessingId
        end
    end
    return result
end

---@param id string
function g.addBlessing(id)
    local info = assert(BLESSING_DEFS[id], "Unknown blessing: " .. tostring(id))
    local run = g.getRun()
    local d = info.startingData
    if d == nil then d = true end
    if not run.blessings[id] then
        run.blessings[id] = d
        g.call("blessingAdded", id)
    end
end

---@param id string
function g.removeBlessing(id)
    local run = g.getRun()
    if run.blessings[id] ~= nil then
        run.blessings[id] = nil
        return true
    end
    return false
end

---@param id string
function g.getBlessingData(id)
    local run = g.getRun()
    return run.blessings[id]
end

---@param id string
---@param val any
function g.setBlessingData(id, val)
    local run = g.getRun()
    assert(run.blessings[id] ~= nil, "Blessing not present: " .. tostring(id))
    if val == nil then val = false end
    run.blessings[id] = val
end


---@param ent ecs.Entity
local function getWrappedEntityPerkHandler(ent)
    if ent.__cachedPerkHandler then
        return ent.__cachedPerkHandler
    end
    if ent.__cachedPerkHandler == false then
        -- false indicates no rawHandlers on perks.
        return nil
    end

    local squad = assert(ent.squad)
    local __cachedPerkHandler = nil
    for _, perk in ipairs(squad.perks) do
        local pinfo = g.getPerkInfo(perk)
        if pinfo.rawHandlers then
            __cachedPerkHandler = __cachedPerkHandler or {}
            for k,func in pairs(pinfo.rawHandlers) do
                __cachedPerkHandler[k] = function(...)
                    func(ent, ...)
                end
            end
        end
    end
    if not __cachedPerkHandler then
        ent.__cachedPerkHandler = false -- dont run this again.
    else
        ent.__cachedPerkHandler = __cachedPerkHandler
    end
    return ent.__cachedPerkHandler
end


function g.addBlessingAndEntityHandlers()
    if not g.hasRun() then return end
    local run = g.getRun()
    for id, _ in pairs(run.blessings) do
        local info = BLESSING_DEFS[id]
        if info and info.handlers then
            g.addHandler(info.handlers)
        end
    end
    local ecs = g.getECS()
    for _, ent in ecs:iterate("squad") do
        ---@cast ent ecs.Entity
        -- HACK: only entities with squads can add raw handlers.
        local cachedHandler = getWrappedEntityPerkHandler(ent)
        if cachedHandler then
            g.addHandler(cachedHandler)
        end
    end
end


-- Perk system

--- Define a perk. Two handler tables:
--- `handlers`: per-entity. Fires only when dispatched AT this entity, e.g. g.call(event, ent). Cheap; default.
--- `rawHandlers`: scene-level. Fires on EVERY global dispatch. Entity passed as 1st arg:
---   rawHandlers.onAllyHurt = function(selfEnt, ally, dmg) ... end
--- Use rawHandlers when listening to things not happening to the entity itself.
---@param id string
---@param name string
---@param info g.PerkInfo|{id:nil,name:nil}
function g.definePerk(id, name, info)
    assert(not PERK_DEFS[id], "Duplicate perk: " .. id)
    info.name = loc(name, {}, {
        context = "The name of a perk"
    })
    info.id = id
    PERK_DEFS[id] = info
    PERK_LIST[#PERK_LIST + 1] = id
end

function g.getPerkInfo(id)
    return assert(PERK_DEFS[id], "Unknown perk: " .. tostring(id))
end

function g.getPerkList()
    return PERK_LIST
end

--- Add a custom effect (handler) to an entity. Promotes shared scopes so it only affects this entity.
--- If `tag` is given, the effect is "tagged": re-adding with same tag overwrites the previous one (no stacking).
---@param ent table
---@param handler table
---@param duration number?
---@param tag any?
function g.addCustomEffect(ent, handler, duration, tag)
    if not ent.scope then
        ent.scope = g.newScope()
    elseif ent.scope.shared then
        ent.scope = g.newScope(ent.scope)
    end
    ent.scope:addHandler(handler, duration, tag)
end



function g.defineEntity(id, def)
    assert(not ENTITY_DEFS[id], "Duplicate entity type: " .. id)
    assert(def.x == nil and def.y == nil and def.type == nil and def._world == nil, "x/y/type/_world are reserved")
    for k in pairs(Entity) do
        assert(def[k] == nil, "Entity def '" .. id .. "' cannot override base method: " .. k)
    end
    def.type = id
    def.image = def.image or id
    for k, v in pairs(Entity) do
        def[k] = v
    end
    if def.baseHealPower and def.baseHealPower > 0 then
        assert(not def.baseAttackDamage or def.baseAttackDamage <= 0, "Entities cannot be healers AND attackers at same time")
    end
    local mt = {__index = def}
    ENTITY_DEFS[id] = mt
    ENTITY_LIST[#ENTITY_LIST + 1] = id
end


---@param id string
---@param x number
---@param y number
---@param ... unknown
---@return ecs.Entity
function g.spawnEntity(id, x, y, ...)
    local mt = ENTITY_DEFS[id]
    assert(mt, "Unknown entity type: " .. tostring(id))
    local ecs = g.getECS()
    assert(ecs, "g.spawnEntity called when ECS isnt active")
    currentEntityId = currentEntityId + 1
    local ent = setmetatable({
        id = currentEntityId,
        x = x, y = y, type = id,
        _world = ecs,
    }, mt)
    if ent.init then
        ent:init(...)
    end
    ecs:addEntity(ent)
    g.call("entitySpawned", ent)
    if ent.startingArmor then
        g.addArmor(ent, ent.startingArmor)
    end
    return ent
end

function g.isAlive(ent)
    -- todo: check if inside ECS too
    return not ent.___removed
end

---@param ent ecs.Entity
---@param duration number
---@param source ecs.Entity?
---@return boolean applied
function g.applyBurn(ent, duration, source)
    local wasActive = ent.burnTime and ent.burnTime > 0
    ent.burnTime = (ent.burnTime or 0) + duration
    if not wasActive then
        g.call("statusEffectApplied", ent, "burn", duration, source)
        return true
    end
    return false
end

---@param ent ecs.Entity
---@param amount number
---@param source ecs.Entity?
---@return boolean applied
function g.applyPoison(ent, amount, source)
    ent.poisonAmount = (ent.poisonAmount or 0) + amount
    -- poison if always applied, since it stacks
    if amount > 0 then
        g.call("statusEffectApplied", ent, "poison", 0xffffff, source)
        return true
    end
    return false
end

---@param ent ecs.Entity
---@param duration number
---@param source ecs.Entity?
---@return boolean applied
function g.applyFrozen(ent, duration, source)
    local wasActive = ent.frozenTime and ent.frozenTime > 0
    ent.frozenTime = (ent.frozenTime or 0) + duration
    if not wasActive then
        g.call("statusEffectApplied", ent, "frozen", duration, source)
        return true
    end
    return false
end

---@param victimEnt ecs.Entity Entity that gets taunted.
---@param tauntingEnt ecs.Entity Entity the victim should target/move toward.
---@param duration number?
function g.applyTaunt(victimEnt, tauntingEnt, duration)
    local wasActive = victimEnt.taunt and victimEnt.taunt.duration and victimEnt.taunt.duration > 0
    victimEnt.taunt = {
        ent = tauntingEnt,
        duration = duration or 3,
    }
    if not wasActive then
        g.call("statusEffectApplied", victimEnt, "taunt", duration or 3, tauntingEnt)
    end
end

---@param victimEnt ecs.Entity Entity that gets feared.
---@param fearEnt ecs.Entity? Entity the victim should run away from.
---@param duration number?
function g.applyFear(victimEnt, fearEnt, duration)
    local wasActive = victimEnt.fear and victimEnt.fear.duration and victimEnt.fear.duration > 0
    victimEnt.fear = {
        ent = fearEnt,
        duration = duration or 3,
    }
    if not wasActive then
        g.call("statusEffectApplied", victimEnt, "fear", duration or 3, fearEnt)
    end
end

---@param ent ecs.Entity
---@param healAmount number
---@param healerEnt ecs.Entity?
function g.healEntity(ent, healAmount, healerEnt)
    if not g.isAlive(ent) then return end

    local oldHealth = ent.health
    ent.health = math.min(ent.maxHealth, ent.health + healAmount)
    local finalHeal = ent.health - oldHealth

    if finalHeal > 0 then
        g.call("entityHealed", ent, finalHeal, healerEnt)
        g.call("onHitHeal", healerEnt, finalHeal, ent)
    end
end

---@param target ecs.Entity
---@param damage number
---@param attacker ecs.Entity?
---@param ignoreQuestionBuses boolean?
function g.dealDamage(target, damage, attacker, ignoreQuestionBuses)
    if not g.isAlive(target) then return end

    if not ignoreQuestionBuses and target.armor then
        if attacker then
            g.call("onHitDamage", attacker, damage, target)
        end
        g.removeArmor(target, 1)
        return
    end

    local reduction = ignoreQuestionBuses and 0 or g.ask("getDamageReduction", target)
    local finalDmg = math.max(0, damage - reduction)

    target._damageLagAmount = (target._damageLagAmount or 0) + finalDmg

    target.health = target.health - finalDmg
    target._timeSinceDamaged = 0

    if attacker then
        g.call("onHitDamage", attacker, damage, target)
    end
    g.call("entityHurt", target, damage)

    if attacker and attacker.lifesteal then
        g.healEntity(attacker, damage * attacker.lifesteal, attacker)
    end

    if target.health <= 0 then
        g.killEntity(target, attacker)
    end
end

---@param ent ecs.Entity
---@param amount number
function g.addArmor(ent, amount)
    if amount <= 0 then return end
    ent.armor = (ent.armor or 0) + amount
    g.call("armorIncreased", ent, amount)
end

---@param ent ecs.Entity
---@param count number
function g.removeArmor(ent, count)
    if count <= 0 then return end
    local cur = ent.armor or 0
    local removed = math.min(cur, count)
    if removed <= 0 then return end
    local newArmor = cur - removed
    ent.armor = newArmor > 0 and newArmor or nil
    ent._timeSinceLostArmor = 0
    g.call("armorDecreased", ent, removed)
end

---@param ent ecs.Entity
---@param killer ecs.Entity?
function g.killEntity(ent, killer)
    if not g.isAlive(ent) then return end
    ent.health = 0
    g.call("entityDeath", ent, killer)
    if killer then
        g.call("onKill", killer, ent)
    end
    ent:getWorld():removeEntity(ent)
end

function g.setPos(ent, x, y)
    ent.x = x
    ent.y = y
    if ent.physics then
        local world = ent:getWorld()
        if world then
            local body = world.data.physicsBodies[ent]
            if body then
                body:setPosition(x + ent.physics.ox, y + ent.physics.oy)
            end
        end
    end
end


---@param ent ecs.Entity
---@param x number
---@param y number
---@param strength number?
function g.knockback(ent, x, y, strength)
    local dx, dy = ent.x - x, ent.y - y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 0.001 then dx, dy = 0, -1; dist = 1 end
    ent._knockVx = (ent._knockVx or 0) + dx / dist * strength
    ent._knockVy = (ent._knockVy or 0) + dy / dist * strength
end

function g.getVel(ent)
    return (ent.vx or 0) + (ent._knockVx or 0),
           (ent.vy or 0) + (ent._knockVy or 0)
end



local function drawIceCube(ent, x, y, sx,sy)
    local W,H,_ = 16,16,nil
    local quad = g.getImageQuad(ent.image)
    _,_,W,H = quad:getViewport()
    W = W+10
    H = H+10
    lg.setColor(1,1,1,0.5)
    g.drawImageContained("ice_cube", x-W/2, y-H/2, W,H)
end

---@param ent ecs.Entity
---@param x number
---@param y number
local function drawHealthBar(ent, x,y)
    if not ent.maxHealth then return end
    local w, h = 16, 2
    local frac = ent.health / ent.maxHealth
    -- black outline
    local out=2
    local oy=2
    lg.setColor(0, 0, 0)
    lg.rectangle("fill", x - w/2 - out, y + oy - out, w + out*2, h + out*2)

    local lagFrac = helper.clamp((ent.health + (ent._damageLagAmount or 0)) / ent.maxHealth, 0, 1)
    -- white lagged
    lg.setColor(1, 1, 1)
    lg.rectangle("fill", x - w/2, y + oy, w * lagFrac, h)
    -- red health
    lg.setColor(1, 0, 0)
    lg.rectangle("fill", x - w/2, y + oy, w * frac, h)

    -- status effect tip segments (drawn right-to-left from tip)
    local pxPerHp = w / ent.maxHealth
    local right = x - w/2 + w * frac
    local remaining = ent.health
    local function drawTip(hp, color)
        hp = math.min(hp, remaining)
        if hp <= 0 then return end
        lg.setColor(color)
        lg.rectangle("fill", right - hp * pxPerHp, y + oy, hp * pxPerHp, h)
        right = right - hp * pxPerHp
        remaining = remaining - hp
    end
    drawTip(5 * (ent.poisonAmount or 0), g.COLORS.POISON)
    drawTip((ent.burnTime or 0) * consts.BURN_DPS, g.COLORS.BURN)

    if ent.armor then
        local FLASH_DUR = 0.15
        local armorFlash = math.max(0, FLASH_DUR - (ent._timeSinceLostArmor or 0xfff))/FLASH_DUR
        local armorH = 6
        local armorY = y + h + oy
        local ratio = math.min(1,(ent.armor)/6)
        lg.setColor(0,0,0)
        lg.rectangle("fill", x-w/2, armorY, w*ratio, armorH)
        local pad=2
        lg.setColor(0.5,0.5,0.5)
        lg.rectangle("fill", x-w/2 + pad, armorY + pad, ratio*(w-pad*2), armorH-pad*2)
        if armorFlash then
            lg.setColor(1,1,1, armorFlash)
            lg.rectangle("fill", x-w/2, armorY, w*ratio, armorH)
        end
        lg.setColor(1,1,1)
        g.drawImage("armor_healthbar_icon", x-w/2 - 2, armorY + 2)
        if armorFlash > 0 then
            lg.setColor(1,1,1, armorFlash)
            g.drawImage("armor_healthbar_icon_white", x-w/2 - 2, armorY + 2)
        end
    end
end

function g.drawEntity(ent, x, y)
    local entScale = g.ask("getEntityScale", ent) * (ent.scale or 1)
    local sx, sy = (ent.sx or 1) * (ent.faceDir or 1) * entScale, (ent.sy or 1) * entScale
    if ent.draw then
        ent:draw(x, y)
        return
    end
    if ent.image then
        lg.setColor(ent.color or objects.Color.WHITE)
        g.drawImageOffset(ent.image, x + (ent.ox or 0), y + (ent.oy or 0), ent.rot or 0, sx, sy, 0.5, 0.95, ent.kx, ent.ky)
        if ent.frozenTime and ent.frozenTime > 0 then
            drawIceCube(ent, x,y, sx,sy)
        end
    end
    if ent.health then
        lg.setColor(1,1,1)
        drawHealthBar(ent, x,y)
    end
end



---@param squadId string
function g.getSquadUnitCount(squadId)
    local squad = g.getSquadFromArmy(squadId)
    local info = g.getSquadInfo(squadId)
    if squad then
        local xtra = ((squad.level-1) * info.unitCountUpgradeScaling)
        local xtra2 = g.ask("getSquadUnitCountModifier", squadId)
        return info.unitCount + xtra + xtra2
    end
    return info.unitCount
end


---@param entityId string
---@return number w, number h
function g.getUnitDrawSize(entityId)
    local def = g.getEntityDef(entityId)
    if def and def.image then
        return g.getImageSize(def.image)
    end
    return 10, 10
end

---@param entityId string
---@param x number
---@param y number
---@param maxW number?
---@param maxH number?
function g.drawUnitPreview(entityId, x, y, maxW, maxH)
    local def = g.getEntityDef(entityId)
    if not def or not def.image then return end
    if maxW and maxH then
        g.drawImageContained(def.image, x, y, maxW, maxH)
    else
        g.drawImage(def.image, x, y)
    end
end


---@param id string
---@return table
function g.getEntityDef(id)
    local mt = ENTITY_DEFS[id]
    return mt and mt.__index
end

function g.getEntityList()
    return ENTITY_LIST
end

local suffixes = {
    {1e12, "t"},
    {1e9,  "b"},
    {1e6,  "m"},
    {1e3,  "k"},
}

local bigCache = {}
local smolCache = {}
local fbCache = {}

local function getFallbackFonts(size)
    if not fbCache[size] then
        fbCache[size] = love.graphics.newFont("assets/fonts/unifont-17.0.03.otf", size, "mono", size / 16)
    end
    return fbCache[size]
end

---@param size number
function g.getBigFont(size)
    assert(size % 16 == 0, "Size must by divisible by 16")
    if not bigCache[size] then
        local f = love.graphics.newFont("assets/fonts/Smart 9h.ttf", size, "mono", 1)
        f:setFallbacks(getFallbackFonts(size))
        bigCache[size] = f
    end
    return bigCache[size]
end

---@param size number
function g.getSmallFont(size)
    assert(size % 16 == 0, "Size must by divisible by 16")
    if not smolCache[size] then
        local f = love.graphics.newFont("assets/fonts/Match 7h.ttf", size, "mono", 1)
        f:setFallbacks(getFallbackFonts(size))
        smolCache[size] = f
    end
    return smolCache[size]
end

---@param path string
function g.requireFolder(path)
    local results = {}
    g.walkDirectory(path:gsub("%.", "/"), function(pth)
        if pth:sub(-4, -1) == ".lua" then
            pth = pth:sub(1, -5)
            results[pth] = require(pth:gsub("%/", "."))
        end
    end)
    return results
end

---@param num number
function g.formatNumber(num)
    local isNegative = num < 0
    num = math.abs(num)
    local prefix = (isNegative and "-" or "")

    if num < 1000 then
        if num == math.floor(num) then
            return prefix .. ("%d"):format(num)
        elseif num < 1 then
            return prefix .. ("%.2f"):format(num)
        elseif num < 3 then
            return prefix .. ("%.1f"):format(num)
        end
        return prefix .. tostring(math.floor(num))
    end

    for _, suffix in ipairs(suffixes) do
        if num >= suffix[1] then
            local scaled = num / suffix[1]
            local formatted
            if scaled >= 100 then
                formatted = string.format("%.0f", math.floor(scaled))
            elseif scaled >= 10 then
                formatted = string.format("%.14g", math.floor(scaled * 10) / 10)
            else
                formatted = string.format("%.14g", math.floor(scaled * 100) / 100)
            end
            return prefix .. formatted .. suffix[2]
        end
    end
    return prefix .. tostring(num)
end

function g.gotoScene(sceneName)
    return sceneManager.gotoScene(sceneName)
end

function g.gotoLastScene()
    return sceneManager.gotoLastScene()
end

function g.getCurrentScene()
    return sceneManager.getCurrentScene()
end

function g.screenToWorld(x, y)
    local scene = g.getCurrentScene()
    if scene and scene.camera then
        return scene.camera:toWorld(x, y)
    end
    return x, y
end

function g.worldToScreen(x, y)
    local scene = g.getCurrentScene()
    if scene and scene.camera then
        return scene.camera:toScreen(x, y)
    end
    return x, y
end


function g.getWorldTime()
    -- todo: add a proper counter here; allows for faster game-speed
    return love.timer.getTime()
end


--- @param particleName string
--- @param x number
--- @param y number
--- @param amount integer?
function g.spawnParticle(particleName, x, y, amount)
    local scene, name = g.getCurrentScene()
    if name ~= "battle_scene" or (not scene.particles) then
        return
    end
    return scene.particles:spawnParticles(particleName, x, y, amount)
end


-- Event Bus / Question Bus
local reducers = require("src.modules.reducers")

local definedEvents = {}
local questions = {}

-- global handler caches: name -> {func1, func2, ...}
-- Rebuilt atomically each frame by g.pollHandlers.
local table_clear = require("table.clear")
local handlerCache = {} -- [eventOrQuestionName] -> {func, func, ...}

function g.defineEvent(ev, isGlobalEvent)
    assert(not definedEvents[ev], "Event already defined: " .. ev)
    definedEvents[ev] = true
    handlerCache[ev] = {}
end

function g.isEvent(ev)
    return definedEvents[ev] == true
end

function g.defineQuestion(question, reducer, defaultValue)
    assert(not questions[question], "Question already defined: " .. question)
    questions[question] = {
        reducer = reducer,
        defaultValue = defaultValue,
    }
    handlerCache[question] = {}
end

function g.getQuestionInfo(q)
    return questions[q]
end

local _polling = false

-- Add a handler table for this frame only.
-- Must only be called inside scene:pollHandlers.
function g.addHandler(handler)
    assert(_polling, "g.addHandler called outside of g.pollHandlers!")
    for key, func in pairs(handler) do
        local list = handlerCache[key]
        assert(list, "Unknown event/question: " .. tostring(key))
        list[#list + 1] = func
    end
end

-- Called once per frame. Clears all handlers, then asks the scene to re-register them.
function g.pollHandlers()
    for _, list in pairs(handlerCache) do
        table_clear(list)
    end
    _polling = true
    local sc = sceneManager.getCurrentScene()
    if sc and sc.pollHandlers then
        sc:pollHandlers()
    end
    _polling = false
end


-- Scopes: handler containers on entities for events/questions.
-- (Each scope is a collection of handlers; each Handler is a table containing events/question funcs)
-- Support parent chaining.
-- Squad entities share one scope (shared=true) to avoid duplication.
-- When a buff for a single ent is added, we create a "personal" scope for that entity, 
-- that "inherits" it's old shared scope.
---@class g.Scope: objects.Class
local Scope = objects.Class("g:Scope")

function Scope:init(parent)
    self.parent = parent or nil
    self.shared = false
    self.handlers = {}
    self.expiry = {} -- [handler] -> expire time
    self.tags = {} -- [tag] -> handler
    self.cache = {} -- [eventOrQuestionName] -> {func, func, ...}
    self.lastPrune = 0
end

function Scope:_rebuild()
    local cache = self.cache
    for k in pairs(cache) do
        table_clear(cache[k])
    end
    local now = love.timer.getTime()
    local expiry = self.expiry
    for _, handler in ipairs(self.handlers) do
        if not expiry[handler] or expiry[handler] > now then
            for key, func in pairs(handler) do
                if definedEvents[key] or questions[key] then
                    if not cache[key] then cache[key] = {} end
                    local list = cache[key]
                    list[#list + 1] = func
                end
            end
        end
    end
end

function Scope:_pruneIfNeeded()
    local now = love.timer.getTime()
    if now - self.lastPrune < 0.2 then return end
    self.lastPrune = now
    local dirty = false
    local expiry = self.expiry
    for i = #self.handlers, 1, -1 do
        local h = self.handlers[i]
        if expiry[h] and expiry[h] <= now then
            table.remove(self.handlers, i)
            expiry[h] = nil
            dirty = true
        end
    end
    if dirty then self:_rebuild() end
end

function Scope:addHandler(handler, duration, tag)
    for key in pairs(handler) do
        assert(definedEvents[key] or questions[key], "Unknown event/question: " .. tostring(key))
    end
    if tag then
        local old = self.tags[tag]
        if old then self:removeHandler(old) end
        self.tags[tag] = handler
    end
    if duration then
        self.expiry[handler] = love.timer.getTime() + duration
    end
    self.handlers[#self.handlers + 1] = handler
    self:_rebuild()
end

function Scope:removeHandler(handler)
    for i = #self.handlers, 1, -1 do
        if self.handlers[i] == handler then
            table.remove(self.handlers, i)
            self.expiry[handler] = nil
            self:_rebuild()
            return true
        end
    end
    return false
end

function Scope:call(event, ...)
    self:_pruneIfNeeded()
    local list = self.cache[event]
    if list then
        for i = 1, #list do
            list[i](...)
        end
    end
    if self.parent then
        self.parent:call(event, ...)
    end
end

function Scope:ask(question, ...)
    self:_pruneIfNeeded()
    local t = questions[question]
    if not t then
        error("Invalid question: " .. tostring(question))
    end
    local reducer, val = t.reducer, t.defaultValue
    local list = self.cache[question]
    if list then
        for i = 1, #list do
            val = reducer(val, list[i](...))
        end
    end
    if self.parent then
        val = reducer(val, self.parent:ask(question, ...))
    end
    return val
end


---@return g.Scope
function g.newScope(parent)
    return Scope(parent)
end


-- Fire an event. No return value.
-- Order: global handlers, then ent[ev], then ent.scope
function g.call(ev, arg1, ...)
    -- 1. global handlers (via g.addHandler)
    local list = handlerCache[ev]
    for i = 1, #list do
        list[i](arg1, ...)
    end

    if type(arg1) ~= "table" then return end

    -- 2. direct entity handler
    if arg1[ev] then
        arg1[ev](arg1, ...)
    end

    -- 3. entity scope (perks, buffs, squad scope via parent chain)
    if arg1.scope then
        arg1.scope:call(ev, arg1, ...)
    end
end

-- Ask a question. Returns reduced value.
-- Order: global handlers, then ent[q], then ent.scope
function g.ask(q, arg1, ...)
    local t = questions[q]
    if not t then
        error("Invalid question: " .. tostring(q))
    end
    local reducer, val = t.reducer, t.defaultValue

    -- 1. global handlers (via g.addHandler)
    local list = handlerCache[q]
    for i = 1, #list do
        val = reducer(val, list[i](arg1, ...))
    end

    if type(arg1) == "table" then
        -- 2. direct entity handler
        if arg1[q] then
            val = reducer(val, arg1[q](arg1, ...))
        end

        -- 3. entity scope (perks, buffs, squad scope via parent chain)
        if arg1.scope then
            val = reducer(val, arg1.scope:ask(q, arg1, ...))
        end
    end

    return val
end



---@class g.Rarity
---@field id string
---@field name string
---@field color objects.Color
---@field lightTextEffect string
---@field darkTextEffect string
---@field lightColor objects.Color
---@field darkColor objects.Color
local Rarity

local function darkenColor(col, val)
    local a = select(4, col:getRGBA())
    local h, s, v = col:getHSV()
    local nr, ng, nb = objects.Color.HSVtoRGB(h, s, v * val)
    return objects.Color(nr, ng, nb, a)
end

local function lightenColor(col, val)
    local a = select(4, col:getRGBA())
    local h, s, v = col:getHSV()
    local nr, ng, nb = objects.Color.HSVtoRGB(h, math.max(0, s - val), math.min(1, v + val))
    return objects.Color(nr, ng, nb, a)
end

---@param id string
---@param name string
---@param color objects.Color
---@return g.Rarity
local function newRarity(id, name, color)
    local lightTextEffect = id .. "_COLOR_LIGHT"
    local darkTextEffect = id .. "_COLOR_DARK"
    richtext.defineEffect(lightTextEffect, function (args, x, y, context, next)
        local r, gg, b, a = love.graphics.getColor()
        love.graphics.setColor(color.r or 1, color.g or 1, color.b or 1, (color.a or 1) * a)
        next(context.textOrDrawable, x, y)
        love.graphics.setColor(r, gg, b, a)
    end)

    richtext.defineEffect(darkTextEffect, function (args, x, y, context, next)
        local r, gg, b, a = love.graphics.getColor()
        love.graphics.setColor(color.r or 1, color.g or 1, color.b or 1, (color.a or 1) * a)
        next(context.textOrDrawable, x, y)
        love.graphics.setColor(r, gg, b, a)
    end)

    local rar = {
        id = id,
        lightTextEffect = "{" .. lightTextEffect .. "}",
        darkTextEffect = "{" .. darkTextEffect .. "}",
        name = loc(name, {}, {
            context = "Represents a rarity with roman numerals, as in `UNCOMMON (II)` or `RARE (III)`."
        }),
        color = color,
        darkColor = darkenColor(color, 0.45),
        lightColor = lightenColor(color, 0.3)
    }

    return rar
end


---@class _g._rarities
g.RARITIES = {
    COMMON = newRarity("COMMON", "COMMON (I)", objects.Color.fromByteRGBA(99,99,99)),
    UNCOMMON = newRarity("UNCOMMON", "UNCOMMON (II)", objects.Color.fromByteRGBA(43,105,180)),
    RARE = newRarity("RARE", "RARE (III)", objects.Color.fromByteRGBA(160,62,144)),
    LEGENDARY = newRarity("LEGENDARY", "LEGENDARY (IV)", objects.Color.fromByteRGBA(241,241,25)),

    UNIQUE = newRarity("UNIQUE", "UNIQUE", objects.Color.WHITE),
}


---@alias g.Stat {id:string, name:string, displayName:string, description:string, baseName:string, modQ:string, mulQ:string, color:objects.Color, icon:string, isImportant:fun(ent:ecs.Entity, stat:string):boolean}
local STAT_LIST = {}
local STAT_DEFS = {}

---@param id string
---@param baseName string
---@param info {displayName:string, description:string, color:objects.Color, icon:string, isImportant:fun(ent:ecs.Entity):boolean}
function g.defineStat(id, baseName, info)
    local Name = id:sub(1,1):upper() .. id:sub(2)
    local modQ = "get" .. Name .. "Modifier"
    local mulQ = "get" .. Name .. "Multiplier"
    g.defineQuestion(modQ, reducers.ADD, 0)
    g.defineQuestion(mulQ, reducers.MULTIPLY, 1)
    local stat = {
        id = id,
        name = id,
        displayName = loc(info.displayName, {}, {
            context = "The display name of a unit stat (e.g. Health, Attack Damage)"
        }),
        description = loc(info.description, {}, {
            context = "The description of a unit stat, explaining what it does"
        }),
        baseName = baseName,
        modQ = modQ,
        mulQ = mulQ,
        color = info.color,
        icon = info.icon,
        isImportant = info.isImportant,
    }
    STAT_LIST[#STAT_LIST + 1] = stat
    STAT_DEFS[id] = stat
end



---@param statId string
---@param ent_or_etype string|ecs.Entity
function g.isStatImportant(statId, ent_or_etype)
    local stinfo = g.getStatInfo(statId)
    if type(ent_or_etype) == "string" then
        ent_or_etype = assert(g.getEntityDef(ent_or_etype))
    end
    return stinfo.isImportant(ent_or_etype, statId)
end

function g.getStatList()
    return STAT_LIST
end

---@param ent ecs.Entity
---@param stat string
---@param increase number
function g.buffEntity(ent, stat, increase)
    assert(STAT_DEFS[stat], "unknown stat: " .. tostring(stat))
    ent.buffs = ent.buffs or {}
    ent.buffs[stat] = (ent.buffs[stat] or 0) + increase
    g.call("entityBuffed", ent, stat, increase)
end

---@param id string
---@return g.Stat
function g.getStatInfo(id)
    return STAT_DEFS[id]
end





g.COLORS = {
    --[[
    
    todo: figure out what do put here:
    
    ]]
    UPGRADE = objects.Color("FFF7D172"),

    DAMAGE = objects.Color("ffd53341"),
    HEAL = objects.Color("ffc852a4"),

    BURN = objects.Color("FFE17313"),
    POISON = objects.Color("FF4CC44C"),
    HEALTH = objects.Color("FF397634"),
    ATTACK = objects.Color("FFA2741E"),
    MAP_EDGE = objects.Color(0.16, 0.28, 0.18),
    MAP_EDGE_HIGHLIGHT = objects.Color("FF396938"),
    GROUND_COLOR = objects.Color(0.08, 0.06, 0.06, 1),

    GOLD = objects.Color("FFD8B01F"),
    XP = objects.Color("FF2BC66E"),
    DARK_UI = objects.Color("FF0c0c19"),
}

for k,v in pairs(g.COLORS) do
    richtext.defineEffect(k .. "_COLOR", function (args, x, y, context, next)
        local r, gg, b, a = love.graphics.getColor()
        love.graphics.setColor(v)
        next(context.textOrDrawable, x, y)
        love.graphics.setColor(r, gg, b, a)
    end)
end




local function _alwaysImportant()
    return true
end
local function _importantIfMelee(ent, stat)
    return ent.attack and ent.attack.attackType == "melee"
end
local function _importantIfRanged(ent, stat)
    return ent.attack and ent.attack.attackType == "ranged"
end
local function _importantIfNonZero(ent, stat)
    return (ent[stat.baseName] or 0) > 0
end

g.defineStat("maxHealth", "baseMaxHealth", {
    displayName = "Health",
    description = "Health of unit",
    color = objects.Color(0.3, 0.9, 0.3),
    icon = "health",
    isImportant = _alwaysImportant,
})
g.defineStat("attackDamage", "baseAttackDamage", {
    displayName = "Attack Damage",
    description = "Damage per attack",
    color = objects.Color(0.95, 0.3, 0.3),
    icon = "damage",
    isImportant = _alwaysImportant,
})
g.defineStat("healPower", "baseHealPower", {
    displayName = "Heal Power",
    description = "Healing per attack",
    color = objects.Color(0.3, 0.95, 0.6),
    icon = "healpower",
    isImportant = _importantIfNonZero,
})
g.defineStat("attackSpeed", "baseAttackSpeed", {
    displayName = "Attack Speed",
    description = "Attacks per second",
    color = objects.Color(0.95, 0.85, 0.3),
    icon = "atkspeed",
    isImportant = _importantIfRanged,
})
g.defineStat("lifesteal", "baseLifesteal", {
    displayName = "Lifesteal",
    description = "Health gained per attack damage dealt",
    color = objects.Color(0.7, 0.2, 0.4),
    icon = "damage",
    isImportant = _importantIfNonZero,
})
g.defineStat("moveSpeed", "baseMoveSpeed", {
    displayName = "Move Speed",
    description = "Movement speed",
    color = objects.Color(0.4, 0.7, 0.95),
    icon = "movespeed",
    isImportant = _importantIfMelee,
})
g.defineStat("attackRange", "baseAttackRange", {
    displayName = "Attack Range",
    description = "Range of attacks",
    color = objects.Color(0.8, 0.5, 0.2),
    icon = "range",
    isImportant = _importantIfRanged,
})
g.defineStat("armor", "baseArmor", {
    displayName = "Armor",
    description = "Reduces damage taken",
    color = objects.Color(0.6, 0.6, 0.7),
    icon = "armor",
    isImportant = _importantIfNonZero,
})
g.defineStat("projectileAccuracy", "baseProjectileAccuracy", {
    displayName = "Accuracy",
    description = "Projectile accuracy",
    color = objects.Color(0.9, 0.9, 0.9),
    icon = "hourglass_icon",
    isImportant = _importantIfRanged,
})



---@class g.ManaInfo
---@field id string
---@field image string
---@field imageLarge string
---@field color objects.Color

---@alias g.ManaType "red"|"yellow"|"blue"|"green"

---@alias g.ManaBundle {[g.ManaType]: integer}

---@alias g.ManaCell "blue"|"green"|"red"|"yellow"|"blue_green_red_yellow"

---@alias g.ManaCounts {[g.ManaCell]: integer?}





---@param manaCounts g.ManaCounts?
---@return integer
local function getTotalManaCount(manaCounts)
    local n = 0
    for _, count in pairs(manaCounts or {}) do
        n = n + (count or 0)
    end
    return n
end

-- Returns map of unspent cells after satisfying manaRequirement, or nil if can't afford.
---@param manaCounts g.ManaCounts?
---@param manaRequirement g.ManaBundle
---@return g.ManaCounts?
local function trySpendManaInternal(manaCounts, manaRequirement)
    local needBlue = manaRequirement.blue or 0
    local needGreen = manaRequirement.green or 0
    local needRed = manaRequirement.red or 0
    local needYellow = manaRequirement.yellow or 0

    local totalNeed = needBlue + needGreen + needRed + needYellow
    if getTotalManaCount(manaCounts) < totalNeed then return nil end

    local kept = {}
    for k, v in pairs(manaCounts or {}) do
        kept[k] = v
    end

    local used = math.min(kept.blue or 0, needBlue)
    needBlue = needBlue - used
    kept.blue = (kept.blue or 0) - used

    used = math.min(kept.green or 0, needGreen)
    needGreen = needGreen - used
    kept.green = (kept.green or 0) - used

    used = math.min(kept.red or 0, needRed)
    needRed = needRed - used
    kept.red = (kept.red or 0) - used

    used = math.min(kept.yellow or 0, needYellow)
    needYellow = needYellow - used
    kept.yellow = (kept.yellow or 0) - used

    local needLeft = needBlue + needGreen + needRed + needYellow
    if needLeft > 0 then
        local wildcard = kept[g.WILDCARD_MANA] or 0
        if wildcard < needLeft then
            return nil
        end
        wildcard = wildcard - needLeft
        if wildcard > 0 then
            kept[g.WILDCARD_MANA] = math.max(0, wildcard)
        else
            kept[g.WILDCARD_MANA] = nil
        end
    end

    return kept
end


---@param manaType g.ManaType
---@param count integer
---@param sourceEnt ecs.Entity? The source of the mana
function g.addMana(manaType, count, sourceEnt)
    local battleMana = g.getRun()._battleMana
    battleMana[manaType] = (battleMana[manaType] or 0) + (count or 1)
    g.call("manaAdded", manaType, count, sourceEnt)
end


---@param manaCells g.ManaCounts
---@param manaRequirement g.ManaBundle
---@return boolean
function g.canAffordMana(manaCells, manaRequirement)
    return trySpendManaInternal(manaCells, manaRequirement) ~= nil
end

---@param manaCells g.ManaCounts
---@param manaRequirement g.ManaBundle
---@return boolean
function g.trySpendMana(manaCells, manaRequirement)
    local kept = trySpendManaInternal(manaCells, manaRequirement)
    if not kept then return false end
    for k in pairs(manaCells) do
        manaCells[k] = nil
    end
    for k, v in pairs(kept) do
        manaCells[k] = v
    end
    g.call("manaSpent", manaRequirement)
    return true
end



---@type table<string, g.ManaInfo>
local manaInfos = {}
local manaTypeList = {}

---@param id g.ManaType
---@param color objects.Color
function g.defineManaType(id, color)
    local mana_small = "mana_"..id.."_small"
    local mana_large = "mana_"..id.."_large"
    manaInfos[id] = {
        id = id,
        image = mana_small,
        imageLarge = mana_large,
        color = color,
    }
    table.insert(manaTypeList, id)
end


--- Gets a list of the possible mana types
---@return g.ManaType[]
function g.getManaTypelist()
    return manaTypeList
end


--- gets a list of the mana-types that the player actually has
---@return g.ManaCounts
function g.getPermanentManaCounts()
    return g.getRun().mana
end

--- gets a list of the mana-types available in battle
---@return g.ManaCounts
function g.getBattleManaCounts()
    return g.getRun()._battleMana or {}
end



local VALID_MANA_CELLS = {}

g.defineManaType("red", objects.Color("FFB42430"))
g.defineManaType("blue", objects.Color("FF1C7CB7"))
g.defineManaType("green", objects.Color("FF52B225"))
g.defineManaType("yellow", objects.Color("FFD0D31F"))

for _, mana1 in ipairs(manaTypeList) do
    VALID_MANA_CELLS[mana1] = true
end

g.WILDCARD_MANA = "blue_green_red_yellow"
VALID_MANA_CELLS[g.WILDCARD_MANA] = true -- wildcard mana; accepts ANY type.


g.postLoad(function()
    for _, manaType in ipairs(manaTypeList)do
        local info = manaInfos[manaType]
        local quad = g.getImageQuad(info.image)
        richtext.defineImage(manaType, atlas:getTexture(), quad)
    end
end)


---@param str string
---@return boolean
function g.isValidManaCell(str)
    return VALID_MANA_CELLS[str]
end


---@param id g.ManaType
---@return g.ManaInfo
function g.getManaInfo(id)
    return manaInfos[id]
end

---@param manaCell g.ManaCell
function g.addPermanentMana(manaCell)
    assert(g.isValidManaCell(manaCell), "Invalid mana cell: " .. tostring(manaCell))
    local run = g.getRun()
    run.mana[manaCell] = (run.mana[manaCell] or 0) + 1
end

---@param manaCell g.ManaCell
---@return boolean
function g.removePermanentMana(manaCell)
    assert(g.isValidManaCell(manaCell), "Invalid mana cell: " .. tostring(manaCell))
    local run = g.getRun()
    if (run.mana[manaCell] or 0) <= 0 then
        return false
    end
    run.mana[manaCell] = run.mana[manaCell] - 1
    if run.mana[manaCell] <= 0 then
        run.mana[manaCell] = nil
    end
    return true
end

--- Draw mana cost as individual beads, centered at (x,y), fitting within w.
---@param bundle g.ManaBundle
function g.getManaCostWidth(bundle)
    local count = 0
    for _, manaType in ipairs(manaTypeList) do
        local n = bundle[manaType]
        if n and n > 0 then count = count + n end
    end
    if count == 0 then return 0 end
    local quad = g.getImageQuad(manaInfos[manaTypeList[1]].image)
    local _, _, qw, _ = quad:getViewport()
    return (count - 1) * qw + qw
end

function g.drawManaCost(bundle, x, y, w)
    w = w or 9999
    local beads = {}
    for _, manaType in ipairs(manaTypeList) do
        local n = bundle[manaType]
        if n and n > 0 then
            for i = 1, n do
                beads[#beads + 1] = manaType
            end
        end
    end
    local count = #beads
    if count == 0 then return end

    local quad = g.getImageQuad(manaInfos[beads[1]].image)
    local _, _, qw, _ = quad:getViewport()

    local spacing = math.min(qw, count > 1 and (w - qw) / (count - 1) or qw)
    local startX = x - (count - 1) * spacing / 2

    for i, manaType in ipairs(beads) do
        g.drawImage(manaInfos[manaType].image, startX + (i - 1) * spacing, y)
    end
end



return g
