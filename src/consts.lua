
---@class g.consts
local consts = {}

consts.DEV_MODE = not not (love.filesystem.getInfo(".git", "directory") and os.getenv("DISABLE_DEV_MODE") ~= "1")
consts.TEST = not not (consts.DEV_MODE)
consts.PROFILING = false
consts.CONSOLE_LOG_LEVEL = "debug"
consts.FILE_LOG_LEVEL = "none"
consts.ANALYTICS_URL = nil
consts.GAME_VERSION = 0
consts.IS_MOBILE = false
consts.SHOW_DEV_STUFF = false
consts.MAX_PLAYING_SOURCES = 14
consts.SQUAD_SPACING = 20
consts.LAGGED_HEALTHBAR_DURATION = 0.25

---@type g.RarityMapping
consts.DEFAULT_RARITY_MAPPING = {
    -- i just yolo'd these numbers, feel free to change them
    COMMON = 1,
    UNCOMMON = 0.5,
    RARE = 0.3,
    LEGENDARY = 0.1,
}

consts.STARTING_COMMANDER = "sir_horse"

consts.MAX_SQUAD_COUNT = 10

consts.BURN_DPS = 8
consts.POISON_DPS = 13

return consts
