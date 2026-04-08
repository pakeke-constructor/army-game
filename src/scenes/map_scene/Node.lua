

---@class _g.MapNode: objects.Class
local Node = objects.Class("g:MapNode")


function Node:click()
    return false -- does nothing.
end


function Node:surpriseEncounter()
    return false
end





local BattleNode = objects.Class("g:BattleNode")
    :implement(Node)

---@param seed integer
function BattleNode:init(seed)
    
end

function BattleNode:click()
    -- goto battle-scene
end



return Node

