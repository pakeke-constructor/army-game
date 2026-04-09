
local Class = require("src.modules.objects.Class")
local nodes = require("src.scenes.map_scene.nodes")

--[[

MapGraph

Stores a big (serializable) map of nodes, for world-map.
Each node is a map-location.


Procedural generation is done in 2 stages:
STAGE-1: structure generation algorithm:
- generate a big grid of nodes (N x M)
- connect all nodes to each other (lattice)
- connect diagonals randomly (but no overlaps; it's either south-east, or south-west)
- prune random nodes (punch holes in map)
- prune random edges

STAGE-2: Node-generation (essentially 'filling in' the existing structure)
- pass-1:
- Make 25% of nodes enemy-nodes. 
- Make 15% of nodes "special" nodes. Random choice between FeastNode, FountainNode for now. (Will add more later)
- pass-2:
- Iterate over all enemy-nodes. 5% chance to increase difficulty by 2. 25% to increase difficulty by 1
- Iterate over all enemy-nodes. For every node of difficulty 2: decrease difficulty by 1.
- pass-3: Set pieces
- (SKIP FOR NOW; WILL DO THIS IN FUTURE. Create a method stub so i dont forget)

]]

---@class MapGraph: objects.Class
---@field width integer
---@field height integer
---@field nodes table<string, MapNode>
---@field edges table<string, true>
---@field decor table[]
local MapGraph = Class("g:MapGraph")





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
    self.decor = {}
    self.playerPosition = nil -- node key string, e.g. "2,0"
end


---@param x integer
---@param y integer
---@param nodeType string|MapNode a node type string or a Node class
function MapGraph:addNode(x, y, nodeType)
    local key = nodeKey(x, y)
    local NodeClass = type(nodeType) == "string" and nodes.getClass(nodeType) or nodeType
    NodeClass = NodeClass or nodes.getClass("battle")
    local node = NodeClass(x, y)
    node.nodeType = NodeClass.nodeType or "battle"
    self.nodes[key] = node
end

--- Delete all nodes within radius of (cx, cy). Iterates only the bounding box, not all nodes.
---@param self MapGraph
---@param cx number
---@param cy number
---@param radius number
local function deleteNodesInRadius(self, cx, cy, radius)
    local r2 = radius * radius
    local x0 = math.ceil(cx - radius)
    local x1 = math.floor(cx + radius)
    local y0 = math.ceil(cy - radius)
    local y1 = math.floor(cy + radius)
    for x = x0, x1 do
        for y = y0, y1 do
            if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r2 then
                self:removeNode(x, y)
            end
        end
    end
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


---@param x number
---@param y number
---@return MapNode
function MapGraph:getNode(x, y)
    return self.nodes[nodeKey(x, y)]
end


---@param x number
---@param y number
---@return boolean
function MapGraph:hasNode(x, y)
    return self.nodes[nodeKey(x, y)] ~= nil
end

---@param x number
---@param y number
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
---@param x number
---@param y number
---@return MapNode[]
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

    -- STAGE 2: Node generation
    self:setPlayerPosition(0, 0)
    self:_generateNodes(rng)

    -- 7. Random visual offsets per node
    local maxOff = args.distanceBetweenNodes * args.nodeOffsetFactor
    for _, node in pairs(self.nodes) do
        node.ox = (rng() - 0.5) * 2 * maxOff
        node.oy = (rng() - 0.5) * 2 * maxOff
    end

    return self
end



local SPECIAL_NODES = {"feast", "fountain"}

---@param rng fun():number
function MapGraph:_generateNodes(rng)
    local playerKey = self.playerPosition

    -- pass-1: Assign node types.
    -- 25% battle, 15% special (feast/fountain), 60% empty
    for key, node in pairs(self.nodes) do
        if key == playerKey then goto continue end
        local r = rng()
        if r < 0.25 then
            -- stays as battle (already is)
        elseif r < 0.40 then
            local pick = SPECIAL_NODES[math.floor(rng() * #SPECIAL_NODES) + 1]
            self:addNode(node.x, node.y, pick)
        else
            self:addNode(node.x, node.y, "Empty")
        end
        ::continue::
    end

    -- pass-2: Adjust battle node difficulty
    -- 5% chance +2 difficulty, 25% chance +1 difficulty
    -- Then clamp: any difficulty 2 nodes get reduced to 1
    for _, node in pairs(self.nodes) do
        if node.nodeType == "battle" then
            ---@cast node MapNode.BattleNode
            local r = rng()
            if r < 0.05 then
                node.difficulty = node.difficulty + 2
            elseif r < 0.30 then
                node.difficulty = node.difficulty + 1
            end
        end
    end
    for _, node in pairs(self.nodes) do
        if node.nodeType == "battle" and node.difficulty >= 2 then
            ---@cast node MapNode.BattleNode
            node.difficulty = node.difficulty - 1
        end
    end

    -- pass-3: Set pieces (TODO)
    self:_placeSetPieces(rng)
end


---@param rng fun():number
function MapGraph:_placeSetPieces(rng)
    -- TODO: pass-3 implementation
end


--- Iterate all nodes
function MapGraph:forEachNode(fn)
    for _, node in pairs(self.nodes) do
        fn(node)
    end
end

--- BFS shortest path from node at (ax,ay) to node at (bx,by).
--- Returns list of nodes from start to end (inclusive), or nil if unreachable/too deep.
function MapGraph:findPath(ax, ay, bx, by, maxDepth)
    local startKey = nodeKey(ax, ay)
    local goalKey = nodeKey(bx, by)
    if startKey == goalKey then return { self.nodes[startKey] } end
    if not self.nodes[startKey] or not self.nodes[goalKey] then return nil end

    maxDepth = maxDepth or math.huge
    local prev = {}
    local depth = {}
    local queue = { startKey }
    local head = 1
    prev[startKey] = false
    depth[startKey] = 0
    while head <= #queue do
        local key = queue[head]
        head = head + 1
        if key == goalKey then
            -- reconstruct
            local path = {}
            local k = goalKey
            while k do
                path[#path + 1] = self.nodes[k]
                k = prev[k]
            end
            -- reverse
            for i = 1, math.floor(#path / 2) do
                path[i], path[#path - i + 1] = path[#path - i + 1], path[i]
            end
            return path
        end
        local d = depth[key]
        if d < maxDepth then
            local node = self.nodes[key]
            for _, nb in ipairs(self:getNeighbors(node.x, node.y)) do
                local nk = nodeKey(nb.x, nb.y)
                if prev[nk] == nil then
                    prev[nk] = key
                    depth[nk] = d + 1
                    queue[#queue + 1] = nk
                end
            end
        end
    end
    return nil
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


local function serializeNode(node)
    local data = {}
    for k, v in pairs(node) do
        data[k] = v
    end
    data.nodeType = node.nodeType
    return data
end

local function deserializeNode(data)
    local cls = nodes.getClass(data.nodeType) or nodes.getClass("battle")
    return setmetatable(data, cls)
end


--- Serialize to a plain table (no metatables)
function MapGraph:serialize()
    local serializedNodes = {}
    for key, node in pairs(self.nodes) do
        serializedNodes[key] = serializeNode(node)
    end
    local edges = {}
    local i = 0
    for ek in pairs(self.edges) do
        i = i + 1
        edges[i] = ek
    end
    
    return { width = self.width, height = self.height, distanceBetweenNodes = self.distanceBetweenNodes, scaleX = self.scaleX, scaleY = self.scaleY, nodes = serializedNodes, edges = edges, decor = self.decor, playerPosition = self.playerPosition }
end

--- Deserialize from a plain table
function MapGraph.deserialize(data)
    local self = MapGraph(data.width, data.height)
    for key, nodeData in pairs(data.nodes) do
        self.nodes[key] = deserializeNode(nodeData)
    end
    for _, ek in ipairs(data.edges) do
        self.edges[ek] = true
    end
    self.playerPosition = data.playerPosition
    self.distanceBetweenNodes = data.distanceBetweenNodes
    self.scaleX = data.scaleX or 1
    self.scaleY = data.scaleY or 1
    self.decor = data.decor or {}
    return self
end


return MapGraph
