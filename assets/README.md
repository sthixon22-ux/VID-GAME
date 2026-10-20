# Asset provenance

All assets in this directory are original and generated specifically for Verdant Oath. There are no ripped game assets, third-party art packs, external API dependencies, or purchased assets.

- `textures/*.png`: deterministic surface textures generated with noise and drawn grain, weave, or masonry patterns.
- `portraits/*.svg`: original layered vector portraits of Mira, the hero, the wolf, and the Warden.
- `audio/*.wav`: original synthesized melodies, chord progressions, and sound cues; 22,050 Hz mono PCM. These are simple demo compositions, not recorded orchestral tracks or voice acting.
- `shaders/*.gdshader`: original water-ripple and canopy-wind effects.

Run `python tools/generate_assets.py` to regenerate the textures, portraits and audio (requires Pillow and numpy). Godot only needs the checked-in files. Character and environment meshes are built by `scripts/art.gd`, `scripts/forest.gd` and `scripts/dungeon.gd`. Animation is procedural; the project does not contain professional motion-captured or skinned character animation.
