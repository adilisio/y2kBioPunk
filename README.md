# Y2K: Bio-Punk ARPG

A retro-future isometric action RPG built in Godot 4.3 Stable (Forward+) with a C++ godot-cpp GDExtension and GDScript gameplay systems. Roller skates, cassette stat buffs and a CRT pager meet a flooded mall full of mutated bio-fauna.

Windows x86_64 is the supported platform for now. The extension manifest has no Linux library entry.

## Vertical Slice 1

Start a fresh run in the Flooded Mall, fight telegraphed cicada lunges, roach pounces and kiosk mortars, earn XP and spend stat points. Skate, enter aligned grind rails and land a dismount slam; Bio-Stabilizers save checkpoint progression for death respawns and Continue. Entering the north arena awakens the three-phase Dial-Up Queen (1500 HP). Queen defeat shows a victory card, records completion and returns to the menu. The native soldier/dialogue system is dormant in this slice.

The pager teaches movement, swinging, evade, tapes, skates, grinding and turret reading as each becomes relevant. Music and SFX run on separate buses; tapes resume where they left off and crossfade when switched. All of this is merged on `main` and covered by the 18-suite headless test gate.

## Getting Started

1. Download **Godot 4.3 Stable for Windows** separately; the engine executable is not in the repository.
2. Clone with bindings:

   ```powershell
   git clone --recurse-submodules https://github.com/adilisio/y2kBioPunk.git
   cd y2kBioPunk
   ```

3. Import `project.godot` in Godot 4.3 (Forward+). The repository supplies the Windows debug extension DLL in `bin/`.
4. Press **F5 -> intro -> menu -> New Game -> Flooded Mall**. New Game clears the old save. Continue restores the last checkpoint when a save exists.

These editor/play steps are for human players. Agents run Godot headlessly only.

## Controls

| Input | Action |
|---|---|
| WASD | Camera-relative movement |
| Space | Jump; dismount a grind |
| LMB | Melee combo; dismount a grind |
| RMB / F | Fire secondary weapon |
| Q | Cycle flamethrower / disk launcher |
| K | Toggle skates with momentum and carving |
| Shift / V | Evade with temporary invulnerability |
| T | Cycle Walkman tape and effective stat buffs |
| C | Character sheet and stat allocation |
| E | Interaction binding (soldier is not placed in the slice) |

## Build the C++ Extension

Install Python 3.9+, SCons and Visual Studio 2022 with the C++ Desktop workload. Close Godot editor/game instances that lock the DLL, then run from the repository root:

```powershell
py -3 -m pip install scons
py -3 -m SCons platform=windows target=template_debug -j8
```

SCons builds the bindings and `bin/libbiopunk.windows.template_debug.x86_64.dll`. Preserve SConstruct's `/MT` enforcement to match the bindings' static release runtime.

## Run the Tests

```powershell
powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1
```

The runner looks for `Godot_v4.3-stable_win64.exe` at the repository root (gitignored); pass `-GodotBin <path>` if it lives elsewhere. The runner discovers headless tests, checks failures and exit codes, and saves output in `ops/runs/tests/`. To run one test:

```powershell
./Godot_v4.3-stable_win64.exe --headless --path . -s tests/test_slice_e2e.gd
```

A passing suite verifies scripted behavior; existing teardown/dummy-renderer diagnostics and a legacy save-test skip are documented in the WP-7 report. It does not certify a visual/audio playtest.

## Project Map

`src/` owns native player/flow code; `scripts/` owns enemies, HUD, saving and runtime mall generation; `scenes/` owns canonical scenes and models (including `neon_cicada.tscn`); `music/` contains tapes; `tests/` contains headless checks. `ops/` contains the authoritative ledger, shared context, packet briefs/reports and tools.

See [AGENTS.md](AGENTS.md) for contracts and tooling, [GAME_SYNOPSIS.md](GAME_SYNOPSIS.md) for the vision and current status, and [Director ledger](ops/DIRECTOR_LEDGER.md) for verification evidence.

Created by Anthony Dilisio. Built with Godot Engine and godot-cpp.
