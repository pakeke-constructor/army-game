

--[[

squad-card:
A representation of a squad, it's stats, traits + perks.


CARD UI: Vertical card. Title at top.
Border = same color as rarity.
Background = black with a small fade towards rarity-color; but mostly dark.

<CARD LAYOUT>
Icon (squad.icon), Title (white-text)
Layout of Traits (use ui.drawTraitBox). Should be DIRECTLY below title.

On it's own line: Unit count, x6, x4

A 3x2 grid of stats:
- health
- damage
- attackSpeed
- armor
- speed
- attackRange

List of perks below:
<perk>
perk title (+ rarity color)
perk description (richtext)
</perk>

<perk>
...
</perk>



</CARD LAYOUT>

]]


