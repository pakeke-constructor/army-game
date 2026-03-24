
# backlog:


First change: Use spatial-partitioning.
Have a `Partition` object inside the ecs. 
Then, expose a `g.iteratePartition(partitionId)` that iterates entities.
To decide what entities get put in partition, have a new partition whitelist component: `ent.partitions = {"units", "projectiles", ...}`


Attack-system targetting: it's expensive to run the checks every frame. O(n^2). 
SOLUTION: Do partial-iterations. E.g. re-target 10% of entities every frame, instead of all.
IDEA:
- Store a value, `ent._lastTargetRefreshTime = getTime()` on ents.
- Every frame, iterate over all attacker/ai ents, and sort by lastRefreshTime (Keep a buffer over frames, use luajit table.clear)
Then, run refresh targetting on 5% of entities in the buffer.
If refreshTime is nil, assume that it's like 1000 or something



Attack-system targetting: it's expensive to run the checks every frame. O(n^2). 
We should keep track of a time-budget, and ensure we don't go over-budget. (e.g. 1/400 seconds.)
When we start iterating, pick a random index, and a random prime from a list, then run the AI 
Likewise, we should also 




- create agent-usable codebase and tools. 
- Agents should literally be able to play the game, and inspect state.

- Get rid of bloated task tools.
- Instead, have a `write-task`, `read-task`, and `log-task` tool.


- import iml core
- create UI core (MAKE IT AGENT-INTERACTABLE; via xml?)
- agent tool:  ui_click(elem_id)


- add push-ifs-up methodology (inside `_ex6/coding_style`)  https://gieseanw.wordpress.com/2024/06/24/dont-push-ifs-up-put-them-as-close-to-the-source-of-data-as-possible/



