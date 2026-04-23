

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




local REWARDS_TXT = loc("Rewards", {}, {
    context = "As in, the rewards after battle"
})



function RewardPanel:draw()
    local r = ui.getScreenRegion()

    r = r:padRatio(0.2)

    ---@type ui.Box
    local box = ui.Box({maxWidth = r.w, padding = 12, spacing = 8}, function(bx, by, bw, bh)
        love.graphics.setColor(1,1,1)
        ui.drawDarkPanel(bx, by, bw, bh)
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
            richtext.printRichContained(REWARDS_TXT, LARGE_FONT, x,y,w,h)
        end,
    })

    local pad = 4
    local boxH = SMALL_FONT:getHeight() + pad*2
    local function addBar(txt)
        box:add({
            getHeight = function(w)
                return boxH
            end,
            draw = function(x, y, w, h)
                lg.setColor(0,0,0)
                ui.drawSingleColorPanel(x, y, w, h)
                lg.setColor(1,1,1)
                richtext.printRich(txt, SMALL_FONT, x,y+pad, w, "center")
            end
        })
    end

    if self.gold then
        addBar("{coin_icon}{GOLD_COLOR} " .. tostring(self.gold))
    end

    if self.xp then
        addBar("{xp_icon}{XP_COLOR} " .. tostring(self.xp))
    end

    if self.randomBlessing then
        addBar("{coin_icon} " .. tostring(self.gold))
    end

    if self.randomSquad then
        addBar("{coin_icon} " .. tostring(self.gold))
    end

    box:render(r.x,r.y)
end




return RewardPanel

