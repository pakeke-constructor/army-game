# Battle Scene Pixel Canvases

## Goal
Draw status effect particles (burn/poison) over entities via postDraw, in a PixelCanvas.

## Approach
Keep everything inside ECSWorld. Pass optional camera transform to ecs:draw(transform).
When transform is provided, wrap preDraw/postDraw in pixel canvases.

### ECSWorld changes:
- Add self.backCanvas and self.frontCanvas (created in init)
- draw(transform):
  - if transform: backCanvas:start(transform), preDraw, backCanvas:finish()
  - else: preDraw (as before)
  - sort + draw entities
  - if transform: frontCanvas:start(transform), postDraw, frontCanvas:finish()
  - else: postDraw (as before)

### battle_scene.lua:
- Pass camera transform: self.ecs:draw(self.camera:getTransform())
- Move self.particles:draw() into a postDraw handler, OR keep it after ecs:draw 
  but then it's outside the frontCanvas. 
  → Simplest: move particles into a system or just accept it's outside.
  → Or: add particles:draw() call inside ECSWorld postDraw block... but ECSWorld 
    doesn't know about particles.
  → Best: battle_scene registers a handler for postDraw that draws particles.
    Since pollHandlers runs every frame, this works.

### Files:
1. ECSWorld.lua — add canvases, modify draw(transform)
2. battle_scene.lua — pass transform, add postDraw handler for particles, remove particles:draw() from draw()
3. ev_q_defs.lua — no changes

~20 lines total.
