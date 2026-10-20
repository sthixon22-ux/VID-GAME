# PROJECT MYTHIC
## Master Game Design Document & Codex Development Brief
**Version:** 1.0  
**Engine:** Godot 4  
**Language:** GDScript  
**Genre:** Single-player, stylized 3D, turn-based fantasy RPG  
**Development stage:** Existing introductory area and first quest; early playable prototype  
**Working title:** Project Mythic (temporary)

---

# PART I — PROJECT VISION

## 1. Overall Vision

We are creating an original, single-player fantasy RPG inspired primarily by *Dragon Quest IX: Sentinels of the Starry Skies*, with a more cinematic combat presentation inspired by *Dragon Quest XI*.

The game emphasizes:

- Deep character customization through multiclassing.
- One primary class and two secondary classes simultaneously.
- Class chemistry that rewards complementary combinations.
- Weapon-specific fighting styles.
- Class-specific spellbooks and skill trees.
- Powerful rare, legendary, and mythic abilities.
- One hero accompanied by a creature companion.
- Class-specific armor that visibly changes the character.
- Turn-based combat with cinematic animations.
- Progressive enemy complexity.
- Monster mastery that unlocks fast auto-battles.
- Exploration, quests, character progression, and a fantasy story.

The overall experience should begin relatively simple and become progressively deeper as players discover classes, weapons, abilities, companions, equipment, and increasingly sophisticated monsters.

The game should reward strategic character-building without forcing players into a small number of optimal combinations.

### Design philosophy

**Freedom with meaningful specialization.**

Players can experiment with unconventional combinations, but classes that naturally complement each other should receive meaningful incentives.

**Long-term progression.**

Powerful spells, legendary fighting techniques, and mythic abilities should feel earned rather than being available immediately.

**Respect the player's time.**

Repetitive encounters should become faster after the player has demonstrated mastery of an enemy species.

**Visible progression.**

Better equipment, new fighting techniques, stronger spells, and companion development should be reflected in gameplay and appearance.

**Scalable development.**

We are building a small introductory quest now, but its underlying systems should be designed for the entire game.

---

# PART II — CURRENT DEVELOPMENT STATUS

## 2. Existing Project

An introductory area and the beginnings of the first quest have already been created in Godot.

The basic foundation exists, but several areas need substantial improvement:

1. Character and environmental art.
2. Character animations.
3. Combat animations and cinematic presentation.
4. User interface and menus.
5. Visual consistency.
6. Gameplay polish.
7. Integration of the long-term RPG systems described below.

### Critical instruction to Codex

**DO NOT start a new project or rebuild the game from scratch.**

Inspect the existing Godot project before making changes.

Identify:

- Existing scenes and scripts.
- Player movement and camera systems.
- Current combat implementation.
- Quest progression and dialogue.
- Enemy definitions.
- UI elements.
- Animation systems.
- Existing assets.
- Save/load functionality.
- Current project organization.

Preserve working systems and existing quest content wherever practical.

Refactor systems only when doing so improves maintainability, scalability, or correctness.

Do not assume a system is missing simply because it is not described in this document.

Before making major changes, explain what currently exists, what should be retained, and what needs improvement.

The existing introductory area should become the first polished vertical slice of the complete game.

---

# PART III — VISUAL DESIGN

## 3. Art Direction

The game will use stylized 3D graphics.

### Primary inspiration

Dragon Quest IX's colorful fantasy aesthetic, with a more modern and polished 3D presentation.

### Desired characteristics

- Colorful fantasy environments.
- Expressive character designs.
- Stylized proportions rather than photorealism.
- Recognizable character and monster silhouettes.
- Detailed but readable armor.
- Distinctive weapon designs.
- Visually appealing spell effects.
- Consistent art direction across the entire game.
- Environments that feel inviting, mysterious, and adventurous.

The game should not copy copyrighted Dragon Quest models, textures, characters, monsters, music, or other assets.

Create an original visual identity that draws inspiration from the genre.

### 3D character requirements

The hero should eventually support:

- Customizable appearance.
- Modular armor.
- Multiple weapon types.
- Visible shields.
- Class-specific clothing and armor.
- Combat and exploration animations.
- Companion mounting animations where applicable.

The character model and skeleton should be designed to support equipment changes and animation reuse.

### Art production

Use Blender-compatible 3D models and Godot-compatible assets.

Prefer reusable, modular assets over unique one-off models.

For the current prototype, prioritize a coherent stylized appearance rather than highly detailed assets.

Where appropriate, use simple geometry temporarily, but structure the scenes so those assets can be replaced without rewriting gameplay logic.

---

# PART IV — HERO AND CLASS SYSTEM

## 4. Core Character System

The player controls one primary hero.

The hero can equip three classes simultaneously:

- One primary class.
- Two secondary classes.

All three classes contribute to the hero's available abilities, passive bonuses, and build identity.

However, the primary class has the strongest influence over the hero's core combat identity.

### Primary class

Determines:

- Main class identity.
- Primary stat specialization.
- Full access to that class's skill progression.
- Access to that class's unlocked mythic abilities.
- Primary armor identity.
- Full primary-class combat benefits.

### Secondary classes

Provide:

- Additional skill trees.
- Selected weapon proficiencies.
- Additional spells.
- Passive bonuses.
- Tactical versatility.
- Class chemistry interactions.

Secondary classes should remain meaningful without overpowering the primary class.

### Class switching

The player should eventually be able to change primary and secondary classes at designated locations or through another controlled system.

Invested skill points and unlocked abilities must remain saved when a class is unequipped.

Class progression must not be lost when switching classes.

The exact unlocking conditions for class switching remain to be determined.

---

## 5. Twelve Planned Classes

The initial roster contains 12 classes.

### 5.1 Warrior

**Role:** Physical combat specialist.

Weapons:
- Swords.
- Greatswords.
- Spears.
- Axes.
- Shields.

Strengths:
- Physical damage.
- Weapon mastery.
- Counterattacks.
- Defensive reliability.

Skill branches:
- Weapon Combat.
- Battlefield Defense.
- Martial Discipline.

### 5.2 Barbarian

**Role:** Aggressive melee damage.

Weapons:
- Axes.
- Greatswords.
- Hammers.

Strengths:
- High strength.
- High HP.
- Rage-based abilities.
- Heavy physical attacks.

Skill branches:
- Rage.
- Brutal Combat.
- Survival.

### 5.3 Paladin

**Role:** Holy frontline defender.

Weapons:
- One-handed swords.
- Maces.
- Spears.
- Shields.

Magic:
- Holy.
- Protection.
- Limited restoration.

Strengths:
- Defense.
- Blocking.
- Holy damage.
- Protective magic.
- Sustained combat.

Skill branches:
- Holy Combat.
- Divine Protection.
- Sacred Magic.

### 5.4 Wizard

**Role:** Arcane spell specialist.

Weapons:
- Staves.
- Wands.
- Spellbooks.

Magic:
- Arcane.
- Elemental.
- Magical barriers.

Strengths:
- High MP.
- Magical versatility.
- Advanced spellcasting.

### 5.5 Sorcerer

**Role:** Elemental damage specialist.

Weapons:
- Wands.
- Staves.
- Tomes.

Magic:
- Fire.
- Ice.
- Lightning.

Strengths:
- Elemental damage.
- Spell amplification.
- Elemental resistance manipulation.

### 5.6 Healer

**Role:** Restoration and survival.

Weapons:
- Staves.
- Maces.
- Wands.

Magic:
- Healing.
- Cleansing.
- Restoration.

Strengths:
- Healing efficiency.
- Status recovery.
- Defensive support.

### 5.7 Ranger

**Role:** Precision and wilderness combat.

Weapons:
- Bows.
- Crossbows.
- Daggers.
- Spears.

Magic:
- Minor nature magic.

Strengths:
- Accuracy.
- Agility.
- Tracking.
- Marked targets.
- Companion coordination.

Skill branches:
- Archery.
- Survival.
- Beast Bond.

### 5.8 Rogue

**Role:** Speed and tactical disruption.

Weapons:
- Daggers.
- Short swords.
- Dual blades.

Strengths:
- Evasion.
- Fast attacks.
- Debuffs.
- Opportunistic damage.

### 5.9 Assassin

**Role:** Critical damage and lethal precision.

Weapons:
- Daggers.
- Short swords.
- Throwing weapons.

Magic:
- Minor shadow magic.

Strengths:
- Critical hits.
- Poison.
- Finishing moves.
- Exploiting weakened enemies.

### 5.10 Monk

**Role:** Martial arts specialist.

Weapons:
- Fists.
- Staves.
- Claws.

Magic:
- Limited spiritual techniques.

Strengths:
- Rapid attacks.
- Counters.
- Meditation.
- Self-buffs.

### 5.11 Druid

**Role:** Nature magic and adaptability.

Weapons:
- Staves.
- Spears.
- Sickles.

Magic:
- Nature.
- Earth.
- Regeneration.

Strengths:
- Damage-over-time effects.
- Healing over time.
- Nature-based defense.
- Companion enhancements.

Skill branches:
- Nature Magic.
- Restoration.
- Primal Power.

### 5.12 Necromancer

**Role:** Dark magic and life manipulation.

Weapons:
- Staves.
- Wands.
- Scythes.

Magic:
- Shadow.
- Curses.
- Life drain.

Strengths:
- Enemy weakening.
- Life manipulation.
- Temporary spectral attacks.

Temporary summons should not automatically create additional permanent party members.

---

# PART V — CLASS CHEMISTRY

## 6. Chemistry System

The three equipped classes have a chemistry rating based on how naturally their fighting styles and abilities complement each other.

### Example: High chemistry

Primary: Barbarian  
Secondary: Warrior  
Secondary: Paladin

These classes share physical combat, defense, and frontline fighting strengths.

Potential bonuses:
- Improved physical attack combinations.
- Defensive synergies.
- More efficient melee techniques.
- Exclusive combination abilities.

### Example: Low chemistry

Primary: Barbarian  
Secondary: Wizard  
Secondary: Healer

These classes have less obvious natural synergy.

However, this combination must remain playable and potentially powerful through creative strategies.

### Chemistry rewards

Potential benefits include:

- Complementary passive bonuses.
- Resource efficiency.
- Improved defensive interactions.
- Special combination abilities.
- Bonuses triggered by using abilities from different classes.

Avoid making chemistry primarily a large flat damage multiplier.

The system should reward coordinated playstyles rather than merely forcing certain combinations.

### Proposed chemistry ratings

- Low.
- Moderate.
- High.
- Exceptional.

Exact numerical calculations remain provisional.

### Special combination abilities

Certain class combinations may unlock unique abilities.

Examples:

Barbarian + Paladin:
- Divine Fury.

Wizard + Assassin:
- Arcane Execution.

Paladin + Ranger + Druid:
- Guardian of the Wild.

These are proposed abilities, not finalized content.

### Guardian of the Wild

When the hero successfully blocks an attack, they receive a temporary nature-infused blessing.

Their next Ranger technique may deal additional damage, or their next Druid restoration spell may receive increased effectiveness.

This is a combination ability, not a mythic ability.

### Important technical requirement

Class chemistry should be defined through data rather than hardcoded combinations.

Adding a new class should not require rewriting the chemistry system.

---

# PART VI — LEVELING AND SKILL TREES

## 7. Character Progression

The game uses:

- Hero level.
- Experience points.
- Skill points.
- Individual class mastery.
- Weapon mastery.
- Ability unlocks.

### Proposed level cap

100.

This is provisional and can change during balancing.

### Skill points

Players earn skill points as they level up.

Additional skill points may be available through quests and important milestones.

The preliminary proposal is approximately one point per level, with extra points from selected rewards.

### Class mastery

Hero level and class mastery are separate.

A high-level hero switching to an unfamiliar class should not immediately receive that class's strongest abilities.

Class mastery determines eligibility for advanced abilities.

Skill points determine which eligible abilities the player actually unlocks.

### Skill persistence

Skill investments remain saved permanently unless the game later introduces an intentional respec system.

Switching classes does not erase progress.

### Weapon mastery

Weapon skill trees are separate from class skill trees.

Examples:

- Sword Mastery.
- Shield Mastery.
- Axe Mastery.
- Bow Mastery.
- Staff Mastery.

Equipping a weapon determines which weapon-specific techniques can be used.

Class proficiencies determine access to and effectiveness with weapon types.

A sword ability should not be usable while wielding an incompatible weapon.

---

## 8. Ability Rarity

Abilities progress through five proposed tiers.

| Tier | Proposed Level Range |
|---|---|
| Common | 1–14 |
| Advanced | 15–29 |
| Rare | 30–49 |
| Legendary | 50–74 |
| Mythic | 75–100 |

These are proposed progression ranges, not finalized balancing values.

Unlocks may additionally require:

- Class mastery.
- Skill-point investment.
- Previous abilities.
- Special quests.
- Other progression milestones.

### Mythic abilities — Confirmed Rule

**Mythic abilities can only be used when their associated class is the player's primary class.**

Players may invest skill points into secondary classes and unlock mythic abilities in those classes.

However, the unlocked mythic abilities remain unusable until the corresponding class becomes the primary class.

Example:

Primary: Paladin  
Secondary: Ranger  
Secondary: Druid

Available:
- Unlocked Paladin mythic abilities.

Unavailable:
- Ranger mythic abilities.
- Druid mythic abilities.

If Ranger later becomes primary, unlocked Ranger mythic abilities become available and Paladin mythic abilities become temporarily unavailable.

No skill points or unlocks are lost.

### Mythic ability philosophy

Mythic abilities should feel substantially different from ordinary abilities.

They may feature:

- Unique combat mechanics.
- Powerful status effects.
- Major battlefield changes.
- Distinctive animations.
- Cinematic camera sequences.
- High MP costs or other limitations.

Mythic abilities should not simply be basic attacks with larger damage numbers.

---

# PART VII — FIRST PROTOTYPE CHARACTER

## 9. The Verdant Guardian

Our first playable prototype will focus on the user's preferred character build.

**Primary Class:** Paladin  
**Secondary Class 1:** Ranger  
**Secondary Class 2:** Druid  
**Weapon:** One-handed sword  
**Off-hand:** Shield

Working build name: The Verdant Guardian.

This name describes the build and is not necessarily an in-game class title.

### Character identity

A holy defensive warrior who combines:

- Paladin protection.
- Sword-and-shield combat.
- Ranger precision.
- Druid nature magic.
- Healing and regeneration.
- Companion coordination.

The character should be durable and versatile.

They should not necessarily have the highest raw damage output, but should excel at surviving difficult encounters and using complementary abilities.

### Visual identity

- Stylized fantasy knight.
- One-handed sword.
- Shield.
- Plate armor.
- Green or nature-inspired accents.
- Holy and nature magic effects.
- Visible equipment changes.

### Starting abilities

**Sword Slash**
- Basic physical sword attack.
- No MP cost.

**Shield Bash**
- Physical damage.
- Chance to stun.

**Sacred Strike**
- Holy-enhanced sword attack.
- Consumes MP.

**Hunter's Mark**
- Applies a mark to an enemy.
- Improves subsequent attacks against that target.

**Thornbind**
- Nature damage.
- Chance to immobilize the enemy.

**Regrowth**
- Restores HP over multiple turns.

Additional early abilities may include:

- Divine Guard.
- Holy Light.
- Evasive Step.
- Barkskin.
- Nature's Blessing.

### Sword progression

Proposed techniques:

1. Sword Slash.
2. Riposte.
3. Radiant Edge.
4. Guardian's Assault.

### Shield progression

Create a separate Shield Mastery tree supporting:

- Blocking.
- Damage reduction.
- Shield Bash.
- Counterattacks.
- Defensive passives.

### Paladin mythic ability

Working name: Divine Judgment.

Only usable while Paladin is the primary class.

### Ranger mythic ability

Working name: Celestial Arrow.

Can be unlocked while Ranger is secondary but cannot be used unless Ranger becomes primary.

### Druid mythic ability

Working name: Nature's Wrath.

Can be unlocked while Druid is secondary but cannot be used unless Druid becomes primary.

These names and specific effects may change.

---

# PART VIII — COMBAT SYSTEM

## 10. Dynamic Turn-Based Combat

Combat is fully turn-based, with cinematic 3D presentation.

The underlying system should feel familiar to Dragon Quest IX players while presenting actions more dynamically.

### Standard combat commands

- Attack.
- Weapon Skills.
- Spells.
- Items.
- Defend.
- Companion.

### Attack

Performs a basic attack using the currently equipped weapon.

### Weapon Skills

Opens a submenu of learned techniques compatible with the equipped weapon.

### Spells

Opens a dedicated spell submenu.

Spells consume MP.

The spell list depends on:

- Equipped classes.
- Learned abilities.
- Class mastery.
- Primary-class mythic restrictions.

### Items

Allows consumable item use during battle.

### Defend

Reduces incoming damage and may interact with defensive passives or class chemistry.

### Companion

Allows selection of the companion's general combat behavior.

### Turn order

Agility or speed influences action order.

The player selects their intended actions and the game resolves the turn.

The exact turn-order formula remains to be balanced.

### Combat presentation

Characters should:

- Move toward enemies when performing melee attacks.
- Perform readable weapon animations.
- React to damage.
- Block with shields.
- Cast spells with distinct effects.
- Return to their combat positions when appropriate.

The camera should:

- Establish the battlefield.
- Focus on the acting character.
- Follow significant attacks.
- Highlight spellcasting.
- Emphasize powerful abilities.
- Return to a readable tactical view.

### Combat accessibility

Include settings for:

- Normal animation speed.
- Faster battle animations.
- Skipping lengthy animations when appropriate.

Ordinary encounters should remain efficient.

### Technical principle

Combat calculations must be independent of animation playback.

Damage, status effects, MP costs, and victory conditions should not rely on a particular animation completing correctly.

Animations display combat outcomes rather than determine the rules.

---

# PART IX — MAGIC SYSTEM

## 11. MP-Based Spellcasting

Magic uses MP (Magic Points).

Each spell has an MP cost.

The player accesses spells through a dedicated combat submenu.

### Spell categories

The game should support categories such as:

- Holy.
- Protection.
- Healing.
- Arcane.
- Fire.
- Ice.
- Lightning.
- Nature.
- Earth.
- Shadow.
- Curses.
- Restoration.

These categories should be expandable.

### Spell progression

Higher-level spells should be:

- More powerful.
- More specialized.
- More visually impressive.
- More expensive or strategically demanding.

### Mythic magic

Mythic spells should be exceptionally powerful and restricted by the primary-class rule.

Additional cooldowns for mythic spells are a possible balancing mechanic, but are not yet finalized.

---

# PART X — COMPANION SYSTEM

## 12. Companion Philosophy

The player controls one hero and has one active creature companion.

The companion assists with combat and exploration without requiring the same level of micromanagement as the hero.

### Companion selection — Confirmed Structure

Players may select a maximum of two companions during an entire playthrough.

**First selection:**

After completing the introductory quest, the player chooses one of six available companions.

**Second selection:**

During the postgame, the player chooses one additional companion from the five remaining options.

The player can eventually own two companions but only one may actively accompany the hero at a time.

The other four companions remain unavailable during that playthrough.

Selections are intended to be permanent.

### Six companions

**1. Dire Wolf**

Role:
- Fast physical attacker.
- Bleeding effects.
- Follow-up attacks.
- Offensive support.

Travel:
- Rideable.

**2. Griffin**

Role:
- Mobility.
- Wind attacks.
- Evasion.
- Aerial strikes.

Travel:
- Rideable.
- Potential advanced aerial movement.

**3. Dragon**

Role:
- Elemental damage.
- Breath attacks.
- Magical resistance.

Travel:
- Rideable once sufficiently developed.

**4. Warhorse**

Role:
- Defensive support.
- Charging attacks.
- Protection.
- Mobility.

Travel:
- Rideable.

**5. Spirit Fox**

Role:
- Healing.
- Magical support.
- Cleansing.
- Illusions.

Travel:
- Grants a magical movement enhancement instead of being mounted.

**6. Golem**

Role:
- Damage absorption.
- Protection.
- Earth attacks.
- Enemy disruption.

Travel:
- Grants a movement enhancement instead of being mounted.

### Companion combat

Companions have simplified combat behavior.

Commands:

**Attack**
- Prioritize offensive actions.

**Support**
- Prioritize healing, buffs, and assistance.

**Defend**
- Prioritize protection and damage reduction.

Companions automatically select appropriate actions according to their chosen behavior.

### Companion skill trees

Each companion should have a relatively small skill tree.

Proposed structure:

- Three branches.
- Approximately four abilities per branch.

Example Dire Wolf branches:

- Predator.
- Guardian.
- Pack Bond.

Companions should level up and gain meaningful abilities, but their progression should remain simpler than the hero's.

### Companion chemistry

Certain companions may complement specific hero classes.

Examples:

- Dire Wolf with Barbarian or Ranger.
- Spirit Fox with Wizard or Healer.
- Golem with Paladin or Warrior.

These should be incentives, not requirements.

### Companion travel

Every companion provides access to an equivalent baseline travel-speed enhancement.

Rideable companions use mounted animations.

Non-rideable companions provide magical or physical movement enhancements while following the hero.

No companion should be objectively worse at basic travel speed.

Unique exploration abilities may exist, but selecting a particular companion must not make the main story impossible to complete.

### Postgame companion

The second companion should begin at an appropriate progression level so it can participate in postgame content without excessive grinding.

---

# PART XI — EQUIPMENT AND ARMOR

## 13. Equipment System

The hero has independent equipment slots:

1. Weapon.
2. Shield / Off-hand.
3. Helmet.
4. Chest armor.
5. Gauntlets.
6. Pants.
7. Boots.
8. Accessory.

Accessories may include:

- Necklaces.
- Talismans.
- Rings.

The exact number of simultaneously equipped accessories can be decided later.

### Equipment effects

Equipment may modify:

- Attack.
- Defense.
- Magical attack.
- Magical defense.
- HP.
- MP.
- Agility.
- Evasion.
- Critical chance.
- Elemental resistance.
- Status resistance.
- Special passive effects.

### Class restrictions

Armor and weapons should have class-specific restrictions or proficiencies.

Primary class strongly influences equipment identity.

Secondary classes may provide limited hybrid options.

### Visual equipment

**Equipped armor must visibly change the character.**

The player should see changes when equipping:

- Helmets.
- Chest pieces.
- Gauntlets.
- Pants.
- Boots.
- Weapons.
- Shields.

Accessories may have visual effects when appropriate.

### Equipment progression

Armor and weapons improve throughout the game.

Progression should include:

- Common equipment.
- Improved equipment.
- Rare equipment.
- Legendary equipment.
- Mythic equipment.

Class-specific sets may provide additional bonuses.

### Armor sets

Certain armor sets may interact with class chemistry.

Example:

A Barbarian / Warrior / Paladin combination might eventually unlock an appropriate legendary armor set.

The exact requirements and bonuses remain to be designed.

### Technical requirement

Separate equipment data from visual assets.

An equipment item should define:

- Item ID.
- Equipment slot.
- Compatible classes.
- Stats.
- Special effects.
- Visual asset reference.
- Rarity.
- Description.

Changing equipment must update both stats and appearance.

---

# PART XII — ENEMIES AND DIFFICULTY

## 14. Enemy Progression

Enemies should become progressively more sophisticated as the player advances.

### Early-game monsters

- Basic attacks.
- Limited abilities.
- Simple patterns.
- Clear weaknesses.

### Midgame monsters

- Elemental attacks.
- Status effects.
- Defensive techniques.
- Counterattacks.
- More intelligent targeting.

### Late-game monsters

- Advanced spellcasting.
- Complex attack combinations.
- Powerful resistances.
- Specialized fighting styles.
- Coordinated tactics.

### Endgame and postgame monsters

- Legendary fighting techniques.
- Mythic spells.
- Powerful defensive mechanics.
- Multi-stage encounters.
- More demanding strategic challenges.

Difficulty should not depend exclusively on larger HP and damage numbers.

Players should need to understand enemy behavior, resistances, and their own class abilities.

---

# PART XIII — MONSTER MASTERY AND AUTO-BATTLE

## 15. Monster Mastery

Each enemy species has an independent defeat counter.

After defeating that species 10 times through normal combat, the player unlocks the option to auto-battle that species.

### Confirmed rules

- Ten normal victories unlock auto-battle.
- Auto-battle is optional.
- Traditional combat remains available.
- Auto-battle occurs directly from the overworld.
- The game does not load the normal cinematic battle scene.
- Results appear within seconds.
- Auto-battle does not guarantee victory.
- Bosses and special story encounters cannot be auto-battled.

### Auto-battle simulation

The outcome should account for:

- Hero level.
- Hero stats.
- Current HP and MP.
- Equipment.
- Weapon mastery.
- Learned abilities.
- Class chemistry.
- Companion stats.
- Companion behavior.
- Enemy level.
- Enemy abilities.
- Enemy defenses and resistances.

Use the same underlying combat calculations as normal battles.

Do not implement auto-battle as a separate arbitrary victory-percentage formula.

Instead, simulate combat turns without rendering their animations.

### Resource consumption

Auto-battles can consume:

- Hero HP.
- Hero MP.
- Companion HP.
- Other applicable combat resources.

### Rewards

Successful auto-battles award the same potential rewards as normal battles:

- Experience.
- Gold.
- Item drops.
- Relevant progression rewards.

### Auto-battle results

Display a short results window.

Example:

Victory — Forest Goblin

XP gained: +85  
Gold gained: +24  
HP lost: 8  
MP spent: 3  
Items obtained: None

These are example values, not finalized balance.

### Danger indicator

Before auto-battle, display a general risk assessment.

Suggested categories:

- Low.
- Moderate.
- High.
- Extreme.

This should reflect the current hero and companion's likely performance.

Warn players when defeat is a significant possibility.

### Defeat

Auto-battle defeat should follow the same underlying defeat rules as ordinary combat.

The game's precise death and recovery penalties remain to be designed.

### Mixed encounters

How mastery works when multiple different enemy species appear in one encounter remains an open design question.

Do not silently invent a permanent rule without documenting it.

---

# PART XIV — EXPLORATION

## 16. World Exploration

The game uses third-person 3D exploration.

The player should be able to:

- Move through environments.
- Control the camera.
- Interact with NPCs.
- Encounter visible enemies.
- Explore towns and wilderness.
- Enter buildings and dungeons.
- Complete quests.
- Collect equipment and items.
- Travel with a companion.

### Introductory area

The introductory area already exists.

Preserve its existing layout and quest content unless changes are necessary.

Improve:

- Visual quality.
- Environment composition.
- Lighting.
- Materials.
- Character scale.
- Movement responsiveness.
- Camera behavior.
- Interaction clarity.
- Enemy presentation.
- Quest navigation.
- Performance.

### Exploration-to-combat transition

When the player encounters a monster:

1. Identify the encounter.
2. Check whether monster mastery permits auto-battle.
3. Present applicable combat options.
4. Enter the normal battlefield or resolve the auto-battle.
5. Apply the result.
6. Return to exploration.

Ensure scene transitions do not duplicate enemies, lose progress, or incorrectly reset character state.

---

# PART XV — UI AND USER EXPERIENCE

## 17. User Interface

The current UI needs significant improvement.

Create a coherent visual language for the entire game.

### Style goals

- Fantasy-inspired.
- Clean and readable.
- Visually polished.
- Consistent typography.
- Consistent spacing.
- Clear hierarchy.
- Responsive layouts.
- Controller-friendly architecture where practical.

### Required interface systems

**Exploration HUD**
- Hero HP.
- Hero MP.
- Relevant companion status.
- Quest objective.
- Interaction prompts.

**Combat HUD**
- Hero HP/MP.
- Companion HP.
- Enemy information.
- Battle commands.
- Status effects.
- Damage and healing feedback.

**Character Menu**
- Level.
- XP.
- Stats.
- Primary class.
- Secondary classes.
- Equipment.
- Learned abilities.

**Skill Tree Menu**
- Class selection.
- Available skill points.
- Skill prerequisites.
- Unlocked skills.
- Locked skills.
- Mythic ability restrictions.

**Inventory**
- Item categories.
- Equipment stats.
- Comparison between equipped and selected items.
- Item descriptions.

**Equipment Screen**
- Visible character preview.
- Equipment slots.
- Stat changes.
- Class restrictions.

**Companion Menu**
- Companion information.
- Level.
- Skill tree.
- Combat behavior.
- Active companion selection when available.

**Monster Mastery**
- Enemy species.
- Defeat counts.
- Auto-battle unlock status.

**Quest Log**
- Current objectives.
- Completed objectives.
- Relevant quest information.

**Settings**
- Audio.
- Graphics.
- Controls.
- Animation speed.
- Other accessibility options.

### UI implementation principle

Create reusable UI components.

Do not individually hardcode every spell, skill, equipment item, or enemy into a unique menu.

Menus should populate from game data.

---

# PART XVI — ANIMATION REQUIREMENTS

## 18. Animation System

Animations are currently an important area requiring improvement.

### Exploration animations

Eventually support:

- Idle.
- Walking.
- Running.
- Turning.
- Interacting.
- Companion following.
- Mounting.
- Mounted travel.
- Unmounted movement enhancements.

### Combat animations

Support:

- Combat idle.
- Sword attack.
- Shield Bash.
- Blocking.
- Damage reaction.
- Spellcasting.
- Healing.
- Buff activation.
- Defeat.
- Victory.

### Advanced animations

Later include:

- Weapon-specific fighting styles.
- Class-specific combat techniques.
- Legendary abilities.
- Mythic abilities.
- Companion special attacks.
- Cinematic boss attacks.

### Technical requirements

Use a reusable animation state system.

Animations should be organized by character action rather than tightly coupled to individual combat scripts.

Support blending between animations where appropriate.

Avoid abrupt transitions, sliding feet, weapon clipping, and incorrect character facing.

Combat effects should synchronize visually with the relevant attack or spell.

---

# PART XVII — AUDIO

## 19. Sound and Music

The game should eventually include:

- Exploration music.
- Battle music.
- Boss music.
- Victory music.
- Weapon sounds.
- Shield impacts.
- Spell effects.
- Monster sounds.
- UI sounds.
- Environmental ambience.

Use original or appropriately licensed audio assets.

Audio should reinforce combat impact and atmosphere.

For the introductory prototype, prioritize basic combat, UI, and environmental audio rather than a complete soundtrack.

---

# PART XVIII — TECHNICAL ARCHITECTURE

## 20. Long-Term Code Requirements

The first quest should be implemented using architecture suitable for the complete game.

### Core principles

**Data-driven content**

Classes, enemies, spells, equipment, companions, and abilities should be defined as reusable data.

**Reusable scenes**

Use reusable Godot scenes for characters, enemies, interactable objects, UI components, and effects.

**Separated responsibilities**

Separate:

- Combat calculations.
- Combat presentation.
- Character progression.
- Class definitions.
- Equipment management.
- Inventory.
- Quest progression.
- Companion behavior.
- Enemy AI.
- Save/load.
- UI presentation.

**Stable identifiers**

Use stable IDs for:

- Classes.
- Abilities.
- Equipment.
- Enemy species.
- Companions.
- Quests.
- Quest objectives.

Do not use display names as permanent save identifiers.

**Single source of truth**

Normal combat and auto-battle must share combat rules.

All menus should read the same character, inventory, and progression data.

**Expandable content**

Adding a new class, spell, monster, or item should primarily involve creating data and associated assets rather than rewriting central systems.

### Suggested Godot structure

Adapt this to the existing project rather than forcing an unnecessary reorganization.

```text
res://
  scenes/
    world/
    characters/
    enemies/
    combat/
    companions/
    ui/
    quests/

  scripts/
    core/
    combat/
    progression/
    equipment/
    companions/
    quests/
    save/

  data/
    classes/
    abilities/
    weapons/
    armor/
    enemies/
    companions/
    quests/

  assets/
    characters/
    equipment/
    monsters/
    environments/
    animations/
    effects/
    audio/

  tests/
```

### Suggested systems

- GameState.
- CharacterProgression.
- ClassManager.
- SkillTreeManager.
- AbilityManager.
- CombatResolver.
- BattleController.
- EnemyAI.
- EquipmentManager.
- InventoryManager.
- CompanionManager.
- MonsterMasteryManager.
- QuestManager.
- SaveManager.

These are conceptual responsibilities, not mandatory script names.

Avoid creating unnecessary managers if a simpler design fits the existing code.

### Save system

The game must eventually save:

- Hero level and XP.
- HP and MP.
- Stats.
- Primary class.
- Secondary classes.
- Class mastery.
- Skill-point investments.
- Unlocked abilities.
- Equipment.
- Inventory.
- Gold.
- Companion choices.
- Companion progression.
- Monster mastery counters.
- Quest progression.
- World progression.
- Relevant player location.

Use versioned save data and provide a migration strategy when save formats change.

---

# PART XIX — CURRENT VERTICAL SLICE

## 21. First Quest and Introductory Area

The current development priority is a short, polished playthrough of the existing first quest and introductory area.

We do not need to build the entire RPG immediately.

However, the systems used in this introductory experience should be reusable in the complete game.

### Desired player experience

The player should be able to:

1. Start the game.
2. Enter the existing introductory area.
3. Control the hero smoothly.
4. Explore a visually coherent environment.
5. Interact with existing quest elements.
6. Encounter an early monster.
7. Enter cinematic turn-based combat.
8. Use sword-and-shield attacks.
9. Access the Spells submenu.
10. Cast Paladin, Ranger, or Druid abilities where unlocked.
11. Receive XP and gold after victory.
12. Progress through the existing quest.
13. View character progression.
14. Equip or inspect equipment.
15. Complete the introductory quest.
16. Reach the point where the first companion selection can occur.

The exact story, dialogue, and quest objectives should be preserved from the existing project. Do not invent replacements without approval.

### Companion selection

After the introductory quest, the full game should allow the player to select one of six companions.

For the first prototype, this can initially be a simple selection interface with placeholder models.

The companion framework should support all six even if only one is fully animated at first.

### First combat encounter

Use a simple early-game enemy such as the Forest Goblin, or preserve an existing enemy from the project if more appropriate.

The enemy should:

- Have visible HP.
- Use basic attacks.
- Take damage.
- Be defeatable.
- Award rewards.
- Increment its species defeat counter.

### First skill tree

Implement functional Paladin, Ranger, and Druid progression.

The initial skill tree can contain a small number of skills, but the data structure must support future expansion.

### First equipment system

Implement:

- Sword.
- Shield.
- Chest armor.

These must visibly change the character where practical.

All eight equipment slots should exist in the underlying system even if their visuals are not finished yet.

### First companion system

Implement a basic companion that:

- Follows the hero.
- Participates in combat.
- Uses simple automated behavior.
- Can level up.
- Has an expandable skill tree.

The wolf may be used as the first fully implemented companion, but the player should not be permanently forced to choose the wolf.

### First monster mastery implementation

Track species victories.

Unlock auto-battle after 10 normal victories.

Use the same combat rules for auto-battle simulations.

Display XP, gold, and HP/MP changes.

---

# PART XX — DEVELOPMENT PRIORITIES

## 22. Recommended Implementation Order

### Phase 0 — Audit and stabilize the existing project

Before adding features:

- Inspect all existing code.
- Identify functioning systems.
- Identify errors and incomplete features.
- Review current scenes.
- Review art and animation assets.
- Review UI.
- Document the current project structure.
- Create a safe development branch or backup.

Do not destroy working progress.

**Deliverable:** Project audit and prioritized development plan.

### Phase 1 — Improve the introductory experience

Focus on:

- Player movement.
- Camera controls.
- Environment presentation.
- Lighting.
- Character appearance.
- Basic animation quality.
- Quest interactions.
- UI readability.

**Deliverable:** A stable, visually coherent introductory area.

### Phase 2 — Build reusable combat architecture

Implement:

- Turn-based combat state management.
- Combatant stats.
- Damage calculations.
- Speed-based turn order.
- Ability targeting.
- MP costs.
- Status effects.
- Victory and defeat handling.
- Combat rewards.

**Deliverable:** A reliable battle system independent of animations.

### Phase 3 — Improve cinematic combat

Implement:

- Attack animations.
- Spellcasting.
- Blocking.
- Damage reactions.
- Camera transitions.
- Damage numbers.
- Combat effects.
- Animation speed settings.

**Deliverable:** A visually satisfying, playable combat encounter.

### Phase 4 — Character progression

Implement:

- XP.
- Leveling.
- Skill points.
- Class mastery.
- Paladin, Ranger, and Druid skill trees.
- Primary and secondary class rules.
- Mythic ability restrictions.

**Deliverable:** Functional progression that can support all 12 classes.

### Phase 5 — Equipment

Implement:

- Equipment inventory.
- Independent equipment slots.
- Stat modifications.
- Class restrictions.
- Visible equipment changes.

**Deliverable:** Reusable modular equipment system.

### Phase 6 — Companion framework

Implement:

- Companion selection data.
- Companion following.
- Companion combat behavior.
- Companion progression.
- Basic skill trees.
- Travel enhancement framework.

**Deliverable:** A functioning first companion.

### Phase 7 — Monster mastery

Implement:

- Species defeat counters.
- Ten-victory unlock.
- Overworld auto-battle selection.
- Shared combat simulation.
- Danger assessment.
- Rewards and resource costs.

**Deliverable:** Functional optional auto-battle.

### Phase 8 — Vertical slice polish

Improve:

- Quest flow.
- Visual consistency.
- UI transitions.
- Animation quality.
- Audio feedback.
- Performance.
- Save/load reliability.
- Bugs.
- Gameplay balance.

**Deliverable:** A polished, short first-quest playthrough.

---

# PART XXI — TESTING AND QUALITY REQUIREMENTS

## 23. Testing

Implement tests where practical for:

- Damage calculations.
- Turn order.
- MP costs.
- Skill unlock conditions.
- Primary-class mythic restrictions.
- Class switching.
- Equipment stat changes.
- XP and leveling.
- Monster mastery.
- Auto-battle outcomes.
- Quest progression.
- Save/load persistence.

### Important test cases

**Mythic restriction test**

Unlock a Ranger mythic ability while Ranger is secondary.

Confirm that it remains unavailable.

Switch Ranger to primary.

Confirm that it becomes available without reinvesting skill points.

**Equipment test**

Equip a different sword.

Confirm that the visual model and combat stats update correctly.

**Monster mastery test**

Defeat the same species nine times.

Confirm that auto-battle is unavailable.

Defeat it a tenth time.

Confirm that auto-battle becomes available.

**Auto-battle test**

Confirm that the simulation can produce both victories and defeats and applies the correct resource changes.

**Save/load test**

Save the game after gaining XP, unlocking skills, and changing equipment.

Reload.

Confirm that progression remains intact.

**Quest regression test**

Confirm that changes to combat or UI do not break the existing introductory quest.

### Validation

Run available Godot project validation and tests after meaningful changes.

Do not claim functionality has been tested if the necessary runtime or tools are unavailable.

---

# PART XXII — DESIGN QUESTIONS NOT YET FINALIZED

## 24. Open Decisions

The following topics are not yet settled:

- Final game title.
- Main story and world lore.
- Character creation details.
- Exact level cap.
- Exact XP curve.
- Skill-point economy.
- Respec rules.
- Class switching requirements.
- Class chemistry formulas.
- Final spell lists.
- Exact ability damage and MP costs.
- Full weapon mastery trees.
- Mythic ability balancing.
- Armor set bonuses.
- Item rarity probabilities.
- Inventory capacity.
- Gold economy.
- Crafting and upgrading.
- Companion evolution or growth.
- Companion travel unlock requirements.
- Postgame progression.
- Mixed-species auto-battle eligibility.
- Defeat penalties.
- Final boss mechanics.
- Quest structure beyond the introduction.

Do not make irreversible architectural assumptions about these topics.

Use configurable values and extensible systems.

When an unresolved design decision blocks implementation, explain the options and recommend a reasonable default.

---

# PART XXIII — IMMEDIATE CODEX ASSIGNMENT

## 25. What I Want You to Do Now

You are working with an existing Godot 4 project.

The introductory area and first quest have already been started.

The game currently has a basic foundation, but its art, animations, UI, and overall polish need improvement.

Your task is to use this design document as the long-term development direction.

### Step 1 — Inspect the existing project

Review the project structure, scenes, scripts, assets, and current gameplay.

Determine which systems are already implemented and which are incomplete.

Do not assume the existing project matches an earlier prototype specification.

### Step 2 — Produce a technical audit

Explain:

- What currently works.
- What is incomplete.
- What needs refactoring.
- What should be preserved.
- What needs visual improvement.
- What should be implemented next.

### Step 3 — Create a prioritized implementation plan

Focus on making the existing introductory quest a polished, playable vertical slice.

Identify dependencies and recommend a realistic sequence of work.

### Step 4 — Implement the next coherent milestone

After the audit, begin improving the existing project in a controlled manner.

Prioritize reusable systems and visible improvements to the first quest.

Do not attempt to implement all 12 classes, every spell, every companion, and the complete equipment library immediately.

Instead, build the systems using the Paladin / Ranger / Druid prototype and make them expandable.

### Step 5 — Preserve compatibility

Do not unnecessarily rename or delete working scenes, scripts, assets, or quest data.

Avoid breaking save files and existing gameplay.

Document any necessary breaking changes.

### Step 6 — Test changes

Validate the project after each substantial milestone.

Fix errors before proceeding.

### Step 7 — Report results

After completing each development milestone, report:

1. What was implemented.
2. Which files changed.
3. What was tested.
4. What still needs work.
5. Any design decisions made.
6. Recommended next steps.

Do not claim visual polish or gameplay quality has been verified solely through code inspection.

---

# FINAL DEVELOPMENT DIRECTIVE

We are not trying to create a disposable demonstration.

We are developing the foundation of a full fantasy RPG.

The first introductory quest should function as a small but representative version of the eventual game.

**Every major system implemented now should be designed for reuse, extension, and refinement throughout the full project.**

At the same time, avoid unnecessary complexity, speculative infrastructure, or implementing features that the current playable experience does not need.

Preserve the existing project, improve the current gameplay, and build a scalable foundation for everything described above.

Begin by auditing the existing project and recommending the highest-value improvements to the introductory quest.