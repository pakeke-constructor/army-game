
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
consts.SHOW_DEV_STUFF = consts.DEV_MODE
consts.MAX_PLAYING_SOURCES = 14
consts.SQUAD_SPACING = 20
consts.LAGGED_HEALTHBAR_DURATION = 0.25

consts.SETTINGS_FILE = "settings.json"

consts.MAX_SQUAD_LEVEL = 9

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

consts.BALANCING = {
    -- GLOBAL_HEALTH_MULTIPLIER = 0.7,

    BATTLE_GOLD_REWARD_MIN = 40,
    BATTLE_GOLD_REWARD_MAX = 60
}

-- Default fade durations for scene transitions (seconds).
consts.SCENE_FADE_OUT = 0.9
consts.SCENE_FADE_IN = 1

consts.NODE_FADE_IN = 1
consts.NODE_FADE_OUT = 0.9


-- Fade when starting a run after picking a commander (long, cinematic).
consts.RUN_START_FADE = 1.9
consts.RUN_START_FADE_DEV = 0.1

consts.STARTING_COMMANDER = "sir_horse"


consts.STARTING_MAP_TYPE = "forest"


consts.DEMON_ENCOUNTER_PLUS1_CHANCE = 0.4 -- X% chance for harder fight (+1 demonEncounter), and bonus rewards
consts.DEMON_ENCOUNTER_PLUS2_CHANCE = 0.2 -- X% chance for elite-fight, (+2 demonEncounter), and bonus rewards


consts.MAX_SQUAD_COUNT = 10

-- when false: squads auto-march at the nearest enemy and the player cannot
-- click/select/move deployed squads (no LEADER controls, no related rendering).
consts.LEADER_CONTROLS = false

consts.BURN_DPS = 2

-- Battle camera zoom is multiplied by the UI scale (ui.getUIScaling()), so the
-- battlefield looks the same size regardless of screen resolution.
consts.BATTLE_ZOOM_FACTOR = 0.5

return consts
