---
name: rendering_and_animations
description: Use when there is ANY kind of rendering or visual animation
---


## Drawing Images
All images are packed into an `AutoAtlas`. Reference images by string name.

- `g.drawImage(name, x, y, r, sx, sy)` — draws centered (origin 0.5, 0.5).
- `g.drawImageOffset(name, x, y, r, sx, sy, ox, oy)` — ox/oy are 0..1 fraction of image size.
- `g.drawImageContained(name, x, y, w, h, rot)` — scales image to fit inside a w×h box, centered.
- `g.drawEntity(ent, x, y)` — draws entity image (respects ent.faceDir, alpha, rot, ox, oy, sx, sy). Calls `ent:draw(x,y)` if it exists. Draws health bar if `ent.health`.


## Scenes & Cameras
Battle scene uses `cam11` for world-space. Call `iml.pushTransform(camera:getTransform())` to sync UI clicks with camera coords. Screen-space UI goes after `camera:detach()`.

## Deterministic Animations (Hash + Time)
For looping animations (bob, pulse, blink, shimmer) that don't need a start/end, use `love.timer.getTime()` + a deterministic offset derived from the object's id or index. No state stored on the object.

Pattern: `math.sin(love.timer.getTime() * speed + offset) * amplitude`

Where `offset` is any deterministic value derived from the object (its id, index, position, etc.), so each object animates at a different phase.

Why: no state to store, no timer to manage, no cleanup. Works for objects that are created/destroyed freely. Animation is a pure function of time — draw it and forget it.


## State-Based Animations (Timer on Object)
For animations with a start and end — "flash red for 0.2s", "scale up over 0.5s" — store a timer that tracks time since animation started. Increment by `dt` each frame. Animate while value is in range.

Can live on the entity (`ent.timeSinceDamaged = 0`), the scene (`scene.timeSinceBoxOpened = 0`), or any table.

Set the value once, it increases uniformly every frame. No cleanup needed. Foolproof.


## Lighting
`Lighting` module renders lights to canvas with additive blending, then composites onto the scene with multiply blending. Ambient color is the canvas clear color.
