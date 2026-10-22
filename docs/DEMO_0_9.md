# Demo 0.9 — Starter equipment, bonds and point-based progression

The starter outfitter now offers three weapons and two basic accessories/clothing choices, with consumables separately available. The full equipment catalog is retained for future shops, rewards and owned gear. All 1,320 distinct ordered three-class combinations can equip at least one starter weapon without altering class proficiencies.

## Progression

Every class and weapon family has twelve nodes costing 60 shared SP. A new character gets two SP and earns two per level: one complete tree consumes the lifetime budget through level 30. There are no level or class/weapon victory requirements. Prerequisites, available points and duplicate-purchase checks remain. Any weapon tree can be studied; its final Freedom node grants permanent proficiency. Two-handed/shield restrictions remain physical equipment rules and cannot be bypassed by Freedom.

Class passives are permanently included in stats even if that class later leaves all three roles. Class actions still require a currently selected class; mythics require that class primary. Weapon passives/actions require matching equipped gear. Class choices remain locked during this demo. Learned combat arts include Paladin Holy Light and Sword Thunder Strike, with separate MP costs and effects. All twelve class trees now have thematic passive names and stat profiles, rather than identical upper branches; weapon families likewise favor their combat roles.

Existing 0.7/0.8 learned node IDs and unspent points are retained. Previously bought cheaper nodes are grandfathered; no new respec or removal occurs. Earlier pre-0.7 migration remains backed up and archives its historical short-tree investments.

## Companions

Six distinct hero stat bonds: Dragon MP/offense; Spirit Fox MP/healing; Dire Wolf attack/critical chance; Griffin attack/dexterity; Golem HP/defense; Warhorse HP/agility. Base companion attacks, support power, HP, speed and class synergies remain distinct.

Each permanent companion has an eight-node, 24-bond-point tree teaching three unique abilities. Bond points belong to that companion and are earned at two per level. Training a reserve companion does not change the active companion. Automated Attack/Support/Defend chooses the strongest useful learned matching art off cooldown; otherwise it falls back to the basic behavior. Arts include MP recovery, regeneration, timed attack/defense/agility/dexterity buffs, bleeding bites, stuns and piercing attacks. They use the companion's turn and the shared normal/Auto combat simulator.

Hero bond bonuses remain through the encounter even if the companion falls; its actions stop. Changing companions clamps HP/MP to the new capacities without filling the extra capacity. Physical hero critical hits deal 1.5× damage; chance is capped at 60% and uses seeded rolls.

## Visual changes

The hero's former chibi body is replaced with clothed natural human topology, a defined anatomical face/hands and original eyes/hair assembly, retargeted onto the existing animation skeleton. Source: MakeHuman's CC0 base mesh, combined with the credited CC0 KayKit skeleton/animation clips. Source files, licenses, hashes and a Blender rebuild script are bundled. Clothing, equipment sockets and player appearance colors remain supported. Background spheres are replaced with continuous layered ridgelines; outdoor battle clearings now use the dirt surface maps.

This is a substantial hero-model replacement, not a claim of final commercial visual quality. Companion/enemy geometry remains the previous original art, with segmented animation. Terrain remains mainly flat; skinning, armor intersections, facial customization, foliage aliasing and visual cohesion still need further art work. No paid assets or external runtime service is required.

## Validation

Godot 4.6.3, Linux, headless tests with isolated save directories:

| Suite | Checks | Failures |
|---|---:|---:|
| Core/story | 67 | 0 |
| Real new-adventure / ending / postgame | 159 | 0 |
| Twelve classes and weapon progression | 283 | 0 |
| Animation/UI/persistence presentation | 63 | 0 |
| Save/camera/settings reliability | 19 | 0 |
| Responsive layout | 6 | 0 |
| Equipment preview and shop flow | 128 | 0 |
| Adventure/contact/side quests/puzzles | 124 | 0 |
| New companion/point/proficiency/shop rules | 136 | 0 |
| **Total** | **985** | **0** |

The new suite checks actual stat changes, healing/MP restoration, bleed/stun/regen, ability selection, cooldowns, save/load, UI training, starter coverage and deterministic normal/Auto parity for every companion. After thematic passive adjustments, the affected progression/presentation suites were rerun successfully.

Rendered 24 review captures at 960×540 on the OpenGL compatibility renderer using a virtual X11 display, including creation, equipped hero, all starter previews, companion tree, exploration, battle stance/attack, puzzles and all six companions. No script/runtime errors in the capture run; the software display warns that VSync cannot be changed. Screenshots in this directory's gallery show the shipped hero and menu direction.

Automated tests accelerate time/teleport and do not establish the 15–20 minute human playtime target. Windows playtesting, audio review, deeper balancing and controller support remain outstanding.
