# moorfall-assets

Assets 3D (CC0) du jeu [Moorfall](https://github.com/Dallolz/moorfall), servis au navigateur via
`raw.githubusercontent.com` (CORS ouvert).

- `characters/` — personnages de base (rig Universal, style Unreal : `pelvis`, `spine_01`, …)
- `outfits/` — pièces de tenues modulaires (même rig, composées sur un squelette commun)
- `animations/` — bibliothèques d'animations (clips partagés, ciblage des bones par nom)
- `enemies/` — créatures du bestiaire à **rig propre** (clips embarqués dans chaque GLB,
  filtrés/compactés par `tools/pack_mob.mjs` du repo du jeu)

Sources (toutes CC0, voir LICENSE.md) :
- Quaternius Universal Rig ecosystem — personnages, tenues, animations
- KayKit (Kay Lousberg), Character Pack: Skeletons — `enemies/Skeleton_*.glb`
- Kenney Nature Kit — `env/*.glb` (props instanciés, teintés au runtime)
- Quaternius Ultimate Monsters + Animated Animals — `enemies/*.glb` (récupérés via poly.pizza)
