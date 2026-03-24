
--[[

STATS SYSTEM:
=============
Recomputes entity stats every frame from base values + question bus modifiers.
This keeps stats as a single source of truth; no stale caches.

HOW IT WORKS:
  Each stat has a base field and a computed field.
  e.g. `baseAttackDamage` -> `attackDamage`

  Formula:  stat = (base + modifier) * multiplier

  `defineStat("attackDamage", "baseAttackDamage")` auto-generates two questions:
    - "getAttackDamageModifier"   (ADD reducer, default 0)   -- flat bonuses
    - "getAttackDamageMultiplier" (MULTIPLY reducer, default 1) -- scaling

  Entities only need the base field. The system writes the computed field each frame.
  If an entity doesn't have the base field, the stat is skipped.

USAGE (adding a buff/perk/blessing):
  Just answer the generated questions via handlers or scopes:

  -- Perk: "this unit gains +5 attack damage"
  scope:addHandler({
      getAttackDamageModifier = function(ent) return 5 end
  })

  -- Blessing: "all units deal 1.5x damage"
  g.addHandler({
      getAttackDamageMultiplier = function(ent) return 1.5 end
  })

  -- Conditional modifier via scope:
  scope:addHandler({
      getMoveSpeedMultiplier = function(ent)
          if ent.health < ent.maxHealth * 0.2 then
              return 2 -- double speed when low HP
          end
      end
  })

]]

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
defineStat("projectileAccuracy", "baseProjectileAccuracy")



---@class g.systems.stats: ecs.System
local stats = {}

function stats.entitySpawned(ent)
    for _, stat in ipairs(statlist) do
        local base = ent[stat.baseName]
        if base then
            ent[stat.name] = base
        end
    end
    if ent.maxHealth and not ent.health then
        ent.health = ent.maxHealth
    end
    -- melee units must be able to reach past their own collision
    if ent.physics and ent.attack and ent.attack.attackType == "melee" then
        local minRange = ent.physics.radius * 2
        assert(ent.attackRange >= minRange,
            "melee baseAttackRange (" .. ent.attackRange .. ") < physics radius*2 (" .. minRange .. ")")
    end
end

function stats.preUpdate(world, dt)
    for _, ent in world:iterate() do
        for _, stat in ipairs(statlist) do
            if ent[stat.baseName] or ent[stat.name] then
                recomputeStat(ent, stat)
            end
        end
    end
end

return stats
