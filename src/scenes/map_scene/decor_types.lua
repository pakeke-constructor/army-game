local M = {}

---@class DecorTypeDef
---@field id string
---@field nodeRadius number clearance from nodes/edges
---@field decorRadius number clearance from other decor
---@field chance number per-cell roll chance
---@field image string? image name (used for draw + radius)

local registry = {}

---@param id string
---@param def DecorTypeDef
function M.define(id, def)
    def.id = id
    registry[id] = def
end

---@param id string
---@return DecorTypeDef?
function M.get(id)
    return registry[id]
end

--- Returns decor types sorted by nodeRadius descending
---@param ids string[]
---@return DecorTypeDef[]
function M.getSortedByRadius(ids)
    local result = {}
    for _, id in ipairs(ids) do
        result[#result + 1] = registry[id]
    end
    table.sort(result, function(a, b) return a.nodeRadius > b.nodeRadius end)
    return result
end


-- Define built-in decor types
M.define("mountain_large", { image = "mountain_large_1", chance = 0.5, nodeRadius = 35, decorRadius = 20 })

M.define("tree_large_1", { image = "tree_large_1", chance = 0.2, nodeRadius = 20, decorRadius = 8 })

M.define("tree_small_1", { image = "tree_small_1", chance = 0.1, nodeRadius = 16, decorRadius = 6 })


return M
