# Mirefen / Reedcross / Sunken Reliquary — tested Chapter 2 alpha

This milestone extends `feature/campaign-content-registry` on `feature/mirefen-chapter-polish`; `main` and the original demo ending remain intact. The previously approved Quaternius hero/class skins and companion-art branch were merged because the campaign scaffold predated them. All twelve primary classes, freely chosen secondaries and male/female looks remain available.

## Playing Chapter 2

Import `project.godot` in Godot 4.6+, press **F5**, and continue your existing adventure. Restore the Hollow Warden, return its ember to Mira and choose your first permanent companion. At Willowbrook's **southern road marker**, walk to the road exit and press **E** for Reedcross. The old ending and optional echo still work; a new adventure is unnecessary for a completed save.

1. Meet **King Aldren and Messenger Elian** in Reedcross's southern square. Aldren commits supplies and evacuation boats and gives a one-time travel purse.
2. Speak with **Warden Iona** at the northern square. Read all three blue survey stones along the causeway and return to her for the sluice key.
3. Enter the Sunken Reliquary at the northern road end. Drain the west basin, cross its bed, find the optional cache, divert the east channel, and enter the heart chamber.
4. Face the **Keeper of the Drowned Oath**. Its crown gathers water before **Oathbreaker Tide**; Defend on the following turn to reduce the blow. Return to Iona after victory for the chapter reward and Emberglass/Sahir clue.

**Sahir/Dungeon 3 is not implemented or accessible.** The clue is a saved continuation hook, not a claim that the next region is playable.

## Delivered gameplay

- Distinct weapon and armor market stalls using the existing purchase, compatibility, ownership, equipment and rotating-preview systems. Willowbrook retains its small starter inventory.
- Reedsteel sword, marsh daggers, willowheart staff, reed bow and ferryman spear; reedcoat, sluicekeeper robe and fenwarden pendant. These are regional stat variants using existing weapon/armor mesh families, not eight newly sculpted items. Ranger/Druid/Healer equipment emphasis retains compatible alternatives for other builds.
- Free recovery at the inn; inventory, skill, companion and journal pages; save/load and return travel.
- **Medicine on the High Water:** Sella needs four separate silverreed bundles; reward 100 base gold and 140 XP.
- **The Ferryman's Road:** Jory needs three Reed Stalkers defeated; reward 120 base gold and 160 XP. Victories before accepting count. Each side reward is claimable once; dexterity bonus gold uses the established rules.
- Three water readings, dialogue completion flags, dungeon key, two water mechanisms, a hidden 75-gold/ether/potion cache, Keeper completion and the return report all persist.
- Main return reward: 260 XP, 200 base gold and a Fenwarden Pendant. Royal travel purse: 90 base gold. Replaying conversations cannot repeat either payout.
- Regional defeat retreats to Reedcross's inn rather than moving the player to a distant Willowbrook camp. Normal and auto encounters share this behavior.

## Region and dungeon presentation

Reedcross has the royal relief camp, four named local characters plus messenger, two awning stalls with display stock, an inn sign, ferry landing, relief crates, lit wayfinding and a bounded causeway. Marsh surfaces, reeds/cattails, trees, channel water, restrained atmospheric fog, winding plank sections and an original looping ambient track distinguish it from Willowbrook. The minimap uses regional coordinates and service/survey markers.

The Reliquary has a vestibule, western basin, eastern gallery and inner oath chamber. Floodwater is above the floor before draining; animated lowering exposes the basin bed. Collision progression follows saved water flags, with small movement substeps preventing long-frame wall/floodgate bypass. Water height is restored immediately on re-entry. Partition walls, lintels, stone surfaces, lanterns and an optional drained treasure pocket replace the original two-switch empty corridor. The boss arena adds water channels, crown silhouette and tide VFX.

This remains compact authored geometry, not final environmental art. There is no fluid simulation, branching multi-state sluice puzzle or swimming; the first gate must drain before the east diversion can operate.

## Enemies and boss

| Species | Combat identity | Visual foundation |
|---|---|---|
| Mire Leech | Slow vitality recovery after attacking | Original segmented procedural creature with wriggle animation |
| Lantern Bog Wisp | Drains 3 MP on alternating turns | Original emissive core/cage with hovering and action motion |
| Reed Stalker | First-round ambush attack bonus | Existing CC0 animated wolf derivative with reed crest |
| Drowned Sentinel | Periodic self-repair instead of attacking | Existing CC0 stone-guardian derivative and native/retargeted actions |
| Keeper of the Drowned Oath | Repeating charge/telegraph/tide cycle, countered by Defend | Enlarged guardian derivative, original crown/wards and water presentation |

Stats are fixed regional tuning, not derived from hero level. Current values target roughly level 6–12; the campaign bible's 8–15 remains a planning band requiring pacing review. Ten **normal** victories unlock the existing forecast/optional Auto-Battle for each ordinary species. Auto victories do not grant mastery, may lose and consume real resources. The Keeper requires normal combat even if a manipulated save contains ten boss victories.

The Keeper is mechanically distinct from an ordinary monster but still uses the guardian rig; it is not a commissioned unique creature. Leech/wisp assets and simple NPC staging especially need another art pass.

## Architecture and save compatibility

- `mirefen_rules.gd`: additive version-one campaign defaults, objective text, collection and valve rules.
- `mirefen.gd` / `reliquary.gd`: region interactions and traversal.
- `marsh_art.gd` / `marsh_creature.gd`: environment, local actors and creature presentation, separate from combat state.
- `combat.gd`: species-specific telegraph/drain/repair/ambush behavior in the existing deterministic simulator; hero damage formulas and prior enemy behaviors remain unchanged.
- Existing shops, quests, items, equipment, companion and battle systems are extended rather than duplicated.
- Save schema stays **4**; `hero.campaign.version` is **1**. Existing partial west/east/clear flags are preserved and missing fields default safely. Legacy files without campaign data cannot inherit the running session's completed chapter flags. Invalid campaign arrays/booleans are rejected by the normal validated-save workflow.
- No new playable class, forced build, save-path/application-name change, companion ownership change or mythic-rule exception.

Historical art-lab hash checks explicitly exclude the requested campaign files now being developed. The companion suite still protects the original companion rules/data, class catalog, skins and hero adapter; its old state/combat hash assertions are replaced by the executed campaign and gameplay regressions. These scoped exceptions are visible in source rather than rewriting historical hash evidence.

## Validation

Godot **4.6.3, Linux**, headless tests and actual OpenGL Compatibility renders on the local software display:

- **1,760 assertions passed** across 15 suites: core story 67, presentation 63, reliability 19, demo 159, progression 283, layout 6, shop flow 174, opening adventure 132, progression 0.9 136, hero art 141, class skins 209, companion art 206, campaign expansion 14, Chapter 2 **76**, art lab 75.
- Separate campaign catalog script validates all twelve planning records and starting-town references. Initial baseline failure from missing `starting_town` fields is fixed.
- New scene-driven tests execute the royal/local dialogue, survey collection, both side rewards, store purchases/equips, partial saves, visible flood levels, hidden cache, main reward, actual cinematic victory callback, legacy defaults and return/re-entry. Boss simulation is seeded and Defend's mitigation is compared directly. Twelve uninvested level-six primary-class builds with regional gear and a companion win the boss tuning smoke test; this is not exhaustive balance certification.
- A clean project copy imports without using the existing `.godot` cache. The chapter suite is also run in that clean copy.
- Nine actual rendered captures cover town, Aldren, causeway, shop, flooded/drained dungeon, heart, Keeper and telegraph. [Screenshots](screenshots/mirefen/).

Existing native `Parameter "material" is null` diagnostics still occur in headless presentation/demo/class-skin stress fixtures despite their passing assertions. These are not GDScript failures. The clean import, Chapter 2 suite and normal chapter-render captures are checked separately; the assertion total is not a claim that every stress log is error-free. Detailed suite results: [validation record](validation/mirefen_chapter_results.json).

Reproduce with isolated user data (tests create saves):

```bash
godot --headless --path . --editor --import --quit
for suite in run presentation reliability demo progression layout shop_flow adventure8 progression9 hero_quaternius class_skins companion_art campaign_expansion mirefen_chapter; do
  XDG_DATA_HOME=/tmp/verdant-$suite godot --headless --path . res://tests/$suite.tscn
done
XDG_DATA_HOME=/tmp/verdant-catalog godot --headless --path . --script tests/campaign_catalog.gd
XDG_DATA_HOME=/tmp/verdant-lab godot --headless --path . res://art_lab/validate.tscn
```

With a display, `tools/mirefen_capture.tscn` creates the nine review images under `/tmp/mirefen-review`, then exits. It is an automated capture tool; players should launch with F5.

## Remaining work before a polished release

A complete timed human playthrough from a fresh character on Windows, audio listening, keyboard/controller focus review, hardware performance checks and deeper encounter/economy tuning remain outstanding. Automated tests accelerate/position scenes and do not establish play length or certify navigation intuitiveness. All scenes were rendered, but no human Windows playthrough is claimed.

Environment terrain is mostly flat, deep banks use simplified movement bounds, followers can cut corners, NPCs have simple staging and generic dialogue portraits, shops are outdoor stalls, and the water puzzle is a short ordered drain/divert sequence. Further work should add bespoke marsh creatures and Keeper animations, stronger environmental composition, better puzzle depth and transitions. No multi-enemy encounters, swimming, voice acting, Sahir region or Dungeon 3 was added.
