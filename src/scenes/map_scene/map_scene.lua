local ECSWorld = require("src.ecs.ECSWorld")
local Camera = require("lib.cam11")

local CAMERA_ZOOM = 2

local map_scene = {}

function map_scene:init()
end

function map_scene:enter()
    -- INTENT: On enter, we rebuild the map ECS from scratch using the Run's saved map data.
    -- The Run stores the "crucial bits" of the map: nodes, edges, and node-types.
    -- (e.g. run.mapData = { nodes = {...}, edges = {...} })
    -- The ECS entities (sprites, decorations, lines) are purely visual and regenerated
    -- from that data each time we enter the scene.
    --
    -- This means: if map serialization is broken, we'll see it immediately on re-entering
    -- the map, rather than only noticing on a full save/load cycle.
    --
    -- Flow:
    --   1. Read run.mapData (nodes, edges, node-types)
    --   2. Create a fresh ECSWorld
    --   3. Spawn map entities (node sprites, edge lines, etc.) from run.mapData

    -- CRUCIALLY IMPORTANT DETAIL: Map-generation should ideally be *mostly* deterministic.
    -- this will avoid most issues
    self.ecs = ECSWorld()
    self.camera = Camera(0, 0, CAMERA_ZOOM)
    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.x = 0
    self.y = 0
end

function map_scene:leave()
    -- INTENT: On leave, discard the ECS entirely. The map's logical state (nodes, edges,
    -- node-types, player position) lives on the Run and is already saved there.
    -- The ECS is just a visual representation and gets rebuilt on next enter.
    self.ecs = nil
    self.camera = nil
end

function map_scene:pollHandlers()
    self.ecs:addSystemHandlers()
end

function map_scene:update(dt)
    self.camera:setViewport(0, 0, love.graphics.getDimensions())
    self.camera:setPos(self.x, self.y)
    self.ecs:update(dt)
end

function map_scene:draw()
    local lg = love.graphics
    lg.clear(0.08, 0.06, 0.06, 1)

    self.camera:attach(false)
    iml.pushTransform(self.camera:getTransform())
    self.ecs:draw()
    iml.popTransform()
    self.camera:detach()

    ui.startUI()
    -- HERE.
    ui.endUI()
end

return map_scene
