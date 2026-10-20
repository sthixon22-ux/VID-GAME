# Verdant Oath — Fantasy RPG Prototype 0.1

An original, small 3D fantasy RPG made with Godot 4 and GDScript. All art is generated from colored primitive meshes; no external assets, services, or plugins are required.

## Launch

Open `project.godot` in Godot 4.6 or newer and press **F6** on `scenes/world.tscn`, or **F5** to run the project. Godot 4.6.3 was used for validation.

```sh
godot --path . --editor
godot --path .
```

In this cloud sandbox the default home directory is read-only. Use writable XDG directories:

```sh
mkdir -p /workspace/.runtime/{data,config,cache}
XDG_DATA_HOME=/workspace/.runtime/data XDG_CONFIG_HOME=/workspace/.runtime/config XDG_CACHE_HOME=/workspace/.runtime/cache godot --path /workspace/VID-GAME
```

This task already has an isolated checkout. Use the existing checkout; no additional Git worktree is needed.

## Controls and play loop

- **WASD:** move relative to the orbit camera.
- **Hold right mouse and move:** orbit camera. Mouse remains available for menus.
- **E:** start normal combat within three meters of a visible goblin.
- **Q:** Auto-Battle a nearby goblin after ten normal victories.
- **I:** scrollable equipment and class-tree menu. Gear changes are free prototype toggles.
- **R:** restore HP and MP within three meters of the starting clearing.
- **F5 / F9:** save / load. Actions, management changes, and completed battles also save automatically.

Approach the goblin directly ahead, press E, and select actions with the mouse. Every action resolves a full speed-ordered round; the wolf acts automatically. Companion opens a behavior menu without spending the hero's turn. Spells have a separate submenu, display their MP cost, and are disabled when unaffordable. Return to camp after defeat to recover. Goblins remain available for repeat encounters.

## Implemented systems

- Primary Paladin with Ranger and Druid secondary classes, visible sword, shield, chest armor, HP, MP, XP, gold, leveling, three skill points per level, and independent class investment tracks.
- Each data-defined class has a three-node linear tree. Each point advances one node; Paladin and Ranger ranks add attack, Druid ranks add maximum MP. Rank three also unlocks that class's mythic. Investments survive class changes, but only the primary class's mythic appears and is legal in combat.
- Sword Slash, Shield Bash (damage and defense), Sacred Strike, Hunter's Mark (extra damage), Thornbind (skips enemy turns), Regrowth (healing), three mythics, potions, and Defend.
- Speed-ordered, fully turn-based rounds with deterministic seeded enemy choices. No real-time combat timer. Attack lunges, floating numbers, camera pulses, and a victory/reward panel.
- Wolf Attack, Support (healing), and Defend (protect hero) behaviors. Wolf is incapacitated for the current battle at zero HP and recovers for the next encounter. Save schema reserves six roster entries and a separate postgame slot; only Wolf is implemented.
- Eight independent equipment slots. Every slot affects attack or defense; sword, shield, and chest changes are visible immediately. Paladin/Ranger/Druid investment also affects stats.
- Ten **normal** Forest Goblin victories unlock species Auto-Battle. Auto uses the same simulator without instantiating the battle scene. Its policy casts Regrowth below half health, otherwise Sacred Strike when affordable, otherwise Attack. It uses current gear, level, MP, HP, wolf behavior and seeded randomness. Defeat remains possible. Wins award 35 XP, 18 gold, and a deterministic seeded 1-in-3 potion drop in both modes. Auto wins do not increase the normal-win count.
- Version 0.1 single-slot JSON persistence at `user://hero.json`, including class configuration, investments, equipment, companion state, mastery, consumables, gold, and random seed. Saved files are local to the OS user-data directory.

## Structure and extension

- `data/classes.json`: class names, starting skills, tree nodes, and mythic identities.
- `scripts/state.gd`: persistent state, derived equipment stats, leveling and rewards.
- `scripts/combat.gd`: presentation-independent round simulator used by both modes.
- `scripts/world.gd` and `scenes/world.tscn`: forest, encounters and management.
- `scripts/battle.gd` and `scenes/battle.tscn`: animation, combat menus and victory UI.
- `scripts/art.gd`, `scripts/ui.gd`: shared procedural models and UI helpers.

Adding a class definition creates its management track and primary-class option. New effects also require handlers in the simulator and a derived-stat rule where appropriate. Additional companions need roster data, a model, a selector, and a behavior implementation; placeholder slots are intentionally not selectable.

## Validation

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 90
# Use a separate data directory so tests cannot overwrite your personal save:
XDG_DATA_HOME=/tmp/verdant-oath-tests godot --headless --path . res://tests/run.tscn
```

The integration runner checks seeded Auto/normal parity, MP use, possible defeat, secondary mythic gating, primary activation, gear stats, mastery, leveling, save round trip, forest startup, Auto-Battle gating/resolution, and animated battle completion/rewards. It exits nonzero on failure. Headless checks validate runtime execution, not the subjective visual experience.

## Known limitations

One forest, one enemy species, one implemented companion, primitive art, no sound, no inventory shop, no obstacle collision or navigation, and no quests. Trees are scenery; the clearing has hard movement boundaries. Equipment is a free development selector rather than loot inventory. Class trees are linear with three ranks and all six starting abilities are initially available. Wolf HP is per encounter; only selection/behavior/active state is persistent. Goblins respawn immediately; no encounter cooldown. Save migration and recovery from manually corrupted saves are outside this prototype. The menus target a 1280×720 desktop window. Mouse/UI visual playtesting is still recommended.
