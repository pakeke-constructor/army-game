
-- TODO: not implemented yet. Mirror squad_card.lua when building the real spell card.
---@param spellId string
---@param region kirigami.Region
---@param index number
local function drawSpellCard(spellId, region, index)
    ui.assertUIStarted()
    lg.setColor(1,1,1)
    lg.rectangle("fill", region:get())
end

return drawSpellCard
