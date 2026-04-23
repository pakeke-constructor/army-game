local newPicker = require("src.modules.Picker")

local godrays = require("src.modules.godrays.godrays")


---@class g.RewardPanel: objects.Class
local RewardPanel = objects.Class("g:RewardPanel")


local NUM_CHOICES = 3


---@param rType "squad"|"blessing"|"mana"
---@param rarityMapping g.RarityMapping?
function RewardPanel:init(rType, rarityMapping)
    self.rType = rType
    self.choices = {}
    self.rarityMapping = rarityMapping or consts.DEFAULT_RARITY_MAPPING
    self.timeSincePicked = nil
    self.timeSinceFirstDraw = nil
    self.selectedI = nil

    local manaCells = g.getRun().mana

    if rType == "squad" then
        local pool = g.getSquadsByMana(manaCells)
        self:_pickFromPool(pool, function(id) return g.getSquadInfo(id) end)
    elseif rType == "blessing" then
        local pool = g.getBlessingsByMana(manaCells)
        self:_pickFromPool(pool, function(id) return g.getBlessingInfo(id) end)
    end
end


---@private
function RewardPanel:_pickFromPool(pool, getInfo)
    if #pool == 0 then return end
    local weights = {}
    for i, id in ipairs(pool) do
        local info = getInfo(id)
        weights[i] = self.rarityMapping[info.rarity.id] or 0
    end
    local picker = newPicker(pool, weights)
    local seen = {}
    for _ = 1, NUM_CHOICES do
        local pick = picker:pick()
        -- avoid duplicates; try a few times
        for _ = 1, 20 do
            if not seen[pick] then break end
            pick = picker:pick()
        end
        seen[pick] = true
        self.choices[#self.choices + 1] = pick
    end
end


local PICKANIMATION_FADE_TO_WHITE_TIME = 0.15
local PICKANIMATION_COLLAPSE_TIME = 0.12

local PICK_ANIMATION_TIME = PICKANIMATION_COLLAPSE_TIME + PICKANIMATION_FADE_TO_WHITE_TIME




---@param self g.RewardPanel
---@param regions kirigami.Region[]
---@param i integer
---@param ww number
---@param hh number
local function doFancyAnim(self, regions, i, ww,hh)
    if not self.timeSincePicked then
        return
    end

    local t = self.timeSincePicked
    local r = regions[i]

    local col = objects.Color.CRIMSON:darken(0.55)
    if i ~= self.selectedI then
        col = col:darken(0.3)
    end

    lg.setColor(col[1],col[2],col[3])

    local function drawPanel(x,y,w,h)
        ui.drawSingleColorPanel(x,y,w,h)
        lg.setColor(objects.Color.BLACK)
        ui.drawPanel(x,y,w,h)
    end

    if t < PICKANIMATION_FADE_TO_WHITE_TIME then
        -- draw outline, fading to white
        lg.setColor(col[1],col[2],col[3], t/PICKANIMATION_FADE_TO_WHITE_TIME)
        drawPanel(r.x, r.y, ww,math.max(hh,r.h))
    elseif t < PICKANIMATION_FADE_TO_WHITE_TIME + PICKANIMATION_COLLAPSE_TIME then
        -- draw panel collapsing
        local ratio1 = (t-PICKANIMATION_FADE_TO_WHITE_TIME)/PICKANIMATION_COLLAPSE_TIME
        local ratioInv = 1 - ratio1
        local h = math.max(hh,r.h)
        if self.selectedI == i then
            drawPanel(r.x + ww*ratio1/2, r.y, ww*ratioInv, h)
        else
            drawPanel(r.x + ww*ratio1/2, r.y + h*ratio1/2, ww*ratioInv, h*ratioInv)
        end
    end
end


function RewardPanel:draw()
    local dt = love.timer.getAverageDelta()
    if self.timeSincePicked then
        self.timeSincePicked = self.timeSincePicked + dt
    end
    self.timeSinceFirstDraw = (self.timeSinceFirstDraw or 0) + dt

    local r = ui.getFullScreenRegion()
    local cardArea = r:padRatio(0.05, 0.1)
    local regions = cardArea:grid(#self.choices, 1)
    for i,rr in ipairs(regions) do
        regions[i] = rr:padRatio(0.15)
    end

    ---@param i integer
    local function drawCard(i)
        local rew = self.choices[i]
        local f = self.rType == "squad" and ui.drawSquadCard or ui.drawBlessingCard
        local reg = regions[i]
        local clicked, ww,hh = false, reg.w, reg.h
        if (not self.timeSincePicked) or self.timeSincePicked < PICKANIMATION_FADE_TO_WHITE_TIME then
            clicked,ww,hh = f(rew, regions[i], i)
        end
        if clicked then
            self.selectedI = i
            self.timeSincePicked = 0
        end
        doFancyAnim(self, regions, i, ww,hh)
    end

    for i = 1, #regions do
        drawCard(i)
    end

    return self.timeSincePicked and self.timeSincePicked > PICK_ANIMATION_TIME
end




return RewardPanel

