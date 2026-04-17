---
name: ui
description: Use when creating UI
---


explains following concepts:
- iml, and how its used (panels, wasJustClicked)
- Kirigami, and how best to use it
- startUI, endUI and the ui.getScreenDimensions() pattern. And how ui scaling works

Conventions:
- Avoid scaling images
- Always use richtext for rendering text (and ensure text is localized)
- 9slice is good. use `ui.drawPanel` and/or `ui.drawDarkPanel`.
- Gradient-rects are good. Use helper.gradientRect if wanting to add "jazz"
- Consider ui.Box for anything that requires a display of text, like a list. It's API is very nice.
- For mouse-hovering to show UI, you MUST use hoverService; it's super good.


