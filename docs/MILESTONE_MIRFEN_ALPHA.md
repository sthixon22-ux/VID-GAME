# Mirefen / Reedcross / Sunken Reliquary — first playable alpha

## Status
This is **an early playable content scaffold**, not a polished or fully complete second major dungeon. It intentionally reuses existing demo systems and assets. The full narrative arc, unique regional shop inventories, water-gate machinery animation, new marsh creature meshes, and complete boss mechanics still need production work.

## Implemented on the campaign branch
- An optional transition to Reedcross near Willowbrook's southern road marker, available **after restoring the Hollow Warden and selecting a first permanent companion**. Existing demo-ending/echo play remains accessible.
- `scenes/mirefen.tscn`: Reedcross buildings, route through marsh, weapon/armor trader entry points (currently use existing general shop), inn restoration, existing Mossling encounters and travel into the reliquary.
- `scenes/reliquary.tscn`: traversable flooded ruins, two persistent floodgate switches, locked inner corridor and distinct keeper encounter.
- New `reliquary_keeper` enemy ID built on existing Mossling mesh and combat behavior. The keeper's victory sets `hero.campaign.reliquary_cleared`.
- Region-specific return routes and save/load routing in `state.gd`.
- `data/campaign.json` tracks full campaign structure as planning data only (the existence of records does not mean locations are playable).

## Known gameplay limitations
- The marsh map is a compact flat prototype; wooden walkway and swamp water currently have visual rather than physics-based boundaries.
- The two valves are toggle-by-interaction progression puzzles; no animation of rising/falling water and no mandatory combat in the Reliquary interior.
- The boss is an existing single-enemy combat archetype with an increased stat profile and reused mesh. It needs unique actions and visual identity.
- The two Reedcross traders currently reuse the existing global shop rather than offering differentiated inventories. Their signs indicate their intended future roles.
- Mirefen marsh encounters use the existing `mossling` species and do not introduce unique species yet.
- The fully authored human king introduction, quest-chain dialogue, additional side quests and region exit toward the desert are **not yet implemented**.
- This branch has not been run under Godot in the authoring environment. **Do not merge without Godot 4.6 headless checks and a manual playthrough.**

## Validation
Import the project and run:
```bash
godot --headless --path . --editor --import --quit
XDG_DATA_HOME=/tmp/verdant-campaign godot --headless --path . res://tests/campaign_expansion.tscn
for suite in run presentation reliability demo progression layout shop_flow adventure8; do
 XDG_DATA_HOME=/tmp/verdant-$suite godot --headless --path . res://tests/$suite.tscn
done
```
Open the actual game as a fresh character, complete the first quest, choose a companion, then travel to Reedcross and the reliquary. Confirm door collision, interaction distances, battle return positions, shop behavior and puzzle progression.

## Next development sprint
1. Fix issues found in Godot tests and human playthrough.
2. Add regional merchant-filtered inventories without breaking existing Willowbrook purchasing.
3. Add a coherent quest chain from the Hollow Warden to the Sunken Reliquary, including an early first audience with human King Aldren.
4. Give the marsh its own enemies and properly animated boss; make floodgate water level mechanically visible.
5. Make the next story region unlock only after the reliquary keeper is defeated.
