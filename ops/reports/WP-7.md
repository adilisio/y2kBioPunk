# WP-7 ? End-to-end slice test and balance

Completed on `wp7-e2e` in the assigned worktree. No branches created; no `src/`, scene, DLL, or HUD layout changes. The tree was clean at entry. The explicit user request and packet commit instructions take precedence over the older ?Never commit? note in `ops/CONTEXT.md`.

## Deliverables and behavior

`tests/test_slice_e2e.gd` loads the real mall after clearing the save, kills the live cicada/roach roster through `take_damage`, checks cumulative earned XP across level thresholds, spends strength, activates the actual checkpoint by collision, dies and polls a real scene reload, and verifies restored XP, strength, unspent points, level and health. It enters the actual curved atrium rail through its sensor with skates, aligned velocity and jump input, then checks dismount and the landing slam signal. The real boss trigger, damage thresholds, transition timers, summon state, defeat signal, minion freeing, HUD victory panel, timed menu return, Continue visibility and persisted completion flag all run in one session. Only the Queen's summon state is selected directly to avoid a random AI choice; its timer and spawning run normally. The test backs up the production save bytes and restores them during teardown because SaveManager's save path is constant. A real-time watchdog fails and restores the save after 55 seconds.

`ops/tools/balance_table.gd` instantiates enemies and the player off-tree, reads exported enemy stats and effective player getters, extracts non-exported constants from current source, runs the real off-tree spawn routine to count the roster, and feeds its XP into real `gain_xp`. Missing source patterns produce an error and nonzero exit. The following tables are pasted from that script's stdout, not manually populated.

## GDScript fix

Commit `7eda57e`, `fix(e2e): remove duplicate HUD signal connections`: loading the mall and reloading on death emitted four duplicate-connection errors because `_ready()` connected the same tape, skate, level-up and secondary-weapon callbacks in two blocks. Removed the four later redundant connections (eight lines), retaining the original connections before save loading. This avoids connection errors while preserving event handling and all HUD layout. The complete suite and three consecutive E2E runs verify the fix.

## Balance table and assumptions

These are code-derived ideal timing bounds, not measured combat benchmarks. Baseline is a fresh level-one Bubblegum player, before stat allocation. The speed column uses cicada chase, roach scuttle and Queen phase-three speed; Queen damage/telegraph also use phase three. Turret telegraph includes tracking plus charge. Repeated one-hit bat means repeating the first swing; combo includes the third-hit multiplier. All attacks connect. Excludes approach, physics rounding, hit-stop, target displacement and misses. Flame and disk count their first hit at zero; disk additionally pays projectile travel. Three-roach TTD is an optimistic lower bound with staggered hits and hurt i-frames; pack slots and reposition travel can only lengthen it. Turret excludes initial idle and flight. Queen TTD assumes consecutive AoEs with intervening idle, excluding tracking, minion choices and phase transitions.

| Enemy | HP | Damage | Speed (m/s) | Telegraph (s) | XP |
|---|---:|---:|---:|---:|---:|
| Cicada | 50 | 6 | 3.00 | 0.50 | 10 |
| Roach | 30 | 10 | 5.50 | 0.35 | 15 |
| Turret | 120 | 20 | 0.00 | 1.60 | 40 |
| Queen | 600 | 28 | 5.50 | 0.90 | 250 |

Player: level 1, Bubblegum, HP 100, bat 40, flame 13/tick (108.33 DPS), disk 64.

| Enemy | Repeated 1-hit bat TTK (s) | 3-hit combo TTK (s) | Flame TTK (s) | Disk TTK (s + travel) |
|---|---:|---:|---:|---:|
| Cicada | 0.39 | 0.35 | 0.36 | 0.00 |
| Roach | 0.10 | 0.10 | 0.24 | 0.00 |
| Turret | 0.68 | 0.68 | 1.08 | 0.45 |
| Queen | 4.16 | 3.58 | 5.52 | 4.05 |

| Threat | Ideal player TTD lower bound (s) |
|---|---:|
| 1 roach | 14.30 |
| 3 roaches (staggered; hurt i-frames included) | 5.75 |
| Turret (excluding initial idle and mortar flight) | 16.80 + flight |
| Queen phase 3 (repeated AoE, excluding tracking/summons) | 5.40 |

Queen TTK above excludes two 1.80s invulnerable transitions (add at least 3.60s).
Roach recovery flame TTK: 0.12s (1.50x vulnerability).

```text
Roster: 3 cicadas + 4 roaches + 2 turrets = 170 XP; real gain_xp yields level 3, XP 45/112.
BALANCE: PASS (0 source errors)
```

## Assessment and recommendations (no tuning applied)

The full WP-4 roster supplies 170 XP and reaches level 3 with 45/112 XP toward the next level; level 3 requires 125 cumulative XP. Killing only cicadas and roaches supplies 90 XP and leaves level 2 at 40/75. One turret then raises the total to 130, enough for level 3. The current trigger allows entering the boss early, so level 3 is attainable before the boss, not guaranteed.

Trivial ideal pairings: roach versus bat (0.10s), normal flame (0.24s), and recovery flame (0.12s). Cicadas and roaches each take one disk: their zero firing-time TTK still pays travel, so the actual sub-0.3s classification depends on range. No listed player TTD lower bound is below 3s, including three staggered roaches. These estimates do not certify mixed-enemy encounters or play difficulty. The boss's sustained-damage TTK is also very short relative to the intended session length.

Proposed parameter changes for a later tuning packet:

- Roach `max_health`: 30 ? 70, making a normal bat or disk hit nonlethal and normal flame require more ticks.
- Cicada `max_health`: 50 ? 75, removing normal one-disk kills while retaining two normal bat hits.
- Queen `max_health`: 600 ? 1800, extending the fight beyond a few combos without changing telegraphs.
- Roach kill XP: 15 ? 25, allowing the cicada/roach roster alone to cross the level-three threshold when turrets are bypassed.

## Three consecutive E2E runs

Executed sequentially after the HUD fix and final test assertions/watchdog; every process exited 0. Verbatim assertion/result stdout follows.

Run 1:

```text
PASS: a: load real mall
PASS: a: level 1, full HP, player group
PASS: a: nearby cicadas=2, roaches=0
PASS: b: exact earned XP=90 (3 cicadas, 4 roaches), level=2
PASS: b: strength point increases bat damage
PASS: c: checkpoint collision saves current level
PASS: d: real lethal damage enters dead state
PASS: d: death reloads scene within 4s
PASS: d: respawn restores saved level, full HP, checkpoint position
PASS: d: respawn preserves XP, spent strength and unspent points
PASS: e: real atrium sensor enters grind within 0.5s
PASS: e: jump dismount emits grind_ended and one landing slam
PASS: f: real trigger spawns exactly one Queen
PASS: f: phase 2 signal/state in order
PASS: f: phase 2 invulnerability expires
PASS: f: phase 3 signal/state in order
PASS: f: phase 3 invulnerability expires
PASS: f: real summon state creates minions
PASS: f: boss_defeated fires once
PASS: f: summoned minions freed on victory
PASS: f: HUD victory card node exists
PASS: f: victory returns to main_menu within 7s
PASS: g: Continue button visible
PASS: g: saved slice_complete is true
PASS: runtime 15.35s < 60s
RESULT: PASS (0 fails)
```

Run 2:

```text
PASS: a: load real mall
PASS: a: level 1, full HP, player group
PASS: a: nearby cicadas=2, roaches=0
PASS: b: exact earned XP=90 (3 cicadas, 4 roaches), level=2
PASS: b: strength point increases bat damage
PASS: c: checkpoint collision saves current level
PASS: d: real lethal damage enters dead state
PASS: d: death reloads scene within 4s
PASS: d: respawn restores saved level, full HP, checkpoint position
PASS: d: respawn preserves XP, spent strength and unspent points
PASS: e: real atrium sensor enters grind within 0.5s
PASS: e: jump dismount emits grind_ended and one landing slam
PASS: f: real trigger spawns exactly one Queen
PASS: f: phase 2 signal/state in order
PASS: f: phase 2 invulnerability expires
PASS: f: phase 3 signal/state in order
PASS: f: phase 3 invulnerability expires
PASS: f: real summon state creates minions
PASS: f: boss_defeated fires once
PASS: f: summoned minions freed on victory
PASS: f: HUD victory card node exists
PASS: f: victory returns to main_menu within 7s
PASS: g: Continue button visible
PASS: g: saved slice_complete is true
PASS: runtime 15.36s < 60s
RESULT: PASS (0 fails)
```

Run 3:

```text
PASS: a: load real mall
PASS: a: level 1, full HP, player group
PASS: a: nearby cicadas=2, roaches=0
PASS: b: exact earned XP=90 (3 cicadas, 4 roaches), level=2
PASS: b: strength point increases bat damage
PASS: c: checkpoint collision saves current level
PASS: d: real lethal damage enters dead state
PASS: d: death reloads scene within 4s
PASS: d: respawn restores saved level, full HP, checkpoint position
PASS: d: respawn preserves XP, spent strength and unspent points
PASS: e: real atrium sensor enters grind within 0.5s
PASS: e: jump dismount emits grind_ended and one landing slam
PASS: f: real trigger spawns exactly one Queen
PASS: f: phase 2 signal/state in order
PASS: f: phase 2 invulnerability expires
PASS: f: phase 3 signal/state in order
PASS: f: phase 3 invulnerability expires
PASS: f: real summon state creates minions
PASS: f: boss_defeated fires once
PASS: f: summoned minions freed on victory
PASS: f: HUD victory card node exists
PASS: f: victory returns to main_menu within 7s
PASS: g: Continue button visible
PASS: g: saved slice_complete is true
PASS: runtime 15.35s < 60s
RESULT: PASS (0 fails)
```

## Suite verification

Command: `powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1`. Final runner exit code: **0**. Log: `ops/runs/tests/20261007_171531.log`. Verbatim result lines from the completed final run:

```text
--- END: tests/test_3d_player.gd (ExitCode: 0, Time: 4.77s) ---
--- END: tests/test_5_systems.gd (ExitCode: 0, Time: 1.44s) ---
--- END: tests/test_candy_pickup.gd (ExitCode: 0, Time: 0.78s) ---
--- END: tests/test_critical_path.gd (ExitCode: 0, Time: 1.51s) ---
--- END: tests/test_cursor_aiming.gd (ExitCode: 0, Time: 0.97s) ---
--- END: tests/test_encounters.gd (ExitCode: 0, Time: 22.05s) ---
--- END: tests/test_feel_combat.gd (ExitCode: 0, Time: 3.22s) ---
--- END: tests/test_feel_movement.gd (ExitCode: 0, Time: 8.01s) ---
--- END: tests/test_feel_traversal.gd (ExitCode: 0, Time: 2.11s) ---
--- END: tests/test_flamethrower_particles.gd (ExitCode: 0, Time: 0.44s) ---
--- END: tests/test_gameplay_fixes.gd (ExitCode: 0, Time: 0.95s) ---
--- END: tests/test_grinding.gd (ExitCode: 0, Time: 1.33s) ---
--- END: tests/test_presentation.gd (ExitCode: 0, Time: 0.76s) ---
--- END: tests/test_slice_e2e.gd (ExitCode: 0, Time: 15.64s) ---
--- END: tests/test_systems.gd (ExitCode: 0, Time: 0.43s) ---
--- END: tests/test_tapes.gd (ExitCode: 0, Time: 0.32s) ---
--- END: tests/verify_camera_and_hud.gd (ExitCode: 0, Time: 0.68s) ---
SUMMARY: 17 Total | 17 PASSED | 0 FAILED
```

## STOP items and verification limits

No blocked packet item and no required C++ or scene fix. Headless behavior was verified; no windowed visual/audio playtest was performed. The E2E runs still emit the existing dummy-renderer null-mesh diagnostic; they contain no script errors, assertion failures or duplicate HUD connection errors. The complete suite also retains existing teardown/resource diagnostics and the legacy `test_5_systems.gd` save/checkpoint SKIP. This packet's E2E test covers the real save/checkpoint path without that skip. A green runner means all exit-code/script/assertion gates passed, not warning-free execution.

Representative retained stderr (verbatim):

```text
ERROR: Parameter "m" is null.
   at: mesh_get_surface_count (servers/rendering/dummy/storage/mesh_storage.h:120)
```

All changes are committed with the requested trailers. Generated `*.import` files and `ops/runs` are excluded from commits.
