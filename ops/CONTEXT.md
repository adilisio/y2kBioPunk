# Shared context for all agents (written by the Director, 2026-10-07)

Facts already established. Do not re-derive; verify only if your task depends on them.

- Engine binary: `./Godot_v4.3-stable_win64.exe` at repo root (gitignored). Headless test run:
  `./Godot_v4.3-stable_win64.exe --headless --path . -s tests/<file>.gd` (each test is a SceneTree script with `_init`).
- C++ build: `py -3 -m SCons platform=windows target=template_debug -j8` from repo root. Builds `bin/libbiopunk.windows.template_debug.x86_64.dll`. Never run while a Godot editor/game instance is open (DLL lock). SConstruct forces /MT; do not change it.
- New Game loads `res://scenes/FloodedMall_Greybox.tscn` (fixed in VS1); `scenes/main.tscn` no longer exists.
- `StrandedSoldierNPC` and `MutatedBugEnemy` (C++) were deleted 2026-10-08 (Anthony ruling); GDScript enemies are the live roster.
- Canonical code lives in `scripts/` and `scenes/`; the root holds only `project.godot`, `export_presets.cfg`, `biopunk.gdextension`, `SConstruct`, `icon.svg`, `intro_video.ogv`, `Skate_Grind.res` and docs.
- No `addons/` folder: the godot-ai MCP editor plugin is not installed in this project.
- Player model: Meshy glb `scenes/Meshy_AI_biopunk_delinquent_te_All_Animations.glb`. Code plays animations named `Walking`, `Running`, `restpose`, and tries several attack names.
- Player movement accelerates/brakes (VS1 WP-2); skating 12 m/s with carving; grinding requires skates, an aligned approach and SPACE; dismount with jump/attack triggers an AoE slam.
- Collision: player layer 1|2; enemies/attack sensors use layers 1-4 loosely.
- Tests: 23 suites via `ops/tools/run_tests.ps1`, all PASS at HEAD. They share the `user://` save; never run suites from two checkouts concurrently (e2e steps c/g flake).
- Rules for every agent: do not open the Godot editor or a windowed game on the user's screen; headless runs are fine, and the shot harness may run windowed only with `--windowed --position 2000,2000` when the brief allows it. Commit on your packet branch before finishing (briefs override the older never-commit rule); the Director merges. Write reports/briefs only where your brief says. Paste real output; never claim a pass you did not observe.
- Packaging: `ops/tools/build_release.ps1` + `ops/tools/smoke_packaged.ps1`; the release DLL is committed; templates live in `%APPDATA%\Godot\export_templates\4.3.stable\`.
