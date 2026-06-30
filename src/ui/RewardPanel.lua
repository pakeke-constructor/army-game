

---@class g.RewardPanel: objects.Class
local RewardPanel = objects.Class("g:RewardPanel")

---@class g.RewardPanel.XPReward
---@field type "xp"
---@field amount integer

---@class g.RewardPanel.GoldReward
---@field type "gold"
---@field amount integer

---@class g.RewardPanel.SquadReward
---@field type "squad"
---@field rerolls integer? (0 = no reroll)

---@class g.RewardPanel.BlessingReward
---@field type "blessing"

---@class g.RewardPanel.ManaReward
---@field type "mana"

---@class g.RewardPanel.ManaBlessingReward
---@field type "mana_blessing"

---@alias g.RewardPanel.Any
---| g.RewardPanel.XPReward
---| g.RewardPanel.GoldReward
---| g.RewardPanel.SquadReward
---| g.RewardPanel.BlessingReward
---| g.RewardPanel.ManaReward
---| g.RewardPanel.ManaBlessingReward

---@class g.RewardPanel.ORReward
---@field type "or"
---@field a g.RewardPanel.Any (LHS)
---@field b g.RewardPanel.Any (RHS)

---@alias g.RewardPanel.Rewards (g.RewardPanel.ORReward|g.RewardPanel.Any)[]

---@param typ "levelup"|"battle"|"other"
---@param args g.RewardPanel.Rewards
function RewardPanel:init(typ, args)
    self.type = typ
    self.rewards = args
end



---@return boolean
function RewardPanel:hasAnyRewards()
    return #self.rewards > 0
end




local BATTLE_REWARDS_TXT = loc("Rewards", {}, {
    context = "As in, the rewards after battle / level-up"
})

local LEVEL_UP_TXT = loc("Level Up!", {}, {
    context = "As in, at title showing a reward screen after battle / level-up"
})

local OR_TEXT = loc("OR", {}, {
    context = "A binary choice of option"})





local BROWN_COL = objects.Color("FF9B6F57")
local colStr = ("{c r=%.2f g=%.2f b=%.2f}"):format(
    objects.Color("FFBBA7A7"):getRGBA()
)

local NEW_SQUAD =  "{recruit_icon} ".. colStr .. loc("Recruit new squads!")

local NEW_BLESSING = "{blessing_icon} " ..colStr .. loc("Get random Blessing!")

local NEW_MANA =  "{mana_colorless_large} " .. colStr .. loc("Gain a Mana crystal!")

local MANA_AND_BLESSING = "{mana_colorless_large} {blessing_icon} " .. colStr .. loc("Choose Mana + Blessing!")



function RewardPanel:draw()
    iml.panel(ui.getFullScreenRegion():get())

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
            local txt = self.type == "levelup" and LEVEL_UP_TXT or BATTLE_REWARDS_TXT
            local embelPad = 50
            local padW = richtext.getWidth(txt, LARGE_FONT) / 2 + embelPad
            lg.setColor(1,1,1)
            g.drawImage(IMG, x+w/2+padW, y+h/2, 0, 1,1)
            g.drawImage(IMG, x+w/2-padW, y+h/2, 0, -1,1)
            lg.setColor(BROWN_COL)
            richtext.printRichContained(txt, LARGE_FONT, x,y,w,h)
        end,
    })

    local pad = 4

    ---@param baseR kirigami.Region
    ---@param txt string
    ---@param cb function
    local function drawButton(baseR, txt, cb)
        lg.setColor(0, 0, 0)
        local isHovered = iml.isHovered(baseR:get())
        if isHovered then
            lg.setColor(0.05,0.05,0.15)
        end
        ui.drawSingleColorPanel(baseR:get())
        if not isHovered then
            lg.setColor(1, 0.85, 0.3, 0.2)
            -- g.drawImage("glow_lootreward", x + w/2, y + h/2, 0, w/78, h/14)
        end
        lg.setColor(1,1,1)
        richtext.printRich(txt, SMALL_FONT, baseR.x, baseR.y + pad, baseR.w - pad, "center")
        if iml.wasJustClicked(baseR:get()) then
            cb()
        end
        if iml.wasJustHovered(baseR:get()) then
            -- play sound
            g.playUISound("ui_tick")
        end
    end

    local boxH = SMALL_FONT:getHeight() + pad*2
    ---@param txt string
    ---@param callback function
    local function addBar(txt, callback)
        box:add({
            getHeight = function(w)
                return boxH
            end,
            draw = function(x, y, w, h)
                return drawButton(Kirigami(x,y,w,h), txt, callback)
            end
        })
    end

    for i, v in ipairs(self.rewards) do
        if v.type == "or" then
            box:add({
                getHeight = function(w)
                    return boxH
                end,
                draw = function(x, y, w, h)
                    local OR_PADDING = 8
                    lg.setColor(0,0,0)
                    local baseR = Kirigami(x, y, w, h)
                    local leftR, midR, rightR = baseR:splitHorizontalExact(
                        0, LARGE_FONT:getWidth(OR_TEXT) + OR_PADDING * 2, 0
                    )

                    -- Draw the 'OR' text
                    lg.setColor(BROWN_COL)
                    richtext.printRichContainedNoWrap(OR_TEXT, LARGE_FONT, midR:padUnit(OR_PADDING, 0):get())
                    lg.setColor(1, 1, 1)

                    -- Draw left and right
                    for _, b in ipairs({{v.a, leftR}, {v.b, rightR}}) do
                        if b[1].type == "xp" then
                            drawButton(b[2], "{xp_icon}{XP_COLOR} "..tostring(b[1].amount), function()
                                g.addXP(b[1].amount)
                                table.remove(self.rewards, i)
                            end)
                        elseif b[1].type == "gold" then
                            drawButton(b[2], "{coin_icon}{GOLD_COLOR} "..tostring(b[1].amount), function()
                                g.addGold(b[1].amount)
                                table.remove(self.rewards, i)
                            end)
                        elseif b[1].type == "squad" then
                            drawButton(b[2], NEW_SQUAD, function()
                                choicePopupService.set("squad", b[1].rerolls or 0)
                                table.remove(self.rewards, i)
                            end)
                        elseif b[1].type == "blessing" then
                            drawButton(b[2], NEW_BLESSING, function()
                                choicePopupService.set("blessing")
                                table.remove(self.rewards, i)
                            end)
                        elseif b[1].type == "mana" then
                            drawButton(b[2], NEW_MANA, function()
                                choicePopupService.set("mana")
                                table.remove(self.rewards, i)
                            end)
                        elseif b[1].type == "mana_blessing" then
                            drawButton(b[2], MANA_AND_BLESSING, function()
                                choicePopupService.set("mana_blessing")
                                table.remove(self.rewards, i)
                            end)
                        end
                    end
                end
            })
        elseif v.type == "xp" then
            addBar("{xp_icon}{XP_COLOR} "..tostring(v.amount), function()
                g.addXP(v.amount)
                table.remove(self.rewards, i)
            end)
        elseif v.type == "gold" then
            addBar("{coin_icon}{GOLD_COLOR} "..tostring(v.amount), function()
                g.addGold(v.amount)
                table.remove(self.rewards, i)
            end)
        elseif v.type == "squad" then
            addBar(NEW_SQUAD, function()
                choicePopupService.set("squad", v.rerolls or 0)
                table.remove(self.rewards, i)
            end)
        elseif v.type == "blessing" then
            addBar(NEW_BLESSING, function()
                choicePopupService.set("blessing")
                table.remove(self.rewards, i)
            end)
        elseif v.type == "mana" then
            addBar(NEW_MANA, function()
                choicePopupService.set("mana")
                table.remove(self.rewards, i)
            end)
        elseif v.type == "mana_blessing" then
            addBar(MANA_AND_BLESSING, function()
                choicePopupService.set("mana_blessing")
                table.remove(self.rewards, i)
            end)
        else
            error("Unknown reward type: "..tostring(v.type))
        end
    end

    box:render(r.x,r.y)
end




return RewardPanel

