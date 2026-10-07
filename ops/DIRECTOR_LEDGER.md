# Director's Ledger — Y2K: Bio-Punk ARPG

Live project-state document. Owner: the acting Game/Technical Director (Fable 5.1 session, started 2026-10-07).
Another strong agent should be able to take over directorship from this file plus `ops/CONTEXT.md`.

## Current player experience (verified 2026-10-07, before any changes)

Evidence: `ops/runs/shots/greybox.*.png` (in-engine captures), `ops/runs/shots/greybox.log`, headless test run, three audits in `ops/reports/`.

What actually happens when you press New Game:
- The menu loads `scenes/main.tscn`: a flat 100x100 grey box with the player, HUD and one candy. No enemies, no rails, no boss. The real level `scenes/FloodedMall_Greybox.tscn` is unreachable from the menu.
- If you load the mall directly: the HUD applies the last save on start (`hud.gd:274`), including a save written on death (`hud.gd:491`), so a "new game" resumes a dead run. The player spawns at (0,1,9), inside roach aggro range of three Sludge Roaches in the basin. With zero input the player is dead in ~10 s, the scene reloads, the save re-applies, and the loop repeats.
- Enemies never award XP (`gain_xp` is called from no GDScript). Leveling and the stat sheet are dead in play.
- The Neon Cicada has no attack. It is a green cylinder that wanders.
- Enemies are untextured CSG primitives: green cylinders (cicada), olive blobs (roach), brown box (turret). The player model is ~40 px tall at the 16 m camera arm. The level is uniformly grey under one directional light.
- The pager HUD reads "TAPE: Metal" while the Walkman box shows the Bubblegum buff text after a save restore; XP shows 125/50.
- Movement is instant-velocity (no acceleration); skating is a 6→12 m/s step. Grinding requires skates; the K toggle is not taught anywhere.
- Death reloads the whole scene, respawning every enemy; the boss trigger requires every enemy dead, so each boss retry means re-clearing the mall.

What is genuinely good and must be protected:
- The traversal fantasy: skates, rails that snap and carry you, the dismount slam AoE. It reads well even in greybox.
- The Walkman tape as a stat/music switch. Thematic, instant, legible in the HUD.
- Turret and boss telegraphs (CRT color ramp, expanding ring) are the right idea.
- The flamethrower feels powerful.
- The C++ player core is stable; headless tests of stats/tapes pass.

## Vertical Slice 1 — definition of done
(to be filled after the three audits are synthesized)

## Active work
| Agent | Packet | Status |
|---|---|---|
| Codex (gpt-6.1-sol, high) | AUDIT-ARCH | running |
| Agy (gemini-3.1-pro-high) | AUDIT-PX | done → `ops/reports/AUDIT-PX.md` |
| Claude (opus) | AUDIT-FEEL | running |
| Fable | own play-through, synthesis, plan | in progress |

## Ready for integration
(none yet)

## Verified
(none yet)

## Rejected / reworked
(none yet)

## Next highest-leverage work
(to be filled after synthesis)

## Anthony decisions
(none yet — nothing so far requires human taste)

## Baseline facts
- Build: `py -3 -m SCons platform=windows target=template_debug -j8` works; DLL dated Sep 18 is "up to date".
- Tests (headless): `test_systems`, `test_tapes`, `test_candy_pickup`, `test_flamethrower_particles`, `verify_camera_and_hud` pass. `test_3d_player` and `test_cursor_aiming` crash calling `_ready()` directly (not exposed). `test_5_systems`, `test_gameplay_fixes`, `test_grinding` print errors; exit codes are always 0 because none use `quit(1)` on failure.
- Quotas at start (15:35): Codex 100%/100%, Gemini 100%/100%, Claude 86% 5h / 50% weekly (Fable 44%).

## Machine-state changes made by the Director
- 2026-10-07 15:48: set `HKCU\Software\Microsoft\Windows\Windows Error Reporting\DontShowUI = 1` (was unset) so Godot crash-at-exit dialogs from headless test runs stop popping on Anthony's screen. Revert with `Remove-ItemProperty` on that key if unwanted.
