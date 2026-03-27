
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
---@field x integer grid x (centered around 0)
---@field y integer grid y (centered around 0)
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
        local ka, kb = ek:match("^(.-)>(.+)$")
        if ka == key or kb == key then
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
    local key = nodeKey(x, y)
    for ek in pairs(self.edges) do
        local ka, kb = ek:match("^(.-)>(.+)$")
        local other
        if ka == key then other = kb
        elseif kb == key then other = ka
        end
        if other then
            local node = self.nodes[other]
            if node then
                result[#result + 1] = node
            end
        end
    end
    return result
end

---@class MapGraph.GenArgs
---@field width integer
---@field height integer
---@field nodePruneChance number
---@field edgePruneChance number
---@field distanceBetweenNodes number
---@field randomDiagonalChance number
---@field nodeOffsetFactor number
---@field scaleX number
---@field scaleY number

--- Generate a map procedurally.
---@param args MapGraph.GenArgs
---@param rng? fun():number a function returning [0,1), e.g. math.random
function MapGraph.generate(args, rng)
    local width = args.width
    local height = args.height
    local nodePrune = args.nodePruneChance
    local edgePrune = args.edgePruneChance
    local diagChance = args.randomDiagonalChance

    local self = MapGraph(width, height)
    self.distanceBetweenNodes = args.distanceBetweenNodes
    self.scaleX = args.scaleX
    self.scaleY = args.scaleY
    rng = rng or math.random

    local hw = math.floor(width / 2)
    local hh = math.floor(height / 2)
    local x0, x1 = -hw, hw
    local y0, y1 = -hh, hh

    -- 1. Create all nodes centered around (0,0)
    for y = y0, y1 do
        for x = x0, x1 do
            self:addNode(x, y, "battle")
        end
    end

    -- 2. Connect lattice (right and down)
    for y = y0, y1 do
        for x = x0, x1 do
            if x < x1 then self:addEdge(x, y, x + 1, y) end
            if y < y1 then self:addEdge(x, y, x, y + 1) end
        end
    end

    -- 3. Add random diagonals (no crossing)
    local hasSE = {}
    for y = y0, y1 - 1 do
        for x = x0, x1 - 1 do
            local r = rng()
            if r < diagChance / 2 then
                self:addEdge(x, y, x + 1, y + 1)
                hasSE[nodeKey(x, y)] = true
            elseif r < diagChance then
                if not hasSE[nodeKey(x, y)] then
                    self:addEdge(x + 1, y, x, y + 1)
                end
            end
        end
    end

    -- 4. Prune random nodes (punch holes), but never the center node
    for key, node in pairs(self.nodes) do
        if not (node.x == 0 and node.y == 0) and rng() < nodePrune then
            self:removeNode(node.x, node.y)
        end
    end

    -- 5. Prune random edges
    local edgeList = {}
    for ek in pairs(self.edges) do
        edgeList[#edgeList + 1] = ek
    end
    for _, ek in ipairs(edgeList) do
        if rng() < edgePrune then
            self.edges[ek] = nil
        end
    end

    -- 6. DFS from (0,0) — prune all unreachable nodes
    local reachable = {}
    local stack = { nodeKey(0, 0) }
    while #stack > 0 do
        local key = table.remove(stack)
        if not reachable[key] then
            reachable[key] = true
            local node = self.nodes[key]
            if node then
                for _, nb in ipairs(self:getNeighbors(node.x, node.y)) do
                    local nk = nodeKey(nb.x, nb.y)
                    if not reachable[nk] then
                        stack[#stack + 1] = nk
                    end
                end
            end
        end
    end
    for key in pairs(self.nodes) do
        if not reachable[key] then
            local node = self.nodes[key]
            self:removeNode(node.x, node.y)
        end
    end

    -- 7. Random visual offsets per node
    local maxOff = args.distanceBetweenNodes * args.nodeOffsetFactor
    for _, node in pairs(self.nodes) do
        node.ox = (rng() - 0.5) * 2 * maxOff
        node.oy = (rng() - 0.5) * 2 * maxOff
    end

    -- 8. Player starts at center
    self:setPlayerPosition(0, 0)

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
    return { width = self.width, height = self.height, distanceBetweenNodes = self.distanceBetweenNodes, scaleX = self.scaleX, scaleY = self.scaleY, nodes = nodes, edges = edges, playerPosition = self.playerPosition }
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
    self.distanceBetweenNodes = data.distanceBetweenNodes
    self.scaleX = data.scaleX or 1
    self.scaleY = data.scaleY or 1
    return self
end


return MapGraph
