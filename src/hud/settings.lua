local settings = require("src.settings")
local bgm = require("src.sound.bgm")
local sfx = require("src.sound.sfx")

---@class g.settingsPopupService
local settingsPopupService = {}

local visible = false
local linesOfContent = 5

local TEXT
do
local TITLE = loc("SETTINGS", nil, {context = "Settings menu title"})
TEXT = {
    TITLE = "{o}" .. TITLE .. "{/o}",
    FULLSCREEN = loc("Fullscreen", nil, {context = "Settings toggle: enable fullscreen window mode"}),
    MUSIC = loc("Music", nil, {context = "Settings slider: background music volume"}),
    SFX = loc("Sound Effects", nil, {context = "Settings slider: sound effects volume"}),
    CLOSE = loc("Close", nil, {context = "Settings menu close button"}),
    AUDIO = loc("Audio", nil, {context = "Settings tab: audio options"}),
    GRAPHICS = loc("Graphics", nil, {context = "Settings tab: graphics options"}),
    CONTROLS = loc("Controls", nil, {context = "Settings tab: control options"}),
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

--- Tabs. Each tab holds a list of UI items (buttons + sliders) in display order.
--- An item is {uiType = "button"|"slider", ...}, drawn by drawButton/drawSlider.
---@type {id: string, label: string, items: table[]}[]
local tabs = {}
local tabsById = {}
local currentTab

--- Adds a tab. First tab defined becomes the default selected one.
local function defineTab(id, label)
    local t = {id = id, label = label, items = {}}
    tabs[#tabs + 1] = t
    tabsById[id] = t
    currentTab = currentTab or id
end

defineTab("audio", TEXT.AUDIO)
defineTab("graphics", TEXT.GRAPHICS)
defineTab("controls", TEXT.CONTROLS)

--- Adds a labelled checkbox to a tab.
---@param tabID string
---@param label string
---@param getChecked fun(): boolean  -- current state
---@param onToggle fun(checked: boolean)  -- called when the box changes
local function defineButton(tabID, label, getChecked, onToggle)
    local items = tabsById[tabID].items
    items[#items + 1] = {uiType = "button", label = label, getChecked = getChecked, onToggle = onToggle}
end

defineButton("graphics", TEXT.FULLSCREEN, settings.isFullscreen, function(checked)
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

--- Adds a labelled slider (0..100) to a tab.
---@param tabID string
---@param label string
---@param getValue fun(): number  -- current value, 0..100
---@param onChange fun(value: number)  -- called when the slider moves
local function defineSlider(tabID, label, getValue, onChange)
    local items = tabsById[tabID].items
    items[#items + 1] = {uiType = "slider", label = label, getValue = getValue, onChange = onChange}
end

defineSlider("audio", TEXT.MUSIC, bgm.getVolume, function(value)
    bgm.setVolume(value)
    settings.save()
end)

defineSlider("audio", TEXT.SFX, sfx.getVolume, function(value)
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
    local r = ui.getScreenRegion():padRatio(0.15)
    ui.drawDarkPanel(r:get())
    r = r:padRatio(0.05)

    local titleR, _, content, buttonBaseR = r:splitVertical(
      0.4,0.1, 2,0.4
    )

    richtext.printRichContained(TEXT.TITLE, titleFont, titleR:get())

    -- Tab bar
    local tabBarR, _, contentR = content:splitVertical(0.3, 0.05, 2)
    local tabCols = tabBarR:rows(#tabs)
    for i, tab in ipairs(tabs) do
        local active = tab.id == currentTab
        local col1 = active and objects.Color.WHITE or objects.Color.GRAY
        if ui.DefaultButton(tab.label, tabCols[i]:padRatio(0.3, 0, 0.3, 0):padRatio(0.1)) then
            currentTab = tab.id
        end
    end

    contentR = contentR:padRatio(0, 0.2, 0, 0.2)
    local items = tabsById[currentTab].items
    local rows = contentR:columns(linesOfContent)
    for i, item in ipairs(items) do
      local reg = rows[i]:padRatio(0.15, 0.1, 0.15, 0.1)
        if item.uiType == "button" then
            drawButton(reg, item, smallFont)
        else
            drawSlider(reg, item, smallFont)
        end
    end

    -- Close button
    local buttonR = buttonBaseR:set(nil, nil, 100, nil):center(buttonBaseR)
    if ui.DefaultButton(TEXT.CLOSE, buttonR) then
        visible = false
    end
end

return settingsPopupService
