# AUDIT-FEEL — Game-feel, animation, camera, combat feedback & presentation

Read-only review, 2026-10-07. Scope: `FloodedMall_Greybox.tscn` (the real level) + `src/player_controller.cpp` + `scripts/*.gd`.
No repo files were modified except this report.

**How the numbers were obtained.** Static reading, plus two throwaway headless harnesses kept in the session scratchpad (not in the repo):
- `measure_anims.gd` sampled every clip at 60 Hz and measured foot-plant speed, hand reach and pose.
- `sim_feel.gd` loaded the mall scene, deleted the enemies, and drove `Input.action_press`.

Figures marked "measured" come from these harnesses. Everything else is derived from code constants.

| Measured (headless, 60 Hz physics) | Value |
|---|---|
| Gap between the player's floor contact and the model's toe bone (`LeftToe_End`) | **1.076 m** (the character floats) |
| Walk speed: frame 1 / 1 s / 1 frame after release | 8.10 / 8.10 / 0.00 m/s (instant on, instant off) |
| Skate speed: frame 1 / 1 s | 12.0 / 12.0 m/s; a 180-degree reversal is applied fully on the next frame |
| Jump apex / airtime | 1.89 m / **1.25 s** |
| Evade | 21 frames (0.35 s), 18 m/s, 6.1 m, then 0.80 s cooldown |
| Melee lock (`Punch_Combo_1` at 2x) | 70 frames (**1.17 s**); horizontal speed while attacking = 8.10 m/s (no slowdown) |
| Camera lag at walk / skate speed | 0.76 m / 1.13 m |
| `take_damage(10)` twice in 2 frames | HP 100 -> 80; Visuals unchanged, animation unchanged (no feedback, no i-frames) |
| Clip ground speed implied by foot plants | Walking 0.86 m/s, Running 2.62 m/s; Punch/Attack/Skate_Grind are in-place (< 0.1 m/s) |
| Clip loop modes (glb import and scene libraries) | **all `loop_mode = 0`** (none loop) |

Note: `ops/CONTEXT.md` says walking is 6 m/s. It is actually `6 + 0.15 x AGI` (`player_controller.cpp:292`), which gives 7.5–9.3 m/s depending on the tape. That makes skates (+33–60%) a smaller jump than the HUD's "+55%" (`hud.gd:526`).

---

## 1. Feel scorecard (1 = broken, 5 = shippable)

| Area | Score | Justification (evidence) |
|---|---|---|
| Movement (walk) | **2** | Velocity is set directly from input with no acceleration or deceleration (`player_controller.cpp:775-778`; measured 0 -> 8.1 -> 0 m/s in one frame each way). The walk cycle plays at 1.0x at 8.1 m/s against a 0.86 m/s clip, so the feet slide about 9x. The model floats 1.08 m above its shadow. |
| Skating | **1** | Same instant model as walking, just at 12 m/s (`:764`, `:776`). No glide, no coast, no carve, and a 180-degree flip is applied the next frame. A running cycle plays at 1.0x (2.62 m/s clip, so about 4.6x foot slide) (`:861-866`). |
| Jump | **2** | Symmetric gravity 9.8 with v0 = 6 (`player_controller.hpp:118-120`): 1.89 m apex and 1.25 s hang feels floaty for an ARPG. No jump, fall or land animation; it plays `restpose` or the walk cycle in the air (`:854-875`). No coyote time or jump buffer (`:678`). The camera follows Y 1:1, so the whole frame bobs. |
| Evade | **3** | Speed, i-frames and SFX all work (`:560-591`, `:2297-2334`). But 0.35 s is long next to the reference (Hades ~0.2 s / ~5 m), and the 0.8 s cooldown (`.hpp:84`) gives 1.15 s between dashes. Speed snaps from 18 to 8.1 m/s on the exit frame. It plays `Skate_Grind` at 2.5x because `Slide`/`Power_Slide` do not exist. |
| Grind | **2** | Auto-magnet with no input and no approach-angle test: any skating overlap within ~1.05 m (0.9 m box + 0.6 m sensor; `mall_greybox_builder.gd:390`, `player_controller.cpp:176`) teleports you onto the rail (`:2071-2087`). Dismount checks *held* Space or LMB (`:532`, `:536`), so jumping onto a rail with Space held slams off it on the same frame. Rails are 17.5 m and 7.6 m long, so grinds last 1.45 s and 0.63 s. |
| Melee | **1** | Damage is applied on the press frame (`:1164`), but the first fist peaks at clip 0.70 s, i.e. 0.35 s later at 2x (measured). The lock lasts 1.17 s (`:1147-1162`) while you keep sliding at full speed (`:776` ignores `is_attacking`). The clip shows three punches but only one damage event. Effective DPS (default tape) is 34, against 108 for the flamethrower and 142 for disks. No swing VFX: `BatSwingVisual` is a hidden 2D polygon (`FloodedMall_Greybox.tscn:2312`). |
| Secondary | **3** | Flame particles plus 0.12 s ticks, and disk spinning visuals, respond well (`:2551-2672`). However neither has SFX. The flame damage cone is 120 degrees (dot >= 0.5, `:2600`) while the visible spread is 22.5 degrees (`.tscn:42`). The disk travels 60 m (24 m/s x 2.5 s). |
| Hit feedback | **2** | Enemies get a red flash (0.25–0.3 s), a squash tween and knockback (`neon_cicada.gd:204-251`, `sludge_roach.gd:231-270`), which is a good base. There is no hit-stop, no camera shake, no impact particles and no damage numbers anywhere. On the player's side there is no feedback at all: `take_damage` (`:1742-1756`) only changes HP and has no SFX, flash, animation, knockback or post-hit i-frames. |
| Enemy readability | **2** | The turret is the model to copy: screen goes green -> yellow (0.8 s) -> red (0.8 s, squash) -> grey (`corrupted_kiosk_turret.gd:113-177`). The roach pounces with no wind-up (2.0 m trigger, 1.2 m contact at 8.5 m/s gives a **0.09 s** reaction window; `sludge_roach.gd:150-191`) and is dark brown on a dark floor at about 26 px tall. Cicadas chase but never attack. Enemy bodies and projectiles share the player's green. |
| Camera | **3** | Smooth and stable: exponential lerp at 9/s (`isometric_camera.gd:53-54`) gives 1.13 m lag at 12 m/s. No look-ahead: at FOV 50 / arm 16 you see 6.8 m down-screen vs 22.5 m up-screen, about 0.47 s of warning when skating toward the camera. No shake hook. No occlusion handling (`collision_mask = 0`, `:21`) for the 4.5 m south/east walls, 5 m pillars and 4 m storefronts. Mezzanine height changes are followed fine. |
| HUD | **2** | Effective text sizes at 1080p: pager 12.6 px (18 x 0.7; `.tscn:2810-2811`, `hud.gd:351`), buff text 9.1 px (13 x 0.7; `.tscn:2971`, `hud.gd:416`), action keys 10 px (`.tscn:2907`). The XP bar never moves because no live enemy calls `gain_xp` (grep: only the unused C++ `MutatedBugEnemy`). Adrenaline and cooldowns are not displayed. The boss gate ("kill N more") only goes to the console (`boss_encounter_trigger.gd:107`). |
| Audio | **1** | The 8 music tapes are good. Every procedural SFX is written as unsigned bytes into `AudioStreamWAV.FORMAT_8_BITS`, which Godot reads as *signed* PCM8 (`player_controller.cpp:1786` and siblings; `health_candy_pickup.gd:193`). Silence decodes as full-scale negative and the waveform wraps, so every SFX plays distorted. One shared voice (`:156-161`) means each SFX cuts the previous one. Only 6 events have sounds (see section 4, item 10). |

---

## 2. Animation matrix

Glb clips (both AnimationPlayers): `Attack` 2.875 s, `Punch_Combo_1` 2.333 s, `Running` 0.708 s, `Walking` 1.083 s, `restpose` 0.083 s. `Skate_Grind` (3.04 s, external `res://Skate_Grind.res`) exists **only** in the mall's `AnimationPlayer` library (`.tscn:1241-1249`). It is not in `AnimationPlayer2`, `player.tscn` or `main.tscn`.

Other notes:
- No clip loops.
- No `playback_default_blend_time` is set (0 s), so every transition is a hard pop.
- All clips are in-place (Hips position drift < 4 cm), so there are no root-motion problems.
- `sprites/player_idle/` holds a 23 MB Walking glb, not a sprite sheet, and nothing references it.

| Player state | Requested (file:line) | Exists? | Problem |
|---|---|---|---|
| NORMAL, idle | `restpose` (`:869-873`, `:81`) | yes (1 key) | Frozen A-pose bind pose (hands at shoulder −0.39 m, arms out 0.25 m). Non-looping, so it is re-`play()`ed whenever it stops. |
| NORMAL, walking | `Walking` @1.0 (`:861-866`) | yes | 0.86 m/s clip at 7.5–9.3 m/s, about **9x foot slide**. Non-looping; restarts via the `!is_playing()` check, which pops at the seam. |
| NORMAL, skating | `Running` @1.0 (`:861`) | yes | A run cycle for skating, at 2.62 m/s vs 12 m/s (**4.6x slide**). The `speed_scale(2.0)` at `:645`/`:1602` is overwritten to 1.0 the next frame (`:862`), so it is dead code. |
| AIRBORNE | locomotion fallthrough (`:854`) | no jump/fall/land clips | Plays `restpose` when jumping in place and the walk/run cycle in mid-air when moving. |
| ATTACKING | `Punch_Combo_1` @2.0 (`:1149-1156`) | yes | A three-punch combo, though the HUD says "BAT" and there is no bat mesh. Fist peaks at 0.70 / 0.95 / 1.40 s clip time (0.35 / 0.48 / 0.70 s real); damage fires once at 0.00 s. 1.17 s lock while still moving. `Attack` (peak 1.13 s) is never used. |
| GRINDING | `Skate_Grind` @1.0 (`:2135-2141`) | mall only | Non-looping 3.04 s clip (rails take 0.6–1.5 s, so this is latent). Feet are about 1.38 m above the rail (0.3 m snap + 1.08 m float). |
| EVADING | `Slide` -> `Power_Slide` -> `Skate_Grind` -> `Running`, all @2.5 (`:2319-2328`) | first two missing | Shows a grind stance at 2.5x. In `main.tscn` it falls back to a 2.5x run. |
| Hit-react | none requested | none | Getting hit causes zero animation change (measured). |
| DEAD | `Death` / `Die` / `Fall` (`:1909-1917`) | all missing | Calls `stop()`, then tweens `Visuals.rotation.x` to −1.45 (`:1933`). Despite the "Collapse Backward" comment, the model falls forward like a stiff plank, pivoting at feet that are 1 m in the air. |
| Movement locked | `restpose` (`:613`) | yes | A-pose during dialogue. |

**Facing inconsistencies:**
- Moving uses a basis slerp at `rotation_speed` 12 (`:816-836`), about 90% in 11 frames.
- Cursor aim (`:1085`), evade (`:2312`) and grind entry (`:2109`) all snap instantly with `look_at`.
- So every click snaps the body to the cursor, then movement slerps it back.
- While holding RMB and moving away from the cursor, the forward walk cycle plays while the body faces backward (moonwalking).

---

## 3. Top 3 highest-leverage feel fixes

### Fix 1 — Put the character on the ground and make locomotion animation match speed
**Problem:** the floating, sliding A-pose is the first thing every player sees, and it reads as "broken".
- **Floor contact:** set the model node's transform origin from `(0, 1, 0)` to `(0, 0, 0)` in `FloodedMall_Greybox.tscn:2346`, `scenes/player.tscn:97` and `scenes/main.tscn:116`. The mesh AABB starts at y = 0 (measured) and the capsule bottom is the body origin (`.tscn:2331-2333`), so the 1.076 m gap goes to about 0.
- **Blending and loops:** in `PlayerController::_ready()` after finding `anim_player` (`:78`):
  - Call `anim_player->set_default_blend_time(0.12)`.
  - For `Walking`, `Running` and `Skate_Grind`, call `anim_player->get_animation(n)->set_loop_mode(Animation::LOOP_LINEAR)`.
  - Durable alternative: set loop in the glb import `_subresources`.
- **Speed-matched cycles:** replace `:859-866` with:
  - Walking: `Running` with `speed_scale = clamp(h_speed / 2.62, 0.8, 2.2)`. At 8.1 m/s that is 2.2x, leaving about 1.4x residual slide (versus 9x today).
  - Optionally lower walk to `base_movement_speed = 4.0`, `AGI x 0.10` (5.0–6.2 m/s) to get slide to about 1.0x.
  - Skating above 6 m/s: loop `Skate_Grind` (a stance pose, measured in-place) at 1.0x as the glide pose.
  - Skating below 6 m/s or accelerating: use the `Running` "push".
- **Idle:** replace the A-pose with `Punch_Combo_1` paused at t = 2.10 s (settled guard stance, feet planted, measured foot speed 0.04 m/s): `play("Punch_Combo_1"); seek(2.10, true); pause();`.
- **Air:** when `!is_on_floor()`, play `Running`, `seek(0.18)` (passing pose), and `pause()`.
- **Facing:** make `orient_towards_point` (`:1079-1090`) feed the same slerp as `:821-835` with a faster `rotation_speed` of 25 (about 90% in 5 frames), so aiming stays crisp but never pops. When RMB is held, set `speed_scale = -speed_scale` if `dot(facing, velocity) < -0.3` (backpedal).
- **Expected player-visible result:** feet planted with shadow contact, no T/A-pose, stride matches ground speed, and smooth 120 ms transitions between idle, run, attack and grind.

### Fix 2 — Make melee hits land, and make getting hit register (timing, hit-stop, shake, hurt feedback, working SFX)
- **Sync damage to the fist:** in `attack()` (`:1147-1164`):
  - Instead of playing from 0 at 2.0x, use `play("Punch_Combo_1"); seek(0.45, true); set_speed_scale(2.4)`.
  - Store `pending_hit_timer = (0.70 - 0.45) / 2.4 ≈ 0.10f` and call `execute_bat_attack()` when it expires, instead of on the press frame.
  - `attack_timer = (1.15 - 0.45) / 2.4 ≈ 0.29f`.
  - Buffer a second click inside the last 0.15 s to chain: hit 2 = `seek(0.80)` with impact after 0.06 s; hit 3 = `seek(1.15)` with impact after 0.10 s, 1.5x damage and 1.5x knockback.
  - Result: lock goes 1.17 s -> 0.29 s per swing, and DPS goes from about 34 to about 140 (on par with disks), with damage landing on the visible punch.
- **Commitment instead of skating while punching:** at `:776-777` multiply `speed` by `0.25` while `is_attacking`, and add a 0.08 s lunge of 4 m/s along `facing_direction` at swing start.
- **Hit-stop:** when `damaged_nodes` is non-empty (`:1296`), set `Engine::get_singleton()->set_time_scale(0.05)` and restore it via `get_tree()->create_timer(0.06, true, false, true)` (ignores time scale). Use 0.10 s for the slam and the third combo hit.
- **Camera shake:** add `var trauma := 0.0` and `func add_trauma(a): trauma = min(1.0, trauma + a)` to `isometric_camera.gd`. In `_physics_process` set `camera.h_offset`/`v_offset = trauma² * 0.35 * randf_range(-1, 1)` and decay with `trauma = max(0, trauma - 1.8 * delta)`. Call it with 0.25 on a melee hit, 0.6 on a slam and 0.45 when the player is hurt.
- **Player hurt feedback** (`take_damage`, `:1742`):
  - Bind as `take_damage(amount, knockback = Vector3())` to match the AGENTS.md interface.
  - Add 0.6 s post-hit i-frames (`hurt_invuln_timer`) so three roaches cannot stack bites in one frame.
  - Flash: put a white unshaded `material_overlay` on `Mesh_0`/`Mesh_1` for 0.08 s, then red for 0.10 s.
  - Call `play_sfx("hurt")`: new 0.15 s square-wave sweep from 300 to 120 Hz.
  - Knockback: 7 m/s for 0.12 s, honored by a `knockback_timer` that skips the `:776` assignment. That same timer also makes the Queen's phase shove (`dial_up_queen.gd:302`), which is currently overwritten next frame, actually work.
- **Fix the SFX byte format:**
  - In every branch of `create_sfx_stream` (`:1786`, `:1798`, `:1810`, `:1822`, `:1846`, `:1855`), write `data[i] = (uint8_t)(int8_t)Math::clamp((int)(val * 127.0f), -128, 127);`.
  - In `health_candy_pickup.gd:193`, write `data[i] = int(clampf(val, -1, 1) * 127.0) & 0xFF`.
  - Give `play_sfx` a pool of 4 `AudioStreamPlayer`s used round-robin, and cache the 6 generated streams in `_ready` rather than regenerating them each call.
- **Expected player-visible result:** the punch connects on the frame the fist extends; hits freeze for a beat and shake the screen; taking damage is unmistakable and survivable; SFX sound like thuds and whooshes instead of buzz.

### Fix 3 — Momentum: acceleration, skate glide, landing carry-over, and a snappier jump
Replace the ground branch `:775-778` and the air branch `:765-774` with `move_toward` on the horizontal velocity `hv`:

| Mode | Accel (input) | Decel (no input) | Brake (input opposes vel, dot < −0.3) | Turn limit |
|---|---|---|---|---|
| Walk | 70 m/s² (0 -> 8 in 0.11 s) | 90 m/s² (stop in 0.09 s) | 90 | none (direction snaps; only speed ramps) |
| Skates | 16 m/s² (0 -> 12 in 0.75 s) | 4 m/s² coast (12 -> 0 in 3.0 s) | 28 m/s² | rotate `hv` toward input at 360°/s below 6 m/s, easing to 200°/s at 12 m/s |
| Air | 20 m/s² toward input | 0 (keep momentum) | 20 | 180°/s |

- **Landing** must not overwrite `hv`. Grind exits at 15 m/s (`:547`) then carry into a skate glide; today you dead-stop on touchdown when no key is held.
- **Jump** (`.hpp:118-120`, `:595`, `:679`):
  - `jump_velocity` 6.0 -> **7.2**.
  - Rise gravity **22**, fall gravity **36** (use the fall value when `velocity.y < 0`).
  - Jump-cut: on `jump` release while `vy > 0`, `vy *= 0.5`.
  - Coyote time 0.10 s; jump buffer 0.12 s.
  - Result: apex 7.2²/44 = **1.18 m** (still clears the 0.85 m planters and 0.75 m rails), rise 0.33 s, fall 0.26 s, so airtime about **0.58 s** (down from 1.25 s).
- **Camera vertical:** in `isometric_camera.gd:52-54` lerp Y separately at 3/s (X/Z stay at 9/s) so jumps read as the character moving, not the world bobbing. Mezzanine transitions (1.2 m) still settle in about 0.5 s.
- **Expected player-visible result:** walking stays responsive but loses the robotic on/off. Skates finally feel like skates (push to speed, glide, carve, brake). Rail exits keep their speed. Jumps are crisp hops.

---

## 4. Ten further feel issues (ranked)

1. **Grind entry is a sticky magnet.** In `try_start_grind` (`:2052`) require `abs(dot(hv.normalized(), world_tangent)) >= 0.5`, and require either airborne or jump pressed within 0.15 s. Cut lateral tolerance to 0.6 m (box 0.9 -> 0.5, `mall_greybox_builder.gd:390`). Lerp the snap over 0.06 s instead of teleporting (`:2083`). Ignore dismount input for the first 0.15 s and use only `is_action_just_pressed` (`:532`, `:536`).
2. **The grind slam fires at take-off, not on landing.** `execute_grind_slam` runs right after `dismount_grind` (`:549-552`) at the rail position (`:2358`, `:2386`), so the shockwave disc spawns about 1.05 m in the air. Set a `pending_slam` flag, fire it on the first `is_on_floor()` frame, place the disc at floor height, and add a hit-stop of 0.10 s and trauma of 0.6.
3. **Roach pounce cannot be reacted to (0.09 s).** Trigger at 3.5 m. Add a 0.35 s wind-up: stop, squash to (1.3, 0.5, 1.3), and turn the emission red. Then pounce at 11 m/s for 0.4 s (`sludge_roach.gd:150-174`). The 0.35 s window then matches the evade.
4. **The knockback contract is broken.** Senders pass scaled vectors (slam `x12` `:2478`, disk `x8.5` `disk_projectile.gd:90`, flame `x2` `:2602`) and receivers multiply again (`neon_cicada.gd:247-248` x7.5, `sludge_roach.gd:268-269` x10). The bat yields 7.5 m/s, disks 64–85 m/s, the slam 90–120 m/s (tunnelling risk), and the flame re-shoves every 0.12 s while resetting AI to idle (stun-lock). Fix: receivers use `dir.normalized() * impulse * clampf(dir.length(), 1.0, 1.6)`, and the flame passes `Vector3.ZERO`-strength 0.3.
5. **Enemy deaths have no beat and no reward.** Every enemy just calls `queue_free()` (`neon_cicada.gd:258`, `sludge_roach.gd:300`, `corrupted_kiosk_turret.gd:324`) with no burst, sound or XP; no GDScript enemy calls `gain_xp`, so the pager's XP bar is frozen at 0/50. Add a 0.15 s scale-pop to 0, a 12-particle one-shot, a `"pop"` SFX, and `player.gain_xp(10/15/40/250)` for cicada/roach/turret/queen.
6. **Evade tuning.** `evade_duration` 0.35 -> **0.22**, `evade_speed` 18 -> **24** for the first 70%, then ease to the current move speed (≈4.8 m travel). I-frames 0–0.18 s only. `evade_cooldown_max` 0.8 -> **0.35**. On exit keep `hv` (no snap to 8.1). Reference: Hades ~0.2 s / ~5 m.
7. **Camera occlusion and look-ahead.**
   - The camera sits at +X/+Z, so `Wall_South`/`Wall_East` (4.5 m, builder `:87-90`) hide the player completely within about 2 m of them and partly within about 3.2 m. Pillars (5 m) and the SW storefront (4 m) do the same.
   - Build the south and east walls at 1.0 m (the standard isometric cutaway) and fade pillars when they overlap a camera-to-player ray.
   - Add look-ahead `target += hv * 0.18` (clamped to 2.5 m), which raises down-screen warning at 12 m/s from 0.47 s to about 0.7 s. Alternatively use `PROJECTION_ORTHOGONAL` with `size = 16`, which gives ±11.3 m symmetric ground coverage.
8. **Queen AoE telegraph lies about its size.** The ring grows from 0.5 m to the full radius over the charge (`dial_up_queen.gd:195-199`), so the danger edge is only shown at detonation. Phase 3 is 12 m in 0.7 s (it needs 17 m/s to outrun), and detonation has no VFX, SFX or shake (`:207-223`). Show a full-radius outline ring at t = 0, fill the disc over the charge, add a 0.1 s white flash before detonation, an expanding shock ring on detonate, and trauma 0.5. Also floor-anchor the ring: it is a boss child at local y 0.05 while she hovers.
9. **Lighting and colour language.**
   - Environment is a flat background colour with no glow, SSAO or fog, and no MSAA (`.tscn:14-20`, `project.godot`), so every "neon" emission reads flat.
   - The rails (metallic 0.85, builder `:195`) have no reflection source and render dark.
   - Green means player HP, pager, flame and turret-idle, but also cicada body (`neon_cicada.tscn`), mortar (`turret_mortar.gd:34-36`) and roach glow.
   - Fix: `glow_enabled = true`, `glow_intensity = 0.8`, `glow_hdr_threshold = 0.9`, `ssao_enabled = true`; MSAA 3D 2x; rails metallic 0 with emission 0.6.
   - Make enemies and enemy projectiles magenta/orange (e.g. mortar `Color(1, 0.15, 0.6)`), keep green for the player, cyan for interactables, and red only for telegraphs.
10. **HUD legibility and silent systems.**
    - Drop the 0.7 scale (`hud.gd:351`, `:416`) and set a 20 px minimum font.
    - Show adrenaline (signal `adrenaline_changed` is emitted, never consumed) as a thin bar under HP, and add radial cooldowns on the evade/disk icons.
    - Page the boss gate ("QUARANTINE: 7 BIO-THREATS LEFT") and level-ups to the pager with a beep (this is what the pager conceit is for).
    - Stop rebuilding BBCode every frame (`hud.gd:441-442`); use signals only.
    - Missing SFX: player hurt, jump/land, skate roll loop, grind loop, flame loop, disk fire/impact, enemy hit/death, mortar fire/impact, turret charge, the boss "Modem Screech" (silent today), the tape "clack" (print only, `:1392`). Tape switches restart the track from 0 (`:1402`, `:1458`); remember per-tape positions or crossfade 0.25 s.

**Also noted (lower priority):**
- Bat sensor sphere (r 2.2 m centred 1.2 m ahead, `:206`, `:212`) reaches 1.0 m behind the player.
- The sensor is moved and queried on the same frame (`:1186-1189`), so overlaps reflect last frame's facing.
- Mortars use no ballistic solve (`corrupted_kiosk_turret.gd:212-213`): they pass over the player's head at about 5 m range and have no landing marker or impact splash (`turret_mortar.gd:55-63`).
- Godot 4.3 has no 3D physics interpolation; with player and camera both at 60 Hz physics, 120/144 Hz displays judder. Consider `physics_ticks_per_second = 120`.
- `attack_cooldown` (`.hpp:123`) is unused.
- The death tween pivots the 1 m-floating model; this is fixed by Fix 1.
