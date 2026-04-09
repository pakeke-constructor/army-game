

--[[

PixelCanvas class:
Essentially is a big canvas that the user can render to to make their stuff pixelart.
It achieves this by creating a smaller canvas that is to be rendered to, and then
upscaling that canvas to fit the entire screen.

## USAGE:


function love.draw()
    pc = PixelCanvas(screenWidth, screenHeight)

    transform = camera:getTransform() or love.math.newTransform()

    pc:start(transform) -- applies transform, sets canvas.

    renderStuff(...)
    love.graphics.circle("fill",x,y, 5)

    pc:finish() -- renders canvas, pops transform, etc.
end


-- if start is called twice in a row (no finish) raise error.



## SPECIAL DETAILS:
PixelCanvas sounds simple, but there's actually a bit more going on.
Notably, pixelCanvas objects are meant to be the size of the screen.
they won't neccessarily render to the entire canvas; only renders to a portion.

then, when ps:finish() is called, the canvas portion is scaled such that it FITS the size of the screen.

The PS objects will also scale their pixels to be the size of scale of THE TRANSFORM.

## Agent instructions:
All of this is a bit complex; so make sure you do planning and thinking before proceeding.

]]

local PixelCanvas = objects.Class("g:PixelCanvas")



function PixelCanvas:init()
end


function PixelCanvas:init()
end



return PixelCanvas


