


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



---@param args ui.BoxArgs
---@param children ui.Child[]
local function horizontalBox(args, children)

end


local function verticalBox()

end



--[[

horizontalBox(args, {
    child1,
    child2,
    child3
})


verticalBox(args, {
    child1,
    child2,
    child3
})



]]
