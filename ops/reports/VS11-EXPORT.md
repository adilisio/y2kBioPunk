# VS11-EXPORT — Windows release package and validation

Worktree: `C:\y2k-biopunk-rpg\.worktrees\vs11export`; branch: `vs11-export`.
Date: 2026-10-08. Agent: codex/gpt-6.1-sol.

## Result and outstanding gate

The final release/QA build completed (exit 0), and the release archive is `build/Y2K-BioPunk-VS1.1-win64.zip` (391,003,124 bytes). The release PCK has 854 entries; QA has 860. Both resource/filter checks passed. Packaged menu flow passed (exit 0), and the off-screen release ran for 600 frames with no matching error lines (exit 0).

**The required validation gate is not green.** Packaged `test_slice_e2e.gd` failed on `c: checkpoint collision saves current level` in both runs (exit 1). The full repository test runner reproduced that same assertion: 18/19 passed, `test_slice_e2e.gd` failed, runner exit 1. The final smoke script therefore correctly exits 1 even though menu, PCK and release-launch checks passed.

The checkpoint test teleports the player and awaits only two physics/process-frame pairs before checking the save. In both the engine and packaged logs, the real checkpoint save is recorded immediately after the failed assertion, and subsequent death/respawn/progression/boss/victory checks pass. This suggests a timing-sensitive assertion; it is an inference, not a proven fix. No test, gameplay, scene, native source, or project-setting edit was made to force the gate green. The existing runner's summary prints an empty failed-count field for this single failure; the individual table and nonzero exit establish one failure.

STOP/outstanding item: resolving this checkpoint assertion requires a follow-up within the test/gameplay owner's scope. The packet grants ownership only of export configuration, build/smoke tooling, the runs sentinel, gitignore, this report, and a README section. The archive is built and its launch is verified, but it cannot be described as fully validated. Neither `-s` nor `--script` was refused (`-s` executed both tests); no project-setting change or `res://` save-path problem was found.

`BUILD-INFO.txt` records gameplay/source HEAD `21ae3de8eb893a94b85b4b7f829458394c6faae4`, a UTC date, Godot `4.3.stable.official.77dcf97d8`, and `Working tree modified: True`. Packaging tooling was being authored during that build. The supplied/rebuilt release DLL remains an untracked local artifact, and build outputs/logs stay ignored. Generated tracked `.import` churn is restored before committing.

## Implementation

Added release and QA Windows x86_64 presets, a bounded noninteractive build script, packaged smoke validation, and a committed `ops/runs/.gdignore`. Added `build/` to `.gitignore`, retained only the runs sentinel as trackable, and added the requested short README release section.

The build refuses a Godot engine process using this checkout, rebuilds the release extension only when missing or older than C++ sources, imports headlessly, exports release/debug templates, checks expected artifacts, copies music credits, records Git/date/engine metadata, and zips the complete release directory. Generated output directories are checked against their designated absolute paths before cleanup. Timeouts terminate only the process tree launched by the script. All command output and exit codes are retained.

The release excludes ops/tests/bindings/native sources, worktrees, build outputs, documentation/logs, the unused MP4 and test materials, export configuration, and compiler/temporary DLL artifacts. QA includes all test scripts and only `ops/tools/shot_harness.gd` from ops. Because Godot applies exclusion filters after inclusion filters, QA enumerates exclusions for other ops resources instead of using `ops/*`, which would also remove the allowed harness. The smoke script independently rejects any other ops entry in the real QA PCK.

`application/modify_resources=false` avoids requiring rcedit. Requested icon/company/product/version values remain in the presets, including the literal product version `1.1 (VS1.1)`. They are not applied to the PE executable's Windows icon/version resources. The game icon is included as a runtime resource. The console wrappers are shipped beside the main executables, with separate PCKs and the selected native DLL.

The PCK reader follows Godot 4.3's version-2 directory format and checks bounds, unencrypted entries, duplicates, required files, import/remap targets, and forbidden paths. Imported MP3/GLB files are represented by their logical `.import` entries and platform-ready `.mp3str`/`.scn` payloads, rather than redundant original source bytes. Each required mapping and its nonempty payload is proved from the exported PCK itself. See the complete smoke output below for the full release directory and the eight track/seven model mappings. Godot's [PCK reader](https://github.com/godotengine/godot/blob/4.3-stable/core/io/file_access_pack.cpp) and [resource exporter](https://github.com/godotengine/godot/blob/4.3-stable/editor/export/editor_export_platform.cpp) are the format references. The [Windows exporter](https://github.com/godotengine/godot/blob/4.3-stable/platform/windows/export/export_plugin.cpp) documents the resource-modification switch.

## Save location

`scripts/save_manager.gd` declares `const SAVE_PATH: String = "user://y2k_save_data.json"`. All save/load/clear operations use that constant. `project.godot` names the application `Y2` and supplies no custom user directory. The packaged Windows save therefore lives at:

```text
%APPDATA%\Godot\app_userdata\Y2\y2k_save_data.json
```

This is writable user storage outside the PCK/executable directory. Both packaged tests back up and restore any existing production save. No save-path change was needed.

## Earlier build attempts and diagnostics

The copied release DLL was older than the checkout's C++ source timestamps, so the first build ran `py.exe -3 -m SCons platform=windows target=template_release -j8` and linked successfully (exit 0). The initial fresh-cache import emitted two `get_multiple_md5` null-file diagnostics despite engine exit 0; the build correctly rejected that attempt (script exit 1). The next import was clean without a source or project-setting edit.

The second build produced a release export (engine exit 0), but the initial strict log gate rejected the established headless `mesh_get_surface_count` null-mesh diagnostic. The build gate was corrected to tolerate only that exact two-line dummy-renderer diagnostic for headless exports, while retaining its full output and rejecting every other ERROR/SCRIPT ERROR. A subsequent build passed. Inspecting that export revealed a temporary `bin/~libbiopunk.windows.template_debug.x86_64.dll` generated during headless native loading; both presets now explicitly exclude temporary DLLs and compiler intermediates. The final build below uses those exclusions.

QA uses the established headless suite gate: zero exit, `RESULT: PASS`, no failed assertions/script errors, and no missing-resource/native-library failures. Dummy-renderer and teardown diagnostics are preserved in output. The rendered release launch rejects every ERROR line as required. No editor was opened, and the only rendered launch uses the prescribed off-screen position `2000,2000`.

## Verification output

Complete final script output and earlier attempt output are appended below, together with exit codes, archive/file sizes, and the full regression runner output. The final smoke run repeats the unchanged packaged checkpoint assertion while completing the independent menu/release checks; it does not retry until success or relax the assertion gate.

## Final release directory and archive sizes

| File | Bytes |
|---|---:|
| `build/release/BUILD-INFO.txt` | 199 |
| `build/release/libbiopunk.windows.template_release.x86_64.dll` | 679,424 |
| `build/release/MUSIC-CREDITS.txt` | 686 |
| `build/release/Y2K-BioPunk.console.exe` | 185,856 |
| `build/release/Y2K-BioPunk.exe` | 84,214,784 |
| `build/release/Y2K-BioPunk.pck` | 413,121,248 |
| `build/Y2K-BioPunk-VS1.1-win64.zip` | 391,003,124 |

The ZIP was also inspected with `System.IO.Compression.ZipFile.OpenRead`; it contains exactly the six release files listed above, at the same uncompressed lengths.

## Final build (exit 0)

Command from the assigned worktree:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops/tools/build_release.ps1
```

Complete stdout/stderr captured with `*> ops/runs/export/build_release.completed.full.log` (line endings normalized for Markdown):

```text
Worktree: C:\y2k-biopunk-rpg\.worktrees\vs11export
Logs: C:\y2k-biopunk-rpg\.worktrees\vs11export\ops\runs\export\build_20261008_133825
Release DLL is current; skipping SCons.
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\Godot_v4.3-stable_win64.exe --headless --path "C:\y2k-biopunk-rpg\.worktrees\vs11export" --import
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org


EXIT: 0 (import)
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\Godot_v4.3-stable_win64.exe --headless --path "C:\y2k-biopunk-rpg\.worktrees\vs11export" --export-release "Windows Desktop" build/release/Y2K-BioPunk.exe
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

savepack: begin: Packing steps: 102
	savepack: step 2: Storing File: res://.godot/imported/dial_up_queen.glb-c1a5cb2f8ad5373c4dcab5634b6375c1.scn
	savepack: step 2: Storing File: res://assets/models/dial_up_queen.glb.import
	savepack: step 2: Storing File: res://.godot/imported/fountain_sculpture.glb-a0ab240fe62ced988ba9a52de635ff8f.scn
	savepack: step 2: Storing File: res://assets/models/fountain_sculpture.glb.import
	savepack: step 2: Storing File: res://.godot/imported/kiosk_turret.glb-21d18cfe5e39c287914cfac610d69389.scn
	savepack: step 2: Storing File: res://assets/models/kiosk_turret.glb.import
	savepack: step 2: Storing File: res://.godot/imported/mall_kiosk.glb-ef7ad498f3da947c3b5d733a4903be11.scn
	savepack: step 2: Storing File: res://assets/models/mall_kiosk.glb.import
	savepack: step 2: Storing File: res://.godot/imported/mall_planter.glb-f1515752ded96a398eafbdc994b6e669.scn
	savepack: step 2: Storing File: res://assets/models/mall_planter.glb.import
	savepack: step 3: Storing File: res://.godot/imported/neon_cicada.glb-c075b36b4e093e1d35265564e67f028c.scn
	savepack: step 3: Storing File: res://assets/models/neon_cicada.glb.import
	savepack: step 3: Storing File: res://.godot/imported/sludge_roach.glb-1ae35041ab2d79767ebaf70f00e6243f.scn
	savepack: step 3: Storing File: res://assets/models/sludge_roach.glb.import
	savepack: step 3: Storing File: res://.godot/imported/anthem.mp3-2f7a92cf245df82890b7830193e2bea6.mp3str
	savepack: step 3: Storing File: res://music/anthem.mp3.import
	savepack: step 3: Storing File: res://.godot/imported/bigbeat.mp3-719a317dfac214297f4d640840ee7874.mp3str
	savepack: step 3: Storing File: res://music/bigbeat.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/bubblegum.mp3-6600d7a64ddbbec66a2b18480a79e0ad.mp3str
	savepack: step 4: Storing File: res://music/bubblegum.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/combat.mp3-1829eebac0ee46487ae84a3be83a352e.mp3str
	savepack: step 4: Storing File: res://music/combat.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/eurodance.mp3-fef95430f66d8053d0220ef34137fda9.mp3str
	savepack: step 4: Storing File: res://music/eurodance.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/hiphop.mp3-3d4b4945f60e4d0cddde31e8acbf2438.mp3str
	savepack: step 4: Storing File: res://music/hiphop.mp3.import
	savepack: step 5: Storing File: res://.godot/imported/numetal.mp3-058dd4db2f01f0c63415579f555fa23f.mp3str
	savepack: step 5: Storing File: res://music/numetal.mp3.import
	savepack: step 5: Storing File: res://.godot/imported/skater.mp3-47c0b3f6a66951ef919ba1b8e36e472c.mp3str
	savepack: step 5: Storing File: res://music/skater.mp3.import
	savepack: step 5: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-8f735e678b86df73bf8978d10c629e6f.s3tc.ctex
	savepack: step 5: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
	savepack: step 5: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-e909b100dc6bbda0c7e19c5e6c81bef1.s3tc.ctex
	savepack: step 5: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
	savepack: step 5: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-8122c1ec715bcbe34a4661682b54b4c3.s3tc.ctex
	savepack: step 5: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
	savepack: step 6: Storing File: res://bin/libbiopunk.windows.template_debug.x86_64.dll
	savepack: step 6: Storing File: res://bin/libbiopunk.windows.template_release.x86_64.dll
	savepack: step 6: Storing File: res://biopunk.gdextension
	savepack: step 6: Storing File: res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex
	savepack: step 6: Storing File: res://icon.svg.import
	savepack: step 7: Storing File: res://intro_video.ogv
	savepack: step 7: Storing File: res://Skate_Grind.res
	savepack: step 7: Storing File: res://.godot/exported/133200997/export-72ee11ce23100f2096d10891190f557e-dial_up_queen.scn
	savepack: step 7: Storing File: res://.godot/exported/133200997/export-f257e87bfdc9f628dcc382c88547a250-FloodedMall_Greybox.scn
	savepack: step 8: Storing File: res://.godot/exported/133200997/export-d9b46989ff26b563f7686f0a6c74ef08-health_candy_pickup.scn
	savepack: step 8: Storing File: res://.godot/exported/133200997/export-aa3f5c97579d5c748215bbb2e364ddeb-intro.scn
	savepack: step 8: Storing File: res://.godot/exported/133200997/export-ea5c6ad4629af728dc514cefde332394-main_menu.scn
	savepack: step 8: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb-32a6b43d5d45dfc4ede7dd83598e8211.scn
	savepack: step 8: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg-4aa502cd14a84b2c529a8898c302226b.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg-ecf3d6b8aac2645fe97470a1f4e99f00.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg-3a28b97969be2809be74c1a9476bd1c9.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb-100b1b23c136ecaea2b2c2932c21ac1b.scn
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg-57c9bb5b0ae9234c05de81e42f298c6f.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg-2ba7f038ac6d306fa2b8d47c08417ab1.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg-55d7e5261dcedb3df0eddb11b7b87636.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations.glb-e7f241e6428c2b67e04f90f3be56e5af.scn
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations.glb.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg-3cea79246c65c32a532c42ecef570744.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg-cc800615ee86b5e4ee11529ddfdcda9e.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg-8ced58427b3620342c6ab9d1df00a24c.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb-dd2ef507427ee6ecd6de7aea3842d3f1.scn
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg-114f149bb1e7d1877ac3e9ac4b9ffcab.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg-95776f1ad3e7f33ed594f450af85b1ab.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg-b16ad54c8d136d69239c481caeb12679.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d6fdad554547eb106e82adbbc33e252f.scn
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-86710d89420272bd05b7dff2cb7dc19c.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
	savepack: step 13: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-2c44aaf060978cde46693e50c10062e2.s3tc.ctex
	savepack: step 13: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
	savepack: step 13: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-edd18b21906bbfe2adb2655e252bd46b.s3tc.ctex
	savepack: step 13: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
	savepack: step 13: Storing File: res://.godot/exported/133200997/export-e098924b008c7d9e49d8e825c974b95b-neon_cicada.scn
	savepack: step 13: Storing File: res://.godot/exported/133200997/export-234fb6894ec6226e856ab7f825500d3d-player.scn
	savepack: step 13: Storing File: res://scripts/boss_encounter_trigger.gdc
	savepack: step 14: Storing File: res://scripts/checkpoint.gdc
	savepack: step 14: Storing File: res://scripts/corrupted_kiosk_turret.gdc
	savepack: step 14: Storing File: res://scripts/dial_up_queen.gdc
	savepack: step 14: Storing File: res://scripts/disk_projectile.gdc
	savepack: step 15: Storing File: res://scripts/enemy_model.gdc
	savepack: step 15: Storing File: res://scripts/health_candy_pickup.gdc
	savepack: step 15: Storing File: res://scripts/hud.gdc
	savepack: step 15: Storing File: res://scripts/isometric_camera.gdc
	savepack: step 16: Storing File: res://scripts/mall_greybox_builder.gdc
	savepack: step 16: Storing File: res://scripts/neon_cicada.gdc
	savepack: step 16: Storing File: res://scripts/save_manager.gdc
	savepack: step 16: Storing File: res://scripts/sludge_roach.gdc
	savepack: step 16: Storing File: res://scripts/turret_mortar.gdc
	savepack: step 17: Storing File: res://scripts/tutorial_director.gdc
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0001.png-b710fbec88935683feaa9ce80bb168b5.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0001.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0002.png-0e5a2de3b5fd5d28ce436b421d055443.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0002.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0003.png-9b15b799a24f9fbfe900e8481215af28.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0003.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0004.png-7a93f1ab1179b0e965dc3faf9d34a601.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0004.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0005.png-a93eefa81d5de8b3df0e3a3ffa5a5a96.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0005.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0006.png-31078175cbbcda22f61172097a8379ef.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0006.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0007.png-5b49c7f21f56fa1f374a7643c4fa7f67.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0007.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0008.png-6d3590e2a1ac045c506836477d5759a0.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0008.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0009.png-14ae05c6400d3b747b38851b3f005a58.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0009.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0010.png-0d358bb0ba4f5b17b4fd2db4c1db63a0.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0010.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0011.png-66f8d32db6bd94489fa6462c63bb9e25.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0011.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0012.png-9af3e2a6a8140f68ca9c52822981ac4f.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0012.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0013.png-2c3132152db14b63df2020e769510265.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0013.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0014.png-9bee12fb872d8c3f8b14f8dc83a2e723.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0014.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0015.png-bf3931a65824eda506dac5cb70f66061.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0015.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0016.png-d5ef184284aa8dfbfa436acbd30ff617.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0016.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0017.png-95408049edb1e06eeca6a0623d844741.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0017.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0018.png-04ff2164a4e8823a45d760cb0f8c924c.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0018.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0019.png-bdf2ece8fc4b7d7339b68d8e3078e42d.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0019.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0020.png-5dafb0540cece6243250ba9fe2abcf9d.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0020.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0021.png-26b13f13a12aab931dc5a165ba2449d7.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0021.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0022.png-b7a7bcfe420d7715d19a0ab6614317de.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0022.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0023.png-323c1720fd734f8d4c3011866b334eaf.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0023.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0024.png-d2c8f2e1d387e065f473c9c433f9ddb7.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0024.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0025.png-1c40f3a80700734d053d96815854dfc0.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0025.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0026.png-c19f0c040198da8b7f9ee5df795757c2.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0026.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0027.png-ea9f0ee81748d1e693a28067922f5d2e.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0027.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0028.png-e24290a9e623664b03ab27acfb2650df.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0028.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0029.png-a3c0a06ce660b5e7c165b81610c54676.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0029.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0030.png-f6c9eac873d6fd0dbdc288b0fb569357.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0030.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0031.png-310e4fd4a08c8100e154b74c903283b5.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0031.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0032.png-f278b23644ae1ce5327c8b2c0b039452.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0032.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0033.png-cdb93ffb1ecb703add4499597912f067.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0033.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0034.png-fe43b2e0f994d038860628fea7c4f1d5.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0034.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0035.png-f4fa13aed07d11601dfd153b5d5242bf.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0035.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0036.png-bffcb23fb884cd6d25a3ac3a0412b507.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0036.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0037.png-68914dedfaad711accc4409744a56e4d.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0037.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0038.png-1dab661763c48455fedaf2e96dd5a07a.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0038.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0039.png-7032a0cb4ab60b64402bf0c907e4ca54.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0039.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0040.png-302ba8cb31466cb6ea3dc8dc997b3c57.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0040.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0041.png-2c61cdb0875d6e6575cbc0df76d37a17.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0041.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_0_0042.png-6659fdb2494734652654c028ea5087fc.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_0_0042.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_0_0043.png-0c7e915e718028acacfedaad679e0227.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_0_0043.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_0_0044.png-01e3e2dc516f2dcdf7b4aa7a81620deb.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_0_0044.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_0_0045.png-2c2a1680b70e12826afc1b2b3b9e29b7.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_0_0045.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_1_0001.png-bdb495a9757bdad6797f07eb8555971a.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_1_0001.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0002.png-934840a768165d77186589af676f8a4e.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0002.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0003.png-050f68e9fff75da7614b94ff90773eed.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0003.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0004.png-ebd21421acf611af84f966b5091ce26b.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0004.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0005.png-555a0784cf791c3641ccbc1c5990fb87.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0005.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0006.png-ca0673a91afce76bf8874c74463838f1.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0006.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0007.png-1214b7a104d06df3c3d497bcd1be1834.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0007.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0008.png-f8a89ef405120ae9a8bf879e19cdfa97.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0008.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0009.png-5dcfbd387d83e1ba7227231c891d949a.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0009.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0010.png-f87d76a8175e6446982bab4d7d54ea61.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0010.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0011.png-0337dba63b70dc413b74a06679b6f28c.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0011.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0012.png-03f5f787850b85bee05c351073002118.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0012.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0013.png-b30021586e7c63704890c71eb3a782d9.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0013.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0014.png-1564734f8bb6b3ba6603a743ca7f2575.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0014.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0015.png-e710f55eee5b4c83238640df6bd82846.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0015.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0016.png-0b030e77519508ff1c669f94a1909f94.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0016.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0017.png-e82a6bdd5771e6423a06a0f7342f6e3b.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0017.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0018.png-522091f455426a018d858f5e03c2ab2e.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0018.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0019.png-58201ff8f09e92ec1da1b349fe68db5b.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0019.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0020.png-594e00db2708c2beb29bc93b558dacc3.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0020.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0021.png-074a2e39d733763b37f5b5023df8dfa2.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0021.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0022.png-b8945aba745c3588278faeaf7e1419d4.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0022.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0023.png-5574c663a5fd93f4f03c7eb49828e01a.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0023.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0024.png-60b1a3cd41d1449cc00f64ac3a3f2024.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0024.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0025.png-fb4f2085498167f038dea4b9ec1c2279.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0025.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0026.png-3265acf35ac991ca8f99d9158ac0c1ec.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0026.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0027.png-3418243241bb87f5dc647a772a0efb43.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0027.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0028.png-ee04ca2d0c1aec65325fa925b01c7b1f.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0028.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0029.png-b38794b7bc2ffad1ed4ba99b92cc7227.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0029.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0030.png-671d0253c720699f7c3aa085a63e2a5b.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0030.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0031.png-89b3713d6f7838cee10dd042401d3fad.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0031.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0032.png-2593f66ac31520f96e7fa30959a43e91.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0032.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0033.png-f661de841ee888883396bbe72741b344.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0033.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0034.png-dec28c10562b756dfd86ca58b3e77c40.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0034.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0035.png-1ce258d5745a5fe65a0fd18bfe165fff.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0035.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0036.png-8b7624a493e1a0760ebb2d1f085a37d6.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0036.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0037.png-41f34d23b8fa74a0072956b37088e759.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0037.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0038.png-55a78398a9df364419def19f4ce95af0.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0038.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0039.png-e7a80ce8f9a02fe1310fe47958fd1d41.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0039.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0040.png-b787b560ded3a9fa62bdd1b77723786c.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0040.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0041.png-9690a7eae3341348c1f95f5602be05aa.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0041.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0042.png-7ebe60fb7dda624362b76375368134dd.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0042.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0043.png-7d23a42240b59f04fe4b48547e8f6da9.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0043.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_1_0044.png-0a5dc74966e7dc5eab92fdf6420ea36a.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_1_0044.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_1_0045.png-612dd05ef6ba543963834c97608a32a8.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_1_0045.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0001.png-5edef45f93b3c30215829a5f4ee539a5.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0001.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0002.png-0dc81ff8f64a189a3b647d52dfacf8ea.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0002.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0003.png-8a0453cc9f955415e5f82c386c9ca46c.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0003.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0004.png-9ae7dde74db7dd14c7cbe87d30c66b68.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0004.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0005.png-6f55b2b9c644ef31b21e0dcd11b57ec2.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0005.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0006.png-2e676cddde54f2d6eb922c7069f62736.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0006.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0007.png-9474866534e92b9a05921a6d4857067d.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0007.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0008.png-824cc4850c09bfcbd2d1b0035a43e067.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0008.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0009.png-2e18df9058df064f6724510b64e7ba78.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0009.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0010.png-e4b40f869b92e6e9cd7307dc8d05489b.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0010.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0011.png-3aa009aa9fd5f1d11df53c6ac2f5b5df.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0011.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0012.png-7c170912d4a612a69a3c4e695f111c5f.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0012.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0013.png-bc3e7baa32067d83335a4e95cf4b741c.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0013.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0014.png-3722562c1d091de2a0b91e5cd8349db5.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0014.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0015.png-f464949052b0da7f6a17637e4b1661f6.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0015.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0016.png-4843269e6dc01a3544a9e4d926e1241a.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0016.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0017.png-ff620210c514d0a21957038f3916bd14.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0017.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0018.png-b36d4042dc59a8aaed3ffdceb402e501.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0018.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0019.png-e052941f9a25252589d938aa2627df8a.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0019.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0020.png-6268e8691232161d7624dcca11583e41.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0020.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0021.png-ed3d2424d7120473fbbadc074f4efd14.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0021.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0022.png-51a6f3b3e77c867242bc342972c33180.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0022.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0023.png-3e6859d04911c957f9489557b78b06cc.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0023.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0024.png-282d8d17bae6c8654d89674f1c32a197.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0024.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0025.png-ca5226424597c3ac543f265056272ac8.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0025.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0026.png-9e0d7fbc5fea747e938f546d364ee7ba.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0026.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0027.png-bc33f42a80a11ec8fe49ef20a0661a9a.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0027.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0028.png-25176d6154401916dcaa077304511057.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0028.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0029.png-49975c5c6af211692c84f9679331e1f3.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0029.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0030.png-56de73700cd6f6aa2936077195517479.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0030.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0031.png-52aac777105c1cd8f0b3ec0db04482d7.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0031.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0032.png-ff3d7f88100e92134cab2e7ccc4fd01b.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0032.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0033.png-e6d5817fff0854bd1857b949c443d2c7.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0033.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0034.png-5a8afc03d617da4ff4b9f6a9ee630db8.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0034.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0035.png-aacef661a413cdac61ab7b4b2347df30.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0035.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0036.png-66afe91228cbd5490fa49e5ea2f0335b.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0036.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0037.png-1d3c68ac96e6cf31b172295b3de067b5.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0037.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_2_0038.png-ee2ee22a14ff22dfd3b5a6cde164af77.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_2_0038.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_2_0039.png-1060b4ca444a509a181dc11dc97444ec.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_2_0039.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_2_0040.png-fd2865b617e7b9d89d3e9766db0a3840.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_2_0040.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_2_0041.png-c97812285731470074b9c9e300ef9e65.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_2_0041.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_2_0042.png-0c39dcba0311b68852dba1f724f4be04.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_2_0042.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_2_0043.png-bfd2ba0016b2bdec0825f788a31ea897.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_2_0043.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_2_0044.png-97f3b7371f5b1724ee7d68221d6b1912.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_2_0044.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_2_0045.png-11acbd16bb764485e7ae2275107db149.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_2_0045.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0001.png-31fc37a9e42930004808f030423fd577.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0001.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0002.png-7c1bc4aeb3ff35b537bb53998bf69bab.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0002.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0003.png-5bf3295a4d9b8284bd0ac673a6309a08.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0003.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0004.png-5592b0dbe01a20f12ec8618b369c6f52.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0004.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0005.png-3c1230e43d81597f80567d873c55db13.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0005.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0006.png-45e84080bfd6afaaa0955b9cd46ff09d.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0006.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0007.png-8e3503f7074ae3023a0b9b132650b22a.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0007.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0008.png-26f083538118f1e8b42106e2f6372be2.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0008.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0009.png-10dbc8517bbc031463f3ae77296f97ad.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0009.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0010.png-08298348522f60379afec88de95bb2b7.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0010.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0011.png-5a0bfc0660596d00b1cb8b891fb6fa10.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0011.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0012.png-ed0ac74b550525819c05e15a362549ef.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0012.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0013.png-4c02174a68c2dba29376b8c908786c25.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0013.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0014.png-13ebdda30cc330123a5790ca2a2555f0.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0014.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0015.png-5fbdce781159aadc35349c5a3bebb91e.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0015.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0016.png-e9d305e258e9afd8f205c0cac9fc78c3.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0016.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0017.png-d763659027a5da4cea16ec4fe382345e.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0017.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0018.png-d82463317106aa660a52a7533094d673.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0018.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0019.png-eaa1ae0ed50e2f4d68476dbcaa8962e7.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0019.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0020.png-62f9861f6e2cd96510d4f56c3f351d4b.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0020.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0021.png-5e787d913618906013f43632d4e23f11.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0021.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0022.png-4eb98c30c1306ecd14123de3db43457c.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0022.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0023.png-2ff3ddbdaf2d9b3685fdc173624c3912.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0023.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0024.png-b1dbed21965ad7787031e26dc7960277.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0024.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0025.png-17d0c92b90940d326db4bb0a82b3d7a5.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0025.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0026.png-63facc91904dbd66f32b0a101dc9318d.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0026.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0027.png-af9d4619028fe1327bae6f2acd8f4601.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0027.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0028.png-a10c2fc2c81e56539c59dc1ee413394c.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0028.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0029.png-daf87e63081f9c0a54447006bd2209b6.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0029.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0030.png-e0daaf8466b78886ee3c4d6a13c77a88.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0030.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0031.png-79dd733b6f4796896ee4754093cbf574.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0031.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0032.png-673d415399e336f57767622876a059cc.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0032.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0033.png-351ed26bf049f1c9f5b8f63b48fdc540.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0033.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0034.png-bf45ccd5b8ecb2498520ba55ea8fca90.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0034.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_3_0035.png-4129cce2cdd07ba02d5c20ca4c246a11.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_3_0035.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_3_0036.png-abf04b2b00fe88fdd23ad0bea5df2f99.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_3_0036.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_3_0037.png-751d3c8b75838e4c057b69baa189a6fb.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_3_0037.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_3_0038.png-8a31cb5390a0d5e3a37469e403fc9ea0.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_3_0038.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_3_0039.png-360cb8e786195be9e7dfb3c3a41fae55.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_3_0039.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_3_0040.png-4668837ad40cd17338f2a3a499a99944.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_3_0040.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_3_0041.png-4ede56ee72e588a4885b2b8d46d20b13.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_3_0041.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_3_0042.png-3f2669e912059103f59dd7cbdf921b09.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_3_0042.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_3_0043.png-cf5aae44be164daae0adafb255e53c3a.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_3_0043.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_3_0044.png-8171ad75fd9c98d5eb123b4fcc2fe1d0.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_3_0044.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_3_0045.png-739fee3a1c4268b262bce228f3c25540.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_3_0045.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0001.png-44c0140589c9477c53e693ca422a610f.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0001.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0002.png-03e83ca13844bf120ff9f33592cabb55.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0002.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0003.png-5a067b1ce8c2abce9d265d1085006aa2.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0003.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0004.png-3e737cb0da6ac2bbf67f17e9de4541da.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0004.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0005.png-50ca1e2ace0ad812aa8e4658e5fbc49b.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0005.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0006.png-cbaebc60f655a63514a9ee42bbe601a8.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0006.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0007.png-9b4fde0a646fd92a84a198f3308e7f9c.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0007.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0008.png-914cc8543e9f50ced206fb184b891a30.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0008.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0009.png-f906857f39f7c9499bf866179301a8fa.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0009.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0010.png-e5aea61231082aa35a21f40f2712ec09.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0010.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0011.png-046e49dffaa400aa7376d9ab1b6427b9.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0011.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0012.png-fd1244d2744d4afcec69891ea22bf3ef.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0012.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0013.png-7b2b287a5acb0f329ec30bd468e72c1b.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0013.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0014.png-a86ccdbf773101b21bcc3797b678b648.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0014.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0015.png-b58405815ea0731a85856890e866e793.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0015.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0016.png-81e83a46d052604fb757f7c0412bfeb0.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0016.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0017.png-39333cb64f3c2877e9b4b20f86f02771.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0017.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0018.png-4003cb82bd9d789910f6f8d31a8bec48.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0018.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0019.png-dead4a6a63153cb0b9b7931f5ae678ed.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0019.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0020.png-71b2b2ce20e8fbab8b36a7ca71ba801c.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0020.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0021.png-ec51ee3073d172fbdb1752fe73b64753.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0021.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0022.png-c9d441a84209b2fd15a00faa56fb1251.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0022.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0023.png-2ce81c611a182118a20d5505faf43e96.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0023.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0024.png-8de87e72e639b46d062c45e528d5ca76.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0024.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0025.png-0c9d69a0d7dd65f8c19b5d14c8c9e938.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0025.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0026.png-b4078c194745d66f3f8b16c33db101ba.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0026.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0027.png-a0e8070b2a4b990a2fa3970d09ed07df.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0027.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0028.png-81d472d161be45c7797b5fbf138424a3.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0028.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0029.png-89b8cb45ca54fce7e0b0a4345dd77e09.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0029.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0030.png-a4ea7e588e4207342eab45b6bece9b09.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0030.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0031.png-56f62fd7bf021bdf915f7a99d49c25d4.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0031.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0032.png-a02734f8bdb2a9ad41fa7f5b015afc87.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0032.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_4_0033.png-6d81174d22f2c4d14bcd6a92aedafe5c.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_4_0033.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_4_0034.png-65e08bf7b6548c7094aa67e59f0be8be.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_4_0034.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_4_0035.png-be32669bf98db3b34e6df6590b21a192.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_4_0035.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_4_0036.png-0d1a5b53a63e57bd8542ccb7f3bb3f64.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_4_0036.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_4_0037.png-f3e55a4dc2b84a975bbdeb291c52bf65.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_4_0037.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_4_0038.png-4a5bd9cfd14b5deedd060279575f5aef.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_4_0038.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_4_0039.png-c90075c8d1b9a00ed5bb2713007533a9.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_4_0039.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_4_0040.png-1bb4300271bd8cde60ac4bf231cad3f8.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_4_0040.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_4_0041.png-24f218bb887697ebff8afbc939c66102.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_4_0041.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_4_0042.png-32f0cb46cb07386daf5336ede400072f.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_4_0042.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_4_0043.png-c29414dfe98a0fffa05aa08c80b5a047.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_4_0043.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_4_0044.png-267944e3e6bc3dffcd6632d486270177.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_4_0044.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_4_0045.png-7d4f63980d87410e0f5f75d6fcd7980f.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_4_0045.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0001.png-54ecb67a3b64ef53b95f38cfcaab5d7e.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0001.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0002.png-4be9ff92bf6613ac5f0532ee594c9f8d.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0002.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0003.png-02ae3ecccec6854388104446a5cce060.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0003.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0004.png-78f400ba5159020d0cc327fb7751626b.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0004.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0005.png-a61599f3a6912253a4ee8a46f2179ee0.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0005.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0006.png-a7a9166dcc80e53082039570e987d60e.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0006.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0007.png-97719fa861936e98f05b1c47c7437edb.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0007.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0008.png-bfa0a41e9582b4220810342faa17048b.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0008.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0009.png-222b7f2c0ba311d0eb36c49e18d4fac0.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0009.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0010.png-a0a53aaa4f0d1e1d0b151c9561284562.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0010.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0011.png-718b2daecc82a6b8e27bafe5e48aeeda.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0011.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0012.png-0165b583c3cf87032ff35631b2e3e95a.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0012.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0013.png-838fe2b9da91889799d90ec54c4cc969.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0013.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0014.png-d8663fd1c9ebf299c93e7dc67e26f95f.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0014.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0015.png-2100f509d345cd07461664ab3eaa81dd.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0015.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0016.png-226901d9b28cf7df2decd0451326d75c.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0016.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0017.png-dfd5420cd9b200935c84bf0f4cac4ab0.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0017.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0018.png-aa2e5c55ce7ff835a3ea1c42d9837741.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0018.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0019.png-a943751b68884dfc46fbb0c2c0d5178b.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0019.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0020.png-3584c763a7727de0c392a8c618354c88.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0020.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0021.png-79793cf9cbb8fe9c5c92a8a8c186c165.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0021.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0022.png-ea8d8f9eacfcc6ad60cf0eac8f76bb2d.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0022.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0023.png-f2938d845123450a87fd6be27d904951.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0023.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0024.png-a231cbffffd158111eb4a45e6c9494ab.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0024.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0025.png-fe9f38a76a4fcb7b388729392facaaf2.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0025.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0026.png-e8934ff24161fe66919d3f09ded05027.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0026.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0027.png-26da75d75afe8b79255c43e3d8e08e98.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0027.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0028.png-d694010607039d58c26ddbd9f48585be.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0028.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0029.png-800bbbc0a1f0dae81fe7ae5f7e27f370.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0029.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0030.png-7b64c82c5a0463a9b47161a4935e60ce.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0030.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0031.png-acfc1df8e7d5e6d193dfc8220f1db0ee.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0031.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0032.png-423371a1636bc3f76ff44be178654e40.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0032.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0033.png-78216bae1d9c00088dcc3233e62ca4db.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0033.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0034.png-34a0b317ec360b1b06a2262b63ffae14.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0034.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_5_0035.png-62cf4a4fa40fc11ae23842db81261d48.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_5_0035.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_5_0036.png-38c419c3886c9f73785214229b1e5e8a.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_5_0036.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_5_0037.png-70052c6484a98cf0e42ae14e7c15da95.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_5_0037.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_5_0038.png-c0bf8c173fa4868b88096fb5ef6cd786.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_5_0038.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_5_0039.png-976536a45ab5477c7df7d1c99b776380.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_5_0039.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_5_0040.png-ba9bce1718013b82ef4d19d9b0f1c763.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_5_0040.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_5_0041.png-46f91cd851a5f818c5a02091783f1be4.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_5_0041.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_5_0042.png-02de82baf6bddc7ed4ba0f7cb97fcc55.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_5_0042.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_5_0043.png-c35a6a6a429dcfc7d718438169e5de18.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_5_0043.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_5_0044.png-ce3e123d0b3626a753b875112d502854.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_5_0044.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_5_0045.png-6852b5c6ea7d3ebfd8e76ca923623c0e.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_5_0045.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0001.png-305ad0570c16badf494841e57f4ba611.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0001.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0002.png-22826ad2b1480d94ac49569140300b7d.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0002.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0003.png-2ddfab84d846eea12800d2ae3258d124.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0003.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0004.png-198bf0b806aed2f6d3c931a62777c72b.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0004.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0005.png-2843d807360986b608946b90e888010b.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0005.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0006.png-3e9d956ac832e00cd3c5c5e88b3ed985.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0006.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0007.png-5d37f95317537321949f3aa1b3bdaec5.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0007.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0008.png-5e47c714d8975acee8a61f03c7e1c8a8.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0008.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0009.png-a5ff6975ef9d035dc44e9369a7633b7b.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0009.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0010.png-18fefd47204b86c43402b80449215e5d.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0010.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0011.png-403f81f4712d87a6fc7bc293abfe951c.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0011.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0012.png-7a43de7f34962670014e2fa8cf58bdbd.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0012.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0013.png-6997758c5a879c6dfebd9bf83fb80b19.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0013.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0014.png-cded909ae25b702d64c05cd7ae0d2f13.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0014.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0015.png-66aeb5bd0bc542fc175fec55a3bf6087.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0015.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0016.png-b938bf7a70c22eb9d70fcaf577311100.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0016.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0017.png-176b7f93ffdda965c54bdd0eb9326d9b.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0017.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0018.png-f92b96743b8714dcbaf521b80eafbf3f.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0018.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0019.png-5761e61793846e110d7703fd46cae4d4.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0019.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0020.png-8a75df3dc801931a2f4c8ace65113319.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0020.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0021.png-9a33865f02a031907cbfe0e27fd35f00.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0021.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0022.png-3e67df7c6e0a065b498d39b0c08b0312.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0022.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0023.png-7f64aa280564aebe45e5dc0d8d9d5c16.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0023.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0024.png-88f09f26e628d7d315ce59732ccc2834.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0024.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0025.png-0b3af2fa1d2cbbfd99d4ee002fb12840.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0025.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0026.png-021f4a1a723c8d54576610d04d7fd57f.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0026.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0027.png-44e3d8b5ff0f346c8104b4032f560f71.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0027.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0028.png-1105d75f85506ccc5746fbd864b24fff.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0028.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0029.png-e4b4caed37291002953d56f4ca4131ab.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0029.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0030.png-61625df132dbbd128d4e1f75e75aabfc.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0030.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0031.png-d749cc2494f059267e4e7df5116e8622.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0031.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0032.png-71a30f79d5da9c1b438f22b398b5dab1.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0032.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_6_0033.png-1581d03ab3875a38a17e89ed97f9e4b7.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_6_0033.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_6_0034.png-901410a3b9a1123e4fe9c6c067e84996.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_6_0034.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_6_0035.png-0ca73a5099e5ee470642737d3d349212.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_6_0035.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_6_0036.png-74212616df9d8d718bb761f75646bcc1.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_6_0036.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_6_0037.png-b8f3cd7f00d11e1738def20ba138ad31.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_6_0037.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_6_0038.png-de4b8fd9a432a6d0cb6d62a70779f107.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_6_0038.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_6_0039.png-30fe4a5d0248c94f51c386de6818aab0.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_6_0039.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_6_0040.png-01c5d066ea63da2b2939414aab6b7897.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_6_0040.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_6_0041.png-36d9495a377e03e36d424fd98695a054.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_6_0041.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_6_0042.png-0d3be26f076a11fe04aa48150607f766.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_6_0042.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_6_0043.png-b9f2da0ea4ca216970722097f128bbd1.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_6_0043.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_6_0044.png-3f84695fc07f7b738486280eb5603000.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_6_0044.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_6_0045.png-deb75272ecbeaf94c9d8a660d7c0ac85.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_6_0045.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0001.png-f56163f66408f9b4868c963b7ccdc888.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0001.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0002.png-c0fe11e0a41fb3e172cad384ea0d6fdb.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0002.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0003.png-80353ff236d3b9e9529d95b234901c2f.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0003.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0004.png-f17b8c72db6c5a5555c1e058a4fdb37d.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0004.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0005.png-9b495c651b85e4394c7278ed9117f507.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0005.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0006.png-b55337d24f1991722d24974127890164.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0006.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0007.png-3f74fdb57cdfb5cf92632111c7c47353.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0007.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0008.png-14fff645fc469a9ca37da44571c8bf40.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0008.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0009.png-44a989bb4ef8aec21b41ccf787b8ad79.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0009.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0010.png-f8b6efa1bc0fdde4984d18d79ab2b87a.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0010.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0011.png-8d079e563451cb648d05f12fcd83410e.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0011.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0012.png-c481686c32eb52fd6fd4412c6d7b4b4e.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0012.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0013.png-230ea27940975966523df263c58504ff.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0013.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0014.png-cd9b475b011d51a12b5035e2f55c89a4.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0014.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0015.png-6462d0a0c363f5a418682bbd99cfee9f.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0015.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0016.png-1e525788b0aecb2c77f9c99b2c6e7961.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0016.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0017.png-fc1fb54f89a66e7672a3dea4977bf5dd.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0017.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0018.png-ab4b697f5439f7562d6495d6ca1b21c2.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0018.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0019.png-d6adf250f69ca718c20f2b6f1e1dab8b.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0019.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0020.png-13e81bed771a378dd92fe3e44a5dcae9.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0020.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0021.png-95025a26723093c478b81f9159680c72.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0021.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0022.png-7119dbcacfdc1fbeea0a4908fde2ad4c.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0022.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0023.png-42911aed0fd1e7b00c59d14e1d3bd2ec.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0023.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0024.png-cd0313892fa0271db3530d704b558c3a.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0024.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0025.png-e837b778cf6654dccb6e1c3cac343e06.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0025.png.import
	savepack: step 97: Storing File: res://.godot/imported/dir_7_0026.png-c14e9001cf3dbffbd89121685a29876b.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/dir_7_0026.png.import
	savepack: step 97: Storing File: res://.godot/imported/dir_7_0027.png-410a93b758978f6107af16ca2265aaca.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/dir_7_0027.png.import
	savepack: step 97: Storing File: res://.godot/imported/dir_7_0028.png-f441389b1b2984eba015ff3018824976.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/dir_7_0028.png.import
	savepack: step 97: Storing File: res://.godot/imported/dir_7_0029.png-37b4c07a4c3f14a34495ee55687869f8.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/dir_7_0029.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0030.png-ef549d8584817425a792f64d53b357de.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0030.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0031.png-368fd541b5b5219ce5724ebf77b504e3.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0031.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0032.png-5862cafb570810c768df0659dbd21c86.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0032.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0033.png-04b92d5998216baaca5ce78bc7e2b0ab.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0033.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0034.png-f360fbba45604b91d35ca2106e17547f.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0034.png.import
	savepack: step 99: Storing File: res://.godot/imported/dir_7_0035.png-ab41dcabc7044bd63709f874ba63d42f.ctex
	savepack: step 99: Storing File: res://sprites/player_idle/dir_7_0035.png.import
	savepack: step 99: Storing File: res://.godot/imported/dir_7_0036.png-e59c70a78b8e861cb280f41a3eb39067.ctex
	savepack: step 99: Storing File: res://sprites/player_idle/dir_7_0036.png.import
	savepack: step 99: Storing File: res://.godot/imported/dir_7_0037.png-ac4072e6541b8df202a43dea56e7cd67.ctex
	savepack: step 99: Storing File: res://sprites/player_idle/dir_7_0037.png.import
	savepack: step 99: Storing File: res://.godot/imported/dir_7_0038.png-42cd164980ead0a5b2376797057244a2.ctex
	savepack: step 99: Storing File: res://sprites/player_idle/dir_7_0038.png.import
	savepack: step 100: Storing File: res://.godot/imported/dir_7_0039.png-7c2343a6c86942135313d0c4bc4f414e.ctex
	savepack: step 100: Storing File: res://sprites/player_idle/dir_7_0039.png.import
	savepack: step 100: Storing File: res://.godot/imported/dir_7_0040.png-5312afda3741127ce8a70bfb88de9549.ctex
	savepack: step 100: Storing File: res://sprites/player_idle/dir_7_0040.png.import
	savepack: step 100: Storing File: res://.godot/imported/dir_7_0041.png-9b4ca50bea3cbd33520b6451fc976146.ctex
	savepack: step 100: Storing File: res://sprites/player_idle/dir_7_0041.png.import
	savepack: step 100: Storing File: res://.godot/imported/dir_7_0042.png-435fab965479c665ead6209978a0e5fc.ctex
	savepack: step 100: Storing File: res://sprites/player_idle/dir_7_0042.png.import
	savepack: step 101: Storing File: res://.godot/imported/dir_7_0043.png-5bf45588c7753e97799660453a66348f.ctex
	savepack: step 101: Storing File: res://sprites/player_idle/dir_7_0043.png.import
	savepack: step 101: Storing File: res://.godot/imported/dir_7_0044.png-e710ee96e2dd522844ed77edfeac0918.ctex
	savepack: step 101: Storing File: res://sprites/player_idle/dir_7_0044.png.import
	savepack: step 101: Storing File: res://.godot/imported/dir_7_0045.png-9b82aafad83a15cdf5250f678768e4c3.ctex
	savepack: step 101: Storing File: res://sprites/player_idle/dir_7_0045.png.import
	savepack: step 101: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d386ad401674f18d1edfd264d67ce020.scn
	savepack: step 101: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
	savepack: step 101: Storing File: res://scenes/dial_up_queen.tscn.remap
	savepack: step 101: Storing File: res://scenes/FloodedMall_Greybox.tscn.remap
	savepack: step 101: Storing File: res://scenes/health_candy_pickup.tscn.remap
	savepack: step 101: Storing File: res://scenes/intro.tscn.remap
	savepack: step 101: Storing File: res://scenes/main_menu.tscn.remap
	savepack: step 101: Storing File: res://scenes/neon_cicada.tscn.remap
	savepack: step 101: Storing File: res://scenes/player.tscn.remap
	savepack: step 101: Storing File: res://scripts/boss_encounter_trigger.gd.remap
	savepack: step 101: Storing File: res://scripts/checkpoint.gd.remap
	savepack: step 101: Storing File: res://scripts/corrupted_kiosk_turret.gd.remap
	savepack: step 101: Storing File: res://scripts/dial_up_queen.gd.remap
	savepack: step 101: Storing File: res://scripts/disk_projectile.gd.remap
	savepack: step 101: Storing File: res://scripts/enemy_model.gd.remap
	savepack: step 101: Storing File: res://scripts/health_candy_pickup.gd.remap
	savepack: step 101: Storing File: res://scripts/hud.gd.remap
	savepack: step 101: Storing File: res://scripts/isometric_camera.gd.remap
	savepack: step 101: Storing File: res://scripts/mall_greybox_builder.gd.remap
	savepack: step 101: Storing File: res://scripts/neon_cicada.gd.remap
	savepack: step 101: Storing File: res://scripts/save_manager.gd.remap
	savepack: step 101: Storing File: res://scripts/sludge_roach.gd.remap
	savepack: step 101: Storing File: res://scripts/turret_mortar.gd.remap
	savepack: step 101: Storing File: res://scripts/tutorial_director.gd.remap
	savepack: step 101: Storing File: res://.godot/global_script_class_cache.cfg
	savepack: step 101: Storing File: res://icon.svg
	savepack: step 101: Storing File: res://.godot/uid_cache.bin
	savepack: step 101: Storing File: res://.godot/extension_list.cfg
	savepack: step 101: Storing File: res://project.binary
savepack: end

EXIT: 0 (release)
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\Godot_v4.3-stable_win64.exe --headless --path "C:\y2k-biopunk-rpg\.worktrees\vs11export" --export-debug "Windows Desktop QA" build/qa/Y2K-BioPunk-QA.exe
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

savepack: begin: Packing steps: 102
	savepack: step 2: Storing File: res://.godot/imported/dial_up_queen.glb-c1a5cb2f8ad5373c4dcab5634b6375c1.scn
	savepack: step 2: Storing File: res://assets/models/dial_up_queen.glb.import
	savepack: step 2: Storing File: res://.godot/imported/fountain_sculpture.glb-a0ab240fe62ced988ba9a52de635ff8f.scn
	savepack: step 2: Storing File: res://assets/models/fountain_sculpture.glb.import
	savepack: step 2: Storing File: res://.godot/imported/kiosk_turret.glb-21d18cfe5e39c287914cfac610d69389.scn
	savepack: step 2: Storing File: res://assets/models/kiosk_turret.glb.import
	savepack: step 2: Storing File: res://.godot/imported/mall_kiosk.glb-ef7ad498f3da947c3b5d733a4903be11.scn
	savepack: step 2: Storing File: res://assets/models/mall_kiosk.glb.import
	savepack: step 2: Storing File: res://.godot/imported/mall_planter.glb-f1515752ded96a398eafbdc994b6e669.scn
	savepack: step 2: Storing File: res://assets/models/mall_planter.glb.import
	savepack: step 3: Storing File: res://.godot/imported/neon_cicada.glb-c075b36b4e093e1d35265564e67f028c.scn
	savepack: step 3: Storing File: res://assets/models/neon_cicada.glb.import
	savepack: step 3: Storing File: res://.godot/imported/sludge_roach.glb-1ae35041ab2d79767ebaf70f00e6243f.scn
	savepack: step 3: Storing File: res://assets/models/sludge_roach.glb.import
	savepack: step 3: Storing File: res://.godot/imported/anthem.mp3-2f7a92cf245df82890b7830193e2bea6.mp3str
	savepack: step 3: Storing File: res://music/anthem.mp3.import
	savepack: step 3: Storing File: res://.godot/imported/bigbeat.mp3-719a317dfac214297f4d640840ee7874.mp3str
	savepack: step 3: Storing File: res://music/bigbeat.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/bubblegum.mp3-6600d7a64ddbbec66a2b18480a79e0ad.mp3str
	savepack: step 4: Storing File: res://music/bubblegum.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/combat.mp3-1829eebac0ee46487ae84a3be83a352e.mp3str
	savepack: step 4: Storing File: res://music/combat.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/eurodance.mp3-fef95430f66d8053d0220ef34137fda9.mp3str
	savepack: step 4: Storing File: res://music/eurodance.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/hiphop.mp3-3d4b4945f60e4d0cddde31e8acbf2438.mp3str
	savepack: step 4: Storing File: res://music/hiphop.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/numetal.mp3-058dd4db2f01f0c63415579f555fa23f.mp3str
	savepack: step 4: Storing File: res://music/numetal.mp3.import
	savepack: step 5: Storing File: res://.godot/imported/skater.mp3-47c0b3f6a66951ef919ba1b8e36e472c.mp3str
	savepack: step 5: Storing File: res://music/skater.mp3.import
	savepack: step 5: Storing File: res://biopunk.gdextension
	savepack: step 5: Storing File: res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex
	savepack: step 5: Storing File: res://icon.svg.import
	savepack: step 5: Storing File: res://intro_video.ogv
	savepack: step 6: Storing File: res://Skate_Grind.res
	savepack: step 6: Storing File: res://tests/test_tapes.gd
	savepack: step 6: Storing File: res://tests/verify_camera_and_hud.gd
	savepack: step 6: Storing File: res://ops/tools/shot_harness.gd
	savepack: step 6: Storing File: res://bin/libbiopunk.windows.template_debug.x86_64.dll
	savepack: step 7: Storing File: res://bin/libbiopunk.windows.template_release.x86_64.dll
	savepack: step 7: Storing File: res://.godot/exported/133200997/export-72ee11ce23100f2096d10891190f557e-dial_up_queen.scn
	savepack: step 7: Storing File: res://.godot/exported/133200997/export-f257e87bfdc9f628dcc382c88547a250-FloodedMall_Greybox.scn
	savepack: step 7: Storing File: res://.godot/exported/133200997/export-d9b46989ff26b563f7686f0a6c74ef08-health_candy_pickup.scn
	savepack: step 8: Storing File: res://.godot/exported/133200997/export-aa3f5c97579d5c748215bbb2e364ddeb-intro.scn
	savepack: step 8: Storing File: res://.godot/exported/133200997/export-ea5c6ad4629af728dc514cefde332394-main_menu.scn
	savepack: step 8: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb-32a6b43d5d45dfc4ede7dd83598e8211.scn
	savepack: step 8: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb.import
	savepack: step 8: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg-4aa502cd14a84b2c529a8898c302226b.s3tc.ctex
	savepack: step 8: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg.import
	savepack: step 8: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg-ecf3d6b8aac2645fe97470a1f4e99f00.s3tc.ctex
	savepack: step 8: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg-3a28b97969be2809be74c1a9476bd1c9.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb-100b1b23c136ecaea2b2c2932c21ac1b.scn
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg-57c9bb5b0ae9234c05de81e42f298c6f.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg-2ba7f038ac6d306fa2b8d47c08417ab1.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg-55d7e5261dcedb3df0eddb11b7b87636.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations.glb-e7f241e6428c2b67e04f90f3be56e5af.scn
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations.glb.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg-3cea79246c65c32a532c42ecef570744.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg-cc800615ee86b5e4ee11529ddfdcda9e.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg-8ced58427b3620342c6ab9d1df00a24c.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb-dd2ef507427ee6ecd6de7aea3842d3f1.scn
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg-114f149bb1e7d1877ac3e9ac4b9ffcab.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg-95776f1ad3e7f33ed594f450af85b1ab.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg-b16ad54c8d136d69239c481caeb12679.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d6fdad554547eb106e82adbbc33e252f.scn
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-86710d89420272bd05b7dff2cb7dc19c.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-2c44aaf060978cde46693e50c10062e2.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-edd18b21906bbfe2adb2655e252bd46b.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
	savepack: step 12: Storing File: res://.godot/exported/133200997/export-e098924b008c7d9e49d8e825c974b95b-neon_cicada.scn
	savepack: step 13: Storing File: res://.godot/exported/133200997/export-234fb6894ec6226e856ab7f825500d3d-player.scn
	savepack: step 13: Storing File: res://scripts/boss_encounter_trigger.gd
	savepack: step 13: Storing File: res://scripts/checkpoint.gd
	savepack: step 13: Storing File: res://scripts/corrupted_kiosk_turret.gd
	savepack: step 14: Storing File: res://scripts/dial_up_queen.gd
	savepack: step 14: Storing File: res://scripts/disk_projectile.gd
	savepack: step 14: Storing File: res://scripts/enemy_model.gd
	savepack: step 14: Storing File: res://scripts/health_candy_pickup.gd
	savepack: step 14: Storing File: res://scripts/hud.gd
	savepack: step 15: Storing File: res://scripts/isometric_camera.gd
	savepack: step 15: Storing File: res://scripts/mall_greybox_builder.gd
	savepack: step 15: Storing File: res://scripts/neon_cicada.gd
	savepack: step 15: Storing File: res://scripts/save_manager.gd
	savepack: step 16: Storing File: res://scripts/sludge_roach.gd
	savepack: step 16: Storing File: res://scripts/turret_mortar.gd
	savepack: step 16: Storing File: res://scripts/tutorial_director.gd
	savepack: step 16: Storing File: res://.godot/imported/dir_0_0001.png-b710fbec88935683feaa9ce80bb168b5.ctex
	savepack: step 16: Storing File: res://sprites/player_idle/dir_0_0001.png.import
	savepack: step 16: Storing File: res://.godot/imported/dir_0_0002.png-0e5a2de3b5fd5d28ce436b421d055443.ctex
	savepack: step 16: Storing File: res://sprites/player_idle/dir_0_0002.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0003.png-9b15b799a24f9fbfe900e8481215af28.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0003.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0004.png-7a93f1ab1179b0e965dc3faf9d34a601.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0004.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0005.png-a93eefa81d5de8b3df0e3a3ffa5a5a96.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0005.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0006.png-31078175cbbcda22f61172097a8379ef.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0006.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0007.png-5b49c7f21f56fa1f374a7643c4fa7f67.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0007.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0008.png-6d3590e2a1ac045c506836477d5759a0.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0008.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0009.png-14ae05c6400d3b747b38851b3f005a58.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0009.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0010.png-0d358bb0ba4f5b17b4fd2db4c1db63a0.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0010.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0011.png-66f8d32db6bd94489fa6462c63bb9e25.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0011.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0012.png-9af3e2a6a8140f68ca9c52822981ac4f.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0012.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0013.png-2c3132152db14b63df2020e769510265.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0013.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0014.png-9bee12fb872d8c3f8b14f8dc83a2e723.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0014.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0015.png-bf3931a65824eda506dac5cb70f66061.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0015.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0016.png-d5ef184284aa8dfbfa436acbd30ff617.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0016.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0017.png-95408049edb1e06eeca6a0623d844741.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0017.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0018.png-04ff2164a4e8823a45d760cb0f8c924c.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0018.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0019.png-bdf2ece8fc4b7d7339b68d8e3078e42d.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0019.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0020.png-5dafb0540cece6243250ba9fe2abcf9d.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0020.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0021.png-26b13f13a12aab931dc5a165ba2449d7.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0021.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0022.png-b7a7bcfe420d7715d19a0ab6614317de.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0022.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0023.png-323c1720fd734f8d4c3011866b334eaf.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0023.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0024.png-d2c8f2e1d387e065f473c9c433f9ddb7.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0024.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0025.png-1c40f3a80700734d053d96815854dfc0.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0025.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0026.png-c19f0c040198da8b7f9ee5df795757c2.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0026.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0027.png-ea9f0ee81748d1e693a28067922f5d2e.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0027.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0028.png-e24290a9e623664b03ab27acfb2650df.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0028.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0029.png-a3c0a06ce660b5e7c165b81610c54676.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0029.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0030.png-f6c9eac873d6fd0dbdc288b0fb569357.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0030.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0031.png-310e4fd4a08c8100e154b74c903283b5.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0031.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0032.png-f278b23644ae1ce5327c8b2c0b039452.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0032.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0033.png-cdb93ffb1ecb703add4499597912f067.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0033.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0034.png-fe43b2e0f994d038860628fea7c4f1d5.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0034.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0035.png-f4fa13aed07d11601dfd153b5d5242bf.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0035.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0036.png-bffcb23fb884cd6d25a3ac3a0412b507.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0036.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0037.png-68914dedfaad711accc4409744a56e4d.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0037.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0038.png-1dab661763c48455fedaf2e96dd5a07a.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0038.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0039.png-7032a0cb4ab60b64402bf0c907e4ca54.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0039.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0040.png-302ba8cb31466cb6ea3dc8dc997b3c57.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0040.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0041.png-2c61cdb0875d6e6575cbc0df76d37a17.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0041.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0042.png-6659fdb2494734652654c028ea5087fc.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0042.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0043.png-0c7e915e718028acacfedaad679e0227.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0043.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0044.png-01e3e2dc516f2dcdf7b4aa7a81620deb.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0044.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0045.png-2c2a1680b70e12826afc1b2b3b9e29b7.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0045.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_1_0001.png-bdb495a9757bdad6797f07eb8555971a.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_1_0001.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_1_0002.png-934840a768165d77186589af676f8a4e.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_1_0002.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_1_0003.png-050f68e9fff75da7614b94ff90773eed.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_1_0003.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_1_0004.png-ebd21421acf611af84f966b5091ce26b.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_1_0004.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_1_0005.png-555a0784cf791c3641ccbc1c5990fb87.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_1_0005.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_1_0006.png-ca0673a91afce76bf8874c74463838f1.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_1_0006.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0007.png-1214b7a104d06df3c3d497bcd1be1834.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0007.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0008.png-f8a89ef405120ae9a8bf879e19cdfa97.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0008.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0009.png-5dcfbd387d83e1ba7227231c891d949a.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0009.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0010.png-f87d76a8175e6446982bab4d7d54ea61.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0010.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0011.png-0337dba63b70dc413b74a06679b6f28c.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0011.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0012.png-03f5f787850b85bee05c351073002118.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0012.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0013.png-b30021586e7c63704890c71eb3a782d9.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0013.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0014.png-1564734f8bb6b3ba6603a743ca7f2575.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0014.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0015.png-e710f55eee5b4c83238640df6bd82846.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0015.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0016.png-0b030e77519508ff1c669f94a1909f94.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0016.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0017.png-e82a6bdd5771e6423a06a0f7342f6e3b.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0017.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0018.png-522091f455426a018d858f5e03c2ab2e.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0018.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0019.png-58201ff8f09e92ec1da1b349fe68db5b.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0019.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0020.png-594e00db2708c2beb29bc93b558dacc3.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0020.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0021.png-074a2e39d733763b37f5b5023df8dfa2.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0021.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0022.png-b8945aba745c3588278faeaf7e1419d4.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0022.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0023.png-5574c663a5fd93f4f03c7eb49828e01a.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0023.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0024.png-60b1a3cd41d1449cc00f64ac3a3f2024.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0024.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0025.png-fb4f2085498167f038dea4b9ec1c2279.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0025.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0026.png-3265acf35ac991ca8f99d9158ac0c1ec.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0026.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0027.png-3418243241bb87f5dc647a772a0efb43.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0027.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0028.png-ee04ca2d0c1aec65325fa925b01c7b1f.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0028.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0029.png-b38794b7bc2ffad1ed4ba99b92cc7227.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0029.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0030.png-671d0253c720699f7c3aa085a63e2a5b.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0030.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0031.png-89b3713d6f7838cee10dd042401d3fad.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0031.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0032.png-2593f66ac31520f96e7fa30959a43e91.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0032.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0033.png-f661de841ee888883396bbe72741b344.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0033.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0034.png-dec28c10562b756dfd86ca58b3e77c40.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0034.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0035.png-1ce258d5745a5fe65a0fd18bfe165fff.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0035.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0036.png-8b7624a493e1a0760ebb2d1f085a37d6.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0036.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0037.png-41f34d23b8fa74a0072956b37088e759.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0037.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0038.png-55a78398a9df364419def19f4ce95af0.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0038.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0039.png-e7a80ce8f9a02fe1310fe47958fd1d41.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0039.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0040.png-b787b560ded3a9fa62bdd1b77723786c.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0040.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0041.png-9690a7eae3341348c1f95f5602be05aa.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0041.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0042.png-7ebe60fb7dda624362b76375368134dd.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0042.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0043.png-7d23a42240b59f04fe4b48547e8f6da9.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0043.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0044.png-0a5dc74966e7dc5eab92fdf6420ea36a.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0044.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0045.png-612dd05ef6ba543963834c97608a32a8.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0045.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_2_0001.png-5edef45f93b3c30215829a5f4ee539a5.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_2_0001.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_2_0002.png-0dc81ff8f64a189a3b647d52dfacf8ea.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_2_0002.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_2_0003.png-8a0453cc9f955415e5f82c386c9ca46c.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_2_0003.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_2_0004.png-9ae7dde74db7dd14c7cbe87d30c66b68.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_2_0004.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_2_0005.png-6f55b2b9c644ef31b21e0dcd11b57ec2.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_2_0005.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_2_0006.png-2e676cddde54f2d6eb922c7069f62736.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_2_0006.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0007.png-9474866534e92b9a05921a6d4857067d.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0007.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0008.png-824cc4850c09bfcbd2d1b0035a43e067.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0008.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0009.png-2e18df9058df064f6724510b64e7ba78.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0009.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0010.png-e4b40f869b92e6e9cd7307dc8d05489b.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0010.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0011.png-3aa009aa9fd5f1d11df53c6ac2f5b5df.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0011.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0012.png-7c170912d4a612a69a3c4e695f111c5f.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0012.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0013.png-bc3e7baa32067d83335a4e95cf4b741c.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0013.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0014.png-3722562c1d091de2a0b91e5cd8349db5.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0014.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0015.png-f464949052b0da7f6a17637e4b1661f6.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0015.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0016.png-4843269e6dc01a3544a9e4d926e1241a.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0016.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0017.png-ff620210c514d0a21957038f3916bd14.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0017.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0018.png-b36d4042dc59a8aaed3ffdceb402e501.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0018.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0019.png-e052941f9a25252589d938aa2627df8a.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0019.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0020.png-6268e8691232161d7624dcca11583e41.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0020.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0021.png-ed3d2424d7120473fbbadc074f4efd14.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0021.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0022.png-51a6f3b3e77c867242bc342972c33180.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0022.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0023.png-3e6859d04911c957f9489557b78b06cc.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0023.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0024.png-282d8d17bae6c8654d89674f1c32a197.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0024.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0025.png-ca5226424597c3ac543f265056272ac8.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0025.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0026.png-9e0d7fbc5fea747e938f546d364ee7ba.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0026.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0027.png-bc33f42a80a11ec8fe49ef20a0661a9a.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0027.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0028.png-25176d6154401916dcaa077304511057.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0028.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0029.png-49975c5c6af211692c84f9679331e1f3.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0029.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0030.png-56de73700cd6f6aa2936077195517479.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0030.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0031.png-52aac777105c1cd8f0b3ec0db04482d7.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0031.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0032.png-ff3d7f88100e92134cab2e7ccc4fd01b.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0032.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0033.png-e6d5817fff0854bd1857b949c443d2c7.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0033.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0034.png-5a8afc03d617da4ff4b9f6a9ee630db8.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0034.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0035.png-aacef661a413cdac61ab7b4b2347df30.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0035.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0036.png-66afe91228cbd5490fa49e5ea2f0335b.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0036.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0037.png-1d3c68ac96e6cf31b172295b3de067b5.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0037.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0038.png-ee2ee22a14ff22dfd3b5a6cde164af77.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0038.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0039.png-1060b4ca444a509a181dc11dc97444ec.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0039.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0040.png-fd2865b617e7b9d89d3e9766db0a3840.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0040.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0041.png-c97812285731470074b9c9e300ef9e65.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0041.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0042.png-0c39dcba0311b68852dba1f724f4be04.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0042.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0043.png-bfd2ba0016b2bdec0825f788a31ea897.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0043.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0044.png-97f3b7371f5b1724ee7d68221d6b1912.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0044.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0045.png-11acbd16bb764485e7ae2275107db149.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0045.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_3_0001.png-31fc37a9e42930004808f030423fd577.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_3_0001.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_3_0002.png-7c1bc4aeb3ff35b537bb53998bf69bab.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_3_0002.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_3_0003.png-5bf3295a4d9b8284bd0ac673a6309a08.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_3_0003.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_3_0004.png-5592b0dbe01a20f12ec8618b369c6f52.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_3_0004.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_3_0005.png-3c1230e43d81597f80567d873c55db13.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_3_0005.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_3_0006.png-45e84080bfd6afaaa0955b9cd46ff09d.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_3_0006.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_3_0007.png-8e3503f7074ae3023a0b9b132650b22a.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_3_0007.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_3_0008.png-26f083538118f1e8b42106e2f6372be2.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_3_0008.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_3_0009.png-10dbc8517bbc031463f3ae77296f97ad.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_3_0009.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_3_0010.png-08298348522f60379afec88de95bb2b7.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_3_0010.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0011.png-5a0bfc0660596d00b1cb8b891fb6fa10.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0011.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0012.png-ed0ac74b550525819c05e15a362549ef.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0012.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0013.png-4c02174a68c2dba29376b8c908786c25.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0013.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0014.png-13ebdda30cc330123a5790ca2a2555f0.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0014.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0015.png-5fbdce781159aadc35349c5a3bebb91e.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0015.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0016.png-e9d305e258e9afd8f205c0cac9fc78c3.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0016.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0017.png-d763659027a5da4cea16ec4fe382345e.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0017.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0018.png-d82463317106aa660a52a7533094d673.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0018.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0019.png-eaa1ae0ed50e2f4d68476dbcaa8962e7.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0019.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0020.png-62f9861f6e2cd96510d4f56c3f351d4b.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0020.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0021.png-5e787d913618906013f43632d4e23f11.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0021.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0022.png-4eb98c30c1306ecd14123de3db43457c.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0022.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0023.png-2ff3ddbdaf2d9b3685fdc173624c3912.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0023.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0024.png-b1dbed21965ad7787031e26dc7960277.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0024.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0025.png-17d0c92b90940d326db4bb0a82b3d7a5.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0025.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0026.png-63facc91904dbd66f32b0a101dc9318d.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0026.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0027.png-af9d4619028fe1327bae6f2acd8f4601.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0027.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0028.png-a10c2fc2c81e56539c59dc1ee413394c.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0028.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0029.png-daf87e63081f9c0a54447006bd2209b6.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0029.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0030.png-e0daaf8466b78886ee3c4d6a13c77a88.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0030.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0031.png-79dd733b6f4796896ee4754093cbf574.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0031.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0032.png-673d415399e336f57767622876a059cc.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0032.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0033.png-351ed26bf049f1c9f5b8f63b48fdc540.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0033.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0034.png-bf45ccd5b8ecb2498520ba55ea8fca90.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0034.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0035.png-4129cce2cdd07ba02d5c20ca4c246a11.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0035.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0036.png-abf04b2b00fe88fdd23ad0bea5df2f99.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0036.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0037.png-751d3c8b75838e4c057b69baa189a6fb.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0037.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0038.png-8a31cb5390a0d5e3a37469e403fc9ea0.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0038.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0039.png-360cb8e786195be9e7dfb3c3a41fae55.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0039.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0040.png-4668837ad40cd17338f2a3a499a99944.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0040.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0041.png-4ede56ee72e588a4885b2b8d46d20b13.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0041.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0042.png-3f2669e912059103f59dd7cbdf921b09.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0042.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0043.png-cf5aae44be164daae0adafb255e53c3a.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0043.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0044.png-8171ad75fd9c98d5eb123b4fcc2fe1d0.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0044.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0045.png-739fee3a1c4268b262bce228f3c25540.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0045.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_4_0001.png-44c0140589c9477c53e693ca422a610f.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_4_0001.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_4_0002.png-03e83ca13844bf120ff9f33592cabb55.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_4_0002.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_4_0003.png-5a067b1ce8c2abce9d265d1085006aa2.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_4_0003.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_4_0004.png-3e737cb0da6ac2bbf67f17e9de4541da.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_4_0004.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_4_0005.png-50ca1e2ace0ad812aa8e4658e5fbc49b.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_4_0005.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_4_0006.png-cbaebc60f655a63514a9ee42bbe601a8.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_4_0006.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_4_0007.png-9b4fde0a646fd92a84a198f3308e7f9c.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_4_0007.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_4_0008.png-914cc8543e9f50ced206fb184b891a30.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_4_0008.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_4_0009.png-f906857f39f7c9499bf866179301a8fa.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_4_0009.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_4_0010.png-e5aea61231082aa35a21f40f2712ec09.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_4_0010.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0011.png-046e49dffaa400aa7376d9ab1b6427b9.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0011.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0012.png-fd1244d2744d4afcec69891ea22bf3ef.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0012.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0013.png-7b2b287a5acb0f329ec30bd468e72c1b.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0013.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0014.png-a86ccdbf773101b21bcc3797b678b648.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0014.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0015.png-b58405815ea0731a85856890e866e793.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0015.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0016.png-81e83a46d052604fb757f7c0412bfeb0.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0016.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0017.png-39333cb64f3c2877e9b4b20f86f02771.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0017.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0018.png-4003cb82bd9d789910f6f8d31a8bec48.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0018.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0019.png-dead4a6a63153cb0b9b7931f5ae678ed.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0019.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0020.png-71b2b2ce20e8fbab8b36a7ca71ba801c.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0020.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0021.png-ec51ee3073d172fbdb1752fe73b64753.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0021.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0022.png-c9d441a84209b2fd15a00faa56fb1251.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0022.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0023.png-2ce81c611a182118a20d5505faf43e96.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0023.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0024.png-8de87e72e639b46d062c45e528d5ca76.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0024.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0025.png-0c9d69a0d7dd65f8c19b5d14c8c9e938.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0025.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0026.png-b4078c194745d66f3f8b16c33db101ba.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0026.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0027.png-a0e8070b2a4b990a2fa3970d09ed07df.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0027.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0028.png-81d472d161be45c7797b5fbf138424a3.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0028.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0029.png-89b8cb45ca54fce7e0b0a4345dd77e09.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0029.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0030.png-a4ea7e588e4207342eab45b6bece9b09.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0030.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0031.png-56f62fd7bf021bdf915f7a99d49c25d4.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0031.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0032.png-a02734f8bdb2a9ad41fa7f5b015afc87.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0032.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0033.png-6d81174d22f2c4d14bcd6a92aedafe5c.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0033.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0034.png-65e08bf7b6548c7094aa67e59f0be8be.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0034.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0035.png-be32669bf98db3b34e6df6590b21a192.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0035.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0036.png-0d1a5b53a63e57bd8542ccb7f3bb3f64.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0036.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0037.png-f3e55a4dc2b84a975bbdeb291c52bf65.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0037.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0038.png-4a5bd9cfd14b5deedd060279575f5aef.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0038.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0039.png-c90075c8d1b9a00ed5bb2713007533a9.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0039.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0040.png-1bb4300271bd8cde60ac4bf231cad3f8.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0040.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0041.png-24f218bb887697ebff8afbc939c66102.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0041.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0042.png-32f0cb46cb07386daf5336ede400072f.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0042.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0043.png-c29414dfe98a0fffa05aa08c80b5a047.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0043.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0044.png-267944e3e6bc3dffcd6632d486270177.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0044.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0045.png-7d4f63980d87410e0f5f75d6fcd7980f.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0045.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_5_0001.png-54ecb67a3b64ef53b95f38cfcaab5d7e.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_5_0001.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_5_0002.png-4be9ff92bf6613ac5f0532ee594c9f8d.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_5_0002.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_5_0003.png-02ae3ecccec6854388104446a5cce060.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_5_0003.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_5_0004.png-78f400ba5159020d0cc327fb7751626b.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_5_0004.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_5_0005.png-a61599f3a6912253a4ee8a46f2179ee0.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_5_0005.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_5_0006.png-a7a9166dcc80e53082039570e987d60e.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_5_0006.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_5_0007.png-97719fa861936e98f05b1c47c7437edb.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_5_0007.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_5_0008.png-bfa0a41e9582b4220810342faa17048b.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_5_0008.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_5_0009.png-222b7f2c0ba311d0eb36c49e18d4fac0.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_5_0009.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_5_0010.png-a0a53aaa4f0d1e1d0b151c9561284562.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_5_0010.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_5_0011.png-718b2daecc82a6b8e27bafe5e48aeeda.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_5_0011.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_5_0012.png-0165b583c3cf87032ff35631b2e3e95a.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_5_0012.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_5_0013.png-838fe2b9da91889799d90ec54c4cc969.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_5_0013.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_5_0014.png-d8663fd1c9ebf299c93e7dc67e26f95f.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_5_0014.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0015.png-2100f509d345cd07461664ab3eaa81dd.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0015.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0016.png-226901d9b28cf7df2decd0451326d75c.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0016.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0017.png-dfd5420cd9b200935c84bf0f4cac4ab0.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0017.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0018.png-aa2e5c55ce7ff835a3ea1c42d9837741.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0018.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0019.png-a943751b68884dfc46fbb0c2c0d5178b.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0019.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0020.png-3584c763a7727de0c392a8c618354c88.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0020.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0021.png-79793cf9cbb8fe9c5c92a8a8c186c165.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0021.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0022.png-ea8d8f9eacfcc6ad60cf0eac8f76bb2d.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0022.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0023.png-f2938d845123450a87fd6be27d904951.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0023.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0024.png-a231cbffffd158111eb4a45e6c9494ab.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0024.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0025.png-fe9f38a76a4fcb7b388729392facaaf2.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0025.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0026.png-e8934ff24161fe66919d3f09ded05027.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0026.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0027.png-26da75d75afe8b79255c43e3d8e08e98.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0027.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0028.png-d694010607039d58c26ddbd9f48585be.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0028.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0029.png-800bbbc0a1f0dae81fe7ae5f7e27f370.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0029.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0030.png-7b64c82c5a0463a9b47161a4935e60ce.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0030.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0031.png-acfc1df8e7d5e6d193dfc8220f1db0ee.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0031.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0032.png-423371a1636bc3f76ff44be178654e40.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0032.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0033.png-78216bae1d9c00088dcc3233e62ca4db.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0033.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0034.png-34a0b317ec360b1b06a2262b63ffae14.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0034.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0035.png-62cf4a4fa40fc11ae23842db81261d48.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0035.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0036.png-38c419c3886c9f73785214229b1e5e8a.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0036.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0037.png-70052c6484a98cf0e42ae14e7c15da95.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0037.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0038.png-c0bf8c173fa4868b88096fb5ef6cd786.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0038.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0039.png-976536a45ab5477c7df7d1c99b776380.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0039.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0040.png-ba9bce1718013b82ef4d19d9b0f1c763.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0040.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0041.png-46f91cd851a5f818c5a02091783f1be4.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0041.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0042.png-02de82baf6bddc7ed4ba0f7cb97fcc55.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0042.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0043.png-c35a6a6a429dcfc7d718438169e5de18.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0043.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0044.png-ce3e123d0b3626a753b875112d502854.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0044.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0045.png-6852b5c6ea7d3ebfd8e76ca923623c0e.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0045.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_6_0001.png-305ad0570c16badf494841e57f4ba611.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_6_0001.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_6_0002.png-22826ad2b1480d94ac49569140300b7d.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_6_0002.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_6_0003.png-2ddfab84d846eea12800d2ae3258d124.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_6_0003.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_6_0004.png-198bf0b806aed2f6d3c931a62777c72b.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_6_0004.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_6_0005.png-2843d807360986b608946b90e888010b.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_6_0005.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_6_0006.png-3e9d956ac832e00cd3c5c5e88b3ed985.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_6_0006.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_6_0007.png-5d37f95317537321949f3aa1b3bdaec5.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_6_0007.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_6_0008.png-5e47c714d8975acee8a61f03c7e1c8a8.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_6_0008.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_6_0009.png-a5ff6975ef9d035dc44e9369a7633b7b.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_6_0009.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_6_0010.png-18fefd47204b86c43402b80449215e5d.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_6_0010.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_6_0011.png-403f81f4712d87a6fc7bc293abfe951c.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_6_0011.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_6_0012.png-7a43de7f34962670014e2fa8cf58bdbd.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_6_0012.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_6_0013.png-6997758c5a879c6dfebd9bf83fb80b19.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_6_0013.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_6_0014.png-cded909ae25b702d64c05cd7ae0d2f13.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_6_0014.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0015.png-66aeb5bd0bc542fc175fec55a3bf6087.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0015.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0016.png-b938bf7a70c22eb9d70fcaf577311100.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0016.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0017.png-176b7f93ffdda965c54bdd0eb9326d9b.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0017.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0018.png-f92b96743b8714dcbaf521b80eafbf3f.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0018.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0019.png-5761e61793846e110d7703fd46cae4d4.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0019.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0020.png-8a75df3dc801931a2f4c8ace65113319.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0020.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0021.png-9a33865f02a031907cbfe0e27fd35f00.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0021.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0022.png-3e67df7c6e0a065b498d39b0c08b0312.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0022.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0023.png-7f64aa280564aebe45e5dc0d8d9d5c16.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0023.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0024.png-88f09f26e628d7d315ce59732ccc2834.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0024.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0025.png-0b3af2fa1d2cbbfd99d4ee002fb12840.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0025.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0026.png-021f4a1a723c8d54576610d04d7fd57f.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0026.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0027.png-44e3d8b5ff0f346c8104b4032f560f71.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0027.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0028.png-1105d75f85506ccc5746fbd864b24fff.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0028.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0029.png-e4b4caed37291002953d56f4ca4131ab.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0029.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0030.png-61625df132dbbd128d4e1f75e75aabfc.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0030.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0031.png-d749cc2494f059267e4e7df5116e8622.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0031.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0032.png-71a30f79d5da9c1b438f22b398b5dab1.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0032.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0033.png-1581d03ab3875a38a17e89ed97f9e4b7.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0033.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0034.png-901410a3b9a1123e4fe9c6c067e84996.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0034.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0035.png-0ca73a5099e5ee470642737d3d349212.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0035.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0036.png-74212616df9d8d718bb761f75646bcc1.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0036.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0037.png-b8f3cd7f00d11e1738def20ba138ad31.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0037.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0038.png-de4b8fd9a432a6d0cb6d62a70779f107.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0038.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0039.png-30fe4a5d0248c94f51c386de6818aab0.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0039.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0040.png-01c5d066ea63da2b2939414aab6b7897.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0040.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0041.png-36d9495a377e03e36d424fd98695a054.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0041.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0042.png-0d3be26f076a11fe04aa48150607f766.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0042.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0043.png-b9f2da0ea4ca216970722097f128bbd1.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0043.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0044.png-3f84695fc07f7b738486280eb5603000.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0044.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0045.png-deb75272ecbeaf94c9d8a660d7c0ac85.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0045.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_7_0001.png-f56163f66408f9b4868c963b7ccdc888.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_7_0001.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_7_0002.png-c0fe11e0a41fb3e172cad384ea0d6fdb.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_7_0002.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_7_0003.png-80353ff236d3b9e9529d95b234901c2f.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_7_0003.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_7_0004.png-f17b8c72db6c5a5555c1e058a4fdb37d.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_7_0004.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_7_0005.png-9b495c651b85e4394c7278ed9117f507.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_7_0005.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_7_0006.png-b55337d24f1991722d24974127890164.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_7_0006.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_7_0007.png-3f74fdb57cdfb5cf92632111c7c47353.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_7_0007.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_7_0008.png-14fff645fc469a9ca37da44571c8bf40.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_7_0008.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_7_0009.png-44a989bb4ef8aec21b41ccf787b8ad79.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_7_0009.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_7_0010.png-f8b6efa1bc0fdde4984d18d79ab2b87a.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_7_0010.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_7_0011.png-8d079e563451cb648d05f12fcd83410e.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_7_0011.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_7_0012.png-c481686c32eb52fd6fd4412c6d7b4b4e.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_7_0012.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_7_0013.png-230ea27940975966523df263c58504ff.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_7_0013.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_7_0014.png-cd9b475b011d51a12b5035e2f55c89a4.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_7_0014.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_7_0015.png-6462d0a0c363f5a418682bbd99cfee9f.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_7_0015.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_7_0016.png-1e525788b0aecb2c77f9c99b2c6e7961.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_7_0016.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_7_0017.png-fc1fb54f89a66e7672a3dea4977bf5dd.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_7_0017.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_7_0018.png-ab4b697f5439f7562d6495d6ca1b21c2.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_7_0018.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0019.png-d6adf250f69ca718c20f2b6f1e1dab8b.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0019.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0020.png-13e81bed771a378dd92fe3e44a5dcae9.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0020.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0021.png-95025a26723093c478b81f9159680c72.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0021.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0022.png-7119dbcacfdc1fbeea0a4908fde2ad4c.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0022.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0023.png-42911aed0fd1e7b00c59d14e1d3bd2ec.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0023.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0024.png-cd0313892fa0271db3530d704b558c3a.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0024.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0025.png-e837b778cf6654dccb6e1c3cac343e06.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0025.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0026.png-c14e9001cf3dbffbd89121685a29876b.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0026.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0027.png-410a93b758978f6107af16ca2265aaca.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0027.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0028.png-f441389b1b2984eba015ff3018824976.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0028.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0029.png-37b4c07a4c3f14a34495ee55687869f8.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0029.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0030.png-ef549d8584817425a792f64d53b357de.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0030.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0031.png-368fd541b5b5219ce5724ebf77b504e3.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0031.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0032.png-5862cafb570810c768df0659dbd21c86.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0032.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0033.png-04b92d5998216baaca5ce78bc7e2b0ab.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0033.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0034.png-f360fbba45604b91d35ca2106e17547f.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0034.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0035.png-ab41dcabc7044bd63709f874ba63d42f.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0035.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0036.png-e59c70a78b8e861cb280f41a3eb39067.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0036.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0037.png-ac4072e6541b8df202a43dea56e7cd67.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0037.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0038.png-42cd164980ead0a5b2376797057244a2.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0038.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0039.png-7c2343a6c86942135313d0c4bc4f414e.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0039.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0040.png-5312afda3741127ce8a70bfb88de9549.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0040.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0041.png-9b4ca50bea3cbd33520b6451fc976146.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0041.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0042.png-435fab965479c665ead6209978a0e5fc.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0042.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0043.png-5bf45588c7753e97799660453a66348f.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0043.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0044.png-e710ee96e2dd522844ed77edfeac0918.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0044.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0045.png-9b82aafad83a15cdf5250f678768e4c3.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0045.png.import
	savepack: step 97: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d386ad401674f18d1edfd264d67ce020.scn
	savepack: step 97: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
	savepack: step 97: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-8f735e678b86df73bf8978d10c629e6f.s3tc.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
	savepack: step 97: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-8122c1ec715bcbe34a4661682b54b4c3.s3tc.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
	savepack: step 97: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-e909b100dc6bbda0c7e19c5e6c81bef1.s3tc.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
	savepack: step 97: Storing File: res://tests/_test_util.gd
	savepack: step 98: Storing File: res://tests/test_3d_player.gd
	savepack: step 98: Storing File: res://tests/test_5_systems.gd
	savepack: step 98: Storing File: res://tests/test_candy_pickup.gd
	savepack: step 98: Storing File: res://tests/test_critical_path.gd
	savepack: step 99: Storing File: res://tests/test_cursor_aiming.gd
	savepack: step 99: Storing File: res://tests/test_encounters.gd
	savepack: step 99: Storing File: res://tests/test_feel_combat.gd
	savepack: step 99: Storing File: res://tests/test_feel_movement.gd
	savepack: step 99: Storing File: res://tests/test_feel_traversal.gd
	savepack: step 100: Storing File: res://tests/test_flamethrower_particles.gd
	savepack: step 100: Storing File: res://tests/test_gameplay_fixes.gd
	savepack: step 100: Storing File: res://tests/test_grinding.gd
	savepack: step 100: Storing File: res://tests/test_menu_flow.gd
	savepack: step 101: Storing File: res://tests/test_onboarding.gd
	savepack: step 101: Storing File: res://tests/test_presentation.gd
	savepack: step 101: Storing File: res://tests/test_slice_e2e.gd
	savepack: step 101: Storing File: res://tests/test_systems.gd
	savepack: step 101: Storing File: res://scenes/dial_up_queen.tscn.remap
	savepack: step 101: Storing File: res://scenes/FloodedMall_Greybox.tscn.remap
	savepack: step 101: Storing File: res://scenes/health_candy_pickup.tscn.remap
	savepack: step 101: Storing File: res://scenes/intro.tscn.remap
	savepack: step 101: Storing File: res://scenes/main_menu.tscn.remap
	savepack: step 101: Storing File: res://scenes/neon_cicada.tscn.remap
	savepack: step 101: Storing File: res://scenes/player.tscn.remap
	savepack: step 101: Storing File: res://.godot/global_script_class_cache.cfg
	savepack: step 101: Storing File: res://icon.svg
	savepack: step 101: Storing File: res://.godot/uid_cache.bin
	savepack: step 101: Storing File: res://.godot/extension_list.cfg
	savepack: step 101: Storing File: res://project.binary
savepack: end

EXIT: 0 (qa)
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\Godot_v4.3-stable_win64.exe --version
4.3.stable.official.77dcf97d8

EXIT: 0 (version)
FILES: build/release (bytes)
199  build\release\BUILD-INFO.txt
679424  build\release\libbiopunk.windows.template_release.x86_64.dll
686  build\release\MUSIC-CREDITS.txt
185856  build\release\Y2K-BioPunk.console.exe
84214784  build\release\Y2K-BioPunk.exe
413121248  build\release\Y2K-BioPunk.pck
FILES: build/qa (bytes)
772096  build\qa\libbiopunk.windows.template_debug.x86_64.dll
185856  build\qa\Y2K-BioPunk-QA.console.exe
84108800  build\qa\Y2K-BioPunk-QA.exe
413028240  build\qa\Y2K-BioPunk-QA.pck
ZIP: 391003124 bytes  C:\y2k-biopunk-rpg\.worktrees\vs11export\build\Y2K-BioPunk-VS1.1-win64.zip
BUILD: PASS

```

Script exit code: `0`.

## Final packaged smoke (exit 1)

Command from the assigned worktree:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops/tools/smoke_packaged.ps1
```

Complete stdout/stderr captured with `*> ops/runs/export/smoke_packaged.completed.full.log` (line endings normalized for Markdown):

```text
Worktree: C:\y2k-biopunk-rpg\.worktrees\vs11export
Logs: C:\y2k-biopunk-rpg\.worktrees\vs11export\ops\runs\export\smoke_20261008_134229
PCK: C:\y2k-biopunk-rpg\.worktrees\vs11export\build\release\Y2K-BioPunk.pck (Godot 4.3.0, 854 entries)
RELEASE PCK DIRECTORY (bytes, resource path):
7074  res://.godot/exported/133200997/export-234fb6894ec6226e856ab7f825500d3d-player.scn
719  res://.godot/exported/133200997/export-72ee11ce23100f2096d10891190f557e-dial_up_queen.scn
1660  res://.godot/exported/133200997/export-aa3f5c97579d5c748215bbb2e364ddeb-intro.scn
650  res://.godot/exported/133200997/export-d9b46989ff26b563f7686f0a6c74ef08-health_candy_pickup.scn
4456  res://.godot/exported/133200997/export-e098924b008c7d9e49d8e825c974b95b-neon_cicada.scn
3404  res://.godot/exported/133200997/export-ea5c6ad4629af728dc514cefde332394-main_menu.scn
801079  res://.godot/exported/133200997/export-f257e87bfdc9f628dcc382c88547a250-FloodedMall_Greybox.scn
26  res://.godot/extension_list.cfg
827  res://.godot/global_script_class_cache.cfg
4285267  res://.godot/imported/anthem.mp3-2f7a92cf245df82890b7830193e2bea6.mp3str
4096559  res://.godot/imported/bigbeat.mp3-719a317dfac214297f4d640840ee7874.mp3str
4284015  res://.godot/imported/bubblegum.mp3-6600d7a64ddbbec66a2b18480a79e0ad.mp3str
3829483  res://.godot/imported/combat.mp3-1829eebac0ee46487ae84a3be83a352e.mp3str
23329773  res://.godot/imported/dial_up_queen.glb-c1a5cb2f8ad5373c4dcab5634b6375c1.scn
27146  res://.godot/imported/dir_0_0001.png-b710fbec88935683feaa9ce80bb168b5.ctex
27590  res://.godot/imported/dir_0_0002.png-0e5a2de3b5fd5d28ce436b421d055443.ctex
27558  res://.godot/imported/dir_0_0003.png-9b15b799a24f9fbfe900e8481215af28.ctex
27442  res://.godot/imported/dir_0_0004.png-7a93f1ab1179b0e965dc3faf9d34a601.ctex
27502  res://.godot/imported/dir_0_0005.png-a93eefa81d5de8b3df0e3a3ffa5a5a96.ctex
27394  res://.godot/imported/dir_0_0006.png-31078175cbbcda22f61172097a8379ef.ctex
27170  res://.godot/imported/dir_0_0007.png-5b49c7f21f56fa1f374a7643c4fa7f67.ctex
26722  res://.godot/imported/dir_0_0008.png-6d3590e2a1ac045c506836477d5759a0.ctex
26450  res://.godot/imported/dir_0_0009.png-14ae05c6400d3b747b38851b3f005a58.ctex
25718  res://.godot/imported/dir_0_0010.png-0d358bb0ba4f5b17b4fd2db4c1db63a0.ctex
25372  res://.godot/imported/dir_0_0011.png-66f8d32db6bd94489fa6462c63bb9e25.ctex
25006  res://.godot/imported/dir_0_0012.png-9af3e2a6a8140f68ca9c52822981ac4f.ctex
24660  res://.godot/imported/dir_0_0013.png-2c3132152db14b63df2020e769510265.ctex
24590  res://.godot/imported/dir_0_0014.png-9bee12fb872d8c3f8b14f8dc83a2e723.ctex
24060  res://.godot/imported/dir_0_0015.png-bf3931a65824eda506dac5cb70f66061.ctex
23998  res://.godot/imported/dir_0_0016.png-d5ef184284aa8dfbfa436acbd30ff617.ctex
24154  res://.godot/imported/dir_0_0017.png-95408049edb1e06eeca6a0623d844741.ctex
24288  res://.godot/imported/dir_0_0018.png-04ff2164a4e8823a45d760cb0f8c924c.ctex
24448  res://.godot/imported/dir_0_0019.png-bdf2ece8fc4b7d7339b68d8e3078e42d.ctex
24836  res://.godot/imported/dir_0_0020.png-5dafb0540cece6243250ba9fe2abcf9d.ctex
24480  res://.godot/imported/dir_0_0021.png-26b13f13a12aab931dc5a165ba2449d7.ctex
24346  res://.godot/imported/dir_0_0022.png-b7a7bcfe420d7715d19a0ab6614317de.ctex
23994  res://.godot/imported/dir_0_0023.png-323c1720fd734f8d4c3011866b334eaf.ctex
23572  res://.godot/imported/dir_0_0024.png-d2c8f2e1d387e065f473c9c433f9ddb7.ctex
22964  res://.godot/imported/dir_0_0025.png-1c40f3a80700734d053d96815854dfc0.ctex
22604  res://.godot/imported/dir_0_0026.png-c19f0c040198da8b7f9ee5df795757c2.ctex
22184  res://.godot/imported/dir_0_0027.png-ea9f0ee81748d1e693a28067922f5d2e.ctex
21812  res://.godot/imported/dir_0_0028.png-e24290a9e623664b03ab27acfb2650df.ctex
20952  res://.godot/imported/dir_0_0029.png-a3c0a06ce660b5e7c165b81610c54676.ctex
20484  res://.godot/imported/dir_0_0030.png-f6c9eac873d6fd0dbdc288b0fb569357.ctex
20116  res://.godot/imported/dir_0_0031.png-310e4fd4a08c8100e154b74c903283b5.ctex
19888  res://.godot/imported/dir_0_0032.png-f278b23644ae1ce5327c8b2c0b039452.ctex
19498  res://.godot/imported/dir_0_0033.png-cdb93ffb1ecb703add4499597912f067.ctex
19494  res://.godot/imported/dir_0_0034.png-fe43b2e0f994d038860628fea7c4f1d5.ctex
19150  res://.godot/imported/dir_0_0035.png-f4fa13aed07d11601dfd153b5d5242bf.ctex
19230  res://.godot/imported/dir_0_0036.png-bffcb23fb884cd6d25a3ac3a0412b507.ctex
19088  res://.godot/imported/dir_0_0037.png-68914dedfaad711accc4409744a56e4d.ctex
18848  res://.godot/imported/dir_0_0038.png-1dab661763c48455fedaf2e96dd5a07a.ctex
18572  res://.godot/imported/dir_0_0039.png-7032a0cb4ab60b64402bf0c907e4ca54.ctex
18246  res://.godot/imported/dir_0_0040.png-302ba8cb31466cb6ea3dc8dc997b3c57.ctex
17904  res://.godot/imported/dir_0_0041.png-2c61cdb0875d6e6575cbc0df76d37a17.ctex
17728  res://.godot/imported/dir_0_0042.png-6659fdb2494734652654c028ea5087fc.ctex
17474  res://.godot/imported/dir_0_0043.png-0c7e915e718028acacfedaad679e0227.ctex
17166  res://.godot/imported/dir_0_0044.png-01e3e2dc516f2dcdf7b4aa7a81620deb.ctex
17166  res://.godot/imported/dir_0_0045.png-2c2a1680b70e12826afc1b2b3b9e29b7.ctex
25076  res://.godot/imported/dir_1_0001.png-bdb495a9757bdad6797f07eb8555971a.ctex
25298  res://.godot/imported/dir_1_0002.png-934840a768165d77186589af676f8a4e.ctex
25700  res://.godot/imported/dir_1_0003.png-050f68e9fff75da7614b94ff90773eed.ctex
25726  res://.godot/imported/dir_1_0004.png-ebd21421acf611af84f966b5091ce26b.ctex
25936  res://.godot/imported/dir_1_0005.png-555a0784cf791c3641ccbc1c5990fb87.ctex
26268  res://.godot/imported/dir_1_0006.png-ca0673a91afce76bf8874c74463838f1.ctex
26242  res://.godot/imported/dir_1_0007.png-1214b7a104d06df3c3d497bcd1be1834.ctex
26258  res://.godot/imported/dir_1_0008.png-f8a89ef405120ae9a8bf879e19cdfa97.ctex
26288  res://.godot/imported/dir_1_0009.png-5dcfbd387d83e1ba7227231c891d949a.ctex
26154  res://.godot/imported/dir_1_0010.png-f87d76a8175e6446982bab4d7d54ea61.ctex
25972  res://.godot/imported/dir_1_0011.png-0337dba63b70dc413b74a06679b6f28c.ctex
25806  res://.godot/imported/dir_1_0012.png-03f5f787850b85bee05c351073002118.ctex
25188  res://.godot/imported/dir_1_0013.png-b30021586e7c63704890c71eb3a782d9.ctex
25106  res://.godot/imported/dir_1_0014.png-1564734f8bb6b3ba6603a743ca7f2575.ctex
25042  res://.godot/imported/dir_1_0015.png-e710f55eee5b4c83238640df6bd82846.ctex
24812  res://.godot/imported/dir_1_0016.png-0b030e77519508ff1c669f94a1909f94.ctex
24342  res://.godot/imported/dir_1_0017.png-e82a6bdd5771e6423a06a0f7342f6e3b.ctex
23636  res://.godot/imported/dir_1_0018.png-522091f455426a018d858f5e03c2ab2e.ctex
23752  res://.godot/imported/dir_1_0019.png-58201ff8f09e92ec1da1b349fe68db5b.ctex
23314  res://.godot/imported/dir_1_0020.png-594e00db2708c2beb29bc93b558dacc3.ctex
22698  res://.godot/imported/dir_1_0021.png-074a2e39d733763b37f5b5023df8dfa2.ctex
22370  res://.godot/imported/dir_1_0022.png-b8945aba745c3588278faeaf7e1419d4.ctex
22588  res://.godot/imported/dir_1_0023.png-5574c663a5fd93f4f03c7eb49828e01a.ctex
22156  res://.godot/imported/dir_1_0024.png-60b1a3cd41d1449cc00f64ac3a3f2024.ctex
21602  res://.godot/imported/dir_1_0025.png-fb4f2085498167f038dea4b9ec1c2279.ctex
20740  res://.godot/imported/dir_1_0026.png-3265acf35ac991ca8f99d9158ac0c1ec.ctex
20388  res://.godot/imported/dir_1_0027.png-3418243241bb87f5dc647a772a0efb43.ctex
20454  res://.godot/imported/dir_1_0028.png-ee04ca2d0c1aec65325fa925b01c7b1f.ctex
20214  res://.godot/imported/dir_1_0029.png-b38794b7bc2ffad1ed4ba99b92cc7227.ctex
19534  res://.godot/imported/dir_1_0030.png-671d0253c720699f7c3aa085a63e2a5b.ctex
19374  res://.godot/imported/dir_1_0031.png-89b3713d6f7838cee10dd042401d3fad.ctex
18898  res://.godot/imported/dir_1_0032.png-2593f66ac31520f96e7fa30959a43e91.ctex
18198  res://.godot/imported/dir_1_0033.png-f661de841ee888883396bbe72741b344.ctex
17952  res://.godot/imported/dir_1_0034.png-dec28c10562b756dfd86ca58b3e77c40.ctex
17310  res://.godot/imported/dir_1_0035.png-1ce258d5745a5fe65a0fd18bfe165fff.ctex
16260  res://.godot/imported/dir_1_0036.png-8b7624a493e1a0760ebb2d1f085a37d6.ctex
15544  res://.godot/imported/dir_1_0037.png-41f34d23b8fa74a0072956b37088e759.ctex
14540  res://.godot/imported/dir_1_0038.png-55a78398a9df364419def19f4ce95af0.ctex
13566  res://.godot/imported/dir_1_0039.png-e7a80ce8f9a02fe1310fe47958fd1d41.ctex
12840  res://.godot/imported/dir_1_0040.png-b787b560ded3a9fa62bdd1b77723786c.ctex
12030  res://.godot/imported/dir_1_0041.png-9690a7eae3341348c1f95f5602be05aa.ctex
11778  res://.godot/imported/dir_1_0042.png-7ebe60fb7dda624362b76375368134dd.ctex
11660  res://.godot/imported/dir_1_0043.png-7d23a42240b59f04fe4b48547e8f6da9.ctex
11430  res://.godot/imported/dir_1_0044.png-0a5dc74966e7dc5eab92fdf6420ea36a.ctex
11430  res://.godot/imported/dir_1_0045.png-612dd05ef6ba543963834c97608a32a8.ctex
20582  res://.godot/imported/dir_2_0001.png-5edef45f93b3c30215829a5f4ee539a5.ctex
21696  res://.godot/imported/dir_2_0002.png-0dc81ff8f64a189a3b647d52dfacf8ea.ctex
22324  res://.godot/imported/dir_2_0003.png-8a0453cc9f955415e5f82c386c9ca46c.ctex
22764  res://.godot/imported/dir_2_0004.png-9ae7dde74db7dd14c7cbe87d30c66b68.ctex
23154  res://.godot/imported/dir_2_0005.png-6f55b2b9c644ef31b21e0dcd11b57ec2.ctex
23834  res://.godot/imported/dir_2_0006.png-2e676cddde54f2d6eb922c7069f62736.ctex
24078  res://.godot/imported/dir_2_0007.png-9474866534e92b9a05921a6d4857067d.ctex
24364  res://.godot/imported/dir_2_0008.png-824cc4850c09bfcbd2d1b0035a43e067.ctex
24160  res://.godot/imported/dir_2_0009.png-2e18df9058df064f6724510b64e7ba78.ctex
24316  res://.godot/imported/dir_2_0010.png-e4b40f869b92e6e9cd7307dc8d05489b.ctex
24408  res://.godot/imported/dir_2_0011.png-3aa009aa9fd5f1d11df53c6ac2f5b5df.ctex
24312  res://.godot/imported/dir_2_0012.png-7c170912d4a612a69a3c4e695f111c5f.ctex
24454  res://.godot/imported/dir_2_0013.png-bc3e7baa32067d83335a4e95cf4b741c.ctex
24422  res://.godot/imported/dir_2_0014.png-3722562c1d091de2a0b91e5cd8349db5.ctex
23910  res://.godot/imported/dir_2_0015.png-f464949052b0da7f6a17637e4b1661f6.ctex
23482  res://.godot/imported/dir_2_0016.png-4843269e6dc01a3544a9e4d926e1241a.ctex
23370  res://.godot/imported/dir_2_0017.png-ff620210c514d0a21957038f3916bd14.ctex
22636  res://.godot/imported/dir_2_0018.png-b36d4042dc59a8aaed3ffdceb402e501.ctex
22132  res://.godot/imported/dir_2_0019.png-e052941f9a25252589d938aa2627df8a.ctex
21498  res://.godot/imported/dir_2_0020.png-6268e8691232161d7624dcca11583e41.ctex
21070  res://.godot/imported/dir_2_0021.png-ed3d2424d7120473fbbadc074f4efd14.ctex
19530  res://.godot/imported/dir_2_0022.png-51a6f3b3e77c867242bc342972c33180.ctex
18506  res://.godot/imported/dir_2_0023.png-3e6859d04911c957f9489557b78b06cc.ctex
18206  res://.godot/imported/dir_2_0024.png-282d8d17bae6c8654d89674f1c32a197.ctex
18000  res://.godot/imported/dir_2_0025.png-ca5226424597c3ac543f265056272ac8.ctex
17240  res://.godot/imported/dir_2_0026.png-9e0d7fbc5fea747e938f546d364ee7ba.ctex
16568  res://.godot/imported/dir_2_0027.png-bc33f42a80a11ec8fe49ef20a0661a9a.ctex
15608  res://.godot/imported/dir_2_0028.png-25176d6154401916dcaa077304511057.ctex
14842  res://.godot/imported/dir_2_0029.png-49975c5c6af211692c84f9679331e1f3.ctex
13986  res://.godot/imported/dir_2_0030.png-56de73700cd6f6aa2936077195517479.ctex
13264  res://.godot/imported/dir_2_0031.png-52aac777105c1cd8f0b3ec0db04482d7.ctex
12542  res://.godot/imported/dir_2_0032.png-ff3d7f88100e92134cab2e7ccc4fd01b.ctex
11552  res://.godot/imported/dir_2_0033.png-e6d5817fff0854bd1857b949c443d2c7.ctex
10262  res://.godot/imported/dir_2_0034.png-5a8afc03d617da4ff4b9f6a9ee630db8.ctex
8604  res://.godot/imported/dir_2_0035.png-aacef661a413cdac61ab7b4b2347df30.ctex
8172  res://.godot/imported/dir_2_0036.png-66afe91228cbd5490fa49e5ea2f0335b.ctex
7564  res://.godot/imported/dir_2_0037.png-1d3c68ac96e6cf31b172295b3de067b5.ctex
6950  res://.godot/imported/dir_2_0038.png-ee2ee22a14ff22dfd3b5a6cde164af77.ctex
6020  res://.godot/imported/dir_2_0039.png-1060b4ca444a509a181dc11dc97444ec.ctex
3580  res://.godot/imported/dir_2_0040.png-fd2865b617e7b9d89d3e9766db0a3840.ctex
3580  res://.godot/imported/dir_2_0041.png-c97812285731470074b9c9e300ef9e65.ctex
3580  res://.godot/imported/dir_2_0042.png-0c39dcba0311b68852dba1f724f4be04.ctex
3580  res://.godot/imported/dir_2_0043.png-bfd2ba0016b2bdec0825f788a31ea897.ctex
3580  res://.godot/imported/dir_2_0044.png-97f3b7371f5b1724ee7d68221d6b1912.ctex
3580  res://.godot/imported/dir_2_0045.png-11acbd16bb764485e7ae2275107db149.ctex
22256  res://.godot/imported/dir_3_0001.png-31fc37a9e42930004808f030423fd577.ctex
22350  res://.godot/imported/dir_3_0002.png-7c1bc4aeb3ff35b537bb53998bf69bab.ctex
21868  res://.godot/imported/dir_3_0003.png-5bf3295a4d9b8284bd0ac673a6309a08.ctex
21594  res://.godot/imported/dir_3_0004.png-5592b0dbe01a20f12ec8618b369c6f52.ctex
21824  res://.godot/imported/dir_3_0005.png-3c1230e43d81597f80567d873c55db13.ctex
21736  res://.godot/imported/dir_3_0006.png-45e84080bfd6afaaa0955b9cd46ff09d.ctex
21760  res://.godot/imported/dir_3_0007.png-8e3503f7074ae3023a0b9b132650b22a.ctex
21972  res://.godot/imported/dir_3_0008.png-26f083538118f1e8b42106e2f6372be2.ctex
22384  res://.godot/imported/dir_3_0009.png-10dbc8517bbc031463f3ae77296f97ad.ctex
22142  res://.godot/imported/dir_3_0010.png-08298348522f60379afec88de95bb2b7.ctex
22132  res://.godot/imported/dir_3_0011.png-5a0bfc0660596d00b1cb8b891fb6fa10.ctex
22234  res://.godot/imported/dir_3_0012.png-ed0ac74b550525819c05e15a362549ef.ctex
22454  res://.godot/imported/dir_3_0013.png-4c02174a68c2dba29376b8c908786c25.ctex
21908  res://.godot/imported/dir_3_0014.png-13ebdda30cc330123a5790ca2a2555f0.ctex
21620  res://.godot/imported/dir_3_0015.png-5fbdce781159aadc35349c5a3bebb91e.ctex
21478  res://.godot/imported/dir_3_0016.png-e9d305e258e9afd8f205c0cac9fc78c3.ctex
21358  res://.godot/imported/dir_3_0017.png-d763659027a5da4cea16ec4fe382345e.ctex
21132  res://.godot/imported/dir_3_0018.png-d82463317106aa660a52a7533094d673.ctex
21106  res://.godot/imported/dir_3_0019.png-eaa1ae0ed50e2f4d68476dbcaa8962e7.ctex
21298  res://.godot/imported/dir_3_0020.png-62f9861f6e2cd96510d4f56c3f351d4b.ctex
21096  res://.godot/imported/dir_3_0021.png-5e787d913618906013f43632d4e23f11.ctex
20624  res://.godot/imported/dir_3_0022.png-4eb98c30c1306ecd14123de3db43457c.ctex
19728  res://.godot/imported/dir_3_0023.png-2ff3ddbdaf2d9b3685fdc173624c3912.ctex
18656  res://.godot/imported/dir_3_0024.png-b1dbed21965ad7787031e26dc7960277.ctex
18368  res://.godot/imported/dir_3_0025.png-17d0c92b90940d326db4bb0a82b3d7a5.ctex
18272  res://.godot/imported/dir_3_0026.png-63facc91904dbd66f32b0a101dc9318d.ctex
18476  res://.godot/imported/dir_3_0027.png-af9d4619028fe1327bae6f2acd8f4601.ctex
18352  res://.godot/imported/dir_3_0028.png-a10c2fc2c81e56539c59dc1ee413394c.ctex
17990  res://.godot/imported/dir_3_0029.png-daf87e63081f9c0a54447006bd2209b6.ctex
17584  res://.godot/imported/dir_3_0030.png-e0daaf8466b78886ee3c4d6a13c77a88.ctex
17178  res://.godot/imported/dir_3_0031.png-79dd733b6f4796896ee4754093cbf574.ctex
16816  res://.godot/imported/dir_3_0032.png-673d415399e336f57767622876a059cc.ctex
15894  res://.godot/imported/dir_3_0033.png-351ed26bf049f1c9f5b8f63b48fdc540.ctex
15252  res://.godot/imported/dir_3_0034.png-bf45ccd5b8ecb2498520ba55ea8fca90.ctex
14540  res://.godot/imported/dir_3_0035.png-4129cce2cdd07ba02d5c20ca4c246a11.ctex
13832  res://.godot/imported/dir_3_0036.png-abf04b2b00fe88fdd23ad0bea5df2f99.ctex
13238  res://.godot/imported/dir_3_0037.png-751d3c8b75838e4c057b69baa189a6fb.ctex
12568  res://.godot/imported/dir_3_0038.png-8a31cb5390a0d5e3a37469e403fc9ea0.ctex
11772  res://.godot/imported/dir_3_0039.png-360cb8e786195be9e7dfb3c3a41fae55.ctex
10576  res://.godot/imported/dir_3_0040.png-4668837ad40cd17338f2a3a499a99944.ctex
9364  res://.godot/imported/dir_3_0041.png-4ede56ee72e588a4885b2b8d46d20b13.ctex
8486  res://.godot/imported/dir_3_0042.png-3f2669e912059103f59dd7cbdf921b09.ctex
7806  res://.godot/imported/dir_3_0043.png-cf5aae44be164daae0adafb255e53c3a.ctex
7470  res://.godot/imported/dir_3_0044.png-8171ad75fd9c98d5eb123b4fcc2fe1d0.ctex
7470  res://.godot/imported/dir_3_0045.png-739fee3a1c4268b262bce228f3c25540.ctex
24170  res://.godot/imported/dir_4_0001.png-44c0140589c9477c53e693ca422a610f.ctex
24354  res://.godot/imported/dir_4_0002.png-03e83ca13844bf120ff9f33592cabb55.ctex
24406  res://.godot/imported/dir_4_0003.png-5a067b1ce8c2abce9d265d1085006aa2.ctex
24216  res://.godot/imported/dir_4_0004.png-3e737cb0da6ac2bbf67f17e9de4541da.ctex
23850  res://.godot/imported/dir_4_0005.png-50ca1e2ace0ad812aa8e4658e5fbc49b.ctex
23840  res://.godot/imported/dir_4_0006.png-cbaebc60f655a63514a9ee42bbe601a8.ctex
23586  res://.godot/imported/dir_4_0007.png-9b4fde0a646fd92a84a198f3308e7f9c.ctex
23570  res://.godot/imported/dir_4_0008.png-914cc8543e9f50ced206fb184b891a30.ctex
23706  res://.godot/imported/dir_4_0009.png-f906857f39f7c9499bf866179301a8fa.ctex
23552  res://.godot/imported/dir_4_0010.png-e5aea61231082aa35a21f40f2712ec09.ctex
23350  res://.godot/imported/dir_4_0011.png-046e49dffaa400aa7376d9ab1b6427b9.ctex
23108  res://.godot/imported/dir_4_0012.png-fd1244d2744d4afcec69891ea22bf3ef.ctex
22868  res://.godot/imported/dir_4_0013.png-7b2b287a5acb0f329ec30bd468e72c1b.ctex
22482  res://.godot/imported/dir_4_0014.png-a86ccdbf773101b21bcc3797b678b648.ctex
22224  res://.godot/imported/dir_4_0015.png-b58405815ea0731a85856890e866e793.ctex
22182  res://.godot/imported/dir_4_0016.png-81e83a46d052604fb757f7c0412bfeb0.ctex
22060  res://.godot/imported/dir_4_0017.png-39333cb64f3c2877e9b4b20f86f02771.ctex
21698  res://.godot/imported/dir_4_0018.png-4003cb82bd9d789910f6f8d31a8bec48.ctex
21146  res://.godot/imported/dir_4_0019.png-dead4a6a63153cb0b9b7931f5ae678ed.ctex
20490  res://.godot/imported/dir_4_0020.png-71b2b2ce20e8fbab8b36a7ca71ba801c.ctex
20126  res://.godot/imported/dir_4_0021.png-ec51ee3073d172fbdb1752fe73b64753.ctex
19944  res://.godot/imported/dir_4_0022.png-c9d441a84209b2fd15a00faa56fb1251.ctex
19522  res://.godot/imported/dir_4_0023.png-2ce81c611a182118a20d5505faf43e96.ctex
18890  res://.godot/imported/dir_4_0024.png-8de87e72e639b46d062c45e528d5ca76.ctex
18142  res://.godot/imported/dir_4_0025.png-0c9d69a0d7dd65f8c19b5d14c8c9e938.ctex
17502  res://.godot/imported/dir_4_0026.png-b4078c194745d66f3f8b16c33db101ba.ctex
17018  res://.godot/imported/dir_4_0027.png-a0e8070b2a4b990a2fa3970d09ed07df.ctex
16654  res://.godot/imported/dir_4_0028.png-81d472d161be45c7797b5fbf138424a3.ctex
16586  res://.godot/imported/dir_4_0029.png-89b8cb45ca54fce7e0b0a4345dd77e09.ctex
16352  res://.godot/imported/dir_4_0030.png-a4ea7e588e4207342eab45b6bece9b09.ctex
16152  res://.godot/imported/dir_4_0031.png-56f62fd7bf021bdf915f7a99d49c25d4.ctex
16072  res://.godot/imported/dir_4_0032.png-a02734f8bdb2a9ad41fa7f5b015afc87.ctex
15792  res://.godot/imported/dir_4_0033.png-6d81174d22f2c4d14bcd6a92aedafe5c.ctex
15496  res://.godot/imported/dir_4_0034.png-65e08bf7b6548c7094aa67e59f0be8be.ctex
15090  res://.godot/imported/dir_4_0035.png-be32669bf98db3b34e6df6590b21a192.ctex
14432  res://.godot/imported/dir_4_0036.png-0d1a5b53a63e57bd8542ccb7f3bb3f64.ctex
14064  res://.godot/imported/dir_4_0037.png-f3e55a4dc2b84a975bbdeb291c52bf65.ctex
13660  res://.godot/imported/dir_4_0038.png-4a5bd9cfd14b5deedd060279575f5aef.ctex
13240  res://.godot/imported/dir_4_0039.png-c90075c8d1b9a00ed5bb2713007533a9.ctex
12834  res://.godot/imported/dir_4_0040.png-1bb4300271bd8cde60ac4bf231cad3f8.ctex
11838  res://.godot/imported/dir_4_0041.png-24f218bb887697ebff8afbc939c66102.ctex
11156  res://.godot/imported/dir_4_0042.png-32f0cb46cb07386daf5336ede400072f.ctex
11032  res://.godot/imported/dir_4_0043.png-c29414dfe98a0fffa05aa08c80b5a047.ctex
10870  res://.godot/imported/dir_4_0044.png-267944e3e6bc3dffcd6632d486270177.ctex
10870  res://.godot/imported/dir_4_0045.png-7d4f63980d87410e0f5f75d6fcd7980f.ctex
21978  res://.godot/imported/dir_5_0001.png-54ecb67a3b64ef53b95f38cfcaab5d7e.ctex
21864  res://.godot/imported/dir_5_0002.png-4be9ff92bf6613ac5f0532ee594c9f8d.ctex
21800  res://.godot/imported/dir_5_0003.png-02ae3ecccec6854388104446a5cce060.ctex
22190  res://.godot/imported/dir_5_0004.png-78f400ba5159020d0cc327fb7751626b.ctex
22656  res://.godot/imported/dir_5_0005.png-a61599f3a6912253a4ee8a46f2179ee0.ctex
23198  res://.godot/imported/dir_5_0006.png-a7a9166dcc80e53082039570e987d60e.ctex
23538  res://.godot/imported/dir_5_0007.png-97719fa861936e98f05b1c47c7437edb.ctex
23700  res://.godot/imported/dir_5_0008.png-bfa0a41e9582b4220810342faa17048b.ctex
23928  res://.godot/imported/dir_5_0009.png-222b7f2c0ba311d0eb36c49e18d4fac0.ctex
24078  res://.godot/imported/dir_5_0010.png-a0a53aaa4f0d1e1d0b151c9561284562.ctex
23962  res://.godot/imported/dir_5_0011.png-718b2daecc82a6b8e27bafe5e48aeeda.ctex
23744  res://.godot/imported/dir_5_0012.png-0165b583c3cf87032ff35631b2e3e95a.ctex
23496  res://.godot/imported/dir_5_0013.png-838fe2b9da91889799d90ec54c4cc969.ctex
23300  res://.godot/imported/dir_5_0014.png-d8663fd1c9ebf299c93e7dc67e26f95f.ctex
22378  res://.godot/imported/dir_5_0015.png-2100f509d345cd07461664ab3eaa81dd.ctex
21988  res://.godot/imported/dir_5_0016.png-226901d9b28cf7df2decd0451326d75c.ctex
21504  res://.godot/imported/dir_5_0017.png-dfd5420cd9b200935c84bf0f4cac4ab0.ctex
20640  res://.godot/imported/dir_5_0018.png-aa2e5c55ce7ff835a3ea1c42d9837741.ctex
19862  res://.godot/imported/dir_5_0019.png-a943751b68884dfc46fbb0c2c0d5178b.ctex
18890  res://.godot/imported/dir_5_0020.png-3584c763a7727de0c392a8c618354c88.ctex
17968  res://.godot/imported/dir_5_0021.png-79793cf9cbb8fe9c5c92a8a8c186c165.ctex
17404  res://.godot/imported/dir_5_0022.png-ea8d8f9eacfcc6ad60cf0eac8f76bb2d.ctex
17546  res://.godot/imported/dir_5_0023.png-f2938d845123450a87fd6be27d904951.ctex
17542  res://.godot/imported/dir_5_0024.png-a231cbffffd158111eb4a45e6c9494ab.ctex
17054  res://.godot/imported/dir_5_0025.png-fe9f38a76a4fcb7b388729392facaaf2.ctex
16910  res://.godot/imported/dir_5_0026.png-e8934ff24161fe66919d3f09ded05027.ctex
16762  res://.godot/imported/dir_5_0027.png-26da75d75afe8b79255c43e3d8e08e98.ctex
16674  res://.godot/imported/dir_5_0028.png-d694010607039d58c26ddbd9f48585be.ctex
16204  res://.godot/imported/dir_5_0029.png-800bbbc0a1f0dae81fe7ae5f7e27f370.ctex
15678  res://.godot/imported/dir_5_0030.png-7b64c82c5a0463a9b47161a4935e60ce.ctex
15830  res://.godot/imported/dir_5_0031.png-acfc1df8e7d5e6d193dfc8220f1db0ee.ctex
15672  res://.godot/imported/dir_5_0032.png-423371a1636bc3f76ff44be178654e40.ctex
15160  res://.godot/imported/dir_5_0033.png-78216bae1d9c00088dcc3233e62ca4db.ctex
14634  res://.godot/imported/dir_5_0034.png-34a0b317ec360b1b06a2262b63ffae14.ctex
13816  res://.godot/imported/dir_5_0035.png-62cf4a4fa40fc11ae23842db81261d48.ctex
12978  res://.godot/imported/dir_5_0036.png-38c419c3886c9f73785214229b1e5e8a.ctex
12142  res://.godot/imported/dir_5_0037.png-70052c6484a98cf0e42ae14e7c15da95.ctex
11336  res://.godot/imported/dir_5_0038.png-c0bf8c173fa4868b88096fb5ef6cd786.ctex
10586  res://.godot/imported/dir_5_0039.png-976536a45ab5477c7df7d1c99b776380.ctex
9904  res://.godot/imported/dir_5_0040.png-ba9bce1718013b82ef4d19d9b0f1c763.ctex
9642  res://.godot/imported/dir_5_0041.png-46f91cd851a5f818c5a02091783f1be4.ctex
8988  res://.godot/imported/dir_5_0042.png-02de82baf6bddc7ed4ba0f7cb97fcc55.ctex
8252  res://.godot/imported/dir_5_0043.png-c35a6a6a429dcfc7d718438169e5de18.ctex
7398  res://.godot/imported/dir_5_0044.png-ce3e123d0b3626a753b875112d502854.ctex
7398  res://.godot/imported/dir_5_0045.png-6852b5c6ea7d3ebfd8e76ca923623c0e.ctex
19908  res://.godot/imported/dir_6_0001.png-305ad0570c16badf494841e57f4ba611.ctex
20022  res://.godot/imported/dir_6_0002.png-22826ad2b1480d94ac49569140300b7d.ctex
20450  res://.godot/imported/dir_6_0003.png-2ddfab84d846eea12800d2ae3258d124.ctex
21016  res://.godot/imported/dir_6_0004.png-198bf0b806aed2f6d3c931a62777c72b.ctex
21476  res://.godot/imported/dir_6_0005.png-2843d807360986b608946b90e888010b.ctex
22108  res://.godot/imported/dir_6_0006.png-3e9d956ac832e00cd3c5c5e88b3ed985.ctex
22692  res://.godot/imported/dir_6_0007.png-5d37f95317537321949f3aa1b3bdaec5.ctex
22898  res://.godot/imported/dir_6_0008.png-5e47c714d8975acee8a61f03c7e1c8a8.ctex
23094  res://.godot/imported/dir_6_0009.png-a5ff6975ef9d035dc44e9369a7633b7b.ctex
22992  res://.godot/imported/dir_6_0010.png-18fefd47204b86c43402b80449215e5d.ctex
23036  res://.godot/imported/dir_6_0011.png-403f81f4712d87a6fc7bc293abfe951c.ctex
23454  res://.godot/imported/dir_6_0012.png-7a43de7f34962670014e2fa8cf58bdbd.ctex
23456  res://.godot/imported/dir_6_0013.png-6997758c5a879c6dfebd9bf83fb80b19.ctex
23200  res://.godot/imported/dir_6_0014.png-cded909ae25b702d64c05cd7ae0d2f13.ctex
22622  res://.godot/imported/dir_6_0015.png-66aeb5bd0bc542fc175fec55a3bf6087.ctex
21822  res://.godot/imported/dir_6_0016.png-b938bf7a70c22eb9d70fcaf577311100.ctex
21688  res://.godot/imported/dir_6_0017.png-176b7f93ffdda965c54bdd0eb9326d9b.ctex
21312  res://.godot/imported/dir_6_0018.png-f92b96743b8714dcbaf521b80eafbf3f.ctex
21188  res://.godot/imported/dir_6_0019.png-5761e61793846e110d7703fd46cae4d4.ctex
20790  res://.godot/imported/dir_6_0020.png-8a75df3dc801931a2f4c8ace65113319.ctex
20432  res://.godot/imported/dir_6_0021.png-9a33865f02a031907cbfe0e27fd35f00.ctex
19920  res://.godot/imported/dir_6_0022.png-3e67df7c6e0a065b498d39b0c08b0312.ctex
18882  res://.godot/imported/dir_6_0023.png-7f64aa280564aebe45e5dc0d8d9d5c16.ctex
18320  res://.godot/imported/dir_6_0024.png-88f09f26e628d7d315ce59732ccc2834.ctex
17382  res://.godot/imported/dir_6_0025.png-0b3af2fa1d2cbbfd99d4ee002fb12840.ctex
16332  res://.godot/imported/dir_6_0026.png-021f4a1a723c8d54576610d04d7fd57f.ctex
15486  res://.godot/imported/dir_6_0027.png-44e3d8b5ff0f346c8104b4032f560f71.ctex
14828  res://.godot/imported/dir_6_0028.png-1105d75f85506ccc5746fbd864b24fff.ctex
14232  res://.godot/imported/dir_6_0029.png-e4b4caed37291002953d56f4ca4131ab.ctex
13396  res://.godot/imported/dir_6_0030.png-61625df132dbbd128d4e1f75e75aabfc.ctex
12852  res://.godot/imported/dir_6_0031.png-d749cc2494f059267e4e7df5116e8622.ctex
12046  res://.godot/imported/dir_6_0032.png-71a30f79d5da9c1b438f22b398b5dab1.ctex
10890  res://.godot/imported/dir_6_0033.png-1581d03ab3875a38a17e89ed97f9e4b7.ctex
9688  res://.godot/imported/dir_6_0034.png-901410a3b9a1123e4fe9c6c067e84996.ctex
8218  res://.godot/imported/dir_6_0035.png-0ca73a5099e5ee470642737d3d349212.ctex
7646  res://.godot/imported/dir_6_0036.png-74212616df9d8d718bb761f75646bcc1.ctex
7102  res://.godot/imported/dir_6_0037.png-b8f3cd7f00d11e1738def20ba138ad31.ctex
6588  res://.godot/imported/dir_6_0038.png-de4b8fd9a432a6d0cb6d62a70779f107.ctex
5984  res://.godot/imported/dir_6_0039.png-30fe4a5d0248c94f51c386de6818aab0.ctex
3580  res://.godot/imported/dir_6_0040.png-01c5d066ea63da2b2939414aab6b7897.ctex
3580  res://.godot/imported/dir_6_0041.png-36d9495a377e03e36d424fd98695a054.ctex
3580  res://.godot/imported/dir_6_0042.png-0d3be26f076a11fe04aa48150607f766.ctex
3580  res://.godot/imported/dir_6_0043.png-b9f2da0ea4ca216970722097f128bbd1.ctex
3580  res://.godot/imported/dir_6_0044.png-3f84695fc07f7b738486280eb5603000.ctex
3580  res://.godot/imported/dir_6_0045.png-deb75272ecbeaf94c9d8a660d7c0ac85.ctex
25068  res://.godot/imported/dir_7_0001.png-f56163f66408f9b4868c963b7ccdc888.ctex
25028  res://.godot/imported/dir_7_0002.png-c0fe11e0a41fb3e172cad384ea0d6fdb.ctex
24696  res://.godot/imported/dir_7_0003.png-80353ff236d3b9e9529d95b234901c2f.ctex
24368  res://.godot/imported/dir_7_0004.png-f17b8c72db6c5a5555c1e058a4fdb37d.ctex
24400  res://.godot/imported/dir_7_0005.png-9b495c651b85e4394c7278ed9117f507.ctex
24654  res://.godot/imported/dir_7_0006.png-b55337d24f1991722d24974127890164.ctex
24522  res://.godot/imported/dir_7_0007.png-3f74fdb57cdfb5cf92632111c7c47353.ctex
24526  res://.godot/imported/dir_7_0008.png-14fff645fc469a9ca37da44571c8bf40.ctex
24300  res://.godot/imported/dir_7_0009.png-44a989bb4ef8aec21b41ccf787b8ad79.ctex
23904  res://.godot/imported/dir_7_0010.png-f8b6efa1bc0fdde4984d18d79ab2b87a.ctex
23758  res://.godot/imported/dir_7_0011.png-8d079e563451cb648d05f12fcd83410e.ctex
23646  res://.godot/imported/dir_7_0012.png-c481686c32eb52fd6fd4412c6d7b4b4e.ctex
23452  res://.godot/imported/dir_7_0013.png-230ea27940975966523df263c58504ff.ctex
23650  res://.godot/imported/dir_7_0014.png-cd9b475b011d51a12b5035e2f55c89a4.ctex
23896  res://.godot/imported/dir_7_0015.png-6462d0a0c363f5a418682bbd99cfee9f.ctex
24438  res://.godot/imported/dir_7_0016.png-1e525788b0aecb2c77f9c99b2c6e7961.ctex
24726  res://.godot/imported/dir_7_0017.png-fc1fb54f89a66e7672a3dea4977bf5dd.ctex
25078  res://.godot/imported/dir_7_0018.png-ab4b697f5439f7562d6495d6ca1b21c2.ctex
25514  res://.godot/imported/dir_7_0019.png-d6adf250f69ca718c20f2b6f1e1dab8b.ctex
25118  res://.godot/imported/dir_7_0020.png-13e81bed771a378dd92fe3e44a5dcae9.ctex
24532  res://.godot/imported/dir_7_0021.png-95025a26723093c478b81f9159680c72.ctex
23808  res://.godot/imported/dir_7_0022.png-7119dbcacfdc1fbeea0a4908fde2ad4c.ctex
22540  res://.godot/imported/dir_7_0023.png-42911aed0fd1e7b00c59d14e1d3bd2ec.ctex
21722  res://.godot/imported/dir_7_0024.png-cd0313892fa0271db3530d704b558c3a.ctex
21356  res://.godot/imported/dir_7_0025.png-e837b778cf6654dccb6e1c3cac343e06.ctex
20964  res://.godot/imported/dir_7_0026.png-c14e9001cf3dbffbd89121685a29876b.ctex
20554  res://.godot/imported/dir_7_0027.png-410a93b758978f6107af16ca2265aaca.ctex
20148  res://.godot/imported/dir_7_0028.png-f441389b1b2984eba015ff3018824976.ctex
19868  res://.godot/imported/dir_7_0029.png-37b4c07a4c3f14a34495ee55687869f8.ctex
19676  res://.godot/imported/dir_7_0030.png-ef549d8584817425a792f64d53b357de.ctex
19554  res://.godot/imported/dir_7_0031.png-368fd541b5b5219ce5724ebf77b504e3.ctex
19104  res://.godot/imported/dir_7_0032.png-5862cafb570810c768df0659dbd21c86.ctex
18186  res://.godot/imported/dir_7_0033.png-04b92d5998216baaca5ce78bc7e2b0ab.ctex
17524  res://.godot/imported/dir_7_0034.png-f360fbba45604b91d35ca2106e17547f.ctex
16720  res://.godot/imported/dir_7_0035.png-ab41dcabc7044bd63709f874ba63d42f.ctex
16038  res://.godot/imported/dir_7_0036.png-e59c70a78b8e861cb280f41a3eb39067.ctex
15590  res://.godot/imported/dir_7_0037.png-ac4072e6541b8df202a43dea56e7cd67.ctex
14784  res://.godot/imported/dir_7_0038.png-42cd164980ead0a5b2376797057244a2.ctex
13934  res://.godot/imported/dir_7_0039.png-7c2343a6c86942135313d0c4bc4f414e.ctex
13192  res://.godot/imported/dir_7_0040.png-5312afda3741127ce8a70bfb88de9549.ctex
12406  res://.godot/imported/dir_7_0041.png-9b4ca50bea3cbd33520b6451fc976146.ctex
11780  res://.godot/imported/dir_7_0042.png-435fab965479c665ead6209978a0e5fc.ctex
11054  res://.godot/imported/dir_7_0043.png-5bf45588c7753e97799660453a66348f.ctex
10110  res://.godot/imported/dir_7_0044.png-e710ee96e2dd522844ed77edfeac0918.ctex
10110  res://.godot/imported/dir_7_0045.png-9b82aafad83a15cdf5250f678768e4c3.ctex
4261443  res://.godot/imported/eurodance.mp3-fef95430f66d8053d0220ef34137fda9.mp3str
22920832  res://.godot/imported/fountain_sculpture.glb-a0ab240fe62ced988ba9a52de635ff8f.scn
4081515  res://.godot/imported/hiphop.mp3-3d4b4945f60e4d0cddde31e8acbf2438.mp3str
1176  res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex
21520143  res://.godot/imported/kiosk_turret.glb-21d18cfe5e39c287914cfac610d69389.scn
15048956  res://.godot/imported/mall_kiosk.glb-ef7ad498f3da947c3b5d733a4903be11.scn
16449405  res://.godot/imported/mall_planter.glb-f1515752ded96a398eafbdc994b6e669.scn
167359  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb-32a6b43d5d45dfc4ede7dd83598e8211.scn
11184876  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg-4aa502cd14a84b2c529a8898c302226b.s3tc.ctex
2796268  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg-ecf3d6b8aac2645fe97470a1f4e99f00.s3tc.ctex
22369700  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg-3a28b97969be2809be74c1a9476bd1c9.s3tc.ctex
142885  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb-100b1b23c136ecaea2b2c2932c21ac1b.scn
11184876  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg-57c9bb5b0ae9234c05de81e42f298c6f.s3tc.ctex
2796268  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg-2ba7f038ac6d306fa2b8d47c08417ab1.s3tc.ctex
22369700  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg-55d7e5261dcedb3df0eddb11b7b87636.s3tc.ctex
245433  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations.glb-e7f241e6428c2b67e04f90f3be56e5af.scn
11184876  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg-3cea79246c65c32a532c42ecef570744.s3tc.ctex
2796268  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg-cc800615ee86b5e4ee11529ddfdcda9e.s3tc.ctex
22369700  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg-8ced58427b3620342c6ab9d1df00a24c.s3tc.ctex
175666  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb-dd2ef507427ee6ecd6de7aea3842d3f1.scn
11184876  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg-114f149bb1e7d1877ac3e9ac4b9ffcab.s3tc.ctex
2796268  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg-95776f1ad3e7f33ed594f450af85b1ab.s3tc.ctex
22369700  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg-b16ad54c8d136d69239c481caeb12679.s3tc.ctex
180220  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d386ad401674f18d1edfd264d67ce020.scn
180159  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d6fdad554547eb106e82adbbc33e252f.scn
11184876  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-86710d89420272bd05b7dff2cb7dc19c.s3tc.ctex
11184876  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-8f735e678b86df73bf8978d10c629e6f.s3tc.ctex
2796268  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-2c44aaf060978cde46693e50c10062e2.s3tc.ctex
2796268  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-8122c1ec715bcbe34a4661682b54b4c3.s3tc.ctex
22369700  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-e909b100dc6bbda0c7e19c5e6c81bef1.s3tc.ctex
22369700  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-edd18b21906bbfe2adb2655e252bd46b.s3tc.ctex
20295999  res://.godot/imported/neon_cicada.glb-c075b36b4e093e1d35265564e67f028c.scn
3923527  res://.godot/imported/numetal.mp3-058dd4db2f01f0c63415579f555fa23f.mp3str
4284643  res://.godot/imported/skater.mp3-47c0b3f6a66951ef919ba1b8e36e472c.mp3str
21616270  res://.godot/imported/sludge_roach.glb-1ae35041ab2d79767ebaf70f00e6243f.scn
21824  res://.godot/uid_cache.bin
174  res://assets/models/dial_up_queen.glb.import
180  res://assets/models/fountain_sculpture.glb.import
173  res://assets/models/kiosk_turret.glb.import
172  res://assets/models/mall_kiosk.glb.import
174  res://assets/models/mall_planter.glb.import
172  res://assets/models/neon_cicada.glb.import
174  res://assets/models/sludge_roach.glb.import
772096  res://bin/libbiopunk.windows.template_debug.x86_64.dll
679424  res://bin/libbiopunk.windows.template_release.x86_64.dll
354  res://biopunk.gdextension
435  res://icon.svg
193  res://icon.svg.import
9976045  res://intro_video.ogv
152  res://music/anthem.mp3.import
154  res://music/bigbeat.mp3.import
155  res://music/bubblegum.mp3.import
153  res://music/combat.mp3.import
156  res://music/eurodance.mp3.import
153  res://music/hiphop.mp3.import
154  res://music/numetal.mp3.import
153  res://music/skater.mp3.import
11529  res://project.binary
106  res://scenes/dial_up_queen.tscn.remap
112  res://scenes/FloodedMall_Greybox.tscn.remap
112  res://scenes/health_candy_pickup.tscn.remap
98  res://scenes/intro.tscn.remap
102  res://scenes/main_menu.tscn.remap
213  res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb.import
360  res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg.import
359  res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg.import
359  res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg.import
211  res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb.import
351  res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg.import
351  res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg.import
351  res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg.import
206  res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations.glb.import
353  res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg.import
353  res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg.import
353  res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg.import
225  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb.import
371  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg.import
371  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg.import
371  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg.import
224  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
371  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
371  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
370  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
104  res://scenes/neon_cicada.tscn.remap
99  res://scenes/player.tscn.remap
57  res://scripts/boss_encounter_trigger.gd.remap
13196  res://scripts/boss_encounter_trigger.gdc
45  res://scripts/checkpoint.gd.remap
6476  res://scripts/checkpoint.gdc
57  res://scripts/corrupted_kiosk_turret.gd.remap
34160  res://scripts/corrupted_kiosk_turret.gdc
48  res://scripts/dial_up_queen.gd.remap
46548  res://scripts/dial_up_queen.gdc
50  res://scripts/disk_projectile.gd.remap
8308  res://scripts/disk_projectile.gdc
46  res://scripts/enemy_model.gd.remap
9632  res://scripts/enemy_model.gdc
54  res://scripts/health_candy_pickup.gd.remap
16808  res://scripts/health_candy_pickup.gdc
38  res://scripts/hud.gd.remap
75640  res://scripts/hud.gdc
51  res://scripts/isometric_camera.gd.remap
6400  res://scripts/isometric_camera.gdc
55  res://scripts/mall_greybox_builder.gd.remap
57196  res://scripts/mall_greybox_builder.gdc
46  res://scripts/neon_cicada.gd.remap
28916  res://scripts/neon_cicada.gdc
47  res://scripts/save_manager.gd.remap
17340  res://scripts/save_manager.gdc
47  res://scripts/sludge_roach.gd.remap
32784  res://scripts/sludge_roach.gdc
48  res://scripts/turret_mortar.gd.remap
23104  res://scripts/turret_mortar.gdc
52  res://scripts/tutorial_director.gd.remap
17644  res://scripts/tutorial_director.gdc
51758  res://Skate_Grind.res
198  res://sprites/player_idle/dir_0_0001.png.import
199  res://sprites/player_idle/dir_0_0002.png.import
199  res://sprites/player_idle/dir_0_0003.png.import
199  res://sprites/player_idle/dir_0_0004.png.import
199  res://sprites/player_idle/dir_0_0005.png.import
199  res://sprites/player_idle/dir_0_0006.png.import
199  res://sprites/player_idle/dir_0_0007.png.import
198  res://sprites/player_idle/dir_0_0008.png.import
199  res://sprites/player_idle/dir_0_0009.png.import
199  res://sprites/player_idle/dir_0_0010.png.import
199  res://sprites/player_idle/dir_0_0011.png.import
199  res://sprites/player_idle/dir_0_0012.png.import
198  res://sprites/player_idle/dir_0_0013.png.import
199  res://sprites/player_idle/dir_0_0014.png.import
199  res://sprites/player_idle/dir_0_0015.png.import
199  res://sprites/player_idle/dir_0_0016.png.import
198  res://sprites/player_idle/dir_0_0017.png.import
198  res://sprites/player_idle/dir_0_0018.png.import
198  res://sprites/player_idle/dir_0_0019.png.import
199  res://sprites/player_idle/dir_0_0020.png.import
199  res://sprites/player_idle/dir_0_0021.png.import
199  res://sprites/player_idle/dir_0_0022.png.import
199  res://sprites/player_idle/dir_0_0023.png.import
199  res://sprites/player_idle/dir_0_0024.png.import
198  res://sprites/player_idle/dir_0_0025.png.import
199  res://sprites/player_idle/dir_0_0026.png.import
199  res://sprites/player_idle/dir_0_0027.png.import
198  res://sprites/player_idle/dir_0_0028.png.import
198  res://sprites/player_idle/dir_0_0029.png.import
199  res://sprites/player_idle/dir_0_0030.png.import
199  res://sprites/player_idle/dir_0_0031.png.import
198  res://sprites/player_idle/dir_0_0032.png.import
199  res://sprites/player_idle/dir_0_0033.png.import
198  res://sprites/player_idle/dir_0_0034.png.import
198  res://sprites/player_idle/dir_0_0035.png.import
199  res://sprites/player_idle/dir_0_0036.png.import
198  res://sprites/player_idle/dir_0_0037.png.import
199  res://sprites/player_idle/dir_0_0038.png.import
199  res://sprites/player_idle/dir_0_0039.png.import
198  res://sprites/player_idle/dir_0_0040.png.import
199  res://sprites/player_idle/dir_0_0041.png.import
199  res://sprites/player_idle/dir_0_0042.png.import
198  res://sprites/player_idle/dir_0_0043.png.import
199  res://sprites/player_idle/dir_0_0044.png.import
198  res://sprites/player_idle/dir_0_0045.png.import
198  res://sprites/player_idle/dir_1_0001.png.import
199  res://sprites/player_idle/dir_1_0002.png.import
199  res://sprites/player_idle/dir_1_0003.png.import
198  res://sprites/player_idle/dir_1_0004.png.import
198  res://sprites/player_idle/dir_1_0005.png.import
199  res://sprites/player_idle/dir_1_0006.png.import
199  res://sprites/player_idle/dir_1_0007.png.import
199  res://sprites/player_idle/dir_1_0008.png.import
199  res://sprites/player_idle/dir_1_0009.png.import
199  res://sprites/player_idle/dir_1_0010.png.import
199  res://sprites/player_idle/dir_1_0011.png.import
199  res://sprites/player_idle/dir_1_0012.png.import
199  res://sprites/player_idle/dir_1_0013.png.import
199  res://sprites/player_idle/dir_1_0014.png.import
199  res://sprites/player_idle/dir_1_0015.png.import
198  res://sprites/player_idle/dir_1_0016.png.import
199  res://sprites/player_idle/dir_1_0017.png.import
198  res://sprites/player_idle/dir_1_0018.png.import
199  res://sprites/player_idle/dir_1_0019.png.import
198  res://sprites/player_idle/dir_1_0020.png.import
199  res://sprites/player_idle/dir_1_0021.png.import
199  res://sprites/player_idle/dir_1_0022.png.import
199  res://sprites/player_idle/dir_1_0023.png.import
199  res://sprites/player_idle/dir_1_0024.png.import
199  res://sprites/player_idle/dir_1_0025.png.import
199  res://sprites/player_idle/dir_1_0026.png.import
199  res://sprites/player_idle/dir_1_0027.png.import
199  res://sprites/player_idle/dir_1_0028.png.import
198  res://sprites/player_idle/dir_1_0029.png.import
199  res://sprites/player_idle/dir_1_0030.png.import
199  res://sprites/player_idle/dir_1_0031.png.import
199  res://sprites/player_idle/dir_1_0032.png.import
199  res://sprites/player_idle/dir_1_0033.png.import
198  res://sprites/player_idle/dir_1_0034.png.import
199  res://sprites/player_idle/dir_1_0035.png.import
198  res://sprites/player_idle/dir_1_0036.png.import
198  res://sprites/player_idle/dir_1_0037.png.import
198  res://sprites/player_idle/dir_1_0038.png.import
199  res://sprites/player_idle/dir_1_0039.png.import
199  res://sprites/player_idle/dir_1_0040.png.import
198  res://sprites/player_idle/dir_1_0041.png.import
198  res://sprites/player_idle/dir_1_0042.png.import
199  res://sprites/player_idle/dir_1_0043.png.import
198  res://sprites/player_idle/dir_1_0044.png.import
199  res://sprites/player_idle/dir_1_0045.png.import
199  res://sprites/player_idle/dir_2_0001.png.import
199  res://sprites/player_idle/dir_2_0002.png.import
199  res://sprites/player_idle/dir_2_0003.png.import
199  res://sprites/player_idle/dir_2_0004.png.import
198  res://sprites/player_idle/dir_2_0005.png.import
198  res://sprites/player_idle/dir_2_0006.png.import
199  res://sprites/player_idle/dir_2_0007.png.import
199  res://sprites/player_idle/dir_2_0008.png.import
199  res://sprites/player_idle/dir_2_0009.png.import
199  res://sprites/player_idle/dir_2_0010.png.import
199  res://sprites/player_idle/dir_2_0011.png.import
199  res://sprites/player_idle/dir_2_0012.png.import
199  res://sprites/player_idle/dir_2_0013.png.import
199  res://sprites/player_idle/dir_2_0014.png.import
199  res://sprites/player_idle/dir_2_0015.png.import
199  res://sprites/player_idle/dir_2_0016.png.import
199  res://sprites/player_idle/dir_2_0017.png.import
198  res://sprites/player_idle/dir_2_0018.png.import
199  res://sprites/player_idle/dir_2_0019.png.import
198  res://sprites/player_idle/dir_2_0020.png.import
199  res://sprites/player_idle/dir_2_0021.png.import
198  res://sprites/player_idle/dir_2_0022.png.import
198  res://sprites/player_idle/dir_2_0023.png.import
199  res://sprites/player_idle/dir_2_0024.png.import
199  res://sprites/player_idle/dir_2_0025.png.import
199  res://sprites/player_idle/dir_2_0026.png.import
198  res://sprites/player_idle/dir_2_0027.png.import
198  res://sprites/player_idle/dir_2_0028.png.import
199  res://sprites/player_idle/dir_2_0029.png.import
199  res://sprites/player_idle/dir_2_0030.png.import
199  res://sprites/player_idle/dir_2_0031.png.import
199  res://sprites/player_idle/dir_2_0032.png.import
199  res://sprites/player_idle/dir_2_0033.png.import
199  res://sprites/player_idle/dir_2_0034.png.import
199  res://sprites/player_idle/dir_2_0035.png.import
198  res://sprites/player_idle/dir_2_0036.png.import
198  res://sprites/player_idle/dir_2_0037.png.import
198  res://sprites/player_idle/dir_2_0038.png.import
199  res://sprites/player_idle/dir_2_0039.png.import
199  res://sprites/player_idle/dir_2_0040.png.import
199  res://sprites/player_idle/dir_2_0041.png.import
198  res://sprites/player_idle/dir_2_0042.png.import
199  res://sprites/player_idle/dir_2_0043.png.import
199  res://sprites/player_idle/dir_2_0044.png.import
199  res://sprites/player_idle/dir_2_0045.png.import
199  res://sprites/player_idle/dir_3_0001.png.import
198  res://sprites/player_idle/dir_3_0002.png.import
198  res://sprites/player_idle/dir_3_0003.png.import
199  res://sprites/player_idle/dir_3_0004.png.import
199  res://sprites/player_idle/dir_3_0005.png.import
199  res://sprites/player_idle/dir_3_0006.png.import
199  res://sprites/player_idle/dir_3_0007.png.import
198  res://sprites/player_idle/dir_3_0008.png.import
199  res://sprites/player_idle/dir_3_0009.png.import
199  res://sprites/player_idle/dir_3_0010.png.import
198  res://sprites/player_idle/dir_3_0011.png.import
199  res://sprites/player_idle/dir_3_0012.png.import
199  res://sprites/player_idle/dir_3_0013.png.import
199  res://sprites/player_idle/dir_3_0014.png.import
199  res://sprites/player_idle/dir_3_0015.png.import
199  res://sprites/player_idle/dir_3_0016.png.import
199  res://sprites/player_idle/dir_3_0017.png.import
198  res://sprites/player_idle/dir_3_0018.png.import
199  res://sprites/player_idle/dir_3_0019.png.import
198  res://sprites/player_idle/dir_3_0020.png.import
199  res://sprites/player_idle/dir_3_0021.png.import
199  res://sprites/player_idle/dir_3_0022.png.import
198  res://sprites/player_idle/dir_3_0023.png.import
199  res://sprites/player_idle/dir_3_0024.png.import
199  res://sprites/player_idle/dir_3_0025.png.import
199  res://sprites/player_idle/dir_3_0026.png.import
199  res://sprites/player_idle/dir_3_0027.png.import
199  res://sprites/player_idle/dir_3_0028.png.import
199  res://sprites/player_idle/dir_3_0029.png.import
198  res://sprites/player_idle/dir_3_0030.png.import
199  res://sprites/player_idle/dir_3_0031.png.import
198  res://sprites/player_idle/dir_3_0032.png.import
199  res://sprites/player_idle/dir_3_0033.png.import
198  res://sprites/player_idle/dir_3_0034.png.import
199  res://sprites/player_idle/dir_3_0035.png.import
198  res://sprites/player_idle/dir_3_0036.png.import
199  res://sprites/player_idle/dir_3_0037.png.import
199  res://sprites/player_idle/dir_3_0038.png.import
198  res://sprites/player_idle/dir_3_0039.png.import
198  res://sprites/player_idle/dir_3_0040.png.import
199  res://sprites/player_idle/dir_3_0041.png.import
199  res://sprites/player_idle/dir_3_0042.png.import
198  res://sprites/player_idle/dir_3_0043.png.import
199  res://sprites/player_idle/dir_3_0044.png.import
199  res://sprites/player_idle/dir_3_0045.png.import
199  res://sprites/player_idle/dir_4_0001.png.import
198  res://sprites/player_idle/dir_4_0002.png.import
199  res://sprites/player_idle/dir_4_0003.png.import
199  res://sprites/player_idle/dir_4_0004.png.import
199  res://sprites/player_idle/dir_4_0005.png.import
199  res://sprites/player_idle/dir_4_0006.png.import
199  res://sprites/player_idle/dir_4_0007.png.import
198  res://sprites/player_idle/dir_4_0008.png.import
199  res://sprites/player_idle/dir_4_0009.png.import
199  res://sprites/player_idle/dir_4_0010.png.import
199  res://sprites/player_idle/dir_4_0011.png.import
198  res://sprites/player_idle/dir_4_0012.png.import
199  res://sprites/player_idle/dir_4_0013.png.import
199  res://sprites/player_idle/dir_4_0014.png.import
199  res://sprites/player_idle/dir_4_0015.png.import
199  res://sprites/player_idle/dir_4_0016.png.import
199  res://sprites/player_idle/dir_4_0017.png.import
198  res://sprites/player_idle/dir_4_0018.png.import
198  res://sprites/player_idle/dir_4_0019.png.import
199  res://sprites/player_idle/dir_4_0020.png.import
199  res://sprites/player_idle/dir_4_0021.png.import
199  res://sprites/player_idle/dir_4_0022.png.import
199  res://sprites/player_idle/dir_4_0023.png.import
199  res://sprites/player_idle/dir_4_0024.png.import
199  res://sprites/player_idle/dir_4_0025.png.import
199  res://sprites/player_idle/dir_4_0026.png.import
199  res://sprites/player_idle/dir_4_0027.png.import
198  res://sprites/player_idle/dir_4_0028.png.import
199  res://sprites/player_idle/dir_4_0029.png.import
198  res://sprites/player_idle/dir_4_0030.png.import
199  res://sprites/player_idle/dir_4_0031.png.import
199  res://sprites/player_idle/dir_4_0032.png.import
199  res://sprites/player_idle/dir_4_0033.png.import
199  res://sprites/player_idle/dir_4_0034.png.import
199  res://sprites/player_idle/dir_4_0035.png.import
199  res://sprites/player_idle/dir_4_0036.png.import
199  res://sprites/player_idle/dir_4_0037.png.import
199  res://sprites/player_idle/dir_4_0038.png.import
199  res://sprites/player_idle/dir_4_0039.png.import
199  res://sprites/player_idle/dir_4_0040.png.import
199  res://sprites/player_idle/dir_4_0041.png.import
199  res://sprites/player_idle/dir_4_0042.png.import
199  res://sprites/player_idle/dir_4_0043.png.import
199  res://sprites/player_idle/dir_4_0044.png.import
199  res://sprites/player_idle/dir_4_0045.png.import
199  res://sprites/player_idle/dir_5_0001.png.import
197  res://sprites/player_idle/dir_5_0002.png.import
199  res://sprites/player_idle/dir_5_0003.png.import
199  res://sprites/player_idle/dir_5_0004.png.import
199  res://sprites/player_idle/dir_5_0005.png.import
198  res://sprites/player_idle/dir_5_0006.png.import
199  res://sprites/player_idle/dir_5_0007.png.import
198  res://sprites/player_idle/dir_5_0008.png.import
199  res://sprites/player_idle/dir_5_0009.png.import
199  res://sprites/player_idle/dir_5_0010.png.import
199  res://sprites/player_idle/dir_5_0011.png.import
199  res://sprites/player_idle/dir_5_0012.png.import
199  res://sprites/player_idle/dir_5_0013.png.import
199  res://sprites/player_idle/dir_5_0014.png.import
199  res://sprites/player_idle/dir_5_0015.png.import
198  res://sprites/player_idle/dir_5_0016.png.import
199  res://sprites/player_idle/dir_5_0017.png.import
199  res://sprites/player_idle/dir_5_0018.png.import
199  res://sprites/player_idle/dir_5_0019.png.import
198  res://sprites/player_idle/dir_5_0020.png.import
199  res://sprites/player_idle/dir_5_0021.png.import
199  res://sprites/player_idle/dir_5_0022.png.import
199  res://sprites/player_idle/dir_5_0023.png.import
199  res://sprites/player_idle/dir_5_0024.png.import
199  res://sprites/player_idle/dir_5_0025.png.import
199  res://sprites/player_idle/dir_5_0026.png.import
198  res://sprites/player_idle/dir_5_0027.png.import
199  res://sprites/player_idle/dir_5_0028.png.import
198  res://sprites/player_idle/dir_5_0029.png.import
198  res://sprites/player_idle/dir_5_0030.png.import
199  res://sprites/player_idle/dir_5_0031.png.import
199  res://sprites/player_idle/dir_5_0032.png.import
198  res://sprites/player_idle/dir_5_0033.png.import
199  res://sprites/player_idle/dir_5_0034.png.import
198  res://sprites/player_idle/dir_5_0035.png.import
198  res://sprites/player_idle/dir_5_0036.png.import
199  res://sprites/player_idle/dir_5_0037.png.import
199  res://sprites/player_idle/dir_5_0038.png.import
199  res://sprites/player_idle/dir_5_0039.png.import
199  res://sprites/player_idle/dir_5_0040.png.import
199  res://sprites/player_idle/dir_5_0041.png.import
199  res://sprites/player_idle/dir_5_0042.png.import
199  res://sprites/player_idle/dir_5_0043.png.import
199  res://sprites/player_idle/dir_5_0044.png.import
198  res://sprites/player_idle/dir_5_0045.png.import
199  res://sprites/player_idle/dir_6_0001.png.import
199  res://sprites/player_idle/dir_6_0002.png.import
199  res://sprites/player_idle/dir_6_0003.png.import
199  res://sprites/player_idle/dir_6_0004.png.import
198  res://sprites/player_idle/dir_6_0005.png.import
198  res://sprites/player_idle/dir_6_0006.png.import
199  res://sprites/player_idle/dir_6_0007.png.import
199  res://sprites/player_idle/dir_6_0008.png.import
199  res://sprites/player_idle/dir_6_0009.png.import
198  res://sprites/player_idle/dir_6_0010.png.import
198  res://sprites/player_idle/dir_6_0011.png.import
198  res://sprites/player_idle/dir_6_0012.png.import
199  res://sprites/player_idle/dir_6_0013.png.import
199  res://sprites/player_idle/dir_6_0014.png.import
199  res://sprites/player_idle/dir_6_0015.png.import
199  res://sprites/player_idle/dir_6_0016.png.import
199  res://sprites/player_idle/dir_6_0017.png.import
199  res://sprites/player_idle/dir_6_0018.png.import
199  res://sprites/player_idle/dir_6_0019.png.import
199  res://sprites/player_idle/dir_6_0020.png.import
198  res://sprites/player_idle/dir_6_0021.png.import
198  res://sprites/player_idle/dir_6_0022.png.import
199  res://sprites/player_idle/dir_6_0023.png.import
199  res://sprites/player_idle/dir_6_0024.png.import
199  res://sprites/player_idle/dir_6_0025.png.import
198  res://sprites/player_idle/dir_6_0026.png.import
199  res://sprites/player_idle/dir_6_0027.png.import
198  res://sprites/player_idle/dir_6_0028.png.import
199  res://sprites/player_idle/dir_6_0029.png.import
199  res://sprites/player_idle/dir_6_0030.png.import
199  res://sprites/player_idle/dir_6_0031.png.import
199  res://sprites/player_idle/dir_6_0032.png.import
198  res://sprites/player_idle/dir_6_0033.png.import
199  res://sprites/player_idle/dir_6_0034.png.import
199  res://sprites/player_idle/dir_6_0035.png.import
199  res://sprites/player_idle/dir_6_0036.png.import
199  res://sprites/player_idle/dir_6_0037.png.import
198  res://sprites/player_idle/dir_6_0038.png.import
197  res://sprites/player_idle/dir_6_0039.png.import
199  res://sprites/player_idle/dir_6_0040.png.import
198  res://sprites/player_idle/dir_6_0041.png.import
198  res://sprites/player_idle/dir_6_0042.png.import
199  res://sprites/player_idle/dir_6_0043.png.import
198  res://sprites/player_idle/dir_6_0044.png.import
198  res://sprites/player_idle/dir_6_0045.png.import
198  res://sprites/player_idle/dir_7_0001.png.import
199  res://sprites/player_idle/dir_7_0002.png.import
199  res://sprites/player_idle/dir_7_0003.png.import
199  res://sprites/player_idle/dir_7_0004.png.import
199  res://sprites/player_idle/dir_7_0005.png.import
197  res://sprites/player_idle/dir_7_0006.png.import
199  res://sprites/player_idle/dir_7_0007.png.import
199  res://sprites/player_idle/dir_7_0008.png.import
199  res://sprites/player_idle/dir_7_0009.png.import
198  res://sprites/player_idle/dir_7_0010.png.import
198  res://sprites/player_idle/dir_7_0011.png.import
199  res://sprites/player_idle/dir_7_0012.png.import
199  res://sprites/player_idle/dir_7_0013.png.import
198  res://sprites/player_idle/dir_7_0014.png.import
199  res://sprites/player_idle/dir_7_0015.png.import
199  res://sprites/player_idle/dir_7_0016.png.import
199  res://sprites/player_idle/dir_7_0017.png.import
199  res://sprites/player_idle/dir_7_0018.png.import
199  res://sprites/player_idle/dir_7_0019.png.import
198  res://sprites/player_idle/dir_7_0020.png.import
199  res://sprites/player_idle/dir_7_0021.png.import
199  res://sprites/player_idle/dir_7_0022.png.import
198  res://sprites/player_idle/dir_7_0023.png.import
199  res://sprites/player_idle/dir_7_0024.png.import
199  res://sprites/player_idle/dir_7_0025.png.import
197  res://sprites/player_idle/dir_7_0026.png.import
199  res://sprites/player_idle/dir_7_0027.png.import
198  res://sprites/player_idle/dir_7_0028.png.import
198  res://sprites/player_idle/dir_7_0029.png.import
199  res://sprites/player_idle/dir_7_0030.png.import
198  res://sprites/player_idle/dir_7_0031.png.import
199  res://sprites/player_idle/dir_7_0032.png.import
199  res://sprites/player_idle/dir_7_0033.png.import
199  res://sprites/player_idle/dir_7_0034.png.import
199  res://sprites/player_idle/dir_7_0035.png.import
198  res://sprites/player_idle/dir_7_0036.png.import
199  res://sprites/player_idle/dir_7_0037.png.import
199  res://sprites/player_idle/dir_7_0038.png.import
199  res://sprites/player_idle/dir_7_0039.png.import
198  res://sprites/player_idle/dir_7_0040.png.import
199  res://sprites/player_idle/dir_7_0041.png.import
199  res://sprites/player_idle/dir_7_0042.png.import
199  res://sprites/player_idle/dir_7_0043.png.import
198  res://sprites/player_idle/dir_7_0044.png.import
199  res://sprites/player_idle/dir_7_0045.png.import
225  res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
371  res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
371  res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
371  res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
PACKED: res://intro_video.ogv (direct, 9976045 bytes)
PACKED: res://icon.svg (direct, 435 bytes)
PACKED: res://Skate_Grind.res (direct, 51758 bytes)
PACKED: res://biopunk.gdextension (direct, 354 bytes)
PACKED: res://music/anthem.mp3 -> res://.godot/imported/anthem.mp3-2f7a92cf245df82890b7830193e2bea6.mp3str (4285267 bytes; via res://music/anthem.mp3.import)
PACKED: res://music/bigbeat.mp3 -> res://.godot/imported/bigbeat.mp3-719a317dfac214297f4d640840ee7874.mp3str (4096559 bytes; via res://music/bigbeat.mp3.import)
PACKED: res://music/bubblegum.mp3 -> res://.godot/imported/bubblegum.mp3-6600d7a64ddbbec66a2b18480a79e0ad.mp3str (4284015 bytes; via res://music/bubblegum.mp3.import)
PACKED: res://music/combat.mp3 -> res://.godot/imported/combat.mp3-1829eebac0ee46487ae84a3be83a352e.mp3str (3829483 bytes; via res://music/combat.mp3.import)
PACKED: res://music/eurodance.mp3 -> res://.godot/imported/eurodance.mp3-fef95430f66d8053d0220ef34137fda9.mp3str (4261443 bytes; via res://music/eurodance.mp3.import)
PACKED: res://music/hiphop.mp3 -> res://.godot/imported/hiphop.mp3-3d4b4945f60e4d0cddde31e8acbf2438.mp3str (4081515 bytes; via res://music/hiphop.mp3.import)
PACKED: res://music/numetal.mp3 -> res://.godot/imported/numetal.mp3-058dd4db2f01f0c63415579f555fa23f.mp3str (3923527 bytes; via res://music/numetal.mp3.import)
PACKED: res://music/skater.mp3 -> res://.godot/imported/skater.mp3-47c0b3f6a66951ef919ba1b8e36e472c.mp3str (4284643 bytes; via res://music/skater.mp3.import)
PACKED: res://assets/models/dial_up_queen.glb -> res://.godot/imported/dial_up_queen.glb-c1a5cb2f8ad5373c4dcab5634b6375c1.scn (23329773 bytes; via res://assets/models/dial_up_queen.glb.import)
PACKED: res://assets/models/fountain_sculpture.glb -> res://.godot/imported/fountain_sculpture.glb-a0ab240fe62ced988ba9a52de635ff8f.scn (22920832 bytes; via res://assets/models/fountain_sculpture.glb.import)
PACKED: res://assets/models/kiosk_turret.glb -> res://.godot/imported/kiosk_turret.glb-21d18cfe5e39c287914cfac610d69389.scn (21520143 bytes; via res://assets/models/kiosk_turret.glb.import)
PACKED: res://assets/models/mall_kiosk.glb -> res://.godot/imported/mall_kiosk.glb-ef7ad498f3da947c3b5d733a4903be11.scn (15048956 bytes; via res://assets/models/mall_kiosk.glb.import)
PACKED: res://assets/models/mall_planter.glb -> res://.godot/imported/mall_planter.glb-f1515752ded96a398eafbdc994b6e669.scn (16449405 bytes; via res://assets/models/mall_planter.glb.import)
PACKED: res://assets/models/neon_cicada.glb -> res://.godot/imported/neon_cicada.glb-c075b36b4e093e1d35265564e67f028c.scn (20295999 bytes; via res://assets/models/neon_cicada.glb.import)
PACKED: res://assets/models/sludge_roach.glb -> res://.godot/imported/sludge_roach.glb-1ae35041ab2d79767ebaf70f00e6243f.scn (21616270 bytes; via res://assets/models/sludge_roach.glb.import)
PACKED: res://bin/libbiopunk.windows.template_release.x86_64.dll (direct, 679424 bytes)
FILTERS: PASS (QA=False; no forbidden source/ops/test/build files)
PCK: C:\y2k-biopunk-rpg\.worktrees\vs11export\build\qa\Y2K-BioPunk-QA.pck (Godot 4.3.0, 860 entries)
PACKED: res://intro_video.ogv (direct, 9976045 bytes)
PACKED: res://icon.svg (direct, 435 bytes)
PACKED: res://Skate_Grind.res (direct, 51758 bytes)
PACKED: res://biopunk.gdextension (direct, 354 bytes)
PACKED: res://music/anthem.mp3 -> res://.godot/imported/anthem.mp3-2f7a92cf245df82890b7830193e2bea6.mp3str (4285267 bytes; via res://music/anthem.mp3.import)
PACKED: res://music/bigbeat.mp3 -> res://.godot/imported/bigbeat.mp3-719a317dfac214297f4d640840ee7874.mp3str (4096559 bytes; via res://music/bigbeat.mp3.import)
PACKED: res://music/bubblegum.mp3 -> res://.godot/imported/bubblegum.mp3-6600d7a64ddbbec66a2b18480a79e0ad.mp3str (4284015 bytes; via res://music/bubblegum.mp3.import)
PACKED: res://music/combat.mp3 -> res://.godot/imported/combat.mp3-1829eebac0ee46487ae84a3be83a352e.mp3str (3829483 bytes; via res://music/combat.mp3.import)
PACKED: res://music/eurodance.mp3 -> res://.godot/imported/eurodance.mp3-fef95430f66d8053d0220ef34137fda9.mp3str (4261443 bytes; via res://music/eurodance.mp3.import)
PACKED: res://music/hiphop.mp3 -> res://.godot/imported/hiphop.mp3-3d4b4945f60e4d0cddde31e8acbf2438.mp3str (4081515 bytes; via res://music/hiphop.mp3.import)
PACKED: res://music/numetal.mp3 -> res://.godot/imported/numetal.mp3-058dd4db2f01f0c63415579f555fa23f.mp3str (3923527 bytes; via res://music/numetal.mp3.import)
PACKED: res://music/skater.mp3 -> res://.godot/imported/skater.mp3-47c0b3f6a66951ef919ba1b8e36e472c.mp3str (4284643 bytes; via res://music/skater.mp3.import)
PACKED: res://assets/models/dial_up_queen.glb -> res://.godot/imported/dial_up_queen.glb-c1a5cb2f8ad5373c4dcab5634b6375c1.scn (23329773 bytes; via res://assets/models/dial_up_queen.glb.import)
PACKED: res://assets/models/fountain_sculpture.glb -> res://.godot/imported/fountain_sculpture.glb-a0ab240fe62ced988ba9a52de635ff8f.scn (22920832 bytes; via res://assets/models/fountain_sculpture.glb.import)
PACKED: res://assets/models/kiosk_turret.glb -> res://.godot/imported/kiosk_turret.glb-21d18cfe5e39c287914cfac610d69389.scn (21520143 bytes; via res://assets/models/kiosk_turret.glb.import)
PACKED: res://assets/models/mall_kiosk.glb -> res://.godot/imported/mall_kiosk.glb-ef7ad498f3da947c3b5d733a4903be11.scn (15048956 bytes; via res://assets/models/mall_kiosk.glb.import)
PACKED: res://assets/models/mall_planter.glb -> res://.godot/imported/mall_planter.glb-f1515752ded96a398eafbdc994b6e669.scn (16449405 bytes; via res://assets/models/mall_planter.glb.import)
PACKED: res://assets/models/neon_cicada.glb -> res://.godot/imported/neon_cicada.glb-c075b36b4e093e1d35265564e67f028c.scn (20295999 bytes; via res://assets/models/neon_cicada.glb.import)
PACKED: res://assets/models/sludge_roach.glb -> res://.godot/imported/sludge_roach.glb-1ae35041ab2d79767ebaf70f00e6243f.scn (21616270 bytes; via res://assets/models/sludge_roach.glb.import)
PACKED: res://bin/libbiopunk.windows.template_release.x86_64.dll (direct, 679424 bytes)
PACKED: res://bin/libbiopunk.windows.template_debug.x86_64.dll (direct, 772096 bytes)
PACKED: res://ops/tools/shot_harness.gd (direct, 19847 bytes)
PACKED: res://tests/test_3d_player.gd (direct, 13021 bytes)
PACKED: res://tests/test_5_systems.gd (direct, 9554 bytes)
PACKED: res://tests/test_candy_pickup.gd (direct, 9988 bytes)
PACKED: res://tests/test_critical_path.gd (direct, 4845 bytes)
PACKED: res://tests/test_cursor_aiming.gd (direct, 8829 bytes)
PACKED: res://tests/test_encounters.gd (direct, 6695 bytes)
PACKED: res://tests/test_feel_combat.gd (direct, 6129 bytes)
PACKED: res://tests/test_feel_movement.gd (direct, 5901 bytes)
PACKED: res://tests/test_feel_traversal.gd (direct, 3499 bytes)
PACKED: res://tests/test_flamethrower_particles.gd (direct, 3086 bytes)
PACKED: res://tests/test_gameplay_fixes.gd (direct, 8256 bytes)
PACKED: res://tests/test_grinding.gd (direct, 6764 bytes)
PACKED: res://tests/test_menu_flow.gd (direct, 2334 bytes)
PACKED: res://tests/test_onboarding.gd (direct, 9410 bytes)
PACKED: res://tests/test_presentation.gd (direct, 3755 bytes)
PACKED: res://tests/test_slice_e2e.gd (direct, 8750 bytes)
PACKED: res://tests/test_systems.gd (direct, 2328 bytes)
PACKED: res://tests/test_tapes.gd (direct, 2777 bytes)
PACKED: res://tests/verify_camera_and_hud.gd (direct, 1908 bytes)
PACKED: res://tests/_test_util.gd (direct, 4395 bytes)
FILTERS: PASS (QA=True; no forbidden source/ops/test/build files)
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\build\qa\Y2K-BioPunk-QA.console.exe --headless -s res://tests/test_slice_e2e.gd
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

=== test_slice_e2e ===
PASS: a: load real mall
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
PASS: a: level 1, full HP, player group
PASS: a: nearby cicadas=2, roaches=0
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 2! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 75
PASS: b: exact earned XP=90 (3 cicadas, 4 roaches), level=2
[Y2K-STATS] Stat point allocated to 'strength'! Remaining unspent points: 1
PASS: b: strength point increases bat damage
FAIL: c: checkpoint collision saves current level
[Y2K-PLAYER] *** CRITICAL BIO-FAILURE *** Player HP reached 0. Transitioned to STATE_DEAD. Reloading scene in 2.5s...
PASS: d: real lethal damage enters dead state
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 11 (Bat DMG: 42.5) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[SaveManager] Restored player save state! Level 2 | Unspent Pts: 1 | Tape: 'Bubblegum'
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
PASS: d: death reloads scene within 4s
PASS: d: respawn restores saved level, full HP, checkpoint position
PASS: d: respawn preserves XP, spent strength and unspent points
PASS: e: real atrium sensor enters grind within 0.5s
PASS: e: jump dismount emits grind_ended and one landing slam
[BossTrigger] Awakening Dial-Up Queen...
[DialUpQueen] *** BOSS SPAWNED *** The Dial-Up Queen looms with 1500 HP!
PASS: f: real trigger spawns exactly one Queen
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 2 !!!!!!!
PASS: f: phase 2 signal/state in order
PASS: f: phase 2 invulnerability expires
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 3 !!!!!!!
PASS: f: phase 3 signal/state in order
PASS: f: phase 3 invulnerability expires
PASS: f: real summon state creates minions
[DialUpQueen] *** BOSS DEFEATED! The dial-up carrier frequency has died. ***
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 3! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 112
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 4! Gained 1 Stat Point. Unspent: 3 | Next Level XP: 168
[SaveManager] Slice completion recorded.
PASS: f: boss_defeated fires once
PASS: f: summoned minions freed on victory
PASS: f: HUD victory card node exists
[Y2K-MENU] MenuController ready! Bio-Punk Title Screen online.
PASS: f: victory returns to main_menu within 7s
PASS: g: Continue button visible
PASS: g: saved slice_complete is true
PASS: runtime 21.70s < 60s
RESULT: FAIL (1 fails)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)

EXIT: 1 (test_slice_e2e)
PACKAGED TEST: FAIL (test_slice_e2e); continuing the other independent smoke checks.
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\build\qa\Y2K-BioPunk-QA.console.exe --headless -s res://tests/test_menu_flow.gd
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

PASS: main menu loads
[Y2K-MENU] MenuController ready! Bio-Punk Title Screen online.
PASS: NewGameButton exists
PASS: Continue hidden without a save
[Y2K-MENU] 'NEW GAME' selected! Transitioning to main gameplay...
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
PASS: New Game loads the mall (got res://scenes/FloodedMall_Greybox.tscn)
PASS: fresh player at level 1 in the mall
[SaveManager] *** GAME SAVED *** Checkpoint 'TestCP' | Level 1 | XP 0/50 | Tape 'Bubblegum'
PASS: back to menu
[Y2K-MENU] MenuController ready! Bio-Punk Title Screen online.
PASS: Continue visible and labelled with a save
RESULT: PASS (0 fails)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
WARNING: ObjectDB instances leaked at exit (run with --verbose for details).
     at: cleanup (core/object/object.cpp:2284)
ERROR: 1 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:604)

EXIT: 0 (test_menu_flow)
PACKAGED TEST: PASS (test_menu_flow)
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\build\release\Y2K-BioPunk.console.exe --windowed --resolution 1280x720 --position 2000,2000 --quit-after 600
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org
Vulkan 1.4.312 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce GTX 1060 with Max-Q Design

[Y2K-INTRO] IntroController ready! Press any key or mouse button to skip.

EXIT: 0 (release_launch)
RELEASE LAUNCH: PASS (600 frames, off-screen; no matching error lines)
SMOKE: FAIL - Packaged tests failed: test_slice_e2e; see exact output above and C:\y2k-biopunk-rpg\.worktrees\vs11export\ops\runs\export\smoke_20261008_134229.

```

Script exit code: `1`.

## Full repository test runner (exit 1)

Command from the assigned worktree:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1
```

Complete stdout/stderr captured with `*> ops/runs/export/run_tests.full.log` (line endings normalized for Markdown):

```text
=================================================================
 Y2K BIO-PUNK ARPG - TEST SUITE RUNNER
 Engine : C:\y2k-biopunk-rpg\.worktrees\vs11export\Godot_v4.3-stable_win64.exe
 Worktree: C:\y2k-biopunk-rpg\.worktrees\vs11export
 Timeout: 120s per test
=================================================================
Discovered 19 test suite files.
[PASS] test_3d_player.gd                (Code:  0, Time:  4.77s) - All checks passed
[PASS] test_5_systems.gd                (Code:  0, Time:  5.13s) - Passed (contains SKIP section)
[PASS] test_candy_pickup.gd             (Code:  0, Time:  0.76s) - All checks passed
[PASS] test_critical_path.gd            (Code:  0, Time:  4.61s) - All checks passed
[PASS] test_cursor_aiming.gd            (Code:  0, Time:  0.94s) - All checks passed
[PASS] test_encounters.gd               (Code:  0, Time: 27.32s) - All checks passed
[PASS] test_feel_combat.gd              (Code:  0, Time:  3.21s) - All checks passed
[PASS] test_feel_movement.gd            (Code:  0, Time:  8.03s) - All checks passed
[PASS] test_feel_traversal.gd           (Code:  0, Time:   2.1s) - All checks passed
[PASS] test_flamethrower_particles.gd   (Code:  0, Time:  0.43s) - All checks passed
[PASS] test_gameplay_fixes.gd           (Code:  0, Time:  1.41s) - All checks passed
[PASS] test_grinding.gd                 (Code:  0, Time:   4.3s) - All checks passed
[PASS] test_menu_flow.gd                (Code:  0, Time:  3.92s) - All checks passed
[PASS] test_onboarding.gd               (Code:  0, Time:  8.29s) - All checks passed
[PASS] test_presentation.gd             (Code:  0, Time:  2.06s) - All checks passed
[FAIL] test_slice_e2e.gd                (Code:  1, Time: 22.11s) - Assertion checks failed (Exit 1)
[PASS] test_systems.gd                  (Code:  0, Time:  0.32s) - All checks passed
[PASS] test_tapes.gd                    (Code:  0, Time:  0.41s) - All checks passed
[PASS] verify_camera_and_hud.gd         (Code:  0, Time:  0.57s) - All checks passed

=================================================================
 TEST RUN SUMMARY
=================================================================

Test                           Status ExitCode Time   Details                         
----                           ------ -------- ----   -------                         
test_3d_player.gd              PASS          0 4.77s  All checks passed               
test_5_systems.gd              PASS          0 5.13s  Passed (contains SKIP section)  
test_candy_pickup.gd           PASS          0 0.76s  All checks passed               
test_critical_path.gd          PASS          0 4.61s  All checks passed               
test_cursor_aiming.gd          PASS          0 0.94s  All checks passed               
test_encounters.gd             PASS          0 27.32s All checks passed               
test_feel_combat.gd            PASS          0 3.21s  All checks passed               
test_feel_movement.gd          PASS          0 8.03s  All checks passed               
test_feel_traversal.gd         PASS          0 2.1s   All checks passed               
test_flamethrower_particles.gd PASS          0 0.43s  All checks passed               
test_gameplay_fixes.gd         PASS          0 1.41s  All checks passed               
test_grinding.gd               PASS          0 4.3s   All checks passed               
test_menu_flow.gd              PASS          0 3.92s  All checks passed               
test_onboarding.gd             PASS          0 8.29s  All checks passed               
test_presentation.gd           PASS          0 2.06s  All checks passed               
test_slice_e2e.gd              FAIL          1 22.11s Assertion checks failed (Exit 1)
test_systems.gd                PASS          0 0.32s  All checks passed               
test_tapes.gd                  PASS          0 0.41s  All checks passed               
verify_camera_and_hud.gd       PASS          0 0.57s  All checks passed               



Totals: 19 tests | 18 PASSED |  FAILED
Full log saved to: C:\y2k-biopunk-rpg\.worktrees\vs11export\ops\runs\tests\20261008_134012.log

Test suite FAILED with 1 failure(s).

```

Script exit code: `1`.

## First build: release compilation and fresh-import rejection (exit 1)

Command from the assigned worktree:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops/tools/build_release.ps1
```

Complete stdout/stderr captured with `*> ops/runs/export/build_release.full.log` (line endings normalized for Markdown):

```text
Worktree: C:\y2k-biopunk-rpg\.worktrees\vs11export
Logs: C:\y2k-biopunk-rpg\.worktrees\vs11export\ops\runs\export\build_20261008_132952
COMMAND: py.exe -3 -m SCons platform=windows target=template_release -j8
scons: Reading SConscript files ...
Building for architecture x86_64 on platform windows
scons: done reading SConscript files.
scons: Building targets ...
Generating godot-cpp\gen\include\godot_cpp\core\ext_wrappers.gen.inc ...
Compiling godot-cpp\src\core\memory.cpp ...
Built-in type config: float_64
Compiling godot-cpp\gen\src\classes\editor_export_platform_ios.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_reroute.cpp ...
Compiling godot-cpp\gen\src\classes\editor_export_platform_web.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton_modification_stack2d.cpp ...
Compiling godot-cpp\gen\src\classes\editor_debugger_session.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_polygon.cpp ...
Compiling godot-cpp\gen\src\classes\label3d.cpp ...
Compiling godot-cpp\gen\src\classes\editor_node3d_gizmo.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton_profile_humanoid.cpp ...
Compiling godot-cpp\gen\src\classes\rendering_server.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_random_range.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton_modification2d_two_bone_ik.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_server3d.cpp ...
Compiling godot-cpp\gen\src\classes\java_class.cpp ...
Compiling godot-cpp\gen\src\classes\editor_export_platform_mac_os.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_particle_multiply_by_axis_angle.cpp ...
Compiling godot-cpp\gen\src\classes\slider.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_region3d.cpp ...
Compiling godot-cpp\gen\src\classes\kinematic_collision3d.cpp ...
Compiling godot-cpp\gen\src\classes\sky.cpp ...
Compiling godot-cpp\gen\src\classes\render_scene_data_rd.cpp ...
Compiling godot-cpp\gen\src\classes\editor_export_platform_linux_bsd.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_particle_ring_emitter.cpp ...
Compiling godot-cpp\gen\src\classes\h_box_container.cpp ...
Compiling godot-cpp\gen\src\classes\label.cpp ...
Compiling godot-cpp\gen\src\classes\editor_export_platform_android.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_path_query_result2d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_particle_mesh_emitter.cpp ...
Compiling godot-cpp\gen\src\classes\h_flow_container.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_step.cpp ...
Compiling godot-cpp\gen\src\classes\hmac_context.cpp ...
Compiling godot-cpp\gen\src\classes\java_class_wrapper.cpp ...
Compiling godot-cpp\gen\src\classes\slider_joint3d.cpp ...
Compiling godot-cpp\gen\src\classes\editor_export_platform.cpp ...
Compiling godot-cpp\gen\src\classes\render_scene_buffers_rd.cpp ...
Compiling godot-cpp\gen\src\classes\editor_debugger_plugin.cpp ...
Compiling godot-cpp\gen\src\classes\jsonrpc.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton_modification2d_physical_bones.cpp ...
Compiling godot-cpp\gen\src\classes\reg_ex.cpp ...
Compiling godot-cpp\gen\src\classes\editor_command_palette.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_path_query_result3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_particle_randomness.cpp ...
Compiling godot-cpp\gen\src\classes\groove_joint2d.cpp ...
Compiling godot-cpp\gen\src\classes\jni_singleton.cpp ...
Compiling godot-cpp\gen\src\classes\reflection_probe.cpp ...
Compiling godot-cpp\gen\src\classes\e_net_packet_peer.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_path_query_parameters3d.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton_modification2d.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_path_query_parameters2d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_screen_normal_world_space.cpp ...
Compiling godot-cpp\gen\src\classes\grid_container.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton_modification2d_jiggle.cpp ...
Compiling godot-cpp\gen\src\classes\random_number_generator.cpp ...
Compiling godot-cpp\gen\src\classes\e_net_connection.cpp ...
Compiling godot-cpp\gen\src\classes\graph_frame.cpp ...
Compiling godot-cpp\gen\src\classes\kinematic_collision2d.cpp ...
Compiling godot-cpp\gen\src\classes\shader_material.cpp ...
Compiling godot-cpp\gen\src\classes\display_server.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_sdf_to_screen_uv.cpp ...
Compiling godot-cpp\gen\src\classes\joint3d.cpp ...
Compiling godot-cpp\gen\src\classes\damped_spring_joint2d.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_region2d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_resizable_base.cpp ...
Compiling godot-cpp\gen\src\classes\joint2d.cpp ...
Compiling godot-cpp\gen\src\classes\resource.cpp ...
Compiling godot-cpp\gen\src\classes\directional_light3d.cpp ...
Compiling godot-cpp\gen\src\classes\directional_light2d.cpp ...
Compiling godot-cpp\gen\src\classes\node2d.cpp ...
Compiling godot-cpp\gen\src\classes\gradient.cpp ...
Compiling godot-cpp\gen\src\classes\shape_cast3d.cpp ...
Compiling godot-cpp\gen\src\classes\range.cpp ...
Compiling godot-cpp\gen\src\classes\java_script_object.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_particle_cone_velocity.cpp ...
Compiling godot-cpp\gen\src\classes\node.cpp ...
Compiling godot-cpp\gen\src\classes\graph_node.cpp ...
Compiling godot-cpp\gen\src\classes\render_scene_buffers_extension.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_server2d.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton3d.cpp ...
Compiling godot-cpp\gen\src\classes\nine_patch_rect.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton2d.cpp ...
Compiling godot-cpp\gen\src\classes\dir_access.cpp ...
Compiling godot-cpp\gen\src\classes\java_script_bridge.cpp ...
Compiling godot-cpp\gen\src\classes\remote_transform2d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_mix.cpp ...
Compiling godot-cpp\gen\src\classes\dtls_server.cpp ...
Compiling godot-cpp\gen\src\classes\gradient_texture2d.cpp ...
Compiling godot-cpp\gen\src\classes\reg_ex_match.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_parameter_ref.cpp ...
Compiling godot-cpp\gen\src\classes\collision_object3d.cpp ...
Compiling godot-cpp\gen\src\classes\json.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_outer_product.cpp ...
Compiling godot-cpp\gen\src\classes\placeholder_texture2d_array.cpp ...
Compiling godot-cpp\gen\src\classes\item_list.cpp ...
Compiling godot-cpp\gen\src\classes\collision_object2d.cpp ...
Compiling godot-cpp\gen\src\classes\generic6_dof_joint3d.cpp ...
Compiling godot-cpp\gen\src\classes\ref_counted.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_multiply_add.cpp ...
Compiling godot-cpp\gen\src\classes\curve_xyz_texture.cpp ...
Compiling godot-cpp\gen\src\classes\placeholder_cubemap.cpp ...
Compiling godot-cpp\gen\src\classes\geometry2d.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton_modification2dfabrik.cpp ...
Compiling godot-cpp\gen\src\classes\check_button.cpp ...
Compiling godot-cpp\gen\src\classes\pin_joint3d.cpp ...
Compiling godot-cpp\gen\src\classes\gradient_texture1_d.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton_modification2dccdik.cpp ...
Compiling godot-cpp\gen\src\classes\rectangle_shape2d.cpp ...
Compiling godot-cpp\gen\src\classes\circle_shape2d.cpp ...
Compiling godot-cpp\gen\src\classes\decal.cpp ...
Compiling godot-cpp\gen\src\classes\gpu_particles_collision_height_field3d.cpp ...
Compiling godot-cpp\gen\src\classes\interval_tweener.cpp ...
Compiling godot-cpp\gen\src\classes\ray_cast3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_output.cpp ...
Compiling godot-cpp\gen\src\classes\code_highlighter.cpp ...
Compiling godot-cpp\gen\src\classes\cylinder_shape3d.cpp ...
Compiling godot-cpp\gen\src\classes\graph_edit.cpp ...
Compiling godot-cpp\gen\src\classes\instance_placeholder.cpp ...
Compiling godot-cpp\gen\src\classes\shape3d.cpp ...
Compiling godot-cpp\gen\src\classes\render_data.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_particle_accelerator.cpp ...
Compiling godot-cpp\gen\src\classes\class_db_singleton.cpp ...
Compiling godot-cpp\gen\src\classes\cylinder_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\placeholder_texture_layered.cpp ...
Compiling godot-cpp\gen\src\classes\input_map.cpp ...
Compiling godot-cpp\gen\src\classes\remote_transform3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_particle_emitter.cpp ...
Compiling godot-cpp\gen\src\classes\character_body3d.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_with_modifiers.cpp ...
Compiling godot-cpp\gen\src\classes\shape2d.cpp ...
Compiling godot-cpp\gen\src\classes\e_net_multiplayer_peer.cpp ...
Compiling godot-cpp\gen\src\classes\placeholder_texture2d.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_shortcut.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton_modification2d_stack_holder.cpp ...
Compiling godot-cpp\gen\src\classes\character_body2d.cpp ...
Compiling godot-cpp\gen\src\classes\placeholder_cubemap_array.cpp ...
Compiling godot-cpp\gen\src\classes\gpu_particles_collision_sdf3d.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton_ik3d.cpp ...
Compiling godot-cpp\gen\src\classes\render_data_extension.cpp ...
Compiling godot-cpp\gen\src\classes\physics_test_motion_result3d.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_screen_touch.cpp ...
Compiling godot-cpp\gen\src\classes\shape_cast2d.cpp ...
Compiling godot-cpp\gen\src\classes\reference_rect.cpp ...
Compiling godot-cpp\gen\src\classes\code_edit.cpp ...
Compiling godot-cpp\gen\src\classes\placeholder_material.cpp ...
Compiling godot-cpp\gen\src\classes\grid_map.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_key.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton_modification2d_look_at.cpp ...
Compiling godot-cpp\gen\src\variant\array.cpp ...
Compiling godot-cpp\gen\src\classes\geometry_instance3d.cpp ...
Compiling godot-cpp\gen\src\classes\shortcut.cpp ...
Compiling godot-cpp\gen\src\classes\ray_cast2d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_particle_emit.cpp ...
Compiling godot-cpp\gen\src\classes\triangle_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\rd_shader_spirv.cpp ...
Compiling godot-cpp\gen\src\classes\check_box.cpp ...
Compiling godot-cpp\gen\src\classes\physics_test_motion_result2d.cpp ...
Compiling godot-cpp\gen\src\classes\graph_element.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_midi.cpp ...
Compiling godot-cpp\gen\src\classes\rd_vertex_attribute.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_particle_box_emitter.cpp ...
Compiling godot-cpp\gen\src\classes\curve3d.cpp ...
Compiling godot-cpp\gen\src\classes\geometry3d.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_joypad_motion.cpp ...
Compiling godot-cpp\gen\src\classes\rd_uniform.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_linear_scene_depth.cpp ...
Compiling godot-cpp\gen\src\classes\curve2d.cpp ...
Compiling godot-cpp\gen\src\classes\pin_joint2d.cpp ...
Compiling godot-cpp\gen\src\variant\string_name.cpp ...
Compiling godot-cpp\gen\src\classes\gpu_particles_collision_box3d.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_mouse_button.cpp ...
Compiling godot-cpp\gen\src\classes\char_fx_transform.cpp ...
Compiling godot-cpp\gen\src\classes\curve.cpp ...
Compiling godot-cpp\gen\src\classes\placeholder_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_mouse.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_is.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_mesh_source_geometry_data2d.cpp ...
Compiling godot-cpp\gen\src\classes\center_container.cpp ...
Compiling godot-cpp\gen\src\classes\cubemap_array.cpp ...
Compiling godot-cpp\gen\src\classes\point_light2d.cpp ...
Compiling godot-cpp\gen\src\variant\signal.cpp ...
Compiling godot-cpp\gen\src\variant\utility_functions.cpp ...
Compiling godot-cpp\gen\src\classes\gpu_particles_collision_sphere3d.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_screen_drag.cpp ...
Compiling godot-cpp\gen\src\classes\rd_texture_view.cpp ...
Compiling godot-cpp\gen\src\classes\convex_polygon_shape2d.cpp ...
Compiling godot-cpp\gen\src\variant\rid.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_mouse_motion.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_int_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\container.cpp ...
Compiling godot-cpp\gen\src\classes\gpu_particles_attractor_sphere3d.cpp ...
Compiling godot-cpp\gen\src\classes\rd_sampler_state.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_int_op.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_obstacle3d.cpp ...
Compiling godot-cpp\gen\src\classes\capsule_shape2d.cpp ...
Compiling godot-cpp\gen\src\classes\cubemap.cpp ...
Compiling godot-cpp\gen\src\classes\plane_mesh.cpp ...
Compiling godot-cpp\gen\src\variant\dictionary.cpp ...
Compiling godot-cpp\gen\src\classes\gpu_particles_attractor3d.cpp ...
Compiling godot-cpp\gen\src\classes\tile_set_atlas_source.cpp ...
Compiling godot-cpp\gen\src\classes\rd_texture_format.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_obstacle2d.cpp ...
Compiling godot-cpp\gen\src\classes\config_file.cpp ...
Compiling godot-cpp\gen\src\classes\placeholder_texture3d.cpp ...
Compiling godot-cpp\gen\src\classes\tile_set_scenes_collection_source.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_int_func.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_texture_sampler.cpp ...
Compiling godot-cpp\gen\src\classes\touch_screen_button.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_mesh_source_geometry_data3d.cpp ...
Compiling godot-cpp\gen\src\classes\camera_attributes.cpp ...
Compiling godot-cpp\gen\src\classes\crypto_key.cpp ...
Compiling godot-cpp\gen\src\classes\physics_test_motion_parameters3d.cpp ...
Compiling godot-cpp\gen\src\variant\callable.cpp ...
Compiling godot-cpp\src\classes\editor_plugin_registration.cpp ...
Compiling godot-cpp\gen\src\classes\rd_shader_file.cpp ...
Compiling godot-cpp\gen\src\classes\canvas_item_material.cpp ...
Compiling godot-cpp\gen\src\classes\tree.cpp ...
Compiling godot-cpp\gen\src\classes\rd_pipeline_specialization_constant.cpp ...
Compiling godot-cpp\gen\src\classes\camera_feed.cpp ...
Compiling godot-cpp\gen\src\classes\convex_polygon_shape3d.cpp ...
Compiling godot-cpp\gen\src\classes\physics_server3d_manager.cpp ...
Compiling godot-cpp\gen\src\classes\xrvrs.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_physics_shape.cpp ...
Compiling godot-cpp\gen\src\classes\rd_pipeline_multisample_state.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_float_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\camera_attributes_practical.cpp ...
Compiling godot-cpp\gen\src\classes\physics_shape_query_parameters3d.cpp ...
Compiling godot-cpp\gen\src\variant\packed_byte_array.cpp ...
Compiling godot-cpp\gen\src\classes\tweener.cpp ...
Compiling godot-cpp\gen\src\classes\rd_pipeline_depth_stencil_state.cpp ...
Compiling godot-cpp\gen\src\classes\canvas_texture.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_joypad_button.cpp ...
Compiling godot-cpp\gen\src\classes\tree_item.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_float_func.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_link3d.cpp ...
Compiling godot-cpp\gen\src\classes\cone_twist_joint3d.cpp ...
Compiling godot-cpp\gen\src\variant\node_path.cpp ...
Compiling godot-cpp\gen\src\classes\tween.cpp ...
Compiling godot-cpp\gen\src\classes\rd_pipeline_color_blend_state_attachment.cpp ...
Compiling godot-cpp\gen\src\classes\canvas_modulate.cpp ...
Compiling godot-cpp\gen\src\classes\control.cpp ...
Compiling godot-cpp\gen\src\variant\packed_string_array.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_skeleton.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_magnify_gesture.cpp ...
Compiling godot-cpp\gen\src\classes\translation.cpp ...
Compiling godot-cpp\gen\src\classes\rd_pipeline_color_blend_state.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_expression.cpp ...
Compiling godot-cpp\gen\src\classes\physics_server3d_extension.cpp ...
Compiling godot-cpp\gen\src\classes\xr_server.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_texture.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_agent2d.cpp ...
Compiling godot-cpp\gen\src\classes\camera_texture.cpp ...
Compiling godot-cpp\gen\src\classes\physics_server3d.cpp ...
Compiling godot-cpp\gen\src\classes\xr_positional_tracker.cpp ...
Compiling godot-cpp\gen\src\classes\gpu_particles2d.cpp ...
Compiling godot-cpp\gen\src\classes\tube_trail_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_float_constant.cpp ...
Compiling godot-cpp\gen\src\classes\native_menu.cpp ...
Compiling godot-cpp\gen\src\classes\canvas_layer.cpp ...
Compiling godot-cpp\gen\src\classes\xr_tracker.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_gesture.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_input.cpp ...
Compiling godot-cpp\gen\src\classes\mutex.cpp ...
Compiling godot-cpp\gen\src\classes\curve_texture.cpp ...
Compiling godot-cpp\gen\src\variant\packed_float64_array.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_spec_gloss.cpp ...
Compiling godot-cpp\gen\src\classes\time.cpp ...
Compiling godot-cpp\gen\src\classes\rd_framebuffer_pass.cpp ...
Compiling godot-cpp\gen\src\classes\physics_point_query_parameters3d.cpp ...
Compiling godot-cpp\gen\src\variant\packed_int64_array.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_from_window.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_int_constant.cpp ...
Compiling godot-cpp\gen\src\classes\multiplayer_api_extension.cpp ...
Compiling godot-cpp\gen\src\variant\packed_int32_array.cpp ...
Compiling godot-cpp\gen\src\classes\torus_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\rd_shader_source.cpp ...
Compiling godot-cpp\gen\src\classes\physics_server2d.cpp ...
Compiling godot-cpp\gen\src\variant\packed_float32_array.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_pan_gesture.cpp ...
Compiling godot-cpp\gen\src\classes\camera_server.cpp ...
Compiling godot-cpp\gen\src\classes\concave_polygon_shape3d.cpp ...
Compiling godot-cpp\gen\src\classes\timer.cpp ...
Compiling godot-cpp\gen\src\classes\rd_pipeline_rasterization_state.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_group_base.cpp ...
Compiling godot-cpp\gen\src\classes\camera_attributes_physical.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_face_forward.cpp ...
Compiling godot-cpp\gen\src\classes\multiplayer_api.cpp ...
Compiling godot-cpp\gen\src\classes\gpu_particles_collision3d.cpp ...
Compiling godot-cpp\gen\src\classes\tile_set_source.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_if.cpp ...
Compiling godot-cpp\gen\src\classes\physics_server3d_rendering_server_handler.cpp ...
Compiling godot-cpp\gen\src\classes\multi_mesh_instance3d.cpp ...
Compiling godot-cpp\gen\src\classes\confirmation_dialog.cpp ...
Compiling godot-cpp\gen\src\classes\audio_listener2d.cpp ...
Compiling godot-cpp\gen\src\classes\gpu_particles_attractor_vector_field3d.cpp ...
Compiling godot-cpp\gen\src\classes\tile_set.cpp ...
Compiling godot-cpp\gen\src\classes\tile_map_pattern.cpp ...
Compiling godot-cpp\gen\src\classes\rd_attachment_format.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_global_expression.cpp ...
Compiling godot-cpp\gen\src\classes\crypto.cpp ...
Compiling godot-cpp\gen\src\classes\physics_material.cpp ...
Compiling godot-cpp\gen\src\classes\zip_packer.cpp ...
Compiling godot-cpp\gen\src\classes\gpu_particles3d.cpp ...
Compiling godot-cpp\gen\src\classes\translation_server.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_float_op.cpp ...
Compiling godot-cpp\gen\src\classes\multi_mesh_instance2d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_pitch_shift.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_skin.cpp ...
Compiling godot-cpp\gen\src\classes\tile_map_layer.cpp ...
Compiling godot-cpp\gen\src\classes\quad_occluder3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_fresnel.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_agent3d.cpp ...
Compiling godot-cpp\gen\src\classes\capsule_shape3d.cpp ...
Compiling godot-cpp\gen\src\classes\compressed_texture_layered.cpp ...
Compiling godot-cpp\gen\src\classes\physics_direct_space_state3d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_stereo_enhance.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\progress_bar.cpp ...
Compiling godot-cpp\gen\src\classes\multi_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\compressed_texture3d.cpp ...
Compiling godot-cpp\gen\src\classes\physics_shape_query_parameters2d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_spectrum_analyzer_instance.cpp ...
Compiling godot-cpp\gen\src\classes\gpu_particles_attractor_box3d.cpp ...
Compiling godot-cpp\gen\src\classes\canvas_group.cpp ...
Compiling godot-cpp\gen\src\classes\compressed_texture2d.cpp ...
Compiling godot-cpp\gen\src\classes\physics_ray_query_parameters3d.cpp ...
Compiling godot-cpp\gen\src\classes\texture_rect.cpp ...
Compiling godot-cpp\gen\src\classes\multiplayer_peer.cpp ...
Compiling godot-cpp\gen\src\classes\capsule_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\compressed_texture2d_array.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_reverb.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_physics_body.cpp ...
Compiling godot-cpp\gen\src\classes\canvas_item.cpp ...
Compiling godot-cpp\gen\src\classes\physics_point_query_parameters2d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_spectrum_analyzer.cpp ...
Compiling godot-cpp\gen\src\classes\zip_reader.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_node.cpp ...
Compiling godot-cpp\gen\src\classes\texture_layered_rd.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_dot_product.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_state.cpp ...
Compiling godot-cpp\gen\src\classes\texture_layered.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_frame.cpp ...
Compiling godot-cpp\gen\src\classes\back_buffer_copy.cpp ...
Compiling godot-cpp\gen\src\classes\physics_test_motion_parameters2d.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_mesh_generator.cpp ...
Compiling godot-cpp\gen\src\classes\collision_polygon3d.cpp ...
Compiling godot-cpp\gen\src\classes\physics_server2d_manager.cpp ...
Compiling godot-cpp\gen\src\classes\xr_interface_extension.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_custom.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_wav.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\physics_server2d_extension.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_phaser.cpp ...
Compiling godot-cpp\gen\src\classes\xr_origin3d.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_document_extension.cpp ...
Compiling godot-cpp\gen\src\classes\texture_button.cpp ...
Compiling godot-cpp\gen\src\classes\popup_panel.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_randomizer.cpp ...
Compiling godot-cpp\gen\src\classes\multiplayer_spawner.cpp ...
Compiling godot-cpp\gen\src\classes\physics_ray_query_parameters2d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_record.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_camera.cpp ...
Compiling godot-cpp\gen\src\classes\popup_menu.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_panner.cpp ...
Compiling godot-cpp\gen\src\classes\xr_hand_modifier3d.cpp ...
Compiling godot-cpp\gen\src\classes\procedural_sky_material.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_curve_xyz_texture.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_synchronized.cpp ...
Compiling godot-cpp\gen\src\classes\navigation_link2d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_notch_filter.cpp ...
Compiling godot-cpp\gen\src\classes\xr_face_tracker.cpp ...
Compiling godot-cpp\gen\src\classes\gd_script.cpp ...
Compiling godot-cpp\gen\src\classes\texture_progress_bar.cpp ...
Compiling godot-cpp\gen\src\classes\portable_compressed_texture2d.cpp ...
Compiling godot-cpp\gen\src\classes\multiplayer_peer_extension.cpp ...
Compiling godot-cpp\gen\src\classes\xr_controller_tracker.cpp ...
Compiling godot-cpp\gen\src\classes\physics_direct_space_state3d_extension.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_low_shelf_filter.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_color_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_polyphonic.cpp ...
Compiling godot-cpp\gen\src\classes\multiplayer_synchronizer.cpp ...
Compiling godot-cpp\gen\src\classes\concave_polygon_shape2d.cpp ...
Compiling godot-cpp\gen\src\classes\gd_extension_manager.cpp ...
Compiling godot-cpp\gen\src\classes\property_tweener.cpp ...
Compiling godot-cpp\gen\src\classes\mobile_vr_interface.cpp ...
Compiling godot-cpp\gen\src\classes\xr_anchor3d.cpp ...
Compiling godot-cpp\gen\src\classes\font.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_determinant.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_playlist.cpp ...
Compiling godot-cpp\gen\src\classes\movie_writer.cpp ...
Compiling godot-cpp\gen\src\classes\collision_polygon2d.cpp ...
Compiling godot-cpp\gen\src\classes\physics_direct_body_state3d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_limiter.cpp ...
Compiling godot-cpp\gen\src\classes\theme_db.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_derivative_func.cpp ...
Compiling godot-cpp\gen\src\classes\compressed_cubemap_array.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_high_shelf_filter.cpp ...
Compiling godot-cpp\gen\src\classes\gd_extension.cpp ...
Compiling godot-cpp\gen\src\classes\prism_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_player3d.cpp ...
Compiling godot-cpp\gen\src\classes\missing_resource.cpp ...
Compiling godot-cpp\gen\src\classes\physics_direct_body_state2d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_chorus.cpp ...
Compiling godot-cpp\gen\src\classes\framebuffer_cache_rd.cpp ...
Compiling godot-cpp\gen\src\classes\tile_data.cpp ...
Compiling godot-cpp\gen\src\classes\primitive_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_player2d.cpp ...
Compiling godot-cpp\gen\src\classes\xr_pose.cpp ...
Compiling godot-cpp\gen\src\classes\polygon2d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_curve_texture.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_player.cpp ...
Compiling godot-cpp\gen\src\classes\missing_node.cpp ...
Compiling godot-cpp\gen\src\classes\compositor_effect.cpp ...
Compiling godot-cpp\gen\src\classes\physics_body2d.cpp ...
Compiling godot-cpp\gen\src\classes\xr_node3d.cpp ...
Compiling godot-cpp\gen\src\classes\theme.cpp ...
Compiling godot-cpp\gen\src\classes\polygon_path_finder.cpp ...
Compiling godot-cpp\gen\src\classes\method_tweener.cpp ...
Compiling godot-cpp\gen\src\classes\physics_body3d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_hard_limiter.cpp ...
Compiling godot-cpp\gen\src\classes\thread.cpp ...
Compiling godot-cpp\gen\src\classes\project_settings.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_constant.cpp ...
Compiling godot-cpp\gen\src\classes\compositor.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_filter.cpp ...
Compiling godot-cpp\gen\src\classes\xr_face_modifier3d.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_accessor.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_cubemap_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_playback_polyphonic.cpp ...
Compiling godot-cpp\gen\src\classes\marker2d.cpp ...
Compiling godot-cpp\gen\src\classes\collision_shape2d.cpp ...
Compiling godot-cpp\gen\src\classes\path_follow3d.cpp ...
Compiling godot-cpp\gen\src\classes\xr_hand_tracker.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_compare.cpp ...
Compiling godot-cpp\gen\src\classes\color_rect.cpp ...
Compiling godot-cpp\gen\src\classes\path_follow2d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_eq21.cpp ...
Compiling godot-cpp\gen\src\classes\texture_cubemap_array_rd.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_playback_ogg_vorbis.cpp ...
Compiling godot-cpp\gen\src\classes\physical_bone_simulator3d.cpp ...
Compiling godot-cpp\gen\src\classes\font_variation.cpp ...
Compiling godot-cpp\gen\src\classes\texture3drd.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_color_op.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_playback_playlist.cpp ...
Compiling godot-cpp\gen\src\classes\mesh_data_tool.cpp ...
Compiling godot-cpp\gen\src\classes\color_picker_button.cpp ...
Compiling godot-cpp\gen\src\classes\performance.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_document_extension_convert_importer_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\texture3d.cpp ...
Compiling godot-cpp\gen\src\classes\quad_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\physical_bone3d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_eq6.cpp ...
Compiling godot-cpp\gen\src\classes\tile_map.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_comment.cpp ...
Compiling godot-cpp\gen\src\classes\collision_shape3d.cpp ...
Compiling godot-cpp\gen\src\classes\x509_certificate.cpp ...
Compiling godot-cpp\gen\src\classes\point_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\color_picker.cpp ...
Compiling godot-cpp\gen\src\classes\physical_sky_material.cpp ...
Compiling godot-cpp\gen\src\classes\popup.cpp ...
Compiling godot-cpp\gen\src\classes\physics_direct_body_state2d_extension.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_buffer_view.cpp ...
Compiling godot-cpp\gen\src\classes\texture_cubemap_rd.cpp ...
Compiling godot-cpp\gen\src\classes\polygon_occluder3d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_interactive.cpp ...
Compiling godot-cpp\gen\src\classes\compressed_cubemap.cpp ...
Compiling godot-cpp\gen\src\classes\xr_body_modifier3d.cpp ...
Compiling godot-cpp\gen\src\classes\font_file.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_cubemap.cpp ...
Compiling godot-cpp\gen\src\classes\mesh_texture.cpp ...
Compiling godot-cpp\gen\src\classes\script_language_extension.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_animation.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_distance_fade.cpp ...
Compiling godot-cpp\gen\src\classes\audio_sample_playback.cpp ...
Compiling godot-cpp\gen\src\classes\mesh.cpp ...
Compiling godot-cpp\gen\src\classes\physics_direct_space_state2d_extension.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_eq.cpp ...
Compiling godot-cpp\gen\src\classes\xr_controller3d.cpp ...
Compiling godot-cpp\gen\src\classes\text_paragraph.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_state_machine_transition.cpp ...
Compiling godot-cpp\gen\src\classes\shader.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_light.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_color_constant.cpp ...
Compiling godot-cpp\gen\src\classes\audio_sample.cpp ...
Compiling godot-cpp\gen\src\classes\mesh_library.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_eq10.cpp ...
Compiling godot-cpp\gen\src\classes\texture2drd.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_sub2.cpp ...
Compiling godot-cpp\gen\src\classes\xr_interface.cpp ...
Compiling godot-cpp\gen\src\classes\gltf_document.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_boolean_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream.cpp ...
Compiling godot-cpp\gen\src\classes\menu_button.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_compressor.cpp ...
Compiling godot-cpp\gen\src\classes\xr_body_tracker.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_state_machine.cpp ...
Compiling godot-cpp\gen\src\classes\separator.cpp ...
Compiling godot-cpp\gen\src\classes\menu_bar.cpp ...
Compiling godot-cpp\gen\src\classes\texture2d_array.cpp ...
Compiling godot-cpp\gen\src\classes\scroll_bar.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node.cpp ...
Compiling godot-cpp\gen\src\classes\audio_listener3d.cpp ...
Compiling godot-cpp\gen\src\classes\file_access.cpp ...
Compiling godot-cpp\gen\src\classes\text_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_output.cpp ...
Compiling godot-cpp\gen\src\classes\visible_on_screen_notifier3d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_generator.cpp ...
Compiling godot-cpp\gen\src\classes\mesh_instance3d.cpp ...
Compiling godot-cpp\gen\src\classes\fog_volume.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_distortion.cpp ...
Compiling godot-cpp\gen\src\classes\texture2d_array_rd.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_playback.cpp ...
Compiling godot-cpp\gen\src\classes\mesh_convex_decomposition_settings.cpp ...
Compiling godot-cpp\gen\src\classes\physics_direct_space_state2d.cpp ...
Compiling godot-cpp\gen\src\classes\xr_camera3d.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_state_machine_playback.cpp ...
Compiling godot-cpp\gen\src\classes\separation_ray_shape3d.cpp ...
Compiling godot-cpp\gen\src\classes\visible_on_screen_enabler2d.cpp ...
Compiling godot-cpp\gen\src\classes\marshalls.cpp ...
Compiling godot-cpp\gen\src\classes\physics_direct_body_state3d_extension.cpp ...
Compiling godot-cpp\gen\src\classes\fog_material.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_low_pass_filter.cpp ...
Compiling godot-cpp\gen\src\classes\world_environment.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_mp3.cpp ...
Compiling godot-cpp\gen\src\classes\material.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_delay.cpp ...
Compiling godot-cpp\gen\src\classes\xml_parser.cpp ...
Compiling godot-cpp\gen\src\classes\text_server_extension.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_sync.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_boolean_constant.cpp ...
Compiling godot-cpp\gen\src\classes\marker3d.cpp ...
Compiling godot-cpp\gen\src\classes\flow_container.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_instance.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_time_scale.cpp ...
Compiling godot-cpp\gen\src\classes\segment_shape2d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_ogg_vorbis.cpp ...
Compiling godot-cpp\gen\src\classes\physical_bone2d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_high_pass_filter.cpp ...
Compiling godot-cpp\gen\src\classes\world3d.cpp ...
Compiling godot-cpp\gen\src\classes\video_stream_theora.cpp ...
Compiling godot-cpp\gen\src\classes\file_system_dock.cpp ...
Compiling godot-cpp\gen\src\classes\web_rtc_peer_connection_extension.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_one_shot.cpp ...
Compiling godot-cpp\gen\src\classes\shader_include.cpp ...
Compiling godot-cpp\gen\src\classes\visual_instance3d.cpp ...
Compiling godot-cpp\gen\src\classes\path2d.cpp ...
Compiling godot-cpp\gen\src\classes\window.cpp ...
Compiling godot-cpp\gen\src\classes\texture2d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_billboard.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_playback_synchronized.cpp ...
Compiling godot-cpp\gen\src\classes\particle_process_material.cpp ...
Compiling godot-cpp\gen\src\classes\file_dialog.cpp ...
Compiling godot-cpp\gen\src\classes\text_server_manager.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_transition.cpp ...
Compiling godot-cpp\gen\src\classes\scroll_container.cpp ...
Compiling godot-cpp\gen\src\classes\parallax_layer.cpp ...
Compiling godot-cpp\gen\src\classes\web_socket_peer.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_playback_resampled.cpp ...
Compiling godot-cpp\gen\src\classes\mesh_instance2d.cpp ...
Compiling godot-cpp\gen\src\classes\web_socket_multiplayer_peer.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_blend_tree.cpp ...
Compiling godot-cpp\gen\src\classes\shader_globals_override.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_microphone.cpp ...
Compiling godot-cpp\gen\src\classes\margin_container.cpp ...
Compiling godot-cpp\gen\src\classes\world_boundary_shape2d.cpp ...
Compiling godot-cpp\gen\src\classes\text_server_advanced.cpp ...
Compiling godot-cpp\gen\src\classes\animation_root_node.cpp ...
Compiling godot-cpp\gen\src\classes\visible_on_screen_enabler3d.cpp ...
Compiling godot-cpp\gen\src\classes\packet_peer_udp.cpp ...
Compiling godot-cpp\gen\src\classes\fbx_state.cpp ...
Compiling godot-cpp\gen\src\classes\world2d.cpp ...
Compiling godot-cpp\gen\src\classes\text_server.cpp ...
Compiling godot-cpp\gen\src\classes\audio_server.cpp ...
Compiling godot-cpp\gen\src\classes\expression.cpp ...
Compiling godot-cpp\gen\src\classes\texture.cpp ...
Compiling godot-cpp\gen\src\classes\line2d.cpp ...
Compiling godot-cpp\gen\src\classes\web_rtc_multiplayer_peer.cpp ...
Compiling godot-cpp\gen\src\classes\text_server_dummy.cpp ...
Compiling godot-cpp\gen\src\classes\separation_ray_shape2d.cpp ...
Compiling godot-cpp\gen\src\classes\packed_data_container_ref.cpp ...
Compiling godot-cpp\gen\src\classes\animation_player.cpp ...
Compiling godot-cpp\gen\src\classes\semaphore.cpp ...
Compiling godot-cpp\gen\src\classes\viewport.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_playback_interactive.cpp ...
Compiling godot-cpp\gen\src\classes\label_settings.cpp ...
Compiling godot-cpp\gen\src\classes\worker_thread_pool.cpp ...
Compiling godot-cpp\gen\src\classes\viewport_texture.cpp ...
Compiling godot-cpp\gen\src\classes\lightmap_gi_data.cpp ...
Compiling godot-cpp\gen\src\classes\tcp_server.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_time_seek.cpp ...
Compiling godot-cpp\gen\src\classes\script_editor_base.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_color_func.cpp ...
Compiling godot-cpp\gen\src\classes\audio_stream_generator_playback.cpp ...
Compiling godot-cpp\gen\src\classes\panel.cpp ...
Compiling godot-cpp\gen\src\classes\script_create_dialog.cpp ...
Compiling godot-cpp\gen\src\classes\light3d.cpp ...
Compiling godot-cpp\gen\src\classes\packed_data_container.cpp ...
Compiling godot-cpp\gen\src\classes\surface_tool.cpp ...
Compiling godot-cpp\gen\src\classes\light2d.cpp ...
Compiling godot-cpp\gen\src\classes\packet_peer_dtls.cpp ...
Compiling godot-cpp\gen\src\classes\editor_undo_redo_manager.cpp ...
Compiling godot-cpp\gen\src\classes\web_rtc_data_channel_extension.cpp ...
Compiling godot-cpp\gen\src\classes\scene_tree.cpp ...
Compiling godot-cpp\gen\src\classes\camera3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_clamp.cpp ...
Compiling godot-cpp\gen\src\classes\light_occluder2d.cpp ...
Compiling godot-cpp\gen\src\classes\text_line.cpp ...
Compiling godot-cpp\gen\src\classes\animation_mixer.cpp ...
Compiling godot-cpp\gen\src\classes\web_rtc_peer_connection.cpp ...
Compiling godot-cpp\gen\src\classes\editor_selection.cpp ...
Compiling godot-cpp\gen\src\classes\scene_tree_timer.cpp ...
Compiling godot-cpp\gen\src\classes\lightmapper.cpp ...
Compiling godot-cpp\gen\src\classes\editor_spin_slider.cpp ...
Compiling godot-cpp\gen\src\classes\animated_sprite3d.cpp ...
Compiling godot-cpp\gen\src\classes\camera2d.cpp ...
Compiling godot-cpp\gen\src\classes\visible_on_screen_notifier2d.cpp ...
Compiling godot-cpp\gen\src\classes\tab_container.cpp ...
Compiling godot-cpp\gen\src\classes\web_xr_interface.cpp ...
Compiling godot-cpp\gen\src\classes\rich_text_label.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader.cpp ...
Compiling godot-cpp\gen\src\classes\parallax2d.cpp ...
Compiling godot-cpp\gen\src\classes\engine_profiler.cpp ...
Compiling godot-cpp\gen\src\classes\animation.cpp ...
Compiling godot-cpp\gen\src\classes\web_rtc_data_channel.cpp ...
Compiling godot-cpp\gen\src\classes\scene_replication_config.cpp ...
Compiling godot-cpp\gen\src\classes\callback_tweener.cpp ...
Compiling godot-cpp\gen\src\classes\panel_container.cpp ...
Compiling godot-cpp\gen\src\classes\fbx_document.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_blend_space2d.cpp ...
Compiling godot-cpp\gen\src\classes\csg_torus3d.cpp ...
Compiling godot-cpp\gen\src\classes\video_stream.cpp ...
Compiling godot-cpp\gen\src\classes\lightmapper_rd.cpp ...
Compiling godot-cpp\gen\src\classes\engine.cpp ...
Compiling godot-cpp\gen\src\classes\system_font.cpp ...
Compiling godot-cpp\src\classes\low_level.cpp ...
Compiling godot-cpp\gen\src\classes\scene_state.cpp ...
Compiling godot-cpp\gen\src\classes\csg_sphere3d.cpp ...
Compiling godot-cpp\gen\src\classes\packet_peer.cpp ...
Compiling godot-cpp\gen\src\classes\syntax_highlighter.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_blend_space1_d.cpp ...
Compiling godot-cpp\gen\src\classes\csg_shape3d.cpp ...
Compiling godot-cpp\gen\src\classes\packed_scene.cpp ...
Compiling godot-cpp\gen\src\classes\environment.cpp ...
Compiling godot-cpp\gen\src\classes\text_edit.cpp ...
Compiling godot-cpp\gen\src\classes\animation_library.cpp ...
Compiling godot-cpp\gen\src\classes\world_boundary_shape3d.cpp ...
Compiling godot-cpp\gen\src\classes\ribbon_trail_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\csg_primitive3d.cpp ...
Compiling godot-cpp\gen\src\classes\lightmap_probe.cpp ...
Compiling godot-cpp\gen\src\classes\encoded_object_as_id.cpp ...
Compiling godot-cpp\gen\src\classes\tab_bar.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_world_position_from_depth.cpp ...
Compiling godot-cpp\gen\src\classes\rigid_body2d.cpp ...
Compiling godot-cpp\gen\src\classes\path3d.cpp ...
Compiling godot-cpp\gen\src\classes\editor_syntax_highlighter.cpp ...
Compiling godot-cpp\gen\src\classes\animated_texture.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vector_refract.cpp ...
Compiling godot-cpp\gen\src\classes\script_language.cpp ...
Compiling godot-cpp\gen\src\classes\csg_polygon3d.cpp ...
Compiling godot-cpp\gen\src\classes\parallax_background.cpp ...
Compiling godot-cpp\gen\src\classes\editor_translation_parser_plugin.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_animation.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vector_base.cpp ...
Compiling godot-cpp\gen\src\classes\script.cpp ...
Compiling godot-cpp\gen\src\classes\csg_mesh3d.cpp ...
Compiling godot-cpp\gen\src\classes\lightmap_gi.cpp ...
Compiling godot-cpp\gen\src\classes\editor_vcs_interface.cpp ...
Compiling godot-cpp\gen\src\classes\tls_options.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_blend3.cpp ...
Compiling godot-cpp\gen\src\classes\v_flow_container.cpp ...
Compiling godot-cpp\gen\src\classes\main_loop.cpp ...
Compiling godot-cpp\gen\src\classes\script_extension.cpp ...
Compiling godot-cpp\gen\src\classes\csg_cylinder3d.cpp ...
Compiling godot-cpp\gen\src\classes\upnp_device.cpp ...
Compiling godot-cpp\gen\src\classes\link_button.cpp ...
Compiling godot-cpp\gen\src\classes\sub_viewport_container.cpp ...
Compiling godot-cpp\gen\src\classes\script_editor.cpp ...
Compiling godot-cpp\gen\src\classes\packet_peer_extension.cpp ...
Compiling godot-cpp\gen\src\classes\fast_noise_lite.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vector_compose.cpp ...
Compiling godot-cpp\gen\src\classes\csg_combiner3d.cpp ...
Compiling godot-cpp\gen\src\classes\v_box_container.cpp ...
Compiling godot-cpp\gen\src\classes\line_edit.cpp ...
Compiling godot-cpp\gen\src\classes\panorama_sky_material.cpp ...
Compiling godot-cpp\gen\src\classes\style_box_texture.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vector_decompose.cpp ...
Compiling godot-cpp\gen\src\classes\root_motion_view.cpp ...
Compiling godot-cpp\gen\src\classes\csg_box3d.cpp ...
Compiling godot-cpp\gen\src\classes\uniform_set_cache_rd.cpp ...
Compiling godot-cpp\gen\src\classes\packet_peer_stream.cpp ...
Compiling godot-cpp\gen\src\classes\engine_debugger.cpp ...
Compiling godot-cpp\gen\src\classes\style_box_line.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_blend2.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vector_func.cpp ...
Compiling godot-cpp\gen\src\classes\style_box.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vec4_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\scene_multiplayer.cpp ...
Compiling godot-cpp\gen\src\classes\cpu_particles3d.cpp ...
Compiling godot-cpp\gen\src\classes\vehicle_body3d.cpp ...
Compiling godot-cpp\gen\src\classes\open_xr_interaction_profile.cpp ...
Compiling godot-cpp\gen\src\classes\editor_settings.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_add3.cpp ...
Compiling godot-cpp\gen\src\classes\cpu_particles2d.cpp ...
Compiling godot-cpp\gen\src\classes\open_xr_hand.cpp ...
Compiling godot-cpp\gen\src\classes\style_box_flat.cpp ...
Compiling godot-cpp\gen\src\classes\button_group.cpp ...
Compiling godot-cpp\gen\src\classes\undo_redo.cpp ...
Compiling godot-cpp\gen\src\classes\editor_script_picker.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node_add2.cpp ...
Compiling godot-cpp\gen\src\classes\v_separator.cpp ...
Compiling godot-cpp\gen\src\classes\open_xr_composition_layer_equirect.cpp ...
Compiling godot-cpp\gen\src\classes\style_box_empty.cpp ...
Compiling godot-cpp\gen\src\classes\animation_node.cpp ...
Compiling godot-cpp\gen\src\classes\voxel_gi_data.cpp ...
Compiling godot-cpp\gen\src\classes\v_split_container.cpp ...
Compiling godot-cpp\gen\src\classes\open_xr_action_set.cpp ...
Compiling godot-cpp\gen\src\classes\editor_script.cpp ...
Compiling godot-cpp\gen\src\classes\vehicle_wheel3d.cpp ...
Compiling godot-cpp\gen\src\classes\stream_peer_gzip.cpp ...
Compiling godot-cpp\gen\src\classes\voxel_gi.cpp ...
Compiling godot-cpp\gen\src\classes\rich_text_effect.cpp ...
Compiling godot-cpp\gen\src\classes\v_slider.cpp ...
Compiling godot-cpp\gen\src\classes\open_xrip_binding.cpp ...
Compiling godot-cpp\gen\src\classes\editor_scene_post_import.cpp ...
Compiling godot-cpp\gen\src\classes\status_indicator.cpp ...
Compiling godot-cpp\gen\src\classes\rigid_body3d.cpp ...
Compiling godot-cpp\gen\src\classes\optimized_translation.cpp ...
Compiling godot-cpp\gen\src\classes\accept_dialog.cpp ...
Compiling godot-cpp\gen\src\classes\stream_peer.cpp ...
Compiling godot-cpp\gen\src\classes\box_container.cpp ...
Compiling godot-cpp\gen\src\classes\editor_scene_format_importer_gltf.cpp ...
Compiling godot-cpp\gen\src\classes\a_star3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vector_len.cpp ...
Compiling godot-cpp\gen\src\classes\resource_uid.cpp ...
Compiling godot-cpp\gen\src\classes\open_xr_action_map.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vector_distance.cpp ...
Compiling godot-cpp\gen\src\classes\udp_server.cpp ...
Compiling godot-cpp\gen\src\classes\editor_scene_format_importer_ufbx.cpp ...
Compiling godot-cpp\gen\src\classes\stream_peer_tcp.cpp ...
Compiling godot-cpp\gen\src\classes\resource_saver.cpp ...
Compiling godot-cpp\gen\src\classes\open_xr_composition_layer_quad.cpp ...
Compiling godot-cpp\gen\src\classes\editor_scene_format_importer.cpp ...
Compiling godot-cpp\gen\src\variant\packed_vector3_array.cpp ...
Compiling godot-cpp\gen\src\variant\string.cpp ...
Compiling godot-cpp\gen\src\classes\bit_map.cpp ...
Compiling godot-cpp\gen\src\classes\video_stream_player.cpp ...
Compiling godot-cpp\gen\src\classes\animatable_body3d.cpp ...
Compiling godot-cpp\gen\src\classes\sprite3d.cpp ...
Compiling godot-cpp\gen\src\classes\weak_ref.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_wav.cpp ...
Compiling godot-cpp\gen\src\classes\video_stream_playback.cpp ...
Compiling godot-cpp\gen\src\classes\editor_property.cpp ...
Compiling godot-cpp\gen\src\classes\v_scroll_bar.cpp ...
Compiling godot-cpp\gen\src\classes\open_xr_composition_layer.cpp ...
Compiling godot-cpp\gen\src\classes\editor_paths.cpp ...
Compiling godot-cpp\gen\src\classes\aes_context.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vector_op.cpp ...
Compiling godot-cpp\gen\src\classes\editor_resource_tooltip_plugin.cpp ...
Compiling godot-cpp\gen\src\classes\animatable_body2d.cpp ...
Compiling godot-cpp\src\variant\quaternion.cpp ...
Compiling godot-cpp\src\variant\vector3i.cpp ...
Compiling godot-cpp\src\variant\plane.cpp ...
Compiling godot-cpp\src\variant\aabb.cpp ...
Compiling godot-cpp\src\variant\color.cpp ...
Compiling godot-cpp\src\variant\vector4i.cpp ...
Compiling godot-cpp\src\variant\char_string.cpp ...
Compiling godot-cpp\src\variant\vector2i.cpp ...
Compiling godot-cpp\src\variant\basis.cpp ...
Compiling godot-cpp\src\variant\vector4.cpp ...
Compiling godot-cpp\src\variant\vector3.cpp ...
Compiling godot-cpp\src\variant\rect2i.cpp ...
Compiling godot-cpp\src\core\error_macros.cpp ...
Compiling godot-cpp\src\variant\vector2.cpp ...
Compiling godot-cpp\gen\src\classes\upnp.cpp ...
Compiling godot-cpp\gen\src\classes\pck_packer.cpp ...
Compiling godot-cpp\gen\src\classes\editor_resource_preview_generator.cpp ...
Compiling godot-cpp\src\variant\rect2.cpp ...
Compiling godot-cpp\src\variant\transform2d.cpp ...
Compiling godot-cpp\gen\src\classes\sprite_base3d.cpp ...
Compiling godot-cpp\gen\src\classes\resource_loader.cpp ...
Compiling godot-cpp\gen\src\classes\base_button.cpp ...
Compiling godot-cpp\gen\src\classes\editor_resource_picker.cpp ...
Compiling godot-cpp\gen\src\variant\packed_vector2_array.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_scene.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vec3_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_image.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_texture2d_array.cpp ...
Compiling godot-cpp\gen\src\classes\editor_node3d_gizmo_plugin.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_texture_atlas.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_texture.cpp ...
Compiling godot-cpp\gen\src\classes\open_xr_extension_wrapper_extension.cpp ...
Compiling godot-cpp\gen\src\classes\editor_scene_post_import_plugin.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vec3_constant.cpp ...
Compiling godot-cpp\gen\src\classes\bone_map.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_switch.cpp ...
Compiling godot-cpp\gen\src\classes\input_event_action.cpp ...
Compiling godot-cpp\gen\src\classes\editor_scene_format_importer_blend.cpp ...
Compiling godot-cpp\src\variant\projection.cpp ...
Compiling godot-cpp\src\variant\transform3d.cpp ...
Compiling godot-cpp\src\variant\packed_arrays.cpp ...
Compiling godot-cpp\gen\src\classes\sub_viewport.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_shader_file.cpp ...
Compiling godot-cpp\gen\src\classes\box_shape3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vec2_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_texture3d_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\stream_peer_buffer.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_varying_setter.cpp ...
Compiling godot-cpp\gen\src\classes\open_xr_interaction_profile_metadata.cpp ...
Compiling godot-cpp\gen\src\classes\a_star_grid2d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_varying_getter.cpp ...
Compiling godot-cpp\gen\src\classes\button.cpp ...
Compiling godot-cpp\gen\src\classes\option_button.cpp ...
Compiling godot-cpp\gen\src\classes\importer_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\a_star2d.cpp ...
Compiling godot-cpp\gen\src\classes\stream_peer_extension.cpp ...
Compiling godot-cpp\gen\src\classes\box_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\open_xr_interface.cpp ...
Compiling godot-cpp\gen\src\classes\input_event.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_varying.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_layered_texture.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_texture_sdf.cpp ...
Compiling godot-cpp\gen\src\classes\open_xr_composition_layer_cylinder.cpp ...
Compiling godot-cpp\gen\src\classes\spring_arm3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_uv_polar_coord.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_obj.cpp ...
Compiling godot-cpp\gen\src\classes\open_xr_action.cpp ...
Compiling godot-cpp\gen\src\classes\input.cpp ...
Compiling godot-cpp\gen\src\classes\animated_sprite2d.cpp ...
Compiling godot-cpp\gen\src\classes\spot_light3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_transform_func.cpp ...
Compiling godot-cpp\gen\src\classes\bone2d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_texture2d_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\open_xrapi_extension.cpp ...
Compiling godot-cpp\gen\src\classes\importer_mesh_instance3d.cpp ...
Compiling godot-cpp\gen\src\classes\editor_plugin.cpp ...
Compiling godot-cpp\gen\src\classes\static_body2d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_uv_func.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_texture.cpp ...
Compiling godot-cpp\gen\src\classes\base_material3d.cpp ...
Compiling godot-cpp\gen\src\classes\omni_light3d.cpp ...
Compiling godot-cpp\gen\src\variant\packed_color_array.cpp ...
Compiling godot-cpp\gen\src\classes\resource_preloader.cpp ...
Compiling godot-cpp\gen\src\classes\box_occluder3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_texture3d.cpp ...
Compiling godot-cpp\gen\src\classes\immediate_mesh.cpp ...
Compiling godot-cpp\gen\src\variant\packed_vector4_array.cpp ...
Compiling godot-cpp\gen\src\classes\stream_peer_tls.cpp ...
Compiling godot-cpp\gen\src\classes\bone_attachment3d.cpp ...
Compiling godot-cpp\gen\src\classes\ogg_packet_sequence_playback.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_u_int_constant.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_ogg_vorbis.cpp ...
Compiling godot-cpp\gen\src\classes\image_texture_layered.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_mp3.cpp ...
Compiling godot-cpp\gen\src\classes\aspect_ratio_container.cpp ...
Compiling godot-cpp\gen\src\classes\offline_multiplayer_peer.cpp ...
Compiling godot-cpp\gen\src\classes\editor_scene_format_importer_fbx2_gltf.cpp ...
Compiling godot-cpp\gen\src\classes\sprite2d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_u_int_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\area2d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_transform_compose.cpp ...
Compiling godot-cpp\gen\src\classes\editor_resource_preview.cpp ...
Compiling godot-cpp\gen\src\classes\sprite_frames.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_transform_constant.cpp ...
Compiling godot-cpp\gen\src\classes\orm_material3d.cpp ...
Compiling godot-cpp\gen\src\classes\editor_resource_conversion_plugin.cpp ...
Compiling godot-cpp\gen\src\classes\standard_material3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_transform_op.cpp ...
Compiling godot-cpp\gen\src\classes\array_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\node3d_gizmo.cpp ...
Compiling godot-cpp\gen\src\classes\image_texture.cpp ...
Compiling godot-cpp\gen\src\classes\static_body3d.cpp ...
Compiling godot-cpp\gen\src\classes\editor_inspector.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_u_int_func.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_image_font.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_texture_sdf_normal.cpp ...
Compiling godot-cpp\gen\src\classes\image_format_loader.cpp ...
Compiling godot-cpp\gen\src\classes\editor_export_platform_windows.cpp ...
Compiling godot-cpp\gen\src\classes\audio_bus_layout.cpp ...
Compiling godot-cpp\gen\src\classes\height_map_shape3d.cpp ...
Compiling godot-cpp\gen\src\classes\split_container.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_dynamic_font.cpp ...
Compiling godot-cpp\gen\src\classes\area3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_texture_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\occluder3d.cpp ...
Compiling godot-cpp\gen\src\classes\http_client.cpp ...
Compiling godot-cpp\gen\src\classes\animation_tree.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_texture2d_array_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\os.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_transform_parameter.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_csv_translation.cpp ...
Compiling godot-cpp\gen\src\classes\noise_texture3d.cpp ...
Compiling godot-cpp\gen\src\classes\h_split_container.cpp ...
Compiling godot-cpp\gen\src\classes\editor_import_plugin.cpp ...
Compiling godot-cpp\gen\src\classes\spin_box.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vec4_constant.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_texture_parameter_triplanar.cpp ...
Compiling godot-cpp\gen\src\classes\noise.cpp ...
Compiling godot-cpp\gen\src\classes\h_slider.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_bit_map.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_capture.cpp ...
Compiling godot-cpp\gen\src\classes\ip.cpp ...
Compiling godot-cpp\gen\src\classes\editor_file_system_directory.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_vec2_constant.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer_bm_font.cpp ...
Compiling godot-cpp\gen\src\classes\node3d.cpp ...
Compiling godot-cpp\gen\src\classes\h_separator.cpp ...
Compiling godot-cpp\gen\src\classes\editor_file_system.cpp ...
Compiling godot-cpp\gen\src\classes\sphere_mesh.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_transform_vec_mult.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_smooth_step.cpp ...
Compiling godot-cpp\gen\src\classes\editor_file_dialog.cpp ...
Compiling godot-cpp\gen\src\classes\resource_importer.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_screen_uv_to_sdf.cpp ...
Compiling godot-cpp\gen\src\classes\occluder_instance3d.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton_modifier3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_u_int_op.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_band_pass_filter.cpp ...
Compiling godot-cpp\gen\src\classes\http_request.cpp ...
Compiling godot-cpp\gen\src\classes\editor_export_plugin.cpp ...
Compiling godot-cpp\gen\src\classes\sphere_shape3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_transform_decompose.cpp ...
Compiling godot-cpp\gen\src\classes\resource_format_saver.cpp ...
Compiling godot-cpp\src\variant\variant.cpp ...
Compiling shared src\intro_controller.cpp ...
Compiling godot-cpp\src\godot.cpp ...
Compiling shared src\menu_controller.cpp ...
Compiling godot-cpp\src\classes\wrapped.cpp ...
Compiling godot-cpp\src\variant\callable_custom.cpp ...
Compiling godot-cpp\src\core\object.cpp ...
Compiling godot-cpp\src\core\class_db.cpp ...
Compiling godot-cpp\src\variant\callable_method_pointer.cpp ...
Compiling godot-cpp\src\core\method_bind.cpp ...
Compiling godot-cpp\gen\src\classes\image_format_loader_extension.cpp ...
Compiling godot-cpp\gen\src\classes\sphere_occluder3d.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_band_limit_filter.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_sample3d.cpp ...
Compiling godot-cpp\gen\src\classes\ogg_packet_sequence.cpp ...
Compiling godot-cpp\gen\src\classes\hashing_context.cpp ...
Compiling godot-cpp\gen\src\classes\resource_format_loader.cpp ...
Compiling godot-cpp\gen\src\classes\atlas_texture.cpp ...
Compiling godot-cpp\gen\src\classes\occluder_polygon2d.cpp ...
Compiling godot-cpp\gen\src\classes\editor_export_platform_pc.cpp ...
Compiling godot-cpp\gen\src\classes\skeleton_profile.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_sdf_raymarch.cpp ...
Compiling godot-cpp\gen\src\classes\hinge_joint3d.cpp ...
Compiling godot-cpp\gen\src\classes\editor_interface.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_remap.cpp ...
Compiling godot-cpp\gen\src\classes\rendering_device.cpp ...
Compiling shared src\player_controller.cpp ...
Compiling shared src\register_types.cpp ...
Compiling godot-cpp\gen\src\classes\render_scene_data_extension.cpp ...
Compiling godot-cpp\gen\src\classes\array_occluder3d.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_particle_sphere_emitter.cpp ...
Compiling godot-cpp\gen\src\classes\h_scroll_bar.cpp ...
Compiling godot-cpp\gen\src\classes\editor_file_system_import_format_support_query.cpp ...
Compiling godot-cpp\gen\src\classes\render_scene_data.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_proximity_fade.cpp ...
Compiling godot-cpp\src\core\print_string.cpp ...
Compiling godot-cpp\gen\src\classes\skin.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_rotation_by_axis.cpp ...
Compiling godot-cpp\gen\src\classes\noise_texture2d.cpp ...
Compiling godot-cpp\gen\src\classes\render_scene_buffers_configuration.cpp ...
Compiling godot-cpp\gen\src\classes\audio_effect_amplify.cpp ...
Compiling godot-cpp\gen\src\classes\image.cpp ...
Compiling godot-cpp\gen\src\classes\editor_inspector_plugin.cpp ...
Compiling godot-cpp\gen\src\classes\skin_reference.cpp ...
Compiling godot-cpp\gen\src\classes\render_scene_buffers.cpp ...
Compiling godot-cpp\gen\src\classes\visual_shader_node_particle_output.cpp ...
Compiling godot-cpp\gen\src\classes\editor_feature_profile.cpp ...
Compiling godot-cpp\gen\src\classes\render_data_rd.cpp ...
Compiling godot-cpp\gen\src\classes\image_texture3d.cpp ...
Compiling godot-cpp\gen\src\classes\soft_body3d.cpp ...
Compiling godot-cpp\gen\src\classes\object.cpp ...
Linking Static Library godot-cpp\bin\libgodot-cpp.windows.template_release.x86_64.lib ...
Linking Shared Library bin\libbiopunk.windows.template_release.x86_64.dll ...
scons: done building targets.

EXIT: 0 (scons)
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\Godot_v4.3-stable_win64.exe --headless --path "C:\y2k-biopunk-rpg\.worktrees\vs11export" --import
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

ERROR: Condition "f.is_null()" is true. Continuing.
   at: get_multiple_md5 (core/io/file_access.cpp:812)
ERROR: Condition "f.is_null()" is true. Continuing.
   at: get_multiple_md5 (core/io/file_access.cpp:812)

EXIT: 0 (import)
BUILD: FAIL - import failed; see C:\y2k-biopunk-rpg\.worktrees\vs11export\ops\runs\export\build_20261008_132952

```

Script exit code: `1`.

## Second build: clean import and dummy-renderer gate rejection (exit 1)

Command from the assigned worktree:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops/tools/build_release.ps1
```

Complete stdout/stderr captured with `*> ops/runs/export/build_release.retry.full.log` (line endings normalized for Markdown):

```text
Worktree: C:\y2k-biopunk-rpg\.worktrees\vs11export
Logs: C:\y2k-biopunk-rpg\.worktrees\vs11export\ops\runs\export\build_20261008_133608
Release DLL is current; skipping SCons.
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\Godot_v4.3-stable_win64.exe --headless --path "C:\y2k-biopunk-rpg\.worktrees\vs11export" --import
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org


EXIT: 0 (import)
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\Godot_v4.3-stable_win64.exe --headless --path "C:\y2k-biopunk-rpg\.worktrees\vs11export" --export-release "Windows Desktop" build/release/Y2K-BioPunk.exe
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

savepack: begin: Packing steps: 102
	savepack: step 2: Storing File: res://.godot/imported/dial_up_queen.glb-c1a5cb2f8ad5373c4dcab5634b6375c1.scn
	savepack: step 2: Storing File: res://assets/models/dial_up_queen.glb.import
	savepack: step 2: Storing File: res://.godot/imported/fountain_sculpture.glb-a0ab240fe62ced988ba9a52de635ff8f.scn
	savepack: step 2: Storing File: res://assets/models/fountain_sculpture.glb.import
	savepack: step 2: Storing File: res://.godot/imported/kiosk_turret.glb-21d18cfe5e39c287914cfac610d69389.scn
	savepack: step 2: Storing File: res://assets/models/kiosk_turret.glb.import
	savepack: step 2: Storing File: res://.godot/imported/mall_kiosk.glb-ef7ad498f3da947c3b5d733a4903be11.scn
	savepack: step 2: Storing File: res://assets/models/mall_kiosk.glb.import
	savepack: step 2: Storing File: res://.godot/imported/mall_planter.glb-f1515752ded96a398eafbdc994b6e669.scn
	savepack: step 2: Storing File: res://assets/models/mall_planter.glb.import
	savepack: step 3: Storing File: res://.godot/imported/neon_cicada.glb-c075b36b4e093e1d35265564e67f028c.scn
	savepack: step 3: Storing File: res://assets/models/neon_cicada.glb.import
	savepack: step 3: Storing File: res://.godot/imported/sludge_roach.glb-1ae35041ab2d79767ebaf70f00e6243f.scn
	savepack: step 3: Storing File: res://assets/models/sludge_roach.glb.import
	savepack: step 3: Storing File: res://.godot/imported/anthem.mp3-2f7a92cf245df82890b7830193e2bea6.mp3str
	savepack: step 3: Storing File: res://music/anthem.mp3.import
	savepack: step 3: Storing File: res://.godot/imported/bigbeat.mp3-719a317dfac214297f4d640840ee7874.mp3str
	savepack: step 3: Storing File: res://music/bigbeat.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/bubblegum.mp3-6600d7a64ddbbec66a2b18480a79e0ad.mp3str
	savepack: step 4: Storing File: res://music/bubblegum.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/combat.mp3-1829eebac0ee46487ae84a3be83a352e.mp3str
	savepack: step 4: Storing File: res://music/combat.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/eurodance.mp3-fef95430f66d8053d0220ef34137fda9.mp3str
	savepack: step 4: Storing File: res://music/eurodance.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/hiphop.mp3-3d4b4945f60e4d0cddde31e8acbf2438.mp3str
	savepack: step 4: Storing File: res://music/hiphop.mp3.import
	savepack: step 5: Storing File: res://.godot/imported/numetal.mp3-058dd4db2f01f0c63415579f555fa23f.mp3str
	savepack: step 5: Storing File: res://music/numetal.mp3.import
	savepack: step 5: Storing File: res://.godot/imported/skater.mp3-47c0b3f6a66951ef919ba1b8e36e472c.mp3str
	savepack: step 5: Storing File: res://music/skater.mp3.import
	savepack: step 5: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-8122c1ec715bcbe34a4661682b54b4c3.s3tc.ctex
	savepack: step 5: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
	savepack: step 5: Storing File: res://bin/~libbiopunk.windows.template_debug.x86_64.dll
	savepack: step 5: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-e909b100dc6bbda0c7e19c5e6c81bef1.s3tc.ctex
	savepack: step 5: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
	savepack: step 6: Storing File: res://bin/libbiopunk.windows.template_debug.x86_64.dll
	savepack: step 6: Storing File: res://bin/libbiopunk.windows.template_release.x86_64.dll
	savepack: step 6: Storing File: res://biopunk.gdextension
	savepack: step 6: Storing File: res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex
	savepack: step 6: Storing File: res://icon.svg.import
	savepack: step 7: Storing File: res://intro_video.ogv
	savepack: step 7: Storing File: res://Skate_Grind.res
	savepack: step 7: Storing File: res://.godot/exported/133200997/export-72ee11ce23100f2096d10891190f557e-dial_up_queen.scn
	savepack: step 7: Storing File: res://.godot/exported/133200997/export-f257e87bfdc9f628dcc382c88547a250-FloodedMall_Greybox.scn
	savepack: step 8: Storing File: res://.godot/exported/133200997/export-d9b46989ff26b563f7686f0a6c74ef08-health_candy_pickup.scn
	savepack: step 8: Storing File: res://.godot/exported/133200997/export-aa3f5c97579d5c748215bbb2e364ddeb-intro.scn
	savepack: step 8: Storing File: res://.godot/exported/133200997/export-ea5c6ad4629af728dc514cefde332394-main_menu.scn
	savepack: step 8: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb-32a6b43d5d45dfc4ede7dd83598e8211.scn
	savepack: step 8: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg-4aa502cd14a84b2c529a8898c302226b.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg-ecf3d6b8aac2645fe97470a1f4e99f00.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg-3a28b97969be2809be74c1a9476bd1c9.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb-100b1b23c136ecaea2b2c2932c21ac1b.scn
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg-57c9bb5b0ae9234c05de81e42f298c6f.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg-2ba7f038ac6d306fa2b8d47c08417ab1.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg-55d7e5261dcedb3df0eddb11b7b87636.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations.glb-e7f241e6428c2b67e04f90f3be56e5af.scn
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations.glb.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg-3cea79246c65c32a532c42ecef570744.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg-cc800615ee86b5e4ee11529ddfdcda9e.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg-8ced58427b3620342c6ab9d1df00a24c.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb-dd2ef507427ee6ecd6de7aea3842d3f1.scn
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg-114f149bb1e7d1877ac3e9ac4b9ffcab.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg-95776f1ad3e7f33ed594f450af85b1ab.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg-b16ad54c8d136d69239c481caeb12679.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d6fdad554547eb106e82adbbc33e252f.scn
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-86710d89420272bd05b7dff2cb7dc19c.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-2c44aaf060978cde46693e50c10062e2.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
	savepack: step 13: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-edd18b21906bbfe2adb2655e252bd46b.s3tc.ctex
	savepack: step 13: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
	savepack: step 13: Storing File: res://.godot/exported/133200997/export-e098924b008c7d9e49d8e825c974b95b-neon_cicada.scn
	savepack: step 13: Storing File: res://.godot/exported/133200997/export-234fb6894ec6226e856ab7f825500d3d-player.scn
	savepack: step 13: Storing File: res://scripts/boss_encounter_trigger.gdc
	savepack: step 14: Storing File: res://scripts/checkpoint.gdc
	savepack: step 14: Storing File: res://scripts/corrupted_kiosk_turret.gdc
	savepack: step 14: Storing File: res://scripts/dial_up_queen.gdc
	savepack: step 14: Storing File: res://scripts/disk_projectile.gdc
	savepack: step 15: Storing File: res://scripts/enemy_model.gdc
	savepack: step 15: Storing File: res://scripts/health_candy_pickup.gdc
	savepack: step 15: Storing File: res://scripts/hud.gdc
	savepack: step 15: Storing File: res://scripts/isometric_camera.gdc
	savepack: step 16: Storing File: res://scripts/mall_greybox_builder.gdc
	savepack: step 16: Storing File: res://scripts/neon_cicada.gdc
	savepack: step 16: Storing File: res://scripts/save_manager.gdc
	savepack: step 16: Storing File: res://scripts/sludge_roach.gdc
	savepack: step 16: Storing File: res://scripts/turret_mortar.gdc
	savepack: step 17: Storing File: res://scripts/tutorial_director.gdc
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0001.png-b710fbec88935683feaa9ce80bb168b5.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0001.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0002.png-0e5a2de3b5fd5d28ce436b421d055443.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0002.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0003.png-9b15b799a24f9fbfe900e8481215af28.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0003.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0004.png-7a93f1ab1179b0e965dc3faf9d34a601.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0004.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0005.png-a93eefa81d5de8b3df0e3a3ffa5a5a96.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0005.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0006.png-31078175cbbcda22f61172097a8379ef.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0006.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0007.png-5b49c7f21f56fa1f374a7643c4fa7f67.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0007.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0008.png-6d3590e2a1ac045c506836477d5759a0.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0008.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0009.png-14ae05c6400d3b747b38851b3f005a58.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0009.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0010.png-0d358bb0ba4f5b17b4fd2db4c1db63a0.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0010.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0011.png-66f8d32db6bd94489fa6462c63bb9e25.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0011.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0012.png-9af3e2a6a8140f68ca9c52822981ac4f.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0012.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0013.png-2c3132152db14b63df2020e769510265.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0013.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0014.png-9bee12fb872d8c3f8b14f8dc83a2e723.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0014.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0015.png-bf3931a65824eda506dac5cb70f66061.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0015.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0016.png-d5ef184284aa8dfbfa436acbd30ff617.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0016.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0017.png-95408049edb1e06eeca6a0623d844741.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0017.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0018.png-04ff2164a4e8823a45d760cb0f8c924c.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0018.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0019.png-bdf2ece8fc4b7d7339b68d8e3078e42d.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0019.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0020.png-5dafb0540cece6243250ba9fe2abcf9d.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0020.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0021.png-26b13f13a12aab931dc5a165ba2449d7.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0021.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0022.png-b7a7bcfe420d7715d19a0ab6614317de.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0022.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0023.png-323c1720fd734f8d4c3011866b334eaf.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0023.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0024.png-d2c8f2e1d387e065f473c9c433f9ddb7.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0024.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0025.png-1c40f3a80700734d053d96815854dfc0.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0025.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0026.png-c19f0c040198da8b7f9ee5df795757c2.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0026.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0027.png-ea9f0ee81748d1e693a28067922f5d2e.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0027.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0028.png-e24290a9e623664b03ab27acfb2650df.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0028.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0029.png-a3c0a06ce660b5e7c165b81610c54676.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0029.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0030.png-f6c9eac873d6fd0dbdc288b0fb569357.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0030.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0031.png-310e4fd4a08c8100e154b74c903283b5.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0031.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0032.png-f278b23644ae1ce5327c8b2c0b039452.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0032.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0033.png-cdb93ffb1ecb703add4499597912f067.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0033.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0034.png-fe43b2e0f994d038860628fea7c4f1d5.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0034.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0035.png-f4fa13aed07d11601dfd153b5d5242bf.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0035.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0036.png-bffcb23fb884cd6d25a3ac3a0412b507.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0036.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0037.png-68914dedfaad711accc4409744a56e4d.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0037.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0038.png-1dab661763c48455fedaf2e96dd5a07a.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0038.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0039.png-7032a0cb4ab60b64402bf0c907e4ca54.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0039.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0040.png-302ba8cb31466cb6ea3dc8dc997b3c57.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0040.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0041.png-2c61cdb0875d6e6575cbc0df76d37a17.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0041.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_0_0042.png-6659fdb2494734652654c028ea5087fc.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_0_0042.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_0_0043.png-0c7e915e718028acacfedaad679e0227.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_0_0043.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_0_0044.png-01e3e2dc516f2dcdf7b4aa7a81620deb.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_0_0044.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_0_0045.png-2c2a1680b70e12826afc1b2b3b9e29b7.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_0_0045.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_1_0001.png-bdb495a9757bdad6797f07eb8555971a.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_1_0001.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0002.png-934840a768165d77186589af676f8a4e.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0002.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0003.png-050f68e9fff75da7614b94ff90773eed.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0003.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0004.png-ebd21421acf611af84f966b5091ce26b.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0004.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0005.png-555a0784cf791c3641ccbc1c5990fb87.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0005.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0006.png-ca0673a91afce76bf8874c74463838f1.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0006.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0007.png-1214b7a104d06df3c3d497bcd1be1834.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0007.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0008.png-f8a89ef405120ae9a8bf879e19cdfa97.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0008.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0009.png-5dcfbd387d83e1ba7227231c891d949a.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0009.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0010.png-f87d76a8175e6446982bab4d7d54ea61.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0010.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0011.png-0337dba63b70dc413b74a06679b6f28c.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0011.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0012.png-03f5f787850b85bee05c351073002118.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0012.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0013.png-b30021586e7c63704890c71eb3a782d9.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0013.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0014.png-1564734f8bb6b3ba6603a743ca7f2575.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0014.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0015.png-e710f55eee5b4c83238640df6bd82846.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0015.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0016.png-0b030e77519508ff1c669f94a1909f94.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0016.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0017.png-e82a6bdd5771e6423a06a0f7342f6e3b.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0017.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0018.png-522091f455426a018d858f5e03c2ab2e.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0018.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0019.png-58201ff8f09e92ec1da1b349fe68db5b.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0019.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0020.png-594e00db2708c2beb29bc93b558dacc3.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0020.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0021.png-074a2e39d733763b37f5b5023df8dfa2.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0021.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0022.png-b8945aba745c3588278faeaf7e1419d4.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0022.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0023.png-5574c663a5fd93f4f03c7eb49828e01a.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0023.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0024.png-60b1a3cd41d1449cc00f64ac3a3f2024.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0024.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0025.png-fb4f2085498167f038dea4b9ec1c2279.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0025.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0026.png-3265acf35ac991ca8f99d9158ac0c1ec.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0026.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0027.png-3418243241bb87f5dc647a772a0efb43.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0027.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0028.png-ee04ca2d0c1aec65325fa925b01c7b1f.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0028.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0029.png-b38794b7bc2ffad1ed4ba99b92cc7227.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0029.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0030.png-671d0253c720699f7c3aa085a63e2a5b.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0030.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0031.png-89b3713d6f7838cee10dd042401d3fad.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0031.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0032.png-2593f66ac31520f96e7fa30959a43e91.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0032.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0033.png-f661de841ee888883396bbe72741b344.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0033.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0034.png-dec28c10562b756dfd86ca58b3e77c40.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0034.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0035.png-1ce258d5745a5fe65a0fd18bfe165fff.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0035.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0036.png-8b7624a493e1a0760ebb2d1f085a37d6.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0036.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0037.png-41f34d23b8fa74a0072956b37088e759.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0037.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0038.png-55a78398a9df364419def19f4ce95af0.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0038.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0039.png-e7a80ce8f9a02fe1310fe47958fd1d41.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0039.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0040.png-b787b560ded3a9fa62bdd1b77723786c.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0040.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0041.png-9690a7eae3341348c1f95f5602be05aa.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0041.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0042.png-7ebe60fb7dda624362b76375368134dd.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0042.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0043.png-7d23a42240b59f04fe4b48547e8f6da9.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0043.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0044.png-0a5dc74966e7dc5eab92fdf6420ea36a.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0044.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_1_0045.png-612dd05ef6ba543963834c97608a32a8.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_1_0045.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0001.png-5edef45f93b3c30215829a5f4ee539a5.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0001.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0002.png-0dc81ff8f64a189a3b647d52dfacf8ea.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0002.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0003.png-8a0453cc9f955415e5f82c386c9ca46c.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0003.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0004.png-9ae7dde74db7dd14c7cbe87d30c66b68.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0004.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0005.png-6f55b2b9c644ef31b21e0dcd11b57ec2.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0005.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0006.png-2e676cddde54f2d6eb922c7069f62736.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0006.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0007.png-9474866534e92b9a05921a6d4857067d.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0007.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0008.png-824cc4850c09bfcbd2d1b0035a43e067.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0008.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0009.png-2e18df9058df064f6724510b64e7ba78.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0009.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0010.png-e4b40f869b92e6e9cd7307dc8d05489b.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0010.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0011.png-3aa009aa9fd5f1d11df53c6ac2f5b5df.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0011.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0012.png-7c170912d4a612a69a3c4e695f111c5f.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0012.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0013.png-bc3e7baa32067d83335a4e95cf4b741c.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0013.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0014.png-3722562c1d091de2a0b91e5cd8349db5.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0014.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0015.png-f464949052b0da7f6a17637e4b1661f6.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0015.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0016.png-4843269e6dc01a3544a9e4d926e1241a.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0016.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0017.png-ff620210c514d0a21957038f3916bd14.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0017.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0018.png-b36d4042dc59a8aaed3ffdceb402e501.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0018.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0019.png-e052941f9a25252589d938aa2627df8a.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0019.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0020.png-6268e8691232161d7624dcca11583e41.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0020.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0021.png-ed3d2424d7120473fbbadc074f4efd14.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0021.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0022.png-51a6f3b3e77c867242bc342972c33180.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0022.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0023.png-3e6859d04911c957f9489557b78b06cc.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0023.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0024.png-282d8d17bae6c8654d89674f1c32a197.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0024.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0025.png-ca5226424597c3ac543f265056272ac8.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0025.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0026.png-9e0d7fbc5fea747e938f546d364ee7ba.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0026.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0027.png-bc33f42a80a11ec8fe49ef20a0661a9a.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0027.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0028.png-25176d6154401916dcaa077304511057.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0028.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0029.png-49975c5c6af211692c84f9679331e1f3.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0029.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0030.png-56de73700cd6f6aa2936077195517479.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0030.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0031.png-52aac777105c1cd8f0b3ec0db04482d7.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0031.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0032.png-ff3d7f88100e92134cab2e7ccc4fd01b.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0032.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0033.png-e6d5817fff0854bd1857b949c443d2c7.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0033.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0034.png-5a8afc03d617da4ff4b9f6a9ee630db8.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0034.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0035.png-aacef661a413cdac61ab7b4b2347df30.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0035.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0036.png-66afe91228cbd5490fa49e5ea2f0335b.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0036.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0037.png-1d3c68ac96e6cf31b172295b3de067b5.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0037.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_2_0038.png-ee2ee22a14ff22dfd3b5a6cde164af77.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_2_0038.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_2_0039.png-1060b4ca444a509a181dc11dc97444ec.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_2_0039.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_2_0040.png-fd2865b617e7b9d89d3e9766db0a3840.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_2_0040.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_2_0041.png-c97812285731470074b9c9e300ef9e65.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_2_0041.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_2_0042.png-0c39dcba0311b68852dba1f724f4be04.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_2_0042.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_2_0043.png-bfd2ba0016b2bdec0825f788a31ea897.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_2_0043.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_2_0044.png-97f3b7371f5b1724ee7d68221d6b1912.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_2_0044.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_2_0045.png-11acbd16bb764485e7ae2275107db149.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_2_0045.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_3_0001.png-31fc37a9e42930004808f030423fd577.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_3_0001.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0002.png-7c1bc4aeb3ff35b537bb53998bf69bab.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0002.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0003.png-5bf3295a4d9b8284bd0ac673a6309a08.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0003.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0004.png-5592b0dbe01a20f12ec8618b369c6f52.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0004.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0005.png-3c1230e43d81597f80567d873c55db13.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0005.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0006.png-45e84080bfd6afaaa0955b9cd46ff09d.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0006.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0007.png-8e3503f7074ae3023a0b9b132650b22a.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0007.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0008.png-26f083538118f1e8b42106e2f6372be2.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0008.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0009.png-10dbc8517bbc031463f3ae77296f97ad.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0009.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0010.png-08298348522f60379afec88de95bb2b7.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0010.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0011.png-5a0bfc0660596d00b1cb8b891fb6fa10.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0011.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0012.png-ed0ac74b550525819c05e15a362549ef.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0012.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0013.png-4c02174a68c2dba29376b8c908786c25.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0013.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0014.png-13ebdda30cc330123a5790ca2a2555f0.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0014.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0015.png-5fbdce781159aadc35349c5a3bebb91e.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0015.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0016.png-e9d305e258e9afd8f205c0cac9fc78c3.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0016.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0017.png-d763659027a5da4cea16ec4fe382345e.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0017.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0018.png-d82463317106aa660a52a7533094d673.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0018.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0019.png-eaa1ae0ed50e2f4d68476dbcaa8962e7.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0019.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0020.png-62f9861f6e2cd96510d4f56c3f351d4b.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0020.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0021.png-5e787d913618906013f43632d4e23f11.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0021.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0022.png-4eb98c30c1306ecd14123de3db43457c.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0022.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0023.png-2ff3ddbdaf2d9b3685fdc173624c3912.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0023.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0024.png-b1dbed21965ad7787031e26dc7960277.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0024.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0025.png-17d0c92b90940d326db4bb0a82b3d7a5.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0025.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0026.png-63facc91904dbd66f32b0a101dc9318d.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0026.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0027.png-af9d4619028fe1327bae6f2acd8f4601.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0027.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0028.png-a10c2fc2c81e56539c59dc1ee413394c.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0028.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0029.png-daf87e63081f9c0a54447006bd2209b6.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0029.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0030.png-e0daaf8466b78886ee3c4d6a13c77a88.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0030.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0031.png-79dd733b6f4796896ee4754093cbf574.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0031.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0032.png-673d415399e336f57767622876a059cc.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0032.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0033.png-351ed26bf049f1c9f5b8f63b48fdc540.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0033.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0034.png-bf45ccd5b8ecb2498520ba55ea8fca90.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0034.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0035.png-4129cce2cdd07ba02d5c20ca4c246a11.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0035.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_3_0036.png-abf04b2b00fe88fdd23ad0bea5df2f99.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_3_0036.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_3_0037.png-751d3c8b75838e4c057b69baa189a6fb.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_3_0037.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_3_0038.png-8a31cb5390a0d5e3a37469e403fc9ea0.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_3_0038.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_3_0039.png-360cb8e786195be9e7dfb3c3a41fae55.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_3_0039.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_3_0040.png-4668837ad40cd17338f2a3a499a99944.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_3_0040.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_3_0041.png-4ede56ee72e588a4885b2b8d46d20b13.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_3_0041.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_3_0042.png-3f2669e912059103f59dd7cbdf921b09.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_3_0042.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_3_0043.png-cf5aae44be164daae0adafb255e53c3a.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_3_0043.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_3_0044.png-8171ad75fd9c98d5eb123b4fcc2fe1d0.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_3_0044.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_3_0045.png-739fee3a1c4268b262bce228f3c25540.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_3_0045.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0001.png-44c0140589c9477c53e693ca422a610f.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0001.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0002.png-03e83ca13844bf120ff9f33592cabb55.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0002.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0003.png-5a067b1ce8c2abce9d265d1085006aa2.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0003.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0004.png-3e737cb0da6ac2bbf67f17e9de4541da.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0004.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0005.png-50ca1e2ace0ad812aa8e4658e5fbc49b.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0005.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0006.png-cbaebc60f655a63514a9ee42bbe601a8.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0006.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0007.png-9b4fde0a646fd92a84a198f3308e7f9c.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0007.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0008.png-914cc8543e9f50ced206fb184b891a30.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0008.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0009.png-f906857f39f7c9499bf866179301a8fa.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0009.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0010.png-e5aea61231082aa35a21f40f2712ec09.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0010.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0011.png-046e49dffaa400aa7376d9ab1b6427b9.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0011.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0012.png-fd1244d2744d4afcec69891ea22bf3ef.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0012.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0013.png-7b2b287a5acb0f329ec30bd468e72c1b.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0013.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0014.png-a86ccdbf773101b21bcc3797b678b648.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0014.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0015.png-b58405815ea0731a85856890e866e793.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0015.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0016.png-81e83a46d052604fb757f7c0412bfeb0.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0016.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0017.png-39333cb64f3c2877e9b4b20f86f02771.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0017.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0018.png-4003cb82bd9d789910f6f8d31a8bec48.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0018.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0019.png-dead4a6a63153cb0b9b7931f5ae678ed.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0019.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0020.png-71b2b2ce20e8fbab8b36a7ca71ba801c.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0020.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0021.png-ec51ee3073d172fbdb1752fe73b64753.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0021.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0022.png-c9d441a84209b2fd15a00faa56fb1251.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0022.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0023.png-2ce81c611a182118a20d5505faf43e96.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0023.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0024.png-8de87e72e639b46d062c45e528d5ca76.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0024.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0025.png-0c9d69a0d7dd65f8c19b5d14c8c9e938.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0025.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0026.png-b4078c194745d66f3f8b16c33db101ba.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0026.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0027.png-a0e8070b2a4b990a2fa3970d09ed07df.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0027.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0028.png-81d472d161be45c7797b5fbf138424a3.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0028.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0029.png-89b8cb45ca54fce7e0b0a4345dd77e09.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0029.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0030.png-a4ea7e588e4207342eab45b6bece9b09.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0030.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0031.png-56f62fd7bf021bdf915f7a99d49c25d4.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0031.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0032.png-a02734f8bdb2a9ad41fa7f5b015afc87.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0032.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0033.png-6d81174d22f2c4d14bcd6a92aedafe5c.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0033.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_4_0034.png-65e08bf7b6548c7094aa67e59f0be8be.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_4_0034.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_4_0035.png-be32669bf98db3b34e6df6590b21a192.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_4_0035.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_4_0036.png-0d1a5b53a63e57bd8542ccb7f3bb3f64.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_4_0036.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_4_0037.png-f3e55a4dc2b84a975bbdeb291c52bf65.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_4_0037.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_4_0038.png-4a5bd9cfd14b5deedd060279575f5aef.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_4_0038.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_4_0039.png-c90075c8d1b9a00ed5bb2713007533a9.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_4_0039.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_4_0040.png-1bb4300271bd8cde60ac4bf231cad3f8.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_4_0040.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_4_0041.png-24f218bb887697ebff8afbc939c66102.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_4_0041.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_4_0042.png-32f0cb46cb07386daf5336ede400072f.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_4_0042.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_4_0043.png-c29414dfe98a0fffa05aa08c80b5a047.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_4_0043.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_4_0044.png-267944e3e6bc3dffcd6632d486270177.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_4_0044.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_4_0045.png-7d4f63980d87410e0f5f75d6fcd7980f.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_4_0045.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_5_0001.png-54ecb67a3b64ef53b95f38cfcaab5d7e.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_5_0001.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0002.png-4be9ff92bf6613ac5f0532ee594c9f8d.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0002.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0003.png-02ae3ecccec6854388104446a5cce060.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0003.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0004.png-78f400ba5159020d0cc327fb7751626b.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0004.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0005.png-a61599f3a6912253a4ee8a46f2179ee0.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0005.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0006.png-a7a9166dcc80e53082039570e987d60e.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0006.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0007.png-97719fa861936e98f05b1c47c7437edb.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0007.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0008.png-bfa0a41e9582b4220810342faa17048b.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0008.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0009.png-222b7f2c0ba311d0eb36c49e18d4fac0.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0009.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0010.png-a0a53aaa4f0d1e1d0b151c9561284562.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0010.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0011.png-718b2daecc82a6b8e27bafe5e48aeeda.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0011.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0012.png-0165b583c3cf87032ff35631b2e3e95a.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0012.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0013.png-838fe2b9da91889799d90ec54c4cc969.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0013.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0014.png-d8663fd1c9ebf299c93e7dc67e26f95f.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0014.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0015.png-2100f509d345cd07461664ab3eaa81dd.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0015.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0016.png-226901d9b28cf7df2decd0451326d75c.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0016.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0017.png-dfd5420cd9b200935c84bf0f4cac4ab0.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0017.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0018.png-aa2e5c55ce7ff835a3ea1c42d9837741.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0018.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0019.png-a943751b68884dfc46fbb0c2c0d5178b.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0019.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0020.png-3584c763a7727de0c392a8c618354c88.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0020.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0021.png-79793cf9cbb8fe9c5c92a8a8c186c165.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0021.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0022.png-ea8d8f9eacfcc6ad60cf0eac8f76bb2d.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0022.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0023.png-f2938d845123450a87fd6be27d904951.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0023.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0024.png-a231cbffffd158111eb4a45e6c9494ab.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0024.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0025.png-fe9f38a76a4fcb7b388729392facaaf2.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0025.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0026.png-e8934ff24161fe66919d3f09ded05027.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0026.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0027.png-26da75d75afe8b79255c43e3d8e08e98.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0027.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0028.png-d694010607039d58c26ddbd9f48585be.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0028.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0029.png-800bbbc0a1f0dae81fe7ae5f7e27f370.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0029.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0030.png-7b64c82c5a0463a9b47161a4935e60ce.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0030.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0031.png-acfc1df8e7d5e6d193dfc8220f1db0ee.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0031.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0032.png-423371a1636bc3f76ff44be178654e40.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0032.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0033.png-78216bae1d9c00088dcc3233e62ca4db.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0033.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0034.png-34a0b317ec360b1b06a2262b63ffae14.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0034.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0035.png-62cf4a4fa40fc11ae23842db81261d48.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0035.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_5_0036.png-38c419c3886c9f73785214229b1e5e8a.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_5_0036.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_5_0037.png-70052c6484a98cf0e42ae14e7c15da95.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_5_0037.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_5_0038.png-c0bf8c173fa4868b88096fb5ef6cd786.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_5_0038.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_5_0039.png-976536a45ab5477c7df7d1c99b776380.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_5_0039.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_5_0040.png-ba9bce1718013b82ef4d19d9b0f1c763.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_5_0040.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_5_0041.png-46f91cd851a5f818c5a02091783f1be4.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_5_0041.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_5_0042.png-02de82baf6bddc7ed4ba0f7cb97fcc55.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_5_0042.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_5_0043.png-c35a6a6a429dcfc7d718438169e5de18.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_5_0043.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_5_0044.png-ce3e123d0b3626a753b875112d502854.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_5_0044.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_5_0045.png-6852b5c6ea7d3ebfd8e76ca923623c0e.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_5_0045.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0001.png-305ad0570c16badf494841e57f4ba611.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0001.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0002.png-22826ad2b1480d94ac49569140300b7d.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0002.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0003.png-2ddfab84d846eea12800d2ae3258d124.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0003.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0004.png-198bf0b806aed2f6d3c931a62777c72b.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0004.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0005.png-2843d807360986b608946b90e888010b.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0005.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0006.png-3e9d956ac832e00cd3c5c5e88b3ed985.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0006.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0007.png-5d37f95317537321949f3aa1b3bdaec5.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0007.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0008.png-5e47c714d8975acee8a61f03c7e1c8a8.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0008.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0009.png-a5ff6975ef9d035dc44e9369a7633b7b.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0009.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0010.png-18fefd47204b86c43402b80449215e5d.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0010.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0011.png-403f81f4712d87a6fc7bc293abfe951c.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0011.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0012.png-7a43de7f34962670014e2fa8cf58bdbd.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0012.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0013.png-6997758c5a879c6dfebd9bf83fb80b19.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0013.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0014.png-cded909ae25b702d64c05cd7ae0d2f13.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0014.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0015.png-66aeb5bd0bc542fc175fec55a3bf6087.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0015.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0016.png-b938bf7a70c22eb9d70fcaf577311100.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0016.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0017.png-176b7f93ffdda965c54bdd0eb9326d9b.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0017.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0018.png-f92b96743b8714dcbaf521b80eafbf3f.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0018.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0019.png-5761e61793846e110d7703fd46cae4d4.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0019.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0020.png-8a75df3dc801931a2f4c8ace65113319.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0020.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0021.png-9a33865f02a031907cbfe0e27fd35f00.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0021.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0022.png-3e67df7c6e0a065b498d39b0c08b0312.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0022.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0023.png-7f64aa280564aebe45e5dc0d8d9d5c16.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0023.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0024.png-88f09f26e628d7d315ce59732ccc2834.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0024.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0025.png-0b3af2fa1d2cbbfd99d4ee002fb12840.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0025.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0026.png-021f4a1a723c8d54576610d04d7fd57f.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0026.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0027.png-44e3d8b5ff0f346c8104b4032f560f71.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0027.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0028.png-1105d75f85506ccc5746fbd864b24fff.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0028.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0029.png-e4b4caed37291002953d56f4ca4131ab.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0029.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0030.png-61625df132dbbd128d4e1f75e75aabfc.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0030.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0031.png-d749cc2494f059267e4e7df5116e8622.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0031.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0032.png-71a30f79d5da9c1b438f22b398b5dab1.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0032.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0033.png-1581d03ab3875a38a17e89ed97f9e4b7.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0033.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_6_0034.png-901410a3b9a1123e4fe9c6c067e84996.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_6_0034.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_6_0035.png-0ca73a5099e5ee470642737d3d349212.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_6_0035.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_6_0036.png-74212616df9d8d718bb761f75646bcc1.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_6_0036.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_6_0037.png-b8f3cd7f00d11e1738def20ba138ad31.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_6_0037.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_6_0038.png-de4b8fd9a432a6d0cb6d62a70779f107.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_6_0038.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_6_0039.png-30fe4a5d0248c94f51c386de6818aab0.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_6_0039.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_6_0040.png-01c5d066ea63da2b2939414aab6b7897.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_6_0040.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_6_0041.png-36d9495a377e03e36d424fd98695a054.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_6_0041.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_6_0042.png-0d3be26f076a11fe04aa48150607f766.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_6_0042.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_6_0043.png-b9f2da0ea4ca216970722097f128bbd1.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_6_0043.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_6_0044.png-3f84695fc07f7b738486280eb5603000.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_6_0044.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_6_0045.png-deb75272ecbeaf94c9d8a660d7c0ac85.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_6_0045.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0001.png-f56163f66408f9b4868c963b7ccdc888.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0001.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0002.png-c0fe11e0a41fb3e172cad384ea0d6fdb.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0002.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0003.png-80353ff236d3b9e9529d95b234901c2f.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0003.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0004.png-f17b8c72db6c5a5555c1e058a4fdb37d.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0004.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0005.png-9b495c651b85e4394c7278ed9117f507.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0005.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0006.png-b55337d24f1991722d24974127890164.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0006.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0007.png-3f74fdb57cdfb5cf92632111c7c47353.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0007.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0008.png-14fff645fc469a9ca37da44571c8bf40.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0008.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0009.png-44a989bb4ef8aec21b41ccf787b8ad79.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0009.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0010.png-f8b6efa1bc0fdde4984d18d79ab2b87a.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0010.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0011.png-8d079e563451cb648d05f12fcd83410e.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0011.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0012.png-c481686c32eb52fd6fd4412c6d7b4b4e.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0012.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0013.png-230ea27940975966523df263c58504ff.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0013.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0014.png-cd9b475b011d51a12b5035e2f55c89a4.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0014.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0015.png-6462d0a0c363f5a418682bbd99cfee9f.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0015.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0016.png-1e525788b0aecb2c77f9c99b2c6e7961.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0016.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0017.png-fc1fb54f89a66e7672a3dea4977bf5dd.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0017.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0018.png-ab4b697f5439f7562d6495d6ca1b21c2.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0018.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0019.png-d6adf250f69ca718c20f2b6f1e1dab8b.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0019.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0020.png-13e81bed771a378dd92fe3e44a5dcae9.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0020.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0021.png-95025a26723093c478b81f9159680c72.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0021.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0022.png-7119dbcacfdc1fbeea0a4908fde2ad4c.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0022.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0023.png-42911aed0fd1e7b00c59d14e1d3bd2ec.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0023.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0024.png-cd0313892fa0271db3530d704b558c3a.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0024.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0025.png-e837b778cf6654dccb6e1c3cac343e06.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0025.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0026.png-c14e9001cf3dbffbd89121685a29876b.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0026.png.import
	savepack: step 97: Storing File: res://.godot/imported/dir_7_0027.png-410a93b758978f6107af16ca2265aaca.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/dir_7_0027.png.import
	savepack: step 97: Storing File: res://.godot/imported/dir_7_0028.png-f441389b1b2984eba015ff3018824976.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/dir_7_0028.png.import
	savepack: step 97: Storing File: res://.godot/imported/dir_7_0029.png-37b4c07a4c3f14a34495ee55687869f8.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/dir_7_0029.png.import
	savepack: step 97: Storing File: res://.godot/imported/dir_7_0030.png-ef549d8584817425a792f64d53b357de.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/dir_7_0030.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0031.png-368fd541b5b5219ce5724ebf77b504e3.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0031.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0032.png-5862cafb570810c768df0659dbd21c86.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0032.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0033.png-04b92d5998216baaca5ce78bc7e2b0ab.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0033.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0034.png-f360fbba45604b91d35ca2106e17547f.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0034.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0035.png-ab41dcabc7044bd63709f874ba63d42f.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0035.png.import
	savepack: step 99: Storing File: res://.godot/imported/dir_7_0036.png-e59c70a78b8e861cb280f41a3eb39067.ctex
	savepack: step 99: Storing File: res://sprites/player_idle/dir_7_0036.png.import
	savepack: step 99: Storing File: res://.godot/imported/dir_7_0037.png-ac4072e6541b8df202a43dea56e7cd67.ctex
	savepack: step 99: Storing File: res://sprites/player_idle/dir_7_0037.png.import
	savepack: step 99: Storing File: res://.godot/imported/dir_7_0038.png-42cd164980ead0a5b2376797057244a2.ctex
	savepack: step 99: Storing File: res://sprites/player_idle/dir_7_0038.png.import
	savepack: step 99: Storing File: res://.godot/imported/dir_7_0039.png-7c2343a6c86942135313d0c4bc4f414e.ctex
	savepack: step 99: Storing File: res://sprites/player_idle/dir_7_0039.png.import
	savepack: step 100: Storing File: res://.godot/imported/dir_7_0040.png-5312afda3741127ce8a70bfb88de9549.ctex
	savepack: step 100: Storing File: res://sprites/player_idle/dir_7_0040.png.import
	savepack: step 100: Storing File: res://.godot/imported/dir_7_0041.png-9b4ca50bea3cbd33520b6451fc976146.ctex
	savepack: step 100: Storing File: res://sprites/player_idle/dir_7_0041.png.import
	savepack: step 100: Storing File: res://.godot/imported/dir_7_0042.png-435fab965479c665ead6209978a0e5fc.ctex
	savepack: step 100: Storing File: res://sprites/player_idle/dir_7_0042.png.import
	savepack: step 100: Storing File: res://.godot/imported/dir_7_0043.png-5bf45588c7753e97799660453a66348f.ctex
	savepack: step 100: Storing File: res://sprites/player_idle/dir_7_0043.png.import
	savepack: step 101: Storing File: res://.godot/imported/dir_7_0044.png-e710ee96e2dd522844ed77edfeac0918.ctex
	savepack: step 101: Storing File: res://sprites/player_idle/dir_7_0044.png.import
	savepack: step 101: Storing File: res://.godot/imported/dir_7_0045.png-9b82aafad83a15cdf5250f678768e4c3.ctex
	savepack: step 101: Storing File: res://sprites/player_idle/dir_7_0045.png.import
	savepack: step 101: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d386ad401674f18d1edfd264d67ce020.scn
	savepack: step 101: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
	savepack: step 101: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-8f735e678b86df73bf8978d10c629e6f.s3tc.ctex
	savepack: step 101: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
	savepack: step 101: Storing File: res://scenes/dial_up_queen.tscn.remap
	savepack: step 101: Storing File: res://scenes/FloodedMall_Greybox.tscn.remap
	savepack: step 101: Storing File: res://scenes/health_candy_pickup.tscn.remap
	savepack: step 101: Storing File: res://scenes/intro.tscn.remap
	savepack: step 101: Storing File: res://scenes/main_menu.tscn.remap
	savepack: step 101: Storing File: res://scenes/neon_cicada.tscn.remap
	savepack: step 101: Storing File: res://scenes/player.tscn.remap
	savepack: step 101: Storing File: res://scripts/boss_encounter_trigger.gd.remap
	savepack: step 101: Storing File: res://scripts/checkpoint.gd.remap
	savepack: step 101: Storing File: res://scripts/corrupted_kiosk_turret.gd.remap
	savepack: step 101: Storing File: res://scripts/dial_up_queen.gd.remap
	savepack: step 101: Storing File: res://scripts/disk_projectile.gd.remap
	savepack: step 101: Storing File: res://scripts/enemy_model.gd.remap
	savepack: step 101: Storing File: res://scripts/health_candy_pickup.gd.remap
	savepack: step 101: Storing File: res://scripts/hud.gd.remap
	savepack: step 101: Storing File: res://scripts/isometric_camera.gd.remap
	savepack: step 101: Storing File: res://scripts/mall_greybox_builder.gd.remap
	savepack: step 101: Storing File: res://scripts/neon_cicada.gd.remap
	savepack: step 101: Storing File: res://scripts/save_manager.gd.remap
	savepack: step 101: Storing File: res://scripts/sludge_roach.gd.remap
	savepack: step 101: Storing File: res://scripts/turret_mortar.gd.remap
	savepack: step 101: Storing File: res://scripts/tutorial_director.gd.remap
	savepack: step 101: Storing File: res://.godot/global_script_class_cache.cfg
	savepack: step 101: Storing File: res://icon.svg
	savepack: step 101: Storing File: res://.godot/uid_cache.bin
	savepack: step 101: Storing File: res://.godot/extension_list.cfg
	savepack: step 101: Storing File: res://project.binary
savepack: end
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)

EXIT: 0 (release)
BUILD: FAIL - release failed; see C:\y2k-biopunk-rpg\.worktrees\vs11export\ops\runs\export\build_20261008_133608

```

Script exit code: `1`.

## Intermediate build before temporary-DLL exclusion (exit 0)

Command from the assigned worktree:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops/tools/build_release.ps1
```

Complete stdout/stderr captured with `*> ops/runs/export/build_release.final.full.log` (line endings normalized for Markdown):

```text
Worktree: C:\y2k-biopunk-rpg\.worktrees\vs11export
Logs: C:\y2k-biopunk-rpg\.worktrees\vs11export\ops\runs\export\build_20261008_133648
Release DLL is current; skipping SCons.
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\Godot_v4.3-stable_win64.exe --headless --path "C:\y2k-biopunk-rpg\.worktrees\vs11export" --import
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org


EXIT: 0 (import)
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\Godot_v4.3-stable_win64.exe --headless --path "C:\y2k-biopunk-rpg\.worktrees\vs11export" --export-release "Windows Desktop" build/release/Y2K-BioPunk.exe
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

savepack: begin: Packing steps: 102
	savepack: step 2: Storing File: res://.godot/imported/dial_up_queen.glb-c1a5cb2f8ad5373c4dcab5634b6375c1.scn
	savepack: step 2: Storing File: res://assets/models/dial_up_queen.glb.import
	savepack: step 2: Storing File: res://.godot/imported/fountain_sculpture.glb-a0ab240fe62ced988ba9a52de635ff8f.scn
	savepack: step 2: Storing File: res://assets/models/fountain_sculpture.glb.import
	savepack: step 2: Storing File: res://.godot/imported/kiosk_turret.glb-21d18cfe5e39c287914cfac610d69389.scn
	savepack: step 2: Storing File: res://assets/models/kiosk_turret.glb.import
	savepack: step 2: Storing File: res://.godot/imported/mall_kiosk.glb-ef7ad498f3da947c3b5d733a4903be11.scn
	savepack: step 2: Storing File: res://assets/models/mall_kiosk.glb.import
	savepack: step 2: Storing File: res://.godot/imported/mall_planter.glb-f1515752ded96a398eafbdc994b6e669.scn
	savepack: step 2: Storing File: res://assets/models/mall_planter.glb.import
	savepack: step 3: Storing File: res://.godot/imported/neon_cicada.glb-c075b36b4e093e1d35265564e67f028c.scn
	savepack: step 3: Storing File: res://assets/models/neon_cicada.glb.import
	savepack: step 3: Storing File: res://.godot/imported/sludge_roach.glb-1ae35041ab2d79767ebaf70f00e6243f.scn
	savepack: step 3: Storing File: res://assets/models/sludge_roach.glb.import
	savepack: step 3: Storing File: res://.godot/imported/anthem.mp3-2f7a92cf245df82890b7830193e2bea6.mp3str
	savepack: step 3: Storing File: res://music/anthem.mp3.import
	savepack: step 3: Storing File: res://.godot/imported/bigbeat.mp3-719a317dfac214297f4d640840ee7874.mp3str
	savepack: step 3: Storing File: res://music/bigbeat.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/bubblegum.mp3-6600d7a64ddbbec66a2b18480a79e0ad.mp3str
	savepack: step 4: Storing File: res://music/bubblegum.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/combat.mp3-1829eebac0ee46487ae84a3be83a352e.mp3str
	savepack: step 4: Storing File: res://music/combat.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/eurodance.mp3-fef95430f66d8053d0220ef34137fda9.mp3str
	savepack: step 4: Storing File: res://music/eurodance.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/hiphop.mp3-3d4b4945f60e4d0cddde31e8acbf2438.mp3str
	savepack: step 4: Storing File: res://music/hiphop.mp3.import
	savepack: step 5: Storing File: res://.godot/imported/numetal.mp3-058dd4db2f01f0c63415579f555fa23f.mp3str
	savepack: step 5: Storing File: res://music/numetal.mp3.import
	savepack: step 5: Storing File: res://.godot/imported/skater.mp3-47c0b3f6a66951ef919ba1b8e36e472c.mp3str
	savepack: step 5: Storing File: res://music/skater.mp3.import
	savepack: step 5: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-8122c1ec715bcbe34a4661682b54b4c3.s3tc.ctex
	savepack: step 5: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
	savepack: step 5: Storing File: res://bin/~libbiopunk.windows.template_debug.x86_64.dll
	savepack: step 5: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-e909b100dc6bbda0c7e19c5e6c81bef1.s3tc.ctex
	savepack: step 5: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
	savepack: step 6: Storing File: res://bin/libbiopunk.windows.template_debug.x86_64.dll
	savepack: step 6: Storing File: res://bin/libbiopunk.windows.template_release.x86_64.dll
	savepack: step 6: Storing File: res://biopunk.gdextension
	savepack: step 6: Storing File: res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex
	savepack: step 6: Storing File: res://icon.svg.import
	savepack: step 7: Storing File: res://intro_video.ogv
	savepack: step 7: Storing File: res://Skate_Grind.res
	savepack: step 7: Storing File: res://.godot/exported/133200997/export-72ee11ce23100f2096d10891190f557e-dial_up_queen.scn
	savepack: step 7: Storing File: res://.godot/exported/133200997/export-f257e87bfdc9f628dcc382c88547a250-FloodedMall_Greybox.scn
	savepack: step 8: Storing File: res://.godot/exported/133200997/export-d9b46989ff26b563f7686f0a6c74ef08-health_candy_pickup.scn
	savepack: step 8: Storing File: res://.godot/exported/133200997/export-aa3f5c97579d5c748215bbb2e364ddeb-intro.scn
	savepack: step 8: Storing File: res://.godot/exported/133200997/export-ea5c6ad4629af728dc514cefde332394-main_menu.scn
	savepack: step 8: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb-32a6b43d5d45dfc4ede7dd83598e8211.scn
	savepack: step 8: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg-4aa502cd14a84b2c529a8898c302226b.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg-ecf3d6b8aac2645fe97470a1f4e99f00.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg-3a28b97969be2809be74c1a9476bd1c9.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb-100b1b23c136ecaea2b2c2932c21ac1b.scn
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg-57c9bb5b0ae9234c05de81e42f298c6f.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg-2ba7f038ac6d306fa2b8d47c08417ab1.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg-55d7e5261dcedb3df0eddb11b7b87636.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations.glb-e7f241e6428c2b67e04f90f3be56e5af.scn
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations.glb.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg-3cea79246c65c32a532c42ecef570744.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg-cc800615ee86b5e4ee11529ddfdcda9e.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg-8ced58427b3620342c6ab9d1df00a24c.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb-dd2ef507427ee6ecd6de7aea3842d3f1.scn
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg-114f149bb1e7d1877ac3e9ac4b9ffcab.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg-95776f1ad3e7f33ed594f450af85b1ab.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg-b16ad54c8d136d69239c481caeb12679.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d6fdad554547eb106e82adbbc33e252f.scn
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-86710d89420272bd05b7dff2cb7dc19c.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-2c44aaf060978cde46693e50c10062e2.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
	savepack: step 13: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-edd18b21906bbfe2adb2655e252bd46b.s3tc.ctex
	savepack: step 13: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
	savepack: step 13: Storing File: res://.godot/exported/133200997/export-e098924b008c7d9e49d8e825c974b95b-neon_cicada.scn
	savepack: step 13: Storing File: res://.godot/exported/133200997/export-234fb6894ec6226e856ab7f825500d3d-player.scn
	savepack: step 13: Storing File: res://scripts/boss_encounter_trigger.gdc
	savepack: step 14: Storing File: res://scripts/checkpoint.gdc
	savepack: step 14: Storing File: res://scripts/corrupted_kiosk_turret.gdc
	savepack: step 14: Storing File: res://scripts/dial_up_queen.gdc
	savepack: step 14: Storing File: res://scripts/disk_projectile.gdc
	savepack: step 15: Storing File: res://scripts/enemy_model.gdc
	savepack: step 15: Storing File: res://scripts/health_candy_pickup.gdc
	savepack: step 15: Storing File: res://scripts/hud.gdc
	savepack: step 15: Storing File: res://scripts/isometric_camera.gdc
	savepack: step 16: Storing File: res://scripts/mall_greybox_builder.gdc
	savepack: step 16: Storing File: res://scripts/neon_cicada.gdc
	savepack: step 16: Storing File: res://scripts/save_manager.gdc
	savepack: step 16: Storing File: res://scripts/sludge_roach.gdc
	savepack: step 16: Storing File: res://scripts/turret_mortar.gdc
	savepack: step 17: Storing File: res://scripts/tutorial_director.gdc
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0001.png-b710fbec88935683feaa9ce80bb168b5.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0001.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0002.png-0e5a2de3b5fd5d28ce436b421d055443.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0002.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0003.png-9b15b799a24f9fbfe900e8481215af28.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0003.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0004.png-7a93f1ab1179b0e965dc3faf9d34a601.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0004.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0005.png-a93eefa81d5de8b3df0e3a3ffa5a5a96.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0005.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0006.png-31078175cbbcda22f61172097a8379ef.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0006.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0007.png-5b49c7f21f56fa1f374a7643c4fa7f67.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0007.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0008.png-6d3590e2a1ac045c506836477d5759a0.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0008.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0009.png-14ae05c6400d3b747b38851b3f005a58.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0009.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0010.png-0d358bb0ba4f5b17b4fd2db4c1db63a0.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0010.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0011.png-66f8d32db6bd94489fa6462c63bb9e25.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0011.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0012.png-9af3e2a6a8140f68ca9c52822981ac4f.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0012.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0013.png-2c3132152db14b63df2020e769510265.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0013.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0014.png-9bee12fb872d8c3f8b14f8dc83a2e723.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0014.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0015.png-bf3931a65824eda506dac5cb70f66061.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0015.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0016.png-d5ef184284aa8dfbfa436acbd30ff617.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0016.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0017.png-95408049edb1e06eeca6a0623d844741.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0017.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0018.png-04ff2164a4e8823a45d760cb0f8c924c.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0018.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0019.png-bdf2ece8fc4b7d7339b68d8e3078e42d.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0019.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0020.png-5dafb0540cece6243250ba9fe2abcf9d.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0020.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0021.png-26b13f13a12aab931dc5a165ba2449d7.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0021.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0022.png-b7a7bcfe420d7715d19a0ab6614317de.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0022.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0023.png-323c1720fd734f8d4c3011866b334eaf.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0023.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0024.png-d2c8f2e1d387e065f473c9c433f9ddb7.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0024.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0025.png-1c40f3a80700734d053d96815854dfc0.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0025.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0026.png-c19f0c040198da8b7f9ee5df795757c2.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0026.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0027.png-ea9f0ee81748d1e693a28067922f5d2e.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0027.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0028.png-e24290a9e623664b03ab27acfb2650df.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0028.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0029.png-a3c0a06ce660b5e7c165b81610c54676.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0029.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0030.png-f6c9eac873d6fd0dbdc288b0fb569357.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0030.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0031.png-310e4fd4a08c8100e154b74c903283b5.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0031.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0032.png-f278b23644ae1ce5327c8b2c0b039452.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0032.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0033.png-cdb93ffb1ecb703add4499597912f067.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0033.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0034.png-fe43b2e0f994d038860628fea7c4f1d5.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0034.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0035.png-f4fa13aed07d11601dfd153b5d5242bf.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0035.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0036.png-bffcb23fb884cd6d25a3ac3a0412b507.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0036.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0037.png-68914dedfaad711accc4409744a56e4d.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0037.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0038.png-1dab661763c48455fedaf2e96dd5a07a.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0038.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0039.png-7032a0cb4ab60b64402bf0c907e4ca54.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0039.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0040.png-302ba8cb31466cb6ea3dc8dc997b3c57.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0040.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0041.png-2c61cdb0875d6e6575cbc0df76d37a17.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0041.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_0_0042.png-6659fdb2494734652654c028ea5087fc.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_0_0042.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_0_0043.png-0c7e915e718028acacfedaad679e0227.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_0_0043.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_0_0044.png-01e3e2dc516f2dcdf7b4aa7a81620deb.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_0_0044.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_0_0045.png-2c2a1680b70e12826afc1b2b3b9e29b7.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_0_0045.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_1_0001.png-bdb495a9757bdad6797f07eb8555971a.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_1_0001.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0002.png-934840a768165d77186589af676f8a4e.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0002.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0003.png-050f68e9fff75da7614b94ff90773eed.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0003.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0004.png-ebd21421acf611af84f966b5091ce26b.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0004.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0005.png-555a0784cf791c3641ccbc1c5990fb87.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0005.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0006.png-ca0673a91afce76bf8874c74463838f1.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0006.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0007.png-1214b7a104d06df3c3d497bcd1be1834.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0007.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0008.png-f8a89ef405120ae9a8bf879e19cdfa97.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0008.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0009.png-5dcfbd387d83e1ba7227231c891d949a.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0009.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0010.png-f87d76a8175e6446982bab4d7d54ea61.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0010.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0011.png-0337dba63b70dc413b74a06679b6f28c.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0011.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0012.png-03f5f787850b85bee05c351073002118.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0012.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0013.png-b30021586e7c63704890c71eb3a782d9.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0013.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0014.png-1564734f8bb6b3ba6603a743ca7f2575.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0014.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0015.png-e710f55eee5b4c83238640df6bd82846.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0015.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0016.png-0b030e77519508ff1c669f94a1909f94.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0016.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0017.png-e82a6bdd5771e6423a06a0f7342f6e3b.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0017.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0018.png-522091f455426a018d858f5e03c2ab2e.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0018.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0019.png-58201ff8f09e92ec1da1b349fe68db5b.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0019.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0020.png-594e00db2708c2beb29bc93b558dacc3.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0020.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0021.png-074a2e39d733763b37f5b5023df8dfa2.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0021.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0022.png-b8945aba745c3588278faeaf7e1419d4.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0022.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0023.png-5574c663a5fd93f4f03c7eb49828e01a.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0023.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0024.png-60b1a3cd41d1449cc00f64ac3a3f2024.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0024.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0025.png-fb4f2085498167f038dea4b9ec1c2279.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0025.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0026.png-3265acf35ac991ca8f99d9158ac0c1ec.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0026.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0027.png-3418243241bb87f5dc647a772a0efb43.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0027.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0028.png-ee04ca2d0c1aec65325fa925b01c7b1f.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0028.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0029.png-b38794b7bc2ffad1ed4ba99b92cc7227.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0029.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0030.png-671d0253c720699f7c3aa085a63e2a5b.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0030.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0031.png-89b3713d6f7838cee10dd042401d3fad.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0031.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0032.png-2593f66ac31520f96e7fa30959a43e91.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0032.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0033.png-f661de841ee888883396bbe72741b344.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0033.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0034.png-dec28c10562b756dfd86ca58b3e77c40.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0034.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0035.png-1ce258d5745a5fe65a0fd18bfe165fff.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0035.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0036.png-8b7624a493e1a0760ebb2d1f085a37d6.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0036.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0037.png-41f34d23b8fa74a0072956b37088e759.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0037.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0038.png-55a78398a9df364419def19f4ce95af0.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0038.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0039.png-e7a80ce8f9a02fe1310fe47958fd1d41.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0039.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0040.png-b787b560ded3a9fa62bdd1b77723786c.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0040.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0041.png-9690a7eae3341348c1f95f5602be05aa.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0041.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0042.png-7ebe60fb7dda624362b76375368134dd.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0042.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0043.png-7d23a42240b59f04fe4b48547e8f6da9.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0043.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_1_0044.png-0a5dc74966e7dc5eab92fdf6420ea36a.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_1_0044.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_1_0045.png-612dd05ef6ba543963834c97608a32a8.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_1_0045.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0001.png-5edef45f93b3c30215829a5f4ee539a5.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0001.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0002.png-0dc81ff8f64a189a3b647d52dfacf8ea.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0002.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0003.png-8a0453cc9f955415e5f82c386c9ca46c.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0003.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0004.png-9ae7dde74db7dd14c7cbe87d30c66b68.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0004.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0005.png-6f55b2b9c644ef31b21e0dcd11b57ec2.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0005.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0006.png-2e676cddde54f2d6eb922c7069f62736.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0006.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0007.png-9474866534e92b9a05921a6d4857067d.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0007.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0008.png-824cc4850c09bfcbd2d1b0035a43e067.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0008.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0009.png-2e18df9058df064f6724510b64e7ba78.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0009.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0010.png-e4b40f869b92e6e9cd7307dc8d05489b.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0010.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0011.png-3aa009aa9fd5f1d11df53c6ac2f5b5df.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0011.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0012.png-7c170912d4a612a69a3c4e695f111c5f.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0012.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0013.png-bc3e7baa32067d83335a4e95cf4b741c.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0013.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0014.png-3722562c1d091de2a0b91e5cd8349db5.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0014.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0015.png-f464949052b0da7f6a17637e4b1661f6.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0015.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0016.png-4843269e6dc01a3544a9e4d926e1241a.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0016.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0017.png-ff620210c514d0a21957038f3916bd14.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0017.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0018.png-b36d4042dc59a8aaed3ffdceb402e501.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0018.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0019.png-e052941f9a25252589d938aa2627df8a.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0019.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0020.png-6268e8691232161d7624dcca11583e41.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0020.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0021.png-ed3d2424d7120473fbbadc074f4efd14.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0021.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0022.png-51a6f3b3e77c867242bc342972c33180.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0022.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0023.png-3e6859d04911c957f9489557b78b06cc.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0023.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0024.png-282d8d17bae6c8654d89674f1c32a197.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0024.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0025.png-ca5226424597c3ac543f265056272ac8.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0025.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0026.png-9e0d7fbc5fea747e938f546d364ee7ba.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0026.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0027.png-bc33f42a80a11ec8fe49ef20a0661a9a.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0027.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0028.png-25176d6154401916dcaa077304511057.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0028.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0029.png-49975c5c6af211692c84f9679331e1f3.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0029.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0030.png-56de73700cd6f6aa2936077195517479.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0030.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0031.png-52aac777105c1cd8f0b3ec0db04482d7.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0031.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0032.png-ff3d7f88100e92134cab2e7ccc4fd01b.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0032.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0033.png-e6d5817fff0854bd1857b949c443d2c7.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0033.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0034.png-5a8afc03d617da4ff4b9f6a9ee630db8.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0034.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0035.png-aacef661a413cdac61ab7b4b2347df30.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0035.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0036.png-66afe91228cbd5490fa49e5ea2f0335b.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0036.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0037.png-1d3c68ac96e6cf31b172295b3de067b5.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0037.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_2_0038.png-ee2ee22a14ff22dfd3b5a6cde164af77.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_2_0038.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_2_0039.png-1060b4ca444a509a181dc11dc97444ec.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_2_0039.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_2_0040.png-fd2865b617e7b9d89d3e9766db0a3840.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_2_0040.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_2_0041.png-c97812285731470074b9c9e300ef9e65.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_2_0041.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_2_0042.png-0c39dcba0311b68852dba1f724f4be04.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_2_0042.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_2_0043.png-bfd2ba0016b2bdec0825f788a31ea897.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_2_0043.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_2_0044.png-97f3b7371f5b1724ee7d68221d6b1912.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_2_0044.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_2_0045.png-11acbd16bb764485e7ae2275107db149.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_2_0045.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_3_0001.png-31fc37a9e42930004808f030423fd577.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_3_0001.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0002.png-7c1bc4aeb3ff35b537bb53998bf69bab.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0002.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0003.png-5bf3295a4d9b8284bd0ac673a6309a08.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0003.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0004.png-5592b0dbe01a20f12ec8618b369c6f52.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0004.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0005.png-3c1230e43d81597f80567d873c55db13.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0005.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0006.png-45e84080bfd6afaaa0955b9cd46ff09d.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0006.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0007.png-8e3503f7074ae3023a0b9b132650b22a.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0007.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0008.png-26f083538118f1e8b42106e2f6372be2.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0008.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0009.png-10dbc8517bbc031463f3ae77296f97ad.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0009.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0010.png-08298348522f60379afec88de95bb2b7.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0010.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0011.png-5a0bfc0660596d00b1cb8b891fb6fa10.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0011.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0012.png-ed0ac74b550525819c05e15a362549ef.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0012.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0013.png-4c02174a68c2dba29376b8c908786c25.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0013.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0014.png-13ebdda30cc330123a5790ca2a2555f0.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0014.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0015.png-5fbdce781159aadc35349c5a3bebb91e.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0015.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0016.png-e9d305e258e9afd8f205c0cac9fc78c3.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0016.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0017.png-d763659027a5da4cea16ec4fe382345e.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0017.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0018.png-d82463317106aa660a52a7533094d673.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0018.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0019.png-eaa1ae0ed50e2f4d68476dbcaa8962e7.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0019.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0020.png-62f9861f6e2cd96510d4f56c3f351d4b.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0020.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0021.png-5e787d913618906013f43632d4e23f11.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0021.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0022.png-4eb98c30c1306ecd14123de3db43457c.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0022.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0023.png-2ff3ddbdaf2d9b3685fdc173624c3912.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0023.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0024.png-b1dbed21965ad7787031e26dc7960277.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0024.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0025.png-17d0c92b90940d326db4bb0a82b3d7a5.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0025.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0026.png-63facc91904dbd66f32b0a101dc9318d.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0026.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0027.png-af9d4619028fe1327bae6f2acd8f4601.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0027.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0028.png-a10c2fc2c81e56539c59dc1ee413394c.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0028.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0029.png-daf87e63081f9c0a54447006bd2209b6.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0029.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0030.png-e0daaf8466b78886ee3c4d6a13c77a88.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0030.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0031.png-79dd733b6f4796896ee4754093cbf574.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0031.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0032.png-673d415399e336f57767622876a059cc.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0032.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0033.png-351ed26bf049f1c9f5b8f63b48fdc540.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0033.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0034.png-bf45ccd5b8ecb2498520ba55ea8fca90.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0034.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0035.png-4129cce2cdd07ba02d5c20ca4c246a11.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0035.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_3_0036.png-abf04b2b00fe88fdd23ad0bea5df2f99.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_3_0036.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_3_0037.png-751d3c8b75838e4c057b69baa189a6fb.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_3_0037.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_3_0038.png-8a31cb5390a0d5e3a37469e403fc9ea0.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_3_0038.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_3_0039.png-360cb8e786195be9e7dfb3c3a41fae55.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_3_0039.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_3_0040.png-4668837ad40cd17338f2a3a499a99944.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_3_0040.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_3_0041.png-4ede56ee72e588a4885b2b8d46d20b13.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_3_0041.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_3_0042.png-3f2669e912059103f59dd7cbdf921b09.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_3_0042.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_3_0043.png-cf5aae44be164daae0adafb255e53c3a.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_3_0043.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_3_0044.png-8171ad75fd9c98d5eb123b4fcc2fe1d0.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_3_0044.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_3_0045.png-739fee3a1c4268b262bce228f3c25540.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_3_0045.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0001.png-44c0140589c9477c53e693ca422a610f.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0001.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0002.png-03e83ca13844bf120ff9f33592cabb55.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0002.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0003.png-5a067b1ce8c2abce9d265d1085006aa2.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0003.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0004.png-3e737cb0da6ac2bbf67f17e9de4541da.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0004.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0005.png-50ca1e2ace0ad812aa8e4658e5fbc49b.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0005.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0006.png-cbaebc60f655a63514a9ee42bbe601a8.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0006.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0007.png-9b4fde0a646fd92a84a198f3308e7f9c.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0007.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0008.png-914cc8543e9f50ced206fb184b891a30.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0008.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0009.png-f906857f39f7c9499bf866179301a8fa.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0009.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0010.png-e5aea61231082aa35a21f40f2712ec09.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0010.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0011.png-046e49dffaa400aa7376d9ab1b6427b9.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0011.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0012.png-fd1244d2744d4afcec69891ea22bf3ef.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0012.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0013.png-7b2b287a5acb0f329ec30bd468e72c1b.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0013.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0014.png-a86ccdbf773101b21bcc3797b678b648.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0014.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0015.png-b58405815ea0731a85856890e866e793.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0015.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0016.png-81e83a46d052604fb757f7c0412bfeb0.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0016.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0017.png-39333cb64f3c2877e9b4b20f86f02771.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0017.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0018.png-4003cb82bd9d789910f6f8d31a8bec48.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0018.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0019.png-dead4a6a63153cb0b9b7931f5ae678ed.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0019.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0020.png-71b2b2ce20e8fbab8b36a7ca71ba801c.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0020.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0021.png-ec51ee3073d172fbdb1752fe73b64753.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0021.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0022.png-c9d441a84209b2fd15a00faa56fb1251.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0022.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0023.png-2ce81c611a182118a20d5505faf43e96.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0023.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0024.png-8de87e72e639b46d062c45e528d5ca76.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0024.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0025.png-0c9d69a0d7dd65f8c19b5d14c8c9e938.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0025.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0026.png-b4078c194745d66f3f8b16c33db101ba.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0026.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0027.png-a0e8070b2a4b990a2fa3970d09ed07df.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0027.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0028.png-81d472d161be45c7797b5fbf138424a3.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0028.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0029.png-89b8cb45ca54fce7e0b0a4345dd77e09.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0029.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0030.png-a4ea7e588e4207342eab45b6bece9b09.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0030.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0031.png-56f62fd7bf021bdf915f7a99d49c25d4.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0031.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0032.png-a02734f8bdb2a9ad41fa7f5b015afc87.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0032.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0033.png-6d81174d22f2c4d14bcd6a92aedafe5c.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0033.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_4_0034.png-65e08bf7b6548c7094aa67e59f0be8be.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_4_0034.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_4_0035.png-be32669bf98db3b34e6df6590b21a192.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_4_0035.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_4_0036.png-0d1a5b53a63e57bd8542ccb7f3bb3f64.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_4_0036.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_4_0037.png-f3e55a4dc2b84a975bbdeb291c52bf65.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_4_0037.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_4_0038.png-4a5bd9cfd14b5deedd060279575f5aef.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_4_0038.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_4_0039.png-c90075c8d1b9a00ed5bb2713007533a9.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_4_0039.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_4_0040.png-1bb4300271bd8cde60ac4bf231cad3f8.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_4_0040.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_4_0041.png-24f218bb887697ebff8afbc939c66102.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_4_0041.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_4_0042.png-32f0cb46cb07386daf5336ede400072f.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_4_0042.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_4_0043.png-c29414dfe98a0fffa05aa08c80b5a047.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_4_0043.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_4_0044.png-267944e3e6bc3dffcd6632d486270177.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_4_0044.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_4_0045.png-7d4f63980d87410e0f5f75d6fcd7980f.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_4_0045.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_5_0001.png-54ecb67a3b64ef53b95f38cfcaab5d7e.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_5_0001.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0002.png-4be9ff92bf6613ac5f0532ee594c9f8d.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0002.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0003.png-02ae3ecccec6854388104446a5cce060.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0003.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0004.png-78f400ba5159020d0cc327fb7751626b.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0004.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0005.png-a61599f3a6912253a4ee8a46f2179ee0.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0005.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0006.png-a7a9166dcc80e53082039570e987d60e.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0006.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0007.png-97719fa861936e98f05b1c47c7437edb.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0007.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0008.png-bfa0a41e9582b4220810342faa17048b.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0008.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0009.png-222b7f2c0ba311d0eb36c49e18d4fac0.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0009.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0010.png-a0a53aaa4f0d1e1d0b151c9561284562.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0010.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0011.png-718b2daecc82a6b8e27bafe5e48aeeda.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0011.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0012.png-0165b583c3cf87032ff35631b2e3e95a.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0012.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0013.png-838fe2b9da91889799d90ec54c4cc969.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0013.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0014.png-d8663fd1c9ebf299c93e7dc67e26f95f.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0014.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0015.png-2100f509d345cd07461664ab3eaa81dd.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0015.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0016.png-226901d9b28cf7df2decd0451326d75c.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0016.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0017.png-dfd5420cd9b200935c84bf0f4cac4ab0.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0017.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0018.png-aa2e5c55ce7ff835a3ea1c42d9837741.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0018.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0019.png-a943751b68884dfc46fbb0c2c0d5178b.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0019.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0020.png-3584c763a7727de0c392a8c618354c88.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0020.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0021.png-79793cf9cbb8fe9c5c92a8a8c186c165.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0021.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0022.png-ea8d8f9eacfcc6ad60cf0eac8f76bb2d.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0022.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0023.png-f2938d845123450a87fd6be27d904951.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0023.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0024.png-a231cbffffd158111eb4a45e6c9494ab.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0024.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0025.png-fe9f38a76a4fcb7b388729392facaaf2.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0025.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0026.png-e8934ff24161fe66919d3f09ded05027.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0026.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0027.png-26da75d75afe8b79255c43e3d8e08e98.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0027.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0028.png-d694010607039d58c26ddbd9f48585be.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0028.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0029.png-800bbbc0a1f0dae81fe7ae5f7e27f370.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0029.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0030.png-7b64c82c5a0463a9b47161a4935e60ce.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0030.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0031.png-acfc1df8e7d5e6d193dfc8220f1db0ee.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0031.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0032.png-423371a1636bc3f76ff44be178654e40.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0032.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0033.png-78216bae1d9c00088dcc3233e62ca4db.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0033.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0034.png-34a0b317ec360b1b06a2262b63ffae14.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0034.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_5_0035.png-62cf4a4fa40fc11ae23842db81261d48.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_5_0035.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_5_0036.png-38c419c3886c9f73785214229b1e5e8a.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_5_0036.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_5_0037.png-70052c6484a98cf0e42ae14e7c15da95.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_5_0037.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_5_0038.png-c0bf8c173fa4868b88096fb5ef6cd786.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_5_0038.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_5_0039.png-976536a45ab5477c7df7d1c99b776380.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_5_0039.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_5_0040.png-ba9bce1718013b82ef4d19d9b0f1c763.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_5_0040.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_5_0041.png-46f91cd851a5f818c5a02091783f1be4.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_5_0041.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_5_0042.png-02de82baf6bddc7ed4ba0f7cb97fcc55.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_5_0042.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_5_0043.png-c35a6a6a429dcfc7d718438169e5de18.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_5_0043.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_5_0044.png-ce3e123d0b3626a753b875112d502854.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_5_0044.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_5_0045.png-6852b5c6ea7d3ebfd8e76ca923623c0e.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_5_0045.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0001.png-305ad0570c16badf494841e57f4ba611.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0001.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0002.png-22826ad2b1480d94ac49569140300b7d.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0002.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0003.png-2ddfab84d846eea12800d2ae3258d124.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0003.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0004.png-198bf0b806aed2f6d3c931a62777c72b.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0004.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0005.png-2843d807360986b608946b90e888010b.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0005.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0006.png-3e9d956ac832e00cd3c5c5e88b3ed985.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0006.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0007.png-5d37f95317537321949f3aa1b3bdaec5.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0007.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0008.png-5e47c714d8975acee8a61f03c7e1c8a8.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0008.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0009.png-a5ff6975ef9d035dc44e9369a7633b7b.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0009.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0010.png-18fefd47204b86c43402b80449215e5d.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0010.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0011.png-403f81f4712d87a6fc7bc293abfe951c.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0011.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0012.png-7a43de7f34962670014e2fa8cf58bdbd.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0012.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0013.png-6997758c5a879c6dfebd9bf83fb80b19.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0013.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0014.png-cded909ae25b702d64c05cd7ae0d2f13.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0014.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0015.png-66aeb5bd0bc542fc175fec55a3bf6087.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0015.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0016.png-b938bf7a70c22eb9d70fcaf577311100.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0016.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0017.png-176b7f93ffdda965c54bdd0eb9326d9b.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0017.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0018.png-f92b96743b8714dcbaf521b80eafbf3f.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0018.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0019.png-5761e61793846e110d7703fd46cae4d4.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0019.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0020.png-8a75df3dc801931a2f4c8ace65113319.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0020.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0021.png-9a33865f02a031907cbfe0e27fd35f00.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0021.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0022.png-3e67df7c6e0a065b498d39b0c08b0312.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0022.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0023.png-7f64aa280564aebe45e5dc0d8d9d5c16.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0023.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0024.png-88f09f26e628d7d315ce59732ccc2834.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0024.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0025.png-0b3af2fa1d2cbbfd99d4ee002fb12840.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0025.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0026.png-021f4a1a723c8d54576610d04d7fd57f.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0026.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0027.png-44e3d8b5ff0f346c8104b4032f560f71.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0027.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0028.png-1105d75f85506ccc5746fbd864b24fff.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0028.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0029.png-e4b4caed37291002953d56f4ca4131ab.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0029.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0030.png-61625df132dbbd128d4e1f75e75aabfc.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0030.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0031.png-d749cc2494f059267e4e7df5116e8622.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0031.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0032.png-71a30f79d5da9c1b438f22b398b5dab1.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0032.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_6_0033.png-1581d03ab3875a38a17e89ed97f9e4b7.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_6_0033.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_6_0034.png-901410a3b9a1123e4fe9c6c067e84996.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_6_0034.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_6_0035.png-0ca73a5099e5ee470642737d3d349212.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_6_0035.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_6_0036.png-74212616df9d8d718bb761f75646bcc1.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_6_0036.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_6_0037.png-b8f3cd7f00d11e1738def20ba138ad31.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_6_0037.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_6_0038.png-de4b8fd9a432a6d0cb6d62a70779f107.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_6_0038.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_6_0039.png-30fe4a5d0248c94f51c386de6818aab0.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_6_0039.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_6_0040.png-01c5d066ea63da2b2939414aab6b7897.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_6_0040.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_6_0041.png-36d9495a377e03e36d424fd98695a054.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_6_0041.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_6_0042.png-0d3be26f076a11fe04aa48150607f766.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_6_0042.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_6_0043.png-b9f2da0ea4ca216970722097f128bbd1.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_6_0043.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_6_0044.png-3f84695fc07f7b738486280eb5603000.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_6_0044.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_6_0045.png-deb75272ecbeaf94c9d8a660d7c0ac85.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_6_0045.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0001.png-f56163f66408f9b4868c963b7ccdc888.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0001.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0002.png-c0fe11e0a41fb3e172cad384ea0d6fdb.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0002.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0003.png-80353ff236d3b9e9529d95b234901c2f.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0003.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0004.png-f17b8c72db6c5a5555c1e058a4fdb37d.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0004.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0005.png-9b495c651b85e4394c7278ed9117f507.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0005.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0006.png-b55337d24f1991722d24974127890164.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0006.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0007.png-3f74fdb57cdfb5cf92632111c7c47353.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0007.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0008.png-14fff645fc469a9ca37da44571c8bf40.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0008.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0009.png-44a989bb4ef8aec21b41ccf787b8ad79.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0009.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0010.png-f8b6efa1bc0fdde4984d18d79ab2b87a.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0010.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0011.png-8d079e563451cb648d05f12fcd83410e.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0011.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0012.png-c481686c32eb52fd6fd4412c6d7b4b4e.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0012.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0013.png-230ea27940975966523df263c58504ff.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0013.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0014.png-cd9b475b011d51a12b5035e2f55c89a4.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0014.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0015.png-6462d0a0c363f5a418682bbd99cfee9f.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0015.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0016.png-1e525788b0aecb2c77f9c99b2c6e7961.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0016.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0017.png-fc1fb54f89a66e7672a3dea4977bf5dd.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0017.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0018.png-ab4b697f5439f7562d6495d6ca1b21c2.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0018.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0019.png-d6adf250f69ca718c20f2b6f1e1dab8b.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0019.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0020.png-13e81bed771a378dd92fe3e44a5dcae9.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0020.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0021.png-95025a26723093c478b81f9159680c72.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0021.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0022.png-7119dbcacfdc1fbeea0a4908fde2ad4c.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0022.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0023.png-42911aed0fd1e7b00c59d14e1d3bd2ec.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0023.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0024.png-cd0313892fa0271db3530d704b558c3a.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0024.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0025.png-e837b778cf6654dccb6e1c3cac343e06.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0025.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0026.png-c14e9001cf3dbffbd89121685a29876b.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0026.png.import
	savepack: step 97: Storing File: res://.godot/imported/dir_7_0027.png-410a93b758978f6107af16ca2265aaca.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/dir_7_0027.png.import
	savepack: step 97: Storing File: res://.godot/imported/dir_7_0028.png-f441389b1b2984eba015ff3018824976.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/dir_7_0028.png.import
	savepack: step 97: Storing File: res://.godot/imported/dir_7_0029.png-37b4c07a4c3f14a34495ee55687869f8.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/dir_7_0029.png.import
	savepack: step 97: Storing File: res://.godot/imported/dir_7_0030.png-ef549d8584817425a792f64d53b357de.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/dir_7_0030.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0031.png-368fd541b5b5219ce5724ebf77b504e3.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0031.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0032.png-5862cafb570810c768df0659dbd21c86.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0032.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0033.png-04b92d5998216baaca5ce78bc7e2b0ab.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0033.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0034.png-f360fbba45604b91d35ca2106e17547f.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0034.png.import
	savepack: step 98: Storing File: res://.godot/imported/dir_7_0035.png-ab41dcabc7044bd63709f874ba63d42f.ctex
	savepack: step 98: Storing File: res://sprites/player_idle/dir_7_0035.png.import
	savepack: step 99: Storing File: res://.godot/imported/dir_7_0036.png-e59c70a78b8e861cb280f41a3eb39067.ctex
	savepack: step 99: Storing File: res://sprites/player_idle/dir_7_0036.png.import
	savepack: step 99: Storing File: res://.godot/imported/dir_7_0037.png-ac4072e6541b8df202a43dea56e7cd67.ctex
	savepack: step 99: Storing File: res://sprites/player_idle/dir_7_0037.png.import
	savepack: step 99: Storing File: res://.godot/imported/dir_7_0038.png-42cd164980ead0a5b2376797057244a2.ctex
	savepack: step 99: Storing File: res://sprites/player_idle/dir_7_0038.png.import
	savepack: step 99: Storing File: res://.godot/imported/dir_7_0039.png-7c2343a6c86942135313d0c4bc4f414e.ctex
	savepack: step 99: Storing File: res://sprites/player_idle/dir_7_0039.png.import
	savepack: step 100: Storing File: res://.godot/imported/dir_7_0040.png-5312afda3741127ce8a70bfb88de9549.ctex
	savepack: step 100: Storing File: res://sprites/player_idle/dir_7_0040.png.import
	savepack: step 100: Storing File: res://.godot/imported/dir_7_0041.png-9b4ca50bea3cbd33520b6451fc976146.ctex
	savepack: step 100: Storing File: res://sprites/player_idle/dir_7_0041.png.import
	savepack: step 100: Storing File: res://.godot/imported/dir_7_0042.png-435fab965479c665ead6209978a0e5fc.ctex
	savepack: step 100: Storing File: res://sprites/player_idle/dir_7_0042.png.import
	savepack: step 100: Storing File: res://.godot/imported/dir_7_0043.png-5bf45588c7753e97799660453a66348f.ctex
	savepack: step 100: Storing File: res://sprites/player_idle/dir_7_0043.png.import
	savepack: step 101: Storing File: res://.godot/imported/dir_7_0044.png-e710ee96e2dd522844ed77edfeac0918.ctex
	savepack: step 101: Storing File: res://sprites/player_idle/dir_7_0044.png.import
	savepack: step 101: Storing File: res://.godot/imported/dir_7_0045.png-9b82aafad83a15cdf5250f678768e4c3.ctex
	savepack: step 101: Storing File: res://sprites/player_idle/dir_7_0045.png.import
	savepack: step 101: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d386ad401674f18d1edfd264d67ce020.scn
	savepack: step 101: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
	savepack: step 101: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-8f735e678b86df73bf8978d10c629e6f.s3tc.ctex
	savepack: step 101: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
	savepack: step 101: Storing File: res://scenes/dial_up_queen.tscn.remap
	savepack: step 101: Storing File: res://scenes/FloodedMall_Greybox.tscn.remap
	savepack: step 101: Storing File: res://scenes/health_candy_pickup.tscn.remap
	savepack: step 101: Storing File: res://scenes/intro.tscn.remap
	savepack: step 101: Storing File: res://scenes/main_menu.tscn.remap
	savepack: step 101: Storing File: res://scenes/neon_cicada.tscn.remap
	savepack: step 101: Storing File: res://scenes/player.tscn.remap
	savepack: step 101: Storing File: res://scripts/boss_encounter_trigger.gd.remap
	savepack: step 101: Storing File: res://scripts/checkpoint.gd.remap
	savepack: step 101: Storing File: res://scripts/corrupted_kiosk_turret.gd.remap
	savepack: step 101: Storing File: res://scripts/dial_up_queen.gd.remap
	savepack: step 101: Storing File: res://scripts/disk_projectile.gd.remap
	savepack: step 101: Storing File: res://scripts/enemy_model.gd.remap
	savepack: step 101: Storing File: res://scripts/health_candy_pickup.gd.remap
	savepack: step 101: Storing File: res://scripts/hud.gd.remap
	savepack: step 101: Storing File: res://scripts/isometric_camera.gd.remap
	savepack: step 101: Storing File: res://scripts/mall_greybox_builder.gd.remap
	savepack: step 101: Storing File: res://scripts/neon_cicada.gd.remap
	savepack: step 101: Storing File: res://scripts/save_manager.gd.remap
	savepack: step 101: Storing File: res://scripts/sludge_roach.gd.remap
	savepack: step 101: Storing File: res://scripts/turret_mortar.gd.remap
	savepack: step 101: Storing File: res://scripts/tutorial_director.gd.remap
	savepack: step 101: Storing File: res://.godot/global_script_class_cache.cfg
	savepack: step 101: Storing File: res://icon.svg
	savepack: step 101: Storing File: res://.godot/uid_cache.bin
	savepack: step 101: Storing File: res://.godot/extension_list.cfg
	savepack: step 101: Storing File: res://project.binary
savepack: end

EXIT: 0 (release)
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\Godot_v4.3-stable_win64.exe --headless --path "C:\y2k-biopunk-rpg\.worktrees\vs11export" --export-debug "Windows Desktop QA" build/qa/Y2K-BioPunk-QA.exe
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

savepack: begin: Packing steps: 102
	savepack: step 2: Storing File: res://.godot/imported/dial_up_queen.glb-c1a5cb2f8ad5373c4dcab5634b6375c1.scn
	savepack: step 2: Storing File: res://assets/models/dial_up_queen.glb.import
	savepack: step 2: Storing File: res://.godot/imported/fountain_sculpture.glb-a0ab240fe62ced988ba9a52de635ff8f.scn
	savepack: step 2: Storing File: res://assets/models/fountain_sculpture.glb.import
	savepack: step 2: Storing File: res://.godot/imported/kiosk_turret.glb-21d18cfe5e39c287914cfac610d69389.scn
	savepack: step 2: Storing File: res://assets/models/kiosk_turret.glb.import
	savepack: step 2: Storing File: res://.godot/imported/mall_kiosk.glb-ef7ad498f3da947c3b5d733a4903be11.scn
	savepack: step 2: Storing File: res://assets/models/mall_kiosk.glb.import
	savepack: step 2: Storing File: res://.godot/imported/mall_planter.glb-f1515752ded96a398eafbdc994b6e669.scn
	savepack: step 2: Storing File: res://assets/models/mall_planter.glb.import
	savepack: step 3: Storing File: res://.godot/imported/neon_cicada.glb-c075b36b4e093e1d35265564e67f028c.scn
	savepack: step 3: Storing File: res://assets/models/neon_cicada.glb.import
	savepack: step 3: Storing File: res://.godot/imported/sludge_roach.glb-1ae35041ab2d79767ebaf70f00e6243f.scn
	savepack: step 3: Storing File: res://assets/models/sludge_roach.glb.import
	savepack: step 3: Storing File: res://.godot/imported/anthem.mp3-2f7a92cf245df82890b7830193e2bea6.mp3str
	savepack: step 3: Storing File: res://music/anthem.mp3.import
	savepack: step 3: Storing File: res://.godot/imported/bigbeat.mp3-719a317dfac214297f4d640840ee7874.mp3str
	savepack: step 3: Storing File: res://music/bigbeat.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/bubblegum.mp3-6600d7a64ddbbec66a2b18480a79e0ad.mp3str
	savepack: step 4: Storing File: res://music/bubblegum.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/combat.mp3-1829eebac0ee46487ae84a3be83a352e.mp3str
	savepack: step 4: Storing File: res://music/combat.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/eurodance.mp3-fef95430f66d8053d0220ef34137fda9.mp3str
	savepack: step 4: Storing File: res://music/eurodance.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/hiphop.mp3-3d4b4945f60e4d0cddde31e8acbf2438.mp3str
	savepack: step 4: Storing File: res://music/hiphop.mp3.import
	savepack: step 4: Storing File: res://.godot/imported/numetal.mp3-058dd4db2f01f0c63415579f555fa23f.mp3str
	savepack: step 4: Storing File: res://music/numetal.mp3.import
	savepack: step 5: Storing File: res://.godot/imported/skater.mp3-47c0b3f6a66951ef919ba1b8e36e472c.mp3str
	savepack: step 5: Storing File: res://music/skater.mp3.import
	savepack: step 5: Storing File: res://bin/~libbiopunk.windows.template_debug.x86_64.dll
	savepack: step 5: Storing File: res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex
	savepack: step 5: Storing File: res://icon.svg.import
	savepack: step 5: Storing File: res://intro_video.ogv
	savepack: step 6: Storing File: res://Skate_Grind.res
	savepack: step 6: Storing File: res://tests/verify_camera_and_hud.gd
	savepack: step 6: Storing File: res://biopunk.gdextension
	savepack: step 6: Storing File: res://ops/tools/shot_harness.gd
	savepack: step 6: Storing File: res://bin/libbiopunk.windows.template_debug.x86_64.dll
	savepack: step 7: Storing File: res://bin/libbiopunk.windows.template_release.x86_64.dll
	savepack: step 7: Storing File: res://.godot/exported/133200997/export-72ee11ce23100f2096d10891190f557e-dial_up_queen.scn
	savepack: step 7: Storing File: res://.godot/exported/133200997/export-f257e87bfdc9f628dcc382c88547a250-FloodedMall_Greybox.scn
	savepack: step 7: Storing File: res://.godot/exported/133200997/export-d9b46989ff26b563f7686f0a6c74ef08-health_candy_pickup.scn
	savepack: step 8: Storing File: res://.godot/exported/133200997/export-aa3f5c97579d5c748215bbb2e364ddeb-intro.scn
	savepack: step 8: Storing File: res://.godot/exported/133200997/export-ea5c6ad4629af728dc514cefde332394-main_menu.scn
	savepack: step 8: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb-32a6b43d5d45dfc4ede7dd83598e8211.scn
	savepack: step 8: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb.import
	savepack: step 8: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg-4aa502cd14a84b2c529a8898c302226b.s3tc.ctex
	savepack: step 8: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg.import
	savepack: step 8: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg-ecf3d6b8aac2645fe97470a1f4e99f00.s3tc.ctex
	savepack: step 8: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg-3a28b97969be2809be74c1a9476bd1c9.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb-100b1b23c136ecaea2b2c2932c21ac1b.scn
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg-57c9bb5b0ae9234c05de81e42f298c6f.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg.import
	savepack: step 9: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg-2ba7f038ac6d306fa2b8d47c08417ab1.s3tc.ctex
	savepack: step 9: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg-55d7e5261dcedb3df0eddb11b7b87636.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations.glb-e7f241e6428c2b67e04f90f3be56e5af.scn
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations.glb.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg-3cea79246c65c32a532c42ecef570744.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg-cc800615ee86b5e4ee11529ddfdcda9e.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg.import
	savepack: step 10: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg-8ced58427b3620342c6ab9d1df00a24c.s3tc.ctex
	savepack: step 10: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb-dd2ef507427ee6ecd6de7aea3842d3f1.scn
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg-114f149bb1e7d1877ac3e9ac4b9ffcab.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg-95776f1ad3e7f33ed594f450af85b1ab.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg.import
	savepack: step 11: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg-b16ad54c8d136d69239c481caeb12679.s3tc.ctex
	savepack: step 11: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d6fdad554547eb106e82adbbc33e252f.scn
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-86710d89420272bd05b7dff2cb7dc19c.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-2c44aaf060978cde46693e50c10062e2.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
	savepack: step 12: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-edd18b21906bbfe2adb2655e252bd46b.s3tc.ctex
	savepack: step 12: Storing File: res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
	savepack: step 12: Storing File: res://.godot/exported/133200997/export-e098924b008c7d9e49d8e825c974b95b-neon_cicada.scn
	savepack: step 13: Storing File: res://.godot/exported/133200997/export-234fb6894ec6226e856ab7f825500d3d-player.scn
	savepack: step 13: Storing File: res://scripts/boss_encounter_trigger.gd
	savepack: step 13: Storing File: res://scripts/checkpoint.gd
	savepack: step 13: Storing File: res://scripts/corrupted_kiosk_turret.gd
	savepack: step 14: Storing File: res://scripts/dial_up_queen.gd
	savepack: step 14: Storing File: res://scripts/disk_projectile.gd
	savepack: step 14: Storing File: res://scripts/enemy_model.gd
	savepack: step 14: Storing File: res://scripts/health_candy_pickup.gd
	savepack: step 14: Storing File: res://scripts/hud.gd
	savepack: step 15: Storing File: res://scripts/isometric_camera.gd
	savepack: step 15: Storing File: res://scripts/mall_greybox_builder.gd
	savepack: step 15: Storing File: res://scripts/neon_cicada.gd
	savepack: step 15: Storing File: res://scripts/save_manager.gd
	savepack: step 16: Storing File: res://scripts/sludge_roach.gd
	savepack: step 16: Storing File: res://scripts/turret_mortar.gd
	savepack: step 16: Storing File: res://scripts/tutorial_director.gd
	savepack: step 16: Storing File: res://.godot/imported/dir_0_0001.png-b710fbec88935683feaa9ce80bb168b5.ctex
	savepack: step 16: Storing File: res://sprites/player_idle/dir_0_0001.png.import
	savepack: step 16: Storing File: res://.godot/imported/dir_0_0002.png-0e5a2de3b5fd5d28ce436b421d055443.ctex
	savepack: step 16: Storing File: res://sprites/player_idle/dir_0_0002.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0003.png-9b15b799a24f9fbfe900e8481215af28.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0003.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0004.png-7a93f1ab1179b0e965dc3faf9d34a601.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0004.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0005.png-a93eefa81d5de8b3df0e3a3ffa5a5a96.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0005.png.import
	savepack: step 17: Storing File: res://.godot/imported/dir_0_0006.png-31078175cbbcda22f61172097a8379ef.ctex
	savepack: step 17: Storing File: res://sprites/player_idle/dir_0_0006.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0007.png-5b49c7f21f56fa1f374a7643c4fa7f67.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0007.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0008.png-6d3590e2a1ac045c506836477d5759a0.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0008.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0009.png-14ae05c6400d3b747b38851b3f005a58.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0009.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0010.png-0d358bb0ba4f5b17b4fd2db4c1db63a0.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0010.png.import
	savepack: step 18: Storing File: res://.godot/imported/dir_0_0011.png-66f8d32db6bd94489fa6462c63bb9e25.ctex
	savepack: step 18: Storing File: res://sprites/player_idle/dir_0_0011.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0012.png-9af3e2a6a8140f68ca9c52822981ac4f.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0012.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0013.png-2c3132152db14b63df2020e769510265.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0013.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0014.png-9bee12fb872d8c3f8b14f8dc83a2e723.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0014.png.import
	savepack: step 19: Storing File: res://.godot/imported/dir_0_0015.png-bf3931a65824eda506dac5cb70f66061.ctex
	savepack: step 19: Storing File: res://sprites/player_idle/dir_0_0015.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0016.png-d5ef184284aa8dfbfa436acbd30ff617.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0016.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0017.png-95408049edb1e06eeca6a0623d844741.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0017.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0018.png-04ff2164a4e8823a45d760cb0f8c924c.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0018.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0019.png-bdf2ece8fc4b7d7339b68d8e3078e42d.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0019.png.import
	savepack: step 20: Storing File: res://.godot/imported/dir_0_0020.png-5dafb0540cece6243250ba9fe2abcf9d.ctex
	savepack: step 20: Storing File: res://sprites/player_idle/dir_0_0020.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0021.png-26b13f13a12aab931dc5a165ba2449d7.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0021.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0022.png-b7a7bcfe420d7715d19a0ab6614317de.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0022.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0023.png-323c1720fd734f8d4c3011866b334eaf.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0023.png.import
	savepack: step 21: Storing File: res://.godot/imported/dir_0_0024.png-d2c8f2e1d387e065f473c9c433f9ddb7.ctex
	savepack: step 21: Storing File: res://sprites/player_idle/dir_0_0024.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0025.png-1c40f3a80700734d053d96815854dfc0.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0025.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0026.png-c19f0c040198da8b7f9ee5df795757c2.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0026.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0027.png-ea9f0ee81748d1e693a28067922f5d2e.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0027.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0028.png-e24290a9e623664b03ab27acfb2650df.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0028.png.import
	savepack: step 22: Storing File: res://.godot/imported/dir_0_0029.png-a3c0a06ce660b5e7c165b81610c54676.ctex
	savepack: step 22: Storing File: res://sprites/player_idle/dir_0_0029.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0030.png-f6c9eac873d6fd0dbdc288b0fb569357.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0030.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0031.png-310e4fd4a08c8100e154b74c903283b5.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0031.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0032.png-f278b23644ae1ce5327c8b2c0b039452.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0032.png.import
	savepack: step 23: Storing File: res://.godot/imported/dir_0_0033.png-cdb93ffb1ecb703add4499597912f067.ctex
	savepack: step 23: Storing File: res://sprites/player_idle/dir_0_0033.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0034.png-fe43b2e0f994d038860628fea7c4f1d5.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0034.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0035.png-f4fa13aed07d11601dfd153b5d5242bf.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0035.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0036.png-bffcb23fb884cd6d25a3ac3a0412b507.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0036.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0037.png-68914dedfaad711accc4409744a56e4d.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0037.png.import
	savepack: step 24: Storing File: res://.godot/imported/dir_0_0038.png-1dab661763c48455fedaf2e96dd5a07a.ctex
	savepack: step 24: Storing File: res://sprites/player_idle/dir_0_0038.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0039.png-7032a0cb4ab60b64402bf0c907e4ca54.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0039.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0040.png-302ba8cb31466cb6ea3dc8dc997b3c57.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0040.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0041.png-2c61cdb0875d6e6575cbc0df76d37a17.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0041.png.import
	savepack: step 25: Storing File: res://.godot/imported/dir_0_0042.png-6659fdb2494734652654c028ea5087fc.ctex
	savepack: step 25: Storing File: res://sprites/player_idle/dir_0_0042.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0043.png-0c7e915e718028acacfedaad679e0227.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0043.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0044.png-01e3e2dc516f2dcdf7b4aa7a81620deb.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0044.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_0_0045.png-2c2a1680b70e12826afc1b2b3b9e29b7.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_0_0045.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_1_0001.png-bdb495a9757bdad6797f07eb8555971a.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_1_0001.png.import
	savepack: step 26: Storing File: res://.godot/imported/dir_1_0002.png-934840a768165d77186589af676f8a4e.ctex
	savepack: step 26: Storing File: res://sprites/player_idle/dir_1_0002.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_1_0003.png-050f68e9fff75da7614b94ff90773eed.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_1_0003.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_1_0004.png-ebd21421acf611af84f966b5091ce26b.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_1_0004.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_1_0005.png-555a0784cf791c3641ccbc1c5990fb87.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_1_0005.png.import
	savepack: step 27: Storing File: res://.godot/imported/dir_1_0006.png-ca0673a91afce76bf8874c74463838f1.ctex
	savepack: step 27: Storing File: res://sprites/player_idle/dir_1_0006.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0007.png-1214b7a104d06df3c3d497bcd1be1834.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0007.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0008.png-f8a89ef405120ae9a8bf879e19cdfa97.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0008.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0009.png-5dcfbd387d83e1ba7227231c891d949a.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0009.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0010.png-f87d76a8175e6446982bab4d7d54ea61.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0010.png.import
	savepack: step 28: Storing File: res://.godot/imported/dir_1_0011.png-0337dba63b70dc413b74a06679b6f28c.ctex
	savepack: step 28: Storing File: res://sprites/player_idle/dir_1_0011.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0012.png-03f5f787850b85bee05c351073002118.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0012.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0013.png-b30021586e7c63704890c71eb3a782d9.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0013.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0014.png-1564734f8bb6b3ba6603a743ca7f2575.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0014.png.import
	savepack: step 29: Storing File: res://.godot/imported/dir_1_0015.png-e710f55eee5b4c83238640df6bd82846.ctex
	savepack: step 29: Storing File: res://sprites/player_idle/dir_1_0015.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0016.png-0b030e77519508ff1c669f94a1909f94.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0016.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0017.png-e82a6bdd5771e6423a06a0f7342f6e3b.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0017.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0018.png-522091f455426a018d858f5e03c2ab2e.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0018.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0019.png-58201ff8f09e92ec1da1b349fe68db5b.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0019.png.import
	savepack: step 30: Storing File: res://.godot/imported/dir_1_0020.png-594e00db2708c2beb29bc93b558dacc3.ctex
	savepack: step 30: Storing File: res://sprites/player_idle/dir_1_0020.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0021.png-074a2e39d733763b37f5b5023df8dfa2.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0021.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0022.png-b8945aba745c3588278faeaf7e1419d4.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0022.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0023.png-5574c663a5fd93f4f03c7eb49828e01a.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0023.png.import
	savepack: step 31: Storing File: res://.godot/imported/dir_1_0024.png-60b1a3cd41d1449cc00f64ac3a3f2024.ctex
	savepack: step 31: Storing File: res://sprites/player_idle/dir_1_0024.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0025.png-fb4f2085498167f038dea4b9ec1c2279.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0025.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0026.png-3265acf35ac991ca8f99d9158ac0c1ec.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0026.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0027.png-3418243241bb87f5dc647a772a0efb43.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0027.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0028.png-ee04ca2d0c1aec65325fa925b01c7b1f.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0028.png.import
	savepack: step 32: Storing File: res://.godot/imported/dir_1_0029.png-b38794b7bc2ffad1ed4ba99b92cc7227.ctex
	savepack: step 32: Storing File: res://sprites/player_idle/dir_1_0029.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0030.png-671d0253c720699f7c3aa085a63e2a5b.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0030.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0031.png-89b3713d6f7838cee10dd042401d3fad.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0031.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0032.png-2593f66ac31520f96e7fa30959a43e91.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0032.png.import
	savepack: step 33: Storing File: res://.godot/imported/dir_1_0033.png-f661de841ee888883396bbe72741b344.ctex
	savepack: step 33: Storing File: res://sprites/player_idle/dir_1_0033.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0034.png-dec28c10562b756dfd86ca58b3e77c40.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0034.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0035.png-1ce258d5745a5fe65a0fd18bfe165fff.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0035.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0036.png-8b7624a493e1a0760ebb2d1f085a37d6.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0036.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0037.png-41f34d23b8fa74a0072956b37088e759.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0037.png.import
	savepack: step 34: Storing File: res://.godot/imported/dir_1_0038.png-55a78398a9df364419def19f4ce95af0.ctex
	savepack: step 34: Storing File: res://sprites/player_idle/dir_1_0038.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0039.png-e7a80ce8f9a02fe1310fe47958fd1d41.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0039.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0040.png-b787b560ded3a9fa62bdd1b77723786c.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0040.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0041.png-9690a7eae3341348c1f95f5602be05aa.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0041.png.import
	savepack: step 35: Storing File: res://.godot/imported/dir_1_0042.png-7ebe60fb7dda624362b76375368134dd.ctex
	savepack: step 35: Storing File: res://sprites/player_idle/dir_1_0042.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0043.png-7d23a42240b59f04fe4b48547e8f6da9.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0043.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0044.png-0a5dc74966e7dc5eab92fdf6420ea36a.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0044.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_1_0045.png-612dd05ef6ba543963834c97608a32a8.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_1_0045.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_2_0001.png-5edef45f93b3c30215829a5f4ee539a5.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_2_0001.png.import
	savepack: step 36: Storing File: res://.godot/imported/dir_2_0002.png-0dc81ff8f64a189a3b647d52dfacf8ea.ctex
	savepack: step 36: Storing File: res://sprites/player_idle/dir_2_0002.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_2_0003.png-8a0453cc9f955415e5f82c386c9ca46c.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_2_0003.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_2_0004.png-9ae7dde74db7dd14c7cbe87d30c66b68.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_2_0004.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_2_0005.png-6f55b2b9c644ef31b21e0dcd11b57ec2.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_2_0005.png.import
	savepack: step 37: Storing File: res://.godot/imported/dir_2_0006.png-2e676cddde54f2d6eb922c7069f62736.ctex
	savepack: step 37: Storing File: res://sprites/player_idle/dir_2_0006.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0007.png-9474866534e92b9a05921a6d4857067d.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0007.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0008.png-824cc4850c09bfcbd2d1b0035a43e067.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0008.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0009.png-2e18df9058df064f6724510b64e7ba78.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0009.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0010.png-e4b40f869b92e6e9cd7307dc8d05489b.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0010.png.import
	savepack: step 38: Storing File: res://.godot/imported/dir_2_0011.png-3aa009aa9fd5f1d11df53c6ac2f5b5df.ctex
	savepack: step 38: Storing File: res://sprites/player_idle/dir_2_0011.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0012.png-7c170912d4a612a69a3c4e695f111c5f.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0012.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0013.png-bc3e7baa32067d83335a4e95cf4b741c.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0013.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0014.png-3722562c1d091de2a0b91e5cd8349db5.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0014.png.import
	savepack: step 39: Storing File: res://.godot/imported/dir_2_0015.png-f464949052b0da7f6a17637e4b1661f6.ctex
	savepack: step 39: Storing File: res://sprites/player_idle/dir_2_0015.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0016.png-4843269e6dc01a3544a9e4d926e1241a.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0016.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0017.png-ff620210c514d0a21957038f3916bd14.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0017.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0018.png-b36d4042dc59a8aaed3ffdceb402e501.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0018.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0019.png-e052941f9a25252589d938aa2627df8a.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0019.png.import
	savepack: step 40: Storing File: res://.godot/imported/dir_2_0020.png-6268e8691232161d7624dcca11583e41.ctex
	savepack: step 40: Storing File: res://sprites/player_idle/dir_2_0020.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0021.png-ed3d2424d7120473fbbadc074f4efd14.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0021.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0022.png-51a6f3b3e77c867242bc342972c33180.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0022.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0023.png-3e6859d04911c957f9489557b78b06cc.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0023.png.import
	savepack: step 41: Storing File: res://.godot/imported/dir_2_0024.png-282d8d17bae6c8654d89674f1c32a197.ctex
	savepack: step 41: Storing File: res://sprites/player_idle/dir_2_0024.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0025.png-ca5226424597c3ac543f265056272ac8.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0025.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0026.png-9e0d7fbc5fea747e938f546d364ee7ba.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0026.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0027.png-bc33f42a80a11ec8fe49ef20a0661a9a.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0027.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0028.png-25176d6154401916dcaa077304511057.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0028.png.import
	savepack: step 42: Storing File: res://.godot/imported/dir_2_0029.png-49975c5c6af211692c84f9679331e1f3.ctex
	savepack: step 42: Storing File: res://sprites/player_idle/dir_2_0029.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0030.png-56de73700cd6f6aa2936077195517479.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0030.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0031.png-52aac777105c1cd8f0b3ec0db04482d7.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0031.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0032.png-ff3d7f88100e92134cab2e7ccc4fd01b.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0032.png.import
	savepack: step 43: Storing File: res://.godot/imported/dir_2_0033.png-e6d5817fff0854bd1857b949c443d2c7.ctex
	savepack: step 43: Storing File: res://sprites/player_idle/dir_2_0033.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0034.png-5a8afc03d617da4ff4b9f6a9ee630db8.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0034.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0035.png-aacef661a413cdac61ab7b4b2347df30.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0035.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0036.png-66afe91228cbd5490fa49e5ea2f0335b.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0036.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0037.png-1d3c68ac96e6cf31b172295b3de067b5.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0037.png.import
	savepack: step 44: Storing File: res://.godot/imported/dir_2_0038.png-ee2ee22a14ff22dfd3b5a6cde164af77.ctex
	savepack: step 44: Storing File: res://sprites/player_idle/dir_2_0038.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0039.png-1060b4ca444a509a181dc11dc97444ec.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0039.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0040.png-fd2865b617e7b9d89d3e9766db0a3840.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0040.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0041.png-c97812285731470074b9c9e300ef9e65.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0041.png.import
	savepack: step 45: Storing File: res://.godot/imported/dir_2_0042.png-0c39dcba0311b68852dba1f724f4be04.ctex
	savepack: step 45: Storing File: res://sprites/player_idle/dir_2_0042.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0043.png-bfd2ba0016b2bdec0825f788a31ea897.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0043.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0044.png-97f3b7371f5b1724ee7d68221d6b1912.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0044.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_2_0045.png-11acbd16bb764485e7ae2275107db149.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_2_0045.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_3_0001.png-31fc37a9e42930004808f030423fd577.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_3_0001.png.import
	savepack: step 46: Storing File: res://.godot/imported/dir_3_0002.png-7c1bc4aeb3ff35b537bb53998bf69bab.ctex
	savepack: step 46: Storing File: res://sprites/player_idle/dir_3_0002.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_3_0003.png-5bf3295a4d9b8284bd0ac673a6309a08.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_3_0003.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_3_0004.png-5592b0dbe01a20f12ec8618b369c6f52.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_3_0004.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_3_0005.png-3c1230e43d81597f80567d873c55db13.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_3_0005.png.import
	savepack: step 47: Storing File: res://.godot/imported/dir_3_0006.png-45e84080bfd6afaaa0955b9cd46ff09d.ctex
	savepack: step 47: Storing File: res://sprites/player_idle/dir_3_0006.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_3_0007.png-8e3503f7074ae3023a0b9b132650b22a.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_3_0007.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_3_0008.png-26f083538118f1e8b42106e2f6372be2.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_3_0008.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_3_0009.png-10dbc8517bbc031463f3ae77296f97ad.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_3_0009.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_3_0010.png-08298348522f60379afec88de95bb2b7.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_3_0010.png.import
	savepack: step 48: Storing File: res://.godot/imported/dir_3_0011.png-5a0bfc0660596d00b1cb8b891fb6fa10.ctex
	savepack: step 48: Storing File: res://sprites/player_idle/dir_3_0011.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0012.png-ed0ac74b550525819c05e15a362549ef.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0012.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0013.png-4c02174a68c2dba29376b8c908786c25.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0013.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0014.png-13ebdda30cc330123a5790ca2a2555f0.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0014.png.import
	savepack: step 49: Storing File: res://.godot/imported/dir_3_0015.png-5fbdce781159aadc35349c5a3bebb91e.ctex
	savepack: step 49: Storing File: res://sprites/player_idle/dir_3_0015.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0016.png-e9d305e258e9afd8f205c0cac9fc78c3.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0016.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0017.png-d763659027a5da4cea16ec4fe382345e.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0017.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0018.png-d82463317106aa660a52a7533094d673.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0018.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0019.png-eaa1ae0ed50e2f4d68476dbcaa8962e7.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0019.png.import
	savepack: step 50: Storing File: res://.godot/imported/dir_3_0020.png-62f9861f6e2cd96510d4f56c3f351d4b.ctex
	savepack: step 50: Storing File: res://sprites/player_idle/dir_3_0020.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0021.png-5e787d913618906013f43632d4e23f11.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0021.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0022.png-4eb98c30c1306ecd14123de3db43457c.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0022.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0023.png-2ff3ddbdaf2d9b3685fdc173624c3912.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0023.png.import
	savepack: step 51: Storing File: res://.godot/imported/dir_3_0024.png-b1dbed21965ad7787031e26dc7960277.ctex
	savepack: step 51: Storing File: res://sprites/player_idle/dir_3_0024.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0025.png-17d0c92b90940d326db4bb0a82b3d7a5.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0025.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0026.png-63facc91904dbd66f32b0a101dc9318d.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0026.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0027.png-af9d4619028fe1327bae6f2acd8f4601.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0027.png.import
	savepack: step 52: Storing File: res://.godot/imported/dir_3_0028.png-a10c2fc2c81e56539c59dc1ee413394c.ctex
	savepack: step 52: Storing File: res://sprites/player_idle/dir_3_0028.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0029.png-daf87e63081f9c0a54447006bd2209b6.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0029.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0030.png-e0daaf8466b78886ee3c4d6a13c77a88.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0030.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0031.png-79dd733b6f4796896ee4754093cbf574.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0031.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0032.png-673d415399e336f57767622876a059cc.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0032.png.import
	savepack: step 53: Storing File: res://.godot/imported/dir_3_0033.png-351ed26bf049f1c9f5b8f63b48fdc540.ctex
	savepack: step 53: Storing File: res://sprites/player_idle/dir_3_0033.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0034.png-bf45ccd5b8ecb2498520ba55ea8fca90.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0034.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0035.png-4129cce2cdd07ba02d5c20ca4c246a11.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0035.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0036.png-abf04b2b00fe88fdd23ad0bea5df2f99.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0036.png.import
	savepack: step 54: Storing File: res://.godot/imported/dir_3_0037.png-751d3c8b75838e4c057b69baa189a6fb.ctex
	savepack: step 54: Storing File: res://sprites/player_idle/dir_3_0037.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0038.png-8a31cb5390a0d5e3a37469e403fc9ea0.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0038.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0039.png-360cb8e786195be9e7dfb3c3a41fae55.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0039.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0040.png-4668837ad40cd17338f2a3a499a99944.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0040.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0041.png-4ede56ee72e588a4885b2b8d46d20b13.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0041.png.import
	savepack: step 55: Storing File: res://.godot/imported/dir_3_0042.png-3f2669e912059103f59dd7cbdf921b09.ctex
	savepack: step 55: Storing File: res://sprites/player_idle/dir_3_0042.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0043.png-cf5aae44be164daae0adafb255e53c3a.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0043.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0044.png-8171ad75fd9c98d5eb123b4fcc2fe1d0.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0044.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_3_0045.png-739fee3a1c4268b262bce228f3c25540.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_3_0045.png.import
	savepack: step 56: Storing File: res://.godot/imported/dir_4_0001.png-44c0140589c9477c53e693ca422a610f.ctex
	savepack: step 56: Storing File: res://sprites/player_idle/dir_4_0001.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_4_0002.png-03e83ca13844bf120ff9f33592cabb55.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_4_0002.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_4_0003.png-5a067b1ce8c2abce9d265d1085006aa2.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_4_0003.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_4_0004.png-3e737cb0da6ac2bbf67f17e9de4541da.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_4_0004.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_4_0005.png-50ca1e2ace0ad812aa8e4658e5fbc49b.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_4_0005.png.import
	savepack: step 57: Storing File: res://.godot/imported/dir_4_0006.png-cbaebc60f655a63514a9ee42bbe601a8.ctex
	savepack: step 57: Storing File: res://sprites/player_idle/dir_4_0006.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_4_0007.png-9b4fde0a646fd92a84a198f3308e7f9c.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_4_0007.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_4_0008.png-914cc8543e9f50ced206fb184b891a30.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_4_0008.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_4_0009.png-f906857f39f7c9499bf866179301a8fa.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_4_0009.png.import
	savepack: step 58: Storing File: res://.godot/imported/dir_4_0010.png-e5aea61231082aa35a21f40f2712ec09.ctex
	savepack: step 58: Storing File: res://sprites/player_idle/dir_4_0010.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0011.png-046e49dffaa400aa7376d9ab1b6427b9.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0011.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0012.png-fd1244d2744d4afcec69891ea22bf3ef.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0012.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0013.png-7b2b287a5acb0f329ec30bd468e72c1b.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0013.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0014.png-a86ccdbf773101b21bcc3797b678b648.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0014.png.import
	savepack: step 59: Storing File: res://.godot/imported/dir_4_0015.png-b58405815ea0731a85856890e866e793.ctex
	savepack: step 59: Storing File: res://sprites/player_idle/dir_4_0015.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0016.png-81e83a46d052604fb757f7c0412bfeb0.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0016.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0017.png-39333cb64f3c2877e9b4b20f86f02771.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0017.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0018.png-4003cb82bd9d789910f6f8d31a8bec48.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0018.png.import
	savepack: step 60: Storing File: res://.godot/imported/dir_4_0019.png-dead4a6a63153cb0b9b7931f5ae678ed.ctex
	savepack: step 60: Storing File: res://sprites/player_idle/dir_4_0019.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0020.png-71b2b2ce20e8fbab8b36a7ca71ba801c.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0020.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0021.png-ec51ee3073d172fbdb1752fe73b64753.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0021.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0022.png-c9d441a84209b2fd15a00faa56fb1251.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0022.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0023.png-2ce81c611a182118a20d5505faf43e96.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0023.png.import
	savepack: step 61: Storing File: res://.godot/imported/dir_4_0024.png-8de87e72e639b46d062c45e528d5ca76.ctex
	savepack: step 61: Storing File: res://sprites/player_idle/dir_4_0024.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0025.png-0c9d69a0d7dd65f8c19b5d14c8c9e938.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0025.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0026.png-b4078c194745d66f3f8b16c33db101ba.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0026.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0027.png-a0e8070b2a4b990a2fa3970d09ed07df.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0027.png.import
	savepack: step 62: Storing File: res://.godot/imported/dir_4_0028.png-81d472d161be45c7797b5fbf138424a3.ctex
	savepack: step 62: Storing File: res://sprites/player_idle/dir_4_0028.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0029.png-89b8cb45ca54fce7e0b0a4345dd77e09.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0029.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0030.png-a4ea7e588e4207342eab45b6bece9b09.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0030.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0031.png-56f62fd7bf021bdf915f7a99d49c25d4.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0031.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0032.png-a02734f8bdb2a9ad41fa7f5b015afc87.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0032.png.import
	savepack: step 63: Storing File: res://.godot/imported/dir_4_0033.png-6d81174d22f2c4d14bcd6a92aedafe5c.ctex
	savepack: step 63: Storing File: res://sprites/player_idle/dir_4_0033.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0034.png-65e08bf7b6548c7094aa67e59f0be8be.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0034.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0035.png-be32669bf98db3b34e6df6590b21a192.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0035.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0036.png-0d1a5b53a63e57bd8542ccb7f3bb3f64.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0036.png.import
	savepack: step 64: Storing File: res://.godot/imported/dir_4_0037.png-f3e55a4dc2b84a975bbdeb291c52bf65.ctex
	savepack: step 64: Storing File: res://sprites/player_idle/dir_4_0037.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0038.png-4a5bd9cfd14b5deedd060279575f5aef.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0038.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0039.png-c90075c8d1b9a00ed5bb2713007533a9.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0039.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0040.png-1bb4300271bd8cde60ac4bf231cad3f8.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0040.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0041.png-24f218bb887697ebff8afbc939c66102.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0041.png.import
	savepack: step 65: Storing File: res://.godot/imported/dir_4_0042.png-32f0cb46cb07386daf5336ede400072f.ctex
	savepack: step 65: Storing File: res://sprites/player_idle/dir_4_0042.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0043.png-c29414dfe98a0fffa05aa08c80b5a047.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0043.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0044.png-267944e3e6bc3dffcd6632d486270177.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0044.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_4_0045.png-7d4f63980d87410e0f5f75d6fcd7980f.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_4_0045.png.import
	savepack: step 66: Storing File: res://.godot/imported/dir_5_0001.png-54ecb67a3b64ef53b95f38cfcaab5d7e.ctex
	savepack: step 66: Storing File: res://sprites/player_idle/dir_5_0001.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_5_0002.png-4be9ff92bf6613ac5f0532ee594c9f8d.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_5_0002.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_5_0003.png-02ae3ecccec6854388104446a5cce060.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_5_0003.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_5_0004.png-78f400ba5159020d0cc327fb7751626b.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_5_0004.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_5_0005.png-a61599f3a6912253a4ee8a46f2179ee0.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_5_0005.png.import
	savepack: step 67: Storing File: res://.godot/imported/dir_5_0006.png-a7a9166dcc80e53082039570e987d60e.ctex
	savepack: step 67: Storing File: res://sprites/player_idle/dir_5_0006.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_5_0007.png-97719fa861936e98f05b1c47c7437edb.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_5_0007.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_5_0008.png-bfa0a41e9582b4220810342faa17048b.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_5_0008.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_5_0009.png-222b7f2c0ba311d0eb36c49e18d4fac0.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_5_0009.png.import
	savepack: step 68: Storing File: res://.godot/imported/dir_5_0010.png-a0a53aaa4f0d1e1d0b151c9561284562.ctex
	savepack: step 68: Storing File: res://sprites/player_idle/dir_5_0010.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_5_0011.png-718b2daecc82a6b8e27bafe5e48aeeda.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_5_0011.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_5_0012.png-0165b583c3cf87032ff35631b2e3e95a.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_5_0012.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_5_0013.png-838fe2b9da91889799d90ec54c4cc969.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_5_0013.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_5_0014.png-d8663fd1c9ebf299c93e7dc67e26f95f.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_5_0014.png.import
	savepack: step 69: Storing File: res://.godot/imported/dir_5_0015.png-2100f509d345cd07461664ab3eaa81dd.ctex
	savepack: step 69: Storing File: res://sprites/player_idle/dir_5_0015.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0016.png-226901d9b28cf7df2decd0451326d75c.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0016.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0017.png-dfd5420cd9b200935c84bf0f4cac4ab0.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0017.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0018.png-aa2e5c55ce7ff835a3ea1c42d9837741.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0018.png.import
	savepack: step 70: Storing File: res://.godot/imported/dir_5_0019.png-a943751b68884dfc46fbb0c2c0d5178b.ctex
	savepack: step 70: Storing File: res://sprites/player_idle/dir_5_0019.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0020.png-3584c763a7727de0c392a8c618354c88.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0020.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0021.png-79793cf9cbb8fe9c5c92a8a8c186c165.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0021.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0022.png-ea8d8f9eacfcc6ad60cf0eac8f76bb2d.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0022.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0023.png-f2938d845123450a87fd6be27d904951.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0023.png.import
	savepack: step 71: Storing File: res://.godot/imported/dir_5_0024.png-a231cbffffd158111eb4a45e6c9494ab.ctex
	savepack: step 71: Storing File: res://sprites/player_idle/dir_5_0024.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0025.png-fe9f38a76a4fcb7b388729392facaaf2.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0025.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0026.png-e8934ff24161fe66919d3f09ded05027.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0026.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0027.png-26da75d75afe8b79255c43e3d8e08e98.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0027.png.import
	savepack: step 72: Storing File: res://.godot/imported/dir_5_0028.png-d694010607039d58c26ddbd9f48585be.ctex
	savepack: step 72: Storing File: res://sprites/player_idle/dir_5_0028.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0029.png-800bbbc0a1f0dae81fe7ae5f7e27f370.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0029.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0030.png-7b64c82c5a0463a9b47161a4935e60ce.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0030.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0031.png-acfc1df8e7d5e6d193dfc8220f1db0ee.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0031.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0032.png-423371a1636bc3f76ff44be178654e40.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0032.png.import
	savepack: step 73: Storing File: res://.godot/imported/dir_5_0033.png-78216bae1d9c00088dcc3233e62ca4db.ctex
	savepack: step 73: Storing File: res://sprites/player_idle/dir_5_0033.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0034.png-34a0b317ec360b1b06a2262b63ffae14.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0034.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0035.png-62cf4a4fa40fc11ae23842db81261d48.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0035.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0036.png-38c419c3886c9f73785214229b1e5e8a.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0036.png.import
	savepack: step 74: Storing File: res://.godot/imported/dir_5_0037.png-70052c6484a98cf0e42ae14e7c15da95.ctex
	savepack: step 74: Storing File: res://sprites/player_idle/dir_5_0037.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0038.png-c0bf8c173fa4868b88096fb5ef6cd786.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0038.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0039.png-976536a45ab5477c7df7d1c99b776380.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0039.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0040.png-ba9bce1718013b82ef4d19d9b0f1c763.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0040.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0041.png-46f91cd851a5f818c5a02091783f1be4.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0041.png.import
	savepack: step 75: Storing File: res://.godot/imported/dir_5_0042.png-02de82baf6bddc7ed4ba0f7cb97fcc55.ctex
	savepack: step 75: Storing File: res://sprites/player_idle/dir_5_0042.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0043.png-c35a6a6a429dcfc7d718438169e5de18.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0043.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0044.png-ce3e123d0b3626a753b875112d502854.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0044.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_5_0045.png-6852b5c6ea7d3ebfd8e76ca923623c0e.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_5_0045.png.import
	savepack: step 76: Storing File: res://.godot/imported/dir_6_0001.png-305ad0570c16badf494841e57f4ba611.ctex
	savepack: step 76: Storing File: res://sprites/player_idle/dir_6_0001.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_6_0002.png-22826ad2b1480d94ac49569140300b7d.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_6_0002.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_6_0003.png-2ddfab84d846eea12800d2ae3258d124.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_6_0003.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_6_0004.png-198bf0b806aed2f6d3c931a62777c72b.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_6_0004.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_6_0005.png-2843d807360986b608946b90e888010b.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_6_0005.png.import
	savepack: step 77: Storing File: res://.godot/imported/dir_6_0006.png-3e9d956ac832e00cd3c5c5e88b3ed985.ctex
	savepack: step 77: Storing File: res://sprites/player_idle/dir_6_0006.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_6_0007.png-5d37f95317537321949f3aa1b3bdaec5.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_6_0007.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_6_0008.png-5e47c714d8975acee8a61f03c7e1c8a8.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_6_0008.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_6_0009.png-a5ff6975ef9d035dc44e9369a7633b7b.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_6_0009.png.import
	savepack: step 78: Storing File: res://.godot/imported/dir_6_0010.png-18fefd47204b86c43402b80449215e5d.ctex
	savepack: step 78: Storing File: res://sprites/player_idle/dir_6_0010.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_6_0011.png-403f81f4712d87a6fc7bc293abfe951c.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_6_0011.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_6_0012.png-7a43de7f34962670014e2fa8cf58bdbd.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_6_0012.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_6_0013.png-6997758c5a879c6dfebd9bf83fb80b19.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_6_0013.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_6_0014.png-cded909ae25b702d64c05cd7ae0d2f13.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_6_0014.png.import
	savepack: step 79: Storing File: res://.godot/imported/dir_6_0015.png-66aeb5bd0bc542fc175fec55a3bf6087.ctex
	savepack: step 79: Storing File: res://sprites/player_idle/dir_6_0015.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0016.png-b938bf7a70c22eb9d70fcaf577311100.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0016.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0017.png-176b7f93ffdda965c54bdd0eb9326d9b.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0017.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0018.png-f92b96743b8714dcbaf521b80eafbf3f.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0018.png.import
	savepack: step 80: Storing File: res://.godot/imported/dir_6_0019.png-5761e61793846e110d7703fd46cae4d4.ctex
	savepack: step 80: Storing File: res://sprites/player_idle/dir_6_0019.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0020.png-8a75df3dc801931a2f4c8ace65113319.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0020.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0021.png-9a33865f02a031907cbfe0e27fd35f00.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0021.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0022.png-3e67df7c6e0a065b498d39b0c08b0312.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0022.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0023.png-7f64aa280564aebe45e5dc0d8d9d5c16.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0023.png.import
	savepack: step 81: Storing File: res://.godot/imported/dir_6_0024.png-88f09f26e628d7d315ce59732ccc2834.ctex
	savepack: step 81: Storing File: res://sprites/player_idle/dir_6_0024.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0025.png-0b3af2fa1d2cbbfd99d4ee002fb12840.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0025.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0026.png-021f4a1a723c8d54576610d04d7fd57f.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0026.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0027.png-44e3d8b5ff0f346c8104b4032f560f71.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0027.png.import
	savepack: step 82: Storing File: res://.godot/imported/dir_6_0028.png-1105d75f85506ccc5746fbd864b24fff.ctex
	savepack: step 82: Storing File: res://sprites/player_idle/dir_6_0028.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0029.png-e4b4caed37291002953d56f4ca4131ab.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0029.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0030.png-61625df132dbbd128d4e1f75e75aabfc.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0030.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0031.png-d749cc2494f059267e4e7df5116e8622.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0031.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0032.png-71a30f79d5da9c1b438f22b398b5dab1.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0032.png.import
	savepack: step 83: Storing File: res://.godot/imported/dir_6_0033.png-1581d03ab3875a38a17e89ed97f9e4b7.ctex
	savepack: step 83: Storing File: res://sprites/player_idle/dir_6_0033.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0034.png-901410a3b9a1123e4fe9c6c067e84996.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0034.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0035.png-0ca73a5099e5ee470642737d3d349212.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0035.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0036.png-74212616df9d8d718bb761f75646bcc1.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0036.png.import
	savepack: step 84: Storing File: res://.godot/imported/dir_6_0037.png-b8f3cd7f00d11e1738def20ba138ad31.ctex
	savepack: step 84: Storing File: res://sprites/player_idle/dir_6_0037.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0038.png-de4b8fd9a432a6d0cb6d62a70779f107.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0038.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0039.png-30fe4a5d0248c94f51c386de6818aab0.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0039.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0040.png-01c5d066ea63da2b2939414aab6b7897.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0040.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0041.png-36d9495a377e03e36d424fd98695a054.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0041.png.import
	savepack: step 85: Storing File: res://.godot/imported/dir_6_0042.png-0d3be26f076a11fe04aa48150607f766.ctex
	savepack: step 85: Storing File: res://sprites/player_idle/dir_6_0042.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0043.png-b9f2da0ea4ca216970722097f128bbd1.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0043.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0044.png-3f84695fc07f7b738486280eb5603000.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0044.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_6_0045.png-deb75272ecbeaf94c9d8a660d7c0ac85.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_6_0045.png.import
	savepack: step 86: Storing File: res://.godot/imported/dir_7_0001.png-f56163f66408f9b4868c963b7ccdc888.ctex
	savepack: step 86: Storing File: res://sprites/player_idle/dir_7_0001.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_7_0002.png-c0fe11e0a41fb3e172cad384ea0d6fdb.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_7_0002.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_7_0003.png-80353ff236d3b9e9529d95b234901c2f.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_7_0003.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_7_0004.png-f17b8c72db6c5a5555c1e058a4fdb37d.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_7_0004.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_7_0005.png-9b495c651b85e4394c7278ed9117f507.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_7_0005.png.import
	savepack: step 87: Storing File: res://.godot/imported/dir_7_0006.png-b55337d24f1991722d24974127890164.ctex
	savepack: step 87: Storing File: res://sprites/player_idle/dir_7_0006.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_7_0007.png-3f74fdb57cdfb5cf92632111c7c47353.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_7_0007.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_7_0008.png-14fff645fc469a9ca37da44571c8bf40.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_7_0008.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_7_0009.png-44a989bb4ef8aec21b41ccf787b8ad79.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_7_0009.png.import
	savepack: step 88: Storing File: res://.godot/imported/dir_7_0010.png-f8b6efa1bc0fdde4984d18d79ab2b87a.ctex
	savepack: step 88: Storing File: res://sprites/player_idle/dir_7_0010.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_7_0011.png-8d079e563451cb648d05f12fcd83410e.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_7_0011.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_7_0012.png-c481686c32eb52fd6fd4412c6d7b4b4e.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_7_0012.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_7_0013.png-230ea27940975966523df263c58504ff.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_7_0013.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_7_0014.png-cd9b475b011d51a12b5035e2f55c89a4.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_7_0014.png.import
	savepack: step 89: Storing File: res://.godot/imported/dir_7_0015.png-6462d0a0c363f5a418682bbd99cfee9f.ctex
	savepack: step 89: Storing File: res://sprites/player_idle/dir_7_0015.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_7_0016.png-1e525788b0aecb2c77f9c99b2c6e7961.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_7_0016.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_7_0017.png-fc1fb54f89a66e7672a3dea4977bf5dd.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_7_0017.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_7_0018.png-ab4b697f5439f7562d6495d6ca1b21c2.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_7_0018.png.import
	savepack: step 90: Storing File: res://.godot/imported/dir_7_0019.png-d6adf250f69ca718c20f2b6f1e1dab8b.ctex
	savepack: step 90: Storing File: res://sprites/player_idle/dir_7_0019.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0020.png-13e81bed771a378dd92fe3e44a5dcae9.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0020.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0021.png-95025a26723093c478b81f9159680c72.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0021.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0022.png-7119dbcacfdc1fbeea0a4908fde2ad4c.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0022.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0023.png-42911aed0fd1e7b00c59d14e1d3bd2ec.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0023.png.import
	savepack: step 91: Storing File: res://.godot/imported/dir_7_0024.png-cd0313892fa0271db3530d704b558c3a.ctex
	savepack: step 91: Storing File: res://sprites/player_idle/dir_7_0024.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0025.png-e837b778cf6654dccb6e1c3cac343e06.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0025.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0026.png-c14e9001cf3dbffbd89121685a29876b.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0026.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0027.png-410a93b758978f6107af16ca2265aaca.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0027.png.import
	savepack: step 92: Storing File: res://.godot/imported/dir_7_0028.png-f441389b1b2984eba015ff3018824976.ctex
	savepack: step 92: Storing File: res://sprites/player_idle/dir_7_0028.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0029.png-37b4c07a4c3f14a34495ee55687869f8.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0029.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0030.png-ef549d8584817425a792f64d53b357de.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0030.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0031.png-368fd541b5b5219ce5724ebf77b504e3.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0031.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0032.png-5862cafb570810c768df0659dbd21c86.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0032.png.import
	savepack: step 93: Storing File: res://.godot/imported/dir_7_0033.png-04b92d5998216baaca5ce78bc7e2b0ab.ctex
	savepack: step 93: Storing File: res://sprites/player_idle/dir_7_0033.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0034.png-f360fbba45604b91d35ca2106e17547f.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0034.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0035.png-ab41dcabc7044bd63709f874ba63d42f.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0035.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0036.png-e59c70a78b8e861cb280f41a3eb39067.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0036.png.import
	savepack: step 94: Storing File: res://.godot/imported/dir_7_0037.png-ac4072e6541b8df202a43dea56e7cd67.ctex
	savepack: step 94: Storing File: res://sprites/player_idle/dir_7_0037.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0038.png-42cd164980ead0a5b2376797057244a2.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0038.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0039.png-7c2343a6c86942135313d0c4bc4f414e.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0039.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0040.png-5312afda3741127ce8a70bfb88de9549.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0040.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0041.png-9b4ca50bea3cbd33520b6451fc976146.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0041.png.import
	savepack: step 95: Storing File: res://.godot/imported/dir_7_0042.png-435fab965479c665ead6209978a0e5fc.ctex
	savepack: step 95: Storing File: res://sprites/player_idle/dir_7_0042.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0043.png-5bf45588c7753e97799660453a66348f.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0043.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0044.png-e710ee96e2dd522844ed77edfeac0918.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0044.png.import
	savepack: step 96: Storing File: res://.godot/imported/dir_7_0045.png-9b82aafad83a15cdf5250f678768e4c3.ctex
	savepack: step 96: Storing File: res://sprites/player_idle/dir_7_0045.png.import
	savepack: step 96: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d386ad401674f18d1edfd264d67ce020.scn
	savepack: step 96: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
	savepack: step 97: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-8f735e678b86df73bf8978d10c629e6f.s3tc.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
	savepack: step 97: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-8122c1ec715bcbe34a4661682b54b4c3.s3tc.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
	savepack: step 97: Storing File: res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-e909b100dc6bbda0c7e19c5e6c81bef1.s3tc.ctex
	savepack: step 97: Storing File: res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
	savepack: step 97: Storing File: res://tests/_test_util.gd
	savepack: step 97: Storing File: res://tests/test_3d_player.gd
	savepack: step 98: Storing File: res://tests/test_5_systems.gd
	savepack: step 98: Storing File: res://tests/test_candy_pickup.gd
	savepack: step 98: Storing File: res://tests/test_critical_path.gd
	savepack: step 98: Storing File: res://tests/test_cursor_aiming.gd
	savepack: step 99: Storing File: res://tests/test_encounters.gd
	savepack: step 99: Storing File: res://tests/test_feel_combat.gd
	savepack: step 99: Storing File: res://tests/test_feel_movement.gd
	savepack: step 99: Storing File: res://tests/test_feel_traversal.gd
	savepack: step 99: Storing File: res://tests/test_flamethrower_particles.gd
	savepack: step 100: Storing File: res://tests/test_gameplay_fixes.gd
	savepack: step 100: Storing File: res://tests/test_grinding.gd
	savepack: step 100: Storing File: res://tests/test_menu_flow.gd
	savepack: step 100: Storing File: res://tests/test_onboarding.gd
	savepack: step 101: Storing File: res://tests/test_presentation.gd
	savepack: step 101: Storing File: res://tests/test_slice_e2e.gd
	savepack: step 101: Storing File: res://tests/test_systems.gd
	savepack: step 101: Storing File: res://tests/test_tapes.gd
	savepack: step 101: Storing File: res://scenes/dial_up_queen.tscn.remap
	savepack: step 101: Storing File: res://scenes/FloodedMall_Greybox.tscn.remap
	savepack: step 101: Storing File: res://scenes/health_candy_pickup.tscn.remap
	savepack: step 101: Storing File: res://scenes/intro.tscn.remap
	savepack: step 101: Storing File: res://scenes/main_menu.tscn.remap
	savepack: step 101: Storing File: res://scenes/neon_cicada.tscn.remap
	savepack: step 101: Storing File: res://scenes/player.tscn.remap
	savepack: step 101: Storing File: res://.godot/global_script_class_cache.cfg
	savepack: step 101: Storing File: res://icon.svg
	savepack: step 101: Storing File: res://.godot/uid_cache.bin
	savepack: step 101: Storing File: res://.godot/extension_list.cfg
	savepack: step 101: Storing File: res://project.binary
savepack: end

EXIT: 0 (qa)
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\Godot_v4.3-stable_win64.exe --version
4.3.stable.official.77dcf97d8

EXIT: 0 (version)
FILES: build/release (bytes)
199  build\release\BUILD-INFO.txt
679424  build\release\libbiopunk.windows.template_release.x86_64.dll
686  build\release\MUSIC-CREDITS.txt
185856  build\release\Y2K-BioPunk.console.exe
84214784  build\release\Y2K-BioPunk.exe
413893440  build\release\Y2K-BioPunk.pck
FILES: build/qa (bytes)
772096  build\qa\libbiopunk.windows.template_debug.x86_64.dll
185856  build\qa\Y2K-BioPunk-QA.console.exe
84108800  build\qa\Y2K-BioPunk-QA.exe
413800432  build\qa\Y2K-BioPunk-QA.pck
ZIP: 391306865 bytes  C:\y2k-biopunk-rpg\.worktrees\vs11export\build\Y2K-BioPunk-VS1.1-win64.zip
BUILD: PASS

```

Script exit code: `0`.

## First packaged smoke: checkpoint assertion failure (exit 1)

Command from the assigned worktree:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops/tools/smoke_packaged.ps1
```

Complete stdout/stderr captured with `*> ops/runs/export/smoke_packaged.full.log` (line endings normalized for Markdown):

```text
Worktree: C:\y2k-biopunk-rpg\.worktrees\vs11export
Logs: C:\y2k-biopunk-rpg\.worktrees\vs11export\ops\runs\export\smoke_20261008_133930
PCK: C:\y2k-biopunk-rpg\.worktrees\vs11export\build\release\Y2K-BioPunk.pck (Godot 4.3.0, 854 entries)
RELEASE PCK DIRECTORY (bytes, resource path):
7074  res://.godot/exported/133200997/export-234fb6894ec6226e856ab7f825500d3d-player.scn
719  res://.godot/exported/133200997/export-72ee11ce23100f2096d10891190f557e-dial_up_queen.scn
1660  res://.godot/exported/133200997/export-aa3f5c97579d5c748215bbb2e364ddeb-intro.scn
650  res://.godot/exported/133200997/export-d9b46989ff26b563f7686f0a6c74ef08-health_candy_pickup.scn
4456  res://.godot/exported/133200997/export-e098924b008c7d9e49d8e825c974b95b-neon_cicada.scn
3404  res://.godot/exported/133200997/export-ea5c6ad4629af728dc514cefde332394-main_menu.scn
801079  res://.godot/exported/133200997/export-f257e87bfdc9f628dcc382c88547a250-FloodedMall_Greybox.scn
26  res://.godot/extension_list.cfg
827  res://.godot/global_script_class_cache.cfg
4285267  res://.godot/imported/anthem.mp3-2f7a92cf245df82890b7830193e2bea6.mp3str
4096559  res://.godot/imported/bigbeat.mp3-719a317dfac214297f4d640840ee7874.mp3str
4284015  res://.godot/imported/bubblegum.mp3-6600d7a64ddbbec66a2b18480a79e0ad.mp3str
3829483  res://.godot/imported/combat.mp3-1829eebac0ee46487ae84a3be83a352e.mp3str
23329773  res://.godot/imported/dial_up_queen.glb-c1a5cb2f8ad5373c4dcab5634b6375c1.scn
27146  res://.godot/imported/dir_0_0001.png-b710fbec88935683feaa9ce80bb168b5.ctex
27590  res://.godot/imported/dir_0_0002.png-0e5a2de3b5fd5d28ce436b421d055443.ctex
27558  res://.godot/imported/dir_0_0003.png-9b15b799a24f9fbfe900e8481215af28.ctex
27442  res://.godot/imported/dir_0_0004.png-7a93f1ab1179b0e965dc3faf9d34a601.ctex
27502  res://.godot/imported/dir_0_0005.png-a93eefa81d5de8b3df0e3a3ffa5a5a96.ctex
27394  res://.godot/imported/dir_0_0006.png-31078175cbbcda22f61172097a8379ef.ctex
27170  res://.godot/imported/dir_0_0007.png-5b49c7f21f56fa1f374a7643c4fa7f67.ctex
26722  res://.godot/imported/dir_0_0008.png-6d3590e2a1ac045c506836477d5759a0.ctex
26450  res://.godot/imported/dir_0_0009.png-14ae05c6400d3b747b38851b3f005a58.ctex
25718  res://.godot/imported/dir_0_0010.png-0d358bb0ba4f5b17b4fd2db4c1db63a0.ctex
25372  res://.godot/imported/dir_0_0011.png-66f8d32db6bd94489fa6462c63bb9e25.ctex
25006  res://.godot/imported/dir_0_0012.png-9af3e2a6a8140f68ca9c52822981ac4f.ctex
24660  res://.godot/imported/dir_0_0013.png-2c3132152db14b63df2020e769510265.ctex
24590  res://.godot/imported/dir_0_0014.png-9bee12fb872d8c3f8b14f8dc83a2e723.ctex
24060  res://.godot/imported/dir_0_0015.png-bf3931a65824eda506dac5cb70f66061.ctex
23998  res://.godot/imported/dir_0_0016.png-d5ef184284aa8dfbfa436acbd30ff617.ctex
24154  res://.godot/imported/dir_0_0017.png-95408049edb1e06eeca6a0623d844741.ctex
24288  res://.godot/imported/dir_0_0018.png-04ff2164a4e8823a45d760cb0f8c924c.ctex
24448  res://.godot/imported/dir_0_0019.png-bdf2ece8fc4b7d7339b68d8e3078e42d.ctex
24836  res://.godot/imported/dir_0_0020.png-5dafb0540cece6243250ba9fe2abcf9d.ctex
24480  res://.godot/imported/dir_0_0021.png-26b13f13a12aab931dc5a165ba2449d7.ctex
24346  res://.godot/imported/dir_0_0022.png-b7a7bcfe420d7715d19a0ab6614317de.ctex
23994  res://.godot/imported/dir_0_0023.png-323c1720fd734f8d4c3011866b334eaf.ctex
23572  res://.godot/imported/dir_0_0024.png-d2c8f2e1d387e065f473c9c433f9ddb7.ctex
22964  res://.godot/imported/dir_0_0025.png-1c40f3a80700734d053d96815854dfc0.ctex
22604  res://.godot/imported/dir_0_0026.png-c19f0c040198da8b7f9ee5df795757c2.ctex
22184  res://.godot/imported/dir_0_0027.png-ea9f0ee81748d1e693a28067922f5d2e.ctex
21812  res://.godot/imported/dir_0_0028.png-e24290a9e623664b03ab27acfb2650df.ctex
20952  res://.godot/imported/dir_0_0029.png-a3c0a06ce660b5e7c165b81610c54676.ctex
20484  res://.godot/imported/dir_0_0030.png-f6c9eac873d6fd0dbdc288b0fb569357.ctex
20116  res://.godot/imported/dir_0_0031.png-310e4fd4a08c8100e154b74c903283b5.ctex
19888  res://.godot/imported/dir_0_0032.png-f278b23644ae1ce5327c8b2c0b039452.ctex
19498  res://.godot/imported/dir_0_0033.png-cdb93ffb1ecb703add4499597912f067.ctex
19494  res://.godot/imported/dir_0_0034.png-fe43b2e0f994d038860628fea7c4f1d5.ctex
19150  res://.godot/imported/dir_0_0035.png-f4fa13aed07d11601dfd153b5d5242bf.ctex
19230  res://.godot/imported/dir_0_0036.png-bffcb23fb884cd6d25a3ac3a0412b507.ctex
19088  res://.godot/imported/dir_0_0037.png-68914dedfaad711accc4409744a56e4d.ctex
18848  res://.godot/imported/dir_0_0038.png-1dab661763c48455fedaf2e96dd5a07a.ctex
18572  res://.godot/imported/dir_0_0039.png-7032a0cb4ab60b64402bf0c907e4ca54.ctex
18246  res://.godot/imported/dir_0_0040.png-302ba8cb31466cb6ea3dc8dc997b3c57.ctex
17904  res://.godot/imported/dir_0_0041.png-2c61cdb0875d6e6575cbc0df76d37a17.ctex
17728  res://.godot/imported/dir_0_0042.png-6659fdb2494734652654c028ea5087fc.ctex
17474  res://.godot/imported/dir_0_0043.png-0c7e915e718028acacfedaad679e0227.ctex
17166  res://.godot/imported/dir_0_0044.png-01e3e2dc516f2dcdf7b4aa7a81620deb.ctex
17166  res://.godot/imported/dir_0_0045.png-2c2a1680b70e12826afc1b2b3b9e29b7.ctex
25076  res://.godot/imported/dir_1_0001.png-bdb495a9757bdad6797f07eb8555971a.ctex
25298  res://.godot/imported/dir_1_0002.png-934840a768165d77186589af676f8a4e.ctex
25700  res://.godot/imported/dir_1_0003.png-050f68e9fff75da7614b94ff90773eed.ctex
25726  res://.godot/imported/dir_1_0004.png-ebd21421acf611af84f966b5091ce26b.ctex
25936  res://.godot/imported/dir_1_0005.png-555a0784cf791c3641ccbc1c5990fb87.ctex
26268  res://.godot/imported/dir_1_0006.png-ca0673a91afce76bf8874c74463838f1.ctex
26242  res://.godot/imported/dir_1_0007.png-1214b7a104d06df3c3d497bcd1be1834.ctex
26258  res://.godot/imported/dir_1_0008.png-f8a89ef405120ae9a8bf879e19cdfa97.ctex
26288  res://.godot/imported/dir_1_0009.png-5dcfbd387d83e1ba7227231c891d949a.ctex
26154  res://.godot/imported/dir_1_0010.png-f87d76a8175e6446982bab4d7d54ea61.ctex
25972  res://.godot/imported/dir_1_0011.png-0337dba63b70dc413b74a06679b6f28c.ctex
25806  res://.godot/imported/dir_1_0012.png-03f5f787850b85bee05c351073002118.ctex
25188  res://.godot/imported/dir_1_0013.png-b30021586e7c63704890c71eb3a782d9.ctex
25106  res://.godot/imported/dir_1_0014.png-1564734f8bb6b3ba6603a743ca7f2575.ctex
25042  res://.godot/imported/dir_1_0015.png-e710f55eee5b4c83238640df6bd82846.ctex
24812  res://.godot/imported/dir_1_0016.png-0b030e77519508ff1c669f94a1909f94.ctex
24342  res://.godot/imported/dir_1_0017.png-e82a6bdd5771e6423a06a0f7342f6e3b.ctex
23636  res://.godot/imported/dir_1_0018.png-522091f455426a018d858f5e03c2ab2e.ctex
23752  res://.godot/imported/dir_1_0019.png-58201ff8f09e92ec1da1b349fe68db5b.ctex
23314  res://.godot/imported/dir_1_0020.png-594e00db2708c2beb29bc93b558dacc3.ctex
22698  res://.godot/imported/dir_1_0021.png-074a2e39d733763b37f5b5023df8dfa2.ctex
22370  res://.godot/imported/dir_1_0022.png-b8945aba745c3588278faeaf7e1419d4.ctex
22588  res://.godot/imported/dir_1_0023.png-5574c663a5fd93f4f03c7eb49828e01a.ctex
22156  res://.godot/imported/dir_1_0024.png-60b1a3cd41d1449cc00f64ac3a3f2024.ctex
21602  res://.godot/imported/dir_1_0025.png-fb4f2085498167f038dea4b9ec1c2279.ctex
20740  res://.godot/imported/dir_1_0026.png-3265acf35ac991ca8f99d9158ac0c1ec.ctex
20388  res://.godot/imported/dir_1_0027.png-3418243241bb87f5dc647a772a0efb43.ctex
20454  res://.godot/imported/dir_1_0028.png-ee04ca2d0c1aec65325fa925b01c7b1f.ctex
20214  res://.godot/imported/dir_1_0029.png-b38794b7bc2ffad1ed4ba99b92cc7227.ctex
19534  res://.godot/imported/dir_1_0030.png-671d0253c720699f7c3aa085a63e2a5b.ctex
19374  res://.godot/imported/dir_1_0031.png-89b3713d6f7838cee10dd042401d3fad.ctex
18898  res://.godot/imported/dir_1_0032.png-2593f66ac31520f96e7fa30959a43e91.ctex
18198  res://.godot/imported/dir_1_0033.png-f661de841ee888883396bbe72741b344.ctex
17952  res://.godot/imported/dir_1_0034.png-dec28c10562b756dfd86ca58b3e77c40.ctex
17310  res://.godot/imported/dir_1_0035.png-1ce258d5745a5fe65a0fd18bfe165fff.ctex
16260  res://.godot/imported/dir_1_0036.png-8b7624a493e1a0760ebb2d1f085a37d6.ctex
15544  res://.godot/imported/dir_1_0037.png-41f34d23b8fa74a0072956b37088e759.ctex
14540  res://.godot/imported/dir_1_0038.png-55a78398a9df364419def19f4ce95af0.ctex
13566  res://.godot/imported/dir_1_0039.png-e7a80ce8f9a02fe1310fe47958fd1d41.ctex
12840  res://.godot/imported/dir_1_0040.png-b787b560ded3a9fa62bdd1b77723786c.ctex
12030  res://.godot/imported/dir_1_0041.png-9690a7eae3341348c1f95f5602be05aa.ctex
11778  res://.godot/imported/dir_1_0042.png-7ebe60fb7dda624362b76375368134dd.ctex
11660  res://.godot/imported/dir_1_0043.png-7d23a42240b59f04fe4b48547e8f6da9.ctex
11430  res://.godot/imported/dir_1_0044.png-0a5dc74966e7dc5eab92fdf6420ea36a.ctex
11430  res://.godot/imported/dir_1_0045.png-612dd05ef6ba543963834c97608a32a8.ctex
20582  res://.godot/imported/dir_2_0001.png-5edef45f93b3c30215829a5f4ee539a5.ctex
21696  res://.godot/imported/dir_2_0002.png-0dc81ff8f64a189a3b647d52dfacf8ea.ctex
22324  res://.godot/imported/dir_2_0003.png-8a0453cc9f955415e5f82c386c9ca46c.ctex
22764  res://.godot/imported/dir_2_0004.png-9ae7dde74db7dd14c7cbe87d30c66b68.ctex
23154  res://.godot/imported/dir_2_0005.png-6f55b2b9c644ef31b21e0dcd11b57ec2.ctex
23834  res://.godot/imported/dir_2_0006.png-2e676cddde54f2d6eb922c7069f62736.ctex
24078  res://.godot/imported/dir_2_0007.png-9474866534e92b9a05921a6d4857067d.ctex
24364  res://.godot/imported/dir_2_0008.png-824cc4850c09bfcbd2d1b0035a43e067.ctex
24160  res://.godot/imported/dir_2_0009.png-2e18df9058df064f6724510b64e7ba78.ctex
24316  res://.godot/imported/dir_2_0010.png-e4b40f869b92e6e9cd7307dc8d05489b.ctex
24408  res://.godot/imported/dir_2_0011.png-3aa009aa9fd5f1d11df53c6ac2f5b5df.ctex
24312  res://.godot/imported/dir_2_0012.png-7c170912d4a612a69a3c4e695f111c5f.ctex
24454  res://.godot/imported/dir_2_0013.png-bc3e7baa32067d83335a4e95cf4b741c.ctex
24422  res://.godot/imported/dir_2_0014.png-3722562c1d091de2a0b91e5cd8349db5.ctex
23910  res://.godot/imported/dir_2_0015.png-f464949052b0da7f6a17637e4b1661f6.ctex
23482  res://.godot/imported/dir_2_0016.png-4843269e6dc01a3544a9e4d926e1241a.ctex
23370  res://.godot/imported/dir_2_0017.png-ff620210c514d0a21957038f3916bd14.ctex
22636  res://.godot/imported/dir_2_0018.png-b36d4042dc59a8aaed3ffdceb402e501.ctex
22132  res://.godot/imported/dir_2_0019.png-e052941f9a25252589d938aa2627df8a.ctex
21498  res://.godot/imported/dir_2_0020.png-6268e8691232161d7624dcca11583e41.ctex
21070  res://.godot/imported/dir_2_0021.png-ed3d2424d7120473fbbadc074f4efd14.ctex
19530  res://.godot/imported/dir_2_0022.png-51a6f3b3e77c867242bc342972c33180.ctex
18506  res://.godot/imported/dir_2_0023.png-3e6859d04911c957f9489557b78b06cc.ctex
18206  res://.godot/imported/dir_2_0024.png-282d8d17bae6c8654d89674f1c32a197.ctex
18000  res://.godot/imported/dir_2_0025.png-ca5226424597c3ac543f265056272ac8.ctex
17240  res://.godot/imported/dir_2_0026.png-9e0d7fbc5fea747e938f546d364ee7ba.ctex
16568  res://.godot/imported/dir_2_0027.png-bc33f42a80a11ec8fe49ef20a0661a9a.ctex
15608  res://.godot/imported/dir_2_0028.png-25176d6154401916dcaa077304511057.ctex
14842  res://.godot/imported/dir_2_0029.png-49975c5c6af211692c84f9679331e1f3.ctex
13986  res://.godot/imported/dir_2_0030.png-56de73700cd6f6aa2936077195517479.ctex
13264  res://.godot/imported/dir_2_0031.png-52aac777105c1cd8f0b3ec0db04482d7.ctex
12542  res://.godot/imported/dir_2_0032.png-ff3d7f88100e92134cab2e7ccc4fd01b.ctex
11552  res://.godot/imported/dir_2_0033.png-e6d5817fff0854bd1857b949c443d2c7.ctex
10262  res://.godot/imported/dir_2_0034.png-5a8afc03d617da4ff4b9f6a9ee630db8.ctex
8604  res://.godot/imported/dir_2_0035.png-aacef661a413cdac61ab7b4b2347df30.ctex
8172  res://.godot/imported/dir_2_0036.png-66afe91228cbd5490fa49e5ea2f0335b.ctex
7564  res://.godot/imported/dir_2_0037.png-1d3c68ac96e6cf31b172295b3de067b5.ctex
6950  res://.godot/imported/dir_2_0038.png-ee2ee22a14ff22dfd3b5a6cde164af77.ctex
6020  res://.godot/imported/dir_2_0039.png-1060b4ca444a509a181dc11dc97444ec.ctex
3580  res://.godot/imported/dir_2_0040.png-fd2865b617e7b9d89d3e9766db0a3840.ctex
3580  res://.godot/imported/dir_2_0041.png-c97812285731470074b9c9e300ef9e65.ctex
3580  res://.godot/imported/dir_2_0042.png-0c39dcba0311b68852dba1f724f4be04.ctex
3580  res://.godot/imported/dir_2_0043.png-bfd2ba0016b2bdec0825f788a31ea897.ctex
3580  res://.godot/imported/dir_2_0044.png-97f3b7371f5b1724ee7d68221d6b1912.ctex
3580  res://.godot/imported/dir_2_0045.png-11acbd16bb764485e7ae2275107db149.ctex
22256  res://.godot/imported/dir_3_0001.png-31fc37a9e42930004808f030423fd577.ctex
22350  res://.godot/imported/dir_3_0002.png-7c1bc4aeb3ff35b537bb53998bf69bab.ctex
21868  res://.godot/imported/dir_3_0003.png-5bf3295a4d9b8284bd0ac673a6309a08.ctex
21594  res://.godot/imported/dir_3_0004.png-5592b0dbe01a20f12ec8618b369c6f52.ctex
21824  res://.godot/imported/dir_3_0005.png-3c1230e43d81597f80567d873c55db13.ctex
21736  res://.godot/imported/dir_3_0006.png-45e84080bfd6afaaa0955b9cd46ff09d.ctex
21760  res://.godot/imported/dir_3_0007.png-8e3503f7074ae3023a0b9b132650b22a.ctex
21972  res://.godot/imported/dir_3_0008.png-26f083538118f1e8b42106e2f6372be2.ctex
22384  res://.godot/imported/dir_3_0009.png-10dbc8517bbc031463f3ae77296f97ad.ctex
22142  res://.godot/imported/dir_3_0010.png-08298348522f60379afec88de95bb2b7.ctex
22132  res://.godot/imported/dir_3_0011.png-5a0bfc0660596d00b1cb8b891fb6fa10.ctex
22234  res://.godot/imported/dir_3_0012.png-ed0ac74b550525819c05e15a362549ef.ctex
22454  res://.godot/imported/dir_3_0013.png-4c02174a68c2dba29376b8c908786c25.ctex
21908  res://.godot/imported/dir_3_0014.png-13ebdda30cc330123a5790ca2a2555f0.ctex
21620  res://.godot/imported/dir_3_0015.png-5fbdce781159aadc35349c5a3bebb91e.ctex
21478  res://.godot/imported/dir_3_0016.png-e9d305e258e9afd8f205c0cac9fc78c3.ctex
21358  res://.godot/imported/dir_3_0017.png-d763659027a5da4cea16ec4fe382345e.ctex
21132  res://.godot/imported/dir_3_0018.png-d82463317106aa660a52a7533094d673.ctex
21106  res://.godot/imported/dir_3_0019.png-eaa1ae0ed50e2f4d68476dbcaa8962e7.ctex
21298  res://.godot/imported/dir_3_0020.png-62f9861f6e2cd96510d4f56c3f351d4b.ctex
21096  res://.godot/imported/dir_3_0021.png-5e787d913618906013f43632d4e23f11.ctex
20624  res://.godot/imported/dir_3_0022.png-4eb98c30c1306ecd14123de3db43457c.ctex
19728  res://.godot/imported/dir_3_0023.png-2ff3ddbdaf2d9b3685fdc173624c3912.ctex
18656  res://.godot/imported/dir_3_0024.png-b1dbed21965ad7787031e26dc7960277.ctex
18368  res://.godot/imported/dir_3_0025.png-17d0c92b90940d326db4bb0a82b3d7a5.ctex
18272  res://.godot/imported/dir_3_0026.png-63facc91904dbd66f32b0a101dc9318d.ctex
18476  res://.godot/imported/dir_3_0027.png-af9d4619028fe1327bae6f2acd8f4601.ctex
18352  res://.godot/imported/dir_3_0028.png-a10c2fc2c81e56539c59dc1ee413394c.ctex
17990  res://.godot/imported/dir_3_0029.png-daf87e63081f9c0a54447006bd2209b6.ctex
17584  res://.godot/imported/dir_3_0030.png-e0daaf8466b78886ee3c4d6a13c77a88.ctex
17178  res://.godot/imported/dir_3_0031.png-79dd733b6f4796896ee4754093cbf574.ctex
16816  res://.godot/imported/dir_3_0032.png-673d415399e336f57767622876a059cc.ctex
15894  res://.godot/imported/dir_3_0033.png-351ed26bf049f1c9f5b8f63b48fdc540.ctex
15252  res://.godot/imported/dir_3_0034.png-bf45ccd5b8ecb2498520ba55ea8fca90.ctex
14540  res://.godot/imported/dir_3_0035.png-4129cce2cdd07ba02d5c20ca4c246a11.ctex
13832  res://.godot/imported/dir_3_0036.png-abf04b2b00fe88fdd23ad0bea5df2f99.ctex
13238  res://.godot/imported/dir_3_0037.png-751d3c8b75838e4c057b69baa189a6fb.ctex
12568  res://.godot/imported/dir_3_0038.png-8a31cb5390a0d5e3a37469e403fc9ea0.ctex
11772  res://.godot/imported/dir_3_0039.png-360cb8e786195be9e7dfb3c3a41fae55.ctex
10576  res://.godot/imported/dir_3_0040.png-4668837ad40cd17338f2a3a499a99944.ctex
9364  res://.godot/imported/dir_3_0041.png-4ede56ee72e588a4885b2b8d46d20b13.ctex
8486  res://.godot/imported/dir_3_0042.png-3f2669e912059103f59dd7cbdf921b09.ctex
7806  res://.godot/imported/dir_3_0043.png-cf5aae44be164daae0adafb255e53c3a.ctex
7470  res://.godot/imported/dir_3_0044.png-8171ad75fd9c98d5eb123b4fcc2fe1d0.ctex
7470  res://.godot/imported/dir_3_0045.png-739fee3a1c4268b262bce228f3c25540.ctex
24170  res://.godot/imported/dir_4_0001.png-44c0140589c9477c53e693ca422a610f.ctex
24354  res://.godot/imported/dir_4_0002.png-03e83ca13844bf120ff9f33592cabb55.ctex
24406  res://.godot/imported/dir_4_0003.png-5a067b1ce8c2abce9d265d1085006aa2.ctex
24216  res://.godot/imported/dir_4_0004.png-3e737cb0da6ac2bbf67f17e9de4541da.ctex
23850  res://.godot/imported/dir_4_0005.png-50ca1e2ace0ad812aa8e4658e5fbc49b.ctex
23840  res://.godot/imported/dir_4_0006.png-cbaebc60f655a63514a9ee42bbe601a8.ctex
23586  res://.godot/imported/dir_4_0007.png-9b4fde0a646fd92a84a198f3308e7f9c.ctex
23570  res://.godot/imported/dir_4_0008.png-914cc8543e9f50ced206fb184b891a30.ctex
23706  res://.godot/imported/dir_4_0009.png-f906857f39f7c9499bf866179301a8fa.ctex
23552  res://.godot/imported/dir_4_0010.png-e5aea61231082aa35a21f40f2712ec09.ctex
23350  res://.godot/imported/dir_4_0011.png-046e49dffaa400aa7376d9ab1b6427b9.ctex
23108  res://.godot/imported/dir_4_0012.png-fd1244d2744d4afcec69891ea22bf3ef.ctex
22868  res://.godot/imported/dir_4_0013.png-7b2b287a5acb0f329ec30bd468e72c1b.ctex
22482  res://.godot/imported/dir_4_0014.png-a86ccdbf773101b21bcc3797b678b648.ctex
22224  res://.godot/imported/dir_4_0015.png-b58405815ea0731a85856890e866e793.ctex
22182  res://.godot/imported/dir_4_0016.png-81e83a46d052604fb757f7c0412bfeb0.ctex
22060  res://.godot/imported/dir_4_0017.png-39333cb64f3c2877e9b4b20f86f02771.ctex
21698  res://.godot/imported/dir_4_0018.png-4003cb82bd9d789910f6f8d31a8bec48.ctex
21146  res://.godot/imported/dir_4_0019.png-dead4a6a63153cb0b9b7931f5ae678ed.ctex
20490  res://.godot/imported/dir_4_0020.png-71b2b2ce20e8fbab8b36a7ca71ba801c.ctex
20126  res://.godot/imported/dir_4_0021.png-ec51ee3073d172fbdb1752fe73b64753.ctex
19944  res://.godot/imported/dir_4_0022.png-c9d441a84209b2fd15a00faa56fb1251.ctex
19522  res://.godot/imported/dir_4_0023.png-2ce81c611a182118a20d5505faf43e96.ctex
18890  res://.godot/imported/dir_4_0024.png-8de87e72e639b46d062c45e528d5ca76.ctex
18142  res://.godot/imported/dir_4_0025.png-0c9d69a0d7dd65f8c19b5d14c8c9e938.ctex
17502  res://.godot/imported/dir_4_0026.png-b4078c194745d66f3f8b16c33db101ba.ctex
17018  res://.godot/imported/dir_4_0027.png-a0e8070b2a4b990a2fa3970d09ed07df.ctex
16654  res://.godot/imported/dir_4_0028.png-81d472d161be45c7797b5fbf138424a3.ctex
16586  res://.godot/imported/dir_4_0029.png-89b8cb45ca54fce7e0b0a4345dd77e09.ctex
16352  res://.godot/imported/dir_4_0030.png-a4ea7e588e4207342eab45b6bece9b09.ctex
16152  res://.godot/imported/dir_4_0031.png-56f62fd7bf021bdf915f7a99d49c25d4.ctex
16072  res://.godot/imported/dir_4_0032.png-a02734f8bdb2a9ad41fa7f5b015afc87.ctex
15792  res://.godot/imported/dir_4_0033.png-6d81174d22f2c4d14bcd6a92aedafe5c.ctex
15496  res://.godot/imported/dir_4_0034.png-65e08bf7b6548c7094aa67e59f0be8be.ctex
15090  res://.godot/imported/dir_4_0035.png-be32669bf98db3b34e6df6590b21a192.ctex
14432  res://.godot/imported/dir_4_0036.png-0d1a5b53a63e57bd8542ccb7f3bb3f64.ctex
14064  res://.godot/imported/dir_4_0037.png-f3e55a4dc2b84a975bbdeb291c52bf65.ctex
13660  res://.godot/imported/dir_4_0038.png-4a5bd9cfd14b5deedd060279575f5aef.ctex
13240  res://.godot/imported/dir_4_0039.png-c90075c8d1b9a00ed5bb2713007533a9.ctex
12834  res://.godot/imported/dir_4_0040.png-1bb4300271bd8cde60ac4bf231cad3f8.ctex
11838  res://.godot/imported/dir_4_0041.png-24f218bb887697ebff8afbc939c66102.ctex
11156  res://.godot/imported/dir_4_0042.png-32f0cb46cb07386daf5336ede400072f.ctex
11032  res://.godot/imported/dir_4_0043.png-c29414dfe98a0fffa05aa08c80b5a047.ctex
10870  res://.godot/imported/dir_4_0044.png-267944e3e6bc3dffcd6632d486270177.ctex
10870  res://.godot/imported/dir_4_0045.png-7d4f63980d87410e0f5f75d6fcd7980f.ctex
21978  res://.godot/imported/dir_5_0001.png-54ecb67a3b64ef53b95f38cfcaab5d7e.ctex
21864  res://.godot/imported/dir_5_0002.png-4be9ff92bf6613ac5f0532ee594c9f8d.ctex
21800  res://.godot/imported/dir_5_0003.png-02ae3ecccec6854388104446a5cce060.ctex
22190  res://.godot/imported/dir_5_0004.png-78f400ba5159020d0cc327fb7751626b.ctex
22656  res://.godot/imported/dir_5_0005.png-a61599f3a6912253a4ee8a46f2179ee0.ctex
23198  res://.godot/imported/dir_5_0006.png-a7a9166dcc80e53082039570e987d60e.ctex
23538  res://.godot/imported/dir_5_0007.png-97719fa861936e98f05b1c47c7437edb.ctex
23700  res://.godot/imported/dir_5_0008.png-bfa0a41e9582b4220810342faa17048b.ctex
23928  res://.godot/imported/dir_5_0009.png-222b7f2c0ba311d0eb36c49e18d4fac0.ctex
24078  res://.godot/imported/dir_5_0010.png-a0a53aaa4f0d1e1d0b151c9561284562.ctex
23962  res://.godot/imported/dir_5_0011.png-718b2daecc82a6b8e27bafe5e48aeeda.ctex
23744  res://.godot/imported/dir_5_0012.png-0165b583c3cf87032ff35631b2e3e95a.ctex
23496  res://.godot/imported/dir_5_0013.png-838fe2b9da91889799d90ec54c4cc969.ctex
23300  res://.godot/imported/dir_5_0014.png-d8663fd1c9ebf299c93e7dc67e26f95f.ctex
22378  res://.godot/imported/dir_5_0015.png-2100f509d345cd07461664ab3eaa81dd.ctex
21988  res://.godot/imported/dir_5_0016.png-226901d9b28cf7df2decd0451326d75c.ctex
21504  res://.godot/imported/dir_5_0017.png-dfd5420cd9b200935c84bf0f4cac4ab0.ctex
20640  res://.godot/imported/dir_5_0018.png-aa2e5c55ce7ff835a3ea1c42d9837741.ctex
19862  res://.godot/imported/dir_5_0019.png-a943751b68884dfc46fbb0c2c0d5178b.ctex
18890  res://.godot/imported/dir_5_0020.png-3584c763a7727de0c392a8c618354c88.ctex
17968  res://.godot/imported/dir_5_0021.png-79793cf9cbb8fe9c5c92a8a8c186c165.ctex
17404  res://.godot/imported/dir_5_0022.png-ea8d8f9eacfcc6ad60cf0eac8f76bb2d.ctex
17546  res://.godot/imported/dir_5_0023.png-f2938d845123450a87fd6be27d904951.ctex
17542  res://.godot/imported/dir_5_0024.png-a231cbffffd158111eb4a45e6c9494ab.ctex
17054  res://.godot/imported/dir_5_0025.png-fe9f38a76a4fcb7b388729392facaaf2.ctex
16910  res://.godot/imported/dir_5_0026.png-e8934ff24161fe66919d3f09ded05027.ctex
16762  res://.godot/imported/dir_5_0027.png-26da75d75afe8b79255c43e3d8e08e98.ctex
16674  res://.godot/imported/dir_5_0028.png-d694010607039d58c26ddbd9f48585be.ctex
16204  res://.godot/imported/dir_5_0029.png-800bbbc0a1f0dae81fe7ae5f7e27f370.ctex
15678  res://.godot/imported/dir_5_0030.png-7b64c82c5a0463a9b47161a4935e60ce.ctex
15830  res://.godot/imported/dir_5_0031.png-acfc1df8e7d5e6d193dfc8220f1db0ee.ctex
15672  res://.godot/imported/dir_5_0032.png-423371a1636bc3f76ff44be178654e40.ctex
15160  res://.godot/imported/dir_5_0033.png-78216bae1d9c00088dcc3233e62ca4db.ctex
14634  res://.godot/imported/dir_5_0034.png-34a0b317ec360b1b06a2262b63ffae14.ctex
13816  res://.godot/imported/dir_5_0035.png-62cf4a4fa40fc11ae23842db81261d48.ctex
12978  res://.godot/imported/dir_5_0036.png-38c419c3886c9f73785214229b1e5e8a.ctex
12142  res://.godot/imported/dir_5_0037.png-70052c6484a98cf0e42ae14e7c15da95.ctex
11336  res://.godot/imported/dir_5_0038.png-c0bf8c173fa4868b88096fb5ef6cd786.ctex
10586  res://.godot/imported/dir_5_0039.png-976536a45ab5477c7df7d1c99b776380.ctex
9904  res://.godot/imported/dir_5_0040.png-ba9bce1718013b82ef4d19d9b0f1c763.ctex
9642  res://.godot/imported/dir_5_0041.png-46f91cd851a5f818c5a02091783f1be4.ctex
8988  res://.godot/imported/dir_5_0042.png-02de82baf6bddc7ed4ba0f7cb97fcc55.ctex
8252  res://.godot/imported/dir_5_0043.png-c35a6a6a429dcfc7d718438169e5de18.ctex
7398  res://.godot/imported/dir_5_0044.png-ce3e123d0b3626a753b875112d502854.ctex
7398  res://.godot/imported/dir_5_0045.png-6852b5c6ea7d3ebfd8e76ca923623c0e.ctex
19908  res://.godot/imported/dir_6_0001.png-305ad0570c16badf494841e57f4ba611.ctex
20022  res://.godot/imported/dir_6_0002.png-22826ad2b1480d94ac49569140300b7d.ctex
20450  res://.godot/imported/dir_6_0003.png-2ddfab84d846eea12800d2ae3258d124.ctex
21016  res://.godot/imported/dir_6_0004.png-198bf0b806aed2f6d3c931a62777c72b.ctex
21476  res://.godot/imported/dir_6_0005.png-2843d807360986b608946b90e888010b.ctex
22108  res://.godot/imported/dir_6_0006.png-3e9d956ac832e00cd3c5c5e88b3ed985.ctex
22692  res://.godot/imported/dir_6_0007.png-5d37f95317537321949f3aa1b3bdaec5.ctex
22898  res://.godot/imported/dir_6_0008.png-5e47c714d8975acee8a61f03c7e1c8a8.ctex
23094  res://.godot/imported/dir_6_0009.png-a5ff6975ef9d035dc44e9369a7633b7b.ctex
22992  res://.godot/imported/dir_6_0010.png-18fefd47204b86c43402b80449215e5d.ctex
23036  res://.godot/imported/dir_6_0011.png-403f81f4712d87a6fc7bc293abfe951c.ctex
23454  res://.godot/imported/dir_6_0012.png-7a43de7f34962670014e2fa8cf58bdbd.ctex
23456  res://.godot/imported/dir_6_0013.png-6997758c5a879c6dfebd9bf83fb80b19.ctex
23200  res://.godot/imported/dir_6_0014.png-cded909ae25b702d64c05cd7ae0d2f13.ctex
22622  res://.godot/imported/dir_6_0015.png-66aeb5bd0bc542fc175fec55a3bf6087.ctex
21822  res://.godot/imported/dir_6_0016.png-b938bf7a70c22eb9d70fcaf577311100.ctex
21688  res://.godot/imported/dir_6_0017.png-176b7f93ffdda965c54bdd0eb9326d9b.ctex
21312  res://.godot/imported/dir_6_0018.png-f92b96743b8714dcbaf521b80eafbf3f.ctex
21188  res://.godot/imported/dir_6_0019.png-5761e61793846e110d7703fd46cae4d4.ctex
20790  res://.godot/imported/dir_6_0020.png-8a75df3dc801931a2f4c8ace65113319.ctex
20432  res://.godot/imported/dir_6_0021.png-9a33865f02a031907cbfe0e27fd35f00.ctex
19920  res://.godot/imported/dir_6_0022.png-3e67df7c6e0a065b498d39b0c08b0312.ctex
18882  res://.godot/imported/dir_6_0023.png-7f64aa280564aebe45e5dc0d8d9d5c16.ctex
18320  res://.godot/imported/dir_6_0024.png-88f09f26e628d7d315ce59732ccc2834.ctex
17382  res://.godot/imported/dir_6_0025.png-0b3af2fa1d2cbbfd99d4ee002fb12840.ctex
16332  res://.godot/imported/dir_6_0026.png-021f4a1a723c8d54576610d04d7fd57f.ctex
15486  res://.godot/imported/dir_6_0027.png-44e3d8b5ff0f346c8104b4032f560f71.ctex
14828  res://.godot/imported/dir_6_0028.png-1105d75f85506ccc5746fbd864b24fff.ctex
14232  res://.godot/imported/dir_6_0029.png-e4b4caed37291002953d56f4ca4131ab.ctex
13396  res://.godot/imported/dir_6_0030.png-61625df132dbbd128d4e1f75e75aabfc.ctex
12852  res://.godot/imported/dir_6_0031.png-d749cc2494f059267e4e7df5116e8622.ctex
12046  res://.godot/imported/dir_6_0032.png-71a30f79d5da9c1b438f22b398b5dab1.ctex
10890  res://.godot/imported/dir_6_0033.png-1581d03ab3875a38a17e89ed97f9e4b7.ctex
9688  res://.godot/imported/dir_6_0034.png-901410a3b9a1123e4fe9c6c067e84996.ctex
8218  res://.godot/imported/dir_6_0035.png-0ca73a5099e5ee470642737d3d349212.ctex
7646  res://.godot/imported/dir_6_0036.png-74212616df9d8d718bb761f75646bcc1.ctex
7102  res://.godot/imported/dir_6_0037.png-b8f3cd7f00d11e1738def20ba138ad31.ctex
6588  res://.godot/imported/dir_6_0038.png-de4b8fd9a432a6d0cb6d62a70779f107.ctex
5984  res://.godot/imported/dir_6_0039.png-30fe4a5d0248c94f51c386de6818aab0.ctex
3580  res://.godot/imported/dir_6_0040.png-01c5d066ea63da2b2939414aab6b7897.ctex
3580  res://.godot/imported/dir_6_0041.png-36d9495a377e03e36d424fd98695a054.ctex
3580  res://.godot/imported/dir_6_0042.png-0d3be26f076a11fe04aa48150607f766.ctex
3580  res://.godot/imported/dir_6_0043.png-b9f2da0ea4ca216970722097f128bbd1.ctex
3580  res://.godot/imported/dir_6_0044.png-3f84695fc07f7b738486280eb5603000.ctex
3580  res://.godot/imported/dir_6_0045.png-deb75272ecbeaf94c9d8a660d7c0ac85.ctex
25068  res://.godot/imported/dir_7_0001.png-f56163f66408f9b4868c963b7ccdc888.ctex
25028  res://.godot/imported/dir_7_0002.png-c0fe11e0a41fb3e172cad384ea0d6fdb.ctex
24696  res://.godot/imported/dir_7_0003.png-80353ff236d3b9e9529d95b234901c2f.ctex
24368  res://.godot/imported/dir_7_0004.png-f17b8c72db6c5a5555c1e058a4fdb37d.ctex
24400  res://.godot/imported/dir_7_0005.png-9b495c651b85e4394c7278ed9117f507.ctex
24654  res://.godot/imported/dir_7_0006.png-b55337d24f1991722d24974127890164.ctex
24522  res://.godot/imported/dir_7_0007.png-3f74fdb57cdfb5cf92632111c7c47353.ctex
24526  res://.godot/imported/dir_7_0008.png-14fff645fc469a9ca37da44571c8bf40.ctex
24300  res://.godot/imported/dir_7_0009.png-44a989bb4ef8aec21b41ccf787b8ad79.ctex
23904  res://.godot/imported/dir_7_0010.png-f8b6efa1bc0fdde4984d18d79ab2b87a.ctex
23758  res://.godot/imported/dir_7_0011.png-8d079e563451cb648d05f12fcd83410e.ctex
23646  res://.godot/imported/dir_7_0012.png-c481686c32eb52fd6fd4412c6d7b4b4e.ctex
23452  res://.godot/imported/dir_7_0013.png-230ea27940975966523df263c58504ff.ctex
23650  res://.godot/imported/dir_7_0014.png-cd9b475b011d51a12b5035e2f55c89a4.ctex
23896  res://.godot/imported/dir_7_0015.png-6462d0a0c363f5a418682bbd99cfee9f.ctex
24438  res://.godot/imported/dir_7_0016.png-1e525788b0aecb2c77f9c99b2c6e7961.ctex
24726  res://.godot/imported/dir_7_0017.png-fc1fb54f89a66e7672a3dea4977bf5dd.ctex
25078  res://.godot/imported/dir_7_0018.png-ab4b697f5439f7562d6495d6ca1b21c2.ctex
25514  res://.godot/imported/dir_7_0019.png-d6adf250f69ca718c20f2b6f1e1dab8b.ctex
25118  res://.godot/imported/dir_7_0020.png-13e81bed771a378dd92fe3e44a5dcae9.ctex
24532  res://.godot/imported/dir_7_0021.png-95025a26723093c478b81f9159680c72.ctex
23808  res://.godot/imported/dir_7_0022.png-7119dbcacfdc1fbeea0a4908fde2ad4c.ctex
22540  res://.godot/imported/dir_7_0023.png-42911aed0fd1e7b00c59d14e1d3bd2ec.ctex
21722  res://.godot/imported/dir_7_0024.png-cd0313892fa0271db3530d704b558c3a.ctex
21356  res://.godot/imported/dir_7_0025.png-e837b778cf6654dccb6e1c3cac343e06.ctex
20964  res://.godot/imported/dir_7_0026.png-c14e9001cf3dbffbd89121685a29876b.ctex
20554  res://.godot/imported/dir_7_0027.png-410a93b758978f6107af16ca2265aaca.ctex
20148  res://.godot/imported/dir_7_0028.png-f441389b1b2984eba015ff3018824976.ctex
19868  res://.godot/imported/dir_7_0029.png-37b4c07a4c3f14a34495ee55687869f8.ctex
19676  res://.godot/imported/dir_7_0030.png-ef549d8584817425a792f64d53b357de.ctex
19554  res://.godot/imported/dir_7_0031.png-368fd541b5b5219ce5724ebf77b504e3.ctex
19104  res://.godot/imported/dir_7_0032.png-5862cafb570810c768df0659dbd21c86.ctex
18186  res://.godot/imported/dir_7_0033.png-04b92d5998216baaca5ce78bc7e2b0ab.ctex
17524  res://.godot/imported/dir_7_0034.png-f360fbba45604b91d35ca2106e17547f.ctex
16720  res://.godot/imported/dir_7_0035.png-ab41dcabc7044bd63709f874ba63d42f.ctex
16038  res://.godot/imported/dir_7_0036.png-e59c70a78b8e861cb280f41a3eb39067.ctex
15590  res://.godot/imported/dir_7_0037.png-ac4072e6541b8df202a43dea56e7cd67.ctex
14784  res://.godot/imported/dir_7_0038.png-42cd164980ead0a5b2376797057244a2.ctex
13934  res://.godot/imported/dir_7_0039.png-7c2343a6c86942135313d0c4bc4f414e.ctex
13192  res://.godot/imported/dir_7_0040.png-5312afda3741127ce8a70bfb88de9549.ctex
12406  res://.godot/imported/dir_7_0041.png-9b4ca50bea3cbd33520b6451fc976146.ctex
11780  res://.godot/imported/dir_7_0042.png-435fab965479c665ead6209978a0e5fc.ctex
11054  res://.godot/imported/dir_7_0043.png-5bf45588c7753e97799660453a66348f.ctex
10110  res://.godot/imported/dir_7_0044.png-e710ee96e2dd522844ed77edfeac0918.ctex
10110  res://.godot/imported/dir_7_0045.png-9b82aafad83a15cdf5250f678768e4c3.ctex
4261443  res://.godot/imported/eurodance.mp3-fef95430f66d8053d0220ef34137fda9.mp3str
22920832  res://.godot/imported/fountain_sculpture.glb-a0ab240fe62ced988ba9a52de635ff8f.scn
4081515  res://.godot/imported/hiphop.mp3-3d4b4945f60e4d0cddde31e8acbf2438.mp3str
1176  res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex
21520143  res://.godot/imported/kiosk_turret.glb-21d18cfe5e39c287914cfac610d69389.scn
15048956  res://.godot/imported/mall_kiosk.glb-ef7ad498f3da947c3b5d733a4903be11.scn
16449405  res://.godot/imported/mall_planter.glb-f1515752ded96a398eafbdc994b6e669.scn
167359  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb-32a6b43d5d45dfc4ede7dd83598e8211.scn
11184876  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg-4aa502cd14a84b2c529a8898c302226b.s3tc.ctex
2796268  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg-ecf3d6b8aac2645fe97470a1f4e99f00.s3tc.ctex
22369700  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg-3a28b97969be2809be74c1a9476bd1c9.s3tc.ctex
142885  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb-100b1b23c136ecaea2b2c2932c21ac1b.scn
11184876  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg-57c9bb5b0ae9234c05de81e42f298c6f.s3tc.ctex
2796268  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg-2ba7f038ac6d306fa2b8d47c08417ab1.s3tc.ctex
22369700  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg-55d7e5261dcedb3df0eddb11b7b87636.s3tc.ctex
245433  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations.glb-e7f241e6428c2b67e04f90f3be56e5af.scn
11184876  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg-3cea79246c65c32a532c42ecef570744.s3tc.ctex
2796268  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg-cc800615ee86b5e4ee11529ddfdcda9e.s3tc.ctex
22369700  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg-8ced58427b3620342c6ab9d1df00a24c.s3tc.ctex
175666  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb-dd2ef507427ee6ecd6de7aea3842d3f1.scn
11184876  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg-114f149bb1e7d1877ac3e9ac4b9ffcab.s3tc.ctex
2796268  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg-95776f1ad3e7f33ed594f450af85b1ab.s3tc.ctex
22369700  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg-b16ad54c8d136d69239c481caeb12679.s3tc.ctex
180220  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d386ad401674f18d1edfd264d67ce020.scn
180159  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb-d6fdad554547eb106e82adbbc33e252f.scn
11184876  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-86710d89420272bd05b7dff2cb7dc19c.s3tc.ctex
11184876  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg-8f735e678b86df73bf8978d10c629e6f.s3tc.ctex
2796268  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-2c44aaf060978cde46693e50c10062e2.s3tc.ctex
2796268  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg-8122c1ec715bcbe34a4661682b54b4c3.s3tc.ctex
22369700  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-e909b100dc6bbda0c7e19c5e6c81bef1.s3tc.ctex
22369700  res://.godot/imported/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg-edd18b21906bbfe2adb2655e252bd46b.s3tc.ctex
20295999  res://.godot/imported/neon_cicada.glb-c075b36b4e093e1d35265564e67f028c.scn
3923527  res://.godot/imported/numetal.mp3-058dd4db2f01f0c63415579f555fa23f.mp3str
4284643  res://.godot/imported/skater.mp3-47c0b3f6a66951ef919ba1b8e36e472c.mp3str
21616270  res://.godot/imported/sludge_roach.glb-1ae35041ab2d79767ebaf70f00e6243f.scn
21824  res://.godot/uid_cache.bin
174  res://assets/models/dial_up_queen.glb.import
180  res://assets/models/fountain_sculpture.glb.import
173  res://assets/models/kiosk_turret.glb.import
172  res://assets/models/mall_kiosk.glb.import
174  res://assets/models/mall_planter.glb.import
172  res://assets/models/neon_cicada.glb.import
174  res://assets/models/sludge_roach.glb.import
772096  res://bin/libbiopunk.windows.template_debug.x86_64.dll
679424  res://bin/libbiopunk.windows.template_release.x86_64.dll
354  res://biopunk.gdextension
435  res://icon.svg
193  res://icon.svg.import
9976045  res://intro_video.ogv
152  res://music/anthem.mp3.import
154  res://music/bigbeat.mp3.import
155  res://music/bubblegum.mp3.import
153  res://music/combat.mp3.import
156  res://music/eurodance.mp3.import
153  res://music/hiphop.mp3.import
154  res://music/numetal.mp3.import
153  res://music/skater.mp3.import
11529  res://project.binary
106  res://scenes/dial_up_queen.tscn.remap
112  res://scenes/FloodedMall_Greybox.tscn.remap
112  res://scenes/health_candy_pickup.tscn.remap
98  res://scenes/intro.tscn.remap
102  res://scenes/main_menu.tscn.remap
213  res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6.glb.import
360  res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_0.jpg.import
359  res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_1.jpg.import
359  res://scenes/Meshy_AI_biopunk_delinquent_te_01a0b042_9730_74a0_b6_Image_2.jpg.import
211  res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture.glb.import
351  res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_0.jpg.import
351  res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_1.jpg.import
351  res://scenes/Meshy_AI_biopunk_delinquent_te_0916230039_texture_2.jpg.import
206  res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations.glb.import
353  res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_0.jpg.import
353  res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_1.jpg.import
353  res://scenes/Meshy_AI_biopunk_delinquent_te_All_Animations_Image_2.jpg.import
225  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin.glb.import
371  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_0.jpg.import
371  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_1.jpg.import
371  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Running_withSkin_Image_2.jpg.import
224  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
371  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
371  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
370  res://scenes/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
104  res://scenes/neon_cicada.tscn.remap
99  res://scenes/player.tscn.remap
57  res://scripts/boss_encounter_trigger.gd.remap
13196  res://scripts/boss_encounter_trigger.gdc
45  res://scripts/checkpoint.gd.remap
6476  res://scripts/checkpoint.gdc
57  res://scripts/corrupted_kiosk_turret.gd.remap
34160  res://scripts/corrupted_kiosk_turret.gdc
48  res://scripts/dial_up_queen.gd.remap
46548  res://scripts/dial_up_queen.gdc
50  res://scripts/disk_projectile.gd.remap
8308  res://scripts/disk_projectile.gdc
46  res://scripts/enemy_model.gd.remap
9632  res://scripts/enemy_model.gdc
54  res://scripts/health_candy_pickup.gd.remap
16808  res://scripts/health_candy_pickup.gdc
38  res://scripts/hud.gd.remap
75640  res://scripts/hud.gdc
51  res://scripts/isometric_camera.gd.remap
6400  res://scripts/isometric_camera.gdc
55  res://scripts/mall_greybox_builder.gd.remap
57196  res://scripts/mall_greybox_builder.gdc
46  res://scripts/neon_cicada.gd.remap
28916  res://scripts/neon_cicada.gdc
47  res://scripts/save_manager.gd.remap
17340  res://scripts/save_manager.gdc
47  res://scripts/sludge_roach.gd.remap
32784  res://scripts/sludge_roach.gdc
48  res://scripts/turret_mortar.gd.remap
23104  res://scripts/turret_mortar.gdc
52  res://scripts/tutorial_director.gd.remap
17644  res://scripts/tutorial_director.gdc
51758  res://Skate_Grind.res
198  res://sprites/player_idle/dir_0_0001.png.import
199  res://sprites/player_idle/dir_0_0002.png.import
199  res://sprites/player_idle/dir_0_0003.png.import
199  res://sprites/player_idle/dir_0_0004.png.import
199  res://sprites/player_idle/dir_0_0005.png.import
199  res://sprites/player_idle/dir_0_0006.png.import
199  res://sprites/player_idle/dir_0_0007.png.import
198  res://sprites/player_idle/dir_0_0008.png.import
199  res://sprites/player_idle/dir_0_0009.png.import
199  res://sprites/player_idle/dir_0_0010.png.import
199  res://sprites/player_idle/dir_0_0011.png.import
199  res://sprites/player_idle/dir_0_0012.png.import
198  res://sprites/player_idle/dir_0_0013.png.import
199  res://sprites/player_idle/dir_0_0014.png.import
199  res://sprites/player_idle/dir_0_0015.png.import
199  res://sprites/player_idle/dir_0_0016.png.import
198  res://sprites/player_idle/dir_0_0017.png.import
198  res://sprites/player_idle/dir_0_0018.png.import
198  res://sprites/player_idle/dir_0_0019.png.import
199  res://sprites/player_idle/dir_0_0020.png.import
199  res://sprites/player_idle/dir_0_0021.png.import
199  res://sprites/player_idle/dir_0_0022.png.import
199  res://sprites/player_idle/dir_0_0023.png.import
199  res://sprites/player_idle/dir_0_0024.png.import
198  res://sprites/player_idle/dir_0_0025.png.import
199  res://sprites/player_idle/dir_0_0026.png.import
199  res://sprites/player_idle/dir_0_0027.png.import
198  res://sprites/player_idle/dir_0_0028.png.import
198  res://sprites/player_idle/dir_0_0029.png.import
199  res://sprites/player_idle/dir_0_0030.png.import
199  res://sprites/player_idle/dir_0_0031.png.import
198  res://sprites/player_idle/dir_0_0032.png.import
199  res://sprites/player_idle/dir_0_0033.png.import
198  res://sprites/player_idle/dir_0_0034.png.import
198  res://sprites/player_idle/dir_0_0035.png.import
199  res://sprites/player_idle/dir_0_0036.png.import
198  res://sprites/player_idle/dir_0_0037.png.import
199  res://sprites/player_idle/dir_0_0038.png.import
199  res://sprites/player_idle/dir_0_0039.png.import
198  res://sprites/player_idle/dir_0_0040.png.import
199  res://sprites/player_idle/dir_0_0041.png.import
199  res://sprites/player_idle/dir_0_0042.png.import
198  res://sprites/player_idle/dir_0_0043.png.import
199  res://sprites/player_idle/dir_0_0044.png.import
198  res://sprites/player_idle/dir_0_0045.png.import
198  res://sprites/player_idle/dir_1_0001.png.import
199  res://sprites/player_idle/dir_1_0002.png.import
199  res://sprites/player_idle/dir_1_0003.png.import
198  res://sprites/player_idle/dir_1_0004.png.import
198  res://sprites/player_idle/dir_1_0005.png.import
199  res://sprites/player_idle/dir_1_0006.png.import
199  res://sprites/player_idle/dir_1_0007.png.import
199  res://sprites/player_idle/dir_1_0008.png.import
199  res://sprites/player_idle/dir_1_0009.png.import
199  res://sprites/player_idle/dir_1_0010.png.import
199  res://sprites/player_idle/dir_1_0011.png.import
199  res://sprites/player_idle/dir_1_0012.png.import
199  res://sprites/player_idle/dir_1_0013.png.import
199  res://sprites/player_idle/dir_1_0014.png.import
199  res://sprites/player_idle/dir_1_0015.png.import
198  res://sprites/player_idle/dir_1_0016.png.import
199  res://sprites/player_idle/dir_1_0017.png.import
198  res://sprites/player_idle/dir_1_0018.png.import
199  res://sprites/player_idle/dir_1_0019.png.import
198  res://sprites/player_idle/dir_1_0020.png.import
199  res://sprites/player_idle/dir_1_0021.png.import
199  res://sprites/player_idle/dir_1_0022.png.import
199  res://sprites/player_idle/dir_1_0023.png.import
199  res://sprites/player_idle/dir_1_0024.png.import
199  res://sprites/player_idle/dir_1_0025.png.import
199  res://sprites/player_idle/dir_1_0026.png.import
199  res://sprites/player_idle/dir_1_0027.png.import
199  res://sprites/player_idle/dir_1_0028.png.import
198  res://sprites/player_idle/dir_1_0029.png.import
199  res://sprites/player_idle/dir_1_0030.png.import
199  res://sprites/player_idle/dir_1_0031.png.import
199  res://sprites/player_idle/dir_1_0032.png.import
199  res://sprites/player_idle/dir_1_0033.png.import
198  res://sprites/player_idle/dir_1_0034.png.import
199  res://sprites/player_idle/dir_1_0035.png.import
198  res://sprites/player_idle/dir_1_0036.png.import
198  res://sprites/player_idle/dir_1_0037.png.import
198  res://sprites/player_idle/dir_1_0038.png.import
199  res://sprites/player_idle/dir_1_0039.png.import
199  res://sprites/player_idle/dir_1_0040.png.import
198  res://sprites/player_idle/dir_1_0041.png.import
198  res://sprites/player_idle/dir_1_0042.png.import
199  res://sprites/player_idle/dir_1_0043.png.import
198  res://sprites/player_idle/dir_1_0044.png.import
199  res://sprites/player_idle/dir_1_0045.png.import
199  res://sprites/player_idle/dir_2_0001.png.import
199  res://sprites/player_idle/dir_2_0002.png.import
199  res://sprites/player_idle/dir_2_0003.png.import
199  res://sprites/player_idle/dir_2_0004.png.import
198  res://sprites/player_idle/dir_2_0005.png.import
198  res://sprites/player_idle/dir_2_0006.png.import
199  res://sprites/player_idle/dir_2_0007.png.import
199  res://sprites/player_idle/dir_2_0008.png.import
199  res://sprites/player_idle/dir_2_0009.png.import
199  res://sprites/player_idle/dir_2_0010.png.import
199  res://sprites/player_idle/dir_2_0011.png.import
199  res://sprites/player_idle/dir_2_0012.png.import
199  res://sprites/player_idle/dir_2_0013.png.import
199  res://sprites/player_idle/dir_2_0014.png.import
199  res://sprites/player_idle/dir_2_0015.png.import
199  res://sprites/player_idle/dir_2_0016.png.import
199  res://sprites/player_idle/dir_2_0017.png.import
198  res://sprites/player_idle/dir_2_0018.png.import
199  res://sprites/player_idle/dir_2_0019.png.import
198  res://sprites/player_idle/dir_2_0020.png.import
199  res://sprites/player_idle/dir_2_0021.png.import
198  res://sprites/player_idle/dir_2_0022.png.import
198  res://sprites/player_idle/dir_2_0023.png.import
199  res://sprites/player_idle/dir_2_0024.png.import
199  res://sprites/player_idle/dir_2_0025.png.import
199  res://sprites/player_idle/dir_2_0026.png.import
198  res://sprites/player_idle/dir_2_0027.png.import
198  res://sprites/player_idle/dir_2_0028.png.import
199  res://sprites/player_idle/dir_2_0029.png.import
199  res://sprites/player_idle/dir_2_0030.png.import
199  res://sprites/player_idle/dir_2_0031.png.import
199  res://sprites/player_idle/dir_2_0032.png.import
199  res://sprites/player_idle/dir_2_0033.png.import
199  res://sprites/player_idle/dir_2_0034.png.import
199  res://sprites/player_idle/dir_2_0035.png.import
198  res://sprites/player_idle/dir_2_0036.png.import
198  res://sprites/player_idle/dir_2_0037.png.import
198  res://sprites/player_idle/dir_2_0038.png.import
199  res://sprites/player_idle/dir_2_0039.png.import
199  res://sprites/player_idle/dir_2_0040.png.import
199  res://sprites/player_idle/dir_2_0041.png.import
198  res://sprites/player_idle/dir_2_0042.png.import
199  res://sprites/player_idle/dir_2_0043.png.import
199  res://sprites/player_idle/dir_2_0044.png.import
199  res://sprites/player_idle/dir_2_0045.png.import
199  res://sprites/player_idle/dir_3_0001.png.import
198  res://sprites/player_idle/dir_3_0002.png.import
198  res://sprites/player_idle/dir_3_0003.png.import
199  res://sprites/player_idle/dir_3_0004.png.import
199  res://sprites/player_idle/dir_3_0005.png.import
199  res://sprites/player_idle/dir_3_0006.png.import
199  res://sprites/player_idle/dir_3_0007.png.import
198  res://sprites/player_idle/dir_3_0008.png.import
199  res://sprites/player_idle/dir_3_0009.png.import
199  res://sprites/player_idle/dir_3_0010.png.import
198  res://sprites/player_idle/dir_3_0011.png.import
199  res://sprites/player_idle/dir_3_0012.png.import
199  res://sprites/player_idle/dir_3_0013.png.import
199  res://sprites/player_idle/dir_3_0014.png.import
199  res://sprites/player_idle/dir_3_0015.png.import
199  res://sprites/player_idle/dir_3_0016.png.import
199  res://sprites/player_idle/dir_3_0017.png.import
198  res://sprites/player_idle/dir_3_0018.png.import
199  res://sprites/player_idle/dir_3_0019.png.import
198  res://sprites/player_idle/dir_3_0020.png.import
199  res://sprites/player_idle/dir_3_0021.png.import
199  res://sprites/player_idle/dir_3_0022.png.import
198  res://sprites/player_idle/dir_3_0023.png.import
199  res://sprites/player_idle/dir_3_0024.png.import
199  res://sprites/player_idle/dir_3_0025.png.import
199  res://sprites/player_idle/dir_3_0026.png.import
199  res://sprites/player_idle/dir_3_0027.png.import
199  res://sprites/player_idle/dir_3_0028.png.import
199  res://sprites/player_idle/dir_3_0029.png.import
198  res://sprites/player_idle/dir_3_0030.png.import
199  res://sprites/player_idle/dir_3_0031.png.import
198  res://sprites/player_idle/dir_3_0032.png.import
199  res://sprites/player_idle/dir_3_0033.png.import
198  res://sprites/player_idle/dir_3_0034.png.import
199  res://sprites/player_idle/dir_3_0035.png.import
198  res://sprites/player_idle/dir_3_0036.png.import
199  res://sprites/player_idle/dir_3_0037.png.import
199  res://sprites/player_idle/dir_3_0038.png.import
198  res://sprites/player_idle/dir_3_0039.png.import
198  res://sprites/player_idle/dir_3_0040.png.import
199  res://sprites/player_idle/dir_3_0041.png.import
199  res://sprites/player_idle/dir_3_0042.png.import
198  res://sprites/player_idle/dir_3_0043.png.import
199  res://sprites/player_idle/dir_3_0044.png.import
199  res://sprites/player_idle/dir_3_0045.png.import
199  res://sprites/player_idle/dir_4_0001.png.import
198  res://sprites/player_idle/dir_4_0002.png.import
199  res://sprites/player_idle/dir_4_0003.png.import
199  res://sprites/player_idle/dir_4_0004.png.import
199  res://sprites/player_idle/dir_4_0005.png.import
199  res://sprites/player_idle/dir_4_0006.png.import
199  res://sprites/player_idle/dir_4_0007.png.import
198  res://sprites/player_idle/dir_4_0008.png.import
199  res://sprites/player_idle/dir_4_0009.png.import
199  res://sprites/player_idle/dir_4_0010.png.import
199  res://sprites/player_idle/dir_4_0011.png.import
198  res://sprites/player_idle/dir_4_0012.png.import
199  res://sprites/player_idle/dir_4_0013.png.import
199  res://sprites/player_idle/dir_4_0014.png.import
199  res://sprites/player_idle/dir_4_0015.png.import
199  res://sprites/player_idle/dir_4_0016.png.import
199  res://sprites/player_idle/dir_4_0017.png.import
198  res://sprites/player_idle/dir_4_0018.png.import
198  res://sprites/player_idle/dir_4_0019.png.import
199  res://sprites/player_idle/dir_4_0020.png.import
199  res://sprites/player_idle/dir_4_0021.png.import
199  res://sprites/player_idle/dir_4_0022.png.import
199  res://sprites/player_idle/dir_4_0023.png.import
199  res://sprites/player_idle/dir_4_0024.png.import
199  res://sprites/player_idle/dir_4_0025.png.import
199  res://sprites/player_idle/dir_4_0026.png.import
199  res://sprites/player_idle/dir_4_0027.png.import
198  res://sprites/player_idle/dir_4_0028.png.import
199  res://sprites/player_idle/dir_4_0029.png.import
198  res://sprites/player_idle/dir_4_0030.png.import
199  res://sprites/player_idle/dir_4_0031.png.import
199  res://sprites/player_idle/dir_4_0032.png.import
199  res://sprites/player_idle/dir_4_0033.png.import
199  res://sprites/player_idle/dir_4_0034.png.import
199  res://sprites/player_idle/dir_4_0035.png.import
199  res://sprites/player_idle/dir_4_0036.png.import
199  res://sprites/player_idle/dir_4_0037.png.import
199  res://sprites/player_idle/dir_4_0038.png.import
199  res://sprites/player_idle/dir_4_0039.png.import
199  res://sprites/player_idle/dir_4_0040.png.import
199  res://sprites/player_idle/dir_4_0041.png.import
199  res://sprites/player_idle/dir_4_0042.png.import
199  res://sprites/player_idle/dir_4_0043.png.import
199  res://sprites/player_idle/dir_4_0044.png.import
199  res://sprites/player_idle/dir_4_0045.png.import
199  res://sprites/player_idle/dir_5_0001.png.import
197  res://sprites/player_idle/dir_5_0002.png.import
199  res://sprites/player_idle/dir_5_0003.png.import
199  res://sprites/player_idle/dir_5_0004.png.import
199  res://sprites/player_idle/dir_5_0005.png.import
198  res://sprites/player_idle/dir_5_0006.png.import
199  res://sprites/player_idle/dir_5_0007.png.import
198  res://sprites/player_idle/dir_5_0008.png.import
199  res://sprites/player_idle/dir_5_0009.png.import
199  res://sprites/player_idle/dir_5_0010.png.import
199  res://sprites/player_idle/dir_5_0011.png.import
199  res://sprites/player_idle/dir_5_0012.png.import
199  res://sprites/player_idle/dir_5_0013.png.import
199  res://sprites/player_idle/dir_5_0014.png.import
199  res://sprites/player_idle/dir_5_0015.png.import
198  res://sprites/player_idle/dir_5_0016.png.import
199  res://sprites/player_idle/dir_5_0017.png.import
199  res://sprites/player_idle/dir_5_0018.png.import
199  res://sprites/player_idle/dir_5_0019.png.import
198  res://sprites/player_idle/dir_5_0020.png.import
199  res://sprites/player_idle/dir_5_0021.png.import
199  res://sprites/player_idle/dir_5_0022.png.import
199  res://sprites/player_idle/dir_5_0023.png.import
199  res://sprites/player_idle/dir_5_0024.png.import
199  res://sprites/player_idle/dir_5_0025.png.import
199  res://sprites/player_idle/dir_5_0026.png.import
198  res://sprites/player_idle/dir_5_0027.png.import
199  res://sprites/player_idle/dir_5_0028.png.import
198  res://sprites/player_idle/dir_5_0029.png.import
198  res://sprites/player_idle/dir_5_0030.png.import
199  res://sprites/player_idle/dir_5_0031.png.import
199  res://sprites/player_idle/dir_5_0032.png.import
198  res://sprites/player_idle/dir_5_0033.png.import
199  res://sprites/player_idle/dir_5_0034.png.import
198  res://sprites/player_idle/dir_5_0035.png.import
198  res://sprites/player_idle/dir_5_0036.png.import
199  res://sprites/player_idle/dir_5_0037.png.import
199  res://sprites/player_idle/dir_5_0038.png.import
199  res://sprites/player_idle/dir_5_0039.png.import
199  res://sprites/player_idle/dir_5_0040.png.import
199  res://sprites/player_idle/dir_5_0041.png.import
199  res://sprites/player_idle/dir_5_0042.png.import
199  res://sprites/player_idle/dir_5_0043.png.import
199  res://sprites/player_idle/dir_5_0044.png.import
198  res://sprites/player_idle/dir_5_0045.png.import
199  res://sprites/player_idle/dir_6_0001.png.import
199  res://sprites/player_idle/dir_6_0002.png.import
199  res://sprites/player_idle/dir_6_0003.png.import
199  res://sprites/player_idle/dir_6_0004.png.import
198  res://sprites/player_idle/dir_6_0005.png.import
198  res://sprites/player_idle/dir_6_0006.png.import
199  res://sprites/player_idle/dir_6_0007.png.import
199  res://sprites/player_idle/dir_6_0008.png.import
199  res://sprites/player_idle/dir_6_0009.png.import
198  res://sprites/player_idle/dir_6_0010.png.import
198  res://sprites/player_idle/dir_6_0011.png.import
198  res://sprites/player_idle/dir_6_0012.png.import
199  res://sprites/player_idle/dir_6_0013.png.import
199  res://sprites/player_idle/dir_6_0014.png.import
199  res://sprites/player_idle/dir_6_0015.png.import
199  res://sprites/player_idle/dir_6_0016.png.import
199  res://sprites/player_idle/dir_6_0017.png.import
199  res://sprites/player_idle/dir_6_0018.png.import
199  res://sprites/player_idle/dir_6_0019.png.import
199  res://sprites/player_idle/dir_6_0020.png.import
198  res://sprites/player_idle/dir_6_0021.png.import
198  res://sprites/player_idle/dir_6_0022.png.import
199  res://sprites/player_idle/dir_6_0023.png.import
199  res://sprites/player_idle/dir_6_0024.png.import
199  res://sprites/player_idle/dir_6_0025.png.import
198  res://sprites/player_idle/dir_6_0026.png.import
199  res://sprites/player_idle/dir_6_0027.png.import
198  res://sprites/player_idle/dir_6_0028.png.import
199  res://sprites/player_idle/dir_6_0029.png.import
199  res://sprites/player_idle/dir_6_0030.png.import
199  res://sprites/player_idle/dir_6_0031.png.import
199  res://sprites/player_idle/dir_6_0032.png.import
198  res://sprites/player_idle/dir_6_0033.png.import
199  res://sprites/player_idle/dir_6_0034.png.import
199  res://sprites/player_idle/dir_6_0035.png.import
199  res://sprites/player_idle/dir_6_0036.png.import
199  res://sprites/player_idle/dir_6_0037.png.import
198  res://sprites/player_idle/dir_6_0038.png.import
197  res://sprites/player_idle/dir_6_0039.png.import
199  res://sprites/player_idle/dir_6_0040.png.import
198  res://sprites/player_idle/dir_6_0041.png.import
198  res://sprites/player_idle/dir_6_0042.png.import
199  res://sprites/player_idle/dir_6_0043.png.import
198  res://sprites/player_idle/dir_6_0044.png.import
198  res://sprites/player_idle/dir_6_0045.png.import
198  res://sprites/player_idle/dir_7_0001.png.import
199  res://sprites/player_idle/dir_7_0002.png.import
199  res://sprites/player_idle/dir_7_0003.png.import
199  res://sprites/player_idle/dir_7_0004.png.import
199  res://sprites/player_idle/dir_7_0005.png.import
197  res://sprites/player_idle/dir_7_0006.png.import
199  res://sprites/player_idle/dir_7_0007.png.import
199  res://sprites/player_idle/dir_7_0008.png.import
199  res://sprites/player_idle/dir_7_0009.png.import
198  res://sprites/player_idle/dir_7_0010.png.import
198  res://sprites/player_idle/dir_7_0011.png.import
199  res://sprites/player_idle/dir_7_0012.png.import
199  res://sprites/player_idle/dir_7_0013.png.import
198  res://sprites/player_idle/dir_7_0014.png.import
199  res://sprites/player_idle/dir_7_0015.png.import
199  res://sprites/player_idle/dir_7_0016.png.import
199  res://sprites/player_idle/dir_7_0017.png.import
199  res://sprites/player_idle/dir_7_0018.png.import
199  res://sprites/player_idle/dir_7_0019.png.import
198  res://sprites/player_idle/dir_7_0020.png.import
199  res://sprites/player_idle/dir_7_0021.png.import
199  res://sprites/player_idle/dir_7_0022.png.import
198  res://sprites/player_idle/dir_7_0023.png.import
199  res://sprites/player_idle/dir_7_0024.png.import
199  res://sprites/player_idle/dir_7_0025.png.import
197  res://sprites/player_idle/dir_7_0026.png.import
199  res://sprites/player_idle/dir_7_0027.png.import
198  res://sprites/player_idle/dir_7_0028.png.import
198  res://sprites/player_idle/dir_7_0029.png.import
199  res://sprites/player_idle/dir_7_0030.png.import
198  res://sprites/player_idle/dir_7_0031.png.import
199  res://sprites/player_idle/dir_7_0032.png.import
199  res://sprites/player_idle/dir_7_0033.png.import
199  res://sprites/player_idle/dir_7_0034.png.import
199  res://sprites/player_idle/dir_7_0035.png.import
198  res://sprites/player_idle/dir_7_0036.png.import
199  res://sprites/player_idle/dir_7_0037.png.import
199  res://sprites/player_idle/dir_7_0038.png.import
199  res://sprites/player_idle/dir_7_0039.png.import
198  res://sprites/player_idle/dir_7_0040.png.import
199  res://sprites/player_idle/dir_7_0041.png.import
199  res://sprites/player_idle/dir_7_0042.png.import
199  res://sprites/player_idle/dir_7_0043.png.import
198  res://sprites/player_idle/dir_7_0044.png.import
199  res://sprites/player_idle/dir_7_0045.png.import
225  res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin.glb.import
371  res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_0.jpg.import
371  res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_1.jpg.import
371  res://sprites/player_idle/Meshy_AI_biopunk_delinquent_te_biped_Animation_Walking_withSkin_Image_2.jpg.import
PACKED: res://intro_video.ogv (direct, 9976045 bytes)
PACKED: res://icon.svg (direct, 435 bytes)
PACKED: res://Skate_Grind.res (direct, 51758 bytes)
PACKED: res://biopunk.gdextension (direct, 354 bytes)
PACKED: res://music/anthem.mp3 -> res://.godot/imported/anthem.mp3-2f7a92cf245df82890b7830193e2bea6.mp3str (4285267 bytes; via res://music/anthem.mp3.import)
PACKED: res://music/bigbeat.mp3 -> res://.godot/imported/bigbeat.mp3-719a317dfac214297f4d640840ee7874.mp3str (4096559 bytes; via res://music/bigbeat.mp3.import)
PACKED: res://music/bubblegum.mp3 -> res://.godot/imported/bubblegum.mp3-6600d7a64ddbbec66a2b18480a79e0ad.mp3str (4284015 bytes; via res://music/bubblegum.mp3.import)
PACKED: res://music/combat.mp3 -> res://.godot/imported/combat.mp3-1829eebac0ee46487ae84a3be83a352e.mp3str (3829483 bytes; via res://music/combat.mp3.import)
PACKED: res://music/eurodance.mp3 -> res://.godot/imported/eurodance.mp3-fef95430f66d8053d0220ef34137fda9.mp3str (4261443 bytes; via res://music/eurodance.mp3.import)
PACKED: res://music/hiphop.mp3 -> res://.godot/imported/hiphop.mp3-3d4b4945f60e4d0cddde31e8acbf2438.mp3str (4081515 bytes; via res://music/hiphop.mp3.import)
PACKED: res://music/numetal.mp3 -> res://.godot/imported/numetal.mp3-058dd4db2f01f0c63415579f555fa23f.mp3str (3923527 bytes; via res://music/numetal.mp3.import)
PACKED: res://music/skater.mp3 -> res://.godot/imported/skater.mp3-47c0b3f6a66951ef919ba1b8e36e472c.mp3str (4284643 bytes; via res://music/skater.mp3.import)
PACKED: res://assets/models/dial_up_queen.glb -> res://.godot/imported/dial_up_queen.glb-c1a5cb2f8ad5373c4dcab5634b6375c1.scn (23329773 bytes; via res://assets/models/dial_up_queen.glb.import)
PACKED: res://assets/models/fountain_sculpture.glb -> res://.godot/imported/fountain_sculpture.glb-a0ab240fe62ced988ba9a52de635ff8f.scn (22920832 bytes; via res://assets/models/fountain_sculpture.glb.import)
PACKED: res://assets/models/kiosk_turret.glb -> res://.godot/imported/kiosk_turret.glb-21d18cfe5e39c287914cfac610d69389.scn (21520143 bytes; via res://assets/models/kiosk_turret.glb.import)
PACKED: res://assets/models/mall_kiosk.glb -> res://.godot/imported/mall_kiosk.glb-ef7ad498f3da947c3b5d733a4903be11.scn (15048956 bytes; via res://assets/models/mall_kiosk.glb.import)
PACKED: res://assets/models/mall_planter.glb -> res://.godot/imported/mall_planter.glb-f1515752ded96a398eafbdc994b6e669.scn (16449405 bytes; via res://assets/models/mall_planter.glb.import)
PACKED: res://assets/models/neon_cicada.glb -> res://.godot/imported/neon_cicada.glb-c075b36b4e093e1d35265564e67f028c.scn (20295999 bytes; via res://assets/models/neon_cicada.glb.import)
PACKED: res://assets/models/sludge_roach.glb -> res://.godot/imported/sludge_roach.glb-1ae35041ab2d79767ebaf70f00e6243f.scn (21616270 bytes; via res://assets/models/sludge_roach.glb.import)
PACKED: res://bin/libbiopunk.windows.template_release.x86_64.dll (direct, 679424 bytes)
FILTERS: PASS (QA=False; no forbidden source/ops/test/build files)
PCK: C:\y2k-biopunk-rpg\.worktrees\vs11export\build\qa\Y2K-BioPunk-QA.pck (Godot 4.3.0, 860 entries)
PACKED: res://intro_video.ogv (direct, 9976045 bytes)
PACKED: res://icon.svg (direct, 435 bytes)
PACKED: res://Skate_Grind.res (direct, 51758 bytes)
PACKED: res://biopunk.gdextension (direct, 354 bytes)
PACKED: res://music/anthem.mp3 -> res://.godot/imported/anthem.mp3-2f7a92cf245df82890b7830193e2bea6.mp3str (4285267 bytes; via res://music/anthem.mp3.import)
PACKED: res://music/bigbeat.mp3 -> res://.godot/imported/bigbeat.mp3-719a317dfac214297f4d640840ee7874.mp3str (4096559 bytes; via res://music/bigbeat.mp3.import)
PACKED: res://music/bubblegum.mp3 -> res://.godot/imported/bubblegum.mp3-6600d7a64ddbbec66a2b18480a79e0ad.mp3str (4284015 bytes; via res://music/bubblegum.mp3.import)
PACKED: res://music/combat.mp3 -> res://.godot/imported/combat.mp3-1829eebac0ee46487ae84a3be83a352e.mp3str (3829483 bytes; via res://music/combat.mp3.import)
PACKED: res://music/eurodance.mp3 -> res://.godot/imported/eurodance.mp3-fef95430f66d8053d0220ef34137fda9.mp3str (4261443 bytes; via res://music/eurodance.mp3.import)
PACKED: res://music/hiphop.mp3 -> res://.godot/imported/hiphop.mp3-3d4b4945f60e4d0cddde31e8acbf2438.mp3str (4081515 bytes; via res://music/hiphop.mp3.import)
PACKED: res://music/numetal.mp3 -> res://.godot/imported/numetal.mp3-058dd4db2f01f0c63415579f555fa23f.mp3str (3923527 bytes; via res://music/numetal.mp3.import)
PACKED: res://music/skater.mp3 -> res://.godot/imported/skater.mp3-47c0b3f6a66951ef919ba1b8e36e472c.mp3str (4284643 bytes; via res://music/skater.mp3.import)
PACKED: res://assets/models/dial_up_queen.glb -> res://.godot/imported/dial_up_queen.glb-c1a5cb2f8ad5373c4dcab5634b6375c1.scn (23329773 bytes; via res://assets/models/dial_up_queen.glb.import)
PACKED: res://assets/models/fountain_sculpture.glb -> res://.godot/imported/fountain_sculpture.glb-a0ab240fe62ced988ba9a52de635ff8f.scn (22920832 bytes; via res://assets/models/fountain_sculpture.glb.import)
PACKED: res://assets/models/kiosk_turret.glb -> res://.godot/imported/kiosk_turret.glb-21d18cfe5e39c287914cfac610d69389.scn (21520143 bytes; via res://assets/models/kiosk_turret.glb.import)
PACKED: res://assets/models/mall_kiosk.glb -> res://.godot/imported/mall_kiosk.glb-ef7ad498f3da947c3b5d733a4903be11.scn (15048956 bytes; via res://assets/models/mall_kiosk.glb.import)
PACKED: res://assets/models/mall_planter.glb -> res://.godot/imported/mall_planter.glb-f1515752ded96a398eafbdc994b6e669.scn (16449405 bytes; via res://assets/models/mall_planter.glb.import)
PACKED: res://assets/models/neon_cicada.glb -> res://.godot/imported/neon_cicada.glb-c075b36b4e093e1d35265564e67f028c.scn (20295999 bytes; via res://assets/models/neon_cicada.glb.import)
PACKED: res://assets/models/sludge_roach.glb -> res://.godot/imported/sludge_roach.glb-1ae35041ab2d79767ebaf70f00e6243f.scn (21616270 bytes; via res://assets/models/sludge_roach.glb.import)
PACKED: res://bin/libbiopunk.windows.template_release.x86_64.dll (direct, 679424 bytes)
PACKED: res://bin/libbiopunk.windows.template_debug.x86_64.dll (direct, 772096 bytes)
PACKED: res://ops/tools/shot_harness.gd (direct, 19847 bytes)
PACKED: res://tests/test_3d_player.gd (direct, 13021 bytes)
PACKED: res://tests/test_5_systems.gd (direct, 9554 bytes)
PACKED: res://tests/test_candy_pickup.gd (direct, 9988 bytes)
PACKED: res://tests/test_critical_path.gd (direct, 4845 bytes)
PACKED: res://tests/test_cursor_aiming.gd (direct, 8829 bytes)
PACKED: res://tests/test_encounters.gd (direct, 6695 bytes)
PACKED: res://tests/test_feel_combat.gd (direct, 6129 bytes)
PACKED: res://tests/test_feel_movement.gd (direct, 5901 bytes)
PACKED: res://tests/test_feel_traversal.gd (direct, 3499 bytes)
PACKED: res://tests/test_flamethrower_particles.gd (direct, 3086 bytes)
PACKED: res://tests/test_gameplay_fixes.gd (direct, 8256 bytes)
PACKED: res://tests/test_grinding.gd (direct, 6764 bytes)
PACKED: res://tests/test_menu_flow.gd (direct, 2334 bytes)
PACKED: res://tests/test_onboarding.gd (direct, 9410 bytes)
PACKED: res://tests/test_presentation.gd (direct, 3755 bytes)
PACKED: res://tests/test_slice_e2e.gd (direct, 8750 bytes)
PACKED: res://tests/test_systems.gd (direct, 2328 bytes)
PACKED: res://tests/test_tapes.gd (direct, 2777 bytes)
PACKED: res://tests/verify_camera_and_hud.gd (direct, 1908 bytes)
PACKED: res://tests/_test_util.gd (direct, 4395 bytes)
FILTERS: PASS (QA=True; no forbidden source/ops/test/build files)
COMMAND: C:\y2k-biopunk-rpg\.worktrees\vs11export\build\qa\Y2K-BioPunk-QA.console.exe --headless -s res://tests/test_slice_e2e.gd
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

=== test_slice_e2e ===
PASS: a: load real mall
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
PASS: a: level 1, full HP, player group
PASS: a: nearby cicadas=2, roaches=0
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 2! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 75
PASS: b: exact earned XP=90 (3 cicadas, 4 roaches), level=2
[Y2K-STATS] Stat point allocated to 'strength'! Remaining unspent points: 1
PASS: b: strength point increases bat damage
FAIL: c: checkpoint collision saves current level
[Y2K-PLAYER] *** CRITICAL BIO-FAILURE *** Player HP reached 0. Transitioned to STATE_DEAD. Reloading scene in 2.5s...
PASS: d: real lethal damage enters dead state
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 11 (Bat DMG: 42.5) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[SaveManager] Restored player save state! Level 2 | Unspent Pts: 1 | Tape: 'Bubblegum'
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
PASS: d: death reloads scene within 4s
PASS: d: respawn restores saved level, full HP, checkpoint position
PASS: d: respawn preserves XP, spent strength and unspent points
PASS: e: real atrium sensor enters grind within 0.5s
PASS: e: jump dismount emits grind_ended and one landing slam
[BossTrigger] Awakening Dial-Up Queen...
[DialUpQueen] *** BOSS SPAWNED *** The Dial-Up Queen looms with 1500 HP!
PASS: f: real trigger spawns exactly one Queen
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 2 !!!!!!!
PASS: f: phase 2 signal/state in order
PASS: f: phase 2 invulnerability expires
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 3 !!!!!!!
PASS: f: phase 3 signal/state in order
PASS: f: phase 3 invulnerability expires
PASS: f: real summon state creates minions
[DialUpQueen] *** BOSS DEFEATED! The dial-up carrier frequency has died. ***
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 3! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 112
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 4! Gained 1 Stat Point. Unspent: 3 | Next Level XP: 168
[SaveManager] Slice completion recorded.
PASS: f: boss_defeated fires once
PASS: f: summoned minions freed on victory
PASS: f: HUD victory card node exists
[Y2K-MENU] MenuController ready! Bio-Punk Title Screen online.
PASS: f: victory returns to main_menu within 7s
PASS: g: Continue button visible
PASS: g: saved slice_complete is true
PASS: runtime 21.57s < 60s
RESULT: FAIL (1 fails)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
WARNING: ObjectDB instances leaked at exit (run with --verbose for details).
     at: cleanup (core/object/object.cpp:2284)
ERROR: 1 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:604)

EXIT: 1 (test_slice_e2e)
SMOKE: FAIL - test_slice_e2e did not pass in the exported template; STOP, see exact output above and C:\y2k-biopunk-rpg\.worktrees\vs11export\ops\runs\export\smoke_20261008_133930.

```

Script exit code: `1`.

## Source E2E details from the regression runner

The runner stores individual process output in `ops/runs/tests/20261008_134012.log`. Its complete E2E block is pasted below to demonstrate the identical source assertion and subsequent checkpoint-save event.

```text
--- START: tests/test_slice_e2e.gd ---
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

=== test_slice_e2e ===
PASS: a: load real mall
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
PASS: a: level 1, full HP, player group
PASS: a: nearby cicadas=2, roaches=0
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 2! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 75
PASS: b: exact earned XP=90 (3 cicadas, 4 roaches), level=2
[Y2K-STATS] Stat point allocated to 'strength'! Remaining unspent points: 1
PASS: b: strength point increases bat damage
FAIL: c: checkpoint collision saves current level
[Y2K-PLAYER] *** CRITICAL BIO-FAILURE *** Player HP reached 0. Transitioned to STATE_DEAD. Reloading scene in 2.5s...
PASS: d: real lethal damage enters dead state
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 11 (Bat DMG: 42.5) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[SaveManager] Restored player save state! Level 2 | Unspent Pts: 1 | Tape: 'Bubblegum'
[FloodedMall] Greybox blockout successfully constructed with 13 structural sections!
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 2 | XP 40/75 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
PASS: d: death reloads scene within 4s
PASS: d: respawn restores saved level, full HP, checkpoint position
PASS: d: respawn preserves XP, spent strength and unspent points
PASS: e: real atrium sensor enters grind within 0.5s
PASS: e: jump dismount emits grind_ended and one landing slam
[BossTrigger] Awakening Dial-Up Queen...
[DialUpQueen] *** BOSS SPAWNED *** The Dial-Up Queen looms with 1500 HP!
PASS: f: real trigger spawns exactly one Queen
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 2 !!!!!!!
PASS: f: phase 2 signal/state in order
PASS: f: phase 2 invulnerability expires
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 3 !!!!!!!
PASS: f: phase 3 signal/state in order
PASS: f: phase 3 invulnerability expires
PASS: f: real summon state creates minions
[DialUpQueen] *** BOSS DEFEATED! The dial-up carrier frequency has died. ***
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 3! Gained 1 Stat Point. Unspent: 2 | Next Level XP: 112
[Y2K-LEVEL] *** LEVEL UP! *** Now Level 4! Gained 1 Stat Point. Unspent: 3 | Next Level XP: 168
[SaveManager] Slice completion recorded.
PASS: f: boss_defeated fires once
PASS: f: summoned minions freed on victory
PASS: f: HUD victory card node exists
[Y2K-MENU] MenuController ready! Bio-Punk Title Screen online.
PASS: f: victory returns to main_menu within 7s
PASS: g: Continue button visible
PASS: g: saved slice_complete is true
PASS: runtime 21.77s < 60s
RESULT: FAIL (1 fails)

ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)

--- END: tests/test_slice_e2e.gd (ExitCode: 1, Time: 22.11s) ---


```
