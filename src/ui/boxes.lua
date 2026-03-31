

---@class ui.Child
---@field draw fun(self:table, x:number, y:number, w:number, h:number)
---@field getSize fun(self:table): number,number
local Child


---@alias boxes.Region {x:number, y:number, w:number, h:number}

---@class ui.BoxArgs
---@field maxWidth number if children want to be bigger, they can request to expand to this size
---@field maxHeight number if children want to be bigger, they can request to expand to this size
---@field childSeparation number 
---@field padding number
---@field region boxes.Region
local BoxArgs


local boxes = {}


---@param args ui.BoxArgs
---@param children ui.Child[]
function boxes.horizontalBox(args, children)
    if #children == 0 then return end
    local pad = args.padding or 0
    local sep = args.childSeparation or 0
    local rx, ry, rw, rh = args.region.x, args.region.y, args.region.w, args.region.h

    -- inner area after padding
    local ix = rx + pad
    local iy = ry + pad
    local iw = rw - pad * 2
    local ih = rh - pad * 2

    -- measure children
    local sizes = {}
    local totalW = 0
    for i, child in ipairs(children) do
        local cw, ch = child:getSize()
        sizes[i] = {w = cw, h = ch}
        totalW = totalW + cw
    end
    totalW = totalW + sep * (#children - 1)

    -- clamp total width to available inner width
    local maxW = args.maxWidth or iw
    local availW = math.min(maxW, iw)

    -- scale factor if children overflow
    local scale = (totalW > availW) and (availW / totalW) or 1

    -- lay out left to right
    local cx = ix
    for i, child in ipairs(children) do
        local cw = sizes[i].w * scale
        local ch = math.min(sizes[i].h, args.maxHeight or ih, ih)
        child:draw(cx, iy, cw, ch)
        cx = cx + cw + sep * scale
    end
end


---@param args ui.BoxArgs
---@param children ui.Child[]
function boxes.verticalBox(args, children)
    if #children == 0 then return end
    local pad = args.padding or 0
    local sep = args.childSeparation or 0
    local rx, ry, rw, rh = args.region.x, args.region.y, args.region.w, args.region.h

    -- inner area after padding
    local ix = rx + pad
    local iy = ry + pad
    local iw = rw - pad * 2
    local ih = rh - pad * 2

    -- measure children
    local sizes = {}
    local totalH = 0
    for i, child in ipairs(children) do
        local cw, ch = child:getSize()
        sizes[i] = {w = cw, h = ch}
        totalH = totalH + ch
    end
    totalH = totalH + sep * (#children - 1)

    -- clamp total height to available inner height
    local maxH = args.maxHeight or ih
    local availH = math.min(maxH, ih)

    -- scale factor if children overflow
    local scale = (totalH > availH) and (availH / totalH) or 1

    -- lay out top to bottom
    local cy = iy
    for i, child in ipairs(children) do
        local cw = math.min(sizes[i].w, args.maxWidth or iw, iw)
        local ch = sizes[i].h * scale
        child:draw(ix, cy, cw, ch)
        cy = cy + ch + sep * scale
    end
end


function boxes.text(txt, background)
    local font = g.getSmallFont(16)
    -- if background, then: draws single-color-ui-panel behind txt

    local stripped = richtext.getWrap(txt, font, )
    local w,h = font:getWidth()
end


return boxes


--[[

API IDEA:

- we want 2-pass
- we ALSO want the ease and strength of kirigami.

IS THERE A WAY WE CAN HAVE 2-PASS WITH KIRIGAMI?


]]

