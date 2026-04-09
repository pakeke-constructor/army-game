local M = {}

---@class DecorTypeDef
---@field id string
---@field radius number exclusion radius
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

--- Returns decor types sorted by radius descending
---@param ids string[]
---@return DecorTypeDef[]
function M.getSortedByRadius(ids)
    local result = {}
    for _, id in ipairs(ids) do
        result[#result + 1] = registry[id]
    end
    table.sort(result, function(a, b) return a.radius > b.radius end)
    return result
end


-- Define built-in decor types (radius set by M.init() from image size)
M.define("mountain_large", { image = "mountain_large_1", chance = 0.04, radius = 80 })

M.define("tree_large_1", { image = "tree_large_1", chance = 0.2, radius = 20 })

M.define("tree_small_1", { image = "tree_small_1", chance = 0.1, radius = 16 })


return M
