# XP Bar Stencil Problem

## Goal
Draw `army_healthbar_background` image clipped to the shape of `drawSingleColorPanel` (9-slice with rounded corners), sized to XP fill width.

## Problem
- `drawSingleColorPanel` is a 9-slice panel — fully opaque across its entire rect
- Stencil ignores alpha, writes for ALL drawn pixels
- So stencil covers full rectangle, rounded corners not respected
- Alpha test shader causes blitting issues per user
- Simple rectangle is not acceptable — need the nice 9-slice shape

## What we need to figure out
How to clip rendering to the 9-slice panel's visual shape (respecting its rounded/shaped corners) without using the alpha test shader.

## Current code location
`src/hud/hud.lua` lines ~278-291, function `drawXpBar`
