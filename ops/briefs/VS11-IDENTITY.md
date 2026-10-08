# VS11-IDENTITY — Turret vs food cart, a Queen that moves, enemies that animate
Agent: codex (gpt-6.1-sol, effort high). Worktree `C:\y2k-biopunk-rpg\.worktrees\vs11identity` on branch `vs11-identity` (from main). Stay there. Godot headless only, except the shot harness windowed OFF-SCREEN (`--windowed --position 2000,2000`) for the shots this brief asks for. Never the editor.

Read `AGENTS.md`, `ops/CONTEXT.md`, the "Owner playtest" section of `ops/DIRECTOR_LEDGER.md`, `scripts/corrupted_kiosk_turret.gd`, `scripts/dial_up_queen.gd` (states, `_face_player`, `queen_body` bob at ~line 100, `_process_aoe`, `_detonate_aoe`), `scripts/sludge_roach.gd`, `scripts/neon_cicada.gd`, `scripts/enemy_model.gd`, `scripts/mall_greybox_builder.gd` (`_add_light`, kiosk prop placement at z = -15), `tests/test_encounters.gd`, `tests/test_presentation.gd`, `tests/_test_util.gd`, then this brief. Look at `ops/runs/shots/vs11/look.2.png` (turret beside the kiosk carts) and `look2_grid.png` (Queen arena) first.

## Owner feedback (Anthony, 2026-10-08, verbatim)
"its a little hard to distinguish the ones that shoot from afar from the food carts. the queen and bugs look good, but the queen doesnt move much. ... the animations in general still feel a little prototype-like."

## You own
- Edit: `scripts/corrupted_kiosk_turret.gd` (visuals + an idle scan only; no damage/timing/range changes), `scripts/dial_up_queen.gd` (motion and presentation only; no HP, phase thresholds, radii, charge durations, damage, summon counts), `scripts/sludge_roach.gd` and `scripts/neon_cicada.gd` (cosmetic motion in their process loops only), `tests/test_presentation.gd` or new `tests/test_identity.gd`.
- New: `ops/reports/VS11-IDENTITY.md`.
- Do NOT touch the player C++ (another packet owns it), the builder, HUD, occlusion, warm-up, export files.

## Scope
1. **Turret identity.** The turret must read as a hostile machine from 12 m, not as another kiosk. Add, in `_build_visuals` and driven by the existing `_set_screen_color` state ramp: (a) a rotating red beacon on top: small emissive cylinder + `OmniLight3D` (no shadow, range 4, energy 1.2) that yaws continuously in `_process`; (b) a yellow-black hazard ring at the base (two thin CSG tori or a flat cylinder with an emissive yellow material, radius ~1.1 m) so the floor around it says "danger"; (c) the body CRT screen 50 % larger with emission energy 2.0, and its colour following the ramp exactly as the light does; (d) an idle "scan": while no target, the head pivot sweeps yaw ±35° over 4 s (sine), so it is never static; when tracking, existing behaviour. Keep the GLB as the body. All of this must also work with the CSG fallback.
2. **A Queen that moves.** Keep every gameplay number. Add: (a) idle/tracking hover drift: a slow lemniscate (figure-8) around her anchor point, amplitude 2.5 m, period ~7 s, blended with her existing facing so she keeps looking at the player; (b) hover bob amplitude 0.12 → 0.35 with a 0.7 s period and a ±6° roll sway; (c) during the screech charge she rises ~0.6 m and on detonation drops back with a squash (scale y 0.85 for 0.15 s); (d) during the summon state she spins slowly (yaw +90° over the 1.5 s) while the tint pulses (already there); (e) on phase transition a short spin + rise. Her `global_position` used for damage/radius checks must remain the body root (don't move the collision/AoE centre with the cosmetic bob; move `queen_body`/visual only, or keep `aoe_center` as today).
3. **Enemy motion tweens.** Roach: while moving, a scuttle bob on the visual (y ±0.04 at ~9 Hz) and a yaw wobble ±4°; while winding up, keep the existing squash. Cicada: a wing-flutter (visual `scale.x` 1.0↔1.08 at ~10 Hz) whenever airborne/moving and a lazy ±0.1 m bob when hovering. Cheap sin() math in `_process` on the visual root only (no tweens per frame, no allocations).
4. **Cost guard:** all added nodes are cheap (two small lights total per turret); no shadows.

## Tests (headless, < 15 s)
- Turret: after `_ready`, has a child named like `Beacon` with an `OmniLight3D`, a hazard ring node, and the screen's emission colour equals the light colour after `_set_screen_color(Color.RED)`; after 2 s idle with no target, head yaw differs from its start.
- Queen: after 3 s idle with a player present, `global_position` (or `queen_body` offset) has moved ≥ 1.0 m from the spawn, and the AoE radius/charge duration values are unchanged (assert the constants: radii 7/9/11, charge 1.4/1.1/1.05).
- Roach/cicada: after 1 s of movement the visual's y offset varies (sample two frames, non-equal).
- `tests/test_encounters.gd` and `tests/test_slice_e2e.gd` unchanged and passing.

## Verification (paste real output)
- `powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1` — all PASS. Another Codex packet (VS11-STATS) is running in `.worktrees/vs11stats`; do NOT run the suite while its suite is running (check for a `Godot_v4.3-stable_win64.exe --headless` process from that path first); if e2e fails on step c/g, rerun it alone and paste.
- Off-screen harness shots: `steps="invuln:1,tp:1:0.5:-10,wait:2.5,shot,wait:1.5,shot,tp:0:1:-21,wait:3,shot,wait:1.5,shot,wait:1.5,shot,fps:6"` — turret identity (two frames) and the Queen in three positions; paste the `[FPS]` lines (render_gpu must stay within +0.5 ms of 7.8 ms; draw calls within +30). Look at the PNGs and describe each in one sentence.

## Commits
On `vs11-identity`, trailers `Agent: codex/gpt-6.1-sol` + `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. No `*.import` churn, nothing under `ops/runs/`. COMMIT BEFORE FINISHING.

## Report
`ops/reports/VS11-IDENTITY.md`: what each enemy now does, pasted suite output and `[FPS]` lines, shot descriptions, STOP items.
