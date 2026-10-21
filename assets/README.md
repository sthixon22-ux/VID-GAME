# Asset provenance

Verdant Oath combines original work with free CC0 asset packs. All required files are included for offline play; no asset-store account, purchase or external API is required.

## KayKit Adventurers Character Pack — Kay Lousberg

- Official pack: https://kaylousberg.itch.io/kaykit-adventurers
- Official source: https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0
- Source commit: `672074b73ba276876a19e8816ecdc5241817ab47`
- License: **CC0-1.0**, bundled at `vendor/kaykit/LICENSE.txt`.
- Included: Knight, Rogue and Mage GLBs, their embedded painted texture atlases, 75 skeletal animation clips per model and embedded weapon/shield/helmet geometry.
- Used for the hero's plate/leather/robe appearances, the village NPC, walking/running, battle poses, action clips, hit reactions and victory/defeat animations.
- The animation clips are pack assets. Verdant Oath adds per-action selection, timing, effects, camera work and rig-attached equipment. Additional gloves, greaves, boots, accessories and hood geometry are original prototype attachments.

## Medieval Village MegaKit — Quaternius

- Official free pack: https://quaternius.itch.io/medieval-village-megakit
- glTF distribution mirror: https://github.com/J-Ponzo/gltf-medieval-village-megakit
- Source commit: `21104b4045261c28fc312360841ed1a7b0ac8782`
- License: **CC0-1.0**, full legal text at `vendor/quaternius_village/LICENSE`.
- Included: a selected subset of walls, doors, windows/shutters, roof, chimney, crate, vine, fence and stone-floor components, with their referenced buffers and textures.
- Used for the cottage assemblies and painted brick, plaster, roof-tile and wood surface textures with normal/roughness maps. The wood trim atlas is sampled only in its grain region when applied to original procedural geometry.
- This is the free standard distribution. Paid PRO/SOURCE assets have not been used.

`vendor/SOURCES.json` records the bundled source file hashes and source commits. Godot also extracts the embedded KayKit atlas images alongside their GLBs during import. Pack models and source texture images are unmodified; runtime placement, material sampling, equipment attachment and animation selection are project code.

## Original project assets

- `textures/`: original deterministic fallback/grass/fabric textures.
- `portraits/`: original vector portrait illustrations.
- `audio/`: original synthesized music themes and cues (22,050 Hz mono PCM).
- `shaders/`: original water-ripple and foliage-wind shaders.
- Procedural wolf, goblin, Mossling, Warden, foliage and battle effects are project geometry/code.

Run `python tools/generate_assets.py` to regenerate the original textures, portraits and audio (Pillow and numpy required). This does not download or replace the CC0 vendor packs. Godot requires only the checked-in assets. Music remains a synthesized demo score, and there is no voice acting.


Demo 0.6 adds original procedural companion variants (Dire Wolf, Griffin, Dragon, Warhorse, Spirit Fox and Golem) in `scripts/companion_visual.gd` and a custom hero palette shader in `assets/shaders/hero_palette.gdshader`. These use original geometry or the existing original wolf geometry and retain the existing CC0 KayKit character textures for hero customization. No additional third-party assets or paid textures are required.

Demo 0.7 adds original procedural weapon geometry in `scripts/gear_visual.gd` for axes, polearms, bows, daggers, staves, wands, claws and heavy weapons. These reuse no third-party game meshes; they use the existing shared CC0 hero rig/animations and remain placeholder art.

## Demo 0.8 original art pass

`models/gear/` contains original designed weapon, shield, armor and accessory meshes with metal/leather/enamel materials. `models/companions/` contains sculpted bodies, articulated limb groups and distinct horns, wings, manes, feathers or tails for all six companions, the temporary wolf and meadow bristlebacks. `models/enemies/` contains the original goblin, mossling and guardian. `textures/rpg/` supplies original albedo, normal and roughness maps plus cutout leaf branches. These are project art created for this demo, with no external service or paid content.

`models/heroes/` contains proportion-adjusted derivatives of the credited CC0 KayKit Knight, Rogue and Mage, retaining their skeletal clips. They still use the credited source palette textures. Rebuild meshes with `blender --background --factory-startup --python tools/build_rpg_art.py`. Rebuild surface maps with `python3 tools/build_surface_textures.py` (Pillow and NumPy). Blender/Python are development tools; opening or playing the shipped project only requires Godot. Hashes and source distinctions are recorded in `vendor/SOURCES.json`.

## Demo 0.9 natural-proportion hero replacement

The active hero meshes in `models/heroes/` now replace the KayKit body geometry with clothed human topology derived from MakeHuman’s CC0 base mesh. The face and hands use anatomical surfaces; fitted clothed torso/legs/boots use its helper topology. Original eye/hair assembly, skinning and retargeting are implemented in `tools/build_natural_hero.py`. KayKit’s credited skeleton and animation clips remain. The original vendor assets remain unmodified for reproducibility.

- Source: https://github.com/makehumancommunity/makehuman/blob/master/makehuman/data/3dobjs/base.obj
- MakeHuman base-mesh header explicitly declares CC0 release in September 2020; copyright holders: Data Collection AB, Joel Palmius and Jonas Hauquier.
- Vendored source: `vendor/makehuman/base.obj.txt`; full CC0 legal text: `vendor/makehuman/LICENSE-CC0.txt`. Source and derivative SHA-256 hashes are recorded in `vendor/SOURCES.json`.
- Rebuild the active hero meshes with `blender --background --factory-startup --python tools/build_natural_hero.py`. If rebuilding every original art asset, run this **after** `build_rpg_art.py`, which produces the older hero variants. No source geometry download or Blender installation is needed to play.

The 0.8 hero description above documents the previous release; these new hero GLBs supersede its proportions and palette material. Companions and enemies remain the 0.8 original meshes with simpler segmented motion.

## Art-development review assets (not production replacements)

The optional comparison scene in `art_lab/` vendors separately licensed Quaternius Standard derivatives/animations, a 2021 CC0 animated wolf, two official VRM sample avatars, and the MIT Godot VRM/MToon addon. See [the complete pinned source and permission manifest](../art_lab/SOURCES.json), [required attribution and controls](../art_lab/README.md) and [audit](../art_lab/reports/VISUAL_AUDIT.md). These models are not used by production hero, enemy or companion factories. Seed-san requires credit to VirtualCast, Inc.; VRM content is not blanket CC0. Bestiary models were excluded after inspecting their QAL license rather than accepting a mirror's general CC0 claim.
