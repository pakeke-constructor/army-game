

I want to create an ECS implementation. 
This will be used for BattleField, and the map-scene.

folder structure:
```
src/ecs/*
src/ecs/ECSWorld.lua
src/ecs/system*.lua -- a bunch of systems for the ecs.
```

api:
```lua
ecs = ECSWorld()

ecs:update(dt) -- calls update on entities

ecs:addEntity(e)
ecs:removeEntity(e)
-- use objects.BufferedSet for addition/removal.

for _,e in ecs:iterate("component") do
  assert(e.component)
  ...
end
```