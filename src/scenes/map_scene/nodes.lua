local Class = require("src.modules.objects.Class")



local SHOP_TXT = loc("Shop: Spend money, upgrade squads")

local BATTLE_TXTS = {
    -- demonEncounter difficulty => pool of flavor names
    [0] = {
        loc("Battle: Demon Scouts (I)"),
        loc("Battle: Demon Stragglers (I)"),
        loc("Battle: Demon Whelps (I)"),
        loc("Battle: Imp Rabble (I)"),
        loc("Battle: Hellspawn Scouts (I)"),
        loc("Battle: Cursed Vagrants (I)"),
    },
    [1] = {
        loc("Battle: Demon Squad (II)"),
        loc("Battle: Demon Warband (II)"),
        loc("Battle: Infernal Patrol (II)"),
        loc("Battle: Brimstone Raiders (II)"),
        loc("Battle: Hellhound Pack (II)"),
        loc("Battle: Demon Marauders (II)"),
    },
    [2] = {
        loc("Battle: Demon Army (III)"),
        loc("Battle: Demon Legion (III)"),
        loc("Battle: Infernal Host (III)"),
        loc("Battle: Hellfire Horde (III)"),
        loc("Battle: Abyssal Vanguard (III)"),
        loc("Battle: Doom Battalion (III)"),
    },
}

local EVENT_TXT = loc("Random event!")

local FOUNTAIN_TXT = loc("Fountain: Reduces Demon-Fury")

local SHRINE_TXT = loc("Shrine: Gain Blessings, Sacrifice Squads")

local FEAST_TXT = loc("Feast: Obtain XP")

local CAMPFIRE_TXT = loc("Campfire: Obtain XP")



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
    love.graphics.setColor(g.COLORS.MAP_EDGE:getRGBA())
    love.graphics.ellipse("fill", wx, wy, 4, 2)
end

---@param builder g.DecorBuilder
---@param wx number
---@param wy number
function Node:buildDecor(builder, wx, wy)
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
---@param builder g.DecorBuilder
---@param x number
---@param y number
local function addDemons(node, builder, x, y)
    if node.demonEncounter then
        local count = node.demonEncounter + 1
        local baseAngle = hashf(node.id) * math.pi * 2
        for i = 1, count do
            local angle = baseAngle + (i - 1) * (math.pi * 2 / count)
            local angleOff = (hashf(node.id, i) - 0.5) * 0.4
            local radiusMul = 0.85 + hashf(node.id, i, 1) * 0.3
            if count == 1 then
                radiusMul = radiusMul * 0.3
            elseif count == 2 then
                radiusMul = radiusMul * 0.6
            end
            local r = 20 * radiusMul
            local a = angle + angleOff
            builder:addImage("node_combat_demon", x + math.cos(a) * r, y + math.sin(a) * r)
        end

        if node.demonEncounter >= 2 then
            -- its a "boss" encounter, add a flag.
            builder:addImage("node_combat_flag", x-14, y-2, 0, 1)
        end
    end
end

-------------------------------
-- BattleNode
-------------------------------
---@class MapNode.BattleNode: MapNode
---@field demonEncounter integer
local BattleNode = nodes.newClass("battle")

function BattleNode:init(x,y)
    Node.init(self,x,y)
    self.demonEncounter = 0
end

function BattleNode:enter()
    g.gotoScene("battle_scene")
end

function BattleNode:getHoverDescription()
    local pool = BATTLE_TXTS[self.demonEncounter] or BATTLE_TXTS[0]
    return pool[hash(self.id) % #pool + 1]
end

function BattleNode:drawBelow(wx, wy)
    love.graphics.setColor(g.COLORS.MAP_EDGE:getRGBA())
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

function FeastNode:enter()
    local run = g.getRun()
end

function FeastNode:getHoverDescription()
    return FEAST_TXT
end

function FeastNode:buildDecor(builder, wx, wy)
    builder:addImage("node_banquet", wx, wy)
    addDemons(self, builder, wx, wy)
end

nodes.FeastNode = FeastNode


-------------------------------
-- FountainNode
-------------------------------
---@class MapNode.FountainNode: MapNode
local FountainNode = nodes.newClass("fountain")

function FountainNode:enter()
end

function FountainNode:getHoverDescription()
    return FOUNTAIN_TXT
end

function FountainNode:buildDecor(builder, wx, wy)
    builder:addImage("node_fountain", wx, wy)
    addDemons(self, builder, wx, wy)
end

nodes.FountainNode = FountainNode




-------------------------------
-- EmptyNode
-------------------------------
---@class MapNode.EmptyNode: MapNode
local EmptyNode = nodes.newClass("empty")

function EmptyNode:enter()
    -- this node does nothing.
end

function EmptyNode:drawBelow(wx, wy)
    love.graphics.setColor(g.COLORS.MAP_EDGE:getRGBA())
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
    nodeEventService.startRandomEvent()
end

function EventNode:getHoverDescription()
    return EVENT_TXT
end

function EventNode:drawBelow(wx, wy)
    love.graphics.setColor(g.COLORS.MAP_EDGE:getRGBA())
    love.graphics.ellipse("fill", wx, wy, 9, 5)
    love.graphics.setColor(g.COLORS.MAP_GROUND_COLOR:getRGBA())
    love.graphics.ellipse("fill", wx, wy, 6, 3)
end

local QCOL

function EventNode:buildDecor(builder, wx,wy)
    builder:addDrawable(wx,wy, function(x, y)
        QCOL = QCOL or g.snapToPalette(objects.Color("FFED8014"))
        local font = g.getBigFont(48)
        local bobY = math.sin(love.timer.getTime()) * 3
        lg.setColor(QCOL)
        richtext.printRichCentered("{o}?", font, x, y+bobY, 100, "left")
    end)
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
    g.gotoScene("shop_scene")
    local sc = g.getCurrentScene()
    ---@cast sc g.ShopScene
    sc:setShop(self)
end

function ShopNode:getHoverDescription()
    return SHOP_TXT
end

function ShopNode:buildDecor(builder, wx, wy)
    builder:addImage("node_town", wx, wy - 8)
end




return nodes
