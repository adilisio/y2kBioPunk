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

Status as of October 7, 2026, grounded in the Director ledger's **Verified (merged to main)** entries. Historical audit baselines describe earlier defects, not the current slice.

### Playable Flow and Progression (WP-1)

F5 runs the intro and menu; New Game clears stale saves and enters `scenes/FloodedMall_Greybox.tscn` with full health at level 1. Continue restores checkpoint progression. Enemies award XP exactly once on death. Bio-Stabilizers save stats, tape, XP, points and position; death reloads and restores the checkpoint with full health. The boss wakes on arena entry at z = -19 without requiring a mall clear. Defeat shows a victory card, records `slice_complete` and returns to the menu.

### Player Feel and Camera (WP-2 and Director Integration)

The native six-state controller uses `set_state` for transitions and exit cleanup; attacks during evade are refused. Grounded animation poses, looping/blended locomotion and speed matching replace the floating frozen model. Walking accelerates and brakes; skating coasts and carves; air steering preserves momentum. Jumps support release cutting, coyote time and buffering. Buffered melee combos align damage with animation, add hit-stop and camera shake. Hurt feedback includes flash, sound, knockback and 0.6 s immunity. Rail entry checks movement/alignment and airborne/jump intent; manual dismount queues its slam until landing. The follow camera uses a 12 m arm and 45-degree FOV.

The flamethrower and disk launcher are active secondary weapons. Walkman tapes alter effective STR, AGI, VIT and VIBE. Native synthesized SFX use signed PCM and cached rotating voices. The registered soldier and native bug enemy are unused by the active slice.

### Presentation and Runtime Level (WP-3)

The runtime mall builder is the source of truth, replacing stale baked geometry. Environment glow, SSAO and fog, brighter lighting, emissive rails, contrasting enemy silhouettes and cutaway walls improve readability. The HUD uses native scale with health/XP/stat readouts, adrenaline, queued pager messages, Walkman display and a character sheet.

### Encounters and Balance (WP-4 and Director Pass)

The pre-boss roster contains nine enemies worth 170 experience points. Cicadas have telegraphed contact lunges (70 HP); roaches wind up before pouncing and have vulnerable recovery with pack limits (45 HP); kiosks launch ballistic mortars with landing markers (120 HP). Death guards prevent repeated rewards. The Queen has 1500 HP, three phases, minion summons and invulnerable transitions. Screech telegraphs match their damage radii: 7/9/11 m with charge durations 1.4/1.1/0.9 s.

### Verification (WP-5 and WP-7)

The headless runner checks exit codes, script errors and failed results, with bounded per-test timeouts and persistent logs. Lifecycle/cleanup fixes repaired previously crashing tests. The end-to-end test drives fresh start, exact kill XP, level/stat spending, checkpoint save, death/respawn restoration, real rail entry, landing slam, boss phases/summons, victory, menu and Continue visibility. The ledger records three consecutive end-to-end passes. Its latest balance entry records a passing suite; WP-7 documents retained dummy-renderer/resource diagnostics and the legacy save-test skip. These are scripted gates, not proof of warning-free execution or a human audio/visual playtest.

### Onboarding and Audio (WP-6)

The pager is the voice of the game: `tutorial_director.gd` surfaces move/swing at spawn, then evade, tape, skates, grind and turret-reading hints as each becomes relevant. Music and SFX have their own buses (music -8 dB); tapes resume their position and crossfade on switch; cues exist for swing, hit, hurt, jump, land, evade, grind, pickup, kill, clack, level-up and pager. Merged and covered by `tests/test_onboarding.gd`. Nobody has yet listened to the mix; that is a playtest item.

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
| **Platform Target** | PC (Windows x86_64; no Linux manifest entry) |
| **Compiled Binary** | `bin/libbiopunk.windows.template_debug.x86_64.dll` |
| **Input Actions** | WASD (move), Space (jump), LMB (attack), RMB/F (secondary), Q (cycle secondary), K (toggle skates), T (cycle tape), Shift/V (evade), C (character sheet), E (interact) |

---

## 5. What's Still Missing / Next Steps

Mirror of the Director ledger's outstanding work and deferred scope:

- Must fix before showing people: a human audio pass (all SFX are procedural 8-bit, verified only by signal tests; the music/SFX mix is a guess), a mouse-and-keyboard playtest in a real window (aim, skate turn feel, grind entry tolerance are tuned to numbers), and a decision on whether death should keep respawning the whole enemy roster.
- Should fix: pillar fade when pillars occlude the player, 4.5 m north/west perimeter walls, placeholder roach/cicada silhouettes, camera occlusion at the mezzanine edge, no paused visual while the character sheet is open, dormant native NPC/enemy classes, Windows debug DLL only.
- Open taste decisions for Anthony: camera distance (12 m vs 16 m), walk-vs-skate contrast, SFX character and mix, death respawn policy, roach pack size.
- Deferred beyond Vertical Slice 1: new enemies, weapons and biomes; NPC/dialogue content; tape splicing; controller support. These are outside the slice's definition of done.
- Existing dummy-renderer/teardown diagnostics and the legacy save-test skip remain verification limits recorded by WP-7; passing test gates do not assert warning-free output.

*Updated October 7, 2026. Reflects Vertical Slice 1 as merged on `main` (all eight definition-of-done criteria, 18/18 headless suites).*
