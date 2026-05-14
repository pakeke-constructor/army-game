local g = require("src.g")
local reducers = require("src.modules.reducers")

-- basic event flow
g.defineEvent("initECS")
g.defineEvent("preUpdate")
g.defineEvent("postUpdate")
g.defineEvent("perSecondUpdate")
g.defineEvent("preDraw")
g.defineEvent("postDraw")


-- Battle events
g.defineEvent("battleWon")
g.defineEvent("battleLost")
g.defineEvent("battleStarted")
g.defineEvent("projectileHit")
g.defineEvent("nexusDamaged")
g.defineEvent("manaAdded")
g.defineEvent("manaSpent")


-- Entity lifecycle
g.defineEvent("entitySpawned")
g.defineEvent("entityDeath")

-- Entity combat
g.defineEvent("entityHurt") -- called whenever any entity is hurt
g.defineEvent("entityHealed")
g.defineEvent("armorIncreased")
g.defineEvent("armorDecreased")
g.defineEvent("entityBuffed")
g.defineEvent("entityShootsProjectile")

g.defineEvent("onAttack") -- Attacker passed as first arg. called when an entity attacks (healer OR attacker)
g.defineEvent("onHitDamage") -- Attacker passed as first arg. called when an entity actually hits their target to deal damage (projectile OR melee)
g.defineEvent("onHitHeal") -- Healer passed as first arg. called when an entity actually hits their target to heal (projectile OR melee)
g.defineEvent("onKill") -- killer passed as first arg. called when an entity kills another.


-- Entity misc:
g.defineEvent("drawEntity")
g.defineEvent("statusEffectApplied")


-- Squad / deployment
g.defineEvent("squadDeployed")


-- Economy / run
-- g.defineEvent("moneyGained")
-- g.defineEvent("rewardChosen")
-- g.defineEvent("chestOpened")
g.defineEvent("rerollShop")
g.defineEvent("blessingAdded")



-- Questions: stat modifiers
local ADD = reducers.ADD
local MUL = reducers.MULTIPLY

g.defineQuestion("getEntityScale", MUL, 1)

g.defineQuestion("getDamageReduction", ADD, 0)

-- Questions: economy/rewards
g.defineQuestion("getMoneyMultiplier", MUL, 1)
g.defineQuestion("getRewardChoiceCount", ADD, 3)

-- Questions: projectiles
g.defineQuestion("getProjectileCountModifier", ADD, 0)
g.defineQuestion("getProjectileSpeedMultiplier", MUL, 1)


g.defineQuestion("getSquadUnitCountModifier", ADD, 0)
