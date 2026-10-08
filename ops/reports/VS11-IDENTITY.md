# VS11-IDENTITY — enemy identity and motion

Worktree: `C:\y2k-biopunk-rpg\.worktrees\vs11identity`, branch `vs11-identity`.
Read AGENTS.md, CONTEXT.md, the Owner playtest ledger entry, the requested scripts/tests, and the brief. Inspected the baseline `look.2.png` and `look2_grid.png` in the main checkout; all edits and executions remained in the assigned worktree.

## Changes

- **Turret:** preserved the GLB body and all combat values. Added a continuously rotating red emissive beacon with an eccentric OmniLight3D bulb (range 4, energy 1.2, no shadows), yellow/black thin base tori (outer radius 1.1), and a 50% larger CRT face (0.9 × 0.675 m, emission energy 2.0). CRT emission and ScreenGlow follow `_set_screen_color` exactly; the warning beacon stays red. With no target, the head scans ±35° over four seconds. The scan yields to existing tracking. Both GLB and CSG paths build these features; there are exactly two OmniLight3D nodes per turret, neither casting shadows.
- **Queen:** a `QueenMotion` visual assembly carries the GLB or the fallback thorax, antennae and wings. Idle/tracking visuals drift along a seven-second figure-eight (2.5 m amplitude), blended toward the existing facing. The assembly bobs ±0.35 m every 0.7 s and rolls ±6°. Charge blends in a 0.6 m rise; detonation drops the rise and squashes visual Y to 0.85 for 0.15 s. Summoning turns the visual 90° during the existing 1.5 s state; phase transitions make a full turn and a short rise during the existing transition. Collision, hurtbox, body-root movement, `aoe_center`, radii, charge durations, damage, HP, thresholds and summons are unchanged. Drift blends back toward the attack centre during charge/summon.
- **Roach:** moving visuals scuttle ±0.04 m at 9 Hz with ±4° yaw wobble. Wind-up retains the existing squash, and no scale animation is overwritten.
- **Cicada:** visual hover bob is ±0.1 m over 2.4 s; airborne/moving visual X flutters between 1.0 and 1.08 at 10 Hz. Flutter yields to wind-up and hurt squash. Both bugs use sin math in `_process`, with no per-frame tweens or new nodes.
- **Tests:** new `tests/test_identity.gd` exercises both GLB and CSG paths, node/light costs, screen ramp, idle scanning, tracking ownership, Queen drift, unchanged collision/AoE centres, phase radii 7/9/11 and charges 1.4/1.1/1.05, charge rise, detonation squash/recovery, summon/phase spins, and two successive moving-bug visual samples after one second. It manually samples the production process methods at deterministic 60 Hz. `test_encounters.gd`, `test_slice_e2e.gd` and `test_presentation.gd` are unchanged.

## Headless verification

Checked `Get-CimInstance Win32_Process -Filter "Name = 'Godot_v4.3-stable_win64.exe'"` before each suite. No VS11-STATS headless process was present at those launch points. Never ran another suite concurrently from this worktree. A VS11-STATS off-screen harness appeared near the end of the third suite; the required FPS measurement below occurred earlier with only this worktree's Godot present.

Command: `./Godot_v4.3-stable_win64.exe --headless --path . -s tests/test_identity.gd` (captured/waited with Start-Process; engine exit 0, approximately 3.1 s):

```text
=== test_identity (deterministic 60 Hz visual samples) ===
[DialUpQueen] *** BOSS SPAWNED *** The Dial-Up Queen looms with 1500 HP!
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 2 !!!!!!!
[DialUpQueen] *** BOSS SPAWNED *** The Dial-Up Queen looms with 1500 HP!
[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE 2 !!!!!!!
Checked GLB and CSG identity, motion, combat centres and timing contracts.
RESULT: PASS
EXIT: 0
```

Earlier full-suite attempts, each using `powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1`:

| Log under `ops/runs/tests/` | Runner exit | Observed result |
|---|---:|---|
| `20261008_151311.log` | 1 | 23/24 passed; menu assertions passed and engine exited 0, but runner caught warm-up teardown SCRIPT ERROR. Encounters and e2e passed. |
| `20261008_151657.log` | 1 | 23/24 passed; encounters exited 1 because the standing player remained at 100 HP. Menu and e2e passed. |
| `20261008_152110.log` | 1 | 23/24 passed; same menu warm-up teardown SCRIPT ERROR. Encounters and e2e passed. |

Exact failure excerpts:

```text
SCRIPT ERROR: Invalid access to property or key 'process_frame' on a base object of type 'null instance'.
          at: _begin (res://scripts/effect_warmup.gd:56)

PASS: standing mall player survives 20s (HP 100)
FAIL: cicada contact attacks hit the real player collision body
RESULT: FAIL (1 fails)
```

Standalone menu retry: `./Godot_v4.3-stable_win64.exe --headless --path . -s tests/test_menu_flow.gd`, captured/waited with Start-Process, exit 0:

```text
PASS: main menu loads
PASS: NewGameButton exists
PASS: Continue hidden without a save
PASS: New Game loads the mall (got res://scenes/FloodedMall_Greybox.tscn)
PASS: fresh player at level 1 in the mall
PASS: back to menu
PASS: Continue visible and labelled with a save
RESULT: PASS (0 fails)
EXIT: 0
```

Standalone unchanged encounter retry: `./Godot_v4.3-stable_win64.exe --headless --path . -s tests/test_encounters.gd`, captured/waited with Start-Process, exit 0; relevant pasted tail:

```text
PASS: nine spawns, two nearby cicadas, no nearby roaches
PASS: pre-boss roster supplies level-three XP (got 170)
[SaveManager] *** GAME SAVED *** Checkpoint 'BioStabilizer_01' | Level 1 | XP 0/50 | Tape 'Bubblegum'
[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for Player at BioStabilizer_01
PASS: standing mall player survives 20s (HP 40)
PASS: cicada contact attacks hit the real player collision body
RESULT: PASS (0 fails)
EXIT: 0
```

Passing the runner does not mean warning-free headless shutdown. Logs also contain Dummy renderer `Parameter "m" is null` messages, detached-tree messages in older tests, and resource/RID leak warnings from tests that quit without teardown. No such stderr messages appeared in the new identity test or the required rendered harness. No e2e c/g retry was needed in the first three suites; they all passed.

## Rendered verification and cost guard

Ran the exact requested steps, off-screen only, with exit 0:

```powershell
./Godot_v4.3-stable_win64.exe --path . --windowed --position 2000,2000 -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn out=ops/runs/shots/vs11identity/identity steps="invuln:1,tp:1:0.5:-10,wait:2.5,shot,wait:1.5,shot,tp:0:1:-21,wait:3,shot,wait:1.5,shot,wait:1.5,shot,fps:6"
```

Pasted output:

```text
[FPS] physics avg=2.34 ms max=3.27 ms | process max=9.66 ms | frames over 2x avg: 0 of 716 | active_objects=11 collision_pairs=88 islands=37
[FPS] frames=716 avg=119.2 fps (8.39 ms)  1%low=95.4 fps (10.48 ms)  worst=11.8 ms  3d=1440x810 scale=0.75 msaa=1 method=forward_plus
[FPS] process=9.28 ms physics=2.64 ms render_cpu=0.79 ms render_gpu=8.18 ms objects=415 primitives=236125 draw_calls=414
[FPS] env ssao=true glow=true fog=true
[FPS] lights=16 shadow_casting=1
[HARNESS] done; 5 shots
```

GPU check during this run: `nvidia-smi --query-gpu=pstate,clocks.gr,utilization.gpu,temperature.gpu --format=csv` printed `P0, 1670 MHz, 1 %, 72`. The snapshot is not an averaged utilization measure. The required measured GPU time was 8.18 ms, +0.38 ms versus the brief's 7.8 ms reference, within the +0.5 ms allowance. Draw calls were 414, +5 versus the ledger's arena reference of 409, within +30. This is a six-second phase-one sample, not a new whole-game performance guarantee.

Inspected every requested PNG (`ops/runs/shots/vs11identity/identity.*.png`):

1. `identity.0.png`: the turret beside Beeper World has a conspicuous yellow danger ring, enlarged CRT and glowing top beacon, while the food cart has none of those markers.
2. `identity.1.png`: the same turret's CRT has changed to bright amber, with the beacon and base ring still clearly separating it from the static carts.
3. `identity.2.png`: the arena and boss bar are visible, but the Queen is mostly clipped at the bottom edge, so this frame alone is insufficient to judge her motion.
4. `identity.3.png`: the Queen's body and wings appear at the lower left during the large red screech telegraph.
5. `identity.4.png`: the Queen has shifted upward and right at the lower left, above a smaller red charge disc, with the attack outline still anchored on the floor.

A first supplemental attempt (`queen-framed.*.png`, player moved to -4:1:-20) also clipped the Queen: frame 0 shows the empty arena above her off-screen body, frame 1 shows the pre-blast flash with only a sliver of the Queen at the bottom, and frame 2 shows the next charge disc and her clipped lower-edge silhouette. This attempt exited 0; it was not used as proof of readable Queen motion.

For a readable supplemental comparison, ran the same off-screen harness with `out=ops/runs/shots/vs11identity/queen-close` and `steps="invuln:1,tp:0:1:-21,wait:0.2,tp:0:1:-14,wait:3,shot,wait:1.5,shot,wait:1.5,shot"`, exit 0, then inspected all three PNGs:

1. `queen-close.0.png`: the Queen hovers to the player's right with a diagonally oriented body and spread wings, partly behind Neon Julius.
2. `queen-close.1.png`: the Queen has risen and moved toward the centre above the player, with her wings and body fully readable over the pre-blast flash.
3. `queen-close.2.png`: the Queen remains visibly elevated at a different roll and horizontal offset above the next charge disc while roaches surround the player.

No screenshot or helper under `ops/runs/` is committed. No editor was opened. No imports were hand-written or regenerated.

## Final suite output and STOP items

Final command: `powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1`, runner exit **0**, log `ops/runs/tests/20261008_152448.log`. All 24 suites passed on the unchanged final implementation. Pasted console output:

~~~text
=================================================================
 Y2K BIO-PUNK ARPG - TEST SUITE RUNNER
 Engine : C:\y2k-biopunk-rpg\.worktrees\vs11identity\Godot_v4.3-stable_win64.exe
 Worktree: C:\y2k-biopunk-rpg\.worktrees\vs11identity
 Timeout: 120s per test
=================================================================
Discovered 24 test suite files.
[PASS] test_3d_player.gd                (Code:  0, Time:  4.74s) - All checks passed
[PASS] test_5_systems.gd                (Code:  0, Time:   2.9s) - Passed (contains SKIP section)
[PASS] test_candy_pickup.gd             (Code:  0, Time:  0.76s) - All checks passed
[PASS] test_character_sheet.gd          (Code:  0, Time:  4.85s) - All checks passed
[PASS] test_critical_path.gd            (Code:  0, Time:  3.13s) - All checks passed
[PASS] test_cursor_aiming.gd            (Code:  0, Time:  0.85s) - All checks passed
[PASS] test_effect_warmup.gd            (Code:  0, Time:  3.36s) - All checks passed
[PASS] test_encounters.gd               (Code:  0, Time: 23.35s) - All checks passed
[PASS] test_feel_combat.gd              (Code:  0, Time:  3.34s) - All checks passed
[PASS] test_feel_movement.gd            (Code:  0, Time:  8.01s) - All checks passed
[PASS] test_feel_traversal.gd           (Code:  0, Time:   2.1s) - All checks passed
[PASS] test_flamethrower_particles.gd   (Code:  0, Time:  0.43s) - All checks passed
[PASS] test_gameplay_fixes.gd           (Code:  0, Time:  1.14s) - All checks passed
[PASS] test_grinding.gd                 (Code:  0, Time:  2.52s) - All checks passed
[PASS] test_identity.gd                 (Code:  0, Time:  1.68s) - All checks passed
[PASS] test_menu_flow.gd                (Code:  0, Time:  2.29s) - All checks passed
[PASS] test_occlusion.gd                (Code:  0, Time:  7.25s) - All checks passed
[PASS] test_onboarding.gd               (Code:  0, Time:  6.71s) - All checks passed
[PASS] test_presentation.gd             (Code:  0, Time:  1.51s) - All checks passed
[PASS] test_slice_e2e.gd                (Code:  0, Time: 17.18s) - All checks passed
[PASS] test_systems.gd                  (Code:  0, Time:  0.32s) - All checks passed
[PASS] test_tapes.gd                    (Code:  0, Time:  0.41s) - All checks passed
[PASS] test_tune.gd                     (Code:  0, Time:  2.79s) - All checks passed
[PASS] verify_camera_and_hud.gd         (Code:  0, Time:  0.57s) - All checks passed

=================================================================
 TEST RUN SUMMARY
=================================================================

Test                           Status ExitCode Time   Details
----                           ------ -------- ----   -------
test_3d_player.gd              PASS          0 4.74s  All checks passed
test_5_systems.gd              PASS          0 2.9s   Passed (contains SKIP section)
test_candy_pickup.gd           PASS          0 0.76s  All checks passed
test_character_sheet.gd        PASS          0 4.85s  All checks passed
test_critical_path.gd          PASS          0 3.13s  All checks passed
test_cursor_aiming.gd          PASS          0 0.85s  All checks passed
test_effect_warmup.gd          PASS          0 3.36s  All checks passed
test_encounters.gd             PASS          0 23.35s All checks passed
test_feel_combat.gd            PASS          0 3.34s  All checks passed
test_feel_movement.gd          PASS          0 8.01s  All checks passed
test_feel_traversal.gd         PASS          0 2.1s   All checks passed
test_flamethrower_particles.gd PASS          0 0.43s  All checks passed
test_gameplay_fixes.gd         PASS          0 1.14s  All checks passed
test_grinding.gd               PASS          0 2.52s  All checks passed
test_identity.gd               PASS          0 1.68s  All checks passed
test_menu_flow.gd              PASS          0 2.29s  All checks passed
test_occlusion.gd              PASS          0 7.25s  All checks passed
test_onboarding.gd             PASS          0 6.71s  All checks passed
test_presentation.gd           PASS          0 1.51s  All checks passed
test_slice_e2e.gd              PASS          0 17.18s All checks passed
test_systems.gd                PASS          0 0.32s  All checks passed
test_tapes.gd                  PASS          0 0.41s  All checks passed
test_tune.gd                   PASS          0 2.79s  All checks passed
verify_camera_and_hud.gd       PASS          0 0.57s  All checks passed



Totals: 24 tests | 24 PASSED | 0 FAILED
Full log saved to: C:\y2k-biopunk-rpg\.worktrees\vs11identity\ops\runs\tests\20261008_152448.log

Test suite PASSED successfully.

~~~

STOP items: no blocking packet work remains. Director follow-ups: the observed warm-up teardown coroutine race is outside this packet's ownership and should be fixed for reliable menu testing; the encounter standing-player contact assertion also varied without code changes. The prescribed arena viewpoint clips the large Queen at the lower edge in one requested frame; the supplemental south-side viewpoint shows all three Queen poses. Camera/arena framing changes remain outside this packet. No audio listening playtest or phase-two/three rendered performance claim is made.

`git diff --check` exited 0 (only Git's LF-to-CRLF conversion notices); no imports, DLLs, helper scripts, or runs artifacts are staged.
