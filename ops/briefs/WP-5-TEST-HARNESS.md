# WP-5 — Test harness: make the suite honest, non-crashing, isolated, and runnable in one command
Agent: agy / gemini-3.8-flash-high. Slot: CODE. Works in worktree `C:\y2k-biopunk-rpg\.worktrees\wp5` on branch `wp5-test-harness`. Stay there. Never touch the main checkout.

Read `AGENTS.md`, `ops/CONTEXT.md`, then the "Tests and coverage" section of `ops/reports/AUDIT-ARCH.md`, then this brief.

## Why this matters
The suite currently lies: every run exits 0, three tests crash Godot at exit (popping Windows error dialogs on the owner's screen), one test writes to the production save file, and one "test" overwrites a shipped scene. The Director cannot accept any delegated work without a trustworthy gate.

## You own (allowed files)
- `tests/test_3d_player.gd`, `tests/test_cursor_aiming.gd`, `tests/test_grinding.gd`, `tests/test_5_systems.gd`, `tests/test_gameplay_fixes.gd`, `tests/build_greybox.gd` (move to `ops/tools/build_greybox.gd`; it is a generator, not a test)
- New: `tests/_test_util.gd` (shared helpers), `ops/tools/run_tests.ps1`
- `ops/CONTEXT.md`: update ONLY the "CRASHING TESTS" line when the tests no longer crash.

## Do not touch
Anything in `src/`, `scripts/`, `scenes/`, `project.godot`, `tests/test_systems.gd`, `tests/test_tapes.gd`, `tests/test_candy_pickup.gd`, `tests/test_flamethrower_particles.gd`, `tests/verify_camera_and_hud.gd` (other agents own those), and any `tests/test_feel_*.gd` / `tests/test_critical_path.gd` that may appear (other agents are writing them).

## Scope
1. **Honest exit codes.** Every test you own must end with `quit(0)` on success and `quit(1)` on any failed assertion or caught script error. Replace bare `assert()` (which is stripped in release and aborts in debug) with a helper `check(cond, msg)` from `tests/_test_util.gd` that records failures and prints `FAIL: msg`; the summary line at the end prints `RESULT: PASS` or `RESULT: FAIL (n)`.
2. **No crash at exit.** The three quarantined tests crash in teardown because they call unbound `_ready()`/`_physics_process()` on the C++ player and leak nodes. Fix: add the player to the tree (`root.add_child(player)`) and `await process_frame` / `await physics_frame` instead of calling lifecycle methods directly; free everything you created (`queue_free()` then `await process_frame`) before `quit()`. Verify with the actual engine (`./Godot_v4.3-stable_win64.exe --headless --path . -s tests/<file>.gd; echo $LASTEXITCODE`) that the process exits cleanly with no `ERROR: ... leaked`, `BUG:` or `Pages in use` lines and NO Windows crash dialog. If an assertion in these tests is simply stale against current behavior (e.g. `test_3d_player.gd:202` expects attack immobility; `:170` expects speed_scale 2; `test_cursor_aiming.gd:100` uses enum 1 for disk), delete or correct it and note it in your report; do not change gameplay code to satisfy a stale test.
3. **Isolated save storage.** `test_5_systems.gd` must not write the production save. Give `tests/_test_util.gd` a helper that redirects `SaveManager.SAVE_PATH` to `user://test_save_<pid>.json` if the property is writable, else skips the save section with `SKIP:`; delete the file afterwards.
4. **Generator out of the suite.** Move `tests/build_greybox.gd` to `ops/tools/build_greybox.gd`; add a one-line header comment saying it overwrites `scenes/FloodedMall_Greybox.tscn` and must never be run by a test runner.
5. **One-command runner.** `ops/tools/run_tests.ps1`: runs every `tests/test_*.gd` and `tests/verify_*.gd` headless with a 120 s timeout each, captures per-test exit code, grep-checks the log for `SCRIPT ERROR`/`RESULT: FAIL`, prints a table, writes `ops/runs/tests/<timestamp>.log`, and exits non-zero if any test failed, timed out or crashed (exit code ≠ 0). Must not pop dialogs (the WER DontShowUI flag is already set on this machine, but also pass `--quit-after` as a safety net only if it does not interfere with async tests).

## Verification you must do and report
- Run `ops/tools/run_tests.ps1` in the worktree; paste the table in the report. The tests you own must all PASS or SKIP; the tests you do not own may fail only for pre-existing reasons (say which).
- Confirm with `Get-Process WerFault -ErrorAction SilentlyContinue` that no crash reporter was spawned during the run.

## Commits
On `wp5-test-harness`, conventional commits per scope item, trailers:
```
Agent: gemini/gemini-3.8-flash-high
Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
```
Do not commit `*.import` changes or `ops/runs/**`.

## Report
`ops/reports/WP-5.md`: table of tests (before → after), what stale assertions you removed and why, runner usage line.
