--[[

This is an example ECS system.

Systems are loaded by name in ECSWorld:
  ECSWorld({"example_system"})

Every function in the table is auto-registered as an event/question handler.
Scene must call world:addSystemHandlers() each frame (in preUpdate).

Use g.getECS() inside handlers to get the current world.

]]

local mySys = {}

function mySys.preUpdate(dt)
end

function mySys.postUpdate(dt)
end

function mySys.preDraw()
end

function mySys.postDraw()
end

function mySys.entityDeath(ent)
    print("Entity died!")
end

return mySys
