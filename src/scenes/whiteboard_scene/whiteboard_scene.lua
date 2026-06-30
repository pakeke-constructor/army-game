local lg = love.graphics

---@class g.WhiteboardScene
local whiteboard_scene = {}

local UI_SCALE = 1      -- whole scene drawn at half scale (doubles virtual space)
local ICON = 32           -- native squad/blessing icon size
local CELL = ICON + 2     -- icon + gap
local GROUP_GAP = 4
local LABEL_H = 18
local PREVIEW_W = 140     -- reserved card area on the right


-- category modes
local RARITY_ORDER = { "COMMON", "UNCOMMON", "RARE", "LEGENDARY", "ALMOST_UNIQUE", "UNIQUE" }

function whiteboard_scene:init()
    self.mode = "squads"        -- "squads" | "blessings"
    self.categorize = "rarity"  -- "rarity" | "tag" | "mana"
    self.scroll = 0
end

function whiteboard_scene:enter()
    if not g.hasRun() then
        g.newTestRun()
    end
    self.scroll = 0
end

function whiteboard_scene:leave() end

---@param dt number
function whiteboard_scene:update(dt) end

function whiteboard_scene:keypressed(key)
    if key == "escape" then
        g.gotoScene("title_scene")
    end
end

function whiteboard_scene:wheelmoved(dx, dy)
    self.scroll = self.scroll - dy * 30
    if self.scroll < 0 then self.scroll = 0 end
end

-- Returns ordered list of {label, color, ids} groups for the current mode+categorize.
function whiteboard_scene:buildGroups()
    local isSquad = self.mode == "squads"
    local ids = isSquad and g.getSquadList() or g.getBlessingList()
    local function getInfo(id)
        return isSquad and g.getSquadInfo(id) or g.getBlessingInfo(id)
    end

    local groups = {}      -- ordered array of {key,label,color,ids}
    local byKey = {}       -- key -> group

    local function group(key, label, color)
        local gr = byKey[key]
        if not gr then
            gr = { key = key, label = label, color = color, ids = {} }
            byKey[key] = gr
            groups[#groups + 1] = gr
        end
        return gr
    end

    if self.categorize == "rarity" then
        for _, rid in ipairs(RARITY_ORDER) do
            local r = g.RARITIES[rid]
            group(rid, r.name, r.color)
        end
        for _, id in ipairs(ids) do
            local info = getInfo(id)
            local rid = info.rarity.id
            local gr = byKey[rid] or group(rid, info.rarity.name, info.rarity.color)
            gr.ids[#gr.ids + 1] = id
        end

    elseif self.categorize == "mana" then
        for _, m in ipairs(g.getManaTypelist()) do
            group(m, m, g.getManaInfo(m).color)
        end
        group("none", "colorless", objects.Color.WHITE)
        for _, id in ipairs(ids) do
            local info = getInfo(id)
            local key
            if isSquad then
                key = "none"
                for _, m in ipairs(g.getManaTypelist()) do
                    if info.cost[m] then key = m break end
                end
            else
                key = info.mana or "none"
            end
            local gr = byKey[key] or group(key, key, objects.Color.WHITE)
            gr.ids[#gr.ids + 1] = id
        end

    else -- tag
        group("untagged", "untagged", objects.Color.GRAY)
        for _, id in ipairs(ids) do
            local info = getInfo(id)
            local tags = info.tags
            if not tags or #tags == 0 then
                byKey["untagged"].ids[#byKey["untagged"].ids + 1] = id
            else
                for _, t in ipairs(tags) do
                    local gr = byKey[t] or group(t, t, objects.Color.WHITE)
                    gr.ids[#gr.ids + 1] = id
                end
            end
        end
    end

    -- drop empty groups
    local out = {}
    for _, gr in ipairs(groups) do
        if #gr.ids > 0 then out[#out + 1] = gr end
    end
    return out
end

function whiteboard_scene:draw()
    lg.clear(0.07, 0.07, 0.09, 1)
    ui.startUI(UI_SCALE)
    -- drawing at UI_SCALE doubles the virtual space, so enlarge the root region to fill it.
    local screen = ui.getScreenRegion():scale(1 / UI_SCALE)
    local font = g.getSmallFont(16)

    local sidebar, rest = screen:splitHorizontalExact(100, 0)
    local main, preview = rest:splitHorizontalExact(0, PREVIEW_W)

    -- sidebar buttons
    local sb = sidebar:padUnit(8)
    local rows = sb:columns(10)
    if ui.DefaultButton(self.mode == "squads" and "SQUADS" or "BLESSINGS", rows[2]) then
        self.mode = self.mode == "squads" and "blessings" or "squads"
        self.scroll = 0
    end
    local cats = { "rarity", "tag", "mana" }
    for i, c in ipairs(cats) do
        local sel = self.categorize == c
        local label = (sel and "{c r=1 g=1 b=0.5}> " or "") .. c
        if ui.DefaultButton(label, rows[i + 3]) then
            self.categorize = c
            self.scroll = 0
        end
    end

    -- main grid
    local mx, my, mw, mh = main:padUnit(8):get()
    -- regionToScreenspace uses the base UI transform, but we drew at UI_SCALE,
    -- so scale the scissor rect down to match.
    local sx, sy, sw, sh = ui.regionToScreenspace(main)
    lg.setScissor(sx * UI_SCALE, sy * UI_SCALE, sw * UI_SCALE, sh * UI_SCALE)

    local groups = self:buildGroups()
    local icon = self.mode == "squads" and ICON or ICON * 0.6
    local cell = self.mode == "squads" and CELL or icon + 2
    local cols = math.max(1, math.floor(mw / cell))
    local y = my - self.scroll
    local hoveredId = nil
    local labels = {}

    for _, gr in ipairs(groups) do
        labels[#labels + 1] = { y = y, color = gr.color, label = gr.label, count = #gr.ids }
        y = y + LABEL_H
        for i, id in ipairs(gr.ids) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local ix = mx + col * cell + icon / 2
            local iy = y + row * cell + icon / 2
            lg.setColor(1, 1, 1)
            if self.mode == "squads" then
                g.drawSquadIcon(id, ix, iy, true)
            else
                g.drawBlessingIcon(id, ix, iy)
            end
            if iml.isHovered(ix - icon / 2, iy - icon / 2, icon, icon, gr.key .. id) then
                hoveredId = id
            end
        end
        local usedRows = math.ceil(#gr.ids / cols)
        y = y + usedRows * cell + GROUP_GAP
    end

    for _, lbl in ipairs(labels) do
        lg.setColor(lbl.color:getRGBA())
        richtext.printRichContainedNoWrap("{o}" .. tostring(lbl.label) .. " (" .. lbl.count .. ")", font, mx, lbl.y, mw, LABEL_H, "left")
    end

    lg.setScissor()

    -- preview card on the right
    if hoveredId then
        local pr = preview:padUnit(6)
        if self.mode == "squads" then
            ui.drawSquadCard(hoveredId, pr, -999, false, true)
        else
            ui.drawBlessingCard(hoveredId, pr, 999)
        end
    end

    ui.endUI()
end


return whiteboard_scene
