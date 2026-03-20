--[[

This is an example ECS system.

Systems are loaded by name in ECSWorld:
  ECSWorld({"example_system"})

Every function in the table is auto-registered as an event/question handler.
Scene must call world:addSystemHandlers() each frame (in preUpdate).

]]

local mySys = {}

function mySys.preUpdate(world, dt)
end

function mySys.postUpdate(world, dt)
end

function mySys.preDraw(world)
end

function mySys.postDraw(world)
end

function mySys.entityDeath(ent)
    print("Entity died!")
end

return mySys
