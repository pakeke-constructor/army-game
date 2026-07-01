local particles = require("src.modules.particles.particles")

local lg = love.graphics
-- local root

---@class g.TitleScene
local title_scene = {}

-- embers live in normalized [0,1] space so they stay resolution-independent.
local EMBER_LIFE_MIN = 0.6
local EMBER_LIFE_MAX = 5
local MAX_EMBERS = 300
local REF_H = 720 -- ember sizes are authored at this height, then scaled

local embers = particles.newParticlesWorld({
    gravity = -0.05, -- floats upward
    extraFields = { maxLife = true }, -- each ember stores its own random lifetime
    getParticleDuration = function(p) return p.maxLife end,
    updateParticle = function(p, dt)
        p.vx = math.sin(love.timer.getTime()*2 + p.id) * 0.03 -- horizontal sway
    end,
    drawParticle = function(p)
        local w, h = lg.getDimensions()
        local life = p.lifetime / p.maxLife
        local size = (1 + (p.id % 3)) * (h / REF_H) * 3
        local flicker = 0.7 + 0.2*math.sin(love.timer.getTime()*7 + p.id)
        local a = (1 - life) * 0.9 * flicker
        lg.setColor(1, 0.45*flicker, 0.1, a)
        lg.circle("fill", p.x * w, p.y * h, size)
    end,
})

local spawnAcc = 0 -- fractional spawn accumulator for a framerate-independent rate

-- spawn one ember rising from just below the bottom edge
local function spawnEmber()
    local x = love.math.random()
    embers:spawnParticle(x, 1.05, 0, -(0.05 + love.math.random()*0.06))
    -- cube the roll so most embers are short-lived (die low) and only a few
    -- live long enough to reach the top.
    local r = love.math.random()
    embers.proxy.maxLife = EMBER_LIFE_MIN + r*r * (EMBER_LIFE_MAX - EMBER_LIFE_MIN)
end

---@class TitleButton
---@field name string
---@field onClick fun()
---@field t number?
---@field offsetX number?

---@type TitleButton[]
local buttons = {
    {name = "START", onClick = function ()
        g.transitionTo("runSelect_scene")
    end},
    {name = "SANDBOX", onClick = function ()
        g.newRun({
            commander = "sir_horse",
            difficulty = 0
        })
        require("src.scenes.battle_scene.battle_scene").sandbox = true
        g.transitionTo("battle_scene")
    end},
    {name = "EXIT", onClick = function ()
        love.event.quit()
    end}
}

local hoveredButton

local gapPerButton = 70
local BUTTON_W = 300

local buttonCells -- one Kirigami region per button (shared by hit-test + draw)

function title_scene:init()
end

function title_scene:enter()
    -- pre-seed a full field of embers at random heights + ages so they don't
    -- all appear as a band at the bottom when the scene opens.
    embers:clear()
    for _ = 1, MAX_EMBERS do
        spawnEmber()
        embers.proxy.y = love.math.random()                        -- scatter up the screen
        embers.proxy.lifetime = love.math.random()*embers.proxy.maxLife -- stagger deaths
    end
end

function title_scene:update(dt)
    local w, h = lg.getDimensions()
    -- root = Kirigami(0, 0, w, h)

    embers:update(dt)
    -- spawn at a steady rate regardless of framerate (cap clamps the total)
    spawnAcc = spawnAcc + dt*150
    while spawnAcc >= 1 and embers:getParticleCount() < MAX_EMBERS do
        spawnAcc = spawnAcc - 1
        spawnEmber()
    end

    for i, button in ipairs(buttons) do
        local target = (i == hoveredButton) and 1 or 0
        local rate = (i == hoveredButton) and 5 or 14
        rate = rate * 2
        button.t = helper.lerp(button.t or 0, target, dt*rate)
        button.offsetX = helper.lerp(0, 30, helper.EASINGS.easeOutBack(button.t))
    end
end

function title_scene:draw()
    ui.startUI()
    local main = ui.getScreenRegion()

    lg.clear(0.05, 0.05, 0.07, 1)

    local titleFont = g.getBigFont(48*3)
    local smallFont = g.getSmallFont(16*3)

    lg.setColor(1, 1, 1, 0.7)

    local x,y,w,h = main:get()

    -- drifting zoomed-in background. zoom in, slowly pan the camera around.
    local ZOOM = 1.03
    local t = love.timer.getTime()*3
    local zw, zh = w*ZOOM, h*ZOOM
    local margX, margY = (zw-w)/2, (zh-h)/2
    local driftX = math.sin(t*0.13) * margX
    local driftY = math.cos(t*0.1) * margY
    -- lg.setScissor(x, y, w, h)
    g.drawImageContained("exampleBackgroundMap", x-margX+driftX, y-margY+driftY, zw, zh)
    -- lg.setScissor()

    lg.setColor(0.05, 0.05, 0.07, 0.5)
    lg.rectangle("fill", x, x, w, h)

    lg.setColor(1, 1, 1, 1)

    local _, left = main:splitHorizontal(1, 2, 5)
    local _, logoReg, _, bottom = left:splitVertical(1.5, 2, 0.5, 5, 1.5)
    local buttonReg = bottom:splitHorizontal(4, 1)
    -- ui.debugRegion(logoReg)
    -- ui.debugRegion(buttonReg)

    local x,y,w,h = logoReg:get()
    g.drawImageContained("logo", x,y,w,h)
    
    buttonCells = buttonReg:columns(#buttons)
    
    hoveredButton = nil
    for i, button in ipairs(buttons) do
        local rx, ry, rw, rh = buttonCells[i]:padRatio(0.2):get()
        if iml.isHovered(rx, ry, rw, rh, button) then
            hoveredButton = i
        end
        if iml.wasJustHovered(rx, ry, rw, rh, button) then
            g.playUISound("ui_tick")
        end
        if iml.wasJustClicked(rx, ry, rw, rh, 1, button) then
            button.onClick()
        end

        lg.setColor((i == hoveredButton) and {1,1,0.6,1} or {1,1,1,1})
        richtext.printRichContainedNoWrap(button.name, smallFont, rx + (button.offsetX or 0), ry+10, rw, rh-20, "left")
    end

    ui.endUI()

    lg.setBlendMode("add")
    embers:draw()
    lg.setBlendMode("alpha")
end

return title_scene
