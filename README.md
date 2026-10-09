# Y2K: Bio-Punk ARPG

**[Download the free Windows demo on itch.io](https://signallampgames.itch.io/y2k-bio-punk)** (about 15 minutes, one complete run to the Dial-Up Queen).

A retro-future isometric action RPG built in Godot 4.3 Stable (Forward+) with a C++ godot-cpp GDExtension and GDScript gameplay systems. Roller skates, cassette stat buffs and a CRT pager meet a flooded mall full of mutated bio-fauna.

Windows x86_64 is the supported platform. The extension manifest has no Linux library entry.

## Vertical Slice 1.1 (showable build)

Start a fresh run in the Flooded Mall, fight telegraphed cicada lunges, roach pounces and beacon-topped kiosk turrets with a baseball bat, earn XP and spend stat points in a character sheet that pauses the game and tells you what each stat does (Strength = strike damage, Agility = speed, Vitality = max HP, Vibe = critical hits). Skate, hop onto grind rails with SPACE and land a dismount slam; the Bio-Stabilizer terminal heals and saves, and entering the north arena also saves before the three-phase Dial-Up Queen (1500 HP) wakes in her neon server pit. Victory shows a completion card and returns to the menu, where Continue restores the checkpoint.

The pager teaches movement, evade, tapes, skates, secondary weapons, grinding and turret reading as each becomes relevant. Pillars, walls and kiosks fade when they hide the player. Music and SFX run on separate buses; tapes resume where they left off and crossfade when switched.

## Play the packaged build

Unzip `Y2K-BioPunk-VS1.1-win64.zip` and double-click `Y2K-BioPunk.exe` inside its folder (the extension DLL must stay beside the exe). Saves live in `%APPDATA%\Godot\app_userdata\Y2K- Bio-Punk\`. `Y2K-BioPunk.console.exe` runs the same game with a console for logs.

## Controls

| Input | Action |
|---|---|
| WASD | Camera-relative movement |
| Space | Jump; hop onto a rail; dismount a grind (slam) |
| LMB | Melee combo |
| RMB / F | Fire secondary weapon |
| Q | Cycle flamethrower / disk launcher |
| K | Toggle skates (+38 % speed, carving, rails) |
| Shift / V | Evade with invulnerability frames |
| T | Cycle Walkman tape (shifts STR/AGI/VIT/VIBE) |
| C / Esc | Character sheet (pauses the game) |

## Developer setup

1. Download **Godot 4.3 Stable for Windows** separately and put `Godot_v4.3-stable_win64.exe` at the repository root (gitignored).
2. Clone with bindings:

   ```powershell
   git clone --recurse-submodules https://github.com/adilisio/y2kBioPunk.git
   cd y2kBioPunk
   ```

3. Import `project.godot` in Godot 4.3 (Forward+). The repository ships both Windows extension DLLs in `bin/`.
4. Press **F5 -> intro -> menu -> New Game -> Flooded Mall**.

Agents run Godot headlessly only.

## Build the C++ extension

Install Python 3.9+, SCons and Visual Studio 2022 with the C++ Desktop workload. Close Godot instances that lock the DLL, then from the repository root:

```powershell
py -3 -m pip install scons
py -3 -m SCons platform=windows target=template_debug -j8
py -3 -m SCons platform=windows target=template_release -j8
```

Preserve SConstruct's `/MT` enforcement to match the bindings' static release runtime.

## Run the tests

```powershell
powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1
```

The runner discovers the 25 headless suites in `tests/`, checks failures and exit codes, and saves output in `ops/runs/tests/`. Run one with `./Godot_v4.3-stable_win64.exe --headless --path . -s tests/test_slice_e2e.gd`. Do not run suites from two checkouts at the same time (they share the `user://` save). A passing suite verifies scripted behaviour, not a visual/audio playtest.

## Release build

Requires the Godot 4.3 export templates (`%APPDATA%\Godot\export_templates\4.3.stable\`). From the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ops/tools/build_release.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File ops/tools/smoke_packaged.ps1
```

The first script rebuilds the release DLL if `src/` is newer, imports, exports the `Windows Desktop` (release) and `Windows Desktop QA` (debug + tests + harness) presets from `export_presets.cfg`, writes `build/release/BUILD-INFO.txt`, copies the music credits, and zips `build/release/` to `build/Y2K-BioPunk-VS1.1-win64.zip`. The second proves the pack contents, runs the end-to-end and menu tests inside the QA pack, and launches the release exe off-screen for 600 frames checking for errors. `build/` is gitignored.

## Project map

`src/` native player/intro/menu controllers; `scripts/` enemies, boss, HUD, saving, occlusion fader, effect warm-up, tutorial director and the runtime mall builder (source of truth for level geometry); `scenes/` canonical scenes and the player model; `assets/models/` Meshy GLBs; `music/` tapes; `sprites/` menu background; `tests/` headless suites; `ops/` the Director ledger, shared context, briefs, reports and tools.

See [AGENTS.md](AGENTS.md) for contracts and tooling, [GAME_SYNOPSIS.md](GAME_SYNOPSIS.md) for the vision and status, and the [Director ledger](ops/DIRECTOR_LEDGER.md) for verification evidence.

Created by Anthony Dilisio. Built with Godot Engine and godot-cpp. Music: see `music/CREDITS.md`.
