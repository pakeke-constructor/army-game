# Traits system

Per-unit traits, simpler than perks. Use entity scope handlers (like perks' per-entity handlers).

## Steps
1. g.lua: add TRAIT_DEFS/TRAIT_LIST near PERK_DEFS.
2. g.lua: g.defineTrait(id,name,info), g.getTraitInfo, g.getTraitDefList.
3. g.lua: g.addTrait/removeTrait/getTraitList (per ent, via scope/addCustomEffect).
4. g.lua: g.squadCanDeployAnywhere(squad) checking startingTraits' deployAnywhere flag.
5. defineSquad: info.startingTraits default {}. SquadInfo doc field.
6. spawnSquad: apply startingTraits to each unit after scope set.
7. battle_scene deploy: allow anywhere if squadCanDeployAnywhere.
8. content/traits/traits.lua: flying (deployAnywhere), fireproof (no burn).
