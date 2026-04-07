g.definePerk("tough", "Tough", {
    description = loc("This unit takes 2 less damage from attacks."),
    image = "coin_icon",
    handlers = {
        getDamageReduction = function(ent)
            return 2
        end,
    },
})

g.definePerk("sharpshooter", "Sharpshooter", {
    description = loc("This unit fires 1 extra projectile."),
    image = "coin_icon",
    handlers = {
        getProjectileCountModifier = function(ent)
            return 1
        end,
    },
})

g.definePerk("berserker", "Berserker", {
    description = loc("This unit gains +5 attack when below 50% health."),
    image = "coin_icon",
    handlers = {
        onAttack = function(ent, attack)
            if ent.hp and ent.maxHp and ent.hp < ent.maxHp * 0.5 then
                attack.damage = attack.damage + 5
            end
        end,
    },
})

g.definePerk("vampiric", "Vampiric", {
    description = loc("This unit heals for 3 HP on kill."),
    image = "coin_icon",
    handlers = {
        entityKillsEnemy = function(ent, target)
            if ent.hp and ent.maxHp then
                ent.hp = math.min(ent.hp + 3, ent.maxHp)
            end
        end,
    },
})
