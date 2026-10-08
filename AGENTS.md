# AGENTS.md — Agent & Developer Operational Manual

> **Project**: Y2K Bio-Punk ARPG  
> **Engine**: Godot Engine 4.3 Stable (Forward+ / 3D)  
> **Core Extension**: C++ GDExtension (`libbiopunk` via `godot-cpp`)  
> **Scripting**: GDScript 2.0 (Enemy AI, Greybox generation, HUD, Consumables)

---

## 1. System Architecture & Component Division

The game uses a **hybrid C++ GDExtension + GDScript architecture** designed for high simulation performance and rapid gameplay iteration.

```
                        ┌──────────────────────────────────────────────┐
                        │              Godot 4.3 Engine                │
                        └──────────────────────┬───────────────────────┘
                                               │
               ┌───────────────────────────────┴───────────────────────────────┐
               ▼                                                               ▼
 ┌───────────────────────────┐                                   ┌───────────────────────────┐
 │   C++ GDExtension Core    │                                   │     GDScript Systems      │
 │       (src/*.cpp)         │                                   │       (scripts/*.gd)      │
 ├───────────────────────────┤                                   ├───────────────────────────┤
 │ • PlayerController        │                                   │ • Enemy AI & Behaviors    │
 │   - 6-State FSM           │                                   │   - Neon Dial-Up Cicada   │
 │   - Locomotion (Walk/Skate)◄─── Signals & Method Calls ───────►   - Sludge Roach (Pounce) │
 │   - Rail Grinding & Slams │                                   │   - Corrupted Kiosk Turret│
 │   - Melee AttackSensor    │                                   │ • Dial-Up Queen (Boss)    │
 │   - Secondary Weapons     │                                   │ • MallGreyboxBuilder      │
 │   - Walkman Tape Synergies│                                   │ • CRT Pager HUD (BBCode)  │
 │ • IntroController         │                                   │ • Health Candy Pickups    │
 │ • MenuController          │                                   │ • Isometric Camera Rig    │
 │                           │                                   │ • SaveManager Autoload    │
 └───────────────────────────┘                                   └───────────────────────────┘
```

### What Lives in C++ (`src/`)
- **`PlayerController`** (`CharacterBody3D`):
  - 6-state locomotion FSM: `STATE_NORMAL` (0), `STATE_ATTACKING` (1), `STATE_GRINDING` (2), `STATE_AIRBORNE` (3), `STATE_EVADING` (4), `STATE_DEAD` (5).
  - Camera-relative 45° isometric movement transform; decoupled `Visuals` rotation lerp.
  - Roller skate toggle: stat/tape-derived walking speed and 12 m/s base skating; acceleration, coast, braking and speed-dependent carving. Air steering preserves momentum.
  - Spline rail grinding along `Path3D` via `PathFollow3D` with dynamic tangent orientation.
  - Aligned, moving, airborne/jump rail entry; manual dismount queues `execute_grind_slam()` until landing (4.5m radius AoE).
  - Evade / power-slide with temporary immunity. All transitions use `set_state`, including exit cleanup; evade-to-attack is refused. Damage grants 0.6 s hurt i-frames, flash, knockback and camera shake.
  - Melee attack registration via `AttackSensor` (`Area3D`, 2.2m radius).
  - Secondary weapon arsenal: Aerosol Flamethrower (continuous tick + particles) and Disk Launcher.
  - Walkman Cassette tape engine modifying real-time effective stats (STR, AGI, VIT, VIBE).
- **`IntroController` & `MenuController`**: Scene flow and menu transitions.
- **`register_types.cpp`**: GDExtension initialization symbol `biopunk_library_init`.

### What Lives in GDScript (`scripts/`)
- **Enemy AI Entities**:
  - `neon_cicada.gd`: wander/chase AI with telegraphed contact lunge, hit reaction and directional knockback (70 HP).
  - `sludge_roach.gd`: flank, wind-up, pounce and vulnerable recovery with pack attack limits (45 HP).
  - `corrupted_kiosk_turret.gd`: Stationary mortar turret with arc projectile launcher; the whole kiosk model turns on the head pivot and a screen-glow light carries the state colour.
  - `enemy_model.gd` (`EnemyModel`): attaches a GLB under a root Node3D fitted to a target height, faces -Z, grounds it, and tints via `material_overlay` so hit flashes keep textures. Every enemy falls back to its CSG body when the GLB is missing.
- **Boss Encounter**:
  - `dial_up_queen.gd`: 3-phase modem boss (1500 HP) featuring Modem Screech AoE, minion summons, and shockwave pulses.
- **Level & World Generation**:
  - `mall_greybox_builder.gd`: `@tool` procedural CSG flooded shopping mall atrium generator with mezzanine, ramps, slalom pillars, and grind rails.
- **User Interface & Feedback**:
  - `hud.gd`: Retro CRT pager display (top-left) with dynamic BBCode health/XP/stat readouts, Walkman deck with animated equalizer and cassette reels, and character sheet (`[C]`).
- **Gameplay Objects & Pickups**:
  - `health_candy_pickup.gd`: Gusher-style bio-candy restoring 10 HP with sound chime.
  - `disk_projectile.gd` & `turret_mortar.gd`: Arcing and linear combat projectiles.
  - `isometric_camera.gd`: SpringArm3D follow, look-ahead and trauma shake; 12 m arm and 45-degree FOV, fixed isometric orientation. Camera collision is disabled for stable framing.
  - `occlusion_fader.gd`: created by the builder at runtime; registers tall CSG boxes/cylinders and prop meshes with world AABBs, tests the camera->player segment each physics tick and fades occluders with per-instance `GeometryInstance3D.transparency` (target 0.7, hold 0.15 s, warm-up, restore on exit).
  - `effect_warmup.gd`: `EffectWarmup` node in the mall scene; draws every combat shader variant through sub-pixel in-frustum probes and caches SFX recipes before the first fight, then frees itself.

---

## 2. Directory Layout

```
y2k-biopunk-rpg/
├── .gitignore                  # Excludes .godot, intermediate build files, large engine exes
├── .gitmodules                 # Submodule configuration for godot-cpp (branch 4.3)
├── AGENTS.md                   # This instruction manual
├── biopunk.gdextension         # Godot GDExtension manifest
├── GAME_SYNOPSIS.md            # Complete game design and technical spec
├── README.md                   # Public repository documentation
├── SConstruct                  # SCons build script (enforces MSVC /MT flag)
├── project.godot               # Godot 4.3 project definition & input bindings
│
├── export_presets.cfg          # "Windows Desktop" (release) and "Windows Desktop QA" presets
├── bin/                        # Compiled shared libraries (both committed)
│   ├── libbiopunk.windows.template_debug.x86_64.dll
│   └── libbiopunk.windows.template_release.x86_64.dll
│
├── godot-cpp/                  # Official C++ bindings submodule (branch 4.3)
│
├── src/                        # C++ GDExtension source code
│   ├── intro_controller.cpp / .hpp
│   ├── menu_controller.cpp / .hpp
│   ├── player_controller.cpp / .hpp
│   └── register_types.cpp / .hpp
│
├── scripts/                    # GDScript gameplay logic
│   ├── boss_encounter_trigger.gd
│   ├── checkpoint.gd
│   ├── corrupted_kiosk_turret.gd
│   ├── dial_up_queen.gd
│   ├── disk_projectile.gd
│   ├── effect_warmup.gd
│   ├── enemy_model.gd
│   ├── health_candy_pickup.gd
│   ├── hud.gd
│   ├── isometric_camera.gd
│   ├── mall_greybox_builder.gd
│   ├── neon_cicada.gd
│   ├── occlusion_fader.gd
│   ├── save_manager.gd
│   ├── sludge_roach.gd
│   ├── tutorial_director.gd
│   └── turret_mortar.gd
│
├── scenes/                     # Godot scenes and the player model
│   ├── FloodedMall_Greybox.tscn
│   ├── dial_up_queen.tscn / health_candy_pickup.tscn / neon_cicada.tscn / player.tscn
│   ├── intro.tscn / main_menu.tscn
│   └── Meshy_AI_biopunk_delinquent_te_All_Animations.glb (+ its 3 textures)
├── build/                      # gitignored: release/, qa/ and the zip from build_release.ps1
│
├── assets/models/              # Meshy-generated GLBs (enemies, boss, props) + their .import files
├── music/                      # Cassette tape audio tracks (+ CREDITS.md)
├── sprites/                    # menu_bg.jpg (menu background)
|-- ops/                        # CONTEXT.md, DIRECTOR_LEDGER.md, briefs/, reports/, tools/, runs/; ops/secrets/ is gitignored
`-- tests/                      # Headless SceneTree scripts; inventory below
```

---

## 3. Toolchain & Build Instructions

### Prerequisites
- **Python 3.9+** and **SCons 4.x** (`pip install scons`)
- **C++ Compiler**:
  - Windows: Visual Studio 2022 (MSVC v143) with C++ Desktop Workload
  - Linux: GCC 11+ or Clang 14+
- **Godot 4.3 Stable** (Forward+ renderer)

### Building the C++ GDExtension
From the repository root:

```powershell
# Initialize and sync submodule if freshly cloned
git submodule update --init --recursive

# Compile godot-cpp (if not already compiled in godot-cpp directory)
cd godot-cpp
scons platform=windows target=template_debug
cd ..

# Build libbiopunk DLL
scons platform=windows target=template_debug
```

### Headless verification and tooling

Download Godot 4.3 separately: the engine executable is gitignored, not supplied by a fresh clone. From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1    # finds Godot_v4.3-stable_win64.exe at the repo root (gitignored) or pass -GodotBin
./Godot_v4.3-stable_win64.exe --headless --path . -s tests/test_slice_e2e.gd
```

The runner discovers `test_*.gd` and `verify_*.gd`, checks exit codes, script errors and failed results, enforces a timeout, and stores logs in `ops/runs/tests/`. `_test_util.gd` provides assertions, cleanup and isolated saves. Passing does not imply warning-free rendering or an audio playtest.

Current tests (23): `test_3d_player`, `test_5_systems`, `test_candy_pickup`, `test_character_sheet`, `test_critical_path`, `test_cursor_aiming`, `test_effect_warmup`, `test_encounters`, `test_feel_combat`, `test_feel_movement`, `test_feel_traversal`, `test_flamethrower_particles`, `test_gameplay_fixes`, `test_grinding`, `test_menu_flow`, `test_occlusion`, `test_onboarding`, `test_presentation`, `test_slice_e2e`, `test_systems`, `test_tapes`, `test_tune`, and `verify_camera_and_hud` (all `.gd`). Suites share the `user://` save: never run them from two checkouts at once.

Release packaging: `powershell -NoProfile -ExecutionPolicy Bypass -File ops/tools/build_release.ps1` (rebuilds the release DLL when `src/` is newer, imports, exports both presets, writes `build/release/BUILD-INFO.txt`, zips to `build/Y2K-BioPunk-VS1.1-win64.zip`) then `ops/tools/smoke_packaged.ps1` (pck content proof, e2e + menu tests inside the QA pack, off-screen release launch). Needs the Godot 4.3 export templates in `%APPDATA%\Godot\export_templates\4.3.stable\`.

`ops/tools/meshy/meshy_gen.py` generates textured GLBs from `manifest.json` via the Meshy Text-to-3D API (key from `MESHY_API_KEY` or gitignored `ops/secrets/meshy.key`; task ids cached under `ops/runs/meshy/` so reruns do not re-spend credits). After adding a GLB run `--import` headlessly, then `ops/tools/inspect_glb.gd -- res://assets/models/<name>.glb` for bounds and `ops/tools/check_enemy_models.gd` to confirm each enemy attaches its model and flashes. GLB imports use `gltf/embedded_image_handling=3` so textures stay inside the imported scene instead of being extracted as loose JPEGs.

`ops/tools/shot_harness.gd` captures in-engine screenshots and scripted input with `scene=`, `out=` and `steps=` arguments after `--`. Steps include `wait`, `shot`, `press`, `hold`, `release`, `key`, `quit`, `tp:x:y:z`, `heal`, `invuln:0|1`, `dmg:<name>:<amount>`, `fps:<s>`, `profile:<s>`, `bench`, `firstuse` and shadow/effect A/B toggles. Launch with `--windowed --position 2000,2000`; the HUD skips its fullscreen switch when `--windowed` is present. It requires rendered/windowed Godot and is Director/human tooling: agents must not run it windowed or claim headless screenshots prove presentation. `shot.ps1` is also windowed tooling. `sim_steer.gd`, `smoke_mall.gd` and `balance_table.gd` are diagnostics; `build_greybox.gd` is a scene generator, not a test.

`ops/tools/setup_worktree.ps1 -Name <packet> -Branch <branch> -From main` creates a worktree, copies local engine/bindings/DLL and imports headlessly. Use only when worktree creation is authorized; an assigned existing worktree must be retained.

### Critical Build Flag Rule (MSVC `/MT`)
`SConstruct` explicitly strips debug runtime flags (`/MDd`, `/MTd`, etc.) and forces `/MT` (static release runtime) to match the runtime used by `godot-cpp`. **Do not bypass this in SConstruct**, otherwise the linker will fail with `LNK2038: mismatch detected for 'RuntimeLibrary'`.

---

## 4. Key Conventions for Agents

### Working with C++ Classes
- **Class Registration**: When adding a new C++ class, remember to include its header in [register_types.cpp](src/register_types.cpp) and register it in `initialize_biopunk_module()` with `GDREGISTER_CLASS(MyClass)`.
- **Method Binding**: Bind methods in `_bind_methods()` with `ClassDB::bind_method(D_METHOD("method_name"), &ClassName::method_name)`.
- **Properties**: Expose properties using `ClassDB::add_property()` with getters and setters so they are accessible from GDScript and the Godot Inspector.
- **Signals**: Register signals via `ADD_SIGNAL(MethodInfo("signal_name", PropertyInfo(...)))`.

### Working with GDScript & Enemies
- **Standard Damage Interface**: All damageable entities must implement:
  ```gdscript
  func take_damage(amount: int, dir: Vector3 = Vector3.ZERO) -> void:
  ```
- **Player Damage Interface**: To damage the player from GDScript:
  ```gdscript
  if body.has_method("take_damage"):
      body.take_damage(damage_amount, knockback_vector)
  ```
- **Native player damage**: `take_damage(float amount, const Vector3 &knockback = Vector3())` is bound with an optional second argument.
- **Direction contract**: Pass a normalized direction (or zero), not a velocity in m/s. Receivers apply their own impulse; cicada/roach normalize supplied directions and clamp magnitude scaling. Combo hits can deliberately scale the direction.
- **XP Dispersal**: Each enemy guards death and calls `player.gain_xp(xp_amount)` exactly once; repeated lethal hits must not duplicate rewards.
- **Player signals**: Bindings in `player_controller.cpp` expose hurt/health, attack, stats, tape/skates, XP/level/stat spending, adrenaline, grind start/end/slam, evade start/end, secondary fire/switch, and `player_died`.

### Session, Level and Boss Contracts
- `SaveManager` is the persistent autoload. New Game calls `clear_save()` and clears load/respawn intent; Continue sets `pending_load`. HUD consumes this flag to restore checkpoint position, progression, stats and tape with full health.
- Death sets `respawn_pending`; after reload the HUD restores the last Bio-Stabilizer save, then clears the flag. Ordinary level entry must not blindly apply a stale save. Respawn restores checkpoint progression, not an arbitrary dead snapshot.
- `mark_slice_complete()` persists `slice_complete` on Queen defeat; on `boss_defeated` the HUD makes the player invincible, every `enemies` node is freed, the victory card appears after 1.2 s and the menu returns 6 s after defeat. Entering the arena saves progression as `ArenaGate` (respawn position stays the Bio-Stabilizer's); the Bio-Stabilizer heals to full and pages `PROGRESS SAVED`.
- The character sheet (C; closed by C, Esc or the button) sets `get_tree().paused = true`; the HUD runs with `PROCESS_MODE_ALWAYS`, the pager timer does not advance while paused, the player's Walkman keeps playing, and the sheet cannot open while dead or during victory.
- The boss gate is entry-triggered at z = -19, independent of clearing every enemy. `boss_encounter_trigger.gd` owns spawning; HUD owns boss display and victory flow.
- `mall_greybox_builder.gd` rebuilds runtime geometry and encounters: it is the source of truth rather than stale baked `.tscn` geometry.
- Onboarding and audio (WP-6, merged): `tutorial_director.gd` gates pager hints (move/swing, evade, tape, skates, grind, turret) on player state; the player creates `Music` and `SFX` buses at startup (music -8 dB), tapes resume their position and crossfade on switch, and cues fire for swing/hit/hurt/jump/land/evade/grind/pickup/kill/clack/level-up/pager. Covered by `tests/test_onboarding.gd`.
- The dormant native `StrandedSoldierNPC` / `MutatedBugEnemy` classes and the HUD dialogue box were deleted on 2026-10-08; the native library registers only the player, menu and intro controllers. The menu has NEW GAME / CONTINUE / EXIT GAME only.
- Telegraph colours: wind-ups amber `(1.0, 0.75, 0.2)`, hit flashes red, roach vulnerable window pale cyan, turret screen/light green->yellow->red, Queen ring red with a magenta-white pre-blast flash. Keep state tints at alpha ~0.3 so textures stay readable.

### Isometric Geometry & Movement
- The isometric camera sits at a 45° angle.
- Player movement takes standard WASD and projects it onto the isometric plane:
  ```cpp
  Vector3 forward = -camera_transform.basis.get_column(2);
  Vector3 right = camera_transform.basis.get_column(0);
  forward.y = 0.0f; forward.normalize();
  right.y = 0.0f; right.normalize();
  Vector3 move_dir = (right * input_dir.x + forward * input_dir.y).normalized();
  ```

### Windows File Lock Considerations
When testing during development, if the Godot Editor or game instance is running, Windows will lock `bin/libbiopunk.windows.template_debug.x86_64.dll`. Always close the running game before rebuilding with `scons`.

---

## 5. Input Action Mapping Reference

| Action Name | Default Key/Mouse | Behavior |
|---|---|---|
| `move_forward` / `move_backward` | `W` / `S` | Move forward / back relative to 45° camera |
| `move_left` / `move_right` | `A` / `D` | Move left / right relative to 45° camera |
| `jump` | `Space` | Jump (7.2 m/s vertical impulse) |
| `attack` / `bat_swing` | `LMB` | Melee baseball bat attack combo |
| `secondary_fire` / `secondary_attack` | `RMB` / `F` | Fire secondary weapon (Flamethrower / Disks) |
| `cycle_secondary` | `Q` | Cycle active secondary weapon |
| `toggle_skates` / `equip_skates` | `K` | Toggle roller skates (momentum, coast and carving) |
| `switch_tape` | `T` | Cycle active Walkman mixtape |
| `evade` | `Shift` / `V` | Power-slide dodge with invincibility frames |
| `toggle_character_sheet` | `C` (Esc closes) | Toggle character sheet; pauses the game |
| `interact` | `E` | Talk to NPCs / interact with world objects |


## 6. Rules for Agents

- Stay in the assigned worktree and follow the packet's file ownership. The ledger's Verified entries supersede historical baseline claims in `ops/CONTEXT.md`.
- Run Godot headlessly only; never open the editor or a windowed game from an agent. Close relevant game/editor instances before building to avoid DLL locks; do not kill other agents' processes.
- Report actual commands, exit codes and pasted output. Distinguish verified behavior, estimates, warnings and unfinished work.
- Commit before finishing when the packet/user requires it; that explicit instruction overrides CONTEXT's older Director-only commit policy.
- Do not rewrite `project.godot` wholesale (an agent did and dropped settings), do not commit helper scripts you wrote for yourself, and do not hand-write `.import` files: run `--import` and let Godot generate them.
- Do not commit generated `*.import` churn or run scene generators as tests.
