local Class = require("src.modules.objects.Class")



local SHOP_TXT = loc("Shop: Spend money, upgrade squads")

local BATTLE_TXTS = {
    -- demonEncounter difficulty => pool of flavor names
    [0] = {
        loc("Demon Scouts (I)"),
        loc("Demon Stragglers (I)"),
        loc("Demon Whelps (I)"),
        loc("Imp Rabble (I)"),
        loc("Hellspawn Scouts (I)"),
        loc("Cursed Vagrants (I)"),
    },
    [1] = {
        loc("Demon Squad (II)"),
        loc("Demon Warband (II)"),
        loc("Infernal Patrol (II)"),
        loc("Brimstone Raiders (II)"),
        loc("Hellhound Pack (II)"),
        loc("Demon Marauders (II)"),
    },
    [2] = {
        loc("Demon Army (III)"),
        loc("Demon Legion (III)"),
        loc("Infernal Host (III)"),
        loc("Hellfire Horde (III)"),
        loc("Abyssal Vanguard (III)"),
        loc("Doom Battalion (III)"),
    },
}

local FOUNTAIN_TXT = loc("Fountain: Reduces Demon Fury")

local SHRINE_TXT = loc("Shrine: Sacrifice Squads to lower Demon Fury")

local FEAST_TXT = loc("Feast: Obtain {xp_icon}")

local CHEST_TXT = loc("Chest: Claim a reward")
local CHEST_NEEDS_KEY_TXT = CHEST_TXT .. "\n{c r=0.9 g=0.2 b=0.2}" .. loc("(requires Key!)")
local CHEST_HAS_KEY_TXT = CHEST_TXT .. "\n{c r=0.2 g=0.9 b=0.2}" .. loc("(unlock with a Key!)")

local CAMPFIRE_TXT = loc("Campfire: Obtain XP")

local PORTAL_ACTIVE_TXT = loc("Portal: Go to random node")
local PORTAL_INACTIVE_TXT = loc("Portal: Inactive")

local NODE_FADE_OUT = consts.NODE_FADE_OUT
local NODE_FADE_IN = consts.NODE_FADE_IN
local VISITED_NODE_OPACITY = 0.45



---@class MapNode: objects.Class
---@field x integer grid x
---@field y integer grid y
---@field id integer random id
---@field demonEncounter integer? (0 1 2) TODO in future, maybe demon-encounters can exist on any kind of node?
---@field ox number visual offset x
---@field oy number visual offset y
---@field nodeType string the type of node it is
---@field visited boolean? Has this node been visited or not?
---@field seen boolean? Has this node been revealed from fog?
local Node = Class("g:MapNode")

function Node:init(x, y)
    self.x = x
    self.y = y
    self.ox = 0
    self.oy = 0
end

function Node:enter()
end

---@return string?
function Node:getHoverDescription()
    return nil -- 
    --- return loc("blah blah")
end



---@param wx number world x
---@param wy number world y
function Node:drawBelow(wx, wy)
    love.graphics.setColor(g.getMapType().mapPath)
    love.graphics.ellipse("fill", wx, wy, 4, 2)
end

---@param builder g.DecorBuilder
---@param wx number
---@param wy number
function Node:buildDecor(builder, wx, wy)
end

---@param dt number
function Node:update(dt)
end


-- Registry + module
local nodes = {}
local NODE_TYPES = {}

--- Create a new node subclass and register it.
---@param id string
---@return MapNode
function nodes.newClass(id)
    local cls = Class("g:MapNode." .. id):implement(Node)
    ---@cast cls any
    cls.nodeType = id
    NODE_TYPES[id] = cls
    return cls
end

---@param id string
---@return MapNode?
function nodes.getClass(id)
    return NODE_TYPES[id]
end

---@param node MapNode
---@return string
function nodes.getType(node)
    return getmetatable(node).nodeType
end


nodes.Node = Node





-- rudimentary hash; takes any number of integer keys
local function hash(...)
    local h = 2654435761
    for i = 1, select("#", ...) do
        h = bit.bxor(h * 73856093 + select(i, ...) * 19349663, 0x5bd1e995)
    end
    return math.abs(h)
end

-- returns 0..1 deterministic float
local function hashf(...)
    return (hash(...) % 10000) / 10000
end

---@param node MapNode
local function nodeOpacity(node)
    if node.visited then
        return VISITED_NODE_OPACITY
    end
    return 1
end


local function addDemons(node, builder, x, y)
    if node.demonEncounter then
        local count = node.demonEncounter + 1
        local baseAngle = hashf(node.x, node.y) * math.pi * 2
        for i = 1, count do
            local angle = baseAngle + (i - 1) * (math.pi * 2 / count)
            local angleOff = (hashf(node.x, node.y, i) - 0.5) * 0.4
            local radiusMul = 0.85 + hashf(node.x, node.y, i, 1) * 0.3
            if count == 1 then
                radiusMul = radiusMul * 0.3
            elseif count == 2 then
                radiusMul = radiusMul * 0.6
            end
            local r = 20 * radiusMul
            local a = angle + angleOff
            local phase = hashf(node.x, node.y, i) * math.pi * 2
            local sx = hashf(node.x, node.y, i, 2) < 0.5 and -1 or 1

            local function bobMod()
                local sy = 1 + math.sin(phase + love.timer.getTime()) * 0.12
                return 0, 0, 0, 1, sy, 0, 0
            end
            builder:addImage("node_combat_demon", x + math.cos(a) * r, y + math.sin(a) * r, 0, sx, nodeOpacity(node), bobMod)
        end

        if node.demonEncounter >= 2 then
            -- its a "boss" encounter, add a flag.
            builder:addImage("node_combat_flag", x-14, y-2, 0, 1, nodeOpacity(node))
        end
    end
end

-------------------------------
-- Bonus rewards (shown on hover, granted on battle win)
-------------------------------
--- Turn a reward descriptor into a richtext line for the hover tooltip.
---@param r g.RewardPanel.ORReward|g.RewardPanel.Any
---@return string
local function describeReward(r)
    if r.type == "gold" then
        return "{GOLD_COLOR}Bonus rewards:{/GOLD_COLOR} {coin_icon}{GOLD_COLOR} +" .. r.amount
    elseif r.type == "xp" then
        return "{XP_COLOR}Bonus rewards:{/XP_COLOR} {xp_icon}{XP_COLOR} +" .. r.amount
    elseif r.type == "blessing" then
        return "Bonus rewards:\nRandom Blessing {blessing_icon}"
    elseif r.type == "keys" then
        return "Bonus rewards: {key_icon} +" .. (r.amount or 1)
    end
    return ""
end

-------------------------------
-- BattleNode
-------------------------------
---@class MapNode.BattleNode: MapNode
---@field demonEncounter integer
---@field rewards g.RewardPanel.Rewards bonus rewards granted on win (rolled by MapGraph based on difficulty)
local BattleNode = nodes.newClass("battle")

function BattleNode:init(x,y)
    Node.init(self,x,y)
    self.demonEncounter = 0
    self.rewards = {}
end

function BattleNode:enter()
    g.transitionTo("battle_scene")
end

function BattleNode:getHoverDescription()
    local pool = BATTLE_TXTS[self.demonEncounter] or BATTLE_TXTS[0]
    local desc = pool[hash(self.id) % #pool + 1]
    for _, r in ipairs(self.rewards) do
        desc = desc .. "\n" .. describeReward(r)
    end
    return desc
end

function BattleNode:drawBelow(wx, wy)
    love.graphics.setColor(g.getMapType().mapPath)
    love.graphics.ellipse("fill", wx, wy, 8, 5)
    love.graphics.setColor(0.8, 0.3, 0.3, 1)
    love.graphics.ellipse("fill", wx, wy, 6, 3)
end

function BattleNode:buildDecor(builder, wx, wy)
    if not self.visited then
        addDemons(self, builder, wx, wy)
    end
end

nodes.BattleNode = BattleNode


-------------------------------
-- FeastNode
-------------------------------
---@class MapNode.FeastNode: MapNode
local FeastNode = nodes.newClass("feast")

---@type table<MapNode.FeastNode, love.graphics.ParticleSystem?>
local firePSes = setmetatable({}, {__mode = "k"})

function FeastNode:enter()
    fadeToBlackService.fadeToFromBlack(NODE_FADE_OUT, function()
        nodeEventService.openFeastPopup(self)
    end, NODE_FADE_IN)
end

function FeastNode:getHoverDescription()
    return FEAST_TXT
end

function FeastNode:update(dt)
    local firePS = firePSes[self]
    if not firePS then
        firePS = love.graphics.newParticleSystem(g.getAtlas())
        firePS:setQuads({
            g.getImageQuad("particle_4"),
            g.getImageQuad("particle_3"),
            g.getImageQuad("particle_2"),
            g.getImageQuad("particle_1"),
            g.getImageQuad("particle_2"),
            g.getImageQuad("particle_1")
        })
        firePS:setParticleLifetime(0.5, 0.8)
        firePS:setEmissionArea("uniform", 5, 3)
        firePS:setColors(
            {1, 1, 0},
            {1, 0.5, 0},
            {0.8, 0.2, 0},
            {0.4,0.4,0.4},
            {0.6,0.6,0.6}
        )
        firePS:setDirection(-math.pi/2)
        firePS:setSpread(0.2)
        firePS:setEmissionRate(15)
        firePS:setSpeed(10, 23)
        firePSes[self] = firePS
    end
    firePS:update(dt)
end

function FeastNode:buildDecor(builder, wx, wy)
    builder:addImage("node_banquet", wx, wy, 0, nil, nodeOpacity(self))
    local firePS = firePSes[self]
    if firePS and not self.visited then
        builder:addDrawable(wx + 1, wy - 20, function(x, y)
            love.graphics.draw(firePS, x, y)
        end, 100)
    end

    addDemons(self, builder, wx, wy)
end

nodes.FeastNode = FeastNode


-------------------------------
-- ShrineNode
-------------------------------
---@class MapNode.ShrineNode: MapNode
local ShrineNode = nodes.newClass("shrine")

function ShrineNode:enter()
    fadeToBlackService.fadeToFromBlack(NODE_FADE_OUT, function()
        nodeEventService.openShrinePopup(self)
    end, NODE_FADE_IN)
end

function ShrineNode:getHoverDescription()
    return SHRINE_TXT
end

---@param x number
---@param y number
---@param opacity number
local function drawShrineAnimated(x, y, opacity)
    local t = love.timer.getTime()
    local t1 = math.sin(t * 3) * 2
    local col = gsman.setColor(1, 1, 1, opacity)
    g.drawImageOffset("node_shrine_base", x, y + 4, 0, 1, 1, 0.5, 1)
    helper.drawWings(x, y - 32, t, "node_shrine_wing", {
        scale = 1,
        distance = -22,
        rotation = math.pi / 6,
        rotationOffset = -math.pi / 12,
        verticalOffsetMultiplier = 0.3,
    })
    g.drawImage("node_shrine_body", x, y - 26 + t1)
    col:pop()
end
function ShrineNode:buildDecor(builder, wx, wy)
    builder:addDrawable(wx, wy, function(x, y)
        drawShrineAnimated(x, y, nodeOpacity(self))
    end)
    addDemons(self, builder, wx, wy)
end

nodes.ShrineNode = ShrineNode


-------------------------------
-- FountainNode
-------------------------------
---@class MapNode.FountainNode: MapNode
local FountainNode = nodes.newClass("fountain")

function FountainNode:enter()
    fadeToBlackService.fadeToFromBlack(NODE_FADE_OUT, function()
        nodeEventService.openFountainPopup(self)
    end, NODE_FADE_IN)
end

function FountainNode:getHoverDescription()
    return FOUNTAIN_TXT
end

function FountainNode:buildDecor(builder, wx, wy)
    builder:addImage("node_fountain", wx, wy, 0, nil, nodeOpacity(self))
    addDemons(self, builder, wx, wy)
end

nodes.FountainNode = FountainNode


-------------------------------
-- ChestNode
-------------------------------
---@class MapNode.ChestNode: MapNode
local ChestNode = nodes.newClass("chest")

function ChestNode:enter()
    fadeToBlackService.fadeToFromBlack(NODE_FADE_OUT, function()
        nodeEventService.openChestPopup(self)
    end, NODE_FADE_IN)
end

function ChestNode:getHoverDescription()
    if g.getRun().keys > 0 then
        return CHEST_HAS_KEY_TXT
    end
    return CHEST_NEEDS_KEY_TXT
end

function ChestNode:buildDecor(builder, wx, wy)
    builder:addImage("node_chest", wx, wy, 0, nil, nodeOpacity(self))
    addDemons(self, builder, wx, wy)
end

nodes.ChestNode = ChestNode




-------------------------------
-- EmptyNode
-------------------------------
---@class MapNode.EmptyNode: MapNode
local EmptyNode = nodes.newClass("empty")

function EmptyNode:enter()
    -- this node does nothing.
end

function EmptyNode:drawBelow(wx, wy)
    love.graphics.setColor(g.getMapType().mapPath)
    love.graphics.ellipse("fill", wx, wy, 9, 5)
    love.graphics.setColor(g.COLORS.MAP_GROUND_COLOR:getRGBA())
    love.graphics.ellipse("fill", wx, wy, 6, 3)
end

nodes.EmptyNode = EmptyNode





-------------------------------
-- EventNode
-------------------------------
---@class MapNode.EventNode: MapNode
local EventNode = nodes.newClass("event")

function EventNode:enter()
    fadeToBlackService.fadeToFromBlack(NODE_FADE_OUT, function()
        nodeEventService.startRandomEvent()
    end, NODE_FADE_IN)
end

function EventNode:drawBelow(wx, wy)
    love.graphics.setColor(g.getMapType().mapPath)
    love.graphics.ellipse("fill", wx, wy, 9, 5)
    love.graphics.setColor(g.COLORS.MAP_GROUND_COLOR:getRGBA())
    love.graphics.ellipse("fill", wx, wy, 6, 3)
end

local function drawDebugCircleForRandomEvent(x, y)
    local col = gsman.setColor(1, 1, 1)
    lg.circle("line", x, y, 6)
    col:pop()
end

function EventNode:buildDecor(builder, wx,wy)
    if consts.SHOW_DEV_STUFF then
        builder:addDrawable(wx,wy, drawDebugCircleForRandomEvent)
    end
end

nodes.EventNode = EventNode






-------------------------------
--- shop node
-------------------------------
---@class MapNode.ShopNode: MapNode
---@field squadShop (false|string)[]
---@field blessingShop (false|string)[]
---@field isSetup boolean?
local ShopNode = nodes.newClass("shop")

local shop_scene

function ShopNode:init(x,y)
    shop_scene = shop_scene or require("src.scenes.shop_scene.shop_scene")
    Node.init(self,x,y)
    self.squadShop = {}
    self.blessingShop = {}
    shop_scene.prefillShopNode(self)
end

function ShopNode:enter()
    shop_scene = shop_scene or require("src.scenes.shop_scene.shop_scene")
    shop_scene.prefillShopNode(self)
    g.transitionTo("shop_scene", {
        fadeOut = NODE_FADE_OUT,
        fadeIn = NODE_FADE_IN,
        onSwitch = function()
            local sc = g.getCurrentScene()
            ---@cast sc g.ShopScene
            sc:setShop(self)
        end
    })
end

function ShopNode:getHoverDescription()
    return SHOP_TXT
end

function ShopNode:buildDecor(builder, wx, wy)
    builder:addImage("node_town", wx, wy - 8, 0, nil, nodeOpacity(self))
end

nodes.ShopNode = ShopNode




-------------------------------
-- Dynamic Node
-------------------------------

local FOGS = {
    "fog_of_war_cloud1",
    "fog_of_war_cloud2",
    "fog_of_war_cloud3",
}

---@class MapNode.DynamicNode: MapNode
local DynamicNode = nodes.newClass("dynamic")

function DynamicNode:enter()
    error("forgot to roll dynamic node!")
end

---@param x number
---@param y number
local function drawFog(x, y)
    local fogColor = g.getMapType().fogColor
    local col = gsman.setColor(g.snapToPalette(fogColor))
    local state = helper.hashIntegerPair(x, y) % 65536
    local t = love.timer.getTime()
    for i = 1, 6 do
        local rot = math.sin(t + (i % 100) / 100)
        local fx = helper.lerp(-15, 15, state / 65536)
        state = helper.hashInteger(state) % 65536
        local fy = helper.lerp(-15, 15, state / 65536)
        state = helper.hashInteger(state) % 65536
        g.drawImage(FOGS[state % #FOGS + 1], x + fx, y + fy, rot)
        state = helper.hashInteger(state) % 65536
    end
    col:pop()
end

function DynamicNode:buildDecor(builder, wx, wy)
    builder:addDrawable(wx, wy, drawFog)
end

nodes.DynamicNode = DynamicNode


-------------------------------
-- Portal Node
-------------------------------

---@class MapNode.PortalNode: MapNode
local PortalNode = nodes.newClass("portal")

---@type table<MapNode.PortalNode, love.graphics.ParticleSystem?>
local portalPSes = setmetatable({}, {__mode = "k"})
local PORTAL_COLORS = {
    objects.Color.WHITE,
    objects.Color("#c852a4"),
    objects.Color("#4f2d5d"),
    objects.Color("00140e12"),
}

function PortalNode:init(x,y)
    Node.init(self,x,y)
    self.active = true
end

function PortalNode:enter()
    fadeToBlackService.fadeToFromBlack(NODE_FADE_OUT, function()
        nodeEventService.openPortalPopup(self)
    end, NODE_FADE_IN)
end

function PortalNode:update(dt)
    if not self.active then
        return
    end

    local portalPS = portalPSes[self]
    if not portalPS then
        portalPS = love.graphics.newParticleSystem(g.getAtlas(), 1000)
        portalPS:setQuads({
            g.getImageQuad("particle_1"),
            g.getImageQuad("particle_2"),
            g.getImageQuad("particle_3"),
            g.getImageQuad("particle_4"),
        })
        portalPS:setEmissionRate(10)
        portalPS:setEmissionArea("uniform", 30, 30)
        portalPS:setParticleLifetime(1.5, 2)
        portalPS:setSizes(0.5)
        --portalPS:setDirection(2.2)
        portalPS:setSpread(3)
        portalPS:setRadialAcceleration(-20, -20)
        portalPS:setTangentialAcceleration(20, 20)
        portalPS:setRotation(0, consts.TAU)
        portalPS:setSpin(1, 4)
        portalPS:setSpinVariation(0.3)
        portalPS:setColors(unpack(PORTAL_COLORS))
        portalPSes[self] = portalPS
    end
    portalPS:update(dt)
end

function PortalNode:buildDecor(builder, wx, wy)
    if self.active then
        builder:addImage("node_portal", wx, wy, 0, nil, nodeOpacity(self))
        local portalPS = portalPSes[self]
        if portalPS then
            builder:addDrawable(wx, wy - 24, function(x, y)
                love.graphics.draw(portalPS, x, y)
            end, 100)
        end
    else
        builder:addImage("node_portal_deactivated", wx, wy, 0, nil, nodeOpacity(self))
    end
end

function PortalNode:getHoverDescription()
    return self.active and PORTAL_ACTIVE_TXT or PORTAL_INACTIVE_TXT
end

nodes.PortalNode = PortalNode



return nodes
