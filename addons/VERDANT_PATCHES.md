# Godot VRM addon — local compatibility patch

Upstream: V-Sekai/godot-vrm, commit `e15199f980064028bfa4fbee5e70dddb82dd55c3`.
Both `addons/vrm` and `addons/Godot-MToon-Shader` retain their upstream MIT license files.

In `vrm/1.0/VRMC_vrm.gd` and `vrm/vrm_extension.gd`, the already-processed guard now uses `GLTFState.has_meta("vrm_already_processed")` / `set_meta`, instead of reading a nonexistent additional-data dictionary key. Godot 4.6.3 logs an engine dictionary error for the original first read. The metadata key is a valid identifier (no slash). Only this guard was changed; VRM constraints, materials, export and spring implementation remain upstream code.

Both included VRM files were cleanly reimported after this patch. The addon is enabled only to supply import/preview support; production scenes and models are unchanged. Do not assume constraint-heavy VRM models retarget correctly without individual visual checks: upstream documents constraint/retargeting limitations, and the Twist sample exhibits sleeve/twist artifacts in this lab.
