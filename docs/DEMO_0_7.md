# Demo 0.7 — twelve classes, six stats and long-term trees

## Player-facing changes

All twelve overview classes are available for primary and secondary selection: Warrior, Barbarian, Paladin, Wizard, Sorcerer, Healer, Ranger, Rogue, Assassin, Monk, Druid and Necromancer. Choose one primary and two distinct secondaries. At camp, assigning an already-equipped class swaps slots; assigning another class replaces only the chosen slot. Investments in unequipped classes remain saved but contribute no passive bonuses or abilities until equipped again.

Every primary class defines its own level-one HP, MP, attack, defense, agility and dexterity, plus per-level growth. The character-creation page displays these values and growth. The other two classes contribute their learned passives, abilities and proficiencies; they do not overwrite the primary's baseline/growth profile.

| Class | HP | MP | ATK | DEF | AGI | DEX |
|---|---:|---:|---:|---:|---:|---:|
| Warrior | 120 | 25 | 18 | 6 | 12 | 7 |
| Barbarian | 140 | 18 | 21 | 3 | 11 | 5 |
| Paladin | 110 | 35 | 15 | 5 | 13 | 8 |
| Wizard | 80 | 65 | 9 | 3 | 11 | 9 |
| Sorcerer | 85 | 60 | 11 | 3 | 14 | 10 |
| Healer | 90 | 60 | 10 | 4 | 12 | 11 |
| Ranger | 100 | 32 | 15 | 4 | 17 | 14 |
| Rogue | 90 | 30 | 15 | 4 | 20 | 20 |
| Assassin | 85 | 30 | 19 | 3 | 19 | 18 |
| Monk | 110 | 30 | 17 | 5 | 18 | 13 |
| Druid | 95 | 50 | 12 | 4 | 12 | 10 |
| Necromancer | 85 | 58 | 11 | 3 | 10 | 12 |

At level L, each base stat is `level-one value + floor(per-level growth × (L − 1))`. Equipment and active learned bonuses are then added. Growth is defined per class in `data/classes.json`; fractional growth accumulates across levels instead of being discarded every level. Agility is at least 1 and dexterity at least 0.

## Agility and dexterity

- **Agility** determines highest-first turn order, recalculated each round. Equal values use the deterministic hero/companion/enemy tie order. Speed remains only an internal compatibility alias; player-facing pages use AGI. Defend takes effect for the chosen round even when the defender acts late.
- **Dexterity** gives a dodge probability of `min(35%, DEX × 0.4%)` against incoming enemy attacks. Physical attacks also respect a target enemy's dexterity when configured; the existing foes have zero DEX. Healing, ongoing damage and guaranteed magical effects do not use physical evasion checks. A dodge consumes no HP and does not count as a successful shield block. The hero has a skeletal dodge reaction when full animations are enabled.
- Battle/quest gold uses `min(60%, DEX × 0.6%)` to award an extra **25% of base gold, rounded up**. It rolls once per reward, not once per item or event. Bonus gold appears in victory/Auto results or exploration reward notices. Battle rewards use the permanent build's DEX after combat buffs end; temporary Feint is a combat evasion buff.
- Both chance systems use seeded calculations. Normal and Auto-Battle share the same combat and reward rules. Forecasts never modify the live character or seed.

Armor, weapons, accessories and learned abilities can now affect all six stats. Examples: light boots raise AGI, heavy plate trades AGI for defense/HP, robes/staves raise MP, Ranger gear/charms raise DEX. Feint raises DEX temporarily, Windstep raises AGI and can change the following round's order, and other class abilities cover attack/defense buffs, healing, poison, weakening, freezing, life drain and meditation. Dodge and bonus-gold chances are shown in the equipment stat panel.

## Class and weapon progression

The previous six-node class and two-node weapon trees were demo shortcuts. They have been replaced with **12 class trees and 13 weapon-family trees**, each containing twelve nodes and costing **50 shared skill points** to finish. All 300 nodes have real effects, costs and prerequisites.

- Start with two skill points; earn two more per hero level.
- Level gates: **1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 48, 50**.
- Costs: **1, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6**.
- A full tree cannot finish before **level 50**, even with banked points or excessive mastery.
- A focused level-50 build has earned 100 points: enough for one full class tree and one full weapon tree. Spreading points across more classes/families delays completion. There is no promise that every tree completes at level 50.
- Class and weapon mastery remain separate victory-based eligibility counters. Later nodes need both hero level and relevant mastery, up to 25 victories for a capstone. Switching to an unfamiliar class therefore still requires investment.
- Class branches grant additional class abilities at levels 10 and 35; the level-50 class capstone grants its primary-only mythic. Learned secondary mythics remain saved but cannot be used.
- Weapon bonuses work only for the matching equipped family; shields require an equipped shield. Weapon branches also unlock an advanced active technique at level 35.

The weapon families are sword, shield, axe, greatsword, hammer, spear, bow, dagger, staff, wand, scythe, claws and unarmed. Added starter weapons have original geometry, combat legality checks and matching techniques. Proficiency comes from any of the three equipped classes. Heavy plate requires Warrior or Paladin primary. Shields are optional; Monk-trained characters may start combat unarmed with chest clothing. The outfitter's opening-budget reserve uses compatible gear prices rather than assuming every class needs a sword/shield.

These are functional introductory implementations of every class, with starting actions, advanced actions, a mythic, stats/growth, proficiencies and progression. They are not the final complete spell libraries or bespoke character rigs for twelve production classes.

## Existing-save upgrade

Save schema/progression version is now **3**. Loading an older save creates an original versioned backup (for 0.6, `hero.json.v2.backup`). Level, XP, quests, gold, companion ownership/training and owned/equipped gear are retained. Old over-fast skill purchases are moved into `progression_archive`; class/weapon investments reset once and the hero receives the new unspent budget of `2 × current level`. The title explains the respec. Upgraded older characters use the new rules, and migration is idempotent after saving. The previous save and archived purchases preserve a record of the old build.

New skill gates are intentional balance changes authorized by the request to stop completing trees during the short demo. Old early mythics are not silently left active at low level. Name-based class/equipment aliases remain supported; new content uses the existing stable ability/item/family IDs.

## Validation and changed areas

New `game_rules.gd` centralizes stat growth, chance formulas and deterministic gold rolls; `gear_visual.gd` builds the additional original weapon shapes. Class/ability/equipment/weapon/enemy data, State, combat/ability logic, creation, character/skill pages, battle/VFX, world rewards and save migration are integrated. The single dialogue wording adjustment changes “raise your shield” to “raise your guard” so the existing boss advice also fits non-shield classes. The quest/story structure is preserved.

**597 automated checks pass in Godot 4.6.3**: 61 full-story, 62 presentation, 19 reliability, 159 demo-flow and 296 new progression/stat checks, with no runtime/script errors. The progression suite also enumerates all 1,320 class-slot combinations.

Tests cover all twelve creation profiles and starting actions, natural six-stat growth, all 1,320 ordered class loadouts, every class's matching starter kit and full six-fight combat sequence, 25 complete level-gated trees, level-49 rejection/level-50 eligibility, primary-only mythics, armor stat changes, initiative/ties, seeded evasion frequency/caps, agility/dexterity buffs, normal/Auto parity, gold chance frequency, quest/battle gold and old-save respec/reload. Existing full-story, presentation, reliability and demo scene suites remain part of regression validation. Rendered review covers the twelve-class picker, class stats/growth, caster gear, extended class/weapon pages and battle screens.

This update changes long-term progression, not the demo's physical world size. There is no newly authored level-50 quest campaign; reaching those tiers with only the existing low-level enemies would require substantial repetition. Growth, rewards and late-game encounter content will need real-player balancing as the game expands. New weapon meshes and shared action animation are functional placeholders, not a claim to final animation/art polish.
