# Companion art refresh

[Preview all six companions beside the approved hero](screenshots/companions/gallery.jpg)

The temporary quest wolf and all six permanent companion IDs now use animated, textured visual adapters in exploration, dungeon, companion selection and battle. **Existing saves retain their companion, bonds, HP, skills and progression; no new adventure is required.** All 24 male/female hero looks and all twelve primary-class choices remain unchanged.

Open `project.godot`, press **F5**, and use **Continue Adventure**. Companion selection/ownership restrictions are unchanged. The current companion updates automatically; new art does not unlock an unchosen permanent bond.

## Designs and actual sources

| Companion | Visual foundation | Motion |
|---|---|---|
| Temporary wolf / Dire Wolf | Quaternius animated wolf, softened/welded authored contours, blue-gray coat, lighter muzzle and amber eyes; temporary wolf is smaller/lighter | Native idle, walk, gallop, attack, reactions and death; pounce for Moonfang Assault |
| Spirit Fox | Quaternius fox with pale/lavender coat and cool eye color | Native quadruped motion; distinct head gestures for healing/renewal |
| Warhorse | Quaternius horse with chestnut coat, dark mane and lighter facial areas | Native walk/gallop, headbutt and kick; real four-legged gait |
| Dragon | Quaternius Dragon Evolved, teal scales, warm wings, ivory horns | Original vendor bind transforms and six embedded hover/fly/attack/hit/death clips; warm fire and cool mana VFX |
| Griffin | **Original derivative**, using the licensed wolf torso/limbs/rig plus new avian head/beak/eyes, neck plumage, feather fans, lion tail and wing bones | Licensed quadruped body animation plus an original keyed wing layer; peck/attack and jumping dive |
| Golem | **Original stone-guardian derivative** of the licensed Quaternius male humanoid base, with new stone face mask, breastplate/hip/limb plates, stone feet and jade insets | Retargeted from the same CC0 humanoid libraries used by the hero: walk/jog, punches, crossed-arm guard, ward gesture, recoil and death |

The griffin and golem are **not downloaded stock Quaternius griffin/golem models**. Their custom parts are project work around professionally authored body/rig foundations. They still warrant further artist refinement. The initial “Goleling” candidate is a winged creature and is **not** shipped or presented as the golem. No QAL Bestiary, restricted RUN asset, unlicensed Sketchfab creature, paid model or copyrighted game extract is included.

Surface treatments are original procedurally painted textures/materials; they are not claimed to be professionally hand-painted texture packs. Shared material roughness, restrained colors, source anatomy and hero-relative scale establish the common visual direction. Golem armor is deliberately faceted stone. There are no imported fur simulations or facial blend-shape systems.

## Integration

- `scripts/companion_actor.gd`: visual-only adapter with native skeleton/player, idle/walk/run/attack/support/guard/hit/death, per-ability clip choices and battle-speed handling. Native animation libraries are duplicated per actor before loop flags change.
- `scripts/companion_visual.gd`: routes the seven playable companion IDs through the new adapter. Static enemy-model loading remains available separately.
- `scripts/battle_motion.gd`: dispatches companion animations, adds themed ability VFX colors, keeps support/ward casting stationary, and plays the new wolf gait during Wild Hunt.
- `scripts/battle.gd`: shows selected companion names and death/victory poses. Combat results remain in `Combat`; animation never calculates damage or changes HP/MP.
- `scripts/character_menu.gd`: companion cameras fit all eight bounding-box corners, including perspective depth, and refit when viewport size changes.
- `tools/build_companion_art.py`: reproducible Blender pipeline; licensed source inputs live under `assets/vendor/quaternius/companions/`, ready-to-use results under `assets/models/companions/refined/`.
- `assets/art_sources/griffin.blend`: editable packed-material griffin source. This directory is ignored by Godot, so **Blender is not required to open or play the game**.
- `assets/models/companions/refined/DERIVATIVES.json` and `docs/validation/companion_asset_inventory.json`: exact runtime model hashes, mesh counts, native rigs and actual embedded clips.

The dragon deliberately retains its original vendor mesh/bind matrices; material changes happen in the adapter. Re-exporting a creature with different armature/bind scaling can collapse otherwise valid animations. New assets must be checked in motion, not merely in their rest pose. The golem has a canonical humanoid import bone map; it does not use quadruped or dragon clips.

Class data, hero appearance data, hero rendering, combat calculations, companion statistics/bonuses/abilities/trees and save code are unchanged. `docs/validation/companion_gameplay_baseline.json` records and tests their pre-change hashes. Passive bonuses remain distinct for all six companions, and Attack/Support/Defend still automates learned abilities with existing cooldowns.

The historical art lab retains its previous generated wolf explicitly as **Legacy Wolf**. Its production-byte audit now lists the approved visual/UI changes as exemptions; it does not silently claim all production files are unchanged.

## Licenses and precise downloads

All third-party foundations are CC0. `assets/vendor/SOURCES.json` records pinned source URLs, exact hashes, author credit, and permission evidence:

- **Quaternius Ultimate Animated Animals**, pinned mirror `Tekh-ops/Ultimate-Animated-Animals-July-2021` at `ac2dbc3fcf82dd915b7fe1a8437efcca1618a311`. The original included pack CC0 notice is retained in `companions/animals/License.txt`. Wolf/Fox/Horse glTF files embed their buffers; no online runtime downloads are needed.
- **Dragon Evolved / Universal Base Characters male**, pinned `Dallolz/moorfall-assets` at `1e83864f55ff8646e929ac9b73faa75df29161de`. The source explicitly declares its model files CC0 and names Quaternius as author. The redistributor README and license are preserved unchanged as `SOURCE-MOORFALL.md` and `LICENSE-MOORFALL.md`; they are identified as redistributor notices, not original Quaternius license documents. The original source README names Ultimate Monsters and Universal Rig/Base Characters. These models are processed redistributions, not claimed to be pristine upstream exports.
- **Guardian animation** reuses the previously verified CC0 UAL Standard libraries already bundled for the player. No new rigging service or animation API is required.

Original feather/head/tail/stone additions and surface-generation code belong to this project; third-party notices remain alongside their foundations. The animal/humanoid authoring inputs are ignored by Godot to keep the runtime import set small. The dragon source is a runtime dependency and remains importable.

Rebuild (Blender 4.3 used here):

```sh
blender --background --factory-startup --python tools/build_companion_art.py
```

For a single derivative, append `-- griffin` or `-- golem`. Preserve the committed `.glb.import` bone map for the guardian, then reimport in Godot. The main game uses GLB results; ordinary players do not run this command.

## Validation and limits

Godot 4.6.3 on Linux, headless plus actual OpenGL Compatibility rendering on a software X11 display. The companion suite checks actual bone changes, valid clips, visible animation scale, normalized/centered roots, textured rendered surfaces, wing motion, behavior/ability dispatch, reactions/death lock, unchanged gameplay files and working menu previews, including full-camera framing.

Commands (use isolated user-data directories because save tests create test heroes):

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . res://tests/companion_art.tscn
godot --headless --path . res://tests/demo.tscn
godot --headless --path . res://art_lab/validate.tscn
```

`tools/companion_capture.tscn` renders hero/companion idle/attack/run views. `tools/companion_game_capture.tscn` captures the actual companion menu, following and battles for all six. These are automated capture tools that cycle and quit; launch the normal game with **F5**.

Known limits: griffin anatomy/feather deformation and stone-guardian plate fit remain custom derivative work, not finished commissioned creatures. The dragon has a small native attack library; fire presentation combines existing body anticipation with themed VFX rather than a newly authored facial/breath rig. There is no riding or player-controlled flight. Enemy art and the rest of the environment are unchanged. Hardware GPU/Windows performance has not been certified. The earlier native material-null diagnostic still appears in some headless stress fixtures; passing assertions are not a claim that every historical test log is free of that diagnostic. Normal rendered companion/game captures are checked separately.

Validation result: 1,613 assertions passed across the existing regression suites and 208 new companion checks. A clean project copy imported successfully without a pre-existing `.godot` cache, and its 208 companion checks passed again. Eighteen studio renders and eighteen actual menu/exploration/battle captures were produced for all six companions. Fresh import and normal rendered capture logs contained no script/runtime errors.
