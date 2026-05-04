
local hoverService = require("src.hud.hoverService")



---@class g.ShopScene
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

---@param dt number
function shop_scene:update(dt)
end

---@param mx number
---@param my number
---@param button number
---@param istouch boolean
---@param presses number
function shop_scene:mousepressed(mx, my, button, istouch, presses)
end

---@param mx number
---@param my number
---@param button number
---@param istouch boolean
function shop_scene:mousereleased(mx, my, button, istouch)
end

---@param mx number
---@param my number
---@param dx number
---@param dy number
---@param istouch boolean
function shop_scene:mousemoved(mx, my, dx, dy, istouch)
end

---@param key string
---@param scancode string
---@param isrep boolean
function shop_scene:keypressed(key, scancode, isrep)
end


---@param dx number
---@param dy number
function shop_scene:wheelmoved(dx, dy)
    self.hud:wheelmoved(dx, dy)
end


local newPicker = require("src.modules.Picker")


---@param shopNode MapNode.ShopNode
function shop_scene.prefillShopNode(shopNode)
    -- fill shopNode
end


---@param shopNode MapNode.ShopNode
function shop_scene.rerollShopNodeInplace(shopNode)
    local pool = g.getSquadsByMana(g.getPermanentManaCounts())
    local rw = consts.DEFAULT_RARITY_WEIGHTS
    local weights = {}
    for i, squadId in ipairs(pool) do
        local sinfo = g.getSquadInfo(squadId)
        weights[i] = rw[sinfo.rarity.id]
    end
    local squadPicker = newPicker(pool, weights)

    for i,entry in ipairs(shopNode.squadShop) do
        if entry ~= false then -- false denotes a purchase.
            shopNode.squadShop[i] = squadPicker:pickAndRemove()
        end
    end
end



---@param shopNode MapNode.ShopNode
function shop_scene:setShop(shopNode)
    self.shopNode = shopNode
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
    if consts.DEV_MODE then
        -- lg.rectangle("line",r:get())
    end
end


local RAR_MAP = {
    [g.RARITIES.COMMON] = "squadbackground_common",
    [g.RARITIES.UNCOMMON] = "squadbackground_uncommon",
    [g.RARITIES.RARE] = "squadbackground_rare",
    [g.RARITIES.LEGENDARY] = "squadbackground_superrare",

    [g.RARITIES.UNIQUE] = "squadbackground_superrare", -- should never happen
}




---@param r kirigami.Region
---@param squadId string
---@param cost number
local function drawSquadCard(r, squadId, cost)
    -- BACKGROUND: gradient-fade
    -- BACKGROUND: color-border
    local sinfo = g.getSquadInfo(squadId)
    local font = g.getSmallFont(16)
    local rar = sinfo.rarity
    local bg = RAR_MAP[rar]
    local canAfford = g.getRun().money >= cost

    -- draw background:
    if canAfford then
        lg.setColor(1,1,1)
    else
        lg.setColor(0.7,0.7,0.7, 0.4)
    end
    g.drawImageContained(bg, r:get())
    do
    local x,y,w,h = r:get()
    helper.gradientRectStencil("vertical", rar.color,rar.lightColor, x,y,w,h, function ()
        ui.drawPanelThin(r:get())
    end)
    end

    -- draw level-widget
    do
    local _,rr = r:padRatio(0.1):splitHorizontal(3,1)
    local rrr = rr:splitVertical(1,3)
    local pop = gsman.mulColor(1,1,1,0.4)
    richtext.printRichContained("Lv 1", font, rrr:get())
    pop:pop()
    -- dbg(rrr)
    end

    local topmid, name, bot2 = r:padUnit(8,8):splitVertical(3,1,1)

    -- squad-icon, manaCost
    local x,y,w,h = topmid:getCenter()
    g.drawSquadIcon(squadId, x,y, true)

    -- unit name
    local txt = sinfo.name
    local squadCol = g.getManaBundleColor(sinfo.cost)
    local pop = gsman.mulColor(squadCol)
    richtext.printRichContained(txt, font, name:get())
    pop:pop()

    -- cost (Gold)
    lg.setColor(1,1,1)
    drawCost(cost, bot2, false)

    -- dbg(topmid)
    -- dbg(name)
    -- dbg(bot2)

    -- TOP-RIGHT: level
end


---@param self g.ShopScene
---@return number
local function getRerollCost(self)
    return 20
end


---@param self g.ShopScene
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

    if iml.wasJustClicked(r2:get()) then
        local cost = getRerollCost(self)
        if g.trySpendGold(cost) then
            shop_scene.rerollShopNodeInplace(self.shopNode)
        end
    end
end




---@param blesR kirigami.Region
---@param blessingId string
---@param cost number
local function drawBlessing(blesR, blessingId, cost)
    blesR = blesR:padRatio(0.2)
    local top, bot = blesR:splitVertical(2,1)

    -- draw blessing 
    g.drawBlessingIcon(blessingId, top:getCenter())

    -- draw cost
    drawCost(cost, bot)

    dbg(top)
    dbg(bot)
    dbg(blesR)

    if iml.isHovered(blesR:get()) then
        local binfo = g.getBlessingInfo(blessingId)
        local mx,my = ui.getMouse()
        hoverService.requestHover(mx,my, function (box, fonts)
            box:addText("{c r=0.7 g=0.5 b=0.4}"..binfo.name,fonts.title)
            box:addText(binfo.description,fonts.body)
        end)
    end
end



---@param self g.ShopScene
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

    local leftR,rightR = shopRegion:splitHorizontal(2,1)

    local blessReg,xpReg = rightR:splitVertical(3,3)
    for _, blesR in ipairs(blessReg:padRatio(0.15):grid(3,2)) do
        drawBlessing(blesR, "golden_coffers", 50)
    end

    -- xp purchasing.
    do
    local leftXp, rightXp = xpReg:padRatio(0.1):splitHorizontal(1,1)
    local function drawXpBuy(reg, img, xpAmount, cost)
        local _,main,bot,_ = reg:splitVertical(2,6,2,1)
        local x,y = main:getCenter()
        local canAfford = g.canAffordGold(cost)
        if canAfford then
            lg.setColor(1,1,1)
        else
            lg.setColor(0.6,0.6,0.6,0.7)
        end
        g.drawImage(img, x,y)
        if iml.wasJustClicked(main:get()) then
            if g.trySpendGold(cost) then
                print("Hi!")
                g.addXP(xpAmount)
            end
        end
        lg.setColor(1,1,1)
        drawCost(cost, bot)
    end

    drawXpBuy(rightXp:padRatio(0.3), "shop_xp_large", 4, 60)
    drawXpBuy(leftXp:padRatio(0.3), "shop_xp_small", 1, 20)
    end

    dbg(xpReg:padRatio(0.1))
    dbg(blessReg:padRatio(0.1))

    local rerollR, unitR = leftR:padRatio(0,-0.2,0,0):splitVertical(1,7)

    -- draw squad purchase
    dbg(unitR:padRatio(0.1))
    local units = unitR:padRatio(0.15):grid(3,2)
    for _, ur in ipairs(units) do
        drawSquadCard(ur:padUnit(6,10), "militia_squad", 90 + helper.hashInteger(_) % 20)
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
        local fakeShop = {squadShop = {}, blessingShop = {}}
        shop_scene.rerollShopNodeInplace(fakeShop)
        g.gotoScene("shop_scene")
        g.getCurrentScene():setShop(fakeShop)
    end)
end

return shop_scene
