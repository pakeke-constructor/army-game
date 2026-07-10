

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
---@field onAdd fun()? Called once, the moment this blessing is first acquired.


---@class g.PerkDef
---@field name string (for definition, untranslated name; for info, translated name)
---@field description string
---@field image string
---@field handlers table<string, fun(ent: ecs.Entity, ...): any>? Scoped to the entity. Only fires when the event/question is dispatched AT this entity (eg g.call("onHit", ent)). Cheap; default choice.
---@field rawHandlers table<string, fun(ent: ecs.Entity, ...): any>? Scene-level. Fires for EVERY dispatch of that event globally, regardless of target. Use when the perk needs to listen to things happening elsewhere (eg "when any ally is hurt"). More expensive; use only when `handlers` can't express it.
---@field armyHandlers table<string, fun(squad: g.Squad, ...): any>? Army-level. Registered once per army squad holding this perk, regardless of whether it has deployed. First arg is the owning squad. Use for effects computed from run state that must be known before the squad spawns (eg modifying this squad's own unit count).

---@class g.PerkInfo: g.PerkDef
---@field id string
---@field handlers table<string, fun(ent: ecs.Entity, ...): any> Scoped to the entity. Only fires when the event/question is dispatched AT this entity (eg g.call("onHit", ent)). Cheap; default choice.
---@field rawHandlers table<string, fun(ent: ecs.Entity, ...): any> Scene-level. Fires for EVERY dispatch of that event globally, regardless of target. Use when the perk needs to listen to things happening elsewhere (eg "when any ally is hurt"). More expensive; use only when `handlers` can't express it.
---@field armyHandlers table<string, fun(squad: g.Squad, ...): any> Army-level. Registered once per army squad holding this perk, regardless of whether it has deployed. First arg is the owning squad. Use for effects computed from run state that must be known before the squad spawns (eg modifying this squad's own unit count).


---@class g.TraitInfo
---@field id string
---@field name string
---@field color table
---@field description string
---@field handlers table<string, fun(ent: ecs.Entity, ...): any>? Per-entity handlers, scoped to the unit that has the trait. Only fires when dispatched AT this entity.
---@field deployAnywhere boolean? Units with this trait can be deployed anywhere (eg flying).


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

local juiceService = require("src.juiceService")
local newPicker = require("src.modules.Picker")
local tags = require("src.tags")



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

function g.getTagList()
    return tags.LIST
end

function g.isTag(tag)
    return tags.SET[tag] == true
end

local function assertValidTags(kind, id, tagList)
    if tagList == nil then
        return
    end

    assert(type(tagList) == "table", kind .. " '" .. id .. "' tags must be a list")

    local total = 0
    for _ in pairs(tagList) do
        total = total + 1
    end
    assert(total == #tagList, kind .. " '" .. id .. "' tags must be a dense array")

    local seen = {}
    for i, tag in ipairs(tagList) do
        assert(type(tag) == "string", kind .. " '" .. id .. "' tag #" .. i .. " must be a string")
        assert(tags.SET[tag], kind .. " '" .. id .. "' uses unknown tag: " .. tag)
        assert(not seen[tag], kind .. " '" .. id .. "' has duplicate tag: " .. tag)
        seen[tag] = true
    end
end





local PALETTE = {
    objects.Color("#c5303d"), -- {197, 48, 61}
    objects.Color("#59471d"), -- {89, 71, 29}
    objects.Color("#4f2d5d"), -- {79, 45, 93}
    objects.Color("#36c7de"), -- {54, 199, 222}
    objects.Color("#c852a4"), -- {200, 82, 164}
    objects.Color("#1d3a51"), -- {29, 58, 81}
    objects.Color("#111211"), -- {17, 18, 17}
    objects.Color("#636363"), -- {99, 99, 99}
    objects.Color("#2e44d1"), -- {46, 68, 209}
    objects.Color("#a6541b"), -- {166, 84, 27}
    objects.Color("#5f3927"), -- {95, 57, 39}
    objects.Color("#1d1b0e"), -- {29, 27, 14}
    objects.Color("#cd853b"), -- {205, 133, 59}
    objects.Color("#080808"), -- {8, 8, 8}
    objects.Color("#ffffff"), -- {255, 255, 255}
    objects.Color("#361e19"), -- {54, 30, 25}
    objects.Color("#140e12"), -- {20, 14, 18}
    objects.Color("#272747"), -- {39, 39, 71}
    objects.Color("#273718"), -- {39, 55, 24}
    objects.Color("#bce3e9"), -- {188, 227, 233}
    objects.Color("#484848"), -- {72, 72, 72}
    objects.Color("#000000"), -- {0, 0, 0}
    objects.Color("#357dd2"), -- {53, 125, 210}
    objects.Color("#236449"), -- {35, 100, 73}
    objects.Color("#f1f11e"), -- {241, 241, 30}
    objects.Color("#7cc82a"), -- {124, 200, 42}
    objects.Color("#646a35"), -- {100, 106, 53}
    objects.Color("#4d8c21"), -- {77, 140, 33}
    objects.Color("#2c2c2c"), -- {44, 44, 44}
    objects.Color("#8c9fa9"), -- {140, 159, 169}
    objects.Color("#7c2222"), -- {124, 34, 34}
    objects.Color("#e1b97b"), -- {225, 185, 123}
}

---Snap a color to the nearest palette entry.
---Uses 4th-power channel distance to deeply penalize large per-channel differences.
---Preserves the input alpha.
---@param r number red [0..1]
---@param gg number green [0..1]
---@param b number blue [0..1]
---@param a number? alpha [0..1] (default 1)
---@overload fun(color:objects.Color):objects.Color
---@overload fun(color:string):objects.Color
---@return objects.Color
function g.snapToPalette(r, gg, b, a)
    if type(r) == "table" then
        r, gg, b, a = r[1], r[2], r[3], r[4]
    elseif type(r) == "string" then
        r, gg, b, a = objects.Color(r):getRGBA()
    end
    a = a or 1
    local best, bestDist = nil, math.huge
    for _, c in ipairs(PALETTE) do
        local rbar = (r + c.r) * 0.5
        local dr, dg, db = r - c.r, gg - c.g, b - c.b
        -- redmean: cheap perceptual RGB distance
        local dist = (2 + rbar)*dr*dr + 4*dg*dg + (3 - rbar)*db*db
        if dist < bestDist then
            bestDist = dist
            best = c
        end
    end
    assert(best, "?")
    return best:clone():setRGBA(nil, nil, nil, a)
end



---@class g.SquadDefForCommander: g.SquadDef
---@field name nil

---@class g.CommanderDef
---@field description string
---@field image string
---@field startMana g.ManaBundle
---@field squadDef g.SquadDefForCommander?
---@field squadId string?
---@field onStart (fun(run: g.Run))?

---@class g.CommanderInfo: g.CommanderDef
---@field id string
---@field name string
---@field description string
---@field image string
---@field startMana g.ManaBundle
---@field squadDef g.SquadDef?
---@field squadId string?
---@field onStart (fun(run: g.Run))?

local COMMANDERS = {}
local COMMANDER_LIST = {}

local function getCommanderSquadId(id)
    return "commander_" .. id
end

---@param id string
---@param name string
---@param info g.CommanderDef
function g.defineCommander(id, name, info)
    assert(not COMMANDERS[id], "Duplicate commander: " .. id)
    assertValidTags("Commander", id, info.tags)
    info.name = loc(name, {}, {
        context = "The name of a commander"
    })
    info.id = id
    assert(info.image,"commanders need images")
    ---@cast info g.CommanderInfo

    assert(info.startMana and next(info.startMana), "missing starting mana")

    local squadDef = info.squadDef
    if squadDef then
        assert(squadDef.entityDef, "commanders need squadDef.entityDef")
        assert(squadDef.rarity == g.RARITIES.COMMANDER, "commander squad rarity must be UNIQUE")
        assert((squadDef.unitCount or 1) == 1, "commander squad unitCount must be 1")
        assert(squadDef.cost, "commanders need squadDef.cost")

        squadDef.rarity = g.RARITIES.COMMANDER
        squadDef.unitCount = 1
        squadDef.name = squadDef.name or info.name
        squadDef.icon = squadDef.icon or info.image

        local squadId = getCommanderSquadId(id)
        info.squadId = squadId
        g.defineSquad(squadId, squadDef)
    end

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



---@type g.Run?
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
    if cmdInfo.squadId then
        g.addSquadToArmy(cmdInfo.squadId)
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
            golden_coffers = true, blood_tithe = true, barrage = true,
        }
        currentRun.money = 1000
    end

end

function g.hasRun()
    return currentRun ~= nil
end

---@return g.Run
function g.getRun()
    return assert(currentRun, "run not loaded")
end

local RUN_SAVE_PATH = "saves/run1.json"

function g.saveRun()
    if not currentRun or not currentRun.serialize then
        return
    end
    local data = currentRun:serialize()
    local contents = json.encode(data)
    love.filesystem.write(RUN_SAVE_PATH, contents)
end

function g.loadRun()
    local contents = assert(love.filesystem.read(RUN_SAVE_PATH))
    local data = json.decode(contents)
    currentRun = Run.deserialize(data)
end

function g.hasSavedRun()
    return not not love.filesystem.getInfo(RUN_SAVE_PATH, "file")
end

function g.saveAndInvalidateRun()
    if not currentRun or not currentRun.serialize then
        return
    end
    g.saveRun()
    g.delRun()
end

---@param delsave boolean?
function g.delRun(delsave)
    currentRun = nil
    if delsave and g.hasSavedRun() then
        love.filesystem.remove(RUN_SAVE_PATH)
    end
end


---@param partitionId string
---@param x number
---@param y number
---@param fn fun(ent: ecs.Entity)
---@param range number
function g.iteratePartition(partitionId, x, y, fn, range)
    local ecs = g.getECS()
    ecs:iteratePartition(partitionId, x, y, fn, range)
end


--- List is cached, so this function is efficient to call, is O(1).
--- doesn't rebuild list each time.
---@return ecs.Entity[]
function g.getAllyList()
    local ecs = g.getECS()
    return ecs:getAllyList()
end

--- List is cached, so this function is efficient to call, is O(1).
--- doesn't rebuild list each time.
---@return ecs.Entity[]
function g.getEnemyList(fn)
    local ecs = g.getECS()
    return ecs:getEnemyList()
end



---@param x number
---@param y number
---@param damage number
---@param radius number?
---@param fromEntity ecs.Entity?
function g.explosion(x, y, damage, radius, fromEntity)
    radius = radius or 60
    if fromEntity then
        radius = radius * g.ask("getExplosionSizeMultiplier", fromEntity)
    end
    g.call("explosion", x, y, damage, radius, fromEntity)
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


do

---@param x number
---@param y number
---@param maxDistance number
---@param excludeEntities {[ecs.Entity]:boolean?}
local function findFurthestEnemyWithinDistance(x, y, maxDistance, excludeEntities)
    local radius = maxDistance
    local bestEnt = nil
    local bestDistSq = -1
    local maxDistSq = maxDistance * maxDistance

    g.getECS():iteratePartition("enemy", x, y, function(ent)
        if not g.isAlive(ent) then return end
        if excludeEntities[ent] then return end

        local dx = ent.x - x
        local dy = ent.y - y
        local distSq = dx * dx + dy * dy
        if distSq > maxDistSq then return end
        if distSq <= bestDistSq then return end

        bestDistSq = distSq
        bestEnt = ent
    end, radius)

    return bestEnt
end

---@param x number
---@param y number
---@param damage number
---@param attacker ecs.Entity?
---@param enemyChainSize number?
function g.lightning(x, y, damage, attacker, enemyChainSize)
    g.playWorldSound("lightning_zap", 0.9, 0.25, 0.3, 0)
    enemyChainSize = math.max(2, enemyChainSize or 5)

    local MAX_LIGHTNING_GAP = 130

    ---@type {[ecs.Entity]: boolean?}
    local foundEnemies = {}
    ---@type ecs.Entity[]
    local enemyList = {}

    local enemyEnt = findFurthestEnemyWithinDistance(x, y, MAX_LIGHTNING_GAP, foundEnemies)
    if not enemyEnt then return end

    foundEnemies[enemyEnt] = true
    enemyList[#enemyList + 1] = enemyEnt

    for _ = 1, enemyChainSize - 1 do
        local enemyEnt1 = findFurthestEnemyWithinDistance(enemyEnt.x, enemyEnt.y, MAX_LIGHTNING_GAP, foundEnemies)
        if not enemyEnt1 then break end
        foundEnemies[enemyEnt1] = true
        enemyList[#enemyList + 1] = enemyEnt1
        enemyEnt = enemyEnt1
    end

    for _,ent in ipairs(enemyList)do
        g.dealDamage(ent, damage, attacker)
    end

    if #enemyList >= 2 then
        g.spawnEntityWithInit("lightning_chain_visual", 0,0, function(ent)
            -- list of tokens to strike
            ent._lightningTargets = enemyList
            local bestY = -100
            for _,t in ipairs(enemyList) do
                if t.y > bestY then
                    ent.x = t.x
                    ent.y = t.y
                    bestY = t.y
                end
            end
        end)
    end
end

end





---@param count integer? default to 1
function g.incrementDays(count)
    local run = g.getRun()
    run.day = math.min(run.day + (count or 1), run.daysUntilIncursion)
end

---This function won't decrement days if it's already on incursion!
---@param count integer? default to 1
function g.decrementDays(count)
    local run = g.getRun()
    if run.day ~= run.daysUntilIncursion then
        run.day = run.day - (count or 1)
    end
end



local mapTypes = require("src.scenes.map_scene.map_types")

---@return MapType
---@return string
function g.getMapType()
    local run = g.getRun()
    local mapType = run and run.mapGraph and run.mapGraph.mapType.name
    mapType = mapType or consts.STARTING_MAP_TYPE
    return assert(mapTypes[mapType]), mapType
end

local currentECS
---@return ecs.ECSWorld
function g.getECS()
    return assert(currentECS, "ecs not active")
end

--- Non-asserting accessor: returns the active ECS, or nil when no battle is running.
---@return ecs.ECSWorld?
function g.tryGetECS()
    return currentECS
end

--- O(1) cached lookup of the live commander entity (nil if none/dead).
---@return ecs.Entity?
function g.getCommanderEntity()
    return currentECS and currentECS._commander
end

---@param ecs ecs.ECSWorld
function g.setCurrentECS(ecs)
    currentECS = ecs
end

---@param amount number
function g.addGold(amount)
    local run = g.getRun()
    run.money = run.money + amount
    g.call("goldGained", amount)
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



---@return love.Texture
function g.getAtlas()
    return atlas:getTexture()
end

---@param imageName string
---@return love.Quad
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


-- Placeholder function for our artist
do

local weNeedThis = objects.Set() --[[@as objects.Set<string>]]
---@param image string
---@param fallback string?
function g.leo(image, fallback)
    if not g.isImage(image) then
        weNeedThis:add(image)
        return fallback or "placeholder"
    end
    return image
end

function g._dumpWhatLeoNeedsToCreate()
    return weNeedThis:totable()
end

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

local LEVEL_TEXT = interp("Lv.%{level}", {context = "Abbreviated level text"})
local LEVEL_MAX_TEXT = loc("MAX", {context = "Max level reached"})
local SQUAD_LEVEL_COLORS = {
    g.snapToPalette("#ffffff"),
    g.snapToPalette("#f1f11e"),
    g.snapToPalette("#f1f11e"),
    g.snapToPalette("#cd853b"),
    g.snapToPalette("#cd853b"),
    g.snapToPalette("#c5303d"),
    g.snapToPalette("#c5303d"),
    g.snapToPalette("#c852a4"),
    g.snapToPalette("#c852a4"),
    g.snapToPalette("#357dd2")
}

local TRAIL_CHASER_COUNT = {
    RARE = 2,
    LEGENDARY = 4
}

---@param squadId string
---@param x number
---@param y number
---@param drawManaCost boolean?
---@param drawLevel integer?
function g.drawSquadIcon(squadId, x, y, drawManaCost, drawLevel)
    local info = g.getSquadInfo(squadId)
    --local rarityColor = (info.rarity or g.RARITIES.COMMON).color
    local col = g.getManaBundleColor(info.cost)
    local size = 32 -- hacky hardcode

    if TRAIL_CHASER_COUNT[info.rarity.id] then
        local OUTER_PAD = 1
        local trailCount = TRAIL_CHASER_COUNT[info.rarity.id]
        local trailR = Kirigami(
            x - size / 2 - OUTER_PAD,
            y - size / 2 - OUTER_PAD,
            size + 2 * OUTER_PAD,
            size + 2 * OUTER_PAD
        )
        local c = gsman.mulColor(info.rarity.color)
        for i = 1, trailCount do
            helper.drawEdgeTrailAnimation(trailR, info.rarity.color, i / trailCount)
        end
        c:pop()
    end

    g.drawImage(info.icon, x, y)

    local c = gsman.mulColor(col)
    g.drawImage("squadicon_border", x, y)
    c:pop()

    if drawManaCost then
        g.drawManaCost(info.cost, x,y-size/2, size + 6)
    end
    if drawLevel and not info.entityDef.isCommander then
        -- draw level:
        local font = g.getSmallFont(16)
        local co = gsman.setColor(SQUAD_LEVEL_COLORS[helper.clamp(drawLevel, 1, 10)])
        local text
        if drawLevel >= 10 then
            text = "{bob amp=0.5}{o}"..LEVEL_MAX_TEXT
        else
            text = "{o}"..LEVEL_TEXT({level = tostring(drawLevel)})
        end
        richtext.printRichContainedNoWrap(text, font, x - size / 2, y+6, size, 16, "center")
        co:pop()
    end
end


---@param spellId string
---@param x number
---@param y number
---@param drawManaCost boolean?
function g.renderSpellIcon(spellId, x, y, drawManaCost)
    local info = g.getSpellInfo(spellId)
    local col = g.getManaBundleColor(info.cost)
    local c = gsman.mulColor(1, 1, 1)
    g.drawImage(info.icon, x, y)
    c:pop()
    c = gsman.mulColor(col)
    g.drawImage("spellicon_border", x, y)
    c:pop()

    local size = 32 -- hacky hardcode
    if drawManaCost then
        g.drawManaCost(info.cost, x, y - size/2, size + 6)
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
    return sfx.play(soundname, pitch, volume, pitchVar, volumeVar)
end


---@param soundname string
---@param pitch number? (defaults to 1)
---@param volume number? (defaults to 1)
---@param pitchVar number? (pitch variance, default 0)
---@param volumeVar number? (volume variance, default 0)
function g.playUISound(soundname, pitch, volume, pitchVar, volumeVar)
    return sfx.play(soundname, pitch, volume, pitchVar, volumeVar)
end


function g.updateSfx()
    sfx.update()
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

local TRAIT_DEFS = {}
local TRAIT_LIST = {}

-- Squad system
local SQUAD_DEFS = {}
local SQUAD_LIST = {}

-- entity type defs
local ENTITY_DEFS = {}
local ENTITY_LIST = {}
local currentEntityId = 0

---@class g.SquadDef
---@field squadOrder integer? Use this to help determine the "order" of squads. -10 = deployed first, 0 = deployed middle/unimportant, 10 = deployed last. By default, buildings = -10, melee = 0, ranged = 10. Which means that the placement ordering in HUD will be (buildings, melee, ranged).  You MUST edit this if the unit benefits from being placed first/last, e.g. "when deployed, buff all allies." <-- this should be set order = 50 or something, so it's deployed LAST. By contrast, a unit that has a perk: "Whenever an ally is spawned, earn $1", <-- this should have squadOrder = -30 or something; to ensure it's FIRST.
---@field entityId string?
---@field entityDef ecs.Components
---@field unitCount integer? (default is 1)
---@field statUpgradeScaling table<string, number>? { [statName] -> number }
---@field unitCountUpgradeScaling integer?
---@field name string (for definition, untranslated name; for info, translated name)
---@field nameContext string? context passed to `loc` function
---@field rarity g.Rarity
---@field icon string?
---@field perks (g.PerkDef|string|false)[]? Perks will be given ID `id.."_perk_..i` if `g.PerkDef` is passed. Use `false` to skip IDs. Pass existing perk ID to use that instead.
---@field startingTraits string[]? Trait ids applied to every unit in this squad on spawn.
---@field cost g.ManaBundle?
---@field squadType g.SquadType? Optional explicit category. Auto-derived from stats if omitted.
---@field onDeploySquad (fun(squad: g.SquadInfo, entities: ecs.Entity[], x: number, y:number))?
---@field drawSquadHover fun(x:number, y:number)?

---@class g.SquadInfo: g.SquadDef
---@field id string
---@field squadOrder integer
---@field entityId string
---@field unitCount integer
---@field statUpgradeScaling table<string, number> { [statName] -> number }
---@field unitCountUpgradeScaling integer
---@field icon string
---@field perks string[]
---@field startingTraits string[] Trait ids applied to every unit in this squad on spawn.
---@field cost g.ManaBundle
---@field powerIndex number
---@field squadType g.SquadType

---@param squadInfo g.SquadDef
---@return number
local function estimateSquadPowerIndex(squadInfo)
    -- squad power-index is a heuristic representation of like: "how powerful" a squad is.
    ----- 
    local def = squadInfo.entityDef
    local bonus = 1
    local attack = def.baseAttackDamage or def.baseHealPower or 1
    local attackSpeed = def.baseAttackSpeed or 1
    local unitCount = squadInfo.unitCount or 1
    local healthArmr = (def.baseMaxHealth or 1) + (def.baseStartingArmor or 0)
    local timeToDealDmg = 4*healthArmr + math.max(1,((def.baseAttackRange or 1) - 20))

    local manaCost = 0
    for _, n in pairs(squadInfo.cost or {}) do
        manaCost = manaCost + (n or 0)
    end
    if manaCost > 1 then
        bonus = bonus / 2.5 -- units that cost more have lower powerIndex, coz they are more expensive.
    end

    return math.floor(bonus * (attack*attackSpeed*timeToDealDmg*unitCount))
end


---@enum g.SquadType
g.SQUAD_TYPES = objects.Enum({
    "TANK",     -- high hp
    "BRUISER",  -- melee, high hp, good damage
    "RANGED",   -- ranged, damage
    "HEALER",   -- healer
    "BUILDING", -- building
    "OTHER",
})

---Derive a squad's category from its stats.
---@param info g.SquadDef
---@return g.SquadType
local function categorizeSquad(info)
    local def = info.entityDef

    if def.isBuilding then
        return g.SQUAD_TYPES.BUILDING
    end

    local healPower = def.baseHealPower or 0
    local attackDamage = def.baseAttackDamage or 0
    if healPower > 0 and healPower >= attackDamage then
        return g.SQUAD_TYPES.HEALER
    end

    local isRanged = def.attack and def.attack.attackType == "ranged"
    if isRanged and healPower <= 0 then
        return g.SQUAD_TYPES.RANGED
    end

    -- melee from here on. Compare bulk vs damage output.
    local health = (def.baseMaxHealth or 0) + (def.baseStartingArmor or 0)
    local dps = attackDamage * (def.baseAttackSpeed or 0)
    if dps > 0 and health >= dps * 20 then
        return g.SQUAD_TYPES.TANK
    end
    if dps > 0 and health > 0 then
        return g.SQUAD_TYPES.BRUISER
    end

    return g.SQUAD_TYPES.OTHER
end


---@param id string
---@param info g.SquadDef
function g.defineSquad(id, info)
    if SQUAD_DEFS[id] then
        error("Duplicate squad: " .. id)
    end
    assertValidTags("Squad", id, info.tags)

    info.id = id
    info.startingTraits = info.startingTraits or {}
    info.unitCount = info.unitCount or 1
    info.name = loc(assert(info.name), {}, {context = info.nameContext or "Name of a squad."})
    info.rarity = assert(info.rarity)
    info.unitCountUpgradeScaling = info.unitCountUpgradeScaling or 0
    info.statUpgradeScaling = info.statUpgradeScaling or {}
    info.entityId = info.entityId or (id .. "_unit")
    info.cost = info.cost or {}
    info.squadOrder = info.squadOrder or 0
    assert(info.entityDef, "Missing entityDef for squad: " .. id)

    if not info.icon then
        -- Infer icon name from id
        local infericon1 = id:gsub("_squad", ""):gsub("_", "").."_uniticon"
        if g.isImage(infericon1) then
            info.icon = infericon1
        end

        local infericon2 = id:gsub("_squad", ""):gsub("_", "").."s_uniticon"
        if g.isImage(infericon2) then
            info.icon = infericon2
        end

        if not info.icon then
            log.error("Squad had no icon: ", id)
            g.leo(infericon1.."/"..infericon2)
            info.icon = "example_squad_icon"
        end
    end
    if not g.isImage(info.icon) then
        error("Squad has invalid icon: "..info.icon)
    end

    local def = info.entityDef
    local hasDmg = def.baseHealPower or def.baseAttackDamage
    assert((not hasDmg) == (not def.baseAttackSpeed),
        "Squad '" .. id .. "': baseAttackSpeed must be set iff baseAttackDamage/baseHealPower is set")
    def.team = def.team or "ally"
    def.partitions = def.partitions or {"unit", "ally"}
    if not def.isBuilding then
        def.ai = def.ai or { target = "enemy" }
    end
    def.shadow = def.shadow or {}
    if not def.physics and def.image then
        local w = g.getImageSize(def.image)
        def.physics = { shape = "circle", radius = w / 2, ox = 0, oy = 0, mass = 1 }
    end

    if not ENTITY_DEFS[info.entityId] then
        g.defineEntity(info.entityId, info.entityDef)
    end
    assert(type(info.unitCountUpgradeScaling) == "number")
    for stat,scaling in pairs(info.statUpgradeScaling)do
        assert(g.getStatInfo(stat), "?")
        assert(scaling < 1, "Per-level stat scaling shouldn't be more than 100%. Must be number between (0,1)")
    end
    if (not next(info.statUpgradeScaling)) then
        -- then there's no stat upgrades.
        if info.unitCount > 2 and info.unitCountUpgradeScaling <= 0 then
            info.unitCountUpgradeScaling = math.max(1, math.floor(info.unitCount * 0.25 + 0.5))
        else
            log.error("This unit NEEDS a stat upgrade, but doesn't have one: " .. id)
        end
    end
    assert(info.icon)
    info.powerIndex = estimateSquadPowerIndex(info)
    info.squadType = info.squadType or categorizeSquad(info)

    -- register perks
    ---@type string[]
    local perkIds = {}
    if info.perks then
        for i, pdef in ipairs(info.perks) do
            if pdef then
                if type(pdef) == "string" then
                    perkIds[#perkIds+1] = pdef
                else
                    local pid = id.."_perk_"..i
                    g.definePerk(pid, pdef)
                    perkIds[#perkIds + 1] = pid
                end
            end
        end
    end
    table.sort(perkIds)
    info.perks = perkIds

    ---@cast info g.SquadInfo
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
    local sq = g.newSquad(squadId)
    run.squads[squadId] = sq
    run._sortedSquads = nil
    return sq
end

--- Adds a temporary squad to the bench for the current fight only.
--- Battle squads are cleared at the start and end of every battle.
---@param squadId string
---@param level integer?
function g.addBattleSquad(squadId, level)
    local run = g.getRun()
    run._battleSquads = run._battleSquads or {}
    local squad = g.newSquad(squadId)
    squad.level = level or 1
    run._battleSquads[#run._battleSquads + 1] = squad
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
    if g.hasRun() then
        return g.getRun().squads[squadId]
    end
    return nil
end


-- ============================================================================
-- SPELLS
-- Spells are like squads, but played DURING battle (after battle start),
-- whereas squads are played BEFORE battle (during the deploy/planning phase).
-- ============================================================================

local SPELL_DEFS = {}
local SPELL_LIST = {}

---@class g.SpellInstantCastDef
---@field target "ally"|"enemy"
---@field maxTargets integer?
---@field filter (fun(ent: ecs.Entity, castX: number, castY: number, spellId: string): boolean?)?
---@field apply fun(ent: ecs.Entity, castX: number, castY: number, spellId: string)

---@class g.SpellDef
---@field name string (untranslated at definition; translated in info)
---@field nameContext string?
---@field color objects.Color?
---@field rarity g.Rarity
---@field icon string
---@field cost g.ManaBundle?
---@field description string?
---@field spellRange number?
---@field spellArea number?
---@field instantCast g.SpellInstantCastDef?
---@field cast (fun(spellId: string, x: number, y: number))?

---@class g.SpellInfo: g.SpellDef
---@field id string
---@field cost g.ManaBundle

---@param id string
---@param info g.SpellDef
function g.defineSpell(id, info)
    if SPELL_DEFS[id] then
        error("Duplicate spell: " .. id)
    end
    assertValidTags("Spell", id, info.tags)
    info.id = id
    local manaType
    for key,v in pairs(info.cost) do
        manaType = key; break
    end
    local manaCol = g.getManaInfo(manaType).color
    info.color = g.snapToPalette(info.color or manaCol)
    info.name = loc(assert(info.name), {}, {context = info.nameContext or "Name of a spell."})
    info.rarity = assert(info.rarity)
    info.cost = info.cost or {}
    assert(info.icon, "Missing icon for spell: " .. id)
    if not g.isImage(info.icon) then
        error("Spell has invalid icon: " .. info.icon)
    end
    if info.instantCast then
        local instant = info.instantCast
        assert(instant.target == "ally" or instant.target == "enemy", "Invalid spell instantCast.target for: " .. id)
        assert(type(instant.apply) == "function", "Missing spell instantCast.apply for: " .. id)
    end
    ---@cast info g.SpellInfo
    SPELL_DEFS[id] = info
    SPELL_LIST[#SPELL_LIST + 1] = id
end

---@param id string
---@return g.SpellInfo
function g.getSpellInfo(id)
    return assert(SPELL_DEFS[id], "Unknown spell: " .. tostring(id))
end

---@param spellId string
function g.addSpellToArmy(spellId)
    local run = g.getRun()
    assert(SPELL_DEFS[spellId], "Unknown spell: " .. tostring(spellId))
    run.spells[spellId] = true
end

---@param spellId string
---@return boolean
function g.hasSpell(spellId)
    return g.getRun().spells[spellId] == true
end

---@param info g.SpellInfo
---@param x number
---@param y number
---@param fn fun(ent: ecs.Entity)
---@return integer
local function iterateSpellTargets(info, x, y, fn)
    local instant = info.instantCast
    if not instant then return 0 end

    local maxTargets = instant.maxTargets
    local area = info.spellArea or info.spellRange or 500
    local hitCount = 0

    g.iteratePartition(instant.target, x, y, function(ent)
        if maxTargets and hitCount >= maxTargets then return end
        if not g.isAlive(ent) then return end
        if instant.filter and not instant.filter(ent, x, y, info.id) then return end
        hitCount = hitCount + 1
        fn(ent)
    end, area)

    return hitCount
end

---@param worldX number
---@param worldY number
---@param spellId string
---@return boolean
function g.canCastSpell(worldX, worldY, spellId)
    local info = g.getSpellInfo(spellId)
    local run = g.getRun()
    local affordable = (not info.cost) or g.canAffordMana(run._battleMana, info.cost)
    if not affordable then return false end
    if not info.instantCast then return true end

    local hitCount = iterateSpellTargets(info, worldX, worldY, function() end)
    return hitCount > 0
end

---@param x number
---@param y number
---@param spellId string
function g.renderSpellCastPreview(x, y, spellId)
    local info = g.getSpellInfo(spellId)
    local range = info.spellRange or info.spellArea or 500

    lg.setColor(info.color)
    lg.circle("line", x, y, range)

    local rot = love.timer.getTime() * 3

    iterateSpellTargets(info, x, y, function(ent)
        g.drawImageOffset("commander_target_3", ent.x, ent.y - 20, rot, 1, 1, 0.5, 0.5)
    end)

    lg.setColor(1, 1, 1, 1)
end

---@param info g.SpellInfo
---@param x number
---@param y number
local function runInstantCastSpell(info, x, y)
    iterateSpellTargets(info, x, y, function(ent)
        info.instantCast.apply(ent, x, y, info.id)
    end)
end

--- Cast a spell at a point.
---@param spellId string
---@param x number
---@param y number
function g.castSpell(spellId, x, y)
    local info = g.getSpellInfo(spellId)
    g.getRun().spellsCast[spellId] = true

    if info.instantCast then
        runInstantCastSpell(info, x, y)
        return
    end

    if info.cast then
        info.cast(spellId, x, y)
    end
end




--- checks if an entity is a ranged attacker
---@param entId string
---@return boolean
function g.isRangedUnit(entId)
    local etype = g.getEntityDef(entId)
    if etype.attack and etype.attack.attackType == "ranged" then
        return true
    end
    return false
end

--- checks if an entity is a building type
---@param entId string
---@return boolean
function g.isBuildingType(entId)
    local etype = g.getEntityDef(entId)
    if etype.isBuilding then
        return true
    end
    return false
end



---@param a g.Squad
---@param b g.Squad
local function squadSortFn(a, b)
    local infoA = g.getSquadInfo(a.squadId)
    local infoB = g.getSquadInfo(b.squadId)

    -- first, prioritize hardcoded order.
    local orderA = (infoA.squadOrder or 0)
    local orderB = (infoB.squadOrder or 0)

    -- then, prioritize (building > melee > ranged)
    if g.isRangedUnit(infoA.entityId) then
        orderA = orderA + 10
    end
    if g.isBuildingType(infoA.entityId) then
        orderA = orderA - 10
    end

    if g.isRangedUnit(infoB.entityId) then
        orderB = orderB + 10
    end
    if g.isBuildingType(infoB.entityId) then
        orderB = orderB - 10
    end

    if orderA ~= orderB then
        return orderA < orderB
    end
    return a.squadId < b.squadId
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
    if run._battleSquads then
        for _, sq in ipairs(run._battleSquads) do
            list[#list + 1] = sq
        end
    end
    table.sort(list, squadSortFn)
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
        for manaType, _ in pairs(info.cost or {}) do
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


local DEPLOY_ANIMATION_STEP = 0.2

---@param squad g.Squad
---@param x number
---@param y number
---@return ecs.Entity[]
function g.spawnSquad(squad, x, y, ...)
    local scene = g.getCurrentScene()
    local commander = scene and scene.commander
    local commx, commy = x, y
    if commander and g.isAlive(commander) then
        commx = commander.x
        commy = commander.y
        if commander.image then
            local _, h = g.getImageSize(commander.image)
            commy = commy - h / 2
        end
    end
    local info = assert(SQUAD_DEFS[squad.squadId], "Unknown squad: " .. tostring(squad.squadId))
    local squadScope = g.newScope()
    squadScope.shared = true
    for j = 1, #squad.perks do
        local perkInfo = g.getPerkInfo(squad.perks[j])
        if perkInfo.handlers then
            squadScope:addHandler(perkInfo.handlers)
        end
    end
    local offsets = squad:getFormationOffsets()
    -- invisible squad "leader": the whole squad marches toward it as a group.
    squad.leader = { x = x, y = y, target = nil, engaged = false }
    local entities = {}
    local numUnits = #offsets
    for i = 1, numUnits do
        g.spawnEntityWithInit(info.entityId, x + offsets[i].x, y + offsets[i].y, function(ent)
            ent.scope = squadScope
            ent.squad = squad
            ent._formationOffset = offsets[i]
            for _, stat in ipairs(g.getStatList()) do
                -- apply squad buffs:
                if ent[stat.baseName] then
                    ent[stat.baseName] = ent[stat.baseName] + g.getSquadStatBuff(squad.squadId, stat.name)
                end
            end
            ent._deployTime = love.timer.getTime() + ((i - 1)/numUnits) * DEPLOY_ANIMATION_STEP
            for _, traitName in ipairs(info.startingTraits) do
                g.addTrait(ent, traitName)
            end
            entities[i] = ent
        end, ...)
    end
    squad.deployDxFromCommander = x - commx
    squad.deployDyFromCommander = y - commy
    for i = 1, #entities do
        local ent = entities[i]
        ent.deployDxFromCommander = ent.x - commx
        ent.deployDyFromCommander = ent.y - commy
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
    assertValidTags("Blessing", id, info.tags)
    if not info.image or info.image == "placeholder" then
        info.image = g.leo("blessing_"..id)
    end

    if info.image == "placeholder" then
        log.warn("No image for blessing:",id)
    elseif not g.isImage(info.image) then
        error("Invalid image: "..info.image)
    end
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

---@param manaCells g.ManaCounts
---@param rarityWeights g.RarityWeights?
---@param seen table<string, true?>?
---@return string?
function g.getRandomBlessingByMana(manaCells, rarityWeights, seen)
    local pool = g.getBlessingsByMana(manaCells)
    if #pool == 0 then return nil end

    local run = g.getRun()
    seen = seen or helper.shallowCopy(run and run.blessings or {})

    local weights = {}
    rarityWeights = rarityWeights or consts.DEFAULT_RARITY_WEIGHTS
    for i, id in ipairs(pool) do
        local info = g.getBlessingInfo(id)
        weights[i] = rarityWeights[info.rarity.id] or 0
    end

    local picker = newPicker(pool, weights)
    local pick = picker:pick()
    for _ = 1, 20 do
        if not seen[pick] then break end
        pick = picker:pick()
    end

    if seen[pick] then return nil end
    return pick
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
        if info.onAdd then info.onAdd() end
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
    -- army-level perk handlers: registered from squads in the army (not from
    -- battlefield entities), so they answer questions even before the squad
    -- deploys. Each handler is wrapped with its owning squad as the first arg.
    for _, squad in pairs(run.squads) do
        for _, perkId in ipairs(squad.perks) do
            local pinfo = g.getPerkInfo(perkId)
            if pinfo.armyHandlers then
                for k, func in pairs(pinfo.armyHandlers) do
                    g.addHandler({ [k] = function(...) return func(squad, ...) end })
                end
            end
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
---@param info g.PerkDef
function g.definePerk(id, info)
    if PERK_DEFS[id] then
        error("Duplicate perk: " .. id)
    end
    assertValidTags("Perk", id, info.tags)

    ---@cast info g.PerkInfo
    info.name = loc(info.name, {}, {
        context = "The name of a perk"
    })
    info.id = id
    info.handlers = info.handlers or {}
    info.rawHandlers = info.rawHandlers or {}
    info.armyHandlers = info.armyHandlers or {}
    PERK_DEFS[id] = info
    PERK_LIST[#PERK_LIST + 1] = id
end

---@param id string
---@return g.PerkInfo
function g.getPerkInfo(id)
    return assert(PERK_DEFS[id], "Unknown perk: " .. tostring(id))
end

function g.getPerkList()
    return PERK_LIST
end


-- Trait system
-- Traits are a simpler, more commodified step down from perks. Per-unit, applied
-- to an entity's scope. Eg flying, fireproof, loyal.

--- Define a trait.
---@param id string
---@param name string
---@param info g.TraitInfo|{id:nil,name:nil}
function g.defineTrait(id, name, info)
    assert(not TRAIT_DEFS[id], "Duplicate trait: " .. id)
    info.name = loc(name, {}, { context = "The name of a trait" })
    info.id = id
    TRAIT_DEFS[id] = info
    TRAIT_LIST[#TRAIT_LIST + 1] = id
end

---@param id string
---@return g.TraitInfo
function g.getTraitInfo(id)
    return assert(TRAIT_DEFS[id], "Unknown trait: " .. tostring(id))
end

---@return string[]
function g.getTraitDefList()
    return TRAIT_LIST
end

--- Add a trait to an entity. Registers its handlers on the entity's scope.
---@param ent ecs.Entity
---@param traitName string
function g.addTrait(ent, traitName)
    local info = g.getTraitInfo(traitName)
    ent.traits = ent.traits or {}
    if ent.traits[traitName] then return end
    if info.handlers then
        g.addCustomEffect(ent, info.handlers, nil, "trait_" .. traitName)
    end
    ent.traits[traitName] = true
end

--- Remove a trait from an entity.
---@param ent ecs.Entity
---@param traitName string
function g.removeTrait(ent, traitName)
    if not (ent.traits and ent.traits[traitName]) then return end
    ent.traits[traitName] = nil
    local info = g.getTraitInfo(traitName)
    if info.handlers and ent.scope then
        ent.scope:removeHandler(info.handlers)
    end
end

---@param ent ecs.Entity
---@return boolean
function g.hasTrait(ent, traitName)
    return ent.traits ~= nil and ent.traits[traitName] == true
end

--- True if a squad's starting traits let it deploy anywhere (eg flying).
---@param squad g.Squad
---@return boolean
function g.squadCanDeployAnywhere(squad)
    local info = g.getSquadInfo(squad.squadId)
    for _, traitName in ipairs(info.startingTraits) do
        if g.getTraitInfo(traitName).deployAnywhere then
            return true
        end
    end
    return false
end

--- List of trait names on an entity.
---@param ent ecs.Entity
---@return string[]
function g.getTraitList(ent)
    local list = {}
    if ent.traits then
        for name in pairs(ent.traits) do
            list[#list + 1] = name
        end
    end
    return list
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



---@param id string
---@param def ecs.Components
function g.defineEntity(id, def)
    assert(not ENTITY_DEFS[id], "Duplicate entity type: " .. id)
    assert(def.x == nil and def.y == nil and def.type == nil and def._world == nil, "x/y/type/_world are reserved")
    for k in pairs(Entity) do
        assert(def[k] == nil, "Entity def '" .. id .. "' cannot override base method: " .. k)
    end
    if def.isBuilding and def.physics then
        assert((def.baseMoveSpeed or 0) <= 0)
        assert(def.physics.isStatic, "Buildings must have static physics")
    end
    def.type = id

    def.image = def.image or id
    if def.image and (not g.isImage(def.image)) then
        def.image = g.leo(def.image)
    end

    for k, v in pairs(Entity) do
        def[k] = v
    end
    if def.baseHealPower and def.baseHealPower > 0 then
        assert(not def.baseAttackDamage or def.baseAttackDamage <= 0, "Entities cannot be healers AND attackers at same time")
    end
    if def.attack and def.attack.attackType == "ranged" then
        def.isRanged = true
    end
    if def.physics and def.attack and def.attack.attackType == "melee" then
        local minRange = def.physics.radius * 2
        if def.baseAttackRange < minRange then
            error("melee baseAttackRange (" .. def.baseAttackRange .. ") < physics radius*2 (" .. minRange .. ")")
        end
    end
    local mt = {__index = def}
    ENTITY_DEFS[id] = mt
    ENTITY_LIST[#ENTITY_LIST + 1] = id
end


local entInitTc = typecheck.assert("string","number","number")

--- we need this coz sometimes we need fields to be set immediately BEFORE qbuses or anything run
---@param id string
---@param x number
---@param y number
---@param initFunc (fun(e:ecs.Entity))?
---@param ... unknown
---@return ecs.Entity
function g.spawnEntityWithInit(id, x, y, initFunc, ...)
    entInitTc(id,x,y)
    local mt = ENTITY_DEFS[id]
    assert(mt, "Unknown entity type: " .. tostring(id))
    local ecs = g.getECS()
    currentEntityId = currentEntityId + 1
    local ent = setmetatable({
        id = currentEntityId,
        x = x, y = y, type = id,
        _world = ecs,
    }, mt)
    if ent.init then
        ent:init(...)
    end
    if initFunc then
        initFunc(ent)
    end
    if ent.randomizeScaleX then
        local baseSx = math.abs(ent.sx or 1)
        ent.sx = (love.math.random() < 0.5) and -baseSx or baseSx
    end
    if ent.ai and (not ent.isBuilding) then
        local h = 30
        if ent.image then
            local _, ih = g.getImageSize(ent.image)
            h = ih
        end
        -- normal units ~30 tall = scale 1; bigger = heavier
        local scale = math.max(1, h / 30)
        -- a def may set walkAnimation directly (partial ok); fill missing fields
        local wa = ent.walkAnimation
        ent.walkAnimation = {
            bounceHeight = wa and wa.bounceHeight or (2.5 / scale),
            rotationAmount = wa and wa.rotationAmount or (0.12 / scale),
            speed = wa and wa.speed or (11 / scale),
        }
    end
    ecs:addEntity(ent)
    g.call("entitySpawned", ent)
    if ent.startingArmor then
        g.addArmor(ent, ent.startingArmor)
    end
    return ent
end

---@param id string
---@param x number
---@param y number
---@param ... unknown
---@return ecs.Entity
function g.spawnEntity(id, x, y, ...)
    return g.spawnEntityWithInit(id, x,y, nil, ...)
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
    if g.hasTrait(ent, "fireproof") or g.hasTrait("fishfolk") then return false end
    local wasActive = ent.burnTime and ent.burnTime > 0
    ent.burnTime = (ent.burnTime or 0) + duration
    if not wasActive then
        g.call("statusEffectApplied", ent, "burn", duration, source)
        return true
    end
    return false
end

---@param ent ecs.Entity
---@param amount number NOTE: this is not duration! this is AMOUNT
---@param source ecs.Entity?
---@return boolean applied
function g.applyPoison(ent, amount, source)
    ent.poisonAmount = (ent.poisonAmount or 0) + amount
    -- poison if always applied, since it stacks
    if amount > 0 then
        g.call("statusEffectApplied", ent, "poison", amount, source)
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
        ent._timeSinceHealed = 0
        g.call("entityHealed", ent, finalHeal, healerEnt)
        g.call("onHitHeal", healerEnt, finalHeal, ent)
    end
end

local sfxList = {
    7, 3, 4
}

---@param target ecs.Entity
---@param damage number
---@param attacker ecs.Entity?
---@param ignoreQuestionBuses boolean?
function g.dealDamage(target, damage, attacker, ignoreQuestionBuses)
    if not g.isAlive(target) then return end

    if not ignoreQuestionBuses and target.armor then
        if attacker then
            g.call("onHitDamage", attacker, damage, target, true)
        end
        g.playWorldSound("battle_metalHit", 1+love.math.random(30, 50)/100)
        g.removeArmor(target, 1)
        return
    end

    local finalDmg = math.max(0, damage)
    if not ignoreQuestionBuses then
        finalDmg = finalDmg * g.ask("getDamageTakenMultiplier", target, attacker)
    end

    target._damageLagAmount = (target._damageLagAmount or 0) + finalDmg

    target.health = target.health - finalDmg
    target._timeSinceDamaged = 0

    if attacker then
        g.call("onHitDamage", attacker, damage, target, false)
    end
    g.call("entityHurt", target, damage)
    g.playWorldSound("battle_hit" .. sfxList[love.math.random(1, #sfxList)], 1+love.math.random(-20, 20)/100)

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
    if ent.___dead or not g.isAlive(ent) then return end
    ent.___dead = true
    ent.health = 0
    g.call("entityDeath", ent, killer)
    g.playWorldSound("battle_splat2", 1+love.math.random(-20, 20)/100)
    if killer then
        g.call("onKill", killer, ent)
    end
    if ent.team == "enemy" then
        local amount = math.max(1, math.floor(g.ask("getMoneyMultiplier") + 0.5))
        g.addGold(amount)
        g.addWorldTextPopup(ent.x, ent.y - 10, "{GOLD_COLOR}$" .. tostring(amount), {
            vely = -200,
            velDamping = 0.995,
            duration = 0.3
        })
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
    strength = strength - (ent.knockbackResistance or 0)
    if strength <= 0 then return end
    ent.knockbackResistance = (ent.knockbackResistance or 0) + consts.KNOCKBACK_RESISTANCE_INCREMENT
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


local HEALTHBAR_ON_TOP = true
-- true if healthbar on top, 
-- false implies healthbar on bottom

local USE_OLD_RENDERING = true
-- true if uses old health rendering
-- false to use segmented health bars

local ENEMY_HEALTHBAR_COLOR = g.snapToPalette(1, 0.1, 0.1)
local ALLY_HEALTHBAR_COLOR = g.snapToPalette(0.1, 1, 0.1)
local NEUTRAL_HEALTHBAR_COLOR = g.snapToPalette(0.1, 0.4, 1)
local HEALTHBAR_SIZE_MULT = 1 -- for segmented rendering only.


---@param maxHp number
local function getHPSegmentInfo(maxHp)
    -- The segments count is adjusted depending on the max health
    -- such that the segment for each health is around the specified value.
    local MIN_HP_PER_SEGMENT = 25
	local MAX_HP_PER_SEGMENT = 45
	local IDEAL_HP_PER_SEGMENT = (MIN_HP_PER_SEGMENT + MAX_HP_PER_SEGMENT) / 2

	if maxHp <= MIN_HP_PER_SEGMENT then
		return 1, 1
	end

	local minSegments = math.ceil(maxHp / MAX_HP_PER_SEGMENT)
	local maxSegments = math.floor(maxHp / MIN_HP_PER_SEGMENT)

	local ideal = math.floor(maxHp / IDEAL_HP_PER_SEGMENT + 0.5)

	local segments = math.max(minSegments, math.min(maxSegments, ideal))
    return segments, 1
end

---@param ent ecs.Entity
---@param x number
---@param y number
local function drawHealthBar(ent, x,y)
    if not ent.maxHealth then return end

    -- Ok so technical info in new rendering:
    -- Single health segment is between certain HP range
    -- The segments count and thickness is adjusted depending on the max health
    -- Each segment is like 10 pixel long.

    if not USE_OLD_RENDERING then
        local SEGMENT_SPACING = 2
        local SEGMENT_HEIGHT = 2
        local PADDING = 2
        local nsegments, thickness = getHPSegmentInfo(ent.maxHealth)
        local height = SEGMENT_HEIGHT + (thickness - 1) * 2

        local iw, ih = 32, 32 -- sensible default
        if ent.image then
            iw, ih = g.getImageSize(ent.image)
        end

        local width = math.min(iw, ih) * HEALTHBAR_SIZE_MULT
        local segmentWidth = math.floor(width / nsegments + 0.5)
        width = nsegments * segmentWidth + (nsegments - 1) * SEGMENT_SPACING

        local hx = x - width / 2
        local hy
        if HEALTHBAR_ON_TOP then
            hy = y - ih - 4 - height
        else
            hy = y + height + 4
        end

        -- Draw base area for health bar
        lg.setColor(0, 0, 0)
        helper.drawFilledRectangle(
            hx - PADDING,
            hy - PADDING,
            width + 2 * PADDING,
            height + 2 * PADDING
        )

        local hpPerSegment = ent.maxHealth / nsegments
        local rulerCount = math.floor(math.min(hpPerSegment / 3 / thickness, segmentWidth / 3))
        local lagHealth = helper.clamp((ent.health or 0) + (ent._damageLagAmount or 0), 0, ent.maxHealth)
        local health = helper.clamp(ent.health or 0, 0, ent.maxHealth)

        local healthColor = NEUTRAL_HEALTHBAR_COLOR
        if ent.team == "enemy" then
            healthColor = ENEMY_HEALTHBAR_COLOR
        elseif ent.team == "ally" then
            healthColor = ALLY_HEALTHBAR_COLOR
        end
        local healthColorStrip = healthColor:darken(0.3)

        ---@param hpA number
        ---@param hpB number
        ---@param color objects.Color
        local function drawHealthRange(hpA, hpB, color)
            hpA = helper.clamp(hpA, 0, ent.maxHealth)
            hpB = helper.clamp(hpB, 0, ent.maxHealth)
            if hpB <= hpA then return end

            lg.setColor(color)
            for i = 1, nsegments do
                local sx = hx + (i - 1) * (segmentWidth + SEGMENT_SPACING)
                local segmentStart = (i - 1) * hpPerSegment
                local segmentEnd = i * hpPerSegment
                local a = math.max(hpA, segmentStart)
                local b = math.min(hpB, segmentEnd)

                if b > a then
                    local fracA = (a - segmentStart) / hpPerSegment
                    local fracB = (b - segmentStart) / hpPerSegment
                    local x1 = sx + fracA * segmentWidth
                    local x2 = sx + fracB * segmentWidth
                    helper.drawFilledRectangle(x1, hy, x2 - x1, height)

                    lg.setColor(color:darken(0.3))
                    for j = 1, rulerCount do
                        local pos = j / (rulerCount + 1)
                        if pos > fracA and pos < fracB then
                            local px = segmentWidth * pos
                            helper.drawFilledRectangle(sx + px - 0.5, hy, 1, height)
                        end
                    end
                    lg.setColor(color)
                end
            end
        end

        -- Draw the segments
        for i = 1, nsegments do
            local sx = hx + (i - 1) * (segmentWidth + SEGMENT_SPACING)
            local segmentStart = (i - 1) * hpPerSegment
            local lagFrac = helper.clamp((lagHealth - segmentStart) / hpPerSegment, 0, 1)
            local frac = helper.clamp((health - segmentStart) / hpPerSegment, 0, 1)

            if lagFrac > 0 then
                lg.setColor(1, 1, 1)
                helper.drawFilledRectangle(sx, hy, segmentWidth * lagFrac, height)
            end

            if frac > 0 then
                lg.setColor(healthColor)
                helper.drawFilledRectangle(sx, hy, segmentWidth * frac, height)

                lg.setColor(healthColorStrip)
                for j = 1, rulerCount do
                    local pos = j / (rulerCount + 1)
                    if pos >= frac then
                        break
                    end

                    local px = segmentWidth * pos
                    helper.drawFilledRectangle(sx + px - 0.5, hy, 1, height)
                end
            end
        end

        -- status effect tip segments (drawn right-to-left from tip)
        local rightHp = health
        local function drawTip(hp, color)
            hp = math.min(hp, rightHp)
            if hp <= 0 then return end
            drawHealthRange(rightHp - hp, rightHp, color)
            rightHp = rightHp - hp
        end
        drawTip(5 * (ent.poisonAmount or 0), g.COLORS.POISON)
        drawTip((ent.burnTime or 0) * consts.BURN_DPS, g.COLORS.BURN)

        if ent.armor then
            local FLASH_DUR = 0.15
            local armorFlash = math.max(0, FLASH_DUR - (ent._timeSinceLostArmor or 0xfff)) / FLASH_DUR
            local armorH = 6
            local armorY = hy + height
            local ratio = math.min(1, ent.armor / 6)
            local pad = 2

            lg.setColor(0, 0, 0)
            helper.drawFilledRectangle(hx, armorY, width * ratio, armorH)

            lg.setColor(0.5, 0.5, 0.5)
            helper.drawFilledRectangle(hx + pad, armorY + pad, ratio * (width - pad * 2), armorH - pad * 2)

            if armorFlash > 0 then
                lg.setColor(1, 1, 1, armorFlash)
                helper.drawFilledRectangle(hx, armorY, width * ratio, armorH)
            end

            lg.setColor(1, 1, 1)
            g.drawImage("armor_healthbar_icon", hx - 2, armorY + 2)
            if armorFlash > 0 then
                lg.setColor(1, 1, 1, armorFlash)
                g.drawImage("armor_healthbar_icon_white", hx - 2, armorY + 2)
            end
        end

        return
    end

    -- Below is old rendering
    local w, h = 16, 2
    local frac = ent.health / ent.maxHealth

    local oy = -2
    if HEALTHBAR_ON_TOP then
        local _w,hhh = g.getImageSize(ent.image)
        oy= -hhh - 4
    end

    -- black outline
    local out=2
    lg.setColor(0, 0, 0)
    lg.rectangle("fill", x - w/2 - out, y + oy - out, w + out*2, h + out*2)

    local lagFrac = helper.clamp((ent.health + (ent._damageLagAmount or 0)) / ent.maxHealth, 0, 1)
    -- white lagged
    lg.setColor(1, 1, 1)
    lg.rectangle("fill", x - w/2, y + oy, w * lagFrac, h)

    -- green healthbar for allies, red for enemies
    if ent.team == "enemy" then
        lg.setColor(ENEMY_HEALTHBAR_COLOR)
    elseif ent.team == "ally" then
        lg.setColor(ALLY_HEALTHBAR_COLOR)
    else -- neutral unit
        lg.setColor(NEUTRAL_HEALTHBAR_COLOR)
    end
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



---@param ent ecs.Entity
---@return number
function g.getAttackCooldown(ent)
    return 1 / (ent.attackSpeed or 1)
end


---@param ent ecs.Entity
---@return "windup"|"swing"|"idle" phase, number t
function g.getAttackPhase(ent)
    local wep = ent.weapon
    if not ent._isInAttackRange then
        return "idle", 0
    end
    if not wep or not ent._attackTimer or not ent.attackSpeed then
        return "idle", 0
    end
    local cooldown = g.getAttackCooldown(ent)
    local strikeDur = wep.swordStrikeTime or 0.12
    local windupDur = wep.swordSwingTime or 0.2
    local sinceAttack = cooldown - ent._attackTimer
    if sinceAttack >= 0 and sinceAttack < strikeDur then
        return "swing", sinceAttack / strikeDur
    elseif ent._attackTimer < windupDur then
        return "windup", 1 - ent._attackTimer / windupDur
    end
    return "idle", 0
end

---@param ent ecs.Entity
---@param x number
---@param y number
local function drawWeapon(ent, x,y)
    local wep = ent.weapon
    ---@cast wep ecs.components.Weapon

    local w,h = g.getImageSize(ent.image)

    local atkTime = ent._attackTimer or 10

    if wep.type == "sword" then
        local face = ent.faceDir or 1
        local dx = face * (wep.xOffset or 6)
        local dy = wep.yOffset or 0
        local phase, t = g.getAttackPhase(ent)
        local rotLogical = 0
        if phase == "windup" then
            rotLogical = -1.0 * helper.EASINGS.easeInCubic(t)
        elseif phase == "swing" then
            rotLogical = helper.lerp(-1.0, 1.4, helper.EASINGS.easeOutBack(t))
        end
        local dxx, dyy = helper.fromPolar(rotLogical, 7)
        dxx = dxx * face
        dyy = dyy - math.floor(h/5)
        g.drawImageOffset(wep.image, x + dx + dxx, y + dy + dyy, rotLogical * face, 1,1, 0.5, 0.95)
        -- drawImageOffset(imageName, x, y, r, sx, sy, ox, oy, kx, ky)

    elseif wep.type == "spear" then
        local face = ent.faceDir or 1
        local dx = face * (wep.xOffset or 10)
        local swingTime = (wep.spearStrikeTime) or 0.2
        local ratio = helper.clamp(1 - (atkTime / swingTime), 0, 1)

        local target = ent._aiTarget
        local targetRot = 0.25 * face
        if target and target.x and target.y and ent.x and ent.y then
            targetRot = math.atan2((target.y - 12) - ent.y, target.x - ent.x)
        end

        local FORWARD_OFFSET = -math.pi / 2
        local attackRot = targetRot - FORWARD_OFFSET

        local rot = 0
        local stab = 0
        local T1 = 0.2
        local T2 = 1 - T1

        if ratio < T1 then
            local t = ratio / T1
            rot = helper.lerp(0, attackRot, t)
        elseif ratio < T2 then
            local t = (ratio - T1) / (T2 - T1)
            rot = attackRot
            stab = 1 - math.abs(t * 2 - 1)
        else
            local t = (ratio - T2) / (1 - T2)
            rot = helper.lerp(attackRot, 0, t)
        end

        local stabDist = stab * (ent.attackRange / 2)
        local forwardRot = rot + FORWARD_OFFSET
        local stabx, staby = helper.fromPolar(forwardRot, stabDist)
        local dyy = staby - math.floor(h/5)
        g.drawImageOffset(wep.image, x + dx + stabx, y + dyy, rot, 1, 1, 0.5, 0.95)
    elseif wep.type == "bow" then
        local dx = (ent.faceDir or 1) * (wep.xOffset or 8)
        local drawTime = 0.2
        local ratio = helper.clamp(1 - (atkTime / drawTime), 0, 1)
        local face = ent.faceDir or 1
        local target = ent._aiTarget
        local rot = (face >= 0) and 0 or math.pi
        if target and target.x and target.y and ent.x and ent.y then
            rot = math.atan2((target.y - 12) - ent.y, target.x - ent.x)
        end
        local recoil = (wep.bowRecoil or 0.1) * 24 * ratio
        local bob = math.sin(g.getWorldTime() * 7 + (ent.id or 0)) * ((wep.weaponBobbing or 0.1) * 2)
        local offx, offy = helper.fromPolar(rot, 5)
        local pullx, pully = helper.fromPolar(rot + math.pi, recoil)
        local dyy = bob + offy + pully - math.floor(h/2) + (wep.yOffset or 0)
        g.drawImageOffset(wep.image, x + dx + offx + pullx, y + dyy, rot, 1, 1, 0.5, 0.5)
    elseif wep.type == "object" then
    elseif wep.type == "hammer" then
        local face = ent.faceDir or 1
        local dx = face * (wep.xOffset or 8)
        local phase, t = g.getAttackPhase(ent)
        local BACK = -2 -- raised behind the back
        local DOWN = 1.3  -- smashed down in front
        local SMASH = 0.75 -- fraction of swing spent spinning; rest holds down
        local rotLogical = 0
        if phase == "windup" then
            rotLogical = BACK * helper.EASINGS.sineOut(t)
        elseif phase == "swing" then
            if t < SMASH then
                rotLogical = helper.lerp(BACK, DOWN, (t / SMASH) ^ 7)
            else
                rotLogical = DOWN -- hold down at the end
            end
        end
        local radius = wep.arcRadius or (h * 0.6)
        local dxx, dyy = helper.fromPolar(rotLogical, radius)
        dxx = dxx * face
        dyy = dyy - math.floor(h/3)
        g.drawImageOffset(wep.image, x + dx + dxx, y + dyy, rotLogical * face, 1, 1, 0.5, 0.95)
    elseif wep.type == "staff" then
        local face = ent.faceDir or 1
        local dx = face * (wep.xOffset or 8)
        local dy = wep.yOffset or 0

        local idleBob = math.sin(g.getWorldTime() * 2.5 + (ent.id or 0)) * (wep.weaponBobbing or 1.5)
        local phase, t = g.getAttackPhase(ent)
        local castLift = 0
        local castHeight = wep.staffCastHeight or 8
        if phase == "windup" then
            castLift = -castHeight * helper.EASINGS.sineOut(t)
        elseif phase == "swing" then
            castLift = -castHeight * (1 - helper.EASINGS.sineIn(t))
        end

        local dyy = dy + idleBob + castLift - math.floor(h/3)
        g.drawImageOffset(wep.image, x + dx, y + dyy, 0, 1, 1, 0.5, 0.95)
    elseif wep.type == "shield" then
        local face = ent.faceDir or 1
        local dx = face * (wep.xOffset or 12)
        local dy = wep.yOffset or 0

        local idleBob = math.sin(g.getWorldTime() * 2.2 + (ent.id or 0)) * (wep.weaponBobbing or 1.0)
        local phase, t = g.getAttackPhase(ent)
        local bash = wep.shieldBashDistance or 3
        local attackDx = 0
        if phase == "windup" then
            attackDx = -bash * 0.25 * helper.EASINGS.sineOut(t)
        elseif phase == "swing" then
            attackDx = bash * helper.EASINGS.sineIn(t)
        end

        local dyy = dy + idleBob
        g.drawImageOffset(wep.image, x + dx + (attackDx * face), y + dyy, 0, 1, 1, 0.5, 0.95)
    end
    -- g.drawImageOffset(wep.image, )
end


local function getBodyRot(ent)
    local bodyRot = 0
    if ent.weapon then
        local typ = ent.weapon.type
        if typ == "sword" or typ == "spear" or typ == "hammer" then
            local mul = 0.4
            if typ == "sword" then mul = 1 end
            if typ == "hammer" then mul = 0.5 end
            local face = ent.faceDir or 1
            local phase, t = g.getAttackPhase(ent)
            if phase == "windup" then
                bodyRot = -0.3 * helper.EASINGS.easeInCubic(t)
            elseif phase == "swing" then
                bodyRot = helper.lerp(-0.3, 0.2, helper.EASINGS.easeOutBack(t))
            end
            bodyRot = bodyRot * face * mul
        end
    end
    return bodyRot
end


local DEPLOY_STRETCH_SY = 2.8
local DEPLOY_ANIMATION_DURATION = 0.15

local DEV_SHOW_RANGE = false
DEV_SHOW_RANGE = consts.DEV_MODE and DEV_SHOW_RANGE


---@param ent ecs.Entity
---@param x number
---@param y number
function g.drawEntity(ent, x, y)
    local entScale = g.ask("getEntityScale", ent) * (ent.scale or 1)
    local sx, sy = (ent.sx or 1) * (ent.faceDir or 1) * entScale, (ent.sy or 1) * entScale
    if ent._deployTime then
        local elapsed = love.timer.getTime() - ent._deployTime
        if elapsed < 0 then
            return
        end
        local p = math.min(1, elapsed / DEPLOY_ANIMATION_DURATION)
        sx = sx * (0.3 + 0.7 * p)
        sy = sy * (DEPLOY_STRETCH_SY - (DEPLOY_STRETCH_SY - 1) * p)
    end
    if ent.onDraw then
        ent:onDraw(x, y)
    end
    local bodyRot = getBodyRot(ent)
    local walkBounce, walkWobble = 0, 0
    if ent._walkTime and ent._walkTime > 0 and ent.walkAnimation then
        local wa = assert(ent.walkAnimation)
        local t = ent._walkTime * wa.speed
        walkBounce = -math.abs(math.sin(t)) * wa.bounceHeight
        walkWobble = math.sin(t) * wa.rotationAmount
    end
    local isFlying = g.hasTrait(ent, "flying")
    if isFlying and ent.image then
        local _, h = g.getImageSize(ent.image)
        walkBounce = math.sin(love.timer.getTime() * 1.2 + ent.id * 7.2389) * h * 0.3
        walkWobble = 0
    end
    if ent.image then
        if isFlying then
            lg.setColor(1, 1, 1, ent.alpha or 1)
            local _,h = g.getImageSize(ent.image)
            helper.drawWings(x, (y - h*0.7) + (ent.oy or 0) + walkBounce, love.timer.getTime() + ent.id * 7.2389)
        end
        local HIT_HEAL_COLOR_INDICATOR_DURATION = 0.25
        local col = ent.color or objects.Color.WHITE

        local timeSinceDmgd = ent._timeSinceDamaged or 0xfffffff
        local timeSinceHeald = ent._timeSinceHealed or 0xfffffff
        local timeSince = math.min(timeSinceDmgd, timeSinceHeald)
        local amount = math.max(0, HIT_HEAL_COLOR_INDICATOR_DURATION - timeSince) / HIT_HEAL_COLOR_INDICATOR_DURATION
        if amount > 0 then
            if timeSinceDmgd < timeSinceHeald then
                col = col:lerp(g.COLORS.DAMAGE, amount)
            elseif timeSinceHeald < timeSinceDmgd then
                col = col:lerp(g.COLORS.HEAL, amount)
            end
        end

        lg.setColor(col[1], col[2], col[3], col[4] * (ent.alpha or 1))
        if ent.weapon and ent.weapon.drawBehind then
            drawWeapon(ent,x,y)
        end

        local rot = (ent.rot or 0) + bodyRot + (ent.damageJolt or 0) + walkWobble
        g.drawImageOffset(ent.image, x + (ent.ox or 0), y + (ent.oy or 0) + walkBounce, rot, sx, sy, 0.5, 0.95, ent.kx, ent.ky)

        if ent.onDrawAbove then
            ent:onDrawAbove(x, y)
        end

        if ent.weapon and not ent.weapon.drawBehind then
            drawWeapon(ent,x,y)
        end

        if ent.frozenTime and ent.frozenTime > 0 then
            drawIceCube(ent, x,y, sx,sy)
        end
    end
    if DEV_SHOW_RANGE and ent.attackRange then
        lg.setColor(1,1,1,0.08 * math.min(1, (100/ent.attackRange)))
        lg.circle("line", x,y, ent.attackRange)
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


---@param squadId string
---@param stat string
---@return number
function g.getSquadStatBuff(squadId, stat)
    local squad = g.getSquadFromArmy(squadId)
    local buff = (squad and squad.statBuffs and squad.statBuffs[stat]) or 0
    return buff + g.ask("getSquadStatBuffModifier", squadId, stat)
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

---@param def ecs.Components
---@param x number
---@param y number
local function drawPreviewWeapon(def, x, y)
    local wep = def.weapon
    if not wep then return end

    local _, h = g.getImageSize(def.image)
    if wep.type == "sword" then
        local dx = wep.xOffset or 6
        local dy = wep.yOffset or 0
        local dxx, dyy = helper.fromPolar(0, 7)
        g.drawImageOffset(wep.image, x + dx + dxx, y + dy + dyy - math.floor(h / 5), 0, 1, 1, 0.5, 0.95)
    elseif wep.type == "spear" then
        local dx = wep.xOffset or 10
        g.drawImageOffset(wep.image, x + dx, y - math.floor(h / 5), 0, 1, 1, 0.5, 0.95)
    elseif wep.type == "bow" then
        local dx = wep.xOffset or 8
        local offx, offy = helper.fromPolar(0, 5)
        g.drawImageOffset(wep.image, x + dx + offx, y + offy - math.floor(h / 2), 0, 1, 1, 0.5, 0.5)
    elseif wep.type == "hammer" then
        local radius = wep.arcRadius or (h * 0.6)
        local dxx, dyy = helper.fromPolar(0, radius)
        g.drawImageOffset(wep.image, x + (wep.xOffset or 8) + dxx, y + dyy - math.floor(h / 3), 0, 1, 1, 0.5, 0.95)
    elseif wep.type == "staff" then
        local bob = math.sin(g.getWorldTime() * 2.5) * (wep.weaponBobbing or 1.5)
        g.drawImageOffset(wep.image, x + (wep.xOffset or 8), y + (wep.yOffset or 0) + bob - math.floor(h / 3), 0, 1, 1, 0.5, 0.95)
    end
end

---@param def ecs.Components
---@param x number
---@param y number
---@param scale number
local function drawUnitPreviewScaled(def, x, y, scale)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(scale)

    if def.weapon and def.weapon.drawBehind then
        drawPreviewWeapon(def, 0, 0)
    end
    g.drawImageOffset(def.image, 0, 0, 0, 1, 1, 0.5, 0.95)
    if def.weapon and not def.weapon.drawBehind then
        drawPreviewWeapon(def, 0, 0)
    end

    love.graphics.pop()
end

---@param entityId string
---@param x number
---@param y number
---@param maxW number?
---@param maxH number?
function g.drawUnitPreview(entityId, x, y, maxW, maxH)
    local def = g.getEntityDef(entityId)
    if not def or not def.image then return end
    local bodyW, bodyH = g.getImageSize(def.image)
    if maxW and maxH then
        local scale = math.min(maxW / bodyW, maxH / bodyH)
        local top = y + (maxH - bodyH * scale) / 2
        drawUnitPreviewScaled(def, x + maxW / 2, top + bodyH * scale * 0.95, scale)
    else
        drawUnitPreviewScaled(def, x, y + bodyH * 0.45, 1)
    end
end


---@param id string
---@return ecs.Components
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
---@return love.Font
function g.getBigFont(size)
    assert(size % 16 == 0, "Size must by divisible by 16")
    if not bigCache[size] then
        local f = love.graphics.newFont("assets/fonts/sburbits.ttf", size, "mono", size / 16)
        f:setFallbacks(getFallbackFonts(size))
        bigCache[size] = f
    end
    return bigCache[size]
end

---@param size number
---@return love.Font
function g.getSmallFont(size)
    assert(size % 16 == 0, "Size must by divisible by 16")
    if not smolCache[size] then
        local f = love.graphics.newFont("assets/fonts/sburbits.ttf", size, "mono", size / 16)
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

---@param sceneName string
---@param opts {fadeOut:number?, fadeIn:number?, onSwitch:fun()?}?
function g.transitionTo(sceneName, opts)
    return sceneManager.transitionTo(sceneName, opts)
end


---@return boolean
function g.isAnyPopupOpen()
    return not not (
        rewardPopupService.getActive()
        or choicePopupService.getActive()
        or statUpgradePopupService.getActive()
        or nodeEventService.isActive()
        or gameoverPopupService.isActive()
    )
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

local MOUSE_TARGET_ENEMY_RADIUS = 90
local MOUSE_TARGET_NEUTRAL_RADIUS = 90

local function isMouseHoveringEntity(mx, my, ent)
    local r = 20
    local phys = ent.physics
    if phys then
        if phys.shape == "circle" and phys.radius then
            r = phys.radius
        elseif phys.shape == "rect" and phys.w and phys.h then
            r = math.max(phys.w, phys.h) * 0.5
        end
    elseif ent.image then
        local w, h = g.getImageSize(ent.image)
        r = math.max(w, h) * 0.35
    end
    local dx = ent.x - mx
    local dy = ent.y - my
    return dx * dx + dy * dy <= r * r
end

local function isEnemyFor(requester, other)
    if not requester or not requester.team then
        return other.team == "enemy"
    end
    return other.team and other.team ~= requester.team and other.team ~= "neutral"
end


-- PLAN (redo target selection from scratch):
-- 1) Build candidate list from alive entities with health under mouse-target radius.
-- 2) Split candidates by commander attack range first:
--    - In-range candidates always beat out-of-range candidates.
--    - If no in-range candidate exists, use closest candidate to mouse.
-- 3) If multiple in-range candidates exist, rank by:
--    a) Enemy over neutral.
--    b) Closest to mouse.
--    c) Closest to commander.
-- 4) Use one score pass (no separate neutral safety pass).
-- 5) Return best candidate, else nil.

---@param requester ecs.Entity?
---@return ecs.Entity?
function g.getMouseTargetEntity(requester)
    local ecs = g.tryGetECS()
    if not ecs then return nil end

    local sx, sy = love.mouse.getPosition()
    local mx, my = g.screenToWorld(sx, sy)

    local commander = requester
    if requester and not requester.isCommander then
        local scene = g.getCurrentScene()
        if scene then
            commander = scene.commander
        end
    end

    local commanderX, commanderY, commanderRange2
    if commander and g.isAlive(commander) and commander.attackRange then
        commanderX = commander.x
        commanderY = commander.y
        commanderRange2 = commander.attackRange * commander.attackRange
    end

    local bestCandidate = nil
    local bestScore = -0xfffffffffff

    g.iteratePartition("unit", mx, my, function(ent)
        if not g.isAlive(ent) then return end
        if commander and ent.team == commander.team then return end

        if not ent.health then return end

        local dx, dy = ent.x - mx, ent.y - my
        local mouseD2 = dx * dx + dy * dy

        local commanderD2 = 0
        local inRange = true
        if commanderX and commanderRange2 then
            local cdx, cdy = ent.x - commanderX, ent.y - commanderY
            commanderD2 = cdx * cdx + cdy * cdy
            inRange = commanderD2 <= commanderRange2
        end

        local score
        if inRange then
            -- in-range tiers: enemy > neutral; closer to mouse; closer to commander
            score = 1e18
            if isEnemyFor(commander, ent) then score = score + 1e15 end
            score = score - mouseD2 * 1e3 - commanderD2
        else
            -- out-of-range: just closest to mouse
            score = -mouseD2
        end

        if score > bestScore then
            bestScore = score
            bestCandidate = ent
        end
    end, 200)

    return bestCandidate
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


--- @param x number
--- @param y number
--- @param richtxt string|richtext.ParsedText
--- @param args textPopupService.args?
function g.addWorldTextPopup(x, y, richtxt, args)
    local sx, sy = g.worldToScreen(x, y)
    local t = ui.getUIScalingTransform()
    local ux, uy = t:inverseTransformPoint(sx, sy)
    textPopupService.addPopup(ux, uy, richtxt, args)
end

--- @param x number
--- @param y number
--- @param richtxt any
--- @param args textPopupService.args?
function g.addUITextPopup(x, y, richtxt, args)
    textPopupService.addPopup(x, y, richtxt, args)
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


local _resetCallEventCounts

-- Called once per frame. Clears all handlers, then asks the scene to re-register them.
function g.pollHandlers()
    _resetCallEventCounts()
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



local MAX_EVENT_CALLS_PER_FRAME = consts.MAX_EVENT_CALLS_PER_FRAME -- max 20 events of a single type per frame
local EVENT_COUNTS = {--[[
    [event] -> integer
]]}

function _resetCallEventCounts()
    for k,_ in pairs(EVENT_COUNTS) do
        EVENT_COUNTS[k] = 0
    end
end

-- Fire an event. No return value.
-- Order: global handlers, then ent[ev], then ent.scope
function g.call(ev, arg1, ...)
    local ct = EVENT_COUNTS[ev] or 0
    if ct >= MAX_EVENT_CALLS_PER_FRAME then
        return
    end
    ct = ct + 1; EVENT_COUNTS[ev] = ct

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

---@param tagname string
---@param col objects.Color
local function defineColorTag(tagname, col)
    richtext.defineEffect(tagname, function (args, x, y, context, next)
        local r, gg, b, a = love.graphics.getColor()
        lg.setColor(col[1], col[2], col[3], (col[4] or 1) * a)
        next(context.textOrDrawable, x, y)
        lg.setColor(r, gg, b, a)
    end)
end

---@param id string
---@param name string
---@param color objects.Color
---@return g.Rarity
local function newRarity(id, name, color)
    local lightTextEffect = id .. "_COLOR_LIGHT"
    local darkTextEffect = id .. "_COLOR_DARK"

    local rar = {
        id = id,
        lightTextEffect = "{" .. lightTextEffect .. "}",
        darkTextEffect = "{" .. darkTextEffect .. "}",
        name = loc(name, {}, {
            context = "Represents a rarity."
        }),
        color = color,
        darkColor = darkenColor(color, 0.45),
        lightColor = lightenColor(color, 0.3)
    }
    defineColorTag(darkTextEffect, rar.darkColor)
    defineColorTag(lightTextEffect, rar.lightColor)

    return rar
end


---@enum (key) g.ValidRarities
g.RARITIES = {
    COMMON = newRarity("COMMON", "COMMON", objects.Color.fromByteRGBA(99,99,99)),
    UNCOMMON = newRarity("UNCOMMON", "UNCOMMON", objects.Color.fromByteRGBA(43,105,180)),
    RARE = newRarity("RARE", "RARE", objects.Color.fromByteRGBA(160,62,144)),
    LEGENDARY = newRarity("LEGENDARY", "LEGENDARY", objects.Color.fromByteRGBA(150,100,25)),

    COMMANDER = newRarity("COMMANDER", "COMMANDER", objects.Color.WHITE),
    ALMOST_UNIQUE = newRarity("ALMOST_UNIQUE", "ALMOST UNIQUE", objects.Color.GRAY),
    UNIQUE = newRarity("UNIQUE", "UNIQUE", objects.Color.GRAY),
}


---@class g.Stat
---@field id string
---@field name string
---@field displayName string
---@field description string
---@field shortName string
---@field richText string
---@field baseName string
---@field modQ string
---@field mulQ string
---@field color objects.Color
---@field icon string
---@field isImportant fun(ent:ecs.Entity, stat:string):boolean

---@type g.Stat[]
local STAT_LIST = {}
---@type table<string, g.Stat>
local STAT_DEFS = {}

---@param id string
---@param baseName string
---@param info {displayName:string, description:string, shortName:string, color:objects.Color, icon:string, isImportant:fun(ent:ecs.Components):boolean}
function g.defineStat(id, baseName, info)
    local Name = id:sub(1,1):upper() .. id:sub(2)
    local modQ = "get" .. Name .. "Modifier"
    local mulQ = "get" .. Name .. "Multiplier"
    g.defineQuestion(modQ, reducers.ADD, 0)
    g.defineQuestion(mulQ, reducers.MULTIPLY, 1)
    local col = g.snapToPalette(info.color)
    local r, gg, b = col:getRGBA()
    local stat = {
        id = id,
        name = id,
        displayName = loc(info.displayName, {}, {
            context = "The display name of a unit stat (e.g. Health, Attack Damage)"
        }),
        description = loc(info.description, {}, {
            context = "The description of a unit stat, explaining what it does"
        }),
        shortName = info.shortName,
        richText = string.format("{%s}{c r=%.3f g=%.3f b=%.3f}%s{/c}", info.icon, r, gg, b, info.shortName),
        baseName = baseName,
        modQ = modQ,
        mulQ = mulQ,
        color = col,
        icon = info.icon,
        isImportant = info.isImportant,
    }
    STAT_LIST[#STAT_LIST + 1] = stat
    STAT_DEFS[id] = stat
end



---@param statId string
---@param ent_or_etype string|ecs.Components
function g.isStatImportant(statId, ent_or_etype)
    local stinfo = g.getStatInfo(statId)
    if type(ent_or_etype) == "string" then
        ent_or_etype = assert(g.getEntityDef(ent_or_etype))
    end
    return stinfo.isImportant(ent_or_etype, stinfo)
end

function g.getStatList()
    return STAT_LIST
end

local KEYWORDS = {
    ["BURN"] = loc("{BURN_COLOR}Burn{/BURN_COLOR}", {}, {
        context = "as in, a status-effect. 'Apply 2 BURN', or 'if unit has BURN, do foobar'."
    }),
    ["POISON"] = loc("{POISON_COLOR}Poison{/POISON_COLOR}", {}, {
        context = "as in, a status-effect. 'Apply 2 POISON', or 'if unit has POISON, do foobar'."
    }),
    ["COIN"] = loc("{coin_icon}{GOLD_COLOR}Coin{/GOLD_COLOR}", {}, {
        context = "a unit of currency"
    }),
}

for i=1, 10 do
    KEYWORDS[i.." BURN"] = loc("{BURN_COLOR}%{n} Burn{/BURN_COLOR}", {n = i}, {
        context = "as in, a status-effect. 'Apply %{n} BURN'."
    })
    KEYWORDS[i.." POISON"] = loc("{POISON_COLOR}%{n} Poison{/POISON_COLOR}", {n = i}, {
        context = "as in, a status-effect. 'Apply %{n} POISON'."
    })
end

---@param s string
local function applyLoc2Replace(s)
    local tag = s:sub(2, -2)
    if not tag:find("^[A-Z0-9_]+$") then
        return s
    end

    for _, sinfo in ipairs(g.getStatList()) do
        if sinfo.shortName == tag then
            return sinfo.richText
        end
    end

    if KEYWORDS[tag] then
        return KEYWORDS[tag]
    end

    error("Invalid tag: "..tag)
end

function g.loc2(text, variables, context)
    local result = loc(text, variables or {}, context)
    return (result:gsub("(%b())", applyLoc2Replace))
end


---@param squad g.Squad
---@param stat string
---@param amount number
function g.buffSquadPermanently(squad, stat, amount)
    assert(STAT_DEFS[stat], "unknown stat: " .. tostring(stat))
    squad.statBuffs = squad.statBuffs or {}
    squad.statBuffs[stat] = (squad.statBuffs[stat] or 0) + amount
end

---@param ent ecs.Entity
---@param stat string
---@param increase number
---@param fromEnt ecs.Entity?
function g.buffEntity(ent, stat, increase, fromEnt)
    assert(STAT_DEFS[stat], "unknown stat: " .. tostring(stat))
    ent.buffs = ent.buffs or {}
    ent.buffs[stat] = (ent.buffs[stat] or 0) + increase
    g.call("entityBuffed", ent, stat, increase, fromEnt)
    if fromEnt and fromEnt ~= ent then
        local color = STAT_DEFS[stat].color
        juiceService.spawnArc(color, fromEnt.x, fromEnt.y, ent.x, ent.y, ent)
    end
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
    POISON = objects.Color("FF530C63"),
    HEALTH = objects.Color("FF397634"),
    ATTACK = objects.Color("FFA2741E"),

    MAP_GROUND_COLOR = objects.Color("FF0B0C0B"),
    BATTLE_GROUND_COLOR = objects.Color("FF2C2929"),

    REROLL = g.snapToPalette(0.1,1,0.05),

    GOLD = objects.Color("FFD8B01F"),
    XP = objects.Color("FF2BC66E"),
    KEY = g.snapToPalette(objects.Color("FF755555")),
    BLESSING = g.snapToPalette(objects.Color("FFBF2A90")),
    DARK_UI = objects.Color("FF0c0c19"),
    DEMON_FURY = g.snapToPalette(objects.Color("FF991A1A")),
}

for k,v in pairs(g.COLORS) do
    defineColorTag(k.."_COLOR", v)
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
    shortName = "HP",
    color = objects.Color(0.3, 0.9, 0.3),
    icon = "health",
    isImportant = _alwaysImportant,
})
g.defineStat("attackDamage", "baseAttackDamage", {
    displayName = "Attack Damage",
    description = "Damage per attack",
    shortName = "ATK",
    color = objects.Color(0.95, 0.3, 0.3),
    icon = "damage",
    isImportant = _alwaysImportant,
})
g.defineStat("healPower", "baseHealPower", {
    displayName = "Heal Power",
    description = "Healing per attack",
    shortName = "HEAL",
    color = objects.Color(0.3, 0.95, 0.6),
    icon = "healpower",
    isImportant = _importantIfNonZero,
})
g.defineStat("magic", "baseMagic", {
    displayName = "Magic",
    description = "Strength of magic (doesn't do anything on it's own)",
    shortName = "MAGK",
    color = objects.Color(0.1, 0.35, 0.9),
    icon = "magic_icon2",
    isImportant = _importantIfNonZero,
})
g.defineStat("attackSpeed", "baseAttackSpeed", {
    displayName = "Attack Speed",
    description = "Attacks per second",
    shortName = "ASPD",
    color = objects.Color(0.95, 0.85, 0.3),
    icon = "atkspeed",
    isImportant = _importantIfRanged,
})
g.defineStat("lifesteal", "baseLifesteal", {
    displayName = "Lifesteal",
    description = "Health gained per attack damage dealt",
    shortName = "LIFESTEAL",
    color = objects.Color(0.7, 0.2, 0.4),
    icon = "damage",
    isImportant = _importantIfNonZero,
})
g.defineStat("moveSpeed", "baseMoveSpeed", {
    displayName = "Move Speed",
    description = "Movement speed",
    shortName = "SPD",
    color = objects.Color(0.4, 0.7, 0.95),
    icon = "movespeed",
    isImportant = _importantIfMelee,
})
g.defineStat("attackRange", "baseAttackRange", {
    displayName = "Attack Range",
    description = "Range of attacks",
    shortName = "RANGE",
    color = objects.Color(0.8, 0.5, 0.2),
    icon = "range",
    isImportant = _importantIfRanged,
})
g.defineStat("startingArmor", "baseStartingArmor", {
    displayName = "Armor",
    description = "Number of hits that are blocked before losing health.",
    shortName = "ARMR",
    color = objects.Color(0.3, 0.4, 0.7),
    icon = "armor",
    isImportant = _importantIfNonZero,
})
g.defineStat("projectileAccuracy", "baseProjectileAccuracy", {
    displayName = "Accuracy",
    description = "Projectile accuracy",
    shortName = "ACC",
    color = objects.Color(0.9, 0.9, 0.9),
    icon = "hourglass_icon",
    isImportant = _importantIfRanged,
})






-- built-in traits:

g.defineTrait("flying", "Flying", {
    description = loc("Can be deployed anywhere on the battlefield."),
    deployAnywhere = true,
    color = g.snapToPalette(1,1,1),
})

g.defineTrait("fireproof", "Fireproof", {
    description = loc("Immune to burning."),
    handlers = {
        getBurnDPSMultiplier = function(ent)
            return 0
        end,
    },
    color = g.snapToPalette(1,0,0),
})

g.defineTrait("loyal", "Loyal", {
    description = loc("A loyal unit."),
    color = g.snapToPalette(0,1,0),
})

g.defineTrait("fishfolk", "Fishfolk", {
    description = loc("Immune to burning."),
    handlers = {
        getBurnDPSMultiplier = function(ent)
            return 0
        end,
    },
    color = g.snapToPalette(0.2,0.2,1),
})

g.defineTrait("human", "Human", {
    description = loc("A human unit"),
    color = g.snapToPalette(0,1,0),
})

g.defineTrait("bot", "Bot", {
    description = loc("A robot unit"),
    color = g.snapToPalette(1,1,0),
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
    -- HACK: colorless. Only total count matters.
    local totalNeed = (manaRequirement.blue or 0) + (manaRequirement.green or 0)
        + (manaRequirement.red or 0) + (manaRequirement.yellow or 0)

    if getTotalManaCount(manaCounts) < totalNeed then return nil end

    local kept = {}
    for k, v in pairs(manaCounts or {}) do
        kept[k] = v
    end

    local needLeft = totalNeed
    for k, v in pairs(kept) do
        if needLeft <= 0 then break end
        local used = math.min(v, needLeft)
        needLeft = needLeft - used
        kept[k] = (v - used > 0) and (v - used) or nil
    end

    return kept
end

--[[ OLD color-aware version:
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
]]




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

    local idup = id:upper()
    defineColorTag(idup .. "_MANA_COLOR", color)
    local rt = string.format(
        "{%s}{%s} %s Mana{/%s}",
        idup.."_MANA_COLOR",
        mana_small,
        id:sub(1, 1):upper()..id:sub(2), -- Capitalize
        idup.."_MANA_COLOR"
    )
    KEYWORDS[idup .. "_MANA"] = loc(rt, {}, {context = "Mana is a currency used to spawn squad and spells"})
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

g.defineManaType("red", g.snapToPalette(objects.Color("FFB42430")))
g.defineManaType("blue", g.snapToPalette(objects.Color("FF1C7CB7")))
g.defineManaType("green", g.snapToPalette(objects.Color("FF52B225")))
g.defineManaType("yellow", g.snapToPalette(objects.Color("FFD0D31F")))

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
---@return number smallWidth
---@return number largeWidth
function g.getManaCostWidth(bundle)
    local count = 0
    for _, manaType in ipairs(manaTypeList) do
        local n = bundle[manaType]
        if n and n > 0 then count = count + n end
    end
    if count == 0 then return 0,0 end
    local manaInfo = manaInfos[manaTypeList[1]]
    local ws = g.getImageSize(manaInfo.image)
    local wl = g.getImageSize(manaInfo.imageLarge)
    return count * ws, count * wl
end

---@param bundle g.ManaBundle
---@param x number
---@param y number
---@param w number?
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

    local qw = g.getImageSize(manaInfos[beads[1]].image)
    local spacing = math.min(qw, count > 1 and (w - qw) / (count - 1) or qw)
    local startX = x - (count - 1) * spacing / 2

    for i, manaType in ipairs(beads) do
        g.drawImage(manaInfos[manaType].image, startX + (i - 1) * spacing, y)
    end
end

---@param bundle g.ManaBundle
---@param x number
---@param y number
---@param w number?
function g.drawManaCostLarge(bundle, x, y, w)
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

    local qw = g.getImageSize(manaInfos[beads[1]].imageLarge)
    local spacing = math.min(qw, count > 1 and (w - qw) / (count - 1) or qw)
    local startX = x - (count - 1) * spacing / 2

    for i, manaType in ipairs(beads) do
        g.drawImage(manaInfos[manaType].imageLarge, startX + (i - 1) * spacing, y)
    end
end



return g
