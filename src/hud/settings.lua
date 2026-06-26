local settings = require("src.settings")

---@class g.settingsPopupService
local settingsPopupService = {}

local visible = false

local TEXT
do
local TITLE = loc("SETTINGS", nil, {context = "Settings menu title"})
TEXT = {
    TITLE = "{o}" .. TITLE .. "{/o}",
    FULLSCREEN = loc("Fullscreen", nil, {context = "Settings toggle: enable fullscreen window mode"}),
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

---@param r kirigami.Region
---@param label string
---@param checked boolean
---@return boolean checked
local function drawRow(r, label, checked, font)
    local labelR, _, boxR = r:splitHorizontal(0.7, 0.05, 0.25)
    lg.setColor(1, 1, 1)
    richtext.printRichContainedNoWrap(label, font, labelR:get())
    local box = boxR:set(nil, nil, r.h, r.h)
    return ui.Checkbox(objects.Color.WHITE, box, checked)
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

    lg.setColor(0.2, 0.2, 0.2, 1)
    local r = ui.getScreenRegion():padRatio(0.25)
    ui.drawSingleColorPanel(r:get())
    lg.setColor(0.1, 0.1, 0.1, 1)
    ui.drawPanel(r:get())
    r = r:padUnit(20)

    lg.setColor(1,1,1, 1)

    local titleR, _, fullscreenR, _, buttonBaseR = r:splitVerticalExact(
        titleFont:getHeight(),
        16,
        smallFont:getHeight() * 1.5,
        16,
        smallFont:getHeight() * 2 + 8
    )

    richtext.printRichContained(TEXT.TITLE, titleFont, titleR:get())

    -- Fullscreen toggle
    local newFullscreen = drawRow(fullscreenR, TEXT.FULLSCREEN, settings.isFullscreen(), smallFont)
    if newFullscreen ~= settings.isFullscreen() then
        settings.setFullscreen(newFullscreen)
        settings.save()
    end

    -- Close button
    local buttonR = buttonBaseR:set(nil, nil, 200, nil):center(buttonBaseR)
    if ui.DefaultButton(TEXT.CLOSE, buttonR) then
        visible = false
    end
end

return settingsPopupService
