local g = require("src.g")
local reducers = require("src.modules.reducers")

-- basic event flow
g.defineEvent("initECS")
g.defineEvent("preUpdate")
g.defineEvent("postUpdate")
g.defineEvent("perSecondUpdate")
g.defineEvent("preDraw")
g.defineEvent("postDraw")
g.defineEvent("drawAboveFog") -- fired after fog is rendered, so decor can draw on top of it


-- Battle events
g.defineEvent("battleWon")
g.defineEvent("battleLost")
g.defineEvent("battleStarted")
g.defineEvent("projectileHit")
g.defineEvent("explosion")
g.defineEvent("manaAdded")
g.defineEvent("manaSpent")
g.defineEvent("spellCast")


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
g.defineEvent("goldGained")
g.defineEvent("arrivedAtNode") -- args: nodeType, node
-- g.defineEvent("rewardChosen")
-- g.defineEvent("chestOpened")
g.defineEvent("rerollShop")
g.defineEvent("blessingAdded")



-- Questions: stat modifiers
local ADD = reducers.ADD
local MUL = reducers.MULTIPLY
local OR = reducers.OR

g.defineQuestion("getEntityScale", MUL, 1)

-- Questions: economy/rewards
g.defineQuestion("getMoneyMultiplier", MUL, 1)
g.defineQuestion("getRewardChoiceCount", ADD, 3)

-- Questions: projectiles
g.defineQuestion("getProjectileCountModifier", ADD, 0)
g.defineQuestion("getProjectileSpeedMultiplier", MUL, 1)

g.defineQuestion("getAoeRadius", ADD, 0) -- This works on entities without any base AOE. So if you want a perk/blessing to give AOE, use this.
g.defineQuestion("getAoeDamageMultiplier", MUL, 1)
g.defineQuestion("getExplosionSizeMultiplier", MUL, 1)
g.defineQuestion("getDamageTakenMultiplier", MUL, 1)
g.defineQuestion("getBurnDPSMultiplier", MUL, 1)

g.defineQuestion("getAITargetPriorityModifier", ADD, 0)
g.defineQuestion("getSquadUnitCountModifier", ADD, 0)
g.defineQuestion("getSquadStatBuffModifier", ADD, 0)
g.defineQuestion("canDeployAnywhere", OR, false)
