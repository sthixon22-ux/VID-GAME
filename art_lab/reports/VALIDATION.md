# Art-lab validation results

Environment: Godot 4.6.3, Linux; actual rendered review on OpenGL Compatibility / Mesa llvmpipe / virtual X11. Tests use isolated `XDG_DATA_HOME` directories. Windows and production GPU performance have not been certified.

| Validation | Result |
|---|---|
| Fresh-cache project import, copied project without `.godot` | Passed; no script, import or resource errors |
| Native `.vrm` reimport after metadata-guard compatibility patch | Both models passed; no remaining dictionary/metadata diagnostics |
| Art-lab integration suite | **75 checks, zero failures** |
| Nine unchanged gameplay suites with new import plugins enabled | **985 checks, zero failures** |
| Total automated checks | **1,060 checks, zero failures** |
| Rendered comparison capture | **16 captures**, no script/runtime/shader errors |
| Pinned third-party source/addon hash verification | All 104 recorded download files verified |
| Production resource integrity | All captured production script, scene, model, texture and gameplay-data SHA-256 hashes unchanged |

The software display reports that VSync mode cannot be changed; this is a display-driver warning, not an asset import failure. Initial development exposed and fixed the addon's missing additional-data-key diagnostic. The final fresh import and reimport logs have none of those errors.

The 75 lab checks cover the three visible character rigs; six real motions each; retarget tracks resolving existing bones; changing actual bone rotations; sword/shield attachments following hands; second outfit playback; independent hood/pauldron visibility; both VRMs' facial morph weights; shared camera focal length; pause; native wolf motions; explicit unsupported-action labels; explicit absence of the uncleared Bestiary model; all twelve class definitions; unchanged loaded hero data and production bytes.

The 985 gameplay checks are: core/story 67, actual demo flow 159, class/weapon progression 283, presentation 63, reliability 19, layout 6, shop/preview 128, exploration/quests/puzzles 124 and current skill/companion progression 136. They include all 1,320 ordered distinct primary/two-secondary combinations. These checks do not claim a finished commercial visual standard or human 15–20-minute playtime.

The visual gallery deliberately retains limitations: the VRM Twist sample's sleeve/constraint artifact, stock VRM clothing, unfinished reference-prop grips and the older low-poly wolf. No production replacement has been approved or performed.

Reproduce:

```bash
godot --headless --path . --editor --import --quit
XDG_DATA_HOME=/tmp/verdant-art-test godot --headless --path . res://art_lab/validate.tscn
python3 art_lab/fetch_assets.py
```
