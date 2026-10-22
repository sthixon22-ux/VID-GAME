# Full-game architecture and implementation plan

## Ground truth from repository (main, Demo 0.8.0)
The existing opening already contains character creation for twelve classes, a 60/20/20 stat blend, twelve class trees and thirteen weapon-family trees, six permanent companion options, equipment and purchases, normal/auto battle, forest/plains/shrine and the Hollow Warden. The intro quest ends with Mira and a first permanent companion choice. Current tests listed in README are the baseline to preserve.

Relevant files:
- `scripts/state.gd`, `scripts/save_store.gd`: character/game state, migration and saving (schema 4).
- `scripts/game_rules.gd`, `scripts/combat.gd`, `scripts/battle.gd`: progression and deterministic combat/presentation.
- `scripts/world.gd`, `scripts/forest.gd`, `scripts/dungeon.gd`: existing area, traversal and dungeon logic.
- `scripts/quest_book.gd`, `data/dialogue.json`: existing quests and opening dialogue.
- `data/classes.json`, `data/abilities.json`, `data/equipment.json`, `data/enemies.json`, `data/companions.json`: combat and content registries.
- `tests/*.tscn`: baseline Godot test suites.

## Invariants
1. Never overwrite the opening / Willowbrook, Mira, Moonleaf, the Warden or existing companion selection.
2. Never alter `main` directly during a content sprint; develop on reviewable branches.
3. Keep all 12 selectable classes and two freely chosen secondaries; no Paladin/Ranger/Druid lock.
4. Only unlocked primary-class mythics can be used. Existing two-handed/shield rules remain.
5. Creature mastery remains ten **normal** victories, optional auto-battle with genuine defeat risk.
6. Companion selection stays two-per-run maximum and one active; existing echo-related second choice is currently in the demo. Narrative positioning of the second choice (originally postgame) must be reconciled rather than silently removed.
7. Existing save schema 4 must load, and legacy flags need versioned migration; never overwrite saves silently.
8. Keep combat simulation and visuals separate.
9. The king is introduced **after** the demo to avoid retroactive rewrites, but early in the full campaign.
10. Distinguish authored content, prototype placeholders and verified playable content in every progress report.

## Proposed integration plan
### Gate 0 — documentation and inventory (this branch)
- Write a full campaign bible, 12-dungeon layout, key people, regional shops and level pacing.
- Create an implementation roadmap anchored to current scripts and versioned save data.
- Add no scripts, meshes or incompatible scene changes. No gameplay regression possible from documents alone.

### Gate 1 — story / region scaffolding
- Build **data-driven** region, dungeon, NPC, shop and quest records using stable IDs.
- Add validation that every required reference resolves; no hardcoded shop inventories in UI.
- Introduce an explicit world/campaign state version that *augments* existing `hero.journey`; preserve current flags.
- Provide a bridge from `journey.finished == true` to Act I continuation without altering the old ending or postgame echo.

### Gate 2 — playable Region 2
- Add Mirefen marsh and Reedcross village (weapon shop, armor shop, inn, at least two side quests).
- Add marsh enemy ecology, battle integration, rewards and balanced regional equipment.
- Add Dungeon #2, Sunken Reliquary, with water-level exploration puzzles and boss.
- Introduce the human king through a royal summons or regional mission following dungeon #1.
- Verify a real path from existing demo through Reedcross and dungeon #2; confirm no softlocks.

### Gates 3–5 — repeatable expansion
- Add each new region, town and dungeon with reusable design patterns; never create a huge world full of unreachable or empty areas.
- Act II: dungeons 3–5; Act III: dungeons 6–8 and reveal; Act IV: dungeons 9–11 and historical reckoning.
- Add breadth of enemy behaviors only when the shared battle simulator supports it.

### Gate 6 — branching ending
- Implement explicit allegiance confirmation, independent destinations/encounters for dungeon #12, unique final bosses (Vaelor or Aldren), cinematic ending states and postgame.
- Tests must assert that neither path can be entered prematurely and both can be completed.

## Engineering prerequisites
- Inventory current `state.gd` and `save_store.gd` schema before touching saves.
- Preserve named weapon and enemy IDs across migrations.
- Factor new campaign records into new `data/` files, use `RefCounted` loaders or Resources rather than single huge scripts.
- Avoid duplicating dialogue/quest condition logic; add tests for every story flag.
- Make door exits safe with persistent destination and position.
- Reuse art pipeline with legal sources, document licenses and verify Godot imports.
- Test performance with bounded region loads and stable enemy counts.

## Verification commands (from README)
```bash
godot --headless --path . --editor --import --quit
for suite in run presentation reliability demo progression layout shop_flow adventure8; do
  XDG_DATA_HOME=/tmp/verdant-test-$suite godot --headless --path . res://tests/$suite.tscn
done
```
These tests must be executed in Codex or a Godot-equipped environment. Writing these documents does **not** mean they ran.

## Definition of done for one region
Entrance from previous area, usable town and shops, a quest chain with save/resume, traversable biome, at least three distinct encounters, dungeon puzzle, distinct boss and rewards, route to next region, no hardlock, passing existing regression tests and rendered visual review.

## Next Codex execution task
Read both files in `docs/design/` and inspect current `scripts/state.gd`, `scripts/forest.gd`, `scripts/dungeon.gd`, `scripts/world.gd`, `scripts/save_store.gd` and test suites. First implement the **smallest stable campaign bridge** from completed opening to a *new* region; add tests and save migrations where necessary. Then build playable Mirefen/Reedcross/Dungeon #2 incrementally. Stop before introducing speculative changes to original combat formulas.

## Gate 2 progress — tested Mirefen alpha

The campaign scaffold is now a scene-tested Chapter 2 loop with Aldren’s regional audience, Iona’s three-survey investigation, differentiated Reedcross shops, two local errands, four regional species and a tide-telegraph Keeper. Water height, passage gating, treasure, reporting and rewards persist under additive schema-four campaign defaults. Approved hero/class/companion artwork is retained through a merge of the existing art branch. See [the milestone report](../MILESTONE_MIRFEN_ALPHA.md) for executed checks and explicit visual/playtest limits.

Next gate: timed Windows fresh-start chapter playtest, environmental/creature refinement, water-puzzle depth, encounter/economy pacing and focus/accessibility review. Do not start Dungeon 3 until those Chapter 2 quality checks are reviewed. The Sahir clue is saved, but its route is deliberately unavailable.
