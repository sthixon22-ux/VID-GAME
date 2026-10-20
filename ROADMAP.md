# Toward the polished demo

The agreed target is a polished short adventure with a village, forest route, dungeon and boss. Version 0.3 delivers a playable story arc and establishes the integration points. It does not establish the target's final visual quality or play length.

## Delivered in 0.3

- Complete beginning-to-ending quest flow, portrait dialogue and saved objectives.
- Distinct forest and dungeon scenes with exploration rewards and persistent progression.
- Mossling guardians and a boss whose charge can be countered by Defend.
- Original procedural textures, portraits, music, water/wind shaders and basic animation.
- Automatic combat/persistence/full-story checks and rendered-screen inspection.

## Delivered in 0.4

- CC0 KayKit rigged Knight/Rogue/Mage outfits, with live equipment preview and eight independently managed slots.
- Skeletal action clips, battle poses, walking/running, hit reactions and victory/defeat. Each hero ability has its own clip/effect combination.
- CC0 Quaternius modular cottages and painted PBR stone/wood/plaster/roof materials.
- Dedicated six-node branching skill pages for Paladin, Ranger and Druid, with descriptions, prerequisites, point costs and mythic availability.
- Legacy skill/equipment save migration and a separate presentation/character integration suite.

## Delivered in 0.5 — Project Mythic foundation

- Existing-project audit and prioritized dependencies: [technical audit](docs/PROJECT_MYTHIC_AUDIT.md), guided by the preserved [master brief](docs/design/PROJECT_MYTHIC_V1.md).
- Shared movement substeps and collision-aware orbit camera, with camera-only scenery/wall blockers.
- Modal settings in title, exploration and battle; independent presentation speed, minimal animations, reduced camera motion, sensitivity, audio volumes/mute.
- Versioned, validated save replacement; previous-file recovery; preserved unversioned originals and incompatible newer saves.
- Reliability regression suite alongside the original game/presentation suites.

## Delivered in 0.6 — representative demo loop

- Character creation with primary/two secondary selections and visual colors; unequipped arrival with a starter purse.
- Outfitter, owned inventory/compatibility, starter-budget protection and consumable purchases.
- Independent class/weapon mastery, compact weapon trees, data-defined abilities, timed statuses and Guardian of the Wild chemistry.
- Six functional permanent companion choices, previews, automated roles, training/progression and persistent HP. First bond after the quest; second only after the optional postgame echo; two owned/one active.
- Visible Moonleaf guards, journal/field guide, risk/results Auto-Battle UI, optional postgame board challenge and schema-2 save compatibility.
- Full details and limitations: [demo report](docs/DEMO_0_6.md).

## Next: verify the public-release bar

Run fresh, timed Windows playthroughs without test teleports. Check whether the complete opening reaches the 15–20-minute target, tune costs/MP/encounter difficulty and verify everyone finds the shop, trees and companion endpoint. Review audio, keyboard/controller focus and readability. Bring remaining creature/companion art and animation to a consistent quality bar; the procedural additions demonstrate function, not final production quality.

The ability/status/chemistry and basic ownership/companion foundations now exist. Extend content only after testing and refining these systems; do not replace the current quest or claim all twelve classes are complete.

## Next: unify the art target

The hero rig/outfits and village kit are integrated. Bring the wolf, enemies, Warden and foliage to the same quality bar with consistent meshes, UVs, textures and rigs. Refine the original prototype equipment overlays and spell choreography. Confirm visual style, silhouette, scale, lighting and readability in an actual Windows playtest before expanding the asset count.

## Next: camera and game feel

Refine camera blockers, add smooth encounter transitions, better attack choreography and spell-specific effects. Improve following/pathfinding and replace approximate blockers where needed. Move stats and telegraphs into a more deliberate battle HUD and test mouse/keyboard focus through all submenus. Volume controls are now available; test the score and effects through speakers/headphones.

## Next: content, pacing and balance

Expand the route with meaningful discoveries and conversations, add a small enemy mix and better encounter variation, and replace free gear toggles with a simple inventory/reward economy. Test fresh characters through the full story without teleports or debug actions. Measure play length and adjust the route, dialogue and encounters toward the 15-minute target without padding it with repetitive fights.

## Finish criteria

- A new player can install, start, understand and finish without developer help.
- Characters, scenery, portraits and animation have a consistent, agreed visual quality.
- Combat choices and boss telegraphs are legible; consumables, defeat and saves work reliably.
- No blockers in the full quest flow; acceptable performance on the selected Windows hardware.
- Music, sound, menus, credits and settings are complete enough for a public demo.
- Exported Windows build is tested on a separate machine, alongside the editable Godot project.

No delivery date is promised by this roadmap. Asset quality, playtest feedback and the final scope determine the remaining work.
