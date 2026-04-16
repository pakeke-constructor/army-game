
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



--- Requests a richtext entry to be rendered this frame. Last request wins.
---@param mouseX number
---@param mouseY number
---@param title string title of box (richtext allows colors)
---@param body string description (also uses richtext, so can include images)
---@param col1? objects.Color gradient-1 (colors default to sensible values.)
---@param col2? objects.Color gradient-2
function hoverService.requestHover(mouseX, mouseY, title, body, col1,col2)

end


--- renders the hover box
function hoverService.draw()

end


return hoverService

