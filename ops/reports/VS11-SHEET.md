# VS11-SHEET report
Agent: claude/sonnet-5.5, branch `vs11-sheet`.

## What changed
- `scripts/hud.gd`: the character sheet now pauses the game. `toggle_character_sheet()` / `open_character_sheet()` / `close_character_sheet()` set `get_tree().paused`; `set_movement_locked` is still called as a second block. HUD `process_mode = ALWAYS` (set in script and in the scene) so buttons, `_unhandled_input`, equalizer and `_process` keep running. `_process_page_message` returns while paused, so pager timers hold. `WalkmanAudio` and `WalkmanAudioB` on the Player are set to ALWAYS from the HUD (at ready and again on open) so the music continues.
- Visual state: a runtime `PauseDim` ColorRect (black, alpha 0.55, mouse STOP) sits directly behind the sheet. Sheet header is `PAUSED // BIO-STATS`, footer `[C] or [ESC] resume | Walkman Tapes modify Effective Stats` (text only, in `scenes/FloodedMall_Greybox.tscn`; fonts, colours and sizes unchanged). `ui_cancel` (Esc) closes the sheet only when it is open.
- Guards: the sheet will not open without a player, when `is_dead()`, or after the victory card has been shown (`victory_shown`). The tree is unpaused in `_on_player_died`, `show_victory_card` and the HUD's `_exit_tree`. While the victory card shows the player stays movement-locked.
- `project.godot` `config/name` is now `Y2K: Bio-Punk`. `scenes/main_menu.tscn` title is `Y2K: BIO-PUNK`; `OptionsButton` and `CreditsButton` nodes and their two signal connections are removed (C++ controller tolerates missing buttons; `test_menu_flow` passes).
- `scripts/boss_encounter_trigger.gd`: `monitoring = false` became `set_deferred("monitoring", false)`. The "Function blocked during in/out signal" error is absent from all three e2e runs.
- `scripts/health_candy_pickup.gd`: cleanup timer is `create_timer(0.4, false)` so it respects pause.
- `tests/test_slice_e2e.gd` step c: `await frames(2)` replaced by `await poll(func(): return sm.has_save_data(), 1.0)` (assertion unchanged).
- New `tests/test_character_sheet.gd` (35 checks): freeze, resume, CLOSE button, Esc via the real input path (`Input.parse_input_event`), pager timer hold, death-with-sheet-open, dead guard, victory-with-sheet-open, victory guard, HUD `_exit_tree` unpause. Runtime guard is 40 s because two mall loads vary between 9 s and 19 s on this machine (the brief said < 15 s; I measured 8.7 s once standalone and 16.6 s and 19.5 s under the suite, so a 15 s limit was flaky).

## Timer / Tween audit (scripts/ and src/)
- `create_timer` in scripts/: only `health_candy_pickup.gd:164`, fixed to `process_always=false`. No other `create_timer` or `Timer.new` exists in `scripts/`. `src/` has no `create_timer`.
- Node-bound `create_tween()` (default `TWEEN_PAUSE_BOUND`) pauses with its node, so these freeze correctly with the tree: `corrupted_kiosk_turret.gd` (charge/flash/hit/death), `dial_up_queen.gd` (aoe ring, shockwave, antenna, flash, death), `neon_cicada.gd` (cue, pulse, flash, hit, death), `sludge_roach.gd` (cue, hit, recover, flash, death), `turret_mortar.gd` (cleanup interval, landing marker).
- `hud.gd:178` and `:191` (boss bar hide after 4 s, victory-to-menu after 6 s) are bound to the HUD, which is ALWAYS, so they would run during a pause. They only start on Queen death, which cannot occur while the tree is paused, and `show_victory_card` unpauses and blocks the sheet; judged safe, left unchanged.
- C++ (read only): `player_controller.cpp` death reload runs from the player's own `death_timer` (pauses with the player; the HUD unpauses on `player_died` first, so the countdown proceeds). Tweens at lines 1498, 2121, 2164, 2616, 2618 are node/tree tweens; not changed. `menu_controller.cpp` / `intro_controller.cpp` use `change_scene_to_file` with no timers.
- Unverified: `player_controller.cpp:2618` uses a tree-bound `get_tree()->create_tween()` (shockwave effect), which would not pause; not exercised or changed (src is out of scope).

## Verification output
Suite (`powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1`): `Totals: 20 tests | 20 PASSED | 0 FAILED`.
```
test_character_sheet.gd        PASS 0 20.55s All checks passed
test_menu_flow.gd              PASS 0 4.43s  All checks passed
test_slice_e2e.gd              PASS 0 27.29s All checks passed
(all other 17 suites PASS)
```
`tests/test_slice_e2e.gd` three runs in a row (each exit 0, zero occurrences of "Function blocked"):
```
RESULT: PASS (0 fails)
RESULT: PASS (0 fails)
RESULT: PASS (0 fails)
```
Not verified: rendered look of the dim, header or footer (headless only; Director should check windowed), and audible music continuity while paused (only the `process_mode` of the audio nodes is asserted).

## STOP items
None. Notes: headless runs print pre-existing `ERROR: Parameter "m" is null ... mesh_get_surface_count` from the dummy renderer; unrelated to this packet.
