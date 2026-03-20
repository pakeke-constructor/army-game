local g = require("src.g")
local reducers = require("src.modules.reducers")

-- Battle events
g.defineEvent("battleWon")
g.defineEvent("battleLost")
g.defineEvent("battleStarted")
g.defineEvent("projectileHit")
g.defineEvent("manaSpent")
g.defineEvent("nexusDamaged")

-- Entity lifecycle
g.defineEvent("entitySpawned")
g.defineEvent("entityDeath")

-- Entity combat
g.defineEvent("entityHurt")
g.defineEvent("entityHealed")
g.defineEvent("entityBuffed")
g.defineEvent("entityKillsEnemy")
g.defineEvent("entityShootsProjectile")

-- Entity misc:
g.defineEvent("drawEntity")



-- Squad / deployment
g.defineEvent("squadDeployed")

-- Spells
g.defineEvent("spellCast")

-- Economy / run
g.defineEvent("moneyGained")
g.defineEvent("rewardChosen")
g.defineEvent("shopEntered")
g.defineEvent("chestOpened")




-- Questions: stat modifiers
local ADD = reducers.ADD
local MUL = reducers.MULTIPLY

g.defineQuestion("getMoveSpeedModifier", ADD, 0)
g.defineQuestion("getDamageModifier", ADD, 0)
g.defineQuestion("getDamageMultiplier", MUL, 1)
g.defineQuestion("getMaxHealthModifier", ADD, 0)
g.defineQuestion("getAttackSpeedMultiplier", MUL, 1)
g.defineQuestion("getMoveSpeedMultiplier", MUL, 1)
g.defineQuestion("getRangeModifier", ADD, 0)
g.defineQuestion("getDamageReduction", ADD, 0)
-- g.defineQuestion("getArmorMultiplier", MUL, 1) -- TODO: do we even want armor?

-- Questions: spells/mana
g.defineQuestion("getManaCostMultiplier", MUL, 1)
g.defineQuestion("getCooldownMultiplier", MUL, 1)

-- Questions: economy/rewards
g.defineQuestion("getMoneyMultiplier", MUL, 1)
g.defineQuestion("getRewardChoiceCount", ADD, 3)

-- Questions: projectiles
g.defineQuestion("getProjectileCountModifier", ADD, 0)
g.defineQuestion("getProjectileSpeedMultiplier", MUL, 1)

