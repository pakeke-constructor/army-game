
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
    g.addBlessingAndEntityHandlers()
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

local BLESSING_COST = {
    COMMON = 40,
    UNCOMMON = 60,
    RARE = 90,
    LEGENDARY = 130,
}

local NUM_SQUAD_SLOTS = 6
local NUM_BLESSING_SLOTS = 6

---@param shopNode MapNode.ShopNode
function shop_scene.prefillShopNode(shopNode)
    if shopNode.isSetup then return end
    shopNode.isSetup = true
    for i = 1, NUM_SQUAD_SLOTS do
        shopNode.squadShop[i] = shopNode.squadShop[i] or true
    end
    for i = 1, NUM_BLESSING_SLOTS do
        shopNode.blessingShop[i] = shopNode.blessingShop[i] or true
    end
    shop_scene.rerollShopNodeInplace(shopNode)

    -- fill blessings once
    local bPool = g.getBlessingsByMana(g.getPermanentManaCounts())
    local rw = consts.DEFAULT_RARITY_WEIGHTS
    local bWeights = {}
    for i, blessingId in ipairs(bPool) do
        local binfo = g.getBlessingInfo(blessingId)
        bWeights[i] = rw[binfo.rarity.id]
    end
    local blessingPicker = newPicker(bPool, bWeights)
    for i, entry in ipairs(shopNode.blessingShop) do
        if entry ~= false then
            shopNode.blessingShop[i] = blessingPicker:pickAndRemove()
        end
    end
end


---@param shopNode MapNode.ShopNode
function shop_scene.rerollShopNodeInplace(shopNode)
    shop_scene.prefillShopNode(shopNode)
    -- reroll squads
    local pool = g.getSquadsByMana(g.getPermanentManaCounts())
    local rw = consts.DEFAULT_RARITY_WEIGHTS
    local weights = {}
    for i, squadId in ipairs(pool) do
        local sinfo = g.getSquadInfo(squadId)
        weights[i] = rw[sinfo.rarity.id]
    end
    local squadPicker = newPicker(pool, weights)

    for i,entry in ipairs(shopNode.squadShop) do
        if entry ~= false then
            local newEntry = squadPicker:pickAndRemove()
            shopNode.squadShop[i] = newEntry
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
        lg.rectangle("line",r:get())
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
local function drawSquadBox(r, squadId, cost)
    -- BACKGROUND: gradient-fade
    -- BACKGROUND: color-border
    local sinfo = g.getSquadInfo(squadId)
    local font = g.getSmallFont(16)
    local rar = sinfo.rarity
    local bg = RAR_MAP[rar]
    local squadCol = g.getManaBundleColor(sinfo.cost)
    local canAfford = g.getRun().money >= cost

    local isHovered = iml.isHovered(r:get())
    local wasJustClicked = iml.wasJustClicked(r:get())

    -- find existing squad
    ---@type g.Squad?
    local squad = g.getSquadFromArmy(squadId)

    if canAfford and squad then
        -- if player can upgrade their squad:
        -- Then draw a fancy background animation behind the card.
        helper.drawEdgeTrailAnimation(r, squadCol, 0)
        helper.drawEdgeTrailAnimation(r, squadCol, 0.5)
    end

    -- draw background:
    ui.drawDarkPanel(r:get())
    local hoverAlpha = (canAfford and isHovered) and 0.8 or 0.3
    local affordColorMul = canAfford and 1 or 0.5
    lg.setColor(affordColorMul,affordColorMul,affordColorMul, hoverAlpha)
    g.drawImageContained(bg, r:get())
    lg.setColor(affordColorMul,affordColorMul,affordColorMul, 1)

    do
    local x,y,w,h = r:get()
    helper.gradientRectStencil("vertical", squadCol:lerp(objects.Color.BLACK, 0.2), squadCol:lerp(objects.Color.WHITE, 0.3), x,y,w,h, function ()
        ui.drawPanelThin(r:get())
    end)
    end

    -- draw level-widget
    if squad then
    local _,rr = r:padRatio(0.1):splitHorizontal(3,1)
    local rrr = rr:splitVertical(1,3)
    local pop = gsman.mulColor(1,1,1,0.4)
    richtext.printRichContained("Lv "..squad.level, font, rrr:get())
    pop:pop()
    -- dbg(rrr)
    end

    local topmid, name, bot2 = r:padUnit(8,8):splitVertical(3,1,1)

    -- squad-icon, manaCost
    local x,y,w,h = topmid:getCenter()
    local oy = isHovered and -2 or 0
    g.drawSquadIcon(squadId, x, y + oy, true)

    -- unit name
    local txt = "{o}" .. sinfo.name
    local pop = gsman.mulColor(squadCol)
    richtext.printRichContainedNoWrap(txt, font, name:get())
    pop:pop()

    -- cost (Gold)
    lg.setColor(1,1,1)
    drawCost(cost, bot2, false)

    if wasJustClicked then
        if g.trySpendGold(cost) then
            if squad then
                squad.level = squad.level + 1
            else
                g.addSquadToArmy(squadId)
            end
            return true, isHovered
        end
    end
    return false, isHovered
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
            g.call("rerollShop")
            shop_scene.rerollShopNodeInplace(self.shopNode)
        end
    end
end




---@param blesR kirigami.Region
---@param blessingId string
---@param cost number
---@return boolean bought
local function drawBlessing(blesR, blessingId, cost)
    blesR = blesR:padRatio(0.2)
    local top, bot = blesR:splitVertical(2,1)
    local binfo = g.getBlessingInfo(blessingId)
    local isHovered = iml.isHovered(blesR:get())

    ui.drawDarkPanel(blesR:get())

    if isHovered then
        local bg = RAR_MAP[binfo.rarity]
        lg.setColor(1,1,1,0.7)
        g.drawImageContained(bg, blesR:get())
        lg.setColor(1,1,1,1)
    end

    -- draw blessing 
    if isHovered then
        top = top:moveUnit(0,-2)
    end
    g.drawBlessingIcon(blessingId, top:getCenter())

    -- draw cost
    drawCost(cost, bot)

    dbg(top)
    dbg(bot)
    dbg(blesR)

    if isHovered then
        hoverService.requestHover(function (box, fonts)
            box:addText("{c r=0.7 g=0.5 b=0.4}"..binfo.name,fonts.title)
            box:addText(binfo.description,fonts.body)
        end)
    end

    if iml.wasJustClicked(blesR:get()) then
        if g.trySpendGold(cost) then
            g.addBlessing(blessingId)
            return true
        end
    end
    return false
end



---@param self g.ShopScene
---@param freeArea kirigami.Region
local function drawShopUI(self, freeArea)
    local w,h = ui.getScaledUIDimensions()
    local shopBg = "shop_background"
    local iw,ih = g.getImageSize(shopBg)

    -- draw shop bg
    g.drawImageContained(shopBg, freeArea:get())

    local shopRegion = freeArea:shrinkToAspectRatio(iw,ih)

    dbg(shopRegion)

    local leftR,rightR = shopRegion:splitHorizontal(2,1)

    local blessReg,xpReg = rightR:splitVertical(3,3)

    -- xp purchasing.
    do
    local leftXp, rightXp = xpReg:padRatio(0.1):splitHorizontal(1,1)
    local function drawXpBuy(reg, img, xpAmount, cost)
        local _,main,bot,_ = reg:splitVertical(2,6,2,1)
        local x,y = main:getCenter()
        local canAfford = g.canAffordGold(cost)
        local isHovered = iml.isHovered(main:get())
        local wasJustClicked = iml.wasJustClicked(main:get())

        if canAfford then
            lg.setColor(1,1,1)
        else
            lg.setColor(0.6,0.6,0.6,0.7)
        end
        local oy = isHovered and -2 or 0
        g.drawImage(img, x,y+oy)
        if wasJustClicked and g.trySpendGold(cost) then
            g.addXP(xpAmount)
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
    rerollR = rerollR:moveRatio(0, 0.5)

    -- draw squad purchase
    local hoveredSquadId = nil
    dbg(unitR:padRatio(0.1))
    local units = unitR:padRatio(0.15):grid(3,2)
    for i, ur in ipairs(units) do
        local squadId = self.shopNode.squadShop[i]
        if squadId and squadId ~= false then
            local clicked, hovered = drawSquadBox(ur:padUnit(6,10), squadId, 90 + helper.hashInteger(i) % 20)
            if clicked then
                self.shopNode.squadShop[i] = false
            end
            if hovered then
                hoveredSquadId = squadId
            end
        end
    end

    if not hoveredSquadId then
        local blessCells = blessReg:padRatio(0.15):grid(3,2)
        for i, blesR in ipairs(blessCells) do
            local entry = self.shopNode.blessingShop[i]
            if entry and entry ~= false then
                local binfo = g.getBlessingInfo(entry)
                local cost = BLESSING_COST[binfo.rarity.id] or 50
                if drawBlessing(blesR, entry, cost) then
                    self.shopNode.blessingShop[i] = false
                end
            end
        end
    end

    drawRerollButton(self, rerollR:padRatio(0.1))

    local scrW,scrH = ui.getScaledUIDimensions()
    local exitR = Kirigami(10, scrH * (4/8), scrW/10,scrH/10)
    if ui.DefaultButton("Exit", exitR) then
        g.gotoLastScene()
    end


    if hoveredSquadId then
        local screenReg = ui.getScreenRegion():padRatio(0.1, 0.3, 0.1, 0.1)
        local _,_,creg = screenReg:splitHorizontal(1,1,1)
        local rrr = creg:padRatio(0.1)
        lg.setColor(1,1,1)
        ui.drawDarkPanel(rrr:get())
        ui.drawSquadCard(hoveredSquadId, rrr, 1, true)
    end
end



function shop_scene:draw()
    love.graphics.clear(0.1, 0.1, 0.1, 1)

    ui.startUI()
    local freeArea = self.hud:getFreeArea()
    drawShopUI(self, freeArea)
    self.hud:drawUI({ shopScene = true })
    ui.endUI()
end



if false and consts.DEV_MODE then
    g.postLoad(function()
        g.newTestRun()
        local fakeShop = {squadShop = {}, blessingShop = {}}
        shop_scene.prefillShopNode(fakeShop)
        g.gotoScene("shop_scene")
        g.getCurrentScene():setShop(fakeShop)
    end)
end

return shop_scene
