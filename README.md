# 📼 Y2K: Bio-Punk ARPG

<div align="center">

![Godot 4.3](https://img.shields.io/badge/Engine-Godot%204.3%20Forward%2B-blue?logo=godotengine&logoColor=white)
![C++ GDExtension](https://img.shields.io/badge/Core-C%2B%2B%20GDExtension-00599C?logo=c%2B%2B&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-lightgrey)
![Genre](https://img.shields.io/badge/Genre-Isometric%20Action%20RPG-ff69b4)
![Style](https://img.shields.io/badge/Style-Y2K%20%2F%20Retro%20Bio--Punk-lime)

*"The year 2000 didn't bring a digital apocalypse — it brought biological collapse.*  
*Now, surviving the wasteland takes grit, good skates, and the right mixtape."*

</div>

---

## ⚡ Overview

**Y2K: Bio-Punk ARPG** is a retro-future isometric action role-playing game built in **Godot Engine 4.3 (Forward+)** and powered by a high-performance **C++ GDExtension** core (`libbiopunk`).

The game fuses late-90s street culture—roller skates, cassette mixtapes, pagers, and translucent neon tech—with a post-apocalyptic bio-punk world overrun by mutated fauna, bio-engineered contamination, and stranded military remnants.

---

## 🎮 Key Features

### 🛹 High-Speed Momentum & Traversal
- **6-State Locomotion FSM**: Seamlessly transition between grounded walking, 12.0 m/s roller skate sprinting, vertical jumping with preserved air momentum, spline rail grinding, and power-slide dodging.
- **Dynamic Rail Grinding**: Lock onto 3D curve rails (`Path3D`) at 14 m/s while regenerating adrenaline (+10/sec).
- **Grind Dismount Slam**: Launch off any rail to trigger `execute_grind_slam()` — a directional shockwave AoE dealing heavy explosive damage.
- **Evade / Power-Slide**: Burst forward at 18.0 m/s with invincibility frames (`Shift` / `V`).

### 🏏 Street Combat & Arsenal
- **Baseball Bat Melee**: High-cadence swings with strict spatial hitbox detection (`AttackSensor` `Area3D`), directional knockback, and STR-scaling damage.
- **Secondary Weapon Arsenal**:
  - **Aerosol Flamethrower**: Sustained toxic spray ticks with dynamic green bio-hazard particle streams.
  - **Disk Launcher**: High-velocity CD projectiles ricocheting into enemy packs.

### 📼 Diegetic Walkman Mixtape Synergy
Your cassette player is your RPG stat engine. Switch between **8 genre-themed mixtapes** on the fly with `[T]` to alter your effective stats in real time:
- **Nu-Metal**: Massive Strength (STR) boost for heavy melee impact.
- **Eurodance & Big-Beat Rave**: Agility (AGI) and movement velocity amplification.
- **Skater Punk & Bubblegum Pop**: Vitality (VIT) and health restoration boosts.
- **Combat FIGHT & Hip-Hop Bounce**: Hybrid offensive buffs.
- **Vibe Checks**: High Vibe stats unlock special dialogue outcomes when interacting with wasteland survivors.

### 🪲 Bio-Mutant Enemy Roster & Boss
- **Neon Dial-Up Cicada**: Erratic 3D wander AI with emissive reactive flashes and knockback.
- **Sludge Roach**: 4-state pack predator with flanking sine-wave movement and predatory pounce leaps.
- **Corrupted Kiosk Turret**: Automated mall security kiosk constructing dynamic CSG geometry to launch arcing bio-sludge mortars.
- **The Dial-Up Queen (Boss)**: 600 HP, 3-phase titan with Modem Screech bio-shockwaves, minion summoning rings, and enrage transitions.

### 📟 Retro CRT Pager HUD
- **Authentic Pager Display**: BBCode-rendered health status, XP meters, and color-coded stat readouts.
- **Interactive Walkman Deck**: Animated equalizer bars and rotating tape reels reacting to the currently playing cassette.
- **Character Sheet (`[C]` modal)**: Allocate unspent stat points earned upon leveling up.

---

## 🕹️ Controls Reference

| Input | Action | Description |
|:---:|:---|:---|
| **`W` `A` `S` `D`** | Move | 45° Camera-relative isometric locomotion |
| **`Space`** | Jump | Leap into the air; maintains horizontal momentum |
| **`LMB`** | Melee Attack | Swing baseball bat (combo hits & knockback) |
| **`RMB` / `F`** | Secondary Weapon | Fire Aerosol Flamethrower or Disk Launcher |
| **`Q`** | Cycle Secondary | Swap between Flamethrower and Disk Launcher |
| **`K`** | Toggle Skates | Switch between standard walk (6 m/s) and skates (12 m/s) |
| **`Shift` / `V`** | Evade / Power-Slide | 18 m/s evasion burst with invincibility frames |
| **`T`** | Cycle Mixtape | Swap active Walkman cassette tape and stat buffs |
| **`C`** | Character Sheet | Open stat allocation and leveling modal |
| **`E`** | Interact | Speak with NPCs (trigger Vibe skill checks) |

---

## 🏗️ Architecture & Tech Stack

```
y2k-biopunk-rpg/
├── bin/                        # Precompiled GDExtension binaries
│   └── libbiopunk.windows.template_debug.x86_64.dll
├── godot-cpp/                  # Godot 4.3 C++ bindings (git submodule)
├── src/                        # C++ GDExtension source code
│   ├── player_controller.cpp/hpp   # Locomotion FSM, combat, Walkman system
│   ├── stranded_soldier_npc.cpp    # NPC dialogue & Vibe check logic
│   ├── intro_controller.cpp        # Video splash sequence
│   ├── menu_controller.cpp         # Main menu routing
│   └── register_types.cpp          # GDExtension entrypoint
├── scripts/                    # GDScript gameplay systems
│   ├── hud.gd                      # BBCode CRT Pager & Walkman HUD
│   ├── dial_up_queen.gd            # 3-Phase boss state machine
│   ├── neon_cicada.gd              # Cicada wander & knockback AI
│   ├── sludge_roach.gd             # Pounce predator AI
│   ├── corrupted_kiosk_turret.gd   # Mortar turret & CSG constructor
│   └── mall_greybox_builder.gd     # Procedural CSG mall level generator
├── scenes/                     # Scenes, meshes (.glb), materials, UI
├── music/                      # Walkman cassette audio tracks
└── tests/                      # Verification and test suites
```

---

## 🚀 Getting Started

### Option 1: Play Immediately (Godot 4.3)
The repository includes the prebuilt Windows x86_64 GDExtension DLL in `bin/`:
1. Clone the repository:
   ```bash
   git clone --recurse-submodules https://github.com/adilisio/y2kBioPunk.git
   ```
2. Open **Godot 4.3 Stable** (Forward+ renderer).
3. Import and open the project (`project.godot`).
4. Press **F5** to run!

### Option 2: Build C++ from Source
If you are modifying the C++ core in `src/`:

#### Prerequisites
- **Python 3.9+** and **SCons** (`pip install scons`)
- **Visual Studio 2022** with C++ Desktop Development (or GCC 11+ on Linux)
- **Godot 4.3 Stable**

#### Build Steps
```powershell
# 1. Clone with submodules
git clone --recurse-submodules https://github.com/adilisio/y2kBioPunk.git
cd y2kBioPunk

# 2. Build godot-cpp bindings (first time only)
cd godot-cpp
scons platform=windows target=template_debug
cd ..

# 3. Build libbiopunk extension
scons platform=windows target=template_debug
```

*Note: SConstruct automatically enforces the static release C++ runtime (`/MT`) to match `godot-cpp` and avoid runtime mismatch errors.*

---

## 🤖 For AI Agents & Contributors

If you are developing or contributing using an AI agent (Cursor, Antigravity, Claude Code, etc.), please refer to [AGENTS.md](AGENTS.md) for detailed technical conventions, state machine diagrams, and architectural guidelines.

For complete design vision, lore, and roadmap specifications, see [GAME_SYNOPSIS.md](GAME_SYNOPSIS.md).

---

## 📜 License

Created by Anthony Dilisio. Built with [Godot Engine](https://godotengine.org/) and [godot-cpp](https://github.com/godotengine/godot-cpp).
