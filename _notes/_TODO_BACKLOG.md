
# backlog:




create scopes system for ev/q handlers.
```lua
---@class g.Scope: objects.Class
local Scope

function Scope:addHandler(handler)

end

function Scope:removeHandler(handler)

end

function Scope:ask(question, ...)
end

function Scope:call(event, ...)
end


---@return g.Scope
local function newScope()
    return {}
end
```


- Create stats system.


- create agent-usable codebase and tools. 
- Agents should literally be able to play the game, and inspect state.

- Get rid of bloated task tools.
- Instead, have a `write-task`, `read-task`, and `log-task` tool.


- import iml core
- create UI core (MAKE IT AGENT-INTERACTABLE; via xml?)
- agent tool:  ui_click(elem_id)


- add push-ifs-up methodology (inside `_ex6/coding_style`)  https://gieseanw.wordpress.com/2024/06/24/dont-push-ifs-up-put-them-as-close-to-the-source-of-data-as-possible/



