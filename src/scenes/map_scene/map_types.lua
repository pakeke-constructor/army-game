local makeFallingLeavesAmbient = require("src.scenes.map_scene.falling_leaves_ambient")

local M = {}

---@class MapType.GroundTex
---@field [1] string Image name
---@field [2] number Weight
---@field [3] boolean? Disable random rotation? (default false)

---@class MapType.AmbientService
---@field reInitialize fun(transform:love.Transform)
---@field update fun(dt:number,transform:love.Transform)
---@field draw fun(transform:love.Transform)

---@class MapType
---@field public name string Must same as the field name, used by portal node.
---@field public info string Information shown on top right
---@field public decorTypes string[] As defined in decor_types.lua
---@field public groundTextures MapType.GroundTex[] List of possible ground textures to pick
---@field public groundColors objects.Color[] List of possible ground colors to pick
---@field public fogColor objects.Color Fog color
---@field public cloudSprites string[] Image name for the cloud (random pick unweighted)
---@field public additionalAmbientService MapType.AmbientService?
---@field public mapPath objects.Color
---@field public mapPathHighlight objects.Color

---@type MapType
M.forest = {
    name = "forest",
    info = helper.wrapRichtextColor(
        objects.Color("#236449"),
        loc("Epoch 1 - Breach", nil, {
        context = "current epoch/zone"})),
    decorTypes = {
        "mountain_large",
        "mountain_small_1",
        "mountain_small_2",
        "tree_large_1",
        "tree_small_1",
        "grass_1",
        "grass_2",
        "grass_3"
    },
    groundTextures = {
        {"decor_mega_1", 6},
        {"decor_mega_2", 6},
        {"decor_mega_3", 6},
        {"decor_mega_4", 6},
        {"decor_big_1", 4},
        {"decor_big_2", 4},
        {"decor_big_3", 4},
        {"decor_big_4", 4},
        {"decor_splotch_1", 3},
        {"decor_splotch_2", 3},
        {"decor_splotch_3", 3},
        {"decor_splotch_4", 3},
        {"decor_splotch_5", 3},
        {"decor_tex_1", 2},
        {"decor_tex_2", 2},
        {"decor_tex_3", 2},
        {"decor_tex_4", 2},
        {"decor_tex_5", 2},
    },
    groundColors = {
        objects.Color("FF3B432A"),
        objects.Color("FF384B28"),
        objects.Color("FF483936"),
    },
    fogColor = objects.Color("ff273718"), -- forest green
    cloudSprites = {"cloud1"},
    additionalAmbientService = makeFallingLeavesAmbient({
        count = 36,
        margin = 0.2,
        minSpeed = 24,
        maxSpeed = 46,
        minDrift = -12,
        maxDrift = 18,
        sway = 18,
        minScale = 1,
        maxScale = 1,
        minLifetime = 7,
        maxLifetime = 12,
        flipChance = 0.6,
        flipMinSpeed = 3,
        flipMaxSpeed = 7,
        sprites = {
            "falling_leaves_green_1",
            "falling_leaves_green_2",
            "falling_leaves_green_3",
        },
    }),
    mapPath = objects.Color("#152217"),
    mapPathHighlight = objects.Color("#213a22"),
}

---@type MapType
M.fall = {
    name = "fall",
    info = helper.wrapRichtextColor(
        objects.Color("#a6541b"),
        loc("Epoch 2 - Invasion", nil, {
        context = "current epoch/zone"})),
    decorTypes = {
        "mountain_large",
        "mountain_small_1",
        "mountain_small_2",
        "brownoak_large",
        "brownoak_small",
        "brownpine_large",
        "brownpine_small",
        "bush_medium",
        "bush_small_1",
        "bush_small_2",
    },
    groundTextures = {
        {"decor_mega_1", 6},
        {"decor_mega_2", 6},
        {"decor_mega_3", 6},
        {"decor_mega_4", 6},
        {"decor_big_1", 4},
        {"decor_big_2", 4},
        {"decor_big_3", 4},
        {"decor_big_4", 4},
        {"decor_splotch_1", 3},
        {"decor_splotch_2", 3},
        {"decor_splotch_3", 3},
        {"decor_splotch_4", 3},
        {"decor_splotch_5", 3},
        {"decor_tex_1", 2},
        {"decor_tex_2", 2},
        {"decor_tex_3", 2},
        {"decor_tex_4", 2},
        {"decor_tex_5", 2},
    },
    groundColors = {
        objects.Color("#1d1b0e"),
        objects.Color("#5f3927"),
        objects.Color("#361e19"),
    },
    fogColor = objects.Color("#361e19"),
    cloudSprites = {"cloud1"},
    additionalAmbientService = makeFallingLeavesAmbient({
        count = 200,
        margin = 0.2,
        minSpeed = 26,
        maxSpeed = 50,
        minDrift = -15,
        maxDrift = 20,
        sway = 18,
        minScale = 1,
        maxScale = 1,
        minLifetime = 5,
        maxLifetime = 10,
        flipChance = 0.8,
        flipMinSpeed = 2,
        flipMaxSpeed = 10,
        sprites = {
            "falling_leaves_brown_1",
            "falling_leaves_brown_2",
            "falling_leaves_brown_3",
        },
    }),
    mapPath = objects.Color("#361e19"),
    mapPathHighlight = objects.Color("#5f3927"),
}

---@type MapType
M.hell = {
    name = "hell",
    info = helper.wrapRichtextColor(
        objects.Color("#7c2222"),
        loc("Epoch 3 - Infernal", nil, {
        context = "current epoch/zone"})),
    decorTypes = {
        "hell_mountain_large",
        "hell_mountain_small_1",
        "hell_mountain_small_2",
        "volcano",
        "redcrystal_large_1",
        "redcrystal_large_2",
        "redcrystal_medium",
        "redcrystal_small",
        "demontree",
        "burnedtree_1",
        "burnedtree_2",
        "burnedtree_3",
        "burnedtree_4",
    },
    groundTextures = {
        {"decor_mega_1", 6},
        {"decor_mega_2", 6},
        {"decor_mega_3", 6},
        {"decor_mega_4", 6},
        {"decor_big_1", 4},
        {"decor_big_2", 4},
        {"decor_big_3", 4},
        {"decor_big_4", 4},
        {"decor_splotch_1", 3},
        {"decor_splotch_2", 3},
        {"decor_splotch_3", 3},
        {"decor_splotch_4", 3},
        {"decor_splotch_5", 3},
        {"decor_tex_1", 2},
        {"decor_tex_2", 2},
        {"decor_tex_3", 2},
        {"decor_tex_4", 2},
        {"decor_tex_5", 2},
    },
    groundColors = {
        objects.Color("#140e12"),
        objects.Color("#361e19"),
        objects.Color("#4f2d5d"),
    },
    fogColor = objects.Color("#341615"),
    cloudSprites = {"cloud1"},
    additionalAmbientService = nil, -- TODO: fire/ash particles
    mapPath = objects.Color("#361e19"),
    mapPathHighlight = objects.Color("#5f3927"),
}


for k,v in pairs(M) do
    assert(v.name == k)
end

return M
