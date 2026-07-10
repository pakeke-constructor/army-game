local bgm, sfx

local settings = {}

local fullscreen = false
local language = "en"

function settings.load()
    if not love.filesystem.getInfo(consts.SETTINGS_FILE, "file") then
        return
    end
    bgm = bgm or require("src.sound.bgm")
    sfx = sfx or require("src.sound.sfx")
    local contents = love.filesystem.read(consts.SETTINGS_FILE)
    local data = json.decode(contents)
    fullscreen = not not data.fullscreen
    language = data.language or "en"
    bgm.setVolume(data.musicVolume or 100)
    sfx.setVolume(data.sfxVolume or 100)
end

function settings.isFullscreen()
    return fullscreen
end

function settings.setFullscreen(v)
    fullscreen = not not v
end

function settings.getLanguage()
    return language
end

function settings.setLanguage(lang)
    language = lang or "en"
end

function settings.save()
    bgm = bgm or require("src.sound.bgm")
    sfx = sfx or require("src.sound.sfx")
    local data = {
        fullscreen = fullscreen,
        language = language,
        musicVolume = bgm.getVolume(),
        sfxVolume = sfx.getVolume(),
    }
    love.filesystem.write(consts.SETTINGS_FILE, json.encode(data))
end

return settings
