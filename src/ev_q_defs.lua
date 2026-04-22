local g = require("src.g")
local reducers = require("src.modules.reducers")

-- basic event flow
g.defineEvent("initECS")
g.defineEvent("preUpdate")
g.defineEvent("postUpdate")
g.defineEvent("preDraw")
g.defineEvent("postDraw")


-- Battle events
g.defineEvent("battleWon")
g.defineEvent("battleLost")
g.defineEvent("battleStarted")
g.defineEvent("projectileHit")
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
g.defineEvent("onAttack")

-- Entity misc:
g.defineEvent("drawEntity")



-- Squad / deployment
g.defineEvent("squadDeployed")


-- Economy / run
g.defineEvent("moneyGained")
g.defineEvent("rewardChosen")
g.defineEvent("shopEntered")
g.defineEvent("chestOpened")




-- Questions: stat modifiers
local ADD = reducers.ADD
local MUL = reducers.MULTIPLY

g.defineQuestion("getDamageReduction", ADD, 0)

-- Questions: economy/rewards
g.defineQuestion("getMoneyMultiplier", MUL, 1)
g.defineQuestion("getRewardChoiceCount", ADD, 3)

-- Questions: projectiles
g.defineQuestion("getProjectileCountModifier", ADD, 0)
g.defineQuestion("getProjectileSpeedMultiplier", MUL, 1)

