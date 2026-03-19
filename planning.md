

# api:
```lua


g.call(event, ...)

local ans = g.ask(question, ...)


g.addHandler({
    -- adds a handler for 1 frame.
    -- in order for this handler to continue existing, it MUST be re-added the next frame too.
    -- (this is for robustness reasons; we don't need to remove handlers. Enables SSOT)
    event = func1,
    question = func2,
})
-- ^^^ blessings use this.



ent = {
    event = func,
    question = func, -- ents can listen to events/questions directly.

    handlers = {
        -- but they ALSO have a list of internal handlers
        {event=func1, question=func2},
        {event=func1, question=func2},
        {event=func1, question=func2},
        {event=func1, question=func2},
        -- TODO: how to do this more efficiently?
    }
}


function scene:preUpdate()
    -- scenes can add whatever handlers they want.
    g.addHandler({
        ...
    })
end


g.clearHandlers() -- called every frame.


```

