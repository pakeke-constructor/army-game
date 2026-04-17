---
name: ui
description: Use when creating UI, layouts, panels, input handling, hover tooltips, or scaling
---

## IML (Immediate-Mode Input Layer)

Module: `lib/iml/iml.lua`, globally available as `iml`.
Handles mouse clicks, hovers, drags, and text input in an immediate-mode style.
Every frame, call `iml.beginFrame()` / `iml.endFrame()` (done in `love.draw` in main.lua).

### Panels

`iml.panel(x,y,w,h, key?)` declares a clickable/hoverable region.
Panels don't draw anything — they just register a rectangle for hit-testing.
The topmost panel (last declared that frame) under the mouse "wins" hover.
If no `key` is given, a hash of `(x,y,w,h)` is used. Provide an explicit key when multiple panels share the same rect or when you need stable identity (e.g. for drags).

Most iml query functions (`isHovered`, `wasJustClicked`, etc.) implicitly call `iml.panel` internally, so you usually don't call `iml.panel` directly unless you want to block clicks from propagating through a region without querying anything.

### Query Functions

All queries must be called between `iml.beginFrame()` and `iml.endFrame()`.
They all take `(x,y,w,h, [button], [key])`.

- `iml.isHovered(x,y,w,h, key?)` — true while mouse is over this region AND it's the topmost panel.
- `iml.wasJustHovered(x,y,w,h, key?)` — true the single frame that hover started.
- `iml.isClicked(x,y,w,h, button?, key?)` — true every frame while mouse is held down on this region (only if movement < threshold, otherwise it becomes a drag).
- `iml.wasJustClicked(x,y,w,h, button?, key?)` — true once, the frame after mouse-release, if it was a click (not a drag). This is the main "button pressed" check.
- `iml.wasJustPressed(x,y,w,h, button?, key?)` — true once, the frame after mouse-press.
- `iml.wasJustReleased(x,y,w,h, button?, key?)` — true once, the frame after mouse-release (regardless of click vs drag).
- `iml.isSelected(x,y,w,h, key?)` — true if this panel was the last left-clicked panel. Used for text input focus.

`button` defaults to 1 (left mouse). `key` defaults to `hash(x,y,w,h)`.

### Drags

`iml.consumeDrag(key, x,y,w,h, button)` — returns an `iml.Drag` table if the user is dragging this element, or nil. The drag is "consumed" (dx/dy reset) so only one consumer gets the delta per frame. Key must be an explicit non-number value.

```lua
local drag = iml.consumeDrag("my_slider", x,y,w,h, 1)
if drag then
    offset = offset + drag.dx
end
```

### Transforms

IML tracks a transform stack that maps screen-space mouse coordinates into local coordinates. This is critical when UI is scaled (see UI Scaling below).

- `iml.pushTransform(t)` — push a `love.Transform` onto the stack.
- `iml.popTransform()` — pop the last transform.
- `iml.resetTransforms()` — clear the stack.
- `iml.getTransformedPointer()` — get mouse position in current local coordinates.

### Text Input

- `iml.consumeText()` — returns and consumes any text typed this frame (from `love.textinput`). Returns nil if nothing.

### Callbacks

These must be wired to the corresponding Love2D callbacks in main.lua:
`iml.mousepressed`, `iml.mousereleased`, `iml.keypressed`, `iml.keyreleased`, `iml.textinput`, `iml.setPointer(x,y)`.


## Kirigami (Layout Regions)

Module: `lib/kirigami.lua`, globally available as `Kirigami`.
`Kirigami(x,y,w,h)` creates a `kirigami.Region` — a rectangle you can split, pad, and manipulate to build layouts without manual coordinate math.

### Splitting

Split a region into sub-regions by ratio:
```lua
local top, bottom = region:splitVertical(1, 3)  -- 25% top, 75% bottom
local left, mid, right = region:splitHorizontal(1, 4, 1) -- sidebar, content, sidebar
```
Ratios are normalized automatically (1,3 becomes 0.25,0.75).

Split by exact pixel sizes (0 = "take remaining space"):
```lua
local header, body = region:splitVerticalExact(40, 0) -- 40px header, rest is body
local sidebar, content = region:splitHorizontalExact(200, 0)
```

Grid layout:
```lua
local cells = region:grid(3, 2)  -- 3 columns, 2 rows -> 6 regions
local rows = region:columns(4)   -- 4 rows (1 column)
local cols = region:rows(3)      -- 3 columns (1 row)
```

### Padding

```lua
region:padUnit(10)           -- 10px padding all sides
region:padUnit(10, 20)       -- 10px left/right, 20px top/bottom
region:padUnit(t, l, b, r)   -- individual sides

region:padRatio(0.1)         -- 10% padding all sides (based on min(w,h))
region:padRatio(0.2, 0.1)    -- 20% horizontal, 10% vertical
```

### Positioning & Sizing

```lua
region:center(other)          -- center self inside other
region:centerX(other)         -- center horizontally only
region:centerY(other)         -- center vertically only
region:moveUnit(dx, dy)       -- offset by pixels
region:moveRatio(0.5, 0)      -- offset by fraction of own size

region:shrinkTo(maxW, maxH)             -- clamp size
region:shrinkToAspectRatio(16, 9)       -- shrink to fit aspect ratio
region:scale(2)                         -- scale w,h by factor
region:scaleToFit(targetW, targetH)     -- scale to fit bounds, returns region + scale

region:attachToTopOf(other)
region:attachToBottomOf(other)
region:attachToLeftOf(other)
region:attachToRightOf(other)

region:intersection(other)    -- overlapping area (useful for max-size)
region:union(other)           -- bounding box of both (useful for min-size)
region:clampInside(other)     -- move so self fits inside other
```

### Accessors

```lua
local x, y, w, h = region:get()
local cx, cy = region:getCenter()
local w, h = region:size()
local exists = region:exists()  -- w > 0 and h > 0
region:containsCoords(px, py)
```

### Typical Layout Pattern

```lua
local screen = ui.getScreenRegion()
local topBar, content = screen:splitVerticalExact(36, 0)
local left, right = content:splitHorizontal(1, 2)
local padded = right:padUnit(10)
-- draw stuff into padded:get()
```


## UI Scaling

Module: `src/ui/ui.lua`.
The game auto-scales UI based on window height. Target is `UI_HEIGHT = 360` virtual pixels.

### The startUI / endUI Pattern

All UI drawing must happen between `ui.startUI()` and `ui.endUI()`. This pushes the global scale transform onto both the Love2D graphics stack and the iml transform stack, so that:
1. Drawing coordinates are in virtual (scaled) pixels.
2. iml hit-testing uses the same coordinate space.

```lua
-- In scene:draw():
ui.startUI()
    local screen = ui.getScreenRegion()
    -- ... all UI drawing here ...
ui.endUI()
```

### Key Functions

- `ui.getUIScaling()` — returns the current scale factor (e.g. 2.0 on a 720p window).
- `ui.getScaledUIDimensions()` — returns virtual (w, h) after scaling. Always ~360 tall.
- `ui.getScreenRegion()` — returns a `kirigami.Region` covering the safe area in virtual coordinates. This is what you should use for layout.
- `ui.getFullScreenRegion()` — same but ignores safe area (includes notches etc).
- `ui.getMouse()` — returns mouse position in virtual UI coordinates.
- `ui.regionToScreenspace(reg)` — converts a virtual region back to actual screen pixels.
- `ui.assertUIStarted()` — asserts we're inside startUI/endUI. Call at the top of any UI widget function.

### Coordinate Flow

```
Screen pixels (1920x1080)
  -> ui.startUI() applies scale transform (e.g. 3x)
    -> Virtual coordinates (~640x360)
      -> Kirigami regions, iml queries, drawing all happen here
  -> ui.endUI() pops transform
```


## Drawing Helpers

### 9-Slice Panels

Panels are drawn using 9-slice textures from the atlas. Never scale panel images manually.

```lua
ui.drawPanel(x, y, w, h)           -- light bordered panel (9px padding)
ui.drawDarkPanel(x, y, w, h)       -- dark bordered panel (7px padding)
ui.drawSingleColorPanel(x, y, w, h) -- flat single-color panel (4px padding, tinted by current color)
```

`drawPanel` and `drawDarkPanel` are the main ones. `drawSingleColorPanel` is useful for small colored chips (e.g. trait boxes, stat backgrounds) — set `love.graphics.setColor` before calling to tint it.

### Gradient Rectangles

From `src/modules/helper/helper.lua`. Great for backgrounds, overlays, button fills.

```lua
helper.gradientRect("vertical", col1, col2, x, y, w, h)    -- top-to-bottom gradient
helper.gradientRect("horizontal", col1, col2, x, y, w, h)  -- left-to-right gradient
```

Colors can be `objects.Color` or `{r, g, b, a}` tables.

Outline variant:
```lua
helper.gradientOutlineRect("vertical", col1, col2, x, y, w, h, lineWidth?)
```

Stencil variant (gradient masked by a draw function):
```lua
helper.gradientRectStencil("vertical", col1, col2, x, y, w, h, function()
    ui.drawPanel(x, y, w, h)  -- only gradient pixels inside the panel shape
end)
```

### Jagged Rectangle

`ui.jaggedRectangle(mode, radius, x, y, w, h)` — draws a pixel-art rounded rectangle. Vertices are quantized to pixel grid.

### Images

- `g.drawImage(name, x, y)` — draws centered at (x,y), no scaling. Use for icons at native resolution.
- `g.drawImageContained(name, x, y, w, h)` — scales to fit inside (w,h) preserving aspect ratio.
- Avoid scaling images when possible. Prefer `g.drawImage` for pixel-art icons.


## ui.Box

Module: `src/ui/boxes.lua`, accessed as `ui.Box(args, drawBg?)`.
A vertical box layout for stacking text and custom elements. Handles measurement and rendering. Very useful for tooltips, cards, info panels.

### Construction

```lua
local box = ui.Box({maxWidth = 200, padding = 8, spacing = 4}, function(x, y, w, h)
    -- optional background drawer, called with the final bounding rect
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
end)
```

- `maxWidth` — the box's outer width (required).
- `padding` — inner padding on all sides.
- `spacing` — vertical gap between entries.

### Adding Entries

```lua
box:addText("Some {c r=1 g=0 b=0}rich text", font)  -- richtext, auto-wraps to innerW
box:addSpacing(4)                                      -- vertical gap
box:add({                                              -- custom element
    getHeight = function(innerW) return 20 end,
    draw = function(x, y, w, h)
        love.graphics.rectangle("fill", x, y, w, h)
    end,
})
```

Custom elements must have `getHeight(innerW)` and `draw(x, y, w, h)`.

### Measuring & Rendering

```lua
local totalW, totalH = box:measure()       -- get size without drawing
local totalW, totalH = box:render(x, y)    -- draw at position, returns size
```

### Typical Card Pattern

Cards (squad cards, blessing cards) use Box with a background drawer that renders gradients + panels:

```lua
local box = ui.Box({maxWidth = w, padding = 12, spacing = 8}, function(bx, by, bw, bh)
    helper.gradientRect("vertical", bgCol, darkCol, x, y, w, h)
    ui.drawPanel(x, y, w, h)
end)
box:add({ ... })   -- header with icon + name
box:addText(description, bodyFont)
box:render(x, y)
```


## Built-in Widgets

### Buttons

```lua
-- Default styled button:
if ui.DefaultButton(richText, region) then
    -- clicked
end

-- Custom-colored button:
if ui.Button(richText, col1, col2, region) then ... end

-- Fully custom button (you provide the draw function):
if ui.CustomButton(drawFunc, col1, col2, region) then ... end
```

Buttons auto-handle hover highlighting (gradient fill), hover sound, click sound, and iml panel registration. Must be called inside `ui.startUI()`/`ui.endUI()`.

### Slider

```lua
local segment = ui.Slider(key, "horizontal", color, currentSegment, totalSegments, sliderSize, region)
```

### Checkbox

```lua
checked = ui.Checkbox(color, region, checked)
```

### TextBox

```lua
local tb = ui.newTextBox()
-- in draw:
tb:draw(region)
-- read tb.txt for current text, tb.isFocused for focus state
```


## hoverService

Module: `src/hud/hoverService.lua`, accessed via `require("src.hud.hoverService")`.
Provides mouse-hover tooltip panels. Only one tooltip visible at a time. Stateless — if not requested each frame, nothing renders.

### Usage

```lua
if iml.isHovered(x, y, w, h, myKey) then
    local mx, my = ui.getMouse()
    hoverService.requestHover(mx, my, function(box, fonts)
        box:addText("{c r=0.9 g=0.85 b=0.7}Title Text", fonts.title)
        box:addSpacing(2)
        box:addText("{c r=0.7 g=0.7 b=0.75}Description here.", fonts.body)
    end)
end
```

- `requestHover(mouseX, mouseY, builder, col1?, col2?)` — requests a tooltip this frame.
  - `builder(box, fonts)` receives a `ui.Box` (maxWidth=180, padding=10, spacing=4) and `{title=bigFont16, body=smallFont16}`.
  - `col1`, `col2` are optional gradient background colors.
- `hoverService.draw()` — renders the pending tooltip. Call once per frame, after all UI (so it draws on top). The HUD calls this automatically at the end of `HUD:drawUI`.

Tooltip auto-positions near the mouse, clamping to screen edges.


## Conventions

- Always use richtext for rendering text. Ensure text is localized with `loc()`.
- Avoid scaling images. Use `g.drawImage` for native-size icons.
- Use `ui.drawPanel` / `ui.drawDarkPanel` for borders (9-slice). Don't roll your own.
- Use `helper.gradientRect` for background fills and visual polish.
- Use `ui.Box` for anything that stacks text/content vertically (tooltips, cards, lists).
- Use `hoverService` for mouse-hover explanations. Don't roll your own tooltip system.
- All UI code must be inside `ui.startUI()` / `ui.endUI()`.
- Use `ui.getScreenRegion()` as the root kirigami region for layout.
- Use `ui.getMouse()` (not `love.mouse.getPosition()`) for mouse coords in UI space.
