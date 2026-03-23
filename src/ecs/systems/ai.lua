

---@class g.systems.ai: ecs.System
local ai = {}


function ai:preUpdate()
    for _, ent in self.ecs:iterate("ai") do
        -- move towards
    end
end


return ai


