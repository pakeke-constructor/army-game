
---@class fogService
local fogService = {}


local FOG_STEP = 24

local OPACITY = 1


local FOGS={
"fog_of_war_cloud1",
"fog_of_war_cloud2",
"fog_of_war_cloud3",
}

local FOG_LAYER_MAX = 4
local FOG_DARKEN_PER_LAYER = 0.25
local FOG_EXPAND_CELLS = 5
local FOG_VARIATION_MOD = 4

local ADJ = {
              {0, -1},
    {-1,  0},           {1,  0},
              {0,  1},
}

---@param grid objects.Grid<integer?>
---@param x integer
---@param y integer
local function hasAdjacentNil(grid, x, y)
    for i = 1, #ADJ do
        local dx, dy = ADJ[i][1], ADJ[i][2]
        local nx, ny = x + dx, y + dy
        if (not grid:contains(nx, ny)) or (grid:get(nx, ny) == nil) then
            return true
        end
    end
    return false
end

---@param grid objects.Grid<integer?>
---@param x integer
---@param y integer
---@param v integer
local function hasAdjacentBigger(grid, x, y, v)
    for i = 1, #ADJ do
        local dx, dy = ADJ[i][1], ADJ[i][2]
        local nx, ny = x + dx, y + dy
        if grid:contains(nx, ny) then
            local n = grid:get(nx, ny)
            if n ~= nil and n > v then
                return true
            end
        end
    end
    return false
end

---@param src objects.Grid<integer?>
---@param dst objects.Grid<integer?>
---@param allowBigger boolean
local function step(src, dst, allowBigger)
    for y = 0, src.height - 1 do
        for x = 0, src.width - 1 do
            local v = src:get(x, y)
            if v then
                if hasAdjacentNil(src, x, y) then
                    v = v + 1
                end
                if allowBigger and hasAdjacentBigger(src, x, y, v) then
                    v = v + 1
                end
            end

            dst:set(x, y, v)
        end
    end
end

---@param wx number
---@param wy number
---@param salt integer
local function hashCell(wx, wy, salt)
    local gx = math.floor(wx / FOG_STEP)
    local gy = math.floor(wy / FOG_STEP)
    return helper.hashIntegerPair(gx + salt * 7877, gy + salt * 6991)
end

local gridA, gridB, gridW, gridH -- cached grids; reallocated only when size changes
---@param w integer
---@param h integer
---@return objects.Grid<integer?>, objects.Grid<integer?>
local function getGrids(w, h)
    if gridW ~= w or gridH ~= h then
        gridA = objects.Grid(w, h)
        gridB = objects.Grid(w, h)
        gridW, gridH = w, h
    end
    return gridA, gridB
end

local batch -- persistent SpriteBatch over the atlas; lazy-init
local fogQuads -- cached quads + center-origins for FOGS
---@type integer[][]
local fogLayerCells = {}
local function getFogQuads()
    if not fogQuads then
        fogQuads = {}
        for i = 1, #FOGS do
            local q = g.getImageQuad(FOGS[i])
            local _,_,qw,qh = q:getViewport()
            fogQuads[i] = {quad = q, ox = qw/2, oy = qh/2}
        end
    end
    return fogQuads
end

---@param r kirigami.Region -- world-space
---@param fogColor objects.Color
---@param hasFog fun(x:number,y:number):boolean
---@param getFogAlpha? fun(x:number,y:number):number
function fogService.renderFog(r, fogColor, hasFog, getFogAlpha)
    prof_push("fogService.renderFog")

    local t = love.timer.getTime()
    local x1 = math.floor(r.x / FOG_STEP) * FOG_STEP - FOG_EXPAND_CELLS * FOG_STEP
    local y1 = math.floor(r.y / FOG_STEP) * FOG_STEP - FOG_EXPAND_CELLS * FOG_STEP
    local x2 = math.ceil((r.x + r.w) / FOG_STEP) * FOG_STEP + FOG_EXPAND_CELLS * FOG_STEP
    local y2 = math.ceil((r.y + r.h) / FOG_STEP) * FOG_STEP + FOG_EXPAND_CELLS * FOG_STEP

    local w = math.floor((x2 - x1) / FOG_STEP) + 1
    local h = math.floor((y2 - y1) / FOG_STEP) + 1
    local a, b = getGrids(w, h)

    prof_push("fogcheck")
    for gx = 0, w - 1 do
        for gy = 0, h - 1 do
            local wx = x1 + gx * FOG_STEP
            local wy = y1 + gy * FOG_STEP
            if hasFog(wx, wy) then
                a:set(gx, gy, 0)
            else
                a:set(gx, gy, nil)
            end
        end
    end
    prof_pop() -- prof_push("fogcheck")

    prof_push("fogstep")
    step(a, b, false)
    a, b = b, a

    for _ = 1, FOG_LAYER_MAX-1 do
        step(a, b, true)
        a, b = b, a
    end
    prof_pop() -- prof_push("fogstep")

    local quads = getFogQuads()
    if not batch then
        batch = lg.newSpriteBatch(g.getAtlas(), 4096)
    end
    batch:clear()

    -- layer FOG_LAYER_MAX -> 1 so deeper fog is added (drawn) behind edges
    for layer = 1, FOG_LAYER_MAX do
        fogLayerCells[layer] = fogLayerCells[layer] or {}
        table.clear(fogLayerCells[layer])
    end

    prof_push("fogassigncell")
    for gx = 0, w - 1 do
        for gy = 0, h - 1 do
            local v = a:get(gx, gy)
            if v ~= nil then
                local x = x1 + gx * FOG_STEP
                local y = y1 + gy * FOG_STEP
                local j = hashCell(x, y, 2)
                if j % FOG_VARIATION_MOD == 0 then
                    v = v + 1
                end
                local k = hashCell(x, y, 3)
                if k % FOG_VARIATION_MOD == 0 then
                    v = v + 1
                end

                local lv = helper.clamp(v, 1, FOG_LAYER_MAX)
                local cells = fogLayerCells[lv]
                local ci = #cells
                cells[ci + 1] = x
                cells[ci + 2] = y
                cells[ci + 3] = k
            end
        end
    end
    prof_pop() -- prof_push("fogassigncell")

    prof_push("fogdraw")
    for layer = FOG_LAYER_MAX, 1, -1 do
        local col = fogColor:darken((FOG_LAYER_MAX - layer) * FOG_DARKEN_PER_LAYER)
        if not getFogAlpha then
            batch:setColor(col[1], col[2], col[3], OPACITY)
        end
        local cells = fogLayerCells[layer]
        for ci = 1, #cells, 3 do
            local x = cells[ci]
            local y = cells[ci + 1]
            local i = cells[ci + 2]
            local ox = (i % 19) - 10
            local oy = (hashCell(x, y, 5) % 19) - 10
            local fq = quads[i % #FOGS + 1]
            if getFogAlpha then
                local alpha = helper.clamp(getFogAlpha(x, y) or 1, 0, 1)
                batch:setColor(col[1], col[2], col[3], OPACITY * alpha)
            end
            batch:add(fq.quad, x + ox, y + oy, math.sin(t + (i % 10) / 3), 1.5, 1.5, fq.ox, fq.oy)
        end
    end
    prof_pop() -- prof_push("fogdraw")

    lg.setColor(1, 1, 1, 1)
    lg.draw(batch)

    prof_pop() -- prof_push("fogService.renderFog")
end



return fogService
