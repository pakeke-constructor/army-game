---@class g.pausePopupService
local pausePopupService = {}

local showPause = false
local showExitPopup = false

local settingsPopupService = require("src.hud.settings")

local TEXT = {
    PAUSED = loc("PAUSED"),
    RESUME = loc("RESUME"),
    SETTINGS = loc("SETTINGS"),
    SAVE_EXIT = loc("SAVE AND EXIT"),
    EXIT = loc("EXIT"),
    EXIT_LOWERCASE = loc("Exit"),
    WARNING = loc("Your progress will not be saved."),
    CANCEL = loc("Cancel"),
}

local function isSaveExit()
    local _, scName = g.getCurrentScene()
    return scName == "map_scene"
end

---@class PauseButton
---@field name fun(): string
---@field action fun()
---@field t number?

---@type PauseButton[]
local PAUSE_BUTTON = {
    {
        name = function() return TEXT.RESUME end,
        action = function()
            pausePopupService.clear()
        end,
        t = 0,
    },
    {
        name = function() return TEXT.SETTINGS end,
        action = function()
            settingsPopupService.show()
        end,
        t = 0,
    },
    {
        name = function()
            return isSaveExit() and TEXT.SAVE_EXIT or TEXT.EXIT
        end,
        action = function()
            if isSaveExit() then
                pausePopupService.exitToTitle(true)
            else
                showExitPopup = true
            end
        end,
        t = 0,
    }
}

function pausePopupService.isActive()
    return not not showPause
end

function pausePopupService.activate()
    showPause = true
    showExitPopup = false
end

function pausePopupService.clear()
    showPause = false
    showExitPopup = false
end

function pausePopupService.toggle()
    if showExitPopup then
        showExitPopup = false
    else
        showPause = not showPause
    end
end

---@param save boolean
---@package
function pausePopupService.exitToTitle(save)
    g.transitionTo("title_scene", {onSwitch = function()
        pausePopupService.clear()

        if save then
            g.saveAndInvalidateRun()
        else
            g.delRun()
        end
    end})
end

---@return kirigami.Region
local function drawBasicWindow()
    local r = ui.getFullScreenRegion()
    iml.panel(r:get())
    lg.setColor(0,0,0,.5)
    lg.rectangle("fill", r:get())

    local _, window, _ = r:splitHorizontal(1,4,1)
    window = window:padRatio(0.4)
    lg.setColor(1,1,1)
    ui.drawDarkPanel(window:get())
    return window
end

---@param reg kirigami.Region
---@param txt string
---@param font love.Font
---@return boolean
local function drawChoiceButton(reg, txt, font)
    reg = reg:padRatio(0.1)
    if iml.isHovered(reg:get()) then
        lg.setColor(0.6,0.6,0.6)
    else
        lg.setColor(1,1,1)
    end
    ui.drawDarkPanel(reg:get())
    local x,y,w,h = reg:padRatio(0.1):get()
    richtext.printRichContained(txt, font, x,y,w,h, 1)
    return iml.wasJustClicked(reg:get())
end

---@param i integer
---@param reg kirigami.Region
---@param txt string
---@param font love.Font
---@param dt number
---@return boolean
local function drawTextButton(i, reg, txt, font, dt)
    local buttonR = reg:padUnit(0, 2)
    local button = PAUSE_BUTTON[i]
    local hovered = iml.isHovered(buttonR:get())
    local target = hovered and 1 or 0
    local rate = hovered and 10 or 28
    button.t = helper.lerp(button.t or 0, target, dt * rate)
    local offsetY = helper.lerp(0, -2, helper.EASINGS.easeOutBack(button.t))

    if hovered then
        lg.setColor(1, 1, 0.6)
    else
        lg.setColor(1, 1, 1)
    end

    local cx, cy = buttonR:getCenter()
    cy = cy + offsetY
    helper.printTextOutline(
        txt,
        font,
        1,
        cx, cy,
        buttonR.w,
        "center",
        0, 1, 1,
        buttonR.w / 2, font:getHeight() / 2
    )

    return iml.wasJustClicked(buttonR:get())
end

local function drawPauseMenu()
    local screen = ui.getScreenRegion()
    local menu = screen:set(nil, nil, 420, 360):center(screen)
    local titleFont = g.getBigFont(48)
    local font = g.getSmallFont(16)
    local dt = love.timer.getDelta()

    local _, titleR, _, buttonsR = menu:splitVerticalExact(
        0,
        titleFont:getHeight(),
        0,
        (font:getHeight() + 10) * #PAUSE_BUTTON,
        0,
        0
    )

    lg.setColor(1, 1, 1)
    local tx, ty = titleR:getCenter()
    helper.printTextOutline(
        TEXT.PAUSED,
        titleFont,
        1,
        tx, ty,
        titleR.w,
        "center",
        0, 1, 1,
        titleR.w / 2, titleFont:getHeight() / 2
    )

    local rows = buttonsR:grid(1, #PAUSE_BUTTON)

    for i, info in ipairs(PAUSE_BUTTON) do
        local rowR = rows[i]
        if drawTextButton(i, rowR, info.name(), font, dt) then
            info.action()
        end
    end
end

local function drawExitPopup()
    local window = drawBasicWindow():padRatio(0.2)
    local font = g.getSmallFont(16)
    local txtR, buttonsR = window:splitVertical(3,1)

    local x,y,w,h = txtR:padRatio(0.3):get()
    richtext.printRichContained(TEXT.WARNING, font, x,y,w,h, 1)

    local leftR, rightR = buttonsR:splitHorizontal(1,1)
    if drawChoiceButton(leftR, TEXT.CANCEL, font) then
        showExitPopup = false
    end
    if drawChoiceButton(rightR, TEXT.EXIT_LOWERCASE, font) then
        pausePopupService.exitToTitle(false)
    end
end

function pausePopupService.draw()
    if not showPause then return end
    prof_push("pausePopupService.draw")

    local _, scName = g.getCurrentScene()

    local r = ui.getFullScreenRegion()
    iml.panel(r:get())
    lg.setColor(0,0,0,0.7)
    lg.rectangle("fill", r:get())
    lg.setColor(1, 1, 1)

    if settingsPopupService.isActive() then
        settingsPopupService.draw()
    elseif showExitPopup then
        drawExitPopup()
    else
        drawPauseMenu()
    end

    prof_pop() -- prof_push("pausePopupService.draw")
end

return pausePopupService
