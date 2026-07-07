# USE_LAST_ARMY button

## Goal
Make "Use Last Layout" button work. Show + allow it ONLY IFF:
- No squads currently on battlefield (player hasn't deployed any this battle)
- Every squad in last-army layout still exists in army AND is affordable (cumulatively)

## Design
Store layout on Run (persists + serializes): run.lastArmyLayout =
  { {squadId, dx, dy}, ... } positions relative to commander deploy base pos.

Record layout when player presses "Start Battle" (capture squads deployed this battle).

Track deployed squads this battle: battle_scene.deployedSquads = {{squadId,x,y},...}
- append on each successful manual deploy
- append on use-last-army deploy

## Changes
1. Run.lua: add lastArmyLayout field, init nil, serialize/deserialize.
2. battle_scene enter(): self.deployedSquads = {}
3. manual deploy click handler: record {squadId, x=sx, y=sy} into deployedSquads.
4. Add local canUseLastArmy(self): validity check (no deployed, all exist+affordable cumulatively via mana-copy simulation).
5. Add local deployLastArmy(self): spawn each at commander base + dx,dy, spend mana, record.
6. Add local saveLastArmy(self): on Start, write run.lastArmyLayout from deployedSquads (relative to commander base).
7. Start button: call saveLastArmy.
8. Button render: only draw when canUseLastArmy; on click deployLastArmy.
