
local Class = require("src.modules.objects.Class")
local nodes = require("src.scenes.map_scene.nodes")
local decor_types = require("src.scenes.map_scene.decor_types")

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
- pass-3: Fill in super empty nodes. If >51% of neighbors are empty, become battle node.
- pass-4: Dead-end nodes (1 neighbor) become special nodes.
- pass-5: Set pieces
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

local function edgeKeyFromKeys(ka, kb)
    if ka > kb then ka, kb = kb, ka end
    return ka .. ">" .. kb
end

local function edgeKey(ax, ay, bx, by)
    return edgeKeyFromKeys(nodeKey(ax, ay), nodeKey(bx, by))
end

local function linkAdj(self, ka, kb)
    local a = self.adj[ka]
    if not a then
        a = {}
        self.adj[ka] = a
    end
    local b = self.adj[kb]
    if not b then
        b = {}
        self.adj[kb] = b
    end
    a[kb] = true
    b[ka] = true
end

local function unlinkAdj(self, ka, kb)
    local a = self.adj[ka]
    if a then a[kb] = nil end
    local b = self.adj[kb]
    if b then b[ka] = nil end
end

local function removeEdgeByKeys(self, ka, kb)
    local ek = edgeKeyFromKeys(ka, kb)
    if not self.edges[ek] then return end
    self.edges[ek] = nil
    unlinkAdj(self, ka, kb)
end


function MapGraph:init(width, height)
    self.width = width
    self.height = height
    self.distanceBetweenNodes = 130 -- sensible default just to silence LuaLS
    self.nodes = {}
    self.edges = {}
    self.adj = {}
    self.decor = {}
    self.playerPosition = nil -- node key string, e.g. "2,0"
    self.rng = love.math.random
end

---@param node MapNode
function MapGraph:getDrawPos(node)
    local sp = self.distanceBetweenNodes
    return (node.x * sp + node.ox) * self.scaleX, (node.y * sp + node.oy) * self.scaleY
end


---@param x integer
---@param y integer
---@param nodeType string|MapNode a node type string or a Node class
---@return MapNode
function MapGraph:addNode(x, y, nodeType)
    local key = nodeKey(x, y)
    local NodeClass = type(nodeType) == "string" and nodes.getClass(nodeType) or nodeType
    NodeClass = NodeClass or nodes.getClass("battle")
    local node = NodeClass(x, y)
    node.id = math.floor((love.math.random)() * 2147483647) + 1
    node.nodeType = NodeClass.nodeType or "battle"
    self.nodes[key] = node
    return node
end

---@generic T: MapNode
---@param x integer
---@param y integer
---@param nodeType T a node type string or a Node class
---@return T?
---@overload fun(self:MapGraph,x:integer,y:integer,nodeType:string):(MapNode?)
function MapGraph:setNode(x, y, nodeType)
    local key = nodeKey(x, y)
    if not self.nodes[key] then return nil end
    local NodeClass = type(nodeType) == "string" and nodes.getClass(nodeType) or nodeType
    NodeClass = NodeClass or nodes.getClass("battle")
    local node = NodeClass(x, y)
    node.id = math.floor((love.math.random)() * 2147483647) + 1
    node.nodeType = NodeClass.nodeType or "battle"
    self.nodes[key] = node
    return node
end


function MapGraph:removeNode(x, y)
    local key = nodeKey(x, y)
    if not self.nodes[key] then return end
    self.nodes[key] = nil

    local nbs = self.adj[key]
    if nbs then
        for nk in pairs(nbs) do
            self.edges[edgeKeyFromKeys(key, nk)] = nil
            local back = self.adj[nk]
            if back then back[key] = nil end
        end
        self.adj[key] = nil
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
    local ka, kb = nodeKey(ax, ay), nodeKey(bx, by)
    if not self.nodes[ka] or not self.nodes[kb] then return end
    local ek = edgeKeyFromKeys(ka, kb)
    if self.edges[ek] then return end
    self.edges[ek] = true
    linkAdj(self, ka, kb)
end

function MapGraph:removeEdge(ax, ay, bx, by)
    removeEdgeByKeys(self, nodeKey(ax, ay), nodeKey(bx, by))
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
    local nbs = self.adj[key]
    if not nbs then return result end
    for nk in pairs(nbs) do
        local node = self.nodes[nk]
        if node then
            result[#result + 1] = node
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
---@field decorTypes? string[] list of decor type ids

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
    rng = rng or love.math.random
    self.rng = rng

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
            local ka, kb = ek:match("^(.-)>(.+)$")
            removeEdgeByKeys(self, ka, kb)
        end
    end

    -- 6. Random visual offsets per node
    local function ensureNodeOffsets()
        local maxOff = args.distanceBetweenNodes * args.nodeOffsetFactor
        for _, node in pairs(self.nodes) do
            if (not node.ox) or (node.ox == 0) then
                node.ox = (rng() - 0.5) * 2 * maxOff
                node.oy = (rng() - 0.5) * 2 * maxOff
            end
        end
    end
    ensureNodeOffsets()

    -- 7. Prune edges with similar angles from the same node
    local DOT_THRESHOLD = 0.82 -- ~23 degrees
    for _, node in pairs(self.nodes) do
        local nx, ny = self:getDrawPos(node)
        local nbs = self:getNeighbors(node.x, node.y)
        for i = 1, #nbs do
            for j = i + 1, #nbs do
                local ix, iy = self:getDrawPos(nbs[i])
                local jx, jy = self:getDrawPos(nbs[j])
                local dx1, dy1 = ix - nx, iy - ny
                local dx2, dy2 = jx - nx, jy - ny
                local len1 = math.sqrt(dx1*dx1 + dy1*dy1)
                local len2 = math.sqrt(dx2*dx2 + dy2*dy2)
                local dot = (dx1*dx2 + dy1*dy2) / (len1 * len2)
                if dot > DOT_THRESHOLD then
                    local v = len1 > len2 and nbs[i] or nbs[j]
                    removeEdgeByKeys(self, nodeKey(node.x, node.y), nodeKey(v.x, v.y))
                end
            end
        end
    end

    -- 8. DFS from (0,0) — prune all unreachable nodes
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

    ensureNodeOffsets() -- since more nodes were generated; add more here.


    -- 9. Place decor in gaps using two-grid spatial check
    local decorTypeIds = args.decorTypes
    if decorTypeIds and #decorTypeIds > 0 then
        local sp = args.distanceBetweenNodes
        local cellSize = sp / 8
        local nodeGrid = {} -- nodes + edges (static)
        local decorGrid = {} -- placed decor (grows)

        local function markGrid(grid, wx, wy, r)
            local cx0 = math.floor((wx - r) / cellSize)
            local cx1 = math.floor((wx + r) / cellSize)
            local cy0 = math.floor((wy - r) / cellSize)
            local cy1 = math.floor((wy + r) / cellSize)
            for cy = cy0, cy1 do
                for cx = cx0, cx1 do
                    grid[cx .. "," .. cy] = true
                end
            end
        end

        local function isGridClear(grid, wx, wy, r)
            local cx0 = math.floor((wx - r) / cellSize)
            local cx1 = math.floor((wx + r) / cellSize)
            local cy0 = math.floor((wy - r) / cellSize)
            local cy1 = math.floor((wy + r) / cellSize)
            for cy = cy0, cy1 do
                for cx = cx0, cx1 do
                    if grid[cx .. "," .. cy] then return false end
                end
            end
            return true
        end

        -- Mark all node positions into nodeGrid
        local nodeR = sp * 0.2
        for _, node in pairs(self.nodes) do
            local wx, wy = self:getDrawPos(node)
            markGrid(nodeGrid, wx, wy, nodeR)
        end

        -- Mark all edges into nodeGrid
        local edgeR = sp * 0.15
        self:forEachEdge(function(a, b)
            local ax, ay = self:getDrawPos(a)
            local bx, by = self:getDrawPos(b)
            local dist = math.sqrt((bx - ax)^2 + (by - ay)^2)
            local steps = math.max(1, math.ceil(dist / (cellSize * 0.5)))
            for i = 0, steps do
                local t = i / steps
                markGrid(nodeGrid, ax + (bx - ax) * t, ay + (by - ay) * t, edgeR)
            end
        end)

        -- Get sorted decor types (biggest nodeRadius first)
        local sortedTypes = decor_types.getSortedByRadius(decorTypeIds)

        -- Iterate every fine-grid cell in world bounds
        local hw, hh = math.floor(width / 2), math.floor(height / 2)
        local gx0 = math.floor((-hw * sp * self.scaleX) / cellSize)
        local gx1 = math.floor(( hw * sp * self.scaleX) / cellSize)
        local gy0 = math.floor((-hh * sp * self.scaleY) / cellSize)
        local gy1 = math.floor(( hh * sp * self.scaleY) / cellSize)

        for i=1,#sortedTypes do
            local dtype = sortedTypes[i]
            for gy = gy0, gy1 do
                for gx = gx0, gx1 do
                    if not nodeGrid[gx .. "," .. gy] then
                        local wx = (gx + rng()) * cellSize
                        local wy = (gy + rng()) * cellSize
                        if rng() < dtype.chance then
                            if isGridClear(nodeGrid, wx, wy, dtype.nodeRadius) and isGridClear(decorGrid, wx, wy, dtype.decorRadius) then
                                self.decor[#self.decor + 1] = {
                                    x = wx, y = wy, decorType = dtype.id
                                }
                                markGrid(decorGrid, wx, wy, dtype.decorRadius)
                                -- break
                            end
                        end
                    end
                end
            end
        end
    end

    return self
end



---@return integer
function MapGraph:countNodes()
    local count = 0
    for _ in pairs(self.nodes) do
        count = count + 1
    end
    return count
end




local SPECIAL_NODES = {
    "feast", "fountain", "shrine", "shop",
    "dynamic", "dynamic", "dynamic", "dynamic"
}
-- TODO: add `town` in here too.

local function isNextToNodeOfSameType(self, x, y, nodeType)
    for _, nb in ipairs(self:getNeighbors(x, y)) do
        if nb.nodeType == nodeType then
            return true
        end
    end
    return false
end

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
            local r2 = rng()
            local pick = SPECIAL_NODES[math.floor(rng() * #SPECIAL_NODES) + 1]
            if r2 < 0.3 then
                self:setNode(node.x, node.y, "event")
            elseif not isNextToNodeOfSameType(self, node.x, node.y, pick) then
                self:setNode(node.x, node.y, pick)
            end
        else
            self:setNode(node.x, node.y, "empty")
        end
        ::continue::
    end

    -- pass-2: Adjust battle node difficulty
    -- 5% chance +2 difficulty, 25% chance +1 difficulty
    for _, node in pairs(self.nodes) do
        if node.demonEncounter then
            ---@cast node MapNode
            local r = rng()
            if r < 0.05 then
                node.demonEncounter = node.demonEncounter + 2
            elseif r < 0.30 then
                node.demonEncounter = node.demonEncounter + 1
            end
        end
    end

    -- pass-3: Fill in super empty nodes
    for _, node in pairs(self.nodes) do
        if node.nodeType == "empty" then
            local nbs = self:getNeighbors(node.x, node.y)
            local emptyCount = 0
            for _, nb in ipairs(nbs) do
                if nb.nodeType == "empty" then emptyCount = emptyCount + 1 end
            end
            if #nbs > 0 and emptyCount / #nbs > 0.51 then
                -- if node has too many empty neighbors, make it a battle-node.
                -- ensures that the world isn't "too" empty.
                self:setNode(node.x, node.y, "battle")
            end
        end
    end

    -- pass-4: Dead-end nodes become special
    for _, node in pairs(self.nodes) do
        local nbs = self:getNeighbors(node.x, node.y)
        if #nbs == 1 then
            local pick = SPECIAL_NODES[math.floor(rng() * #SPECIAL_NODES) + 1]
            self:setNode(node.x, node.y, pick)
        end
    end

    -- pass-5: Set pieces (TODO)
    self:_placeSetPieces(rng)
end


---@param rng fun():number
function MapGraph:_placeSetPieces(rng)
    -- TODO: pass-3 implementation
end


--- Iterate all nodes
---@param fn fun(node:MapNode)
function MapGraph:forEachNode(fn)
    for _, node in pairs(self.nodes) do
        fn(node)
    end
end

--- Iterate all decor
function MapGraph:forEachDecor(fn)
    for _, d in ipairs(self.decor) do
        fn(d)
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
        local ka, kb = ek:match("^(.-)>(.+)$")
        linkAdj(self, ka, kb)
    end
    self.playerPosition = data.playerPosition
    self.distanceBetweenNodes = data.distanceBetweenNodes
    self.scaleX = data.scaleX or 1
    self.scaleY = data.scaleY or 1
    self.decor = data.decor or {}
    return self
end


return MapGraph
