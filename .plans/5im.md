# Battle deploy-phase + perSecondUpdate move

## Goal
- Battle starts in a "deploy phase" (limbo): world time frozen, entities don't move.
- Player deploys squads, then presses a "Start" button to begin.
- Move perSecondUpdate timer out of main.lua into ECSWorld, so it only ticks
  when ECSWorld:update advances with real dt.

## Changes
1. ECSWorld: add secondTimer/secondCount; in update() accumulate dt and fire
   g.call("perSecondUpdate", secondCount). (after team-list rebuild)
2. main.lua: remove perSecondUpdateTimer/secondCount block + sc:perSecondUpdate call.
3. battle_scene:
   - remove :perSecondUpdate method.
   - enter(): self.deployPhase = true.
   - update(): ecsDt = deployPhase and 0 or dt*timeScale; ecs:update(ecsDt).
     During deploy, skip win-logic/particles.
   - draw(): when deployPhase, draw "Start" button. On click: deployPhase=false,
     g.call("battleStarted").

## Notes
- ecs:update(0) during deploy keeps entities flushed/drawn but frozen (dt=0).
- battleStarted event already defined + listened (juice_system) but never fired.
