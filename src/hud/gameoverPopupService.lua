---@class g.gameoverPopupService
local gameoverPopupService = {}

local visible = false

local TEXT
do
local GAME_OVER = loc("GAME OVER!", nil, {context = "Player loses the game"})
local DESCRIPTION = loc("you nexus has been destroyed... the last light of Kapathia dies.", nil, {context = "Fancy game over description"})
TEXT = {
    GAME_OVER = "{blink}{c r=1 g=0 b=0}{o}"..GAME_OVER.."{/o}{/c}{/blink}",
    DESCRIPTION = "{c r=1 g=0 b=0}{o}"..DESCRIPTION.."{/o}{/c}",
    ACCEPT = loc("Give in to the demons", nil, {
        context = "Text button to finish the run/post-game-over/whatever it is called"}),
}
end

function gameoverPopupService.show()
    visible = true
end

function gameoverPopupService.clear()
    visible = false
end

function gameoverPopupService.isActive()
    return visible
end

function gameoverPopupService.draw()
    if not visible then return end
    -- Background overlay
    local fr = ui.getFullScreenRegion()
    iml.panel(fr:get())
    lg.setColor(0, 0, 0, 0.7)
    lg.rectangle("fill", fr:get())

    local titleFont = g.getBigFont(48)
    local smallFont = g.getSmallFont(16)
    local r = ui.getScreenRegion():padRatio(0.2)

    local gameOverR, _, goDescR, _, statsR, _, buttonBaseR = r:splitVerticalExact(
        titleFont:getHeight(),
        8,
        smallFont:getHeight(),
        8,
        0,
        8,
        smallFont:getHeight() * 2 + 8
    )

    -- Game over text
    richtext.printRichContained(TEXT.GAME_OVER, titleFont, gameOverR:get())
    richtext.printRichContained(TEXT.DESCRIPTION, smallFont, goDescR:get())

    -- TODO stats

    -- Exit button
    local buttonR = buttonBaseR:set(nil, nil, 200, nil)
        :center(buttonBaseR)
    if ui.DefaultButton(TEXT.ACCEPT, buttonR) then
        g.delRun()
        g.gotoScene("title_scene")
        visible = false
    end
end

return gameoverPopupService
