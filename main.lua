local love = require("love")

_G.lg = love.graphics

_G.utf8 = require("utf8")
_G.json = require("lib.json")

_G.objects = require("src.modules.objects.objects")
_G.helper = require("src.modules.helper.helper")
_G.richtext = require("src.modules.richtext.exports")
_G.iml = require("lib.iml.iml")

_G.g = require("src.g")

local sceneManager = require("src.scenes.sceneManager")

function love.load()
    g.loadImagesFrom("assets")
    sceneManager.loadScenes()
    sceneManager.gotoScene("title_scene")
end

function love.update(dt)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.update then
        sc:update(dt)
    end
end

function love.draw()
    local sc = sceneManager.getCurrentScene()
    if sc and sc.draw then
        iml.beginFrame()
        sc:draw()
        iml.endFrame()
    end
end

function love.mousepressed(mx, my, button, istouch, presses)
    iml.mousepressed(mx, my, button, istouch, presses)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.mousepressed then
        sc:mousepressed(mx, my, button, istouch, presses)
    end
end

function love.mousereleased(mx, my, button, istouch)
    iml.mousereleased(mx, my, button, istouch)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.mousereleased then
        sc:mousereleased(mx, my, button, istouch)
    end
end

function love.mousemoved(mx, my, dx, dy, istouch)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.mousemoved then
        sc:mousemoved(mx, my, dx, dy, istouch)
    end
end

function love.keypressed(key, scancode, isrep)
    iml.keypressed(key, scancode, isrep)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.keypressed then
        sc:keypressed(key, scancode, isrep)
    end
end

function love.keyreleased(key, scancode)
    iml.keyreleased(key, scancode)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.keyreleased then
        sc:keyreleased(key, scancode)
    end
end

function love.textinput(text)
    iml.textinput(text)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.textinput then
        sc:textinput(text)
    end
end

function love.wheelmoved(dx, dy)
    iml.wheelmoved(dx, dy)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.wheelmoved then
        sc:wheelmoved(dx, dy)
    end
end

function love.resize(w, h)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.resize then
        sc:resize(w, h)
    end
end

function love.directorydropped(fullpath)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.directorydropped then
        sc:directorydropped(fullpath)
    end
end

function love.filedropped(file)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.filedropped then
        sc:filedropped(file)
    end
end
