
local reducers = require("src.modules.reducers")

local statlist = {}

local function defineStat(name, baseName)
    local Name = name:sub(1,1):upper() .. name:sub(2)
    local modQ = "get" .. Name .. "Modifier"
    local mulQ = "get" .. Name .. "Multiplier"
    g.defineQuestion(modQ, reducers.ADD, 0)
    g.defineQuestion(mulQ, reducers.MULTIPLY, 1)
    table.insert(statlist, {name = name, baseName = baseName, modQ = modQ, mulQ = mulQ})
end

local function recomputeStat(ent, stat)
    local base = ent[stat.baseName]
    if not base then return end
    local val = base + g.ask(stat.modQ, ent)
    val = val * g.ask(stat.mulQ, ent)
    ent[stat.name] = val
end

defineStat("attackDamage", "baseAttackDamage")
defineStat("maxHealth", "baseMaxHealth")
defineStat("attackSpeed", "baseAttackSpeed")
defineStat("moveSpeed", "baseMoveSpeed")
defineStat("attackRange", "baseAttackRange")
defineStat("armor", "baseArmor")


---@class g.systems.stats: ecs.System
local stats = {}

function stats:preUpdate()
    for _, ent in self.ecs:iterate() do
        for _, stat in ipairs(statlist) do
            if ent[stat.baseName] or ent[stat.name] then
                recomputeStat(ent, stat)
            end
        end
    end
end

return stats
