

local function damageEnemiesInRadius(x, y, radius, dmg)
    local r2 = radius * radius
    g.iteratePartition("enemy", x, y, function(ent)
        if ent.health and g.isAlive(ent) then
            local dx = ent.x - x
            local dy = ent.y - y
            if dx * dx + dy * dy <= r2 then
                ent.health = ent.health - dmg
                ent._timeSinceDamaged = 0
                g.call("entityHurt", ent, dmg, nil)
                if ent.health <= 0 then
                    g.killEntity(ent)
                end
            end
        end
    end, radius)
end


local function healAlliesInRadius(x, y, radius, amount)
    local r2 = radius * radius
    g.iteratePartition("ally", x, y, function(ent)
        if ent.health and ent.maxHealth and g.isAlive(ent) then
            local dx = ent.x - x
            local dy = ent.y - y
            if dx * dx + dy * dy <= r2 then
                ent.health = math.min(ent.maxHealth, ent.health + amount)
            end
        end
    end, radius)
end




local function spellRenderer(rad, c)
    local function drawSpellArea(x,y)
        local l = gsman.setLineWidth(5)
        local col2 = gsman.setColor(c[1],c[2],c[3],0.08)
        lg.circle("fill", x,y, rad-2)
        local col = gsman.setColor(c)
        lg.circle("line", x,y, rad)
        col:pop()
        col2:pop()
        l:pop()
    end
    return drawSpellArea
end


local ZAP_RAD = 100

g.defineSpell("zap", {
    name = loc("Zap"),
    description = loc("Damages enemies in radius"),
    manaCost = 2,
    cooldown = 0,
    icon = "coin_icon",
    castSpell = function(x, y)
        print("HI.")
        damageEnemiesInRadius(x, y, ZAP_RAD, 12)
    end,
    drawSpellHover = spellRenderer(ZAP_RAD, objects.Color.RED)
})




local HEAL_RAD = 60

g.defineSpell("heal", {
    name = loc("Heal"),
    description = loc("Heals allies in radius"),
    manaCost = 2,
    cooldown = 0,
    icon = "coin_icon",
    castSpell = function(x, y)
        healAlliesInRadius(x, y, HEAL_RAD, 10)
    end,
    drawSpellHover = spellRenderer(HEAL_RAD, objects.Color.GREEN)
})
