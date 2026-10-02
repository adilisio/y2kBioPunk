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
 │ • StrandedSoldierNPC      │                                   │ • Health Candy Pickups    │
 │ • IntroController         │                                   │ • Isometric Camera Rig    │
 │ • MenuController          │                                   │ • SaveManager Autoload    │
 └───────────────────────────┘                                   └───────────────────────────┘
```

### What Lives in C++ (`src/`)
- **`PlayerController`** (`CharacterBody3D`):
  - 6-state locomotion FSM: `STATE_NORMAL` (0), `STATE_ATTACKING` (1), `STATE_GRINDING` (2), `STATE_AIRBORNE` (3), `STATE_EVADING` (4), `STATE_DEAD` (5).
  - Camera-relative 45° isometric movement transform; decoupled `Visuals` rotation lerp.
  - Roller skate toggle (6.0 m/s walking ➔ 12.0 m/s skating).
  - Spline rail grinding along `Path3D` via `PathFollow3D` with dynamic tangent orientation.
  - Grind dismount shockwave slam (`execute_grind_slam()`, 4.5m radius AoE).
  - Evade / power-slide with invincibility frames (`is_invincible = true`).
  - Melee attack registration via `AttackSensor` (`Area3D`, 2.2m radius).
  - Secondary weapon arsenal: Aerosol Flamethrower (continuous tick + particles) and Disk Launcher.
  - Walkman Cassette tape engine modifying real-time effective stats (STR, AGI, VIT, VIBE).
- **`StrandedSoldierNPC`**: Proximity interaction, dialogue trigger, Vibe skill check (DC 15).
- **`IntroController` & `MenuController`**: Scene flow and menu transitions.
- **`register_types.cpp`**: GDExtension initialization symbol `biopunk_library_init`.

### What Lives in GDScript (`scripts/`)
- **Enemy AI Entities**:
  - `neon_cicada.gd`: 3D wander AI, emissive flash hit reaction, 7.5 m/s knockback.
  - `sludge_roach.gd`: 4-state flank/pounce AI (Idle ➔ Flanking wave ➔ Pouncing leap ➔ Repositioning).
  - `corrupted_kiosk_turret.gd`: Stationary mortar turret with dynamic CSG mesh construction and arc projectile launcher.
- **Boss Encounter**:
  - `dial_up_queen.gd`: 3-phase modem boss (600 HP) featuring Modem Screech AoE, minion summons, and shockwave pulses.
- **Level & World Generation**:
  - `mall_greybox_builder.gd`: `@tool` procedural CSG flooded shopping mall atrium generator with mezzanine, ramps, slalom pillars, and grind rails.
- **User Interface & Feedback**:
  - `hud.gd`: Retro CRT pager display (top-left) with dynamic BBCode health/XP/stat readouts, Walkman deck with animated equalizer and cassette reels, and character sheet (`[C]`).
- **Gameplay Objects & Pickups**:
  - `health_candy_pickup.gd`: Gusher-style bio-candy restoring 10 HP with sound chime.
  - `disk_projectile.gd` & `turret_mortar.gd`: Arcing and linear combat projectiles.
  - `isometric_camera.gd`: Camera tracking player with fixed isometric offset.

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
├── bin/                        # Compiled shared libraries
│   └── libbiopunk.windows.template_debug.x86_64.dll
│
├── godot-cpp/                  # Official C++ bindings submodule (branch 4.3)
│
├── src/                        # C++ GDExtension source code
│   ├── intro_controller.cpp / .hpp
│   ├── menu_controller.cpp / .hpp
│   ├── mutated_bug_enemy.cpp / .hpp
│   ├── player_controller.cpp / .hpp
│   ├── register_types.cpp / .hpp
│   └── stranded_soldier_npc.cpp / .hpp
│
├── scripts/                    # GDScript gameplay logic
│   ├── boss_encounter_trigger.gd
│   ├── checkpoint.gd
│   ├── corrupted_kiosk_turret.gd
│   ├── dial_up_queen.gd
│   ├── disk_projectile.gd
│   ├── health_candy_pickup.gd
│   ├── hud.gd
│   ├── isometric_camera.gd
│   ├── mall_greybox_builder.gd
│   ├── neon_cicada.gd
│   ├── save_manager.gd
│   ├── sludge_roach.gd
│   └── turret_mortar.gd
│
├── scenes/                     # Godot scenes, 3D models, textures, animations
│   ├── FloodedMall_Greybox.tscn
│   ├── intro.tscn
│   ├── main.tscn
│   ├── main_menu.tscn
│   ├── player.tscn
│   └── Meshy_AI_biopunk_delinquent_*.glb
│
├── music/                      # Cassette tape audio tracks
├── sprites/                    # Spritesheets & 2D art
└── tests/                      # Verification and test GDScripts
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

### Critical Build Flag Rule (MSVC `/MT`)
`SConstruct` explicitly strips debug runtime flags (`/MDd`, `/MTd`, etc.) and forces `/MT` (static release runtime) to match the runtime used by `godot-cpp`. **Do not bypass this in SConstruct**, otherwise the linker will fail with `LNK2038: mismatch detected for 'RuntimeLibrary'`.

---

## 4. Key Conventions for Agents

### Working with C++ Classes
- **Class Registration**: When adding a new C++ class, remember to include its header in [register_types.cpp](file:///C:/Users/14404/Desktop/game/y2k-biopunk-rpg/src/register_types.cpp) and register it in `initialize_biopunk_module()` with `GDREGISTER_CLASS(MyClass)`.
- **Method Binding**: Bind methods in `_bind_methods()` with `ClassDB::bind_method(D_METHOD("method_name"), &ClassName::method_name)`.
- **Properties**: Expose properties using `ClassDB::add_property()` with getters and setters so they are accessible from GDScript and the Godot Inspector.
- **Signals**: Register signals via `ADD_SIGNAL(MethodInfo("signal_name", PropertyInfo(...)))`.

### Working with GDScript & Enemies
- **Standard Damage Interface**: All damageable entities must implement:
  ```gdscript
  func take_damage(amount: int, knockback_dir: Vector3 = Vector3.ZERO) -> void:
  ```
- **Player Damage Interface**: To damage the player from GDScript:
  ```gdscript
  if body.has_method("take_damage"):
      body.take_damage(damage_amount, knockback_vector)
  ```
- **XP Dispersal**: When an enemy dies, it awards XP by calling `player.gain_xp(xp_amount)`.

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
| `jump` | `Space` | Jump (6.0 m/s vertical impulse) |
| `attack` / `bat_swing` | `LMB` | Melee baseball bat attack combo |
| `secondary_fire` / `secondary_attack` | `RMB` / `F` | Fire secondary weapon (Flamethrower / Disks) |
| `cycle_secondary` | `Q` | Cycle active secondary weapon |
| `toggle_skates` / `equip_skates`| `K` | Toggle roller skates (6 m/s walk ➔ 12 m/s sprint) |
| `switch_tape` | `T` | Cycle active Walkman mixtape |
| `evade` | `Shift` / `V` | Power-slide dodge with invincibility frames |
| `toggle_character_sheet` | `C` | Toggle character sheet modal |
| `interact` | `E` | Talk to NPCs / interact with world objects |
