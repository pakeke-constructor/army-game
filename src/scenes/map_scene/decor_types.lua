local M = {}

---@class DecorTypeDef
---@field id string
---@field radius number exclusion radius
---@field chance number per-cell roll chance
---@field image string? image name (used for draw + radius)
---@field draw fun(wx: number, wy: number)

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

--- Called after g and atlas are ready, to finalize image-based decor
function M.init()
    for _, def in pairs(registry) do
        if def.image and not def._inited then
            local w, h = g.getImageSize(def.image)
            def.radius = math.max(w, h)
            local img = def.image
            def.draw = function(wx, wy)
                love.graphics.setColor(1, 1, 1, 1)
                g.drawImage(img, wx, wy)
            end
            def._inited = true
        end
    end
end

-- Define built-in decor types (radius set by M.init() from image size)
M.define("mountain_large", { image = "mountain_large_1", chance = 0.04, radius = 0 })
M.define("mountain_small_1", { image = "mountain_small_1", chance = 0.06, radius = 0 })
M.define("mountain_small_2", { image = "mountain_small_2", chance = 0.06, radius = 0 })

return M
