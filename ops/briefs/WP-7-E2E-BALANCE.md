# WP-7 — End-to-end slice test + balance table
Agent: codex (gpt-6.1-sol, effort medium). Slot: CODE. Worktree `C:\y2k-biopunk-rpg\.worktrees\wp7` on branch `wp7-e2e` (branched from main after WP-4 merged). Stay there.

Read `AGENTS.md`, `ops/CONTEXT.md`, the "Vertical Slice 1 — definition of done" section of `ops/DIRECTOR_LEDGER.md`, `tests/test_critical_path.gd` (style to follow), `ops/reports/WP-4.md` (enemy numbers), then this brief.

## Why this matters
Every packet has unit-level tests. Nothing yet proves the whole loop in one run: start → fight → level up → spend a point → checkpoint → die → respawn with progress → grind → slam → boss → victory → menu. The Director will accept the slice only with this test green.

## You own
- New: `tests/test_slice_e2e.gd`, `ops/tools/balance_table.gd`, `ops/reports/WP-7.md`.
- You may fix bugs you find ONLY in GDScript under `scripts/` with minimal diffs, each in its own commit titled `fix(e2e): ...`, each with a one-paragraph justification in the report. Do not touch `src/`, scenes, or HUD layout. If a fix needs C++ or a scene change, STOP on that item and describe it in the report instead.

## Scope
1. **`tests/test_slice_e2e.gd`** (headless SceneTree script, `quit(1)` on failure, each step prints PASS/FAIL, total runtime < 60 s). Drive the game through its real code paths — real `take_damage`, real `gain_xp`, real SaveManager, real trigger, real boss — but teleport the player (`global_position`) between beats instead of walking. Steps:
   a. Clear save; load the mall; assert level 1, full HP, group `player`, ≥ 2 cicadas within 10 m of spawn, 0 roaches within 10 m.
   b. Kill every cicada and roach with `take_damage(999, Vector3.ZERO)`; assert XP matches 10×cicadas + 15×roaches and that level ≥ 2; assert `spend_stat_point("strength")` returns true and `get_effective_bat_damage()` increased.
   c. Teleport onto the BioCheckpoint; wait 2 frames; assert `SaveManager.has_save_data()` and the saved level equals the current level.
   d. `take_damage(9999)`; assert `is_dead()`; wait for the scene reload (poll `current_scene` identity change, ≤ 4 s); assert the new player has the saved level and full HP and is within 3 m of the checkpoint.
   e. Teleport beside the atrium rail with skates on, set horizontal velocity along the rail tangent at 8 m/s, press jump via `Input.action_press("jump")`, step physics; assert `is_grinding()` within 0.5 s; then press jump again; assert `grind_ended` fired and that a slam happened (`grind_slam_executed` signal or the AoE killed a roach you placed 2 m from the dismount point).
   f. Enter the boss trigger (`_on_body_entered(player)`); assert one node in group `boss`; drive the Queen through her phases with `take_damage` in chunks (assert `boss_phase_transition`/phase changes fire in order); kill her; assert `boss_defeated` fired, summoned minions were freed, the HUD victory card node exists, and (poll ≤ 7 s) the scene changed to `main_menu.tscn`.
   g. From the menu scene: assert the Continue button is visible (a save exists) and that `SaveManager.cached_save_data.slice_complete == true`.
2. **`ops/tools/balance_table.gd`** (headless): instantiate each enemy and the player off-tree, read their current numbers, and print a Markdown table: enemy → HP, contact/pounce damage, speed, telegraph time, XP; and TTK by bat (1-hit, 3-hit combo), flame DPS, disk; and player TTD vs 1 roach, 3 roaches, turret, queen phase 3. Write the table into `ops/reports/WP-7.md` (do not hand-type numbers; paste the script's output).
3. **Balance recommendations** (report only, no tuning): given the table and XP values, does the player reach level 3 before the boss with the spawn set WP-4 placed? Are there any TTK < 0.3 s (trivial) or TTD < 3 s (unfair) pairings? Propose at most 5 one-line parameter changes.

## Verification
- `ops/tools/run_tests.ps1` all PASS including `test_slice_e2e.gd` (paste output).
- Run `test_slice_e2e.gd` three times in a row; it must pass all three (no flakiness).

## Commits
On `wp7-e2e`, trailers `Agent: codex/gpt-6.1-sol` + `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`.

## Report
`ops/reports/WP-7.md`: the pasted suite output, the balance table, recommendations, and any STOP items.
