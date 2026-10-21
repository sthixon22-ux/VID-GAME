# Male and female class skins

Start **New Adventure**. On **Create Your Hero**, choose **Male** or **Female**, then a primary class and two different secondary classes. The 3D preview updates immediately. Name, skin tone, hair color and outfit tint remain available. Begin Adventure saves the body choice. Existing saves without this field keep the previous female body.

There are **24 cosmetic class looks**: 12 primary classes × two body choices. These use professionally authored CC0 male/female Quaternius bodies and two compatible outfit families, with original class texture treatments, embroidery crests, hood/shoulder choices and male/female palette variations. They share base geometry; they are **not 24 separately sculpted armor sets or unique faces**. Secondary classes, combat stats and weapon eligibility are unchanged. The class clothes grant no starting items or armor stats; the first weapon still needs to be purchased.

[View all 24 looks](screenshots/class_skins/gallery.jpg)

| Class | Male look | Female look | Colors / crest |
|---|---|---|---|
| Paladin | Ivory Oath | Dawn Guardian | Ivory, gold, navy; sun |
| Ranger | Woodland Scout | Wildwood Warden | Forest green, russet; arrow |
| Druid | Grovekeeper | Thorn Oracle | Moss, ochre; leaf |
| Warrior | Iron Vanguard | Steel Sentinel | Steel blue, red; crossed blades |
| Barbarian | Ashland Reaver | Ember Marauder | Earth, charcoal; fang |
| Wizard | Astral Scholar | Starweaver | Indigo, silver; star |
| Sorcerer | Crimson Arcanist | Ruby Spellbinder | Crimson, gold; flame |
| Healer | Dawn Medic | Sanctuary Keeper | Ivory, teal; healing cross |
| Rogue | Dusk Vagabond | Velvet Shadow | Burgundy, slate; diamond |
| Assassin | Nightblade | Moonveil | Charcoal, violet; crescent |
| Monk | Saffron Disciple | Golden Lotus | Saffron, wine; lotus |
| Necromancer | Gravebound | Veilkeeper | Obsidian, jade; rune |

These are style labels, not the hero's name. Hair and complexion are player choices. Changing equipment continues to update the rendered character: fitted ranger/traveler clothing, authored hood, bone-attached weapon/shield/helmet/other gear and appropriate two-handed shield hiding. The legacy generated plate/limb props still need better fitted authored replacements. Full robes and unique armor silhouettes for every class remain future art work.

## Files and provenance

- `data/hero_skins.json`: class/sex appearance definitions, isolated from class combat data.
- `scripts/hero_skin_book.gd`: catalog lookup and verified model/texture paths.
- `HeroVisual`: profile-aware model, material and outfit selection. All movement and combat clips still use the canonical humanoid rig. Animation caches include both bone layout and hip height so a clip library filtered for another rig cannot be reused incorrectly.
- `State.hero.profile.sex`: additive, validated save field. Older API callers default to Female; no class/build migration or skill reset.
- `tools/build_class_skins.py`: reproducible Pillow/numpy pipeline for 48 outfit textures (24 looks × two outfit families) and 24 original crest images. Crests are projected onto existing torso UV triangles; no primitive final character meshes were generated.
- `assets/textures/class_skins/DERIVATIVES.json`: texture hashes and source-model identity.
- `assets/vendor/SOURCES.json`: exact pinned male-model URLs and SHA-256 hashes. Original CC0 notices are retained alongside all four character models.

Male sources use the **same licensed Quaternius Standard derivative family** as the selected female character:

- [Male Ranger GLB](https://raw.githubusercontent.com/ibra-kdbra/Generate_infinite/027491fa5d30788d26fc707bddf6c8cdb48ad1f4/public/models/characters/male_ranger.glb)
- [Male Peasant GLB](https://raw.githubusercontent.com/ibra-kdbra/Generate_infinite/027491fa5d30788d26fc707bddf6c8cdb48ad1f4/public/models/characters/male_peasant.glb)

The original source README credits Quaternius Universal Base Characters Standard and Modular Character Outfits Fantasy Standard as CC0. No paid outfit archive or proprietary game model was downloaded. Recolored outfit atlases derive from those CC0 materials; class crest designs and the generator are original project work. Original authored normal/roughness maps remain in use.

## Validation

Tested with Godot 4.6.3, headless and OpenGL Compatibility on Linux. The class-specific suite checks 24 distinct rendered texture bindings, canonical rigs, actual attack/block/spell bone movement, live creation selectors, independent secondary options, no preview mutation, both equipped body rigs, identical male/female class stats, save/load, invalid input rejection and legacy saves. Broader suites cover combat, the complete introductory adventure, quests, items, shops, equipment, all 1,320 ordered three-class choices and progression. The art lab retains its historical comparison and explicitly excludes the approved character-creation/save/visual files from its original byte audit.

Reproduce the new suite:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . res://tests/class_skins.tscn
```

Use an isolated user-data directory: save tests create and overwrite their test hero. `tools/class_skin_capture.tscn` captures all 12 male/female pairs; `tools/creation_skin_capture.tscn` captures both creation choices and the male hero entering the game. These capture tools cycle and quit; play the normal game with **F5**, not the capture scene.

Final assertion counts: gameplay regression suites **985**, existing hero integration **136**, new class-skin suite **209**, preserved art-lab comparison **75**: **1,405 passing assertions**. Fresh-cache import passed without script/import errors. The class-skin suite also passed using the Compatibility renderer, and the rendered creation-to-male-gameplay capture completed without runtime errors.

Known validation diagnostic: mass asset construction/destruction in the headless class/demo fixtures can emit Godot's native `material_get_instance_shader_parameters: material is null` diagnostic (the rendered full-demo stress run also emitted related native material diagnostics). Assertions still pass; these logs are not claimed to be entirely error-free. The normal rendered creation flow and the rendered class-skin suite did not reproduce this diagnostic. It remains a stress/lifecycle issue to investigate separately; no production rendering suppression was added. Windows GPU behavior has not been tested here.
