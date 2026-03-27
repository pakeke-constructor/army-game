
local Class = require("src.modules.objects.Class")

--[[

MapGraph

Stores a big (serializable) map of nodes, for world-map.
Each node is a map-location.

proc generation algorithm:
- generate a big grid of nodes (N x M)
- connect all nodes to each other (lattice)
- connect diagonals randomly (but no overlaps; it's either south-east, or south-west)
- prune random nodes (punch holes in map)
- prune random edges

]]

---@class MapGraph: objects.Class
---@field width integer
---@field height integer
---@field nodes table<string, MapGraph.Node>
---@field edges table<string, true>
local MapGraph = Class("MapGraph")

---@class MapGraph.Node
---@field x integer grid x (0-indexed)
---@field y integer grid y (0-indexed)
---@field ox number visual offset x
---@field oy number visual offset y
---@field nodeType string


local function nodeKey(x, y)
    return x .. "," .. y
end

local function edgeKey(ax, ay, bx, by)
    local ka, kb = nodeKey(ax, ay), nodeKey(bx, by)
    if ka > kb then ka, kb = kb, ka end
    return ka .. ">" .. kb
end


function MapGraph:init(width, height)
    self.width = width
    self.height = height
    self.nodes = {}
    self.edges = {}
    self.playerPosition = nil -- node key string, e.g. "2,0"
end


function MapGraph:addNode(x, y, nodeType)
    local key = nodeKey(x, y)
    self.nodes[key] = { x = x, y = y, ox = 0, oy = 0, nodeType = nodeType or "battle" }
end

function MapGraph:removeNode(x, y)
    local key = nodeKey(x, y)
    if not self.nodes[key] then return end
    self.nodes[key] = nil
    -- remove all edges touching this node
    for ek in pairs(self.edges) do
        if ek:find(key, 1, true) then
            self.edges[ek] = nil
        end
    end
end

function MapGraph:getNode(x, y)
    return self.nodes[nodeKey(x, y)]
end

function MapGraph:hasNode(x, y)
    return self.nodes[nodeKey(x, y)] ~= nil
end

function MapGraph:setPlayerPosition(x, y)
    self.playerPosition = nodeKey(x, y)
end

function MapGraph:getPlayerNode()
    return self.playerPosition and self.nodes[self.playerPosition]
end

function MapGraph:addEdge(ax, ay, bx, by)
    if not self:hasNode(ax, ay) or not self:hasNode(bx, by) then return end
    self.edges[edgeKey(ax, ay, bx, by)] = true
end

function MapGraph:removeEdge(ax, ay, bx, by)
    self.edges[edgeKey(ax, ay, bx, by)] = nil
end

function MapGraph:hasEdge(ax, ay, bx, by)
    return self.edges[edgeKey(ax, ay, bx, by)] == true
end

--- Get all neighbors of a node
function MapGraph:getNeighbors(x, y)
    local result = {}
    for ek in pairs(self.edges) do
        local key = nodeKey(x, y)
        if ek:find(key, 1, true) then
            -- parse both keys out of edge
            local ka, kb = ek:match("^(.-)>(.+)$")
            local other = (ka == key) and kb or ka
            if other ~= key then
                local node = self.nodes[other]
                if node then
                    result[#result + 1] = node
                end
            end
        end
    end
    return result
end

--- Generate a map procedurally.
--- rng: a function() returning [0,1), e.g. math.random
function MapGraph.generate(width, height, rng)
    local self = MapGraph(width, height)
    rng = rng or math.random

    -- 1. Create all nodes
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            self:addNode(x, y, "battle")
        end
    end

    -- 2. Connect lattice (right and down)
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if x < width - 1 then
                self:addEdge(x, y, x + 1, y)
            end
            if y < height - 1 then
                self:addEdge(x, y, x, y + 1)
            end
        end
    end

    -- 3. Add random diagonals (no crossing)
    -- For each cell (x,y) where x<width-1 and y<height-1,
    -- pick either SE or SW diagonal (or neither)
    local hasSE = {} -- hasSE[x..","..y] = true if SE diagonal from (x,y)
    for y = 0, height - 2 do
        for x = 0, width - 2 do
            local r = rng()
            if r < 0.35 then
                -- SE diagonal: (x,y) -> (x+1,y+1)
                self:addEdge(x, y, x + 1, y + 1)
                hasSE[nodeKey(x, y)] = true
            elseif r < 0.7 then
                -- SW diagonal: (x+1,y) -> (x,y+1)
                -- only if SE from (x,y) doesn't exist (they'd cross)
                if not hasSE[nodeKey(x, y)] then
                    self:addEdge(x + 1, y, x, y + 1)
                end
            end
            -- else: no diagonal
        end
    end

    -- 4. Prune random nodes (punch holes), but never first or last row
    for y = 1, height - 2 do
        for x = 0, width - 1 do
            if rng() < 0.15 then
                self:removeNode(x, y)
            end
        end
    end

    -- 5. Prune random edges
    local edgeList = {}
    for ek in pairs(self.edges) do
        edgeList[#edgeList + 1] = ek
    end
    for _, ek in ipairs(edgeList) do
        if rng() < 0.1 then
            self.edges[ek] = nil
        end
    end

    -- 6. Prune disconnected nodes (0 edges)
    local toRemove = {}
    for key, node in pairs(self.nodes) do
        if #self:getNeighbors(node.x, node.y) == 0 then
            toRemove[#toRemove + 1] = node
        end
    end
    for _, node in ipairs(toRemove) do
        self:removeNode(node.x, node.y)
    end

    -- 7. Random visual offsets per node
    local MAX_OFFSET = 16
    for _, node in pairs(self.nodes) do
        node.ox = (rng() - 0.5) * 2 * MAX_OFFSET
        node.oy = (rng() - 0.5) * 2 * MAX_OFFSET
    end

    return self
end


--- Iterate all nodes
function MapGraph:forEachNode(fn)
    for _, node in pairs(self.nodes) do
        fn(node)
    end
end

--- Iterate all edges, calling fn(nodeA, nodeB)
function MapGraph:forEachEdge(fn)
    for ek in pairs(self.edges) do
        local ka, kb = ek:match("^(.-)>(.+)$")
        local a, b = self.nodes[ka], self.nodes[kb]
        if a and b then
            fn(a, b)
        end
    end
end


--- Serialize to a plain table (no metatables)
function MapGraph:serialize()
    local nodes = {}
    for key, node in pairs(self.nodes) do
        nodes[key] = { x = node.x, y = node.y, ox = node.ox, oy = node.oy, nodeType = node.nodeType }
    end
    local edges = {}
    local i = 0
    for ek in pairs(self.edges) do
        i = i + 1
        edges[i] = ek
    end
    return { width = self.width, height = self.height, nodes = nodes, edges = edges, playerPosition = self.playerPosition }
end

--- Deserialize from a plain table
function MapGraph.deserialize(data)
    local self = MapGraph(data.width, data.height)
    for key, node in pairs(data.nodes) do
        self.nodes[key] = { x = node.x, y = node.y, ox = node.ox or 0, oy = node.oy or 0, nodeType = node.nodeType }
    end
    for _, ek in ipairs(data.edges) do
        self.edges[ek] = true
    end
    self.playerPosition = data.playerPosition
    return self
end


return MapGraph
