# Battle Scene Pixel Canvases

## Goal
Add two PixelCanvases to battle_scene: one behind entities ("backCanvas"), one in front ("frontCanvas").
The existing ParticleService draws into the frontCanvas.

## Current draw order in battle_scene:draw()
1. camera:attach() — applies camera transform
2. clear + draw border
3. self.ecs:draw() — entities
4. self.particles:draw() — particles (currently drawn raw, no pixel canvas)
5. deploy preview ghosts
6. camera:detach()
7. UI

## New draw order
1. camera:attach()
2. clear + draw border
3. **backCanvas:start(transform)** → backCanvas:finish() — behind entities
4. self.ecs:draw() — entities (already pixel-art via nearest-neighbor sprites)
5. **frontCanvas:start(transform)** → self.particles:draw() → frontCanvas:finish()
6. deploy preview ghosts
7. camera:detach()
8. UI

## Problem: What draws INTO the canvases?
- backCanvas: nothing yet, but systems/effects can draw into it via events
- frontCanvas: particles draw here

The canvases need start/finish called each frame. Content is drawn between start/finish.
We fire events so systems can draw into them: `g.call("drawBackCanvas", self)` and `g.call("drawFrontCanvas", self)`.
Particles go into frontCanvas too.

## Changes needed

### battle_scene.lua
- [x] Require PixelCanvas
- [x] Create backCanvas and frontCanvas in :enter()
- [x] In :draw(), wrap with start/finish around entity draw
- [x] Move particles:draw() inside frontCanvas
- [x] Add resize handling if needed
- [x] Define events: drawBackCanvas, drawFrontCanvas

### Events
- g.defineEvent("drawBackCanvas") — not needed, just call directly
- Actually, simpler: just expose the canvases on self, and do start/finish in draw.
  Systems/effects that want to draw can hook into preDraw/postDraw or new events.

## Simplest approach
Just add the two pixel canvases to battle_scene, start/finish them in draw().
Fire simple events so other code can draw into them later.
Move particles into frontCanvas.
