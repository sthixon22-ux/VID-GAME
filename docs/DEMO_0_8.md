# Demo 0.8.0 — an expanded journey

The exploration view now leaves the town and landscape visible. The old corner panels are replaced by a compact bottom status strip, a contextual prompt, short fading notices and a bottom-right minimap. Escape opens the adventure menu; Tab opens a dedicated travel inventory. Healing potions, MP ether and companion rations can be used outside battle without wasting supplies on a full target.

## Rules and character creation

Each of the six stats combines 60% of the primary class with 20% from each secondary. The same weights apply to base values and per-level growth, with rounding after combination. Creation displays the selected combination at levels 1 and 10 and updates when either secondary changes. Equal secondary weights mean swapping the secondary order preserves stats. All 1,320 ordered distinct class selections remain valid; primary assignment matters. Reassignment controls are removed, and backend class-change calls reject changes for this demo.

Weapons still use all three classes' combined proficiencies. Greatswords, axes, spears, bows, staves, claws, scythes and hammers stow an equipped shield without losing ownership. Equipping a shield is rejected while using these weapons; stats and combat also normalize invalid old pairs. Two-handed bonuses now provide distinct attack, defense, HP, MP, agility or dexterity advantages. One-handed equipment restores shield eligibility.

Every shop slot and supply can be previewed without purchasing or changing the hero. Weapon previews state which class grants access, armor shows compatibility, and two-handed equipment states the shield restriction. The store automatically equips purchases where legal; shields purchased while a two-handed weapon is active remain in inventory.

## Encounters and travel

The outdoor map grows from roughly 62×58 to a bounded footprint of about 105×98 units, with an excluded southeastern section and authored blockers. Willowbrook has its own cottages, services, quest givers and gate. A winding woodland road leads north, crosses Sunstream, continues through Sunmeadow Plains and reaches the relocated shrine. Purple plants and active skyglass objectives appear on the map. Roaming goblins and bristlebacks occupy the road; herb guards remain visible. Reachability checks include all plants, crystals, quest-giver positions and the shrine.

Contact starts combat automatically, including an enemy approaching the hero. The outdoor contact check covers movement segments to reduce missed encounters on long frames. A short grace period on return/cancellation prevents immediate repeated prompts. Ten normal wins for the contacted species offer normal combat or Auto-Battle first. The current-state forecast is deterministic; the displayed percentage estimates outcomes across 24 alternate seeds. Forecasting changes neither resources nor seed. Auto uses the same rules and rewards, records encounter clearing and consumes real resources. Defeat returns the party to camp, with no victory rewards. Auto victories do not grant normal mastery. The Warden remains a normal fight.

Three optional town errands award gold and XP once: four goblins for Rowan, three skyglass clusters for Nessa and both sanctuary Mosslings for Oren. Existing kills/materials count when accepting an errand. Dexterity gold bonuses apply to quest rewards as well as combat.

## Sanctuary puzzles

Clearing each guardian exposes its puzzle. The west chamber has three symbol dials; its inscription gives the left-to-right alignment. The east chamber uses three bells and an inscription describing their order. Wrong notes clear the current bell sequence. Partial positions/notes and solved flags are saved. Solving allows cleansing the corresponding root seal; both seals open the physical boss gate. Existing completed stories remain completed.

## Art and architecture

Original Blender-generated gear includes shaped blades, curved axe heads, recurved bows, carved staves, shield rims/bosses, plate/enamel/leather pieces and accessories. Companions now have sculpted anatomy and distinct manes, horns, wings, feathers, tails or stone forms; enemies also use new authored meshes. The credited KayKit hero rigs retain their skeletal clips with adjusted proportions and additional visible armor/hair. Terrain uses original albedo/normal/roughness maps, foliage uses instanced alpha-cutout branches, and inventory previews use a separate studio world.

`game_rules.gd`, `state.gd` and `combat.gd` govern calculations and equipment rules. `inventory_book.gd` and `quest_book.gd` define supplies and side rewards. `exploration_hud.gd`/`trail_map.gd` handle presentation independently of world interactions. Existing battle event animation remains separated from simulation. Build scripts and asset hashes/provenance are included.

## Save migration

Schema 4 includes consumables, side errands and puzzle state. Schema-three originals receive a `.v3.backup`; previous recovery and future-schema protections remain. Existing characters retain their classes, points, equipment, companions and story. Outdoor saves from the old map return safely to town. Stats recalculate under the combination rule; incompatible shield pairs are stowed. No new adventure is necessary for compatibility, although one is recommended to review the revised opening.

## Validation

Godot 4.6.3:

| Suite | Assertions | Failures |
|---|---:|---:|
| Existing story/combat integration | 67 | 0 |
| Creation-to-ending and postgame | 160 | 0 |
| Class/stat/progression | 308 | 0 |
| Rig/character/action presentation | 63 | 0 |
| Save/camera/settings reliability | 19 | 0 |
| Title layout | 6 | 0 |
| Equipment/shop preview flow | 126 | 0 |
| New adventure systems | 122 | 0 |
| **Total** | **871** | **0** |

The new suite exercises actual contact transitions, both mastered encounter choices, Auto defeat/camp recovery, inventory use, two-handed gear, every shop model, side-quest interactions/reward limits, both puzzle interfaces, partial-state saves and old-map migration. The main quest and echo also pass through real scenes and battle presentation.

Rendered review covers 21 creation, equipment, supply, town, woodland, plains, dungeon, puzzle and companion views. Both 1280×720 and 960×540 layouts were inspected during development; the release pass uses 960×540 with the Compatibility renderer and software OpenGL. The virtual display warns that V-Sync is unsupported. Headless editor import encounters the cloud sandbox's socket restrictions but reports no script/parse errors. Actual runtime suites are checked separately for errors.

These checks use accelerated combat and teleports. They do not establish human completion time, Windows performance or audio quality. Art remains procedural/stylized; companions use segmented motion, armor may clip, terrain is mostly flat and followers can cut corners. A production visual/animation pass, timed human playtests, accessibility/controller work and deeper balancing remain necessary before calling the game a final commercial release.
