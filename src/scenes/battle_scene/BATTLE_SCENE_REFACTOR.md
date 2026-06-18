
Make the battle-scene be a bit more interesting....
instead of the world being a dull rectangle all the time, Maybe hardcode a few shapes?
(Peanut shape, Oval shape, multi-circle-shape, random-shape?)

In general, the battlefield should feel "cooler" and "bigger". Currently it's just small and boring.

Alongside this, maybe there needs to be more “things” in the world too; alongside just the enemy army. Stuff like:

- Treasure-chests to destroy (give gold)
- Enemy-spawners to destroy on the way
- Enemy flags as decoration
- Scattered rocks and trees in the battlefield

The way it should work:
Player should hover the mouse over treasure-chests to "target" them.
(TODO; maybe there should be a different "kind" of entity, side="neutral", blue healthbar, and it has a `destroyable` component or something. Player can go and harvest them my hovering mouse.)



```
We are currently midway through a refactor of removing ecs.border, and replacing it with a more organic-looking setup of multiple shapes.

The issue is that ground-decor system (and encounters.lua) still use the border system.

We need to change this.

- first, we should rename ecs.border to ecs.boundingBox.
- Then, ground-decor should sample a bunch of values in a grid of bounding-box, and if random < X, then spawn something there, and give it a random offset.
- encounters should sample a bunch of random values in the bounding box, and pick the value that is furtherest away from player's spawn position. (AND also the value that is inside the fog, ie inside the circles.)
```
