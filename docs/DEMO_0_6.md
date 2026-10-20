# Demo 0.6 — the complete opening loop

This release expands the existing introductory quest into a representative game loop. It is a **release candidate**, not a claim that the final art quality, Windows performance or 15–20-minute first-player pacing has been established. Automated scene traversal uses accelerated playback and teleports; it cannot measure that target. The main story is unchanged.

## New-player route

1. Choose **New adventure**. Name the hero, choose Paladin/Ranger/Druid primary plus two distinct secondary slots and select skin, hair and travel-clothes colors. The remaining two demo classes are explicitly shown as secondaries. Characters arrive without owned or equipped gear; clothing has no armor stats.
2. Visit the clearly marked outfitter east of camp. Spend the 120-gold starting allowance on a sword, shield and chest piece. Purchases immediately equip and remain owned. Paladin plate requires Paladin primary. Starter purchases total 75/85/95 gold for leather/robe/plate kits. An equipment-money reserve prevents spending the opening budget into an unrecoverable state; potions cost 8 after equipping the kit.
3. Speak to Mira, inspect class/weapon trees and follow the northern trail. Each Moonleaf site has a visible guard. Defeat it normally, then gather its plant. Three wins introduce XP, class mastery, weapon mastery, gold, drops and point investment before the dungeon.
4. Return the Moonleaf to Mira, enter the shrine, clear the two Mossling guardians and cleanse both seals. The cache supplies potions and fully restores the party. Read the Warden's charge and Defend its heavy attack.
5. Bring the living ember to Mira. The ending opens permanent companion selection: Dire Wolf, Griffin, Dragon, Warhorse, Spirit Fox or Golem. Preview, confirm the permanent choice, and reach the adventure-complete screen. The introductory wolf is a loan and does not consume a selection.
6. Optional postgame: train the chosen companion, upgrade purchased equipment, continue goblin mastery and challenge the Warden echo from the village board. Echo victory unlocks one additional permanent companion from the remaining five. At most two can be owned, and only one is active. This small postgame sample represents the intended full-game rule rather than opening all six to a single character.

## Implemented systems

| Element | Demo implementation |
|---|---|
| Creation/classes | Name and three visual color choices; primary choice among the three implemented classes; distinct two-class secondary configuration; primary stat bonuses; camp-only switching with retained unlocks |
| Equipment economy | Stable inventory item IDs, per-item prices/rarity/descriptions, ownership checks, starter reserve, three starter armor identities, eight independent slots, stat comparisons, live 3D wardrobe preview and safe unequipping of incompatible plate |
| Hero progression | Hero XP/levels/points, independent class-mastery victories, separate sword/shield mastery and learnable weapon bonuses; eligible learned primary mythics only |
| Ability data | Stable ability IDs/display-name aliases, costs, class spellbooks, descriptions and weapon/shield requirements in data; seeded chance rolls shared by normal/Auto combat |
| Statuses | Three-round regeneration after the casting round, three-round marks, 75% one-turn roots, 45% one-turn stun (upgradable), guard, bleed; event-state status feedback in battle |
| Class chemistry | Data-defined Guardian of the Wild: shield block primes the next Ranger mark or Druid restoration, +10 once, expiry after three rounds; no blanket class-damage multiplier |
| Companions | Six data-defined selections and distinct original models; permanent first/second ownership, one active; initiative/power/HP/support differences, three automated behaviors, three learnable bond branches, XP/levels/points, persistent HP and class affinity |
| Companion identities | Wolf bleed; Griffin wind strike and 15% evasion when targeted; Dragon breath; Warhorse charge/support; Fox support/renewal; Golem armor/disrupting earth strike. These are simplified demo actions, not full final skill libraries |
| Travel | Equal +25% movement blessing for any permanent companion. Mounting, flight and bespoke riding animation are not implemented |
| Exploration/quest | Existing village/forest/shrine/dungeon story, outfitter, board, visible site guards, gathering, camp recovery, journal checklist, optional postgame fight |
| Mastery/Auto | Species normal-win records; ten normal goblin victories unlock risk preview and explicit resolution, same deterministic simulator, resource changes, defeat, normal XP/gold/drop roll and short results. Story guardians/bosses are excluded |
| Presentation | Existing action-specific hero skeletal clips/effects and speed/reduced-motion settings; new palette shader, creation and companion previews, distinct companion shapes and attack effects |
| Persistence | Schema 2 adds new profile/economy/progression/bond data. Older saves retain progress, story, skills, equipped gear and their legacy wardrobe/balance behavior; missing fields receive defaults. Versioned original/previous backups and nested shape checks protect loading |

## Deliberate demo rules

- The playable set is Paladin/Ranger/Druid, not twelve finished classes. Their order/primary changes; the other two occupy the secondary slots. Adding classes requires definitions and actual effects/art, not empty roster entries.
- Hero points remain three per level for this short demo. Class mastery counts victories separately from hero XP; the demo mythic gate is three class victories plus the existing prerequisite branches and point cost. These compressed thresholds demonstrate the systems without pretending that final-game level 75 has been reached.
- Each weapon has two learnable nodes, each companion three branches with one first-tier node. Larger libraries remain future content. Every selected companion is functional in this slice.
- No crafting, armor sets, selling, respec economy, mixed-species battles or twelve-class endgame rules were invented; those were unresolved in the master overview. Equipment ownership, shopping and consumable use form the implemented economy.
- Existing name-based class/equipped-gear keys are preserved as migration aliases; new inventory/ability/companion/weapon-node identifiers use stable IDs. A full legacy-key migration remains separate work.
- A second permanent choice follows the optional postgame echo. That encounter reuses the Warden arena and attack pattern; it is not a new story chapter or a claim to complete full-game postgame content.

## Changed files

New: `scenes/create.tscn`; `scripts/character_create.gd`, `ability_book.gd`, `companion_visual.gd`, `auto_battle_panel.gd`; `data/abilities.json`, `chemistry.json`, `companions.json`, `weapon_trees.json`; `assets/shaders/hero_palette.gdshader`; `tests/demo.gd`/`.tscn`; this report.

Integrated: `state.gd`/`save_store.gd`, `title.gd`, `character_menu.gd`, `world.gd`/`forest.gd`/`dungeon.gd`, `combat.gd`/`battle.gd`/`battle_motion.gd`, `hero_visual.gd`/`art.gd`, class/equipment data, tests/capture runner and README/roadmap. Existing quest dialogue and scenes remain in place. All added art is original geometry/palette work using the existing CC0 character assets; no paid or copyrighted game assets were introduced.

## Validation and remaining release work

Godot 4.6.3 validation completed **298 passing checks**: 61 legacy full-game, 61 presentation, 19 reliability and 157 new demo checks, with no runtime/script errors. All suites use isolated user-data directories. The new suite covers all three starts, affordable/owned equipment, reserve protection, ability equipment requirements, statuses and chemistry, mastery/weapon eligibility, save reloads, all six companion models/behaviors and selection limits, actual creation-to-shop-to-ending scene flow, first bond, real optional echo battle and second-bond persistence. A software OpenGL/Xvfb run captured 19 screens covering the new pages and battle flow, with no runtime errors. Creation, shop, weapon training, companion confirmation, Auto-Battle and boss views were inspected visually; shop overflow, preview framing and confirmation placement were corrected. Screenshots support rendered functionality, not final artistic quality.

Before a public final release, a person still needs to play this build on Windows without test shortcuts, time the first experience, listen to audio and evaluate readability, difficulty and controller needs. Remaining art quality varies: creatures are procedural, companion animation is simpler than the hero's, armor overlays are basic, terrain is flat, mounted/flight traversal is absent, and the UI targets 1280×720 desktop. This is substantially more complete system coverage, not finished production art or a measured duration guarantee.
