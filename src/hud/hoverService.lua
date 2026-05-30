
--[[
hoverService:

Support for hovering-mouse, and panels.
Used When the player hovers something with their mouse, and a panel pops up explaining.


Useful for:
- hovering map-nodes
- hovering keywords/traits
- basically anything where the player wants to hover something, and have it be explained


Assumptions:
- Only 1 hover-panel visible at once
- Hover-panel is rendered where mouse is
- Hover-panel is stateless, richtext only.
- Hover-panel uses `ui.Box` under the hood. Reconstruct every frame
- Stateless. If box isnt requested that frame, its not rendered.


FOR THE UI-SIDE:
SEE ui.Panel probably, and see how the ui.SquadCard implements the UI stuff.
Should use similar pixelart border, and similar fade


AGENT INSTRUCTIONS: YOU MUST NOT DELETE THIS COMMENT BLOCK.
]]

---@class g.hoverService
local hoverService = {}

local BORDER_COL = objects.Color(0.5, 0.45, 0.55)

local MAX_WIDTH = 180
local OFFSET_X = 12
local OFFSET_Y = 12

local pending = nil


--- Requests a hover panel this frame. Last request wins.
--- builder receives a ui.Box and the title/body fonts to populate freely.
---@param builder fun(box: ui.Box, fonts: {title: love.Font, body: love.Font})
function hoverService.requestHover(builder)
    local mx, my = ui.getMouse()
    pending = {
        mx = mx, my = my,
        builder = builder,
    }
end


--- renders the hover box
function hoverService.draw()
    if not pending then return end
    local p = pending
    pending = nil

    local col1, col2 = p.col1, p.col2
    local box = ui.Box({maxWidth = MAX_WIDTH, padding = 10, spacing = 4}, function(bx, by, bw, bh)
        love.graphics.setColor(1, 1, 1)
        -- helper.gradientRect("vertical", col1, col2, bx, by, bw, bh)
        love.graphics.setColor(BORDER_COL:getRGBA())
        ui.drawDarkPanel(bx, by, bw, bh)
    end)

    local fonts = {
        title = g.getBigFont(16),
        body = g.getSmallFont(16),
    }
    p.builder(box, fonts)

    local sw, sh = ui.getScaledUIDimensions()
    local totalW, totalH = box:measure()

    local x = p.mx + OFFSET_X
    local y = p.my + OFFSET_Y
    if x + totalW > sw then x = p.mx - totalW - OFFSET_X end
    -- flip tooltip above mouse if it would clip the bottom (so cursor doesn't cover it)
    if y + totalH > sh then y = p.my - totalH - OFFSET_Y end
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end

    box:render(x, y)
end


return hoverService
