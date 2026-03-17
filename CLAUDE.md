

# Project:

## Army-Game
Army-Game a 2d roguelike / RTS / deckbuilder game made in love2d with lua.


## Project architecture:
- `g.lua`: Is the most important file, containing most useful functions.
Classes:
- `ScreenBuffer`: used to render to screen.
- `InputPass`: cleared every frame; handles input management/blocking
- `Region`: represents (x,y,w,h) tuple; used for immediate-mode layout.
- `Context`: represents a LLM context window (and potentially a running LLM.)
- `Message`: represents a message (system, user, assistant). Can return content dynamically/lazily.



