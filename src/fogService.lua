

local fogService = {}


local FOG_COLOR = objects.Color("FF361919")

local FOG_STEP = 20
local FOGS={
"fog_of_war_cloud1",
"fog_of_war_cloud2",
"fog_of_war_cloud3",
}


---@param r kirigami.Region
---@param hasFog fun(x:number,y:number):boolean
function fogService.renderFog(r, hasFog)
    local t = love.timer.getTime()
    lg.setColor(FOG_COLOR)
    local x1 = math.floor(r.x / FOG_STEP) * FOG_STEP
    local y1 = math.floor(r.y / FOG_STEP) * FOG_STEP
    local x2 = math.ceil((r.x + r.w) / FOG_STEP) * FOG_STEP
    local y2 = math.ceil((r.y + r.h) / FOG_STEP) * FOG_STEP
    for x = x1, x2, FOG_STEP do
        for y = y1, y2, FOG_STEP do
            if hasFog(x,y) then
                local i = helper.hashInteger(math.floor(x*33.4 + y*77.65))
                g.drawImage(FOGS[i%#FOGS+1], x,y, math.sin(t+(i%100)/100))
            end
        end
    end
end



return fogService

