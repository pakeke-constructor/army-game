
# Status Effects: burnTime, frozenTime, poisonTime

## Design
Fields already declared in components.lua (lines 87-89). When > 0, effect is active. Tick down each frame.

### Burn
- DPS: 8 damage/sec (high)
- Ticks burnTime down by dt each frame. When <= 0, set to nil.

### Poison  
- DPS: 3 damage/sec (low but steady)
- Ticks poisonTime down by dt each frame. When <= 0, set to nil.

### Frozen
- Entity can't move or attack.
- Ticks frozenTime down by dt each frame. When <= 0, set to nil.
- AI system: skip movement if frozen (set vx,vy=0)
- Attack system: skip attacking if frozen

## Implementation

### 1. New system: `src/ecs/systems/status_effects.lua`
- preUpdate: iterate entities with health. Tick burn/poison/freeze timers. Apply burn/poison damage via g.dealDamage.

### 2. AI system (`src/ecs/systems/ai.lua`)
- If ent.frozenTime and ent.frozenTime > 0, set vx,vy=0 and skip movement.

### 3. Attack system (`src/ecs/systems/attacking.lua`)  
- If ent.frozenTime and ent.frozenTime > 0, skip attack tick.

### 4. Register system in battle scene
- Add "status_effects" to ECSWorld system list (before ai so frozen takes effect)

### 5. Visual tint in g.drawEntity
- Burn: orange-red tint
- Frozen: blue tint  
- Poison: green tint
- Just setColor before drawing the entity image

### 6. Constants in consts.lua
- BURN_DPS = 8
- POISON_DPS = 3

No new events/questions needed. Just direct field manipulation.
