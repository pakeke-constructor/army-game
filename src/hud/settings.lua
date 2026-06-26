local settings = require("src.settings")
local bgm = require("src.sound.bgm")
local sfx = require("src.sound.sfx")

---@class g.settingsPopupService
local settingsPopupService = {}

local visible = false

local TEXT
do
local TITLE = loc("SETTINGS", nil, {context = "Settings menu title"})
TEXT = {
    TITLE = "{o}" .. TITLE .. "{/o}",
    FULLSCREEN = loc("Fullscreen", nil, {context = "Settings toggle: enable fullscreen window mode"}),
    MUSIC = loc("Music", nil, {context = "Settings slider: background music volume"}),
    SFX = loc("Sound Effects", nil, {context = "Settings slider: sound effects volume"}),
    CLOSE = loc("Close", nil, {context = "Settings menu close button"}),
}
end

function settingsPopupService.show()
    visible = true
end

function settingsPopupService.clear()
    visible = false
end

function settingsPopupService.isActive()
    return visible
end

--- Escape toggles the settings popup. Returns true if the key was handled.
function settingsPopupService.keypressed(k)
    if k == "escape" then
        visible = not visible
        return true
    end
    return visible
end

--- Declarative list of checkbox rows in the settings menu.
---@type {label: string, getChecked: fun(): boolean, onToggle: fun(checked: boolean)}[]
local buttons = {}

--- Adds a labelled checkbox to the settings menu.
---@param label string
---@param getChecked fun(): boolean  -- current state
---@param onToggle fun(checked: boolean)  -- called when the box changes
local function defineButton(label, getChecked, onToggle)
    buttons[#buttons + 1] = {label = label, getChecked = getChecked, onToggle = onToggle}
end

defineButton(TEXT.FULLSCREEN, settings.isFullscreen, function(checked)
    settings.setFullscreen(checked)
    settings.save()
end)

local function drawButton(r, button, font)
    local labelR, _, boxR = r:splitHorizontal(0.5, 0.05, 0.45)
    lg.setColor(1, 1, 1)
    local lx, ly, lw, lh = labelR:get()
    richtext.printRichContainedNoWrap(button.label, font, lx, ly, lw, lh, "left")
    local box = boxR:set(nil, nil, r.h, r.h)
    local checked = button.getChecked()
    local newVal = ui.Checkbox(objects.Color.WHITE, box, checked)
    if newVal ~= checked then button.onToggle(newVal) end
end

local SLIDER_SEGMENTS = 11 -- 0, 10, 20, ... 100

--- Declarative list of slider rows. Values are 0..100.
---@type {label: string, getValue: fun(): number, onChange: fun(value: number)}[]
local sliders = {}

--- Adds a labelled slider (0..100) to the settings menu.
---@param label string
---@param getValue fun(): number  -- current value, 0..100
---@param onChange fun(value: number)  -- called when the slider moves
local function defineSlider(label, getValue, onChange)
    sliders[#sliders + 1] = {label = label, getValue = getValue, onChange = onChange}
end

defineSlider(TEXT.MUSIC, bgm.getVolume, function(value)
    bgm.setVolume(value)
    settings.save()
end)

defineSlider(TEXT.SFX, sfx.getVolume, function(value)
    sfx.setVolume(value)
    settings.save()
end)

local function drawSlider(r, slider, font)
    local labelR, _, sliderR = r:splitHorizontal(0.5, 0.05, 0.45)
    lg.setColor(1, 1, 1)
    local lx, ly, lw, lh = labelR:get()
    richtext.printRichContainedNoWrap(slider.label, font, lx, ly, lw, lh, "left")
    lg.setColor(1, 1, 1, 0.2)
    local x,y,w,h = sliderR:get()
    lg.rectangle("fill", x,y,w,h, h/2, h/2)
    local value = slider.getValue()
    local seg = math.floor(value / 100 * (SLIDER_SEGMENTS - 1) + 0.5) + 1
    local newSeg = ui.Slider(slider.label, "horizontal", objects.Color.WHITE, seg, SLIDER_SEGMENTS, nil, sliderR)
    local newVal = (newSeg - 1) / (SLIDER_SEGMENTS - 1) * 100
    if newVal ~= value then slider.onChange(newVal) end
end

function settingsPopupService.draw()
    if not visible then return end

    -- Background overlay
    lg.setColor(0, 0, 0, 0.2)
    lg.rectangle("fill", ui.getFullScreenRegion():get())
    -- eat the mouse so HUD/scene elements behind don't get clicked/hovered
    iml.panel(ui.getFullScreenRegion():get())

    local titleFont = g.getBigFont(48)
    local smallFont = g.getSmallFont(16)

    lg.setColor(1, 1, 1)
    local r = ui.getScreenRegion():padRatio(0.25)
    ui.drawDarkPanel(r:get())
    r = r:padUnit(20)

    local titleR, content, buttonBaseR = r:splitVertical(
      0.8,2,0.6
    )

    content = content:padRatio(0, 0.2, 0, 0.2)

    richtext.printRichContained(TEXT.TITLE, titleFont, titleR:get())

    local rows = content:columns(#buttons + #sliders)
    for i, button in ipairs(buttons) do
        drawButton(rows[i]:padRatio(0.3), button, smallFont)
    end
    for i, slider in ipairs(sliders) do
        drawSlider(rows[#buttons + i]:padRatio(0.3), slider, smallFont)
    end

    -- Close button
    local buttonR = buttonBaseR:set(nil, nil, 200, nil):center(buttonBaseR)
    if ui.DefaultButton(TEXT.CLOSE, buttonR) then
        visible = false
    end
end

return settingsPopupService
