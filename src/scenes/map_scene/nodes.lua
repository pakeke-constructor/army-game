local Class = require("src.modules.objects.Class")

---@class MapNode: objects.Class
---@field x integer grid x
---@field y integer grid y
---@field id integer random id
---@field demonEncounter integer? (0 1 2) Demon-encounters can exist on any kind of node
---@field ox number visual offset x
---@field oy number visual offset y
---@field nodeType string serialization key
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
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
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





---@param node MapNode
---@param x number
---@param y number
local function tryDrawDemons(node, x,y)
    if node.demonEncounter then
        local denc = node.demonEncounter
        -- denc 1 = 2 demons
        -- denc 2 = 3 demons
        -- denc 3 = 4 demons
        -- demons should be offset randomly in different directions
        g.drawImage("node_combat_demon", x,y+10)
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
    love.graphics.setColor(0.1,0.3,0.1)
    love.graphics.ellipse("fill", wx, wy, 8, 5)
    love.graphics.setColor(0.8, 0.3, 0.3, 1)
    love.graphics.ellipse("fill", wx, wy, 6, 3)
    tryDrawDemons(self, wx,wy)
end

nodes.BattleNode = BattleNode


-------------------------------
-- FeastNode
-------------------------------
---@class MapNode.FeastNode: MapNode
local FeastNode = nodes.newClass("feast")

function FeastNode:enter()
    local run = g.getRun()
    run.food = run.maxFood
end

function FeastNode:draw(wx, wy)
    lg.setColor(1,1,1)
    g.drawImage("node_banquet", wx, wy)
    tryDrawDemons(self, wx,wy)
end

nodes.FeastNode = FeastNode


-------------------------------
-- FountainNode
-------------------------------
---@class MapNode.FountainNode: MapNode
local FountainNode = nodes.newClass("fountain")

function FountainNode:enter()
    -- TODO:
    -- in future, should offer options for player to get new spells,
    -- or upgrade existing mana pool
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
local EmptyNode = nodes.newClass("Empty")

function EmptyNode:enter()
    -- this node does nothing.
end

function EmptyNode:draw(wx, wy)
    -- g.drawImage("map/nodes/node_fountain", wx, wy)
end

nodes.EmptyNode = EmptyNode



return nodes
