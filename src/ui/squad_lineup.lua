



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

