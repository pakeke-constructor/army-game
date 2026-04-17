---
name: rendering_and_animations
description: Use when there is ANY kind of rendering or visual animation
---



Explain a bunch of advanced rendering techniques.

For animations, explains how to use hashes or ids to create deterministic animations.
Instead of storing timer on the object/entity, use it's id, (or any deterministic hash,) and then use `love.timer.getTime()` to animate.

for UI animations that have intrinsic state,
eg: "Box increases in scale over 0.5 seconds, until filling screen",
Or "When enemy is damaged, flash red for 0.2 seconds",
The best way to solve this is to keep a robust value that tracks time since the box being opened.
eg:  
`scene.timeSinceBoxOpened = 0` - when this is between 0 and 0.5, animate it.
`timeSinceBoxOpened` will increase every frame by dt.
Can also store in the object if there's an object with `:update` method.
`ent.timeSinceDamaged = X`
or `scene.box = {...data, timeSinceOpened = t}`
etc.

This works very well because it's so robust; you set the value once, and then there's no way for it to go wrong after that. The value just increases uniformly every frame, until animation is done. Super simple. Foolproof.


