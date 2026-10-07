# WP-2 feel core — implementation and verification

Completed in `C:/y2k-biopunk-rpg/.worktrees/wp2`, on the existing `wp2-feel-core` branch. No branch creation or merge. Read AGENTS.md, CONTEXT.md, AUDIT-FEEL.md and the relevant AUDIT-ARCH.md findings. The brief's explicit commit and off-screen screenshot instructions governed over the older CONTEXT.md defaults.

## Changes by scope item

1. **Ground and animation.** Changed only the GLB-origin line in each of the three allowed scenes, from Y=1 to Y=0. Set default animation blend to 0.12s and loop Walking, Running and Skate_Grind when available. Walking uses Running scaled by horizontal speed / 2.62, clamped to 0.8–2.2. Skating above 6m/s uses Skate_Grind, or Running at 2.2 when unavailable. Idle samples Punch_Combo_1 at 2.10; airborne samples Running at 0.18. Aiming and movement share visual-basis slerp at rotation speed 25. Aiming while backpedaling reverses animation playback. Removed obsolete 2.0 speed writes.

   Verification found that the actual frozen guard clip has toes 0.186m above the body origin after the scene-origin fix. A bounded stance-only Visuals offset grounds that pose to a 0.05m toe gap; the scene GLB origins remain zero. Paused clips cannot advance blend weights, so frozen poses are sampled with zero custom blend and only resampled on pose changes. Playing clips retain the 0.12s default blend. This avoids repeatedly restarting a blend into a paused pose.

2. **Momentum and jump.** Walk acceleration/braking/coast use 70/90/90m/s². Skate acceleration/coast/brake use 16/4/28m/s², with a 360→200deg/s carve limit as speed rises from 6 to 12m/s. Air steering uses a horizontal move_toward budget of 20m/s² and a 180deg/s direction limit; releasing input preserves air momentum. Landing does not reset horizontal velocity. Jump uses 7.2m/s, rise/fall gravity 22/36, release cut ×0.5, 0.10s coyote time and 0.12s buffering. Camera XZ/Y follow rates are 9/3 per second, with velocity look-ahead ×0.18 capped at 2.5m. Added trauma² shake with 0.35 offsets and decay 1.8/s.

3. **Melee.** Three buffered punches sample 0.45/0.80/1.15 at speed 2.4. Impact timers are 0.10/0.06/0.10s; each swing lasts 0.29s. Clicks in the final 0.15s buffer the next punch. Hit three multiplies damage and knockback by 1.5. Attack movement is ×0.25, with a 4m/s facing lunge lasting 0.08s. Confirmed hits add 0.25 camera trauma and 0.06s real-time hit-stop; punch three uses 0.10s. Hit-stop uses a real-time clock deadline, supports extension by overlapping hits, restores the previous time scale, and restores immediately on scene exit.

4. **Hurt feedback.** Bound take_damage(amount, knockback=Vector3.ZERO), preserving one-argument callers. Added 0.6s post-hit immunity, white/red skin overlays for 0.08/0.10s, hurt audio, 0.45 camera trauma and player_hurt(amount). Supplied knockback produces 7m/s for 0.12s. External horizontal velocity writes also receive a 0.12s hold so boss shoves survive locomotion. Original overlays are restored. Hurt impulses take priority over the attack lunge.

5. **SFX.** Corrected every native synthesis branch to signed PCM8 and changed only the allowed byte-format line in health_candy_pickup.gd. Added hurt, jump and land cues. Four voices rotate round-robin and reuse cached streams. READY preloads all nine cues. Lazy initialization preserves the existing public play_sfx API for off-tree/pre-READY callers; this was required by test_5_systems. READY is idempotent for legacy tests that explicitly send READY notifications.

6. **Grind.** Entry requires horizontal speed ≥4m/s, alignment abs(dot) ≥0.5, and airborne status or a jump press within 0.15s. Entry position lerps to the advancing rail point over 0.06s. Manual dismount requires a newly pressed jump/attack after a 0.15s grace period. Manual dismount queues its slam until the first floor-contact frame; the disc appears 0.05m above the body/floor, with 0.10s hit-stop and 0.6 trauma. Exit carries the 15m/s boosted rail momentum.

7. **Evade.** Duration 0.22s, initial speed 24m/s, smooth easing toward movement speed over the final 30%, immunity for the first 0.18s, cooldown 0.35s. Exit preserves the final horizontal velocity.

8. **State integrity.** Every state transition uses set_state. Evade exit clears its immunity/timer, starts cooldown and emits evade_ended once; attack exit clears pending hit, lunge, combo buffer and attack status; grind exit releases path/follow state and emits grind_ended. Dead-state exit also clears its immunity. Dialogue locks cancel transient states cleanly. Melee during evade is deliberately **refused**. Grind rejects attacking, evading and locked players. Gameplay input is dispatched once, in physics; render processing only maintains real-time hit-stop. Melee moves the sensor before a fresh PhysicsDirectSpaceState3D shape query, excludes the world layer and player RIDs, filters damage receivers/cone/height, and deduplicates hits.

9. **Damage getter.** Added and bound get_effective_bat_damage(), sharing the native formula with melee and Walkman logging. All existing bound method names remain present. HUD files were untouched.

## Measured baseline and final results

Same authored mall fixture, enemies/UI/encounter callbacks removed, 60Hz physics, default Bubblegum tape. Baseline ran before source changes; logs are in ops/runs/wp2-baseline.log. Final movement log is ops/runs/test_feel_movement.log.

| Measurement | Before | After |
|---|---:|---:|
| Left toe / floor gap | 1.075936m | 0.050245m |
| Walk time to 7m/s | 0.016667s | 0.100000s |
| Skate time to 7m/s | 0.016667s | 0.450000s |
| Skate speed 0.5s after input release | 0m/s | 8.481626m/s |
| Held-jump apex | 1.887741m | 1.239630m |
| Held-jump airtime | 1.250000s | 0.616667s |
| HP lost to two hits within two frames | 20 | 10 |

Additional final measurements/assertions: release-cut apex 0.579909m; combo damage 40/40/60 and knockback magnitudes 1/1/1.5; rail exit 15m/s and landing 14.997066m/s. Coyote launch, buffered touchdown jump, air acceleration/turn caps, stale rear-sensor/front-target melee query, evade immunity expiration/lock cancellation, overlay timing, shove persistence, four audio voices and stream reuse all pass.

**Brief inconsistency:** 16m/s² reaches 7m/s in 7/16 = 0.4375s, sampled here at 0.45s. It cannot satisfy the brief's simultaneous requirement of ≥0.50s. Asked the user which should govern; no reply arrived during implementation. Retained the explicit acceleration table and documented a ≥0.40s test threshold. The literal ≥0.50s requirement remains intentionally unsatisfied; reducing acceleration to 14m/s² would satisfy it if desired.

## Build and tests

Confirmed no running Godot process before builds. Used exactly:

`py -3 -m SCons platform=windows target=template_debug -j8`

Final build exits 0, with **zero compiler warnings**. Log: ops/runs/wp2-build.log. Initial full bindings rebuild exposed a missing Animation include in the new code; corrected it and rebuilt successfully. No SConstruct or godot-cpp source changes.

| Headless script | Final outcome |
|---|---|
| test_systems.gd | PASS assertions, exit 0 |
| test_tapes.gd | PASS assertions, exit 0 |
| test_candy_pickup.gd | PASS assertions, exit 0 |
| test_flamethrower_particles.gd | PASS assertions, exit 0 |
| verify_camera_and_hud.gd | PASS assertions, exit 0 |
| test_5_systems.gd | PASS all five sections, exit 0 |
| test_gameplay_fixes.gd | PASS assertions, exit 0 |
| test_feel_movement.gd | PASS, zero failed checks, exit 0 |
| test_feel_combat.gd | PASS, zero failed checks, exit 0 |
| test_feel_traversal.gd | PASS, zero failed checks, exit 0 |

Only the CONTEXT allowlist and new feel tests ran. No quarantined or scene-generating tests ran. Test save contents were backed up and restored in a finally block. New functional tests return quit(1) on failed checks and release the scene while the physics tree still exists.

Existing tests still emit off-tree/transform, dummy-renderer null-mesh and leak/resource diagnostics. Traversal also emits one dummy-renderer null-mesh diagnostic at cleanup. These are distinguished from assertion success; the runs are not claimed to be free of every engine diagnostic. Final movement and combat logs have no such diagnostics. No process remained running after verification.

## Screenshots and visual review

Ran the exact prescribed off-screen harness sequence, inspected all four PNGs, and preserved the user's save. Files: ops/runs/shots/wp2.0.png through wp2.3.png. The stock mall's enemies obscure the spawn in shot 0, and a pillar obscures the player in shot 3; these shots do not establish an unobstructed guard/glide pose. Shots 1 and 2 show the running/punch poses.

Added a reversible isolated mall screenshot fixture, tests/test_feel_visual.gd, removing enemies/UI/encounter callbacks and using a clear floor position. Ran windowed/off-screen at 1280×720, exit 0. Inspected all four files: ops/runs/shots/wp2-isolated.0.png through wp2-isolated.3.png. Shot 0 visibly shows floor contact and a guard stance; remaining shots show locomotion, punch and skate stance. Screenshots and logs remain uncommitted under ops/runs.

## Deliberate limits and out-of-scope findings

- Preserved the brief's 16m/s² skate constant instead of its incompatible ≥0.50s timing threshold, as explained above.
- Frozen poses use zero custom blend because paused animation cannot finish blending. Playing animation transitions retain the requested default. Added a stance-only grounding adjustment after measuring the actual guard pose.
- The stock screenshot's shot-0 guard visibility requirement is blocked by enemies clustered at spawn; the isolated shot verifies the implemented pose. Enemy placement and scene geometry were not changed.
- Camera occlusion remains visible behind tall pillars. Occlusion handling was outside this packet's specified camera changes.
- HUD restores an existing save on raw mall scene load, so initial screenshots inherited level/tape/spawn changes. The fresh-save screenshot rerun temporarily withheld and then restored the file. HUD/save scripts were not changed.
- Roaches attack during the brief's initial one-second screenshot wait, preventing a quiet stock idle capture. Enemy AI/spawn placement was untouched.
- Enemy knockback unit inconsistencies remain; melee preserves existing unit-direction behavior and scales hit three by 1.5. Enemy scripts were not edited.
- Audio verification checks encoded samples, voice assignment and stream reuse; it does not claim a listening test.
- The rebuilt tracked debug DLL is left in the worktree for immediate play/testing but is **not committed**, since bin is outside the allowed source file list. No *.import files were changed or committed. No ops/runs artifacts were committed.

Nine scope commits were created with the requested trailers, followed by a verification/final-fixes commit and this report. No merge performed.
