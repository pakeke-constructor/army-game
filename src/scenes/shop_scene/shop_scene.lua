local shop_scene = {}

function shop_scene:init()
end

function shop_scene:enter()
    self.hud = HUD()
end

function shop_scene:leave()
end

function shop_scene:pollHandlers()
    g.addBlessingHandlers()
end

function shop_scene:update(dt)
end

function shop_scene:mousepressed(mx, my, button, istouch, presses)
end

function shop_scene:mousereleased(mx, my, button, istouch)
end

function shop_scene:mousemoved(mx, my, dx, dy, istouch)
end

function shop_scene:keypressed(key, scancode, isrep)
end


function shop_scene:wheelmoved(dx, dy)
    self.hud:wheelmoved(dx, dy)
end




---@param money number
---@param r kirigami.Region 
---@param discount boolean?
local function drawCost(money, r, discount)
    local font = g.getSmallFont(16)
    local txt
    if g.getRun().money < money then
        -- cant afford! red color
        txt = "{coin_icon}{c r=0.6 g=0.1 b=0.05} " .. money
    elseif discount then
        txt = "{coin_icon}{c r=0.15 b=0.1 g=0.6} " .. money
    else
        txt = "{coin_icon}{GOLD_COLOR} " .. money
    end
    richtext.printRichContainedNoWrap(txt, font, r:get())
end


local function dbg(r)
    lg.rectangle("line",r:get())
end


local RAR_MAP = {
    [g.RARITIES.COMMON] = "foo"
}

---@param r kirigami.Region
---@param squadId string
---@param cost number
local function drawSquadCard(r, squadId, cost)
    -- BACKGROUND: gradient-fade
    -- BACKGROUND: color-border
    ui.drawPanel(r:get())

    local topmid, name, bot2 = r:padUnit(8,8):splitVertical(3,1,1)

    -- squad-icon, manaCost
    local x,y,w,h = topmid:getCenter()
    g.drawSquadIcon(squadId, x,y, true)

    -- unit name
    local sinfo = g.getSquadInfo(squadId)
    local font = g.getSmallFont(16)
    local txt = sinfo.name
    richtext.printRichContained(txt, font, name:get())
    dbg(name)

    -- cost (Gold)
    drawCost(cost, bot2, false)
    dbg(topmid)
    dbg(bot2)

    -- TOP-RIGHT: level
end


local function getRerollCost(self)
    return 20
end


---@param r kirigami.Region
local function drawRerollButton(self, r)
    local IMG = "shop_reroll_button"
    local x,y = r:getCenter()
    local r2 = Kirigami(0,0, g.getImageSize(IMG))
    r2 = r2:center(r)
    g.drawImage(IMG, x,y)

    local font = g.getSmallFont(16)
    local chain,body = r2:splitVertical(1,2)
    dbg(chain)
    dbg(body)
    richtext.printRichContained(
        "{shop_reroll_icon} {coin_icon} {GOLD_COLOR}" .. getRerollCost(self),
        font, body:padRatio(0.5):moveUnit(0,1):get()
    )
end


local function drawShopUI(self)
    local w,h = ui.getScaledUIDimensions()
    local shopBg = "shop_background"
    local iw,ih = g.getImageSize(shopBg)

    -- draw shop bg
    g.drawImage(shopBg, w/2,h/2)

    local shopRegion
    do
    local shopX,shopY = (w-iw)/2, (h-ih)/2
    local topPad = 40
    shopRegion = Kirigami(shopX,shopY+topPad,iw,ih-topPad)
    end
    -- local r1 = 
    --g.drawImageContained(shopBg, shopRegion:get())
    lg.rectangle("line",shopRegion:get())

    local leftR,rightR = shopRegion:splitHorizontal(2,1)

    local blessReg,xpReg = rightR:splitVertical(3,3)
    dbg(xpReg:padRatio(0.1))
    dbg(blessReg:padRatio(0.1))

    local rerollR, unitR = leftR:padRatio(0,-0.2,0,0):splitVertical(1,7)

    dbg(unitR:padRatio(0.1))
    local units = unitR:padRatio(0.15):grid(3,2)
    for _, ur in ipairs(units) do
        drawSquadCard(ur:padUnit(6,6), "militia_squad", 50)
    end

    drawRerollButton(self, rerollR:padRatio(0.1))
end



function shop_scene:draw()
    love.graphics.clear(0.1, 0.1, 0.1, 1)

    ui.startUI()
    drawShopUI(self)
    self.hud:drawUI({ shopScene = true })
    ui.endUI()
end



if true and consts.DEV_MODE then
    g.postLoad(function()
        g.newTestRun()
        g.gotoScene("shop_scene")
    end)
end

return shop_scene
