--[[
EXAMPLE:
    local box = ui.Box(
        {maxWidth = 200, padding = 8, spacing = 4},
        function(x, y, w, h)  -- optional background drawer
            lg.setColor(0.1, 0.1, 0.15, 0.9)
            lg.rectangle("fill", x, y, w, h, 4, 4)
        end
    )
    box:addText("Title", titleFont)
    box:addSpacing(2)
    box:addText("Body text with {o}rich text{/o}.", bodyFont)
    box:add({
        getHeight = function() return 20 end,
        draw = function(x, y, w, h)
            lg.setColor(0.3, 0.7, 0.4)
            lg.rectangle("fill", x, y, w, h)
        end,
    })
    local totalW, totalH = box:render(10, 10)
]]


---@class ui.Box
---@field private entries table[]
---@field private padding number
---@field private spacing number
---@field private maxWidth number
---@field private drawBg fun(x:number,y:number,w:number,h:number)?
local Box = {}
Box.__index = Box

function Box.new(args, drawBg)
    return setmetatable({
        entries = {},
        padding = args.padding or 0,
        spacing = args.spacing or 0,
        maxWidth = args.maxWidth,
        drawBg = drawBg,
    }, Box)
end

function Box:addText(txt, font)
    self.entries[#self.entries + 1] = { type = "text", txt = txt, font = font }
end

function Box:add(child)
    self.entries[#self.entries + 1] = { type = "custom", child = child }
end

function Box:addSpacing(h)
    self.entries[#self.entries + 1] = { type = "spacing", h = h }
end

function Box:measure()
    local pad = self.padding
    local sp = self.spacing
    local innerW = self.maxWidth - pad * 2

    local heights = {}
    local totalH = 0
    for i, e in ipairs(self.entries) do
        local h
        if e.type == "text" then
            local _, lines = richtext.getWrap(e.txt, e.font, innerW)
            h = lines * e.font:getHeight()
        elseif e.type == "custom" then
            h = e.child.getHeight(innerW)
        else -- spacing
            h = e.h
        end
        heights[i] = h
        totalH = totalH + h
    end

    local n = #self.entries
    local totalW = self.maxWidth
    local totalHeight = totalH + (n > 1 and sp * (n - 1) or 0) + pad * 2
    return totalW, totalHeight, heights
end

function Box:render(x, y)
    local pad = self.padding
    local sp = self.spacing
    local innerW = self.maxWidth - pad * 2
    local totalW, totalHeight, heights = self:measure()

    -- draw bg
    if self.drawBg then
        self.drawBg(x, y, totalW, totalHeight)
    end

    -- draw entries
    local n = #self.entries
    local cy = y + pad
    for i, e in ipairs(self.entries) do
        local ex = x + pad
        if e.type == "text" then
            richtext.printRich(e.txt, e.font, ex, cy, innerW, "left")
        elseif e.type == "custom" then
            e.child.draw(ex, cy, innerW, heights[i])
        end
        cy = cy + heights[i]
        if i < n then
            cy = cy + sp
        end
    end

    return totalW, totalHeight
end




---@class ui.HBox
---@field private entries table[]
---@field private padding number
---@field private spacing number
---@field private maxHeight number?
---@field private drawBg fun(x:number,y:number,w:number,h:number)?
local HBox = {}
HBox.__index = HBox

function HBox.new(args, drawBg)
    return setmetatable({
        entries = {},
        padding = args.padding or 0,
        spacing = args.spacing or 0,
        maxHeight = args.maxHeight,
        drawBg = drawBg,
    }, HBox)
end

function HBox:addText(txt, font)
    self.entries[#self.entries + 1] = { type = "text", txt = txt, font = font }
end

function HBox:add(child)
    self.entries[#self.entries + 1] = { type = "custom", child = child }
end

function HBox:addSpacing(w)
    self.entries[#self.entries + 1] = { type = "spacing", w = w }
end

function HBox:measure()
    local pad = self.padding
    local sp = self.spacing

    local widths = {}
    local maxH = 0
    for i, e in ipairs(self.entries) do
        local w, h
        if e.type == "text" then
            w = richtext.getWidth(e.txt, e.font)
            h = e.font:getHeight()
        elseif e.type == "custom" then
            w = e.child.getWidth()
            h = e.child.getHeight and e.child.getHeight() or 0
        else -- spacing
            w = e.w
            h = 0
        end
        widths[i] = w
        if h > maxH then maxH = h end
    end

    local n = #self.entries
    local totalW = 0
    for _, w in ipairs(widths) do totalW = totalW + w end
    totalW = totalW + (n > 1 and sp * (n - 1) or 0) + pad * 2
    local totalH = maxH + pad * 2
    return totalW, totalH, widths, maxH
end

function HBox:render(x, y)
    local pad = self.padding
    local sp = self.spacing
    local totalW, totalH, widths, maxH = self:measure()

    if self.drawBg then
        self.drawBg(x, y, totalW, totalH)
    end

    local n = #self.entries
    local cx = x + pad
    for i, e in ipairs(self.entries) do
        local ey = y + pad
        if e.type == "text" then
            richtext.printRich(e.txt, e.font, cx, ey, widths[i], "left")
        elseif e.type == "custom" then
            e.child.draw(cx, ey, widths[i], maxH)
        end
        cx = cx + widths[i]
        if i < n then
            cx = cx + sp
        end
    end

    return totalW, totalH
end

return { Box = Box, HBox = HBox }
