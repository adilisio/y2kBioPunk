# VS11-EXPORT — Windows release build and packaged-build validation
Agent: codex (gpt-6.1-sol, effort high). Worktree `C:\y2k-biopunk-rpg\.worktrees\vs11export` on branch `vs11-export` (from main). Stay there. Run Godot headless or windowed OFF-SCREEN only (`--windowed --position 2000,2000`); never the editor; never a window on the user's screen.

Read `AGENTS.md`, `ops/CONTEXT.md`, `biopunk.gdextension`, `SConstruct`, `project.godot`, `.gitignore`, `ops/tools/run_tests.ps1`, `ops/tools/shot_harness.gd` (header and the `tp`/`dmg`/`fps` steps), `scenes/intro.tscn` (video), `scripts/save_manager.gd` (save path), then this brief.

## Why this matters
VS1.1 ends with an executable Anthony can hand to a stranger. Today only the debug DLL ships, there is no `export_presets.cfg`, and nobody has launched the game outside the engine binary. The packaged build is the milestone artifact.

## Facts already established
- Godot 4.3 stable export templates are installed at `%APPDATA%\Godot\export_templates\4.3.stable\` (windows_release_x86_64.exe, windows_debug_x86_64.exe, console variants).
- The engine binary `Godot_v4.3-stable_win64.exe` is in the worktree; it exports headless: `Godot_v4.3-stable_win64.exe --headless --path . --export-release "Windows Desktop" build/release/Y2K-BioPunk.exe` (run `--import` first in a fresh worktree).
- `bin/libbiopunk.windows.template_release.x86_64.dll` is already built and copied into the worktree's `bin/`. If it is missing, build it: `py -3 -m SCons platform=windows target=template_release -j8` (10 min).
- The manifest already maps `windows.release.x86_64` to the release DLL. Exported release builds load the `release` entry; exported debug builds load `debug`.
- Hot-path logging is `print_verbose`; `flush_stdout_on_print=false`.

## You own
- New: `export_presets.cfg` (committed; contains no secrets), `ops/tools/build_release.ps1`, `ops/tools/smoke_packaged.ps1`, `ops/runs/.gdignore` (plus the `.gitignore` exception `!ops/runs/.gdignore` so it is committed; this stops screenshot PNGs under `ops/runs/` being imported as project textures), `ops/reports/VS11-EXPORT.md`.
- Edit: `.gitignore` (add `build/` and the exception above); `README.md` ONLY to add a short "Release build" section (the Director rewrites the rest later).
- Do NOT touch `src/`, `scripts/`, scenes, `project.godot` (if an export needs a project setting, STOP and describe it in the report).

## Scope
1. **Presets.** `export_presets.cfg` with two Windows Desktop presets, both `export_filter="all_resources"` with exclude filters covering `ops/*`, `tests/*`, `godot-cpp/*`, `src/*`, `.worktrees/*`, `*.md`, `*.log`, `Prompt___Generate_a_aspect.mp4`, `test_proc_mat.tres`, `test_quad.tres`, `digital-delivery.md`, `SConstruct`, `.sconsign.dblite`, `.gitmodules`, `export_presets.cfg`. Must include `intro_video.ogv`, `music/*.mp3`, `assets/models/*.glb`, `scenes/*`, `scripts/*`, `bin/*.dll`, `icon.svg`, `Skate_Grind.res` (referenced by the mall scene), `sprites/*`.
   - Preset 1 `Windows Desktop` -> `build/release/Y2K-BioPunk.exe`, release template, embed pck = false (keep the `.pck` beside the exe), `binary_format/architecture="x86_64"`, console wrapper on (the `.console.exe` is useful for log capture; players double-click the main exe), product name "Y2K: Bio-Punk", company "Anthony Dilisio", file version 1.1.0.0, product version "1.1 (VS1.1)". Do not add a dependency on rcedit; if the icon/version info needs it, leave those fields and note it.
   - Preset 2 `Windows Desktop QA` -> `build/qa/Y2K-BioPunk-QA.exe`, same filters but additionally INCLUDING `tests/*` and `ops/tools/shot_harness.gd`, debug template, so headless tests and the shot harness can run against the packaged pck.
2. **`ops/tools/build_release.ps1`**: from repo root: (a) refuse to run if a `Godot_v4.3-stable_win64.exe` process from this checkout is open (DLL lock), (b) run `scons target=template_release` only if the release DLL is older than any `src/*.cpp|hpp`, (c) `--import`, (d) export both presets headless, (e) copy `music/CREDITS.md` into `build/release/` as `MUSIC-CREDITS.txt`, (f) write `build/release/BUILD-INFO.txt` with git hash, date, Godot version, (g) zip `build/release/` to `build/Y2K-BioPunk-VS1.1-win64.zip`, (h) print sizes. Exit non-zero on any failure. No interactive prompts.
3. **`ops/tools/smoke_packaged.ps1`**: validates the packaged builds without the editor: (a) `build/qa/Y2K-BioPunk-QA.console.exe --headless -s res://tests/test_slice_e2e.gd` and `-s res://tests/test_menu_flow.gd` must pass (if `-s` is refused by the exported template, try `--script`; if both are refused, STOP and report exactly what happened), (b) launch `build/release/Y2K-BioPunk.console.exe --windowed --resolution 1280x720 --position 2000,2000 --quit-after 600` capturing stdout/stderr, and fail on any `ERROR`, `SCRIPT ERROR`, `Cannot open file`, `Failed loading resource`, `Resource file not found`, or GDExtension load failure lines, (c) list the release pck contents (`Godot --headless --path . --export-pack` with `--verbose`, or a small PowerShell reader of the pck directory) to prove `intro_video.ogv`, all 8 `music/*.mp3`, all 7 `assets/models/*.glb`, `bin/libbiopunk.windows.template_release.x86_64.dll` are packed and that `ops/`, `tests/`, `godot-cpp/`, `src/` are NOT (except the QA preset's allowed extras).
4. **Save behaviour outside the editor.** Confirm from `scripts/save_manager.gd` that saves go to `user://` (so they land under `%APPDATA%\Godot\app_userdata\<project name>\`) and document the path in the report. If the save path is `res://`, STOP and report.
5. **Run it.** Execute `build_release.ps1` then `smoke_packaged.ps1`; paste full output. Report the `build/release/` file list with sizes and the zip size. Build artifacts stay untracked (gitignored `build/`).

## Verification (paste real output)
- Both scripts' complete output.
- `powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1` still all PASS (you did not touch gameplay, but prove it).

## Commits
On `vs11-export`, trailers `Agent: codex/gpt-6.1-sol` + `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. Do not commit `build/`, `*.import` churn, or `ops/runs/` contents other than the `.gdignore`. COMMIT BEFORE FINISHING.

## Report
`ops/reports/VS11-EXPORT.md`: exact commands, pasted outputs, the pck content proof, file sizes, the save path, STOP items.
