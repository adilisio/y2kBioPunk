# WP-2 — Feel core: grounded character, animation sync, momentum, melee that lands, hurt feedback, working SFX
Agent: codex (gpt-6.1-sol, effort high). Slot: CODE. Works in the MAIN checkout `C:\y2k-biopunk-rpg` on branch `wp2-feel-core` (create it from main; commit there; do not merge).

Read `AGENTS.md`, `ops/CONTEXT.md`, `ops/reports/AUDIT-FEEL.md` (your spec; sections 3 and 4 items 1, 2, 6), then this brief.

## Why this matters
The first thing every player sees is a character floating 1 m above its shadow in an A-pose, sliding its feet, stopping and turning instantly, punching with damage that lands 0.35 s before the fist moves, taking hits with zero feedback, and every SFX playing as distorted buzz. This packet is the single largest change in perceived quality available.

## You own (allowed files)
- `src/player_controller.cpp`, `src/player_controller.hpp`
- `scripts/isometric_camera.gd`
- The model-transform line only in `scenes/FloodedMall_Greybox.tscn` (~line 2346), `scenes/player.tscn` (~line 97), `scenes/main.tscn` (~line 116): set the glb node origin from `(0, 1, 0)` to `(0, 0, 0)`.
- `scripts/health_candy_pickup.gd` line ~193 only (SFX byte format).
- New tests under `tests/` named `test_feel_*.gd`.

## Do not touch
Everything else. In particular: `scripts/hud.gd`, enemy scripts, `scripts/mall_greybox_builder.gd`, `scripts/save_manager.gd`, `scripts/boss_encounter_trigger.gd`, `src/menu_controller.cpp`, `SConstruct`, `project.godot`. Another agent is editing those concurrently in a worktree.

## Scope — implement exactly these, in this order
1. **Ground + animation (AUDIT-FEEL Fix 1).** Model origin y 1 → 0 in the three scenes. In `_ready`: default blend time 0.12; loop `Walking`, `Running`, `Skate_Grind` (if present). Speed-matched locomotion: use `Running` for walking with `speed_scale = clamp(h_speed / 2.62, 0.8, 2.2)`; skating ≥ 6 m/s loops `Skate_Grind` as glide pose when present, else `Running` at 2.2; idle = `Punch_Combo_1` seeked to 2.10 and paused (guard stance); airborne = `Running` seeked 0.18 and paused. Remove the dead `speed_scale(2.0)` writes. Make `orient_towards_point` use the same slerp as movement with rotation_speed 25 (no instant `look_at` pops) and play locomotion backwards when backpedaling while aiming (dot(facing, vel) < -0.3).
2. **Momentum + jump (Fix 3).** Replace the ground/air velocity assignment with `move_toward` using the table in the report (walk 70/90 m/s², skates 16 accel / 4 coast / 28 brake with turn-rate limit 360→200 °/s, air 20 m/s²). Landing and grind exit must NOT overwrite horizontal velocity. Jump: `jump_velocity` 7.2, rise gravity 22, fall gravity 36, jump-cut ×0.5 on release, coyote 0.10 s, jump buffer 0.12 s. Camera: lerp Y at 3/s separately from XZ at 9/s; add `add_trauma()` shake (trauma² × 0.35 offset, decay 1.8/s) and look-ahead `target += hv * 0.18` clamped to 2.5 m.
3. **Melee that lands (Fix 2).** `attack()` plays `Punch_Combo_1` seeked to 0.45 at speed 2.4; damage fires via a `pending_hit_timer` ≈ 0.10 s (not on press); `attack_timer` ≈ 0.29 s; a click buffered in the last 0.15 s chains hit 2 (seek 0.80, impact +0.06 s) then hit 3 (seek 1.15, impact +0.10 s, 1.5× damage/knockback). Movement speed ×0.25 while attacking plus a 0.08 s / 4 m/s lunge along facing. Hit-stop: on any confirmed hit set `Engine.time_scale = 0.05` and restore after 0.06 s real time (0.10 s for hit 3 and slam). Camera trauma 0.25 per melee hit, 0.6 slam, 0.45 when hurt. Make the attack sensor position update BEFORE it is queried.
4. **Hurt feedback.** `take_damage(float amount, Vector3 knockback = Vector3())` — keep the one-arg call working for existing GDScript callers (bind with a default). 0.6 s post-hit invulnerability (`hurt_invuln_timer`), white→red overlay flash on the skin meshes (0.08 s + 0.10 s), `play_sfx("hurt")`, 7 m/s × 0.12 s knockback honored by a `knockback_timer` that skips the velocity assignment (this also makes external shoves like the boss phase push work). Emit a new signal `player_hurt(amount)`.
5. **SFX.** Fix the signed-8-bit byte format in every `create_sfx_stream` branch and in `health_candy_pickup.gd`. Pool of 4 `AudioStreamPlayer` round-robin; cache generated streams in `_ready`. Add `hurt`, `jump`, `land` sounds (short, procedural, same style).
6. **Grind polish (Section 4 items 1–2).** Entry requires `abs(dot(hv_dir, rail_tangent)) >= 0.5` and (airborne or jump pressed ≤ 0.15 s ago); snap lerps over 0.06 s instead of teleporting; dismount input ignored for the first 0.15 s and uses `is_action_just_pressed` only; the slam fires on the first `is_on_floor()` frame after dismount, disc at floor height, hit-stop 0.10 s, trauma 0.6.
7. **Evade tuning (item 6).** duration 0.22, speed 24 easing to move speed after 70%, i-frames for the first 0.18 s, cooldown 0.35, keep horizontal velocity on exit.

You MAY refactor inside `player_controller.cpp` (e.g., split `_physics_process` into `_process_grinding/_process_evading/_process_locomotion/_process_animation` helpers). Do not change the public GDScript-facing API except by adding (new signals/params with defaults). Keep every existing bound method name.

## Verification you must do and report
- Build: `py -3 -m SCons platform=windows target=template_debug -j8` (ensure no Godot instance is running first; `Get-Process Godot_v4.3-stable_win64`). Zero new warnings in `src/`.
- Headless tests: run only the allowed list in CONTEXT.md; all must still pass. Add `tests/test_feel_movement.gd` (a `SceneTree` script that instantiates the mall scene with enemies removed, drives `Input.action_press`, and asserts: speed reaches ≥ 7 m/s within 0.15 s of input on foot and takes ≥ 0.5 s on skates; after releasing input on skates speed is still > 6 m/s after 0.5 s; jump apex between 1.0 and 1.4 m and airtime < 0.75 s; toe/floor gap < 0.1 m; `take_damage(10)` twice within 2 frames reduces HP only once). The test must call `quit(1)` on any failure so exit codes are meaningful.
- Screenshots: `./Godot_v4.3-stable_win64.exe --path . --windowed --resolution 1280x720 --position 2000,2000 -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn out=ops/runs/shots/wp2 "steps=wait:1,shot,hold:move_forward:1,shot,press:attack,wait:0.12,shot,press:toggle_skates,hold:move_left:1.5,shot"`. Look at them yourself (the window is placed off-screen, that is intended). The character must stand on the floor in a guard stance in shot 0.

## Commits
Conventional commits on branch `wp2-feel-core`, one per numbered scope item where practical, each ending with the trailers:
```
Agent: codex/gpt-6.1-sol
Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
```
Do not commit `ops/runs/**`.

## Report
Write `ops/reports/WP-2.md`: what changed per item, measured before/after numbers from your test, test results, screenshot paths, anything you deliberately skipped and why, and any bug you found outside your allowed files (do NOT fix those; list them).

## Stop and report if
- The build fails for reasons outside `src/` or a godot-cpp API you need does not exist in 4.3.
- A requested behavior contradicts something you discover in the engine; propose the alternative in the report rather than silently diverging.
