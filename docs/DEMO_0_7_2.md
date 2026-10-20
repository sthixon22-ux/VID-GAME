# Demo 0.7.2

- Weapons use the union of primary and both secondary class proficiencies (existing rule, now covered explicitly across all classes and both secondary positions).
- Buying/owning any weapon unlocks forest and Moonleaf-guard combat. Neither Mira, chest armor nor keeping the weapon equipped is required. Shops automatically equip purchased items; defeated heroes must still recover.
- Only the cheapest compatible first weapon is protected from optional spending. Armor is optional; potions can be purchased whenever the weapon reserve remains covered.
- Hover or keyboard-focus shop weapons for a rotating 3D model, price, stats and class compatibility. Previewing does not mutate saved hero state. Models match the existing equipped weapon designs.
- Existing saves remain compatible; no migration or new adventure required. Story objectives still govern shrine progression.

Validation: Godot 4.6.3; 714 assertions pass across run (61), presentation (62), reliability (19), demo (160), progression (296), layout (6) and shop_flow (110). The shop_flow scene also passes rendered at 960×540 using the Compatibility renderer with a visible, bounded preview and no runtime errors. The virtual display reports unsupported V-Sync as an environment warning. Headless editor import reports sandbox socket restrictions; no script/parse errors.
