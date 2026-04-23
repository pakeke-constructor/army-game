

---@class g.BlessingInfo
---@field id string
---@field image string
---@field description string
---@field name string
---@field rarity g.Rarity
---@field mana g.ManaType?
---@field handlers table<string, function>


---@class g.PerkInfo
---@field id string
---@field description string
---@field image string
---@field handlers table<string, function>


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

    if consts.DEV_MODE then
        -- populate test stuff.
        currentRun.blessings = {
            "iron_hide", "golden_coffers", "blood_tithe", "barrage",
        }
    end

    return currentRun
end


---@return ecs.ECSWorld?
function g.getBattleECS()
    -- gets the ECS for battle
    local scene, name = g.getCurrentScene()
    if name == "battle_scene" then
        return scene.ecs
    end
end

function g.iteratePartition(partitionId, x, y, fn, range)
    local ecs = g.getBattleECS()
    if ecs then
        ecs:iteratePartition(partitionId, x, y, fn, range)
    end
end


function g.hasRun()
    return currentRun ~= nil
end

function g.getRun()
    return assert(currentRun, "run not loaded")
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

---@param squadId string
---@param x number
---@param y number
---@param w number?
---@param h number?
function g.drawSquadIcon(squadId, x, y, w, h)
    local info = g.getSquadInfo(squadId)
    local rarityColor = (info.rarity or g.RARITIES.COMMON).color
    if w and h then
        local bq = g.getImageQuad("squadicon_border")
        local _,_,bw,bh = bq:getViewport()
        local scale = math.min(w / bw, h / bh)
        local iq = g.getImageQuad(info.icon)
        local _,_,iw,ih = iq:getViewport()
        local c = gsman.mulColor(1, 1, 1)
        atlas:draw(iq, x + w/2, y + h/2, 0, scale, scale, iw/2, ih/2)
        c:pop()
        c = gsman.mulColor(rarityColor:getRGBA())
        atlas:draw(bq, x + w/2, y + h/2, 0, scale, scale, bw/2, bh/2)
        c:pop()
    else
        local c = gsman.mulColor(1, 1, 1)
        g.drawImage(info.icon, x, y)
        c:pop()
        c = gsman.mulColor(rarityColor:getRGBA())
        g.drawImage("squadicon_border", x, y)
        c:pop()
    end
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

---@class g.SquadInfo
---@field id string
---@field entityId string
---@field rarity g.Rarity
---@field name string
---@field count number
---@field icon string
---@field perks string[]
---@field cost g.ManaBundle
---@field onDeploy (fun(squad: g.SquadInfo, entities: table[], x: number, y:number))?
---@field drawSquadHover fun(x:number, y:number)?


---@param id string
---@param info g.SquadInfo|{id:nil}|{perks:nil}
function g.defineSquad(id, info)
    assert(not SQUAD_DEFS[id], "Duplicate squad: " .. id)
    info.id = id
    info.perks = info.perks or {}
    info.count = info.count or 1
    info.name = assert(info.name)
    info.rarity = assert(info.rarity)
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

---@param squad g.Squad
function g.addSquadToArmy(squad)
    local run = g.getRun()
    run.squads[#run.squads + 1] = squad
end

---@param squad g.Squad
---@return boolean
function g.removeSquadFromArmy(squad)
    local run = g.getRun()
    for i = #run.squads, 1, -1 do
        if run.squads[i] == squad then
            table.remove(run.squads, i)
            return true
        end
    end
    return false
end

---@return g.Squad[]
function g.getArmy()
    return g.getRun().squads
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
---@param manaCells g.ManaCell[]
---@return string[]
function g.getSquadsByMana(manaCells)
    local available = {}
    for _, cell in ipairs(manaCells) do
        if cell ~= g.WILDCARD_MANA then
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
    if info.onDeploy then
        info.onDeploy(info, entities)
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
---@param manaCells g.ManaCell[]
---@return string[]
function g.getBlessingsByMana(manaCells)
    local available = {}
    for _, cell in ipairs(manaCells) do
        if cell ~= g.WILDCARD_MANA then
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

function g.addBlessing(id)
    assert(BLESSING_DEFS[id], "Unknown blessing: " .. tostring(id))
    local run = g.getRun()
    run.blessings[#run.blessings + 1] = id
end

function g.removeBlessing(id)
    local run = g.getRun()
    for i = #run.blessings, 1, -1 do
        if run.blessings[i] == id then
            table.remove(run.blessings, i)
            return true
        end
    end
    return false
end

function g.addBlessingHandlers()
    if not g.hasRun() then return end
    local run = g.getRun()
    for i = 1, #run.blessings do
        local info = BLESSING_DEFS[run.blessings[i]]
        if info and info.handlers then
            g.addHandler(info.handlers)
        end
    end
end

-- Perk system

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

--- Add a buff to an entity. Promotes shared scopes so buff only affects this entity.
function g.addBuff(ent, handler, duration)
    if not ent.scope then
        ent.scope = g.newScope()
    elseif ent.scope.shared then
        ent.scope = g.newScope(ent.scope)
    end
    ent.scope:addHandler(handler, duration)
end


-- Entity system
local ENTITY_DEFS = {}
local ENTITY_LIST = {}
local currentEntityId = 0

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
    local ecs = g.getBattleECS()
    assert(ecs, "g.spawnEntity called outside of battle")
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
    return ent
end

function g.isAlive(ent)
    -- todo: check if inside ECS too
    return not ent.___removed
end

---@param target ecs.Entity
---@param damage number
---@param attacker ecs.Entity?
function g.dealDamage(target, damage, attacker)
    if not g.isAlive(target) then return end

    local reduction = g.ask("getDamageReduction", target)
    local finalDmg = math.max(0, damage - reduction)

    target.health = target.health - finalDmg
    target._timeSinceDamaged = 0

    g.call("entityHurt", target, finalDmg, attacker)

    if target.health <= 0 then
        g.killEntity(target, attacker)
    end
end

---@param ent ecs.Entity
---@param killer ecs.Entity?
function g.killEntity(ent, killer)
    if not g.isAlive(ent) then return end
    ent.health = 0
    g.call("entityDeath", ent, killer)
    if killer then
        g.call("entityKillsEnemy", killer, ent)
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



---@param ent ecs.Entity
---@param x number
---@param y number
local function drawHealthBar(ent, x,y)
    if not ent.maxHealth then return end
    local w, h = 16, 2
    local frac = ent.health / ent.maxHealth
    -- black outline
    local out=2
    local oy=10
    lg.setColor(0, 0, 0)
    lg.rectangle("fill", x - w/2 - out, y + oy - out, w + out*2, h + out*2)

    local t = helper.clamp((ent._timeSinceDamaged or 0xfffffffff) / consts.LAGGED_HEALTHBAR_DURATION, 0, 1)
    t = helper.clamp(helper.EASINGS.easeInCubic(t), 0, 1)
    local lagFrac = helper.lerp(1, frac, t)
    -- white lagged
    lg.setColor(1, 1, 1)
    lg.rectangle("fill", x - w/2, y + oy, w * lagFrac, h)
    -- red health
    lg.setColor(1, 0, 0)
    lg.rectangle("fill", x - w/2, y + oy, w * frac, h)
end

function g.drawEntity(ent, x, y)
    local sx, sy = (ent.sx or 1) * (ent.faceDir or 1), ent.sy or 1
    if ent.draw then
        ent:draw(x, y)
        return
    end
    if ent.image then
        love.graphics.setColor(1, 1, 1, ent.alpha or 1)
        g.drawImage(ent.image, x + (ent.ox or 0), y + (ent.oy or 0), ent.rot or 0, sx, sy)
    end
    if ent.health then
        drawHealthBar(ent, x,y)
    end
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
function g.drawUnit(entityId, x, y, maxW, maxH)
    local def = g.getEntityDef(entityId)
    if not def or not def.image then return end
    if maxW and maxH then
        g.drawImageContained(def.image, x, y, maxW, maxH)
    else
        g.drawImage(def.image, x, y)
    end
end

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

function g.defineEvent(ev)
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

function Scope:addHandler(handler, duration)
    for key in pairs(handler) do
        assert(definedEvents[key] or questions[key], "Unknown event/question: " .. tostring(key))
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


---@alias g.Stat {id:string, name:string, baseName:string, modQ:string, mulQ:string, color:objects.Color, icon:string, isImportant:fun(ent:ecs.Entity, stat:string):boolean}
local STAT_LIST = {}
local STAT_DEFS = {}

---@param id string
---@param baseName string
---@param info {color:objects.Color, icon:string, isImportant:fun(ent:ecs.Entity):boolean}
function g.defineStat(id, baseName, info)
    local Name = id:sub(1,1):upper() .. id:sub(2)
    local modQ = "get" .. Name .. "Modifier"
    local mulQ = "get" .. Name .. "Multiplier"
    g.defineQuestion(modQ, reducers.ADD, 0)
    g.defineQuestion(mulQ, reducers.MULTIPLY, 1)
    local stat = {
        id = id,
        name = id,
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

---@param id string
---@return g.Stat
function g.getStatInfo(id)
    return STAT_DEFS[id]
end





g.COLORS = {
    --[[
    
    todo: figure out what do put here:
    
    ]]
    HEALTH = objects.Color("FF397634"),
    ATTACK = objects.Color("FFA2741E"),
    MAP_EDGE = objects.Color(0.16, 0.28, 0.18),
    MAP_EDGE_HIGHLIGHT = objects.Color(1, 1, 0.2, 1),
    GROUND_COLOR = objects.Color(0.08, 0.06, 0.06, 1),
    MANA = objects.Color("FF3DC8E8"),
}




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
    color = objects.Color(0.3, 0.9, 0.3),
    icon = "health",
    isImportant = _alwaysImportant,
})
g.defineStat("attackDamage", "baseAttackDamage", {
    color = objects.Color(0.95, 0.3, 0.3),
    icon = "damage",
    isImportant = _alwaysImportant,
})
g.defineStat("attackSpeed", "baseAttackSpeed", {
    color = objects.Color(0.95, 0.85, 0.3),
    icon = "atkspeed",
    isImportant = _importantIfRanged,
})
g.defineStat("moveSpeed", "baseMoveSpeed", {
    color = objects.Color(0.4, 0.7, 0.95),
    icon = "movespeed",
    isImportant = _importantIfMelee,
})
g.defineStat("attackRange", "baseAttackRange", {
    color = objects.Color(0.8, 0.5, 0.2),
    icon = "range",
    isImportant = _importantIfRanged,
})
g.defineStat("armor", "baseArmor", {
    color = objects.Color(0.6, 0.6, 0.7),
    icon = "armor",
    isImportant = _importantIfNonZero,
})
g.defineStat("projectileAccuracy", "baseProjectileAccuracy", {
    color = objects.Color(0.9, 0.9, 0.9),
    icon = "hourglass_icon",
    isImportant = _importantIfRanged,
})



---@class g.ManaInfo
---@field id string
---@field image string
---@field color objects.Color

---@alias g.ManaType "red"|"yellow"|"blue"|"green"

---@alias g.ManaBundle {[g.ManaType]: integer}

---@alias g.ManaCell "blue"|"green"|"red"|"yellow"|"blue_green_red_yellow"




-- Returns list of unspent cells after satisfying manaRequirement, or nil if can't afford.
local function trySpendManaInternal(manaCells, manaRequirement)
    local needBlue = manaRequirement.blue or 0
    local needGreen = manaRequirement.green or 0
    local needRed = manaRequirement.red or 0
    local needYellow = manaRequirement.yellow or 0

    local totalNeed = needBlue + needGreen + needRed + needYellow
    if #manaCells < totalNeed then return nil end

    local kept = {}
    local keptN = 0

    for _, cell in ipairs(manaCells) do
        if cell == "blue" and needBlue > 0 then
            needBlue = needBlue - 1
        elseif cell == "green" and needGreen > 0 then
            needGreen = needGreen - 1
        elseif cell == "red" and needRed > 0 then
            needRed = needRed - 1
        elseif cell == "yellow" and needYellow > 0 then
            needYellow = needYellow - 1
        else
            keptN = keptN + 1
            kept[keptN] = cell
        end
    end

    local write = 1
    for i = 1, keptN do
        local cell = kept[i]
        if cell == g.WILDCARD_MANA then
            if needBlue > 0 then
                needBlue = needBlue - 1
            elseif needGreen > 0 then
                needGreen = needGreen - 1
            elseif needRed > 0 then
                needRed = needRed - 1
            elseif needYellow > 0 then
                needYellow = needYellow - 1
            else
                kept[write] = cell
                write = write + 1
            end
        else
            kept[write] = cell
            write = write + 1
        end
    end

    if needBlue > 0 or needGreen > 0 or needRed > 0 or needYellow > 0 then
        return nil
    end

    for i = #kept, write, -1 do
        kept[i] = nil
    end

    return kept
end

---@param manaCells g.ManaCell[]
---@param manaRequirement g.ManaBundle
---@return boolean
function g.canAfford(manaCells, manaRequirement)
    return trySpendManaInternal(manaCells, manaRequirement) ~= nil
end

---@param manaCells g.ManaCell[]
---@param manaRequirement g.ManaBundle
---@return boolean
function g.trySpendMana(manaCells, manaRequirement)
    local kept = trySpendManaInternal(manaCells, manaRequirement)
    if not kept then return false end
    for i = #manaCells, 1, -1 do
        table.remove(manaCells, i)
    end
    for _, cell in ipairs(kept) do
        table.insert(manaCells, cell)
    end
    return true
end



---@type table<string, g.ManaInfo>
local manaInfos = {}
local manaTypeList = {}

---@param id g.ManaType
---@param image string
---@param color objects.Color
function g.defineManaType(id, image, color)
    manaInfos[id] = {
        id = id,
        image = image,
        color = color,
    }
    table.insert(manaTypeList, id)
end


---@return g.ManaType[]
function g.getManaTypes()
    return manaTypeList
end


local VALID_MANA_CELLS = {}

g.defineManaType("blue", "blue_mana", objects.Color("#36c7de"))
g.defineManaType("green", "green_mana", objects.Color("#7cc82a"))
for _, mana1 in ipairs(manaTypeList) do
    VALID_MANA_CELLS[mana1] = true
end
            VALID_MANA_CELLS[strKey] = true
        end
    end
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
    run.mana[#run.mana + 1] = manaCell
end

---@param manaCell g.ManaCell
---@return boolean
function g.removePermanentMana(manaCell)
    assert(g.isValidManaCell(manaCell), "Invalid mana cell: " .. tostring(manaCell))
    local run = g.getRun()
    for i = #run.mana, 1, -1 do
        if run.mana[i] == manaCell then
            table.remove(run.mana, i)
            return true
        end
    end
    return false
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
