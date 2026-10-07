# WP-4 — Encounters

Implemented in `C:/y2k-biopunk-rpg/.worktrees/wp4`, branch `wp4-encounters`. No branch creation, C++ edits, DLL rebuild, scene edits, or camera/HUD/save/trigger changes. Mesh construction functions are preserved. Shared procedural audio, transient particles, and floor queries live in the owned mortar script.

## Changes

- Roaches: 3.5m trigger, 0.35s red/squash/hiss wind-up, committed 11m/s pounce for up to 0.4s, one 10-damage bite, 1.2s recovery at 2m/s with 1.5x incoming damage. Scene-root metadata allows only two concurrent wind-ups/pounces; recovery, death, target loss, and removal release slots.
- Cicadas: 50HP, 3m/s chase, 0.5s flare/emission wind-up, committed 1.5m lunge, one 6-damage contact hit, 1.5s cooldown from lunge start, 10XP. Contact uses horizontal distance plus a vertical guard so real capsule bodies can be hit.
- Turrets: retain green/yellow/red screen stages, add rising charge tones, predict target by velocity x 0.6s, clamp horizontal launch range to 6–18m, solve a gravity trajectory to the floor. Mortars mark the 2.2m splash in red at alpha 0.4, grow the marker through flight, ignore airborne player overlaps, and deal one 20-damage landing splash with eight orange particles and launch/impact sounds.
- Queen: charge durations 1.4/1.1/0.9s and radii 7/9/11m. Full thin red outline (alpha 0.6) appears immediately at a floor-anchored center; the existing disc fills, flashes white for the final 0.1s, and detonates with a 0.25s expanding ring, 12 particles, boom, and camera trauma 0.5 through the active camera's parent. Interruptions clean up telegraphs. Living summons are capped at four and retain `summoned_by_boss` tags.
- All four enemies guard death exactly once, award existing XP exactly once, stop attacking, and emit ten colored particles with a short pop/crunch. Detached effects finish after the enemy's shrink. Signed PCM8 sound samples use zero silence and negative samples encoded as two's-complement bytes. No enemy hit-stop added.
- Nine pre-boss enemies: two plaza cicadas at x ±6/z6, three north-basin roaches, two unchanged turret positions, and one cicada/roach pair at the mezzanine ramp/deck entrance. The raised pair starts above the deck collision surface. Total XP is 170 (3x10 + 4x15 + 2x40), exceeding the 125 needed for level three.

## TTK / TTD estimates

These are **code-derived ideal timing estimates, not observed combat benchmarks**. Level-one Bubblegum stats: STR10/AGI18/VIBE14. Bat hits 40/40/60 at nominal 0.10/0.35/0.68s in each 0.87s combo; flame is integer 13 damage per 0.12s tick; disk is integer 64 damage every 0.45s. All attacks connect continuously. Excludes approach, hit-stop, physics-frame rounding, knockback/repositioning, and disk travel. First flame/disk hit is counted at t=0.

| Enemy | HP | Bat TTK | Flame TTK | Disk TTK | Enemy TTD vs 100HP |
|---|---:|---:|---:|---:|---|
| Cicada | 50 | 0.35s (2 hits) | 0.36s (4 ticks) | 0s + travel (1 disk) | ≥32.5s: 17 bites, 0.5s first wind-up, ≥2s between lunges |
| Roach | 30 | 0.10s (1 hit) | 0.24s (3 ticks) | 0s + travel (1 disk) | ≥14.3s: 10 bites; 0.35s wind-up + 1.2s recovery, plus pounce/reposition travel |
| Turret | 120 | 0.68s (3 hits) | 1.08s (10 ticks) | 0.45s + travel (2 disks) | ~17.6s at 10m: 5 splashes, 1.6s charge stages, ~0.83s flight, 3.8s launch cycle |
| Queen | 600 | 3.58s before invulnerability (13 hits) | 5.52s before invulnerability (47 ticks) | 4.05s + travel before invulnerability (10 disks) | Phase1 ~12s (5x20); phase2 ~6.8s / phase3 ~6s (4x28), assuming only repeated close-range AoEs |

Queen TTK also pays two 1.8s invulnerable transitions (roughly another 3.6s with attacks resumed optimally); missed attacks during those windows increase it. Roach recovery makes two 13-damage flame ticks become two 20-damage ticks: ideal recovery flame TTK is 0.12s. Player hurt i-frames suppress simultaneous swarm hits; the observed standing-player test ended at **46HP after 20 seconds**, rather than the sum of both cicadas' nominal DPS.

## Verification

Executed `powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1`. Actual final results follow below. The new regression test exercises telegraph timing, cooldown damage suppression, two-slot pack limit and cleanup, recovery vulnerability/speed, signed audio, simulated ballistic landing, full queen outlines/durations, summon cap, five rapid lethal hits plus a direct repeated `_die()` for every enemy, nine-spawn safety/XP, and real standing-player survival/contact damage for 20 seconds. It restores the save file after its mall simulation.

Earlier runs failed on a turret inferred type, a test-file encoding issue, and the legacy isolated PlayerController aggro assertion; all were corrected before the final suite. No failed run is presented as a pass.

Final runner log: `ops/runs/tests/20261007_170206.log`; runner exit code **0**. Verbatim result lines:

```text
--- END: tests/test_3d_player.gd (ExitCode: 0, Time: 4.76s) ---
--- END: tests/test_5_systems.gd (ExitCode: 0, Time: 1.33s) ---
--- END: tests/test_candy_pickup.gd (ExitCode: 0, Time: 0.77s) ---
--- END: tests/test_critical_path.gd (ExitCode: 0, Time: 1.36s) ---
--- END: tests/test_cursor_aiming.gd (ExitCode: 0, Time: 0.88s) ---
--- END: tests/test_encounters.gd (ExitCode: 0, Time: 21.86s) ---
--- END: tests/test_feel_combat.gd (ExitCode: 0, Time: 3.22s) ---
--- END: tests/test_feel_movement.gd (ExitCode: 0, Time: 7.95s) ---
--- END: tests/test_feel_traversal.gd (ExitCode: 0, Time: 2.11s) ---
--- END: tests/test_flamethrower_particles.gd (ExitCode: 0, Time: 0.43s) ---
--- END: tests/test_gameplay_fixes.gd (ExitCode: 0, Time: 0.95s) ---
--- END: tests/test_grinding.gd (ExitCode: 0, Time: 1.23s) ---
--- END: tests/test_systems.gd (ExitCode: 0, Time: 0.44s) ---
--- END: tests/test_tapes.gd (ExitCode: 0, Time: 0.32s) ---
--- END: tests/verify_camera_and_hud.gd (ExitCode: 0, Time: 0.58s) ---
SUMMARY: 15 Total | 15 PASSED | 0 FAILED
```

Verbatim encounter assertions / ballistic landing:

```text
PASS: enemy SFX uses signed PCM8 with zero silence
PASS: roach winds up at 3.5 m
PASS: roach cannot damage in first 0.3 seconds
PASS: pack permits at most two attacks
PASS: roach recovery is 1.2s at 2m/s
PASS: recovery takes 1.5x damage
PASS: pack slots released on removal
PASS: cicada wind-up deals no damage
PASS: cicada lunge deals six damage exactly once
PASS: cicada cooldown is at least 1.4s
PASS: cicada cannot deal a second hit during 1.4s cooldown
PASS: mortar marks the splash landing point
[TurretMortar] Splash at (9.999995, 0.039999, 0) (radius 2.2m)
PASS: ballistic mortar lands within 1m at 10m range
PASS: queen phase 1 charge duration
PASS: queen phase 1 shows full radius immediately
PASS: queen phase 2 charge duration
PASS: queen phase 2 shows full radius immediately
PASS: queen phase 3 charge duration
PASS: queen phase 3 shows full radius immediately
PASS: queen caps living summons at four
PASS: sludge_roach.gd death awards XP once under five rapid hits
PASS: neon_cicada.gd death awards XP once under five rapid hits
PASS: corrupted_kiosk_turret.gd death awards XP once under five rapid hits
PASS: dial_up_queen.gd death awards XP once under five rapid hits
PASS: nine spawns, two nearby cicadas, no nearby roaches
PASS: pre-boss roster supplies level-three XP (got 170)
PASS: standing mall player survives 20s (HP 46)
PASS: cicada contact attacks hit the real player collision body
RESULT: PASS (0 fails)
```

Required smoke command:

```powershell
./Godot_v4.3-stable_win64.exe --headless --path . -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn "steps=wait:20,quit"
```

Observed smoke process exit code: **0**. Verbatim stdout:

```text
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 1 | XP 0/50 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] lunge (1.5m, 6 damage)
[NeonDialUpCicada] wind-up (0.5s)
[NeonDialUpCicada] wind-up (0.5s)
[HARNESS] done; 0 shots
```

Verbatim smoke stderr:

```text
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
```

## Skipped items / limits

- No requested gameplay scope item skipped. Windowed visual/audio QA was not performed; shared context permits headless testing only. These runs establish script behavior, not perceived effect quality.
- Existing systems-test skip, verbatim:

```text
SKIP: Save / Checkpoint section skipped (SaveManager.SAVE_PATH is a constant/read-only property; skipping to avoid overwriting production save)
```

- Headless suite logs include dummy-renderer null-mesh diagnostics and some teardown resource-leak diagnostics. The required runner reported zero script/assertion/timeout failures on the final run; this report does not claim warning-free execution.
- Changes remain uncommitted under `ops/CONTEXT.md`: “Never commit; the Director integrates.” This conflicts with the brief's commit-trailer section; no commits were created. Generated `*.import` changes were restored; `ops/runs` stays ignored and uncommitted.
