local Class = require("src.modules.objects.Class")

---@class MapNode: objects.Class
---@field x integer grid x
---@field y integer grid y
---@field id integer random id
---@field demonEncounter integer? (0 1 2) Demon-encounters can exist on any kind of node
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

---@param wx number world x
---@param wy number world y
function Node:draw(wx, wy)
    love.graphics.setColor(g.COLORS.MAP_EDGE:getRGBA())
    love.graphics.ellipse("fill", wx, wy, 4, 2)
end

---@param wx number world x
---@param wy number world y
function Node:drawBelow(wx, wy)
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





local DEMON_DISTANCE = 20
local DEMON_OY = -10

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
---@param x number
---@param y number
local function tryDrawDemons(node, x,y)
    if node.demonEncounter then
        local count = node.demonEncounter + 1
        local baseAngle = hashf(node.id) * math.pi * 2
        for i = 1, count do
            local angle = baseAngle + (i - 1) * (math.pi * 2 / count)
            local angleOff = (hashf(node.id, i) - 0.5) * 0.4
            local radiusMul = 0.85 + hashf(node.id, i, 1) * 0.3
            local r = DEMON_DISTANCE * radiusMul
            local a = angle + angleOff
            g.drawImage("node_combat_demon", x + math.cos(a) * r, y + DEMON_OY + math.sin(a) * r)
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
    --[[
    relative difficulty of node, relative to current level:
    0 = normal enemy
    1 = harder enemy
    2 = elite-level enemy
    ]]
end

function BattleNode:enter()
    g.gotoScene("battle_scene")
end

function BattleNode:draw(wx, wy)
    love.graphics.setColor(g.COLORS.MAP_EDGE:getRGBA())
    love.graphics.ellipse("fill", wx, wy, 8, 5)
    love.graphics.setColor(0.8, 0.3, 0.3, 1)
    love.graphics.ellipse("fill", wx, wy, 6, 3)
    if not self.visited then
        g.drawImage("node_combat_flag", wx-14, wy-20)
        tryDrawDemons(self, wx,wy)
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

function FeastNode:draw(wx, wy)
    lg.setColor(1,1,1)
    local sx = self.id%2==0 and 1 or -1
    g.drawImage("node_banquet", wx, wy, 0, sx,1)
    tryDrawDemons(self, wx,wy)
end

nodes.FeastNode = FeastNode


-------------------------------
-- FountainNode
-------------------------------
---@class MapNode.FountainNode: MapNode
local FountainNode = nodes.newClass("fountain")

function FountainNode:enter()
end

function FountainNode:draw(wx, wy)
    lg.setColor(1,1,1)
    g.drawImage("node_fountain", wx, wy)
    tryDrawDemons(self, wx,wy)
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

function EmptyNode:draw(wx, wy)
    love.graphics.setColor(g.COLORS.MAP_EDGE:getRGBA())
    love.graphics.ellipse("fill", wx, wy, 9, 5)
    love.graphics.setColor(g.COLORS.MAP_GROUND_COLOR:getRGBA())
    love.graphics.ellipse("fill", wx, wy, 6, 3)
end

nodes.EmptyNode = EmptyNode






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
    self.squadShop = {} -- List<squadId OR false>. False indicates been purchased
    self.blessingShop = {} -- List<blessingId OR false>. False indicates been purchased
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

function ShopNode:draw(wx,wy)
    lg.setColor(1,1,1)
    local sx = self.id%2==0 and 1 or -1
    g.drawImage("node_town", wx,wy-8, 0, sx, 1)
end





return nodes
