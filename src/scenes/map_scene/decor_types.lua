local M = {}

---@class DecorTypeDef
---@field nodeRadius number clearance from nodes/edges
---@field decorRadius number clearance from other decor
---@field chance number per-cell roll chance
---@field image string? image name (used for draw + radius)
---@field opacity number? image name (used for draw + radius)
---@field transformModifier (fun():(number,number,number,number,number,number,number))?

---@class DecorTypeInfo: DecorTypeDef
---@field id string
---@field image string? image name (used for draw + radius)
---@field opacity number image name (used for draw + radius)
---@field transformModifier fun(id:integer):(number,number,number,number,number,number,number)

---@param id integer deterministic ID
---@return number ox
---@return number oy
---@return number r
---@return number sx
---@return number sy
---@return number kx
---@return number ky
local function defaultTransformModifier(id)
    return 0, 0, 0, 1, 1, 0, 0
end

local registry = {}

---@param id string
---@param def DecorTypeDef
function M.define(id, def)
    ---@cast def DecorTypeInfo
    def.id = id
    def.opacity = def.opacity or 1
    def.transformModifier = def.transformModifier or defaultTransformModifier
    registry[id] = def
end

---@param id string
---@return DecorTypeInfo?
function M.get(id)
    return registry[id]
end

--- Returns decor types sorted by nodeRadius descending
---@param ids string[]
---@return DecorTypeInfo[]
function M.getSortedByRadius(ids)
    local result = {}
    for _, id in ipairs(ids) do
        result[#result + 1] = registry[id]
    end
    table.sort(result, function(a, b) return a.nodeRadius > b.nodeRadius end)
    return result
end


---@param id integer
local function grassSway(id)
    local t = love.timer.getTime()
    local offt = helper.hashInteger(id) / 65536
    local a = (t + offt) * math.pi / 3
    local k = math.sin(a) * math.sin(a * 2) * 0.4
    return 0, 0, 0, 1, 1, k, 0
end

---@param id integer
local function bushSway(id)
    local t = love.timer.getTime()
    local offt = helper.hashInteger(id) / 65536
    local a = (t + offt) * math.pi / 4
    local k = math.sin(a) * math.sin(a * 2) * 0.3
    return 0, 0, 0, 1, 1, k, 0
end


---@param id integer
local function treeAnimation(id)
    local t = love.timer.getTime()
    local offt = helper.hashInteger(id) / 65536

    -- Sway
    local a = (t + offt) * math.pi / 5
    local k = math.sin(a) * math.sin(a * 2) * 0.08

    -- Bobbing
    local a2 = (t + offt + 0.5) * math.pi / 4
    local s2 = (math.sin(a2) ^ 2)
    local sy = 1 + s2 * 0.075

    return 0, 0, 0, 1, sy, k, 0
end

---@param id integer
local function treeAnimationRigid(id)
    local t = love.timer.getTime()
    local offt = helper.hashInteger(id) / 65536

    -- Sway
    local a = (t + offt) * math.pi / 5
    local k = math.sin(a) * math.sin(a * 2) * 0.04

    -- Bobbing
    local a2 = (t + offt + 0.5) * math.pi / 4
    local s2 = (math.sin(a2) ^ 2)
    local sy = 1 + s2 * 0.0375

    return 0, 0, 0, 1, sy, k, 0
end

-- Define built-in decor types

-- Grasses
local GRASS_OPACITY = 0.65
M.define("grass_1", { image = "grass_1", chance = 0.15, nodeRadius = 4, decorRadius = 8, opacity = GRASS_OPACITY, transformModifier = grassSway })
M.define("grass_2", { image = "grass_2", chance = 0.3, nodeRadius = 4, decorRadius = 8, opacity = GRASS_OPACITY, transformModifier = grassSway })
M.define("grass_3", { image = "grass_3", chance = 0.2, nodeRadius = 4, decorRadius = 8, opacity = GRASS_OPACITY, transformModifier = grassSway })


-- Mountains
M.define("mountain_large", { image = "mountain_large_1", chance = 0.1, nodeRadius = 35, decorRadius = 20 })
M.define("mountain_small_1", { image = "mountain_small_1", chance = 0.3, nodeRadius = 15, decorRadius = 10 })
M.define("mountain_small_2", { image = "mountain_small_2", chance = 0.1, nodeRadius = 15, decorRadius = 6 })

M.define("hell_mountain_large", { image = "hell_mountain_large_1", chance = 0.15, nodeRadius = 35, decorRadius = 20 })
M.define("hell_mountain_small_1", { image = "hell_mountain_small_1", chance = 0.3, nodeRadius = 15, decorRadius = 10 })
M.define("hell_mountain_small_2", { image = "hell_mountain_small_2", chance = 0.2, nodeRadius = 15, decorRadius = 6 })
M.define("volcano", { image = "volcano_1", chance = 0.01, nodeRadius = 35, decorRadius = 20 })
M.define("redcrystal_large_1", { image = "redcrystal_large_1", chance = 0.075, nodeRadius = 25, decorRadius = 15 })
M.define("redcrystal_large_2", { image = "redcrystal_large_2", chance = 0.075, nodeRadius = 20, decorRadius = 15 })
M.define("redcrystal_medium", { image = "redcrystal_medium_1", chance = 0.15, nodeRadius = 10, decorRadius = 9 })
M.define("redcrystal_small_1", { image = "redcrystal_small_1", chance = 0.3, nodeRadius = 3, decorRadius = 3 })
M.define("redcrystal_small_2", { image = "redcrystal_small_1", chance = 0.3, nodeRadius = 3, decorRadius = 3 })


-- Trees
M.define("tree_large_1", { image = "tree_large_1", chance = 0.2, nodeRadius = 20, decorRadius = 8, transformModifier = treeAnimation })
M.define("tree_small_1", { image = "tree_small_1", chance = 0.3, nodeRadius = 12, decorRadius = 6, transformModifier = treeAnimation })
-- M.define("tree_small_1_b", { image = "tree_small_1", chance = 0.05, nodeRadius = 8, decorRadius = 4 })

M.define("brownoak_large", { image = "brownoak_large_1", chance = 0.05, nodeRadius = 20, decorRadius = 8, transformModifier = treeAnimation })
M.define("brownoak_small", { image = "brownoak_small_1", chance = 0.06, nodeRadius = 12, decorRadius = 6, transformModifier = treeAnimation })
M.define("brownpine_large", { image = "brownpine_large_1", chance = 0.25, nodeRadius = 20, decorRadius = 8, transformModifier = treeAnimation })
M.define("brownpine_small", { image = "brownpine_small_1", chance = 0.35, nodeRadius = 12, decorRadius = 6, transformModifier = treeAnimation })

M.define("demontree", { image = "demontree_1", chance = 0.1, nodeRadius = 20, decorRadius = 8, transformModifier = treeAnimationRigid })
M.define("burnedtree_1", { image = "burnedtree_1", chance = 0.3, nodeRadius = 10, decorRadius = 8, transformModifier = treeAnimationRigid })
M.define("burnedtree_2", { image = "burnedtree_2", chance = 0.3, nodeRadius = 10, decorRadius = 8, transformModifier = treeAnimationRigid })


-- Small Trees/Bushes
M.define("bush_medium", { image = "bush_medium_1", chance = 0.2, nodeRadius = 12, decorRadius = 6, transformModifier = bushSway })
M.define("bush_small_1", { image = "bush_small_1", chance = 0.3, nodeRadius = 6, decorRadius = 6, transformModifier = bushSway })
M.define("bush_small_2", { image = "bush_small_2", chance = 0.3, nodeRadius = 6, decorRadius = 6, transformModifier = bushSway })
M.define("burnedtree_3", { image = "burnedtree_3", chance = 0.3, nodeRadius = 8, decorRadius = 8, transformModifier = treeAnimationRigid })
M.define("burnedtree_4", { image = "burnedtree_4", chance = 0.3, nodeRadius = 8, decorRadius = 8, transformModifier = treeAnimationRigid })


return M
