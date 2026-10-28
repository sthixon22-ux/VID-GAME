# Learned spell and technique effects

Battle tooltips and tree descriptions use the same definitions as combat. Elements multiply damage using each enemy’s affinities; enemy families and affinity values can be inspected by hovering the enemy HP bar. Marked attacks also receive the existing +6 ally damage bonus.

## Progression rules

Class-tree stat bonuses remain permanent. Weapon-tree bonuses apply while using that weapon (or an equipped shield). Trees share the existing point pool, require prerequisites and cost 60 points to complete; there are no level gates. Weapon Freedom still grants permanent class-independent proficiency. Mythic abilities remain usable only while their class is primary.

Damage power is reduced by defense per hit, then adjusted by elemental/family multipliers and criticals where applicable. Elemental class spells use their listed power plus 18% maximum MP and 1.5 per hero level; physical techniques use attack plus listed power. Multi-hit coefficients apply before per-hit defense. Healing adds the healing stat. Boss stun/root resistance halves the new advanced skills’ listed control chance.

Deathmark rolls exactly once after a landed cast, using the same seeded combat RNG as other actions. Its instant KO never applies to story bosses. Auto-battle uses the same resolver, resource costs, defenses and status timers.

## Class trees

| Tree | Learned move | MP | Effect |
|---|---|---:|---|
| Paladin | Holy Light | 7 | Restore 32 HP + healing bonus. Against undead, also deal 18 holy power damage. No weapon required. |
| Paladin | Judgment | 14 | Holy damage; base power +36. Deals 1.8x damage to undead enemies. |
| Paladin | Dawn Avatar | 25 | Holy damage; base power +55. Defense +12 for 3 rounds. Primary-class mythic only; secondary unlocks stay saved. |
| Ranger | Seeking Arrow | 9 | Physical damage; base power +24. Cannot be dodged. |
| Ranger | Hawkstrike | 14 | Wind damage; base power +36. Deals 1.75x damage to flying enemies. |
| Ranger | Wild Hunt | 25 | Wind damage; base power +55. Deals 1.8x damage to beast enemies. Cannot be dodged. Primary-class mythic only; secondary unlocks stay saved. |
| Druid | Briarstorm | 9 | Nature damage; base power +24. 50% chance to root for one turn (bosses resist half). |
| Druid | Grove Renewal | 14 | Restore 60 HP + healing bonus and renew 12 HP for 4 rounds. Defense +5 for 4 rounds. |
| Druid | Ancient Grove | 25 | Restore 160 HP + healing bonus. Primary-class mythic only; learned with skill points, no level gate. Also restore 100 companion HP (does not revive). |
| Warrior | Cleave | 9 | Physical damage; base power +24. Enemy defense -4 for 3 rounds. |
| Warrior | Veteran Assault | 14 | Physical damage; base power +36. 2 strikes at 62% power each; defense applies per strike. Bonus damage +16 against armor-broken or weakened targets. |
| Warrior | Legendary Onslaught | 25 | Physical damage; base power +55. 4 strikes at 44% power each; defense applies per strike. Primary-class mythic only; secondary unlocks stay saved. |
| Barbarian | Sundering Roar | 9 | Physical damage; base power +24. Enemy defense -7 for 3 rounds. |
| Barbarian | Titan Swing | 14 | Physical damage; base power +36. Ignores 50% defense. Costs 8 HP (cannot self-KO). |
| Barbarian | Worldbreaker | 25 | Physical damage; base power +65. Enemy defense -10 for 3 rounds. Ignores 100% defense. Primary-class mythic only; secondary unlocks stay saved. |
| Wizard | Arcane Barrage | 9 | Arcane damage; base power +24. 3 strikes at 48% power each; defense applies per strike. |
| Wizard | Astral Rupture | 14 | Arcane damage; base power +36. Ignores 100% defense. |
| Wizard | Arcane Cataclysm | 25 | Arcane damage; base power +60. 3 strikes at 55% power each; defense applies per strike. Primary-class mythic only; secondary unlocks stay saved. |
| Sorcerer | Lightning Lance | 9 | Lightning damage; base power +24. 35% chance to stun for one turn (bosses resist half). |
| Sorcerer | Inferno | 14 | Fire damage; base power +36. Burn: 10 fire damage for 3 rounds. |
| Sorcerer | Elemental Tempest | 25 | Lightning damage; base power +65. Burn: 12 fire damage for 3 rounds. Primary-class mythic only; secondary unlocks stay saved. |
| Healer | Greater Mending | 9 | Restore 65 HP + healing bonus. Defense +6 for 2 rounds. |
| Healer | Sanctuary | 14 | Restore 100 HP + healing bonus. Defense +12 for 3 rounds. Also restore 40 companion HP (does not revive). |
| Healer | Miracle | 25 | Restore 180 HP + healing bonus. Primary-class mythic only; learned with skill points, no level gate. Revive the active companion with 55 HP, or restore 55 companion HP. |
| Rogue | Opportunist Strike | 9 | Physical damage; base power +24. Bonus damage +22 against marked, poisoned, bleeding or burning targets. |
| Rogue | Dancing Blades | 14 | Physical damage; base power +36. 3 strikes at 48% power each; defense applies per strike. Dexterity +8 for 2 rounds. |
| Rogue | Phantom Dance | 25 | Physical damage; base power +58. 3 strikes at 55% power each; defense applies per strike. Dexterity +20 for 3 rounds. Primary-class mythic only; secondary unlocks stay saved. |
| Assassin | Deathmark | 9 | Physical damage; base power +24. 1% instant KO on a landed hit. Bosses are immune; otherwise deals normal damage. |
| Assassin | Eclipse Cut | 14 | Physical damage; base power +36. Ignores 25% defense. Bonus damage +30 when enemy HP is below 35%. |
| Assassin | Nightfall | 25 | Shadow damage; base power +65. Bonus damage +35 against marked, poisoned, bleeding or burning targets. Primary-class mythic only; secondary unlocks stay saved. |
| Monk | Rising Palm | 9 | Physical damage; base power +24. 65% chance to stun for one turn (bosses resist half). |
| Monk | Hundred Fists | 14 | Physical damage; base power +36. 5 strikes at 32% power each; defense applies per strike. |
| Monk | Enlightenment | 25 | Physical damage; base power +55. Ignores 100% defense. Defense +10 for 3 rounds. Primary-class mythic only; secondary unlocks stay saved. |
| Necromancer | Soul Rend | 9 | Shadow damage; base power +24. Recover 5 MP on a hit. |
| Necromancer | Grave Harvest | 14 | Shadow damage; base power +36. Restore 75% of damage dealt as HP. Bonus damage +20 when enemy HP is below 35%. |
| Necromancer | Requiem | 25 | Shadow damage; base power +60. Restore 100% of damage dealt as HP. Primary-class mythic only; secondary unlocks stay saved. |

## Weapon trees

| Tree | Learned move | MP | Effect |
|---|---|---:|---|
| sword | Dragon Slash | 5 | Sword strike: attack +9 physical power. Double damage against draconic enemies. Requires a sword. |
| sword | Thunder Strike | 8 | Lightning damage; base power +24. 40% chance to stun for one turn (bosses resist half). |
| shield | Guardian Reprisal | 8 | Physical damage; base power +20. Defense +8 for 3 rounds. |
| axe | Rupturing Cleave | 8 | Physical damage; base power +20. Enemy defense -9 for 3 rounds. Bleed: 5 damage for 3 rounds. |
| greatsword | Cyclone Blade | 8 | Physical damage; base power +20. 2 strikes at 70% power each; defense applies per strike. |
| hammer | Seismic Smash | 8 | Physical damage; base power +20. 75% chance to stun for one turn (bosses resist half). |
| spear | Dragon Thrust | 8 | Physical damage; base power +20. Deals 2x damage to draconic enemies. |
| bow | Piercing Volley | 8 | Physical damage; base power +20. 3 strikes at 55% power each; defense applies per strike. Cannot be dodged. |
| dagger | Twin Crescents | 8 | Physical damage; base power +20. 2 strikes at 70% power each; defense applies per strike. Bonus damage +8 against marked, poisoned, bleeding or burning targets. |
| staff | Runic Rupture | 8 | Arcane damage; base power +20. Recover 6 MP on a hit. |
| wand | Prismatic Ray | 8 | Holy damage; base power +20. Ignores 100% defense. |
| scythe | Soul Reaping | 8 | Shadow damage; base power +20. Restore 60% of damage dealt as HP. |
| claws | Tiger Flurry | 8 | Physical damage; base power +20. 3 strikes at 55% power each; defense applies per strike. Bleed: 7 damage for 3 rounds. |
| unarmed | Rising Knee | 8 | Physical damage; base power +20. Ignores 75% defense. 50% chance to stun for one turn (bosses resist half). |
