# AUDIT-FEEL — Game-feel, animation, camera, combat-feedback & presentation audit (READ-ONLY)
Agent: claude (opus). Slot: REVIEW (no code edits).

Read `AGENTS.md`, `ops/CONTEXT.md`, then this brief.

## Goal
Judge how the game *feels* moment to moment from the implementation, and find the smallest changes that would make movement, combat and presentation feel like a real action game. No new features.

## Scope
- Movement feel: `src/player_controller.cpp` `_physics_process` (line ~334–880), `try_evade`/`start_evade` (~2267–2336), grind code (~2010–2260). Acceleration/deceleration, turn rate, skate momentum, jump arc (6 m/s up, 9.8 gravity), air control, evade feel, grind entry/exit, slam. Compare numbers to good references (e.g., Hades dash ~0.2s with ~5m travel; THPS grind snap tolerance). Call out anything that will feel floaty, sticky or instant.
- Animation/state sync: which animations does the code request (`Walking`, `Running`, `restpose`, attack names in `attack()`/`execute_bat_attack()` ~1127–1305, death in `die()` ~1885)? Which exist in the glb? Inspect `scenes/FloodedMall_Greybox.tscn` lines ~2754–2765 and `scenes/*.glb.import` / scene AnimationPlayer resources, and the sprite sheet `sprites/`. Identify mismatches: states with no animation (jump, evade, grind, hit-react, death), speed_scale vs. actual speed (12 m/s on a walk cycle at 1.0x?), blending (none?), root motion issues, the Visuals rotation slerp vs. `look_at` inconsistency.
- Camera: `scripts/isometric_camera.gd` + scene transform. Lerp speed 9, arm 16, FOV 50, pitch -45 yaw 45. Will the player be readable at 12 m/s? Any look-ahead? Screen shake on hit/slam? Does the camera handle the mezzanine height change?
- Combat feedback: hit-stop, knockback, flash, particles, sounds, camera shake, damage numbers, enemy hit reactions (`neon_cicada.gd`, `sludge_roach.gd`, `corrupted_kiosk_turret.gd`, `dial_up_queen.gd` take_damage). Player taking damage: any feedback at all beyond HUD? Invincibility window after hit? Telegraphs on enemy attacks?
- Presentation: greybox materials/lighting/WorldEnvironment in `FloodedMall_Greybox.tscn`, HUD layout and hierarchy (`scripts/hud.gd`, HUD nodes in the scene), fonts, readability at 1080p, color language (what does green/red/cyan mean?), the 'pager' conceit.
- Audio: tapes via `switch_tape`; `play_sfx` implementation (~1863) — are there any SFX assets at all? Procedural? Silent?
- You MAY run headless tests. Do NOT open the editor or a windowed game.

## Output
Write `ops/reports/AUDIT-FEEL.md`:
1. Feel scorecard (movement, skating, jump, evade, grind, melee, secondary, hit feedback, enemy readability, camera, HUD, audio) each 1–5 with one-sentence justification and file:line evidence.
2. Animation matrix: player state -> animation requested -> exists? -> problem.
3. Top 3 highest-leverage feel fixes with concrete parameter/code-level proposals (numbers, not adjectives) and expected player-visible result.
4. Ranked list of 10 further feel issues (one line each).
Under 350 lines. Do not modify any file other than the report.
