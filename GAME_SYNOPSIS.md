# Y2K: BIO-PUNK ARPG — Project Synopsis & Vision

> *"The year 2000 didn't bring digital apocalypse—it brought biological collapse. Now, surviving the wasteland takes grit, good skates, and the right mixtape."*

---

## 1. Executive Summary

**Y2K: Bio-Punk ARPG** is a retro-future isometric action role-playing game built in **Godot 4.3** (Forward+) powered by a high-performance **C++ GDExtension** core (`libbiopunk`).

The game fuses late-90s/Y2K street-culture aesthetics—roller skates, cassette mixtapes, pagers, CRT monitors, and translucent colored plastic—with a gritty bio-punk apocalyptic world overrun by mutated fauna, bio-engineered contamination, and stranded military remnants.

---

## 2. The Vision: Thematic & Gameplay Pillars

### A. Thematic Identity: The "Millennium Glitch"
At midnight on December 31, 1999, automated bio-remediation protocols across military and municipal networks triggered a catastrophic mutation cascade instead of safeguarding infrastructure. Experimental bio-engineered agents consumed urban sprawl, releasing hyper-adaptive biological contaminants. Survivors scavenge decaying shopping malls, sewer lines, and abandoned transit tunnels, clinging to late-90s analog tech: translucent electronics, CRT pagers, and magnetic cassette tapes that resonate with bio-frequency shielding.

### B. Core Gameplay Pillars
1. **High-Speed Momentum & Urban Traversal**:
   Flow seamlessly between grounded running, 12 m/s roller skate sprinting, vertical jumping with preserved air momentum, and spline-based rail grinding along mall handrails and pipes. A dedicated evade/power-slide (Shift/V) lets you dodge through enemy attacks with invincibility frames.
2. **Tactile, Multi-Weapon Street Combat**:
   High-cadence melee (baseball bat combos) governed by strict spatial hitboxes (`Area3D`), attack acceleration, and directional knockback. A secondary off-hand weapon slot (Aerosol Flamethrower / Disk Launcher) adds ranged threat. Jumping off a grind rail triggers a directional shockwave slam attack.
3. **Diegetic Walkman Audio-Buff Synergy**:
   An in-game Walkman cassette deck dynamically alters RPG stats (STR, AGI, VIT, VIBE) in real-time. Genre-themed tapes (*Nu-Metal, Eurodance, Big-Beat Rave, Bubblegum Pop, Skater Punk, Hip-Hop Bounce, Pop-Rock Anthem, Combat FIGHT*) match player playstyle to musical rhythm.
4. **Retro Low-Poly Aesthetic**:
   Visual style inspired by late PS1 and Sega Dreamcast era: crisp low-poly meshes (Meshy AI-generated player character), uncalibrated vertex colors, CRT scanlines, and saturated neon-acid palettes.

---

## 3. Current State of Development

The game has evolved from early 2D prototypes into a fully playable **3D Isometric Action RPG** with a native C++ core, full enemy roster, boss, NPC dialogue, and a polished HUD. Here is an accurate accounting of what is **implemented and functional**:

---

### A. C++ Player Controller & Locomotion (`src/player_controller.cpp / .hpp`)

The player is a `CharacterBody3D` driven entirely in C++ GDExtension with a **6-state locomotion state machine**:

| State | Enum Value | Description |
|---|---|---|
| `STATE_NORMAL` | 0 | Standard WASD movement & idle |
| `STATE_ATTACKING` | 1 | Baseball bat melee swing lock window |
| `STATE_GRINDING` | 2 | Spline rail traversal at 12–14 m/s |
| `STATE_AIRBORNE` | 3 | Jump with preserved horizontal momentum |
| `STATE_EVADING` | 4 | Power-slide dodge with iframes & velocity boost |
| `STATE_DEAD` | 5 | No input, death VFX, 2.5s scene reload timer |

**Locomotion Details:**
- **Isometric 45° Camera-Relative Movement**: WASD inputs are transformed relative to the camera vector, Y-axis flattened for screen-relative navigation.
- **Independent Visuals Rotation**: Root `CharacterBody3D` holds world position; the inner `Visuals` node smoothly slerps toward movement vectors via `look_at()`.
- **Roller Skate Traversal**: Toggle with `[K]` — moves from 6.0 m/s walk to 12.0 m/s skate sprint. Animation speed scales accordingly.
- **Jump** (`[SPACE]`): 6.0 m/s vertical impulse; horizontal air momentum preserved via lerp.
- **Evade / Power-Slide** (`[SHIFT / V]`): 18.0 m/s burst with 0.35s duration, 0.8s cooldown, and temporary invincibility frames (`is_invincible = true`).

**Grind Rail System (`STATE_GRINDING`):**
- Snaps player onto `Path3D` curve rails at up to 14.0 m/s.
- Uses `PathFollow3D` to trace curved rails; dynamically calculates forward tangent via `sample_baked()` and reorients `Visuals` via `look_at()`.
- Generates adrenaline (+10/sec) while grinding.
- **Dismount Slam**: Exiting a rail triggers `execute_grind_slam()` — a directional shockwave AoE (`Area3D` query, 4.5m radius, 35 base damage) visualized by an expanding cyan/yellow `CylinderMesh` Tween effect.

**Death State (`STATE_DEAD`):**
- Triggered by `die()` when `current_health ≤ 0`.
- Stops all movement, disables all inputs (attack, evade, grind, secondary).
- Triggers a crimson bio-hazard flatline `MeshInstance3D` pulse effect via Tween.
- After 2.5 seconds, calls `get_tree()->reload_current_scene()`.
- Emits `player_died` signal (caught by HUD to display "NEURAL LINK LOST" message).

---

### B. Secondary Weapon Arsenal (C++)

Bound to `[RMB / F]`, with weapon cycling on `[Q]`:

| Weapon | Enum | Behavior |
|---|---|---|
| **Aerosol Flamethrower** | `SECONDARY_SPRAY_FLAMETHROWER` | Continuous damage tick while held; green/acid `GPUParticles3D` visual attached to `Visuals` node |
| **Disk Launcher** | `SECONDARY_DISK_LAUNCHER` | Single-shot projectile (`disk_projectile.gd`) with cooldown |

---

### C. Fast-Paced Melee Combat System (C++)

- **Melee**: Baseball bat swing (`[LMB]`) at `speed_scale = 2.0f`; damage = `base_attack_damage (15) × STR multiplier`.
- **Attack Sensor**: Dedicated `AttackSensor` (`Area3D`, radius = 2.2m) uses `get_overlapping_bodies()` / `get_overlapping_areas()` for strict spatial hit detection.
- **XP on Kill**: Enemies award XP; `gain_xp()` handles level-up cascades, awarding 1 unspent stat point per level.

---

### D. RPG Stat & Progression Engine (C++)

- **Four Stats**: Strength (STR), Agility (AGI), Vitality (VIT), Vibe.
- **Tape Buffs**: Active Walkman tape modifies **effective** stats on top of base stats. VIT × 10 = Max HP. AGI scales movement speed. STR scales melee damage. Vibe controls dialogue skill-checks.
- **Level-Up**: XP threshold scales ×1.5 per level. Each level awards 1 stat point, spendable via the Character Sheet (`[C]`).
- **Adrenaline Meter**: Separate resource that fills during rail grinding.
- **Unspent Stat Points**: Begin with 1 unspent point at level 1.

---

### E. Diegetic Walkman System (C++ & GDScript)

- **8 Genre Tapes** implemented: *Bubblegum Pop, Nu-Metal, Eurodance, Big-Beat Rave, Skater Punk, Combat FIGHT, Hip-Hop Bounce, Pop-Rock Anthem*.
- Tapes boost different stat combinations. Cycling with `[T]` rotates through the list.
- `switch_tape()` emits a `tape_switched` signal with a buff description string caught by the HUD.

---

### F. Enemy Roster (GDScript `CharacterBody3D` — all in `scripts/`)

| Enemy | Script | HP | Behavior |
|---|---|---|---|
| **Neon Dial-Up Cicada** | `neon_cicada.gd` | 50 | 3D wander AI; emissive red flash + squash-and-stretch hit reaction; directional 7.5 m/s knockback |
| **Sludge Roach** | `sludge_roach.gd` | 30 | 4-state machine: Idle → Tracking (flanking wave movement at 5.5 m/s) → Pouncing (leap + bite, 8.5 m/s) → Repositioning |
| **Corrupted Kiosk Turret** | `corrupted_kiosk_turret.gd` | 120 | 5-state machine: Idle → Tracking (head pivot lerp) → Charging (squash pulse) → Firing (bio-sludge mortar arc) → Cooldown; self-builds CSG visuals at runtime |

All enemies: award XP on death, flash red on hit, call `take_damage(amount, knockback_dir)`.

---

### G. The Dial-Up Queen Boss (`scripts/dial_up_queen.gd`)

- 600 HP, 3-phase boss with escalating speed, AoE radius, and summon count.
- **Phase 1** (>66% HP): 2.5 m/s, 7m AoE radius, summons 2 minions.
- **Phase 2** (33–66% HP): 4.0 m/s, 10m AoE radius, summons 3 minions. Transitions flash toxic-amber.
- **Phase 3** (<33% HP): 5.5 m/s, 12m AoE radius, summons 4 minions. Enraged neon-magenta.
- **AoE Attack**: "Modem Screech" bio-shockwave with telegraph ring visual expansion.
- **Minion Summon**: Spawns `SludgeRoach` instances in a ring around the boss.
- **Phase Transitions**: Temporary invulnerability window + player force-push repel.
- Emits `boss_health_changed`, `boss_phase_transition`, `boss_defeated` signals.

---

### H. Turret Mortar Projectile (`scripts/turret_mortar.gd`)

- `Area3D` projectile with arcing physics (`vel + Vector3(0, 4.5, 0)` at 14 m/s), queued up by the Kiosk Turret.
- `setup(spawn_pos, vel, damage, source)` initializes after `add_child()` to prevent null-position errors.

---

### I. NPC & Dialogue System (`src/stranded_soldier_npc.cpp`)

- **Stranded Soldier NPC** (`Area2D` in 3D scene): Proximity detection (E key), dialogue window trigger, movement lock/unlock.
- **Vibe Check**: Compares player's `get_effective_vibe()` against a DC of 15. Pass/fail dialogue outcomes displayed in the HUD's `DialogueBox` modal.
- Full dialogue UI: Speaker label, body text, two choice buttons (Standard / Vibe), Exit button.

---

### J. Greybox Environment (`scenes/FloodedMall_Greybox.tscn` / `scripts/mall_greybox_builder.gd`)

- **Procedural CSG Blockout** of a 50×50m flooded shopping mall atrium:
  - Sunken basin with water plane (micro-offset +0.05m eliminates Z-fighting).
  - Mezzanine terrace + 15° ramp.
  - Colonnade slalom (pillars for skate navigation).
  - Curved and straight `Path3D` grind rails elevated along mezzanine edges.
- **Enemy Spawner**: Procedurally scatters Neon Cicadas, Sludge Roaches, and Corrupted Kiosk Turrets.
- Builder is `@tool`-compatible — can rebuild the level from the editor Inspector.

---

### K. CRT Pager HUD (`scripts/hud.gd` / scenes)

- **Pager Box** (top-left, 0.7 scale): Real-time HP bar + color-coded BBCode RichTextLabel (green/yellow/red by HP %), XP bar, stat readout (STR/AGI/VIT/VIBE in color), equipment mode, color-coded control tips.
- **Walkman Box** (bottom-right, 0.7 scale): Active tape name, buff description, animated equalizer bars, spinning cassette reel characters.
- **Character Sheet** (modal, `[C]`): Full stat breakdown with `+1` buttons per stat; unspent point counter.
- **Dialogue Modal**: Full NPC dialogue window with choice buttons and vibe-check pass/fail text.
- **Death State**: On `player_died` signal → displays "⚠ CRITICAL BIO-FAILURE // FLATLINE" and "NEURAL LINK LOST. REBOOTING SYSTEM CLONE..."
- HUD uses `MarginContainer + VBoxContainer` (separation 8px) with `RichTextLabel` (BBCode enabled, fit_content, scroll off) throughout.

---

### L. Intro, Main Menu & Scenes

- **Intro Screen** (`scenes/intro.tscn`): Video playback (`intro_video.ogv`) via C++ `IntroController`.
- **Main Menu** (`scenes/main_menu.tscn`): C++ `MenuController` handles New Game / Quit.
- **Main Scene** (`scenes/main.tscn`): Spawns Player with AI-generated Meshy character model and all systems active.
- **Player Model**: Meshy AI-generated biopunk delinquent `.glb` with Walking, Running, and All_Animations sets.

---

### M. Pickups & Consumables (`scenes/health_candy_pickup.tscn` / `scripts/health_candy_pickup.gd`)

- **Fruit Candy Health Pickup (Gushers-Style Bio-Candy Pack)**:
  - Small, standalone, zero-inventory pickup system.
  - Floating, rotating Gusher-style candy jewel (ruby-magenta hexagonal outer shell + glowing neon electric-lime juice core + OmniLight3D glow).
  - Walk into / touch trigger (`collision_layer = 0`, `collision_mask = 1 | 2`).
  - Restores **10 HP**, strictly clamped to player `max_health` (e.g. 60/100 -> 70/100; 95/100 -> 100/100).
  - Plays a juicy procedural 8-bit squish pop and rising chime "YUM!" sound effect.
  - Single-use guarantee: disappears immediately upon pickup and queues free cleanly.

---

## 4. Technical Architecture

| Component | Specification |
|---|---|
| **Engine** | Godot Engine 4.3 Stable (Forward+ / 3D) |
| **Core Architecture** | C++ godot-cpp GDExtension (`libbiopunk`) for player, combat, NPC; GDScript for enemy AI, level generation, HUD, projectiles |
| **Perspective** | Fixed 45° Isometric 3D with camera-relative WASD movement |
| **Player State Machine** | `STATE_NORMAL(0)`, `STATE_ATTACKING(1)`, `STATE_GRINDING(2)`, `STATE_AIRBORNE(3)`, `STATE_EVADING(4)`, `STATE_DEAD(5)` |
| **Secondary Weapons** | `SECONDARY_NONE(0)`, `SECONDARY_SPRAY_FLAMETHROWER(1)`, `SECONDARY_DISK_LAUNCHER(2)` |
| **Combat Hitbox** | `AttackSensor` (`Area3D`, radius = 2.2m) with strict spatial overlap filtering |
| **Display** | 1920×1080, Windowed Fullscreen (borderless), canvas stretch expand |
| **Platform Target** | PC (Windows primary; Linux compatible) |
| **Compiled Binary** | `bin/libbiopunk.windows.template_debug.x86_64.dll` |
| **Input Actions** | WASD (move), Space (jump), LMB (attack), RMB/F (secondary), Q (cycle secondary), K (toggle skates), T (cycle tape), Shift/V (evade), C (character sheet), E (interact) |

---

## 5. What's Still Missing / Next Steps

### Phase 2: Polish & Core Feel
- **Actual 3D Camera Rig**: Currently a fixed camera; implement a proper `SpringArm3D` isometric rig with a locked 45° angle and smooth follow.
- **Audio**: No SFX for attacks, enemy hits, death, or evade. Walkman audio plays (slot exists) but tracks not wired. Needs sound design pass.
- **Collision Layers**: Enemy/player collision layers need audit — enemies currently use broad detection rather than proper physics masks.

### Phase 3: Content & World
- **Tape Splice Mechanic**: Combine A-side and B-side tapes at workbench stations for hybrid stat profiles.
- **Second Biome**: Transition from the Flooded Mall to the *Subterranean Cable Catacombs* or *Suburban Asphalt Strip*.
- **Enemy Variety**: Additional archetypes beyond the current three (Cicada, Roach, Turret) — e.g., a melee brute or an aerial enemy.

### Phase 4: Metagame
- **Faction Quests & Vibe Checks**: Expand dialogue trees beyond the Stranded Soldier. More NPC types with passing/failing consequences.
- **Save System**: No persistence yet; death reloads scene from scratch.

---

*Document last updated: September 2026. Reflects all implemented C++ locomotion, 6-state player FSM, 3-enemy roster, Dial-Up Queen boss, Stranded Soldier NPC vibe-check dialogue, secondary weapon arsenal, grind slam attack, evade/power-slide, player death state, BBCode HUD, Walkman tape system, and procedural mall greybox.*
