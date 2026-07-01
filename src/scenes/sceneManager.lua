local objects = require("src.modules.objects.objects")

---@class SceneManager
local sceneManager = {}

local currentScene, currentSceneName
local lastSceneName

local nameToScene = {--[[
    [name] -> Scene
]]}

local allScenes = objects.Array()

local SCENE_PATH = "src/scenes/"

function sceneManager.loadScenes()
    for _, folder in ipairs(love.filesystem.getDirectoryItems(SCENE_PATH)) do
        if love.filesystem.getInfo(SCENE_PATH .. folder, "directory") then
            allScenes:add(folder)
        end
    end

    for _, name in ipairs(allScenes) do
        local scene = require("src.scenes." .. name .. "." .. name)
        if scene.init then
            scene:init()
        end
        scene.name = name
        nameToScene[name] = scene
    end
end

function sceneManager.gotoScene(sceneName)
    assert(nameToScene[sceneName])
    local oldScene = nameToScene[currentSceneName]
    if oldScene and oldScene.leave then
        oldScene:leave()
    end
    lastSceneName = currentSceneName
    currentSceneName = sceneName
    currentScene = nameToScene[sceneName]
    if currentScene.enter then
        currentScene:enter()
    end
end

-- Faded scene switch: fade to black, swap scenes, fade back in.
-- Runs from fadeToBlackService.update (top of love.update, before pollHandlers),
-- so the swap is safe and leaves no gap frame.
---@param name string
---@param opts {fadeOut:number?, fadeIn:number?, onSwitch:fun()?}?
function sceneManager.transitionTo(name, opts)
    opts = opts or {}
    local fadeOut = opts.fadeOut or consts.SCENE_FADE_OUT
    local fadeIn = opts.fadeIn or consts.SCENE_FADE_IN
    fadeToBlackService.fadeToBlack(fadeOut, function()
        sceneManager.gotoScene(name)
        if opts.onSwitch then opts.onSwitch() end
        fadeToBlackService.fadeFromBlack(fadeIn)
    end)
end


function sceneManager.gotoLastScene()
    if lastSceneName then
        return sceneManager.gotoScene(lastSceneName)
    end
end

---@return table
---@return string
function sceneManager.getCurrentScene()
    return currentScene, currentSceneName
end

return sceneManager
