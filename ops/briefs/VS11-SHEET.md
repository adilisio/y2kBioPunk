# VS11-SHEET — Character sheet pauses the game, plus showable-build cleanup
Agent: Claude Sonnet 5.5 (Claude Code Agent tool). Worktree `C:\y2k-biopunk-rpg\.worktrees\vs11sheet` on branch `vs11-sheet` (from main). Stay there. Run Godot headless only (never the editor, never a windowed game): `./Godot_v4.3-stable_win64.exe --headless --path . -s tests/<file>.gd` from the worktree root.

Read `AGENTS.md`, `ops/CONTEXT.md`, `scripts/hud.gd` (character sheet section, `_setup_window_mode`, `_unhandled_input`, `show_victory_card`, `_on_player_died`), `scripts/boss_encounter_trigger.gd`, `scenes/main_menu.tscn`, `src/menu_controller.cpp` (read only), `tests/test_slice_e2e.gd` step c, `tests/_test_util.gd`, `tests/test_menu_flow.gd` (style), then this brief.

## Director decision (do not re-litigate)
The character sheet is a deliberate planning interface. Opening it PAUSES the game (`get_tree().paused = true`). The current state (input locked, enemies keep attacking) is the ambiguous middle we are removing.

## You own
- Edit: `scripts/hud.gd`; `scenes/FloodedMall_Greybox.tscn` (HUD node `process_mode` and the CharacterSheet panel's look only; do not touch the Player subtree or LevelGeometry); `scenes/main_menu.tscn`; `project.godot` (one key, see 4); `scripts/boss_encounter_trigger.gd` (one line, see 5); `tests/test_slice_e2e.gd` (step c only, see 6); `scripts/health_candy_pickup.gd` (timer only, see 3).
- New: `tests/test_character_sheet.gd`, `ops/reports/VS11-SHEET.md`.
- Do NOT touch `src/` (C++), enemy scripts, the builder, the tutorial director.

## Scope
1. **Pause semantics.** `toggle_character_sheet()` and the close button: when opening set `get_tree().paused = true`, when closing set it false. The HUD `CanvasLayer` gets `process_mode = PROCESS_MODE_ALWAYS` so its buttons, `_unhandled_input`, equalizer animation and `_process` keep running; the pager message timer must NOT advance while paused (guard `_process_page_message` with `get_tree().paused`). The player's `WalkmanAudio` (child of Player) should keep playing: set its `process_mode` to ALWAYS from `hud.gd` at ready (find it via the player node) so the diegetic music continues; every other sound and all gameplay freezes. Keep calling `set_movement_locked` as today as a belt-and-braces input block.
2. **Visual state.** While open: a full-screen dim `ColorRect` (black, alpha ~0.55) behind the sheet, a clear header line in the sheet such as `PAUSED // BIO-STATS`, and a footer `[C] or [ESC] resume`. Add `ui_cancel` (Esc) as a second close key. Keep the existing CRT-pager look (green on dark, same fonts/sizes the sheet already uses).
3. **Guards.** The sheet must not open when the player is dead (`is_dead()`), while the victory card is showing, or when the HUD has no player. If the scene changes while paused (death reload, victory -> menu), the tree must be unpaused first: unpause in `_on_player_died`, in `show_victory_card`, and in `_exit_tree` of the HUD as a safety net. Audit every `get_tree().create_timer(...)` and `Tween` in `scripts/` that could fire across a pause and list what you checked (default `create_timer` ignores pause; `health_candy_pickup.gd` line ~164 is one: switch it to `create_timer(0.4, false)`).
4. **Project name.** `project.godot` `config/name` is `"Y2"` (that is the window title). Set it to `"Y2K: Bio-Punk"`. In `scenes/main_menu.tscn` the `TitleLabel` text is also `"Y2"`: make it `"Y2K: BIO-PUNK"`. Remove the `OptionsButton` and `CreditsButton` nodes entirely (their handlers only print "in development"); the C++ controller tolerates missing buttons. Keep NEW GAME / CONTINUE / EXIT GAME. `tests/test_menu_flow.gd` must still pass.
5. **Boss trigger error.** The log prints `ERROR: Function blocked during in/out signal. Use set_deferred("monitoring", true/false).` when the Queen spawns. Find the `monitoring = false` (or similar) inside the `body_entered` handler in `scripts/boss_encounter_trigger.gd` and make it `set_deferred`. Confirm the error is gone in `test_slice_e2e.gd` output.
6. **E2E flake.** `tests/test_slice_e2e.gd` step c (`checkpoint collision saves current level`) waits `frames(2)` after teleporting onto the checkpoint; under CPU load physics may not have ticked. Replace it with a poll of up to 1.0 s (frame loop) until `sm.has_save_data()`; keep the assertion exact.

## Test (`tests/test_character_sheet.gd`, headless, `_test_util.gd`, < 15 s)
- Load the real mall; record a nearby enemy's `global_position`; call `hud.toggle_character_sheet()`; assert `get_tree().paused`, the sheet is visible, the dim overlay is visible, `player.get_movement_locked()`.
- Press `move_forward` via `Input.action_press` for 0.5 s of frames; assert the player and the recorded enemy did not move (<= 0.01 m).
- Toggle again; assert unpaused, overlay hidden, movement unlocked; then hold `move_forward` 0.5 s and assert the player DID move.
- Close via `ui_cancel`.
- Kill the player (`take_damage(9999)`) with the sheet open; assert the tree is not paused before the reload happens.
- Call `show_victory_card()` while the sheet is open; assert unpaused and the sheet hidden.

## Verification (paste real output)
- `powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1` — all suites PASS (20 with yours).
- Run `tests/test_slice_e2e.gd` three times in a row; paste the three RESULT lines; the "Function blocked" error must be absent.

## Commits
On `vs11-sheet`, small commits, trailers `Agent: claude/sonnet-5.5` + `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. Do not commit `*.import` changes or `ops/runs/`. COMMIT BEFORE FINISHING.

## Report
`ops/reports/VS11-SHEET.md`: what changed, the timer/tween audit list, pasted test output, STOP items.
