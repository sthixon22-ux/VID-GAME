# Approved Quaternius hero integration

The player selected Pipeline A's hooded Quaternius ranger in the comparison and approved integrating it. The production `HeroVisual` adapter now uses the authored Quaternius humanoid in character creation, equipment previews, exploration, dungeon and turn-based battle. F5 launches the normal game; `art_lab/comparison.tscn` + F6 still compares the previous hero, Quaternius and VRM. Its old-hero card uses an archived adapter, not the new production model.

## Architecture and content

- `scripts/hero_visual.gd`: visual-only adapter with the previous public API (`motion`, `play_action`, `play_reaction`, skeleton/player/guarding fields). No new save fields or changes to combat calculations.
- `scripts/hero_motion_library.gd`: cached, retargeted CC0 animation libraries, canonical humanoid bone paths, per-rig hip translation scaling, no root-motion displacement. Gameplay still controls character movement and battle lunges.
- `assets/vendor/quaternius/characters`: licensed ranger and peasant derivatives, with original embedded materials/textures. Traveler clothing/unequipped use the peasant; other chest equipment uses the ranger. Hair, skin and clothing color selections remain supported.
- The authored skinned ranger hood responds to the Ranger Hood equipment slot. Sword and shield follow RightHand/LeftHand bone attachments; two-handed families suppress the shield. Static legacy helmet/accessory/limb equipment remains transitional. Chest equipment changes the skinned outfit/material treatment instead of putting a rigid generated shell over its shoulders.
- All 12 classes retain the same character visuals independently of their primary/secondary roles. The selected appearance is a single female-bodied character family, not 12 new models or a new gender selector.
- Companion/enemy art has not been replaced in this pass. The existing Mira construction also uses HeroVisual, so it receives the same rig update; no dialogue/quest behavior changes.

## Animation map

Idle/Walk/Sprint, sword battle idle, shield idle; Sword_Attack for basic sword attack; Sword_Regular_A/B/C and combo for sword skills; Shield_OneShot for bash; Sword_Block for defend; Spell_Simple_Enter/Idle/Shoot for spells; Consume for items; Hit_Chest and shield-break reactions; Roll for dodge; Death01 and Yes for defeat/victory. Starting skills have distinct source clips; existing per-ability VFX remain in BattleMotion. Other class/weapon abilities use appropriate generic spell/melee fallbacks.

These are authored library motions, not bespoke animations for every skill in the full game. The free libraries do not provide a suitable bow draw/release or every two-handed weapon stance: bow attacks currently use a generic upper-body action, and staff attacks use spellcasting. Shield may remain visibly equipped during generic two-arm spell clips. Dedicated bow/staff, shield-aware spell variants, grip calibration per weapon, animation transitions and matched hit timing require a further animation pass.

## License provenance

Production copies are byte-identical to the verified comparison sources. `assets/vendor/SOURCES.json` records the exact URLs, pinned commits, SHA-256 hashes and source attribution. Included notices:

- Character derivatives: Quaternius Universal Base Characters Standard and Modular Character Outfits Fantasy Standard, CC0; assembled by ibra-kdbra/Generate_infinite, pinned `027491fa5d30788d26fc707bddf6c8cdb48ad1f4`. Original Standard pack license and source README are retained alongside the models.
- UAL1 Standard CC0: J-Ponzo/gltf-universal-animation-library, pinned `e24c23cf2a1323488a3faa226ea7ea21f644b73e`, including the required external BIN and license.
- UAL2 Standard CC0: agentkaerf/FreeModels, pinned `db3df04d1e4714298a09510b26fb6de6645138a2`, original license retained.

No paid Source/Pro pack, new unlicensed download, Bestiary model or VRM character is used by production HeroVisual. Production does not depend on art_lab asset paths. The review scene and historical audit remain available independently.

## Limitations / next art work

The free Standard wardrobe only supplies two outfits. Steel and robe IDs retain their exact gameplay stats but do not yet have dedicated fitted plate/robe meshes; steel receives a metallic material treatment on the ranger torso. Existing generated gear remains recognizable placeholder equipment. The selected family has no facial blend shapes. Additional authored fitted armor sets, character bodies, facial rigging, higher quality weapon models and consistent creature art are separate work. Do not run the previous Blender hero generator expecting it to author these imported models.

## Verification

Godot 4.6.3, Linux headless and Compatibility rendering on a local software X11 display. The nine gameplay suites cover combat, full quest flow, all 1,320 ordered three-class choices, equipment, menus, skills, save/load and companions. The new `tests/hero_quaternius.tscn` checks actual rig track targets, hand movement, attachments, all mapped actions, outfit/hood choices, each weapon's shield rules, all 12 classes and unchanged hero data. Art-lab tests continue checking the old comparison independently; its historical byte audit explicitly exempts the approved hero adapter change.

Commands:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . res://tests/hero_quaternius.tscn
godot --headless --path . res://tests/presentation.tscn
godot --headless --path . res://art_lab/validate.tscn
```

Use isolated Godot user-data directories for automated suites: tests intentionally exercise save/reset and should not share a player's save location. Windows-specific GPU rendering has not been tested here.

Final results: fresh-cache import passed without errors; nine gameplay suites passed **985 checks**, the new hero integration suite passed **136 checks**, and the preserved comparison suite passed **75 checks**: **1,196 checks, zero failures**. The 136 hero checks also passed on the fresh-import copy. Actual rendered game and close-up captures showed sword attacks, blocking, spells, death, traveler/ranger outfits and equipment; selected captures are in `docs/screenshots/quaternius/`. Existing generated helmet/limb gear remains visibly provisional.

### Subsequent male/female class skins

The single-body limitation above is superseded by `docs/CLASS_SKINS.md`: both authored male/female ranger and peasant models now support 24 class looks with original class texture derivatives and crests. The earlier 1,196-check count describes the first integration, before this addition. Shared outfit geometry and the need for more fitted armor/robe sets remain limitations.
