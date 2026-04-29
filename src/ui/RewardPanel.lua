

---@class g.RewardPanel: objects.Class
local RewardPanel = objects.Class("g:RewardPanel")


---@class g.RewardPanel.Rewards
---@field gold integer?
---@field xp integer?
---@field randomSquad boolean?
---@field randomBlessing boolean?



---@param args g.RewardPanel.Rewards
function RewardPanel:init(args)
    self.gold = args.gold
    self.xp = args.xp
    self.randomSquad = args.randomSquad
    self.randomBlessing = args.randomBlessing
end



---@return boolean
function RewardPanel:hasAnyRewards()
    return not not (self.gold or self.xp or self.randomBlessing or self.randomSquad)
end




local REWARDS_TXT = loc("Rewards", {}, {
    context = "As in, the rewards after battle"
})



local BROWN_COL = objects.Color("FF9B6F57")
local colStr = ("{c r=%.2f g=%.2f b=%.2f}"):format(
    objects.Color("FFBBA7A7"):getRGBA()
)

local NEW_SQUAD =  "{recruit_icon} ".. colStr .. loc("Recruit new troops!")

local NEW_BLESSING = "{blessing_icon} " ..colStr .. loc("Get random Blessing!")



function RewardPanel:draw()
    local r = ui.getScreenRegion()

    r = r:padRatio(0.2)

    ---@type ui.Box
    local box = ui.Box({maxWidth = r.w, padding = 12, spacing = 8}, function(bx, by, bw, bh)
        love.graphics.setColor(1,1,1)
        ui.drawDarkPanel(bx, by, bw, bh)
        lg.setColor(BROWN_COL)
        ui.drawPanel(bx-4, by-4, bw+8, bh+8)
    end)

    local LARGE_FONT = g.getBigFont(32)
    local SMALL_FONT = g.getBigFont(16)

    local IMG = "victory_embelishment"

    box:add({
        getHeight = function(w)
            local _,_,_,hh = g.getImageQuad(IMG):getViewport()
            return math.max(LARGE_FONT:getHeight(), hh)
        end,
        draw = function(x,y,w,h)
            local embelPad = 50
            local padW = richtext.getWidth(REWARDS_TXT, LARGE_FONT) / 2 + embelPad
            lg.setColor(1,1,1)
            g.drawImage(IMG, x+w/2+padW, y+h/2, 0, 1,1)
            g.drawImage(IMG, x+w/2-padW, y+h/2, 0, -1,1)
            lg.setColor(BROWN_COL)
            richtext.printRichContained(REWARDS_TXT, LARGE_FONT, x,y,w,h)
        end,
    })

    local pad = 4
    local boxH = SMALL_FONT:getHeight() + pad*2
    local function addBar(txt, callback)
        box:add({
            getHeight = function(w)
                return boxH
            end,
            draw = function(x, y, w, h)
                lg.setColor(0,0,0)
                local isHovered = iml.isHovered(x,y,w,h)
                if isHovered then
                    lg.setColor(0.05,0.05,0.15)
                end
                ui.drawSingleColorPanel(x, y, w, h)
                if not isHovered then
                    lg.setColor(1, 0.85, 0.3, 0.2)
                    g.drawImage("glow_lootreward", x + w/2, y + h/2, 0, w/78, h/14)
                end
                lg.setColor(1,1,1)
                richtext.printRich(txt, SMALL_FONT, x,y+pad, w, "center")
                if iml.wasJustClicked(x,y,w,h) then
                    callback()
                end
                if iml.wasJustHovered(x,y,w,h) then
                    -- play sound
                    g.playUISound("ui_tick")
                end
            end
        })
    end

    if self.gold and self.gold > 0 then
        addBar("{coin_icon}{GOLD_COLOR} " .. tostring(self.gold), function()
            g.addGold(self.gold)
            self.gold = nil
        end)
    end

    if self.xp and self.xp > 0 then
        addBar("{xp_icon}{XP_COLOR} " .. tostring(self.xp), function()
            g.addXP(self.xp)
            self.xp = nil
        end)
    end

    if self.randomBlessing then
        addBar(NEW_BLESSING, function()
            choicePopupService.set("blessing")
            self.randomBlessing = nil
        end)
    end

    if self.randomSquad then
        addBar(NEW_SQUAD, function()
            choicePopupService.set("squad")
            self.randomSquad = nil
        end)
    end

    box:render(r.x,r.y)
end




return RewardPanel

