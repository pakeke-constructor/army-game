--[[
SQUAD LINEUP UI
===============
A full-screen (or panel) UI for managing which squads are in the player's lineup.

CONTEXT:
- g.getArmy() returns ALL squads the player owns (g.Squad[])
- g.getLineup() returns only squads where squad.inLineup == true
- Each squad has a mana cost: g.getSquadInfo(squad.squadId).cost (a g.ManaBundle, e.g. {red=2, blue=1})
- The player has limited mana per type. g.getManaInfo(manaType) returns (maxMana, manaInfo).
- g.canAffordSquad(squad) checks if activating this squad fits within mana budget alongside current lineup.
- g.setSquadActive(squad, active) sets squad.inLineup; returns false if can't afford.

LAYOUT (3 vertical sections via region:splitVertical):
  1. TOP (small): Mana bar / budget display.
     - For each mana type in g.getManaTypes(): show used/max (e.g. "3/5" with icon).
     - Used = sum of that mana type across all active squads' costs.
     - Max = g.getManaInfo(manaType) (first return value).
     - Only show mana types where max > 0.
  2. MIDDLE: Current lineup (the active squads).
     - Horizontal row of squad icons/mini-cards for squads where squad.inLineup == true.
     - Clicking a lineup squad removes it (g.setSquadActive(squad, false)).
  3. BOTTOM (large): Bench / all other squads in a grid.
     - Use helper.getBestFitDimensions(#benchSquads, region.w, region.h) for cols/rows.
     - Then region:grid(cols, rows) to get cells.
     - Show squads where squad.inLineup == false.
     - Clicking a bench squad adds it to lineup (g.setSquadActive(squad, true)).
     - If g.setSquadActive returns false (can't afford), don't add; optionally flash/shake.
     - Dim or grey out squads that can't be afforded (use g.canAffordSquad(squad) to check).

DRAWING EACH SQUAD ENTRY:
- Use g.drawSquadIcon(squad.squadId, x, y, w, h) for the icon.
- Below/beside the icon, show mana cost via richtext: g.manaCostString(g.getSquadInfo(squad.squadId).cost)
- For click detection: iml.panel(x,y,w,h, id) then iml.wasJustClicked(x,y,w,h, 1, id).
- Use squad.squadId .. tostring(i) or similar as unique iml id (avoid collisions between lineup/bench).

KEY APIs:
- g.getArmy() -> g.Squad[]              (all squads)
- g.getLineup() -> g.Squad[]            (active squads only)
- g.setSquadActive(squad, bool) -> bool  (toggle; returns false if can't afford)
- g.canAffordSquad(squad) -> bool        (check without toggling)
- g.getSquadInfo(squadId) -> g.SquadInfo (has .cost, .icon, .name, .entityId, .rarity)
- g.getManaInfo(manaType) -> maxMana, manaInfo  (manaInfo has .id, .image, .color)
- g.getManaTypes() -> string[]           (list of mana type ids)
- g.manaCostString(bundle) -> string     (richtext string for cost display)
- g.drawSquadIcon(squadId, x,y,w,h)     (draws icon with rarity border)
- helper.getBestFitDimensions(n, w, h) -> cols, rows
- region:grid(cols, rows) -> Region[]
- region:splitVertical(r1, r2, r3) -> Region, Region, Region
- iml.panel(x,y,w,h, id) / iml.wasJustClicked(x,y,w,h, btn, id) / iml.isHovered(x,y,w,h, id)
- ui.drawDarkPanel(x,y,w,h) / ui.drawPanel(x,y,w,h) for backgrounds
- richtext.printRich(str, font, x, y, w, align) for rendering richtext strings

RETURN VALUE:
- This module should return drawSquadLineUp(region) as a function.

NOTES:
- This is a management screen, NOT the battle HUD. The battle HUD uses g.getLineup() separately.
- Keep it simple. No drag-and-drop. Just click to toggle squads between lineup and bench.
- ui.assertUIStarted() should be called at the top of drawSquadLineUp.
]]


---@param squad g.Squad
local function drawSquad(squad, x,y)
    -- g.drawSquadIcon here,

    -- and then below, draws the mana cost, inside a panel.
end


---@param region kirigami.Region
local function drawSquadLineUp(region)
    local top, lineup, squads = region:splitVertical(
        1, -- 10% taken by header, and shows available mana
        3, -- The current lineup
        6 -- 60% rest; shows the rest of the squads in a big grid, `helper.getBestFitDimensions`
    )
    -- top part: the squads in the lineup.

    -- middle panel: All available squads (except squads in lineup)
end

