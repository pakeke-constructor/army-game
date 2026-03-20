

--[[

This is an example ECS system.

]]


local mySys = {}


function mySys.entityDeath()
    -- systems can respond to events (or questions)
    print("HELLO.")
end




-- systems also have a few "special" fields too:

function mySys.update(dt)
    -- update loop
end
function mySys.draw(dt)
    -- update loop
end




return mySys

