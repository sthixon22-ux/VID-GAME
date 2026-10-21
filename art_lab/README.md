# Verdant Oath — Art Development Lab

This is a review environment, **not a production art replacement**. All gameplay scripts, scenes, models and data remain byte-for-byte unchanged. All twelve classes and free primary/two-secondary creation remain available.

1. Import the repository's `project.godot` in **Godot 4.6+** and allow the new assets/plugins to import.
2. Open **`art_lab/comparison.tscn`** in the FileSystem dock.
3. Press **F6 — Run Current Scene**. F5 still launches the normal game.

Or run `godot --path . res://art_lab/comparison.tscn` after editor import. No downloads or account are needed to use the bundled comparison.

[Face comparison screenshot](reports/screenshots/faces.png) · [Full-body screenshot](reports/screenshots/characters.png)

[Full audit, sources, recommendation and production plan](reports/VISUAL_AUDIT.md) · [Every inspected model's inventory](reports/asset_inventory.json) · [Pinned sources, permissions and SHA-256 hashes](SOURCES.json)

## Review controls

- Compare the current hero, Quaternius Universal Base/Fantasy Standard derivative, and an official anime VRM sample with equal normalized body height, lighting, camera focal length and viewport size.
- Play **Idle, Walking, Running, Sword attack, Blocking and Spellcasting**. Labels identify the actual native or retargeted clip. Pause/Play, Restart, speed and turntable controls support inspection. Space toggles pause.
- Change Front / Three-quarter / Side / Back / Face detail. Face detail centers on each head landmark while retaining the same focal length and distance.
- Swap the Quaternius Ranger and Peasant outfits, or independently toggle the authored hood and pauldrons. These are cosmetic examples, not class restrictions.
- Switch between **Seed-san (VirtualCast, Inc.)** and **VRM1_Constraint_Twist_Sample (pixiv Inc.)**. Test neutral, happy, angry, sad, surprised, blink and vowel expressions. The Twist sample exposes known constraint-retargeting artifacts; it is retained as a diagnostic reference.
- Seed-san's unrelated robot-arm accessory is hidden by default for the body comparison; a button exposes the original accessory. Both VRM samples have reference/sample clothing rather than a finished original fantasy wardrobe.
- Toggle the sword/shield attachment test. These are **existing project placeholder props**, shared by both candidates so grip behavior can be compared fairly. They are not new production equipment. Grip offsets and clipping remain unfinished.
- Wolf comparison shows the current segmented wolf beside a licensed, natively animated Quaternius wolf. Human actions unsupported by that rig are marked unavailable.
- Goblin audit shows the current goblin and an explicitly empty replacement panel. No model is falsely relabeled as a goblin. Bestiary's actual reviewed license conflicts with blanket CC0 claims on another mirror and restricts standalone asset redistribution; no Bestiary asset is bundled.

## Licensing and attribution

- **Seed-san model by VirtualCast, Inc.**, official VRM sample, **VRM Public License 1.0**; credit required. Its embedded permissions allow corporate commercial use, modification and redistribution. Metadata and full license document are included under `assets/vrm/`.
- **VRM1_Constraint_Twist_Sample**, **(c) 2022 pixiv Inc.**, official VRM sample, VRM Public License 1.0; its per-model metadata allows commercial use, modification and redistribution. This is not a claim that arbitrary VRM downloads have the same permissions.
- Quaternius review characters/outfits, pinned free Standard animation libraries and the 2021 animated wolf are credited **CC0** assets. Character GLBs are third-party assembled derivatives of the named free Standard packs, with their source attribution retained; they are not represented as pristine exports. See the exact file/source/license records in `SOURCES.json`.
- The VRM importer and MToon shaders are **MIT**, with licenses retained under `addons/`. A small Godot 4.6 import guard patch is documented at `addons/VERDANT_PATCHES.md`.

## Validation and reproducibility

```bash
godot --headless --path . --editor --import --quit
XDG_DATA_HOME=/tmp/verdant-art-lab-test godot --headless --path . res://art_lab/validate.tscn
```

Do not run tests against personal game save directories. The lab validation verifies real animation tracks, moving bones, hand sockets, expression morph weights, outfit parts, all twelve class definitions and unchanged production hashes. It also asserts the lab does not alter the loaded hero state.

With a display:

```bash
XDG_DATA_HOME=/tmp/verdant-art-lab-capture godot --path . --resolution 1440x900 --rendering-method gl_compatibility --audio-driver Dummy res://art_lab/capture.tscn -- /tmp/verdant-art-review
```

`prepare_retarget.gd` regenerates humanoid bone-map settings on lab imports only. Run it with `godot --headless --path . --script art_lab/prepare_retarget.gd`, then reimport in the editor. The authored `.import` settings are already included, so this is not required for normal use. `fetch_assets.py` verifies bundled hashes and can restore missing licensed downloads from their pinned public sources; it never fetches Bestiary or paid asset editions.

The lab uses the project's existing read-only visual factories for its baseline and reference gear. It adds import plugins in `project.godot` but does not change the production main scene, autoloads, input or save schema. Production replacement should begin only after review of these results.
