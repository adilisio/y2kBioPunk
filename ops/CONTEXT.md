# Shared context for all agents (written by the Director, 2026-10-07)

Facts already established. Do not re-derive; verify only if your task depends on them.

- Engine binary: `./Godot_v4.3-stable_win64.exe` at repo root (gitignored). Headless test run:
  `./Godot_v4.3-stable_win64.exe --headless --path . -s tests/<file>.gd` (each test is a SceneTree script with `_init`).
- C++ build: `py -3 -m SCons platform=windows target=template_debug -j8` from repo root. Builds `bin/libbiopunk.windows.template_debug.x86_64.dll`. Never run while a Godot editor/game instance is open (DLL lock). SConstruct forces /MT; do not change it.
- Critical-path bug (confirmed): `MenuController` New Game loads `res://scenes/main.tscn`, which is an empty 100x100 CSG floor + player + HUD + one candy. The real level with enemies, grind rails, boss trigger and checkpoint is `res://scenes/FloodedMall_Greybox.tscn` and is NOT reachable from the menu.
- `StrandedSoldierNPC` (C++) is registered but placed in no scene. `MutatedBugEnemy` (C++) is registered but unused by any scene; GDScript enemies are the live roster.
- Stale duplicates at repo root (`*.gd`, `*.tscn` copies of files that live in `scripts/` and `scenes/`) are cruft; some differ from the canonical copies. Canonical = `scripts/` and `scenes/`.
- No `addons/` folder: the godot-ai MCP editor plugin is not installed in this project.
- Player model: Meshy glb `scenes/Meshy_AI_biopunk_delinquent_te_All_Animations.glb`. Code plays animations named `Walking`, `Running`, `restpose`, and tries several attack names.
- Player movement sets ground velocity instantly (no accel/decel); skating toggles 6 -> 12 m/s instantly; grinding requires skates; dismount with jump/attack triggers an AoE slam.
- Collision: player layer 1|2; enemies/attack sensors use layers 1-4 loosely.
- Existing tests: `tests/test_systems.gd` and `tests/test_tapes.gd` pass headless. Others pending.
- Rules for every agent: do not open the Godot editor or a windowed game instance (it steals the user's screen and locks the DLL). Headless runs are fine. Never commit; the Director integrates. Write reports/briefs only where your brief says.
- CRASHING TESTS: `tests/test_3d_player.gd`, `tests/test_cursor_aiming.gd` and `tests/test_grinding.gd` make Godot crash at exit (null read during teardown) and pop a Windows error dialog on the owner's screen. Do NOT run them until they are fixed. Run only: test_systems, test_tapes, test_candy_pickup, test_flamethrower_particles, verify_camera_and_hud, test_5_systems, test_gameplay_fixes.
