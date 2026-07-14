---@class g.pausePopupService
local pausePopupService = {}

local showPause = false
local showExitPopup = false

local settingsPopupService = require("src.hud.settings")

local TEXT = {
    RESUME = loc("Resume"),
    SETTINGS = loc("Settings"),
    SAVE_EXIT = loc("Save and Exit"),
    EXIT = loc("Exit"),
    WARNING = loc("Your progress will not be saved."),
    CANCEL = loc("Cancel"),
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

local function exitToTitle(save)
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
    local screen = ui.getFullScreenRegion()
    iml.panel(screen:get())
    lg.setColor(0,0,0,.5)
    lg.rectangle("fill", screen:get())

    local _, window, _ = screen:splitHorizontal(1,5,1)
    window = window:padRatio(0.3)
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

---@param safeExit boolean
local function drawPauseMenu(safeExit)
    local window = drawBasicWindow():padRatio(0.2)
    local font = g.getSmallFont(16)
    local rows = window:grid(1, 3)

    if drawChoiceButton(rows[1], TEXT.RESUME, font) then
        pausePopupService.clear()
    end
    if drawChoiceButton(rows[2], TEXT.SETTINGS, font) then
        settingsPopupService.show()
    end

    local exitText = safeExit and TEXT.SAVE_EXIT or TEXT.EXIT
    if drawChoiceButton(rows[3], exitText, font) then
        if safeExit then
            exitToTitle(true)
        else
            showExitPopup = true
        end
    end
end

local function drawExitPopup()
    local window = drawBasicWindow():padRatio(0.2)
    local font = g.getSmallFont(16)
    local txtR, buttonsR = window:splitVertical(2,1)

    local x,y,w,h = txtR:padRatio(0.3):get()
    richtext.printRichContained(TEXT.WARNING, font, x,y,w,h, 1)

    local leftR, rightR = buttonsR:splitHorizontal(1,1)
    if drawChoiceButton(leftR, TEXT.EXIT, font) then
        exitToTitle(false)
    end
    if drawChoiceButton(rightR, TEXT.CANCEL, font) then
        showExitPopup = false
    end
end

function pausePopupService.draw()
    if not showPause then return end
    prof_push("pausePopupService.draw")

    local _, scName = g.getCurrentScene()
    local safeExit = scName == "map_scene"

    local r = ui.getFullScreenRegion()
    iml.panel(r:get())
    lg.setColor(0,0,0,0.7)
    lg.rectangle("fill", r:get())
    lg.setColor(1, 1, 1)

    if showExitPopup then
        drawExitPopup()
    else
        drawPauseMenu(safeExit)
    end

    prof_pop() -- prof_push("pausePopupService.draw")
end

return pausePopupService
