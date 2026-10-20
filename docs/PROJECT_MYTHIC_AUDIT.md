# Project Mythic — existing-project audit

Historical 0.4/0.5 baseline. Several gaps below are now addressed by [demo 0.6](DEMO_0_6.md); read that report for current implementation and remaining release work.

Baseline: `27d0c306bcd46d51ddd4c86d66956684a62d16d7` (adventure 0.4). Design authority: [PROJECT_MYTHIC_V1.md](design/PROJECT_MYTHIC_V1.md). A local Git backup branch, `backup/pre-project-mythic-0.4`, preserves this baseline; no replacement project or worktree was created.

## Baseline evidence

Godot 4.6.3 is installed. The existing full-game suite completed **60 passing checks**, and the character/presentation suite completed **61 passing checks**, without script errors. Those tests cover a real quest-to-ending scene sequence and distinct skeletal clips, but do not establish subjective visual quality or Windows performance. Rendered review is required after visual changes. Source review covered the current scripts/scenes, data, tests, asset provenance and capture/generation tools.

## Existing structure and what to retain

| Area | Existing implementation | Retain |
|---|---|---|
| Startup | `project.godot`, `scenes/title.tscn`, `scripts/title.gd`; State and Sound autoloads | Existing application/user-data identity, Continue/New adventure and explicit new-game backup |
| Exploration | `world.gd`, `forest.gd`, `village_art.gd`; WASD, orbit, sprint, river/bridge boundaries, roaming goblins, gathering | Willowbrook/Sunstream layout and all interactions; improve the shared movement/camera behavior |
| Dungeon | `dungeon.gd`; generated walkable grid, guardians, two seals, one-time cache, Warden, return route | Exact layout, progression flags, guardian permanence and entrance/exit behavior |
| Story | `data/dialogue.json`, `dialogue.gd`; portrait conversations, shrine callback, ending and epilogue | All current dialogue, story, quest objectives and rewards; no replacement lore |
| Combat rules | `combat.gd`; deterministic seed, speed order, HP/MP, attacks, defense, healing, enemy charge, wolf automation | Shared simulator and its tests; calculations remain independent of playback |
| Presentation | `battle.gd`, `battle_motion.gd`, `hero_visual.gd`; action clips, effects, camera shots, event-state HP bars, victory/defeat | Existing rig/socket integration and distinct action presentation; add pacing controls |
| Character UI | `character_menu.gd`, `skill_graph.gd`; eight slots, live 3D preview, three six-node trees | Existing pages, selected-node explanations, prerequisites, costs and primary-only mythics |
| Content data | `classes.json`, `equipment.json`, `enemies.json`, `dialogue.json` | Current content; extend schemas incrementally rather than reorganizing files unnecessarily |
| Assets | CC0 KayKit Knight/Rogue/Mage rigs; Quaternius cottage/PBR subset; original portraits/music/effects; simpler original creatures/foliage | Provenance records, licenses, functional assets and replaceable art factory |
| Persistence | `state.gd`; hero/class/skills/equipment/gold/mastery/quest/region/position JSON; legacy skill/gear conversion | Existing slot path and migration behavior; strengthen serialization, validation and recovery |
| Tests/tools | `tests/run.tscn`, `tests/presentation.tscn`, `tools/capture.tscn` | Existing regression suites, isolated test data, reproducible rendered captures |

## Gaps against the brief

| System | Current limit | Implication / follow-up |
|---|---|---|
| Movement and camera | Movement checks only the endpoint of a frame; camera has no obstruction sweep; dungeon camera is unsmoothed | Large frames can cross a narrow barrier. Cottages, trees and walls can obscure the view. Address now with shared helpers and dedicated camera-only blockers |
| UI/accessibility | Fixed 1280×720 layout scaled by the project; partial keyboard navigation; no battle speed/minimal-animation option, camera sensitivity slider or audio volume controls | Add reusable options now; later review responsive/controller navigation across all pages |
| Saves | Direct overwrite, no schema version, no automatic recovery on truncated files; only new-game backup | Add version metadata, validated temporary writes, previous-save recovery and future-version protection while keeping the current flat hero shape |
| Ability data | Names, costs, effects and starting spell lists are hardcoded in combat/UI; saved class/item keys are display names | Next foundation task: stable ability IDs/aliases, data-driven spellbooks/effects and a planned ID migration for remaining domains |
| Status effects | Mark and bind are scalar counters. Thornbind guarantees turn denial; Shield Bash guards instead of rolling stun; Regrowth heals instantly | These differ from the brief. Implement a reusable timed-status system and configurable seeded chances before chemistry; update descriptions and balance tests together |
| Primary/secondary classes | All three contribute learned passives, mythics are primary-only, primary can switch freely anywhere; no class mastery or full primary stat specialization | Preserve existing unlocks. Add mastery and controlled switching only after the provisional economy/conditions are chosen |
| Skill/weapon progression | Three six-node class trees, three points per level, early mythics; no separate weapon mastery trees/proficiency checks | Existing values are demo balance, not the proposed final ranges. Do not suddenly impose level 75 or remove unlocked mythics. Add eligibility as configurable data with migration |
| Chemistry | Not implemented | Build data rules on top of stable ability categories, block/status events and timed bonuses; Guardian of the Wild is the first candidate, not a fixed damage multiplier |
| Inventory/equipment | Free demo wardrobe; slots/stats/visuals work; no ownership, item descriptions/rarity/proficiency restrictions or set system | Add an inventory and class-compatible item schema, preserving current equipped items. Do not remove gear merely because a new restriction is introduced |
| Companions | Wolf follows and acts automatically; six null/name slots and a postgame field are placeholders only. Wolf HP resets per encounter | No selection, permanent two-choice cap, companion XP/levels/tree, travel framework or species-specific visuals. Build one data-driven framework and a post-intro chooser without rewriting existing wolf dialogue |
| Mastery/Auto-Battle | Goblin-only scalar counter, ten normal wins, shared simulation, possible defeat, current HP/MP use and normal rewards | Keep it. Add species-indexed records, preflight risk, structured results and learned-ability-aware policy later. Story guardians/boss remain excluded |
| Enemy growth | Three data definitions, basic attacks and Warden telegraph; no resistances/elemental/status-aware AI or multi-enemy encounters | Extend after reusable abilities/statuses. Mixed-species Auto-Battle remains undecided, not implicitly supported |
| Presentation/art | Rigged hero/Mira and textured cottages coexist with simple wolf/enemy/foliage meshes, approximate modular overlays and flat traversable terrain | Coherence remains unfinished. Replace remaining creature/foliage art and refine equipment placement, framing and contact timing incrementally |
| Audio | Original synthesized exploration/sanctuary/battle themes and cues, mute toggle | Add volumes now. Distinct boss score, ambience/monster voices and a production soundtrack remain future work |

## Architecture assessment

The simulator/presentation split, data-backed trees/items/enemies, scene boundaries and centralized character state are useful foundations. A rewrite would discard functioning behavior and test coverage. The next changes should extract only responsibilities actually reused: movement/camera, user options and save storage. Avoid creating a dozen empty managers for planned content.

`State` currently handles progression, equipment, migration and serialization. Extracting storage is justified by recovery/versioning requirements. The larger `world.gd` and `dungeon.gd` retain their own quest-specific interactions; do not replace them with speculative quest infrastructure during this milestone.

## Prioritized implementation plan

1. **0.5 — introductory-playthrough reliability and readability (current milestone).** Shared substepped movement and collision-aware orbit camera; camera blockers for cottages/trunks/canopies/dungeon walls; reusable modal options; presentation-only battle speed/minimal-animation/reduced-camera-motion controls; audio volumes and sensitivity; flat-compatible versioned recoverable saves. Preserve layout, story, existing battle rules and balance. Verify camera/movement, settings persistence, pace-independent battle results and corrupt/legacy/future saves, then render-review.
2. **Ability/status foundation.** Introduce stable IDs and aliases for abilities, data-driven class spellbooks and compatible weapon techniques. Implement regeneration over time, seeded stun/root chances, timed buffs and status HUD feedback. Migrate existing unlocks, and retain shared normal/Auto resolution. This unlocks chemistry and more interesting enemies.
3. **One chemistry interaction and progression eligibility.** Data-defined Guardian of the Wild plus visible trigger/consumption feedback. Add class and weapon mastery as independent progress records; keep XP/skill-point/rarity/mastery thresholds configurable. Resolve class-switch-location and point-economy decisions before enforcing them.
4. **Companion vertical slice.** Data-defined roster and ownership/active distinction, post-intro first-choice interface, explicit permanent-choice confirmation, basic XP/tree for one implemented companion. Preserve the temporary intro wolf. Reserve the second permanent choice for actual postgame state, with equivalent baseline travel benefits. Do not implement all six fully at once.
5. **Equipment/inventory economy.** Stable item IDs, owned inventory, compatible classes, rarity/descriptions, safe legacy gear grants, and honest stat comparisons. Then replace prototype overlays with coherent authored armor pieces.
6. **Mastery/results and enemy variety.** Per-species normal wins, risk/results window, ability-aware simulation, status/resistance-aware enemy patterns. Keep boss/special encounters excluded. Decide mixed encounters only when needed.
7. **Art and release polish throughout.** Bring remaining creatures and foliage to the hero/cottage quality bar, improve terrain composition and ambience, then controller/responsive UI, Windows performance and first-time-player pacing. Do not claim a polished 15-minute experience until observed with new players.

## Decisions deliberately left open

The working title does not rename the application or rewrite the story. Proposed mythic names, level cap, tier ranges, class chemistry ratings, one-point-per-level proposal, respec, class-switch conditions, equipment economy and permanent-companion unlock details remain configurable/planned. Existing three-points-per-level and current mythic unlocks remain intact in 0.5.

The full brief is the long-term direction; the audit distinguishes implemented behavior from reserved fields and future intentions. The remaining classes/companions/spells are not being created as empty stubs just to satisfy a roster count.


## 0.5 completion and verification

Implemented the first milestone in the plan. Shared movement/camera and camera-only art blockers are integrated into both exploration scenes. Settings are modal and persist separately; battle animation/effect/timer clocks use the chosen speed without changing `Engine.time_scale` or deterministic calculations. Minimal playback preserves event-state HP/MP/damage feedback. Storage is extracted into `SaveStore`, retains flat compatibility and old skill/gear migrations, validates temporary output, keeps a previous copy, recovers readable backups and refuses newer schemas.

Changed areas: `project.godot`; new `exploration_motion.gd`, `exploration_camera.gd`, `camera_obstacles.gd`, `user_settings.gd`, `options_panel.gd`, `save_store.gd`; integration in `world.gd`, `dungeon.gd`, `art.gd`, `village_art.gd`, `title.gd`, `battle.gd`, `battle_motion.gd`, `hero_visual.gd`, `sound.gd`, `state.gd`; reliability tests/capture runner and README/roadmap. No story, quest, class, equipment or enemy data was rewritten.

Validation with Godot 4.6.3: **60 game checks + 61 presentation checks + 19 reliability checks = 140 passing checks**. New tests cover long-frame barrier prevention/sliding, camera sphere sweep and outward recovery, legacy backup/schema metadata/fractional coordinates, corrupted primary fallback, backup preservation, future-version protection, unrecoverable-save blocking, persistent settings, unchanged engine clock, modal battle blocking and fast minimal playback matching the pure simulator. Runtime test logs contain no script errors. Editor import completed; the restricted sandbox emitted editor socket-listener errors, so runtime validation and an actual displayed capture run provided the execution evidence.

A software OpenGL/Xvfb run captured title/settings, village, dialogue, equipment, skill trees, dungeon, boss and Sacred Strike with no runtime errors (only unsupported V-Sync warning). Settings and dungeon captures were visually inspected. This establishes rendered functionality, not final art polish, Windows GPU performance, audio quality or comfortable real-player pacing.

Known limits: camera volumes approximate meshes and can pull close to the hero; following still cuts corners; movement remains lightweight rather than physical character navigation. A previous-save recovery may lose the most recent progress and cannot reconstruct two damaged files. The current save validator rejects malformed JSON and essential top-level types, not every possible manually edited nested field. Menus still target desktop 1280×720. Art remains mixed quality. Production-grade statuses, chemistry, mastery, companion choices and inventory ownership remain the next planned work; no new irreversible economy or class rules were imposed.
