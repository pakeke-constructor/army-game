
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

consts.MAX_SQUAD_LEVEL = 6

consts.GRAVITY = 300

consts.DEFAULT_MELEE_KNOCKBACK = 90
consts.DEFAULT_RANGED_KNOCKBACK = 50
consts.KNOCKBACK_RESISTANCE_INCREMENT = 2

consts.MAX_EVENT_CALLS_PER_FRAME = 20
-- the maximum number of event calls of a certain type per frame.
-- (avoids infinite loops in a robust way)

consts.TAU = 2*math.pi

consts.SHOP_BLESSING_COUNT = 6
consts.SHOP_SQUAD_COUNT = 6

---@type g.RarityWeights
consts.DEFAULT_RARITY_WEIGHTS = {
    -- i just yolo'd these numbers, feel free to change them
    COMMON = 1,
    UNCOMMON = 0.5,
    RARE = 0.3,
    LEGENDARY = 0.1,
    ALMOST_UNIQUE = 0.000000001,
}

consts.STARTING_COMMANDER = "sir_horse"

consts.MAX_SQUAD_COUNT = 10

consts.BURN_DPS = 2

return consts
