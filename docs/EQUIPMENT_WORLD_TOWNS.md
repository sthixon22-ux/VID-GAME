# Equipment, environment and enterable towns

Branch: `feature/equipment-world-town-polish`, extending the tested Mirefen chapter. The existing application/save path, twelve classes, free three-class creation, companion progression, combat calculations and campaign remain intact. Existing saves can continue; a new adventure is unnecessary.

## What changed

### Equipped clothing

The former adapter only recognized a few named chest items and otherwise retained the class outfit, so buying clothing could leave the hero visually unchanged. Chest equipment now has an explicit visual profile:

| Equipment | Appearance |
|---|---|
| None | Original selected class look; grants no armor or stats |
| Traveler's Clothing | Authored traveler outfit, warm cloth tint |
| Leather Vest | Authored ranger/leather outfit |
| Steel Cuirass | Ranger foundation, metallic surfaces and a separate skinned plate shell derived from its authored torso |
| Verdant Robe | Traveler foundation, green textile treatment and a weighted long skirt |
| Reedcoat | Ranger foundation, blue treatment and weighted coat tails |
| Sluicekeeper Robe | Traveler foundation, blue robe and weighted long skirt |

Both body types retain their faces, hair, class crests/palettes and customization. Armor changes rebuild in the existing equipment preview and survive menus, region travel and saving. The plate preserves the original torso skin weights; the robe/coat extension follows the existing skin/hips. These additions are not cloth simulation or a complete new professionally sculpted outfit collection. Hood equipment also has a fallback when the traveler model has no built-in hood.

[Male plate](screenshots/equipment_towns/Male_Steel_Cuirass.png) · [Female robe](screenshots/equipment_towns/Female_Sluicekeeper_Robe.png)

### Weapon grips and actions

The old generic 90-degree prop rotation placed the blade along the wrong hand axis. Attachments now place the actual grip inside the palm and align the blade/shaft with the thumb axis. Fingers close around held weapons. Shield exclusion still comes from the original equipment rules.

A post-animation `SkeletonModifier3D` places the two arms using a two-bone solver for two-handed weapons. It runs after the licensed animation library rather than modifying shared animation resources or gameplay state. Grip positions follow the animated shoulder midpoint, preserving fit across male/female proportions and body motion.

- Sword: authored sword stance and attacks with corrected palm orientation.
- Greatsword, axe and hammer: two-handed grip and overhead chopping/striking motion layered over the existing authored clip.
- Spear: forward two-handed thrust, rather than the old sweeping sword attack.
- Scythe: two-handed lateral sweep.
- Staff: two-handed hold and physical strike; spells retain their separate casting clips.
- Daggers: short-blade action; a second dagger is visible when the off-hand has no shield.
- Claws: paired visible weapons with the existing punch action; shields remain excluded.
- Bow: left-hand bow, right-hand string draw, torso turn, head aim, opening/closing string fingers, animated bowstring, nocked arrow, quiver and a released projectile. The old overhand-throw substitution is removed. Normal bow shots do not produce a sword slash or melee lunge.
- Wand and spells: casting presentation remains separate from physical weapon actions.

Bow flight targets the actual enemy's world position. The impact phase waits for draw, release and flight before refreshing damage/reaction presentation; damage is still calculated once by the deterministic simulator. Arrows are visual ammunition for the existing basic attack, not a new finite-ammo inventory or damage source.

The new bow and arm trajectories are original procedural animation layered over the licensed base library. No new motion-capture pack was downloaded. They improve consistency and hand contact, but are not a claim of fully bespoke motion capture or finished choreography for every late-game ability.

[Bow draw](screenshots/equipment_towns/bow_attack.png) · [Greatsword](screenshots/equipment_towns/greatsword_attack.png) · [Spear thrust](screenshots/equipment_towns/spear_attack.png)

### Environment materials

The pass fixes world-scale mapping rather than stretching a small grain texture over a whole board, tree or floor. Terrain uses continuous world-space detail, gentle large-scale color variation, small leaf/clover accents and a feathered dirt edge. Dirt path pieces no longer cast the dark rim shadows seen in the first render review.

Wood samples only the authored wood portion of the bundled CC0 Quaternius trim atlas, with world-oriented grain. Stone surfaces use world triplanar sampling. Building material overrides soften exaggerated normal strength and use anisotropic mip filtering. Water ripples are world-scaled, with a quieter palette and subtle surface normals. Foliage filtering and a restrained atmospheric/ambient-light adjustment improve distant readability.

**No new third-party texture pack was downloaded.** Requests to `https://api.polyhaven.com/files/forest_ground_04` and `https://polyhaven.com/license` were blocked by this environment's proxy with HTTP 403; GitHub API lookups were also blocked. This update reuses the already verified, credited CC0 Quaternius surfaces and existing original terrain maps, with original shader work. It does not claim that inaccessible packs were imported or that their license pages were verified here.

The environment still needs a bespoke authored terrain/vegetation asset pass to reach the character art standard. Geometry remains mostly flat and many trees retain the existing foliage cards. This is a material/readability improvement, not a replacement of all landscape art.

[Willowbrook](screenshots/equipment_towns/willowbrook.png) · [Woodland](screenshots/equipment_towns/woodland.png) · [Marsh](screenshots/equipment_towns/marsh.png)

### Enterable town services

Walk to a marked house door and press **E**. Inside, approach the counter and press **E** to use the existing shop menu. Return from that menu to the room, then use the exit to return outside. Inventory, equipment, skill trees, companions, journal, settings and saving remain available indoors.

| Town | Weapon shop | Armor shop | Items | Inn |
|---|---|---|---|---|
| Willowbrook | Western house: sword, daggers, staff | Eastern house: traveler clothing and pendant | Northern western house: potions, ether, companion rations | Northern eastern house: **12 gold** |
| Reedcross | Tamsin's regional weapons | Beren's regional armor/accessory | Sella's supplies | Lantern Rest: **24 gold** |

The former outdoor outfitter location is a directions marker. The beginner objective and minimap now point to actual shop doors. Reedcross's old instant free inn interaction gives directions to its inn building instead.

Rooms use a reusable cutaway interior scene with counter, merchant, displays, supporting furniture, authored stone floor/windows/crates, rugs and inn beds. Camera blockers keep orbiting views inside the side/back walls; overhead crossing beams were removed after they obscured the hero in the rendered review. Interiors are modest shared layouts, not eight bespoke architectural scenes. They have an open camera-facing wall/roof cutaway.

Inn payment occurs only after choosing Stay. Insufficient gold disables the offer and a rejected purchase changes neither gold nor health. A paid room restores hero HP/MP and companion HP. Existing Willowbrook camp rest is retained for opening/save compatibility and recovery, so inns are not the only recovery option.

The saved `town_visit` record identifies the outside region, service, name and precise return position. Schema 4 remains supported, with defaults for old saves. Saving inside, reloading, browsing equipment and exiting returns to the correct town without placing the hero inside house collision.

[Weapon interior](screenshots/equipment_towns/forest_weapons.png) · [Reedcross inn](screenshots/equipment_towns/mirefen_inn.png)

## Verification and remaining limits

Godot 4.6.3 on Linux. **1,973 assertions passed across 16 suites**, including **213 new equipment/town checks**. The checks cover both body types, chest profiles and silhouette meshes, every weapon family/attachment, grip distance at four attack phases, actual bow battle release/target/timing, unchanged gameplay state, all eight service doors, shop reuse, paid/failed inn stays, indoor save/load and safe return positions. The opening scene-flow fixture now actually enters a building and approaches a merchant instead of invoking the removed outdoor menu.

Fresh import of a separate project copy succeeded without the previous `.godot` cache. The equipment/town suite was also executed in that copy. Existing core/combat, progression, twelve-class skins, companion, opening quest, Chapter 2 and art-lab checks were executed; historical hash exclusions explicitly list the requested visual/material/town changes instead of silently replacing old evidence. Detailed counts are in [the validation record](validation/equipment_towns_results.json).

Rendered review produced 30 clothing/weapon studio views and 11 actual overworld/interior views. The capture tools cycle and exit; players should launch the main game with **F5**. They are `tools/equipment_review.tscn` and `tools/town_world_review.tscn`, using isolated user data and a Compatibility display. The world capture mutes audio and uses the existing shutdown routine to avoid the audio-playback teardown leak diagnosed during review.

Known native `Parameter "material" is null` diagnostics remain in several pre-existing headless stress fixtures despite passing assertions. This is disclosed separately from the clean import, equipment/town scene checks and normal render logs. Windows/hardware GPU performance and a human fresh-start playthrough have not been certified. Close-up hand/armor clipping in untested combinations, stiff robe hems, shared-room art and the remaining landscape/vegetation gap still need refinement. No finite-arrow inventory, cloth physics or new class restrictions were introduced.

Reproduce with isolated saves:

```bash
godot --headless --path . --editor --import --quit
for suite in run presentation reliability demo progression layout shop_flow adventure8 progression9 hero_quaternius class_skins companion_art campaign_expansion mirefen_chapter equipment_towns; do
 XDG_DATA_HOME=/tmp/verdant-$suite godot --headless --path . res://tests/$suite.tscn
done
XDG_DATA_HOME=/tmp/verdant-lab godot --headless --path . res://art_lab/validate.tscn
```
