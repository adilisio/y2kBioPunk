# Y2K: BIO-PUNK ARPG — Project Synopsis & Vision

> *"The year 2000 didn't bring digital apocalypse—it brought biological collapse. Now, surviving the wasteland takes grit, good skates, and the right mixtape."*

---

## 1. Executive Summary

**Y2K: Bio-Punk ARPG** is a retro-future isometric action role-playing game built in **Godot 4.3** (Forward+) powered by a **C++ GDExtension** core (`libbiopunk`) with GDScript gameplay systems.

The game fuses late-90s/Y2K street-culture aesthetics—roller skates, cassette mixtapes, pagers, CRT monitors, and translucent colored plastic—with a gritty bio-punk apocalyptic world overrun by mutated fauna and bio-engineered contamination.

---

## 2. The Vision: Thematic & Gameplay Pillars

### A. Thematic Identity: The "Millennium Glitch"
At midnight on December 31, 1999, automated bio-remediation protocols across military and municipal networks triggered a catastrophic mutation cascade instead of safeguarding infrastructure. Survivors scavenge decaying shopping malls, sewer lines, and abandoned transit tunnels, clinging to late-90s analog tech: translucent electronics, CRT pagers, and magnetic cassette tapes that resonate with bio-frequency shielding.

### B. Core Gameplay Pillars
1. **High-Speed Momentum & Urban Traversal**: grounded running, 12 m/s roller skating with carving, jumps that keep momentum, spline rail grinding with a dismount slam, and an evade with invulnerability frames.
2. **Tactile Street Combat**: a buffered baseball-bat combo with hit-stop and knockback, a flamethrower and a disk launcher in the off hand, and enemies that telegraph (amber wind-ups) before they bite.
3. **Diegetic Walkman Audio-Buff Synergy**: the in-game Walkman alters STR, AGI, VIT and VIBE in real time; eight genre tapes, each a different build.
4. **Retro Low-Poly Aesthetic**: late PS1/Dreamcast-era look, night-mall teal palette with magenta mutants and neon signage, CRT pager HUD.

---

## 3. Current State of Development

Status as of October 8, 2026: **Vertical Slice 1.1, the "showable build", is complete except for the owner's final playtest.** The authoritative record is `ops/DIRECTOR_LEDGER.md`.

### The slice (15-ish minutes, one run)
Intro video → menu → New Game. The player spawns in the flooded mall atrium beside a Bio-Stabilizer terminal, meets two Neon Cicadas within seconds, learns evade, tapes, skates, secondary weapons, grinding and turret reading from the pager as each becomes relevant, clears Sludge Roach packs at the fountain basin and two Corrupted Kiosk Turrets by the kiosks, levels up and spends points in a character sheet that pauses the game, and crosses the arena gate (which saves progression) to wake the three-phase Dial-Up Queen in her neon "MEGABYTE ELECTRONICS" server pit. Victory makes the player invulnerable, clears the floor, shows a completion card and returns to the menu; Continue restores the checkpoint. Death respawns at the Bio-Stabilizer with progression intact; enemies respawn (owner decision).

### What VS1.1 added over VS1 (all verified on `main`)
- A standalone Windows package (`build/Y2K-BioPunk-VS1.1-win64.zip`, 244 MB) with a validated export/release path and packaged smoke tests.
- Player occlusion fading for pillars, walls, mezzanine rails and kiosk props.
- Character sheet pauses the game with a clear overlay; project title and menu cleaned up.
- Presentation pass: tiled floor, wall trims, pillar caps, neon signage, dressed boss arena, checkpoint terminal, menu background, HUD fixes, softer tints, turret screen, water, shadow quality.
- Gameplay critic fixes: no silent progress loss, safe victory window, truthful and complete pager, telegraph colour semantics, Queen phase-3 timing and summon warning, disk/slam/cicada tuning, turrets idle during the boss, roach knockback.
- Effect warm-up before the first fight; performance re-measured at ~120 fps uncapped / stable 60 capped on the target laptop.
- Owner-feedback round after Anthony's playtest: turret identity (beacon, hazard ring, scan), a Queen that drifts, bobs and rises, scuttling roaches and fluttering cicadas, a bat in the player's hand, stats that explain themselves (VIBE = crit chance), sane leveling pace, and the Queen-summon stall fixed.
- 25 headless suites (VS1's 19 plus occlusion, character sheet, tuning, warm-up, identity, stats).

### Verification limits
Headless suites verify scripted behaviour and material/node state; presentation was accepted from in-engine screenshots and two independent critiques; audio was accepted by the owner's VS1 playtest. The owner's VS1.1 playtest (see the ledger checklist) is the remaining gate.

---

## 4. Technical Architecture

| Component | Specification |
|---|---|
| **Engine** | Godot Engine 4.3 Stable (Forward+ / 3D) |
| **Core Architecture** | C++ godot-cpp GDExtension (`libbiopunk`) for the player, intro and menu controllers; GDScript for enemies, boss, level generation, HUD, saving, occlusion, warm-up, projectiles |
| **Perspective** | Fixed 45° isometric camera, 12 m arm, FOV 45, camera-relative WASD |
| **Player State Machine** | `STATE_NORMAL(0)`, `STATE_ATTACKING(1)`, `STATE_GRINDING(2)`, `STATE_AIRBORNE(3)`, `STATE_EVADING(4)`, `STATE_DEAD(5)` |
| **Secondary Weapons** | `SECONDARY_NONE(0)`, `SECONDARY_SPRAY_FLAMETHROWER(1)`, `SECONDARY_DISK_LAUNCHER(2)` |
| **Combat Hitbox** | `AttackSensor` (`Area3D`, radius 2.2 m) |
| **Display** | 1920×1080 fullscreen (borderless), FSR 1.0 at 0.75 scale, MSAA 2x, SSAO/glow/fog |
| **Platform Target** | Windows x86_64 (release and debug GDExtension DLLs shipped) |
| **Package** | `export_presets.cfg` presets "Windows Desktop" (release) and "Windows Desktop QA" |
| **Input Actions** | WASD, Space, LMB, RMB/F, Q, K, T, Shift/V, C/Esc, E |

---

## 5. What's Next

- **Owner playtest** of the VS1.1 package (ledger checklist).
- **Post-VS1.1 polish** (not blockers): Queen HP / fight length, rails that connect areas, victory card art and key-press dismissal, Continue after victory, action-bar label size, floor material detail, stronger light pools.
- **Phase 2 ideas (deferred by Director ruling):** tape splicing, new enemies/weapons/biomes, controller support, NPC dialogue, save slots, kill persistence.

*Updated October 8, 2026. Reflects Vertical Slice 1.1 as merged on `main` (25/25 headless suites, packaged build validated).*
