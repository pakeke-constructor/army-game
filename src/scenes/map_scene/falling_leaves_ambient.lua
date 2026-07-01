---@class fallingLeavesAmbient.Args
---@field sprites string[]
---@field count integer
---@field margin number
---@field minSpeed number
---@field maxSpeed number
---@field minDrift number
---@field maxDrift number
---@field sway number
---@field minScale number
---@field maxScale number
---@field minLifetime number
---@field maxLifetime number
---@field flipChance number
---@field flipMinSpeed number
---@field flipMaxSpeed number

---@class fallingLeavesAmbient.Leaf
---@field x number
---@field y number
---@field vx number
---@field vy number
---@field r number
---@field vr number
---@field scale number
---@field sprite string
---@field sway number
---@field flip number
---@field flipSpeed number
---@field lifetime number
---@field maxLifetime number

---@param args fallingLeavesAmbient.Args
---@return MapType.AmbientService
return function(args)
    local service = {}
    local leaves = {}
    local window = { x = 0, y = 0, w = 100, h = 100 }

    local count = args.count
    local margin = args.margin
    local minSpeed = args.minSpeed
    local maxSpeed = args.maxSpeed
    local minDrift = args.minDrift
    local maxDrift = args.maxDrift
    local sway = args.sway
    local minScale = args.minScale
    local maxScale = args.maxScale
    local minLifetime = args.minLifetime
    local maxLifetime = args.maxLifetime
    local flipChance = args.flipChance
    local flipMinSpeed = args.flipMinSpeed
    local flipMaxSpeed = args.flipMaxSpeed
    local sprites = args.sprites

    ---@param transform love.Transform
    local function windowFromTransform(transform)
        local sw, sh = love.graphics.getDimensions()
        local x1, y1 = transform:inverseTransformPoint(0, 0)
        local x2, y2 = transform:inverseTransformPoint(sw, sh)
        window.x = math.min(x1, x2)
        window.y = math.min(y1, y2)
        window.w = math.abs(x2 - x1)
        window.h = math.abs(y2 - y1)
    end

    ---@param fromTop boolean?
    ---@return fallingLeavesAmbient.Leaf
    local function randomLeaf(fromTop)
        local mx = window.w * margin
        local my = window.h * margin
        local y1 = window.y - my
        local y2 = fromTop and window.y or (window.y + window.h + my)
        local flip = love.math.random() < flipChance

        return {
            x = helper.lerp(window.x - mx, window.x + window.w + mx, love.math.random()),
            y = helper.lerp(y1, y2, love.math.random()),
            vx = helper.lerp(minDrift, maxDrift, love.math.random()),
            vy = helper.lerp(minSpeed, maxSpeed, love.math.random()),
            r = love.math.random() * math.pi * 2,
            vr = helper.lerp(-1.2, 1.2, love.math.random()),
            scale = helper.lerp(minScale, maxScale, love.math.random()),
            sprite = sprites[love.math.random(1, #sprites)],
            sway = love.math.random() * math.pi * 2,
            flip = flip and love.math.random() * math.pi * 2 or 0,
            flipSpeed = flip and helper.lerp(flipMinSpeed, flipMaxSpeed, love.math.random()) or 0,
            lifetime = 0,
            maxLifetime = helper.lerp(minLifetime, maxLifetime, love.math.random()),
        }
    end

    ---@param transform love.Transform
    function service.reInitialize(transform)
        windowFromTransform(transform)
        leaves = {}
        for i = 1, count do
            leaves[i] = randomLeaf(false)
        end
    end

    ---@param dt number
    ---@param transform love.Transform
    function service.update(dt, transform)
        windowFromTransform(transform)

        for i = #leaves + 1, count do
            leaves[i] = randomLeaf(false)
        end
        for i = #leaves, count + 1, -1 do
            leaves[i] = nil
        end

        local mx = window.w * margin
        local my = window.h * margin
        for i, leaf in ipairs(leaves) do
            leaf.sway = leaf.sway + dt * 2
            leaf.x = leaf.x + (leaf.vx + math.sin(leaf.sway) * sway) * dt
            leaf.y = leaf.y + leaf.vy * dt
            leaf.r = leaf.r + leaf.vr * dt
            leaf.flip = leaf.flip + leaf.flipSpeed * dt
            leaf.lifetime = leaf.lifetime + dt

            local outside = leaf.y < window.y - my
                or leaf.y > window.y + window.h + my
                or leaf.x < window.x - mx
                or leaf.x > window.x + window.w + mx

            if outside or leaf.lifetime >= leaf.maxLifetime then
                leaves[i] = randomLeaf(true)
            end
        end
    end

    ---@param transform love.Transform
    function service.draw(transform)
        local lg = love.graphics
        lg.push("all")
        lg.applyTransform(transform)
        for _, leaf in ipairs(leaves) do
            local t = leaf.lifetime / leaf.maxLifetime
            local fade = math.min(t / 0.2, (1 - t) / 0.2, 1)
            local sx = leaf.scale
            if leaf.flipSpeed > 0 then
                sx = leaf.scale * math.cos(leaf.flip)
            end
            lg.setColor(1, 1, 1, fade)
            g.drawImage(leaf.sprite, leaf.x, leaf.y, leaf.r, sx, leaf.scale)
        end
        lg.pop()
    end

    return service
end
