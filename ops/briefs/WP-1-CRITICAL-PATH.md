# WP-1 — Critical path: New Game reaches the mall, progression works, death/retry loop is sane, slice has an ending
Agent: agy / gemini-3.1-pro-high. Slot: CODE. Works in worktree `C:\y2k-biopunk-rpg\.worktrees\wp1` on branch `wp1-critical-path` (already created; cd there; commit there; never touch the main checkout).

Read `AGENTS.md`, `ops/CONTEXT.md`, `ops/reports/AUDIT-PX.md`, then this brief. Skim `ops/reports/AUDIT-ARCH.md` if present for bugs in your files.

## Why this matters
Today "New Game" loads an empty test floor. If a player reaches the mall, a stale death-save is applied, they spawn next to a roach pack and die in ~10 s forever; enemies never award XP; dying to the boss means re-clearing the whole mall; beating the boss ends nothing. No amount of feel polish matters until a player can start, progress, die, retry and finish.

## You own (allowed files)
- `src/menu_controller.cpp`, `src/menu_controller.hpp`, `scenes/main_menu.tscn`
- `scripts/save_manager.gd`, `scripts/checkpoint.gd`, `scripts/boss_encounter_trigger.gd`
- `scripts/hud.gd` — ONLY `_ready` (save-apply logic), `_on_player_died`, and new victory/boss-gate/level-up messaging functions. Do not restyle or resize the HUD.
- `scripts/neon_cicada.gd`, `scripts/sludge_roach.gd`, `scripts/corrupted_kiosk_turret.gd`, `scripts/dial_up_queen.gd` — ONLY their `_die()` functions (XP award + death pop) and `take_damage` knockback normalization (item 5).
- `scripts/disk_projectile.gd`, `scripts/turret_mortar.gd` — knockback normalization only.
- `scripts/mall_greybox_builder.gd` — `_spawn_enemies` positions only.
- `scenes/FloodedMall_Greybox.tscn` — ONLY the `BioCheckpoint` node transform and the `BossEncounterTrigger` node/collision transform. Another agent edits one other line of this file; do not reformat it.
- `scenes/main.tscn`: delete it. Root-level duplicates (`*.gd`, `*.tscn` at repo root that duplicate `scripts/` and `scenes/`): delete them and remove every code fallback that references `res://<name>.gd|tscn` at the root.
- `tests/verify_camera_and_hud.gd` (update for the removed scene), new `tests/test_critical_path.gd`.

## Do not touch
`src/player_controller.*`, `scripts/isometric_camera.gd`, `scripts/health_candy_pickup.gd`, the player model transform lines in scenes, enemy AI/visual code outside `_die`/`take_damage`, `SConstruct`, `project.godot` input map.

## Scope — implement exactly these
1. **Menu → mall.** New Game: delete `user://y2k_save_data.json` (via `SaveManager.clear_save()`), then `change_scene_to_file("res://scenes/FloodedMall_Greybox.tscn")`. Add a `ContinueButton` (visible only when a save exists) that sets `SaveManager.pending_load = true` then loads the mall. Remove the `res://main.tscn` fallbacks. Keep the C++ change minimal; rebuild with SCons (see CONTEXT.md; the worktree has the engine and godot-cpp lib copied in).
2. **Save semantics.** `hud.gd::_ready` applies the save ONLY when `SaveManager.pending_load` is true (then clears the flag) or when `SaveManager.respawn_pending` is true (set on death, see 3). `apply_save_data_to_player` must set `current_health = max_health` after stats are restored. Saving on death (`_on_player_died` → `PlayerDeath_Stabilizer`) is removed. Checkpoint saves remain the only saves. Fix the XP/level inconsistency: a save must store `xp_to_level` consistent with level (recompute as `50 * 1.5^(level-1)` on load if the stored value is lower than it should be).
3. **Death/retry.** On `player_died`: HUD shows the flatline text (existing), sets `SaveManager.respawn_pending = true`; the existing 2.5 s scene reload then restores the checkpoint save (position included). If no checkpoint save exists, respawn at the scene spawn with default stats (a fresh run). Enemies respawn with the scene — acceptable for this slice.
4. **Boss gate and ending.** Replace the "all enemies dead" requirement: the boss spawns when the player enters the trigger, period; when the player enters while ≥1 enemy remains, page the HUD a one-line message instead of printing to console only (e.g. `QUARANTINE BREACH // DIAL-UP QUEEN AWAKENS`). On `boss_defeated`: HUD shows a victory card (`SIGNAL RESTORED // MALL QUARANTINE LIFTED` + kills/level/time), the mall saves a `slice_complete` flag, and after 6 s returns to `scenes/main_menu.tscn`. Move `BioCheckpoint` out of the basin to the spawn plaza (near (3, 0, 12)); move the roach spawn points to the north half (z ≤ -6) so the spawn plaza is quiet for the first 20 s; keep cicadas as the first contact.
5. **XP + death beats.** `_die()` in cicada/roach/turret/queen: find the player (`get_tree().get_first_node_in_group("player")` or by name "Player"), call `gain_xp(10 / 15 / 40 / 250)`, then a 0.15 s scale-to-zero tween before `queue_free()` (queen keeps her existing death tween). Also: the player node must be in group `player` — if the C++ class does not add itself, add it in `mall_greybox_builder.gd::_ready` via `get_node_or_null("Player").add_to_group("player")` (do not edit the C++ player).
   **Knockback contract:** receivers (`take_damage(amount, dir)` in the four enemy scripts) use `dir.normalized() * impulse * clampf(dir.length(), 1.0, 1.6)` so the slam/disk/flame no longer produce 60–120 m/s launches. Keep each enemy's own `impulse` constant.
6. **Cruft.** WARNING (from AUDIT-ARCH): the mall builder loads the ROOT `res://neon_cicada.tscn` (`mall_greybox_builder.gd:228`), and `menu_controller.cpp:49` prefers root `main.tscn` (a 2D prototype) when it exists. First `git mv neon_cicada.tscn scenes/neon_cicada.tscn` and repoint the builder (and `@export var cicada_scene` default) to `res://scenes/neon_cicada.tscn`; make the boss trigger default to the canonical `res://scenes/dial_up_queen.tscn`. THEN delete root duplicates (`*.gd`, `*.tscn` at repo root) and `scenes/main.tscn`; remove dead fallbacks that referenced them in `boss_encounter_trigger.gd`, `mall_greybox_builder.gd`, `menu_controller.cpp`, `intro_controller.cpp` (intro → `scenes/main_menu.tscn` only). Update `AGENTS.md` directory layout accordingly (only that section). `src/mutated_bug_enemy.*` and `src/stranded_soldier_npc.*` stay (unreferenced is fine for now; do not delete C++).
7. **Small correctness items (from AUDIT-ARCH), all in your files:**
   - `disk_projectile.gd`: collision mask must exclude the rail GrindArea layer (bit 4) and world sensors; disks currently die on rail volumes.
   - `hud.gd::toggle_character_sheet`: call `player.set_movement_locked(true)` when opening and `false` when closing (the C++ `attack()` already refuses while locked), so allocation clicks no longer swing the bat.
   - On `boss_defeated`, free remaining nodes in group `enemies` that were summoned by the queen (she spawns roaches; tag them with meta `summoned_by_boss = true` in `dial_up_queen.gd` — the summon function is yours to edit for that one line) before showing the victory card.
   - `boss_encounter_trigger.gd`: set `triggered = true` only after a successful spawn.

## Verification you must do and report
- Build in the worktree: `py -3 -m SCons platform=windows target=template_debug -j8`.
- `tests/test_critical_path.gd` (SceneTree script, headless): (a) `SaveManager.clear_save()` removes the file; (b) saving at level 3 and loading yields `xp_to_level == 112` and `current_health == max_health`; (c) instancing the mall scene with no save leaves the player at level 1 with full HP; (d) killing a roach via `take_damage(999, Vector3.ZERO)` awards 15 XP to the player node; (e) `BossEncounterTrigger._spawn_boss()` spawns a node in group `boss` even when enemies remain; (f) a slam-sized knockback vector of length 12 yields receiver velocity ≤ 1.6 × impulse. Must `quit(1)` on any failure.
- Run the allowed existing tests (CONTEXT.md list) — all pass.
- Headless smoke: `./Godot_v4.3-stable_win64.exe --headless --path . -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn "steps=wait:12,quit"` must show NO `CRITICAL BIO-FAILURE` in the log (player not dead within 12 s standing still at spawn).
- Do NOT open a windowed game or the editor.

## Commits
Conventional commits on `wp1-critical-path`, one per scope item, trailers:
```
Agent: gemini/gemini-3.1-pro-high
Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
```

## Report
`ops/reports/WP-1.md`: per-item summary, test output, the smoke log tail, anything skipped and why, bugs noticed outside your files (list, don't fix).

## Stop and report if
the build fails outside `src/menu_controller.*`, or a step requires editing a file you do not own.
