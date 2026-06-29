local hoverService = require("src.hud.hoverService")

local lg = love.graphics

---@class g.WhiteboardScene
local whiteboard_scene = {}

local ICON = 32
local CELL = 40   -- icon + gap
local GROUP_GAP = 14
local LABEL_H = 18

-- category modes
local RARITY_ORDER = { "COMMON", "UNCOMMON", "RARE", "LEGENDARY", "ALMOST_UNIQUE", "UNIQUE" }

function whiteboard_scene:init()
    self.mode = "squads"        -- "squads" | "blessings"
    self.categorize = "rarity"  -- "rarity" | "tag" | "mana"
    self.scroll = 0
end

function whiteboard_scene:enter()
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

function whiteboard_scene:requestIconHover(id)
    local isSquad = self.mode == "squads"
    local info = isSquad and g.getSquadInfo(id) or g.getBlessingInfo(id)
    hoverService.requestHover(function(box, fonts)
        box:addText("{c r=1 g=1 b=1}" .. info.name, fonts.title)
        box:addText("{c r=0.7 g=0.7 b=0.75}" .. id, fonts.body)
        box:addText("{c r=0.8 g=0.7 b=0.4}" .. info.rarity.name, fonts.body)
        local tags = info.tags
        if tags and #tags > 0 then
            box:addText("{c r=0.6 g=0.8 b=0.9}" .. table.concat(tags, ", "), fonts.body)
        end
    end)
end

function whiteboard_scene:draw()
    lg.clear(0.07, 0.07, 0.09, 1)
    ui.startUI()
    local screen = ui.getScreenRegion()
    local font = g.getSmallFont(16)

    local sidebar, main = screen:splitHorizontalExact(120, 0)

    -- sidebar buttons
    local sb = sidebar:padUnit(8)
    local rows = sb:rows(8)
    if ui.DefaultButton(self.mode == "squads" and "SQUADS" or "BLESSINGS", rows[1]) then
        self.mode = self.mode == "squads" and "blessings" or "squads"
        self.scroll = 0
    end
    local cats = { "rarity", "tag", "mana" }
    for i, c in ipairs(cats) do
        local sel = self.categorize == c
        local label = (sel and "{c r=1 g=1 b=0.5}> " or "") .. c
        if ui.DefaultButton(label, rows[i + 2]) then
            self.categorize = c
            self.scroll = 0
        end
    end

    -- main grid
    local mx, my, mw, mh = main:padUnit(8):get()
    lg.setScissor(ui.regionToScreenspace(main))

    local groups = self:buildGroups()
    local cols = math.max(1, math.floor(mw / CELL))
    local y = my - self.scroll

    for _, gr in ipairs(groups) do
        lg.setColor(gr.color:getRGBA())
        richtext.printRichContainedNoWrap("{o}" .. tostring(gr.label) .. " (" .. #gr.ids .. ")", font, mx, y, mw, LABEL_H, "left")
        y = y + LABEL_H
        for i, id in ipairs(gr.ids) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local ix = mx + col * CELL + ICON / 2
            local iy = y + row * CELL + ICON / 2
            lg.setColor(1, 1, 1)
            if self.mode == "squads" then
                g.drawSquadIcon(id, ix, iy, false)
            else
                g.drawBlessingIcon(id, ix, iy)
            end
            if iml.isHovered(ix - ICON / 2, iy - ICON / 2, ICON, ICON, gr.key .. id) then
                self:requestIconHover(id)
            end
        end
        local usedRows = math.ceil(#gr.ids / cols)
        y = y + usedRows * CELL + GROUP_GAP
    end

    self._contentH = (y + self.scroll) - my
    lg.setScissor()

    hoverService.draw()
    ui.endUI()
end

return whiteboard_scene
