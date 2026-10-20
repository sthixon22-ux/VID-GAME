# Verdant Oath — The Bell Beneath the Woods

**Demo 0.6 · Godot 4.6+ · GDScript · CC0 assets + original art/story/effects**

A short 3D turn-based fantasy adventure built around the Project Mythic overview: create a hero, choose classes, buy your first equipment, help Willowbrook, cleanse the sanctuary and choose a permanent companion. **15–20 minutes is the intended first-play target, not a measured guarantee.** This is a playable release candidate; production art and human playtesting remain unfinished.

## Download and launch

1. Download this repository using **Code → Download ZIP** and extract it into a **new folder**.
2. Open Godot 4.6 or newer. Click **Import**, choose the extracted `project.godot`, then **Import & Edit**.
3. Wait for assets to import and press **F6** only for an individual scene, or **F5** to run the whole game from its title screen.
4. Choose **New adventure** to experience the new creation/shop progression. Your old save is backed up before a new adventure starts. **Continue adventure** preserves an existing character and its old progress/balance; it does not strip equipment to recreate the new opening.

The internal application name remains unchanged so Godot finds the existing user-data directory. No paid assets, online accounts, external services or plugins are required. This is a desktop Godot project, not a browser build.

## Controls

| Input | Action |
|---|---|
| WASD | Move |
| Shift | Sprint; permanent companions also grant equal +25% travel speed |
| Hold right mouse + move | Orbit camera |
| E | Interact, gather, challenge visible enemies, enter/leave sanctuary |
| Q | Auto-Battle for a nearby mastered goblin; opens risk preview first |
| I | Owned equipment and live appearance preview |
| K | Separate class skill-tree page |
| C | Companion selection, behavior and training |
| J | Quest journal, field guide and potion inventory |
| Escape | Adventure menu / return from character page / close modal |
| R | Rest at the village camp: restore hero HP/MP and companion HP |
| F5 / F9 in forest | Save / load; Godot editor F5 starts the project |
| E / Space / Enter | Advance dialogue |
| Mouse / Tab + Enter | Menu controls; scroll long lists |

Settings are available from the title, exploration menu and idle battle screen: battle speed, minimal animations, reduced battle camera movement, camera sensitivity, music/effect volumes and mute. Settings persist separately from your character.

## Your first adventure

- **Create your hero before entering the world.** Enter a name, choose a primary class plus two distinct secondaries, and select skin, hair and travel-clothes colors. Paladin, Ranger and Druid are the three implemented demo classes. Each offers a different primary stat specialization; all three contribute starting abilities. Only a learned primary-class mythic can be used.
- **Start unequipped.** Travel clothes provide no armor stats. You have 120 gold and three potions. Visit the marked **OUTFITTER east of camp** and buy/equip an Iron Sword (30), Oak Shield (20) and chest piece: Leather Vest (25), Verdant Robe (35) or Paladin-only Steel Cuirass (45). Purchases remain owned; equipment changes are free. Essential starter funds are reserved to prevent a shopping dead end.
- **Speak to Mira beside camp.** Follow the northern trail to the three purple Moonleaf plants, defeat each visible guard, then interact again to gather. Check the journal and spend skill points in the class/weapon pages. Normal victories grant XP, gold, drop rolls and separate class/weapon mastery.
- **Return the plants to Mira.** Cross the eastern bridge, enter the shrine and explore both sanctuary side chambers. Defeat each Mossling, then cleanse its root seal. The pilgrim's cache supplies potions and restores the party.
- **Face the Hollow Warden.** When branches coil, choose **Defend** against the next charged blow. Restore the guardian, then return the living ember to Mira.
- **Choose your permanent companion.** Preview and confirm Dire Wolf, Griffin, Dragon, Warhorse, Spirit Fox or Golem. The temporary quest wolf is a loan and does not consume your selection. This reaches the adventure-complete screen.
- **Optional postgame sample:** train your companion, upgrade equipment, master goblins and challenge the Warden echo from the village board south of camp. Echo victory unlocks your second and final permanent companion. Only one accompanies you at a time; the other four remain unchosen.

## Systems represented in the demo

- Eight independently equipped, owned slots with stat changes, class compatibility and visible weapon/shield/chest changes plus simple modular armor details.
- Hero XP/levels/skill points, distinct class mastery, class skill trees, separate sword/shield mastery and learnable weapon techniques. Primary switching is available near the village camp and retains learned skills; incompatible plate is unequipped rather than deleted.
- MP spells in a submenu; data-defined stable ability IDs/aliases, class spellbooks and equipment requirements. Attack, Weapon Skills, Spells, Items, Defend and Companion commands remain fully turn based with deterministic speed order.
- Regrowth heals now and over the following three rounds. Shield Bash can stun; Thornbind can root. Mark, guard, bleed and status feedback support tactical choices.
- **Guardian of the Wild** class chemistry: a successful shield block primes one stronger Hunter's Mark or Regrowth, with a three-round expiry. Mythics remain primary-only.
- Six companions with distinct original models, initiative/power/HP/support, three automated behaviors, three first-tier training branches, XP/levels/points, persistent HP and small class affinities. Equal travel boost works for every choice.
- Per-species normal-win tracking; **10 normal goblin victories** unlock optional Auto-Battle. The risk preview does not spend resources. Resolution uses the same simulator, consumes resources, can lose, grants normal rewards on victory and shows a result summary. Story guardians and bosses are excluded. Auto wins do not advance normal mastery.
- Existing beginning-to-ending quest/dialogue, companion selection endpoint, shop, field board, guarded gathering sites, cache, journal/field guide, camp recovery and optional postgame challenge.
- Skeletal hero animation, action-specific effects, damage numbers, event-state bars/status feedback, cinematic battle shots and victory/defeat presentation with pacing controls.

The [0.6 implementation report](docs/DEMO_0_6.md) lists changed files, demo-specific rules, validation and remaining work. The [master overview](docs/design/PROJECT_MYTHIC_V1.md), [technical audit](docs/PROJECT_MYTHIC_AUDIT.md) and [roadmap](ROADMAP.md) distinguish the full-game direction from what is implemented here.

## Save compatibility

One character slot lives at `user://hero.json`. Schema 2 stores profile, inventory, classes/skills/masteries, equipment, HP/MP, companion ownership/training/HP, quest state/position, monster wins and gold. Saves use a validated temporary write and `.previous` recovery copy. Earlier schema originals are copied to `.v0.backup` or `.v1.backup`; explicit New adventure creates `hero.backup.json`. Newer incompatible or unreadable unrecoverable saves are preserved and blocked from silent overwrite. Recovery may lose the latest progress and cannot reconstruct two damaged copies.

Older characters keep the previous wardrobe and combat balance rules; use **New adventure** to test the new economy, statuses and creation flow. New inventory/ability/companion identifiers are stable IDs. Existing class/equipped-gear display-name keys remain supported migration aliases.

## Development and validation

```bash
# Import/validate resources first.
godot --headless --path . --editor --import --quit

# These suites create/replace saves. Always isolate their user-data directories.
XDG_DATA_HOME=/tmp/verdant-game godot --headless --path . res://tests/run.tscn
XDG_DATA_HOME=/tmp/verdant-presentation godot --headless --path . res://tests/presentation.tscn
XDG_DATA_HOME=/tmp/verdant-reliability godot --headless --path . res://tests/reliability.tscn
XDG_DATA_HOME=/tmp/verdant-demo godot --headless --path . res://tests/demo.tscn
```

**298 automated checks pass in Godot 4.6.3** (61 full-game + 61 presentation + 19 reliability + 157 demo), with no runtime/script errors. Validation includes legacy full-story flow, character/presentation integration, camera/movement/save reliability and the new creation-to-postgame suite. Tests check all three class starts, shopping/ownership/reserve safety, equipment legality, timed effects, chemistry, mastery gates, all six companion models/behaviors, permanent-choice limits, actual new-playthrough scene transitions, the Warden echo and saved second-bond state. Tests accelerate time and use scene teleports; they do not establish a 15–20-minute playtime or final visual quality.

```bash
# Requires a display; use a separate data directory for captures too.
XDG_DATA_HOME=/tmp/verdant-capture godot --path . --rendering-method gl_compatibility --audio-driver Dummy res://tools/capture.tscn -- /tmp/verdant-captures
```

The capture runner visits title/settings, creation, unequipped exploration, shop, gear/trees/weapons/journal, dungeon/boss/spell, companion selection/training, following and Auto-Battle previews/results. Software OpenGL rendering is checked separately from headless tests. Dummy/headless audio cannot validate actual listening quality.

Core separation: `combat.gd` contains deterministic rules; `ability_book.gd`/`data/` define abilities/classes/items/bonds/chemistry; `battle.gd`/`battle_motion.gd`/`hero_visual.gd` present events; `state.gd` applies progression/economy and `save_store.gd` handles storage. World/dungeon retain quest-specific interactions. Asset provenance and licenses are in [assets/README.md](assets/README.md).

## Known limits before a final public release

The game needs a timed Windows playtest without developer shortcuts, audio listening, difficulty/pacing feedback and accessibility/controller review. Art quality is mixed: the hero/Mira use CC0 KayKit rigs and cottages use Quaternius textures/models, while creatures and companion animation remain simpler original geometry; overlays are basic, terrain is flat, following can cut corners and camera blockers approximate meshes. Character creation changes name/colors, not body shape or facial features. Portraits do not dynamically match appearance.

The demo implements three classes, six functional companion choices, compact training trees, one quest/dungeon/boss and a reused boss echo. It does not implement all twelve classes, crafting, selling, armor sets, multi-enemy battles, mounted/flight traversal, voice acting or full-game postgame content. Every permanent companion currently receives an equal movement blessing rather than a ride animation. The UI targets a 1280×720 desktop layout. These limits prevent calling this a finished production release despite the expanded playable systems.
