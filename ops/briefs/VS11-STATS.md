# VS11-STATS — Stats that visibly matter, a bat in the hand, sane leveling pace
Agent: codex (gpt-6.1-sol, effort high). Worktree `C:\y2k-biopunk-rpg\.worktrees\vs11stats` on branch `vs11-stats` (from main). Stay there. Godot headless only, except the shot harness windowed OFF-SCREEN (`--windowed --position 2000,2000`) for the two shots this brief asks for. Never the editor.

Read `AGENTS.md`, `ops/CONTEXT.md`, the "Owner playtest" section of `ops/DIRECTOR_LEDGER.md`, `src/player_controller.cpp` (stats: `get_effective_*`, `get_effective_bat_damage`, `spend_stat_point`, `gain_xp`, melee damage application around line 1240, `fire_disk_launcher`, `get_max_health`, the `_ready` visuals/animation setup), `src/player_controller.hpp`, `scripts/hud.gd` (`_refresh_character_sheet`, `_refresh_hud`, `_on_leveled_up`), `scripts/dial_up_queen.gd` (`_execute_summon`, `_die`), `scripts/sludge_roach.gd` and `scripts/neon_cicada.gd` (`_die` → `gain_xp`), `scripts/tutorial_director.gd`, `tests/test_tune.gd`, `tests/test_systems.gd`, `tests/_test_util.gd`, then this brief.

## Owner feedback (Anthony, 2026-10-08, verbatim)
"one thing thats still weird is the stats. its not obvious that they help you and how. like bat swing dmg. there is no bat swing, the character just punches. what are vibes? no one knows. etc... leveling up doesnt feel like it makes you much stronger, and you can easily gain like 5+ levels just in this fight."

## You own
- Edit: `src/player_controller.cpp/.hpp`, `scripts/hud.gd` (character sheet + HUD stat strings + level-up page only), `scripts/dial_up_queen.gd` (`_execute_summon` meta / XP only), `scripts/sludge_roach.gd` + `scripts/neon_cicada.gd` (XP grant guard only), `scripts/tutorial_director.gd` (one hint text), `tests/test_tune.gd` or new `tests/test_stats.gd`, `bin/*.dll` (rebuild both).
- New: `ops/reports/VS11-STATS.md`.
- Do NOT touch the builder, enemy behaviour, occlusion, warm-up, menu, export files.

## Scope
1. **A bat in the hand.** The player model (`Player/Visuals/Meshy_AI_biopunk_delinquent_te_All_Animations`, a Meshy biped with a `Skeleton3D`) swings bare-handed. In `PlayerController::_ready` (or wherever visuals are resolved), find the `Skeleton3D`, find the right-hand bone (print the bone names once with `print_verbose` to pick it; typical Meshy names are `RightHand` / `mixamorig:RightHand` / `hand_R`), add a `BoneAttachment3D` for it and under it a simple bat: a tapered wooden `CylinderMesh` (top radius 0.045, bottom 0.028, height 0.78, warm wood albedo ~ (0.55, 0.38, 0.2), roughness 0.7) plus a short dark grip cylinder and a strip of cyan tape (emissive, tiny) so it fits the palette; orient it along the forearm/fist so it reads as held (iterate on the local rotation/offset using the harness shot). Keep it a child of the attachment so every animation carries it. No gameplay change. If the model has no usable hand bone, STOP on this item and say so; do not fake it with a world-space mesh.
2. **Stats that matter, and say how.** Change per-point effects (C++) to: STR +4.0 strike damage per point (today +2.5); AGI +3 % movement speed per point (keep its disk-damage contribution); VIT +12 max HP per point (check the current formula and replace it); VIBE = critical-hit chance, 2 % per effective VIBE point (10 VIBE = 20 %), a crit does ×1.75 damage, triggers a slightly longer hit-stop (+40 ms) and a distinct short "pop" SFX via the existing synthesized SFX path, and the hit flash on the enemy is yellow-white instead of red for that hit (pass the colour through `take_damage`'s existing path if a cheap hook exists; otherwise only hit-stop + sound). Document the formulas in the hpp comments.
3. **Naming.** Replace every player-facing "Bat DMG" / "bat damage" with "STRIKE DMG" (the HUD print at `_ready`, the sheet, the level-up/pager copy) — the owner is right that the animation is a punch; with the bat prop in place the word "strike" covers both.
4. **Character sheet copy** (`_refresh_character_sheet`): one line per stat that states the effect and the per-point gain, with live numbers, e.g.
   `STRENGTH 12  →  strike 48 dmg   (+4 per point)`
   `AGILITY 10  →  speed 8.7 m/s · disk 47 dmg   (+3 % speed per point)`
   `VITALITY 10  →  max HP 100   (+12 HP per point)`
   `VIBE 10  →  crit 20 % (×1.75 dmg)   (+2 % per point)`
   and a footer `Tapes shift these numbers while they play.` Keep the panel size reasonable (it must still fit at 1080p; take the shot).
5. **Leveling pace.** Summoned minions (meta `summoned_by_boss`) award 0 XP (guard in their `_die`); the Queen awards 120 XP (was 250). XP curve unchanged (50, 75, 112, …). Target: a player who clears the plaza (170 XP) reaches level 3 before the arena and gains at most one more level during the Queen fight. Verify by computation in the report and by a test.
6. **Level-up feedback.** The level-up pager line becomes `LEVEL %d // +1 STAT PT — press C to grow stronger` and the sheet highlights the unspent-points line (already yellow); nothing else.

## Tests (headless; extend `tests/test_tune.gd` or add `tests/test_stats.gd`, < 15 s)
- Spending one STR point raises `get_effective_bat_damage()` by exactly 4.0; one VIT point raises `get_max_health()` by 12; one AGI point raises `get_movement_speed()` by ~3 %.
- With VIBE forced to 50 (100 % crit), a melee hit deals ×1.75 of the non-crit damage to a roach; with VIBE 0, never.
- A roach with meta `summoned_by_boss` grants 0 XP on death; a normal roach grants 15.
- Queen death grants 120 XP.
- The sheet strings contain "STRIKE" and "per point"; no user-facing string contains "Bat DMG".
- A `BoneAttachment3D` with a bat mesh exists under the player's skeleton after `_ready` (skip gracefully with a clear SKIP line if headless cannot resolve the skeleton, but it should).

## Verification (paste real output)
- Rebuild both DLLs (`py -3 -m SCons platform=windows target=template_debug -j8` and `target=template_release`) and commit them.
- `powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1` — all PASS. Another Codex packet (VS11-IDENTITY) is running in `.worktrees/vs11identity`; do NOT run the suite while its suite is running (check for a `Godot_v4.3-stable_win64.exe --headless` process from that path first); if e2e fails on step c/g, rerun it alone and paste.
- Two off-screen harness shots: `steps="invuln:1,wait:1.5,shot,key:C,wait:0.5,shot"` (bat in hand at spawn, then the sheet). Look at them and describe them in one sentence each.

## Commits
On `vs11-stats`, trailers `Agent: codex/gpt-6.1-sol` + `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. No `*.import` churn, nothing under `ops/runs/`. COMMIT BEFORE FINISHING.

## Report
`ops/reports/VS11-STATS.md`: bone name used, formulas before/after, XP-to-level computation, pasted suite output, shot descriptions, STOP items.
