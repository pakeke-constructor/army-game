


# Enemy encounter system:

What do enemy encounters have?
- difficulty
- spawning-func
- (is elite?)

g.defineEnemyEncounter(id, difficulty, function(es: EnemySpawner)
    es:add("brute", 5)
    es:add("archer", 5)
end)




enemy-pool: Stored in battle-scene
EnemySpawner: Stored in battle-scene



## THINKING:
How is map procedural generation done?
How are nodes picked?

For enemy-encounters: Make it so the difficulty is stored as a delta
difficulty is either 0, 1, or 2 (+2 is "elite")

SIMPLEST: Hardcoded algorithm, step by step:
- Make 30% of nodes enemy encounters. (+2 difficulty). Prune any elite encounters that are next to each other
- Make 15% of nodes "special": (fountain, campsite, shop, town)
- Make 20% of empty nodes enemy encounters around the rest of the nodes (20% of nodes)
- Out of existing enemy-nodes, increase 30% of `0-encounters` increase by +1.








