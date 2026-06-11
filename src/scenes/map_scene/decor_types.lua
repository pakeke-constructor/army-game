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



local GRASS_OPACITY = 0.65
M.define("grass_1", {image = "grass_1", chance = 0.15, nodeRadius = 4, decorRadius = 8, opacity = GRASS_OPACITY})
M.define("grass_2", { image = "grass_2", chance = 0.3, nodeRadius = 4, decorRadius = 8, opacity = GRASS_OPACITY })
M.define("grass_3", { image = "grass_3", chance = 0.2, nodeRadius = 4, decorRadius = 8, opacity = GRASS_OPACITY })


-- Define built-in decor types
M.define("mountain_large", { image = "mountain_large_1", chance = 0.1, nodeRadius = 35, decorRadius = 20 })
M.define("mountain_small_1", { image = "mountain_small_1", chance = 0.3, nodeRadius = 15, decorRadius = 10 })
M.define("mountain_small_2", { image = "mountain_small_2", chance = 0.1, nodeRadius = 15, decorRadius = 6 })

M.define("tree_large_1", { image = "tree_large_1", chance = 0.2, nodeRadius = 20, decorRadius = 8 })
M.define("tree_small_1", { image = "tree_small_1", chance = 0.3, nodeRadius = 12, decorRadius = 6 })
-- M.define("tree_small_1_b", { image = "tree_small_1", chance = 0.05, nodeRadius = 8, decorRadius = 4 })


return M
