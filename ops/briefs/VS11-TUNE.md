# VS11-TUNE — Gameplay critic fixes (progress safety, victory safety, truthful pager, cheap fairness)
Agent: codex (gpt-6.1-sol, effort high). Worktree `C:\y2k-biopunk-rpg\.worktrees\vs11tune` on branch `vs11-tune` (from main). Stay there. Godot headless only (never the editor, never a windowed game).

Read `AGENTS.md`, `ops/CONTEXT.md`, `ops/reports/CRITIC-GAMEPLAY-VS11.md` (the independent critique; this brief is the Director's triage of it, follow the brief where they differ), `scripts/tutorial_director.gd`, `scripts/hud.gd` (victory card, level-up pager, legend at ~line 838), `scripts/boss_encounter_trigger.gd`, `scripts/checkpoint.gd` (`_on_body_entered` only; another packet is rewriting `_build_visuals`, do not touch it), `scripts/dial_up_queen.gd`, `scripts/sludge_roach.gd`, `scripts/neon_cicada.gd`, `scripts/corrupted_kiosk_turret.gd`, `scripts/save_manager.gd`, `src/player_controller.cpp` (slam damage ~line 2570, secondary cooldown ~line 2825), `tests/test_slice_e2e.gd`, `tests/test_onboarding.gd`, `tests/test_encounters.gd`, `tests/_test_util.gd`.

## Director decisions (do these; do not re-litigate the owner's five rulings: camera, walk/skate, mix, enemy respawn, roach cap)
Another packet (VS11-LOOK, Gemini) is concurrently editing: the builder, `checkpoint.gd::_build_visuals`, `dial_up_queen.gd` blast colours in `_process_aoe`/`_detonate_aoe`, the tint ALPHA/energy numbers in the three enemy scripts, `hud.gd::_setup_ui_layout`, the menu scene. Keep your diffs out of those functions/lines so the Director can merge both; where you must touch the same file, touch different functions.

### MUST
1. **No silent progress loss.** (a) In `boss_encounter_trigger.gd`, when the arena is entered and the Queen spawns, save progression through `SaveManager.save_player_data(player, "ArenaGate", <checkpoint respawn position>)` where the respawn position stays the Bio-Stabilizer's (find the node in group `checkpoints` and use its `global_position + respawn_offset`; fall back to the player position if none). The pager pages `PROGRESS SAVED // ARENA GATE`. (b) In `checkpoint.gd::_on_body_entered`, every successful save pages `PROGRESS SAVED // BIO-STABILIZER` (via the HUD group node's `page_message`) and heals the player to full (`heal` or `set_current_health(get_max_health())`), with a 1.0 s re-trigger cooldown so standing in it does not spam. Keep the existing colour change and print.
2. **Victory is safe.** On `boss_defeated`: the player becomes invincible (`set_is_invincible(true)`) and stays locked; EVERY node in group `enemies` (not only summons) is freed; all turrets stop; the victory card appears after a 1.2 s delay (so the Queen's death beat is visible), and during the victory flow no level-up pager lines are shown (suppress `_on_leveled_up` output while `victory_shown`, or grant the Queen XP silently). The return to menu timing stays as it is.
3. **Truthful, complete pager.** In `tutorial_director.gd`: (a) tape hint text becomes `TAPE: T cycles mixtapes — each tape shifts STR/AGI/VIT/VIBE` and fires after the second kill or 25 s, not on low HP; (b) turret hint text becomes `TURRET: its light ramps green→yellow→RED, then a mortar drops on the red marker` (true today; LOOK may add a body screen later); (c) grind hint names the key: `GRIND: skate along the rail and press SPACE to hop on; SPACE again to slam off`; (d) add a `secondary` hint `SECONDARY: RMB or F fires; Q swaps flamethrower / disks`, shown after the skates hint, dismissed by firing; (e) the final legend line in `hud.gd` includes SPACE; (f) skates hint says `+38% speed` instead of `2x`; (g) MOVE dismisses on movement alone (swing gets folded into the first combat), and EVADE takes priority over the pending hint when an enemy is within 6 m; (h) the HUD shows `STAT PTS: 1` from the start (the player spawns with one unspent point). Update `tests/test_onboarding.gd` to the new texts/order; keep its structure.

### SHOULD (cheap, do them)
4. Queen phase-3 screech: charge 0.9 → 1.05 s and the pre-blast flash 0.1 → 0.3 s (so an evade can be timed). Phase 1/2 unchanged.
5. Summon warning: during the 1.5 s summon state the Queen pulses a tint (reuse `EnemyModel.tint`) and plays a cue (`FX.sound` recipe), and minions spawn at least 5 m from the player.
6. Telegraph colour semantics: wind-ups (cicada flare, roach wind-up, turret charge light stays as is) use AMBER `Color(1.0, 0.75, 0.2)`; damage/hit flashes stay red; the roach's vulnerable window gets a visible pale-cyan tint `Color(0.5, 1.0, 1.0)` at low alpha. Change colours only; LOOK owns the alpha/energy numbers (leave them as you find them).
7. Disk launcher cooldown 0.45 → 0.8 s (`player_controller.cpp` ~2825). Grind-slam base damage so a level-1 slam kills a 70 HP cicada: raise `base_slam_damage` by 5 (find its definition). Rebuild the debug DLL (`py -3 -m SCons platform=windows target=template_debug -j8`) AND the release DLL (`target=template_release`) and commit both DLLs.
8. Turrets go idle while a boss exists (check `get_tree().get_first_node_in_group("boss")` in their state update, or have the boss trigger put them in an `idle` state) so the arena is not shelled from outside.
9. Roach bite passes a normalized knockback direction to `take_damage` (AGENTS.md contract).
10. Cicada contact damage 6 → 10.

### LATER (do NOT do): Queen HP changes, rail relocation, key-press victory card, deflect sound, action-bar font size, Continue hiding after victory.

## Tests
- Extend `tests/test_slice_e2e.gd` minimally: after the arena trigger fires, assert `SaveManager.has_save_data()` and that the saved checkpoint id is `ArenaGate`; after victory assert `get_nodes_in_group("enemies")` is empty and the player is invincible. Keep runtime < 60 s.
- Extend `tests/test_encounters.gd` or add `tests/test_tune.gd` (< 15 s): roach bite knockback is non-zero, cicada damage is 10, Queen phase-3 charge is 1.05, disk cooldown 0.8, summon minions >= 5 m from the player, turret stays idle while a boss node exists, checkpoint heals to full and pages.

## Verification (paste real output)
- `powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1` — all PASS. Do NOT run the suite concurrently with another worktree's suite (shared `user://` saves make e2e steps c/g flake); if e2e fails on c or g, rerun it alone and paste.
- `tests/test_slice_e2e.gd` three times in a row, paste the RESULT lines.

## Commits
On `vs11-tune`, small commits per numbered item where practical, trailers `Agent: codex/gpt-6.1-sol` + `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. No `*.import` churn, nothing under `ops/runs/`. COMMIT BEFORE FINISHING.

## Report
`ops/reports/VS11-TUNE.md`: per item what changed (file:function), pasted suite output, three e2e RESULT lines, STOP items.
