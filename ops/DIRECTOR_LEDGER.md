# Director's Ledger — Y2K: Bio-Punk ARPG

Live project-state document. Owner: the acting Game/Technical Director (Fable 5.1 session, started 2026-10-07).
Another strong agent should be able to take over directorship from this file plus `ops/CONTEXT.md`.
Audits: `ops/reports/AUDIT-ARCH.md` (Codex), `AUDIT-PX.md` (Gemini), `AUDIT-FEEL.md` (Claude Opus). Briefs: `ops/briefs/`.

## Current player experience (verified 2026-10-07, before any changes)

Evidence: `ops/runs/shots/greybox.*.png` (in-engine captures), `ops/runs/shots/greybox.log`, headless test run, three audits.

What actually happens when you press New Game:
- The menu loads a `main.tscn` (root 2D prototype if present, else `scenes/main.tscn`, a flat grey box). The real level `scenes/FloodedMall_Greybox.tscn` is unreachable from the menu.
- If you load the mall directly: the HUD applies the last save on start (`hud.gd:274`), including a save written on death (`hud.gd:491`), so a "new game" resumes a dead run. The player spawns at (0,1,9), inside roach aggro range of three Sludge Roaches in the basin. With zero input the player is dead in ~10 s, the scene reloads, the save re-applies, and the loop repeats.
- Enemies never award XP (`gain_xp` is called from no GDScript). Leveling and the stat sheet are dead in play.
- The Neon Cicada has no attack. It is a green cylinder that wanders.
- The character model floats 1.08 m above the floor in a frozen A-pose; no clip loops; blend time 0; walk cycle slides 9x; melee damage lands 0.35 s before the fist moves; getting hit has no feedback and no i-frames; every procedural SFX is written unsigned into a signed 8-bit stream and plays as buzz.
- Movement is instant on/off, skating is a 6→12 m/s step with no glide; jumps hang 1.25 s; grinding is a magnet that snaps from any angle; slam fires in mid-air.
- Enemies are untextured CSG primitives; the player is ~40 px tall at the 16 m camera arm; the level is uniformly grey under one directional light with no glow/SSAO/fog.
- Death reloads the whole scene, respawning every enemy; the boss trigger requires every enemy dead, so each boss retry means re-clearing the mall. Beating the boss ends nothing.
- Evade then attack leaves the player permanently invincible (state exit never runs).

What is genuinely good and must be protected:
- The traversal fantasy: skates, rails that snap and carry you, the dismount slam AoE.
- The Walkman tape as a stat/music switch. Thematic, instant, legible in the HUD. Eight real tracks.
- Turret (green→yellow→red screen) and boss (expanding ring) telegraphs are the right pattern.
- The flamethrower feels powerful; the disk launcher works.
- The C++ player core is stable and well-bound; headless tests of stats/tapes pass. The C++/GDScript split is workable (Codex's conclusion, which I share): keep it, fix contracts, add one GDScript session/flow owner.

## Vertical Slice 1 — definition of done

A first-time player, given only the on-screen prompts, can:
1. Press New Game from the menu and arrive in the Flooded Mall with full HP at level 1 (no stale save), standing on the floor in a readable pose, and survive the first 20 s without input.
2. Learn skates, evade, tape switch and secondary weapon from the pager within the first two minutes.
3. Fight cicadas, roaches and turrets that each read differently, telegraph before they hurt, and award XP; reach at least level 3 and spend a stat point before the boss.
4. Grind at least one rail intentionally (entry requires approach alignment), dismount-slam onto the floor, and feel the hit (hit-stop, shake, sound).
5. Take damage and know it (flash, sound, knockback, 0.6 s i-frames); die; respawn at the last Bio-Stabilizer with saved progression; reach the boss again without re-clearing the mall.
6. Fight the Dial-Up Queen with honest telegraphs; on victory see a completion card and return to the menu. Continue from the menu restores the last checkpoint.
7. Hear a sound for: swing, hit, hurt, jump, land, evade, grind, pickup, kill, tape clack. Music tapes keep playing across switches without restarting.
8. No crash, no error dialog, no console-only messaging for anything the player needs. `ops/tools/run_tests.ps1` exits 0.
Target session length 15–30 min. Explicitly OUT: new enemies, weapons, biomes, NPC/dialogue (the C++ soldier stays dormant), tape splicing, controller support.

## Work packets (ordered by player impact → dependency → risk)

| ID | Objective | Player problem solved | Owner / model / effort | Depends on | Diff | Risk | Status |
|---|---|---|---|---|---|---|---|
| WP-1 | Critical path: menu→mall, New/Continue, XP on kill, checkpoint respawn, boss gate + victory, cruft removal | Can't start, can't progress, can't retry, can't finish | Agy gemini-3.1-pro-high | — | M | Med (save semantics) | running (wt wp1) |
| WP-2 | Feel core: grounded model, anim blend/loop/speed-match, momentum + jump, melee timing + hit-stop + shake, hurt feedback, SFX format, grind entry/slam-on-land, evade tune, state-machine exits | Looks and feels broken moment to moment | Codex gpt-6.1-sol high | — | L | Med (hot file, feel tuning) | running (wt wp2) |
| WP-5 | Honest test harness: exit codes, no crash at exit, isolated save path, one-command runner | Director can't trust any gate | Agy gemini-3.8-flash-high | — | S | Low | running (wt wp5) |
| WP-3 | Presentation: WorldEnvironment glow/SSAO/fog/MSAA, color language (player green, enemies magenta/orange, interactables cyan, telegraphs red), emissive rails/kiosks, cutaway south/east walls, HUD legibility (no 0.7 scale, ≥20 px), adrenaline bar, pager messages for gate/level-up | Grey soup, unreadable enemies, tiny text | Agy gemini-3.1-pro-high | WP-1 merged | M | Low–Med | queued (brief drafted) |
| WP-4 | Encounters: roach wind-up (0.35 s), cicada contact attack, mortar ballistic solve + landing marker, queen telegraph honest radius + detonation VFX/SFX, death pop + kill SFX, enemy SFX, spawn pacing | Enemies unfair or harmless; no combat beat | Codex gpt-6.1-sol medium | WP-1 + WP-2 merged | M | Med | queued (brief drafted) |
| WP-6 | Onboarding + audio pass: pager tutorial lines (skates/evade/tape/secondary/grind) timed to first encounters; SFX for jump/land/grind/flame/disk/tape; music continues across tape switch | Nothing is taught; silence | Claude sonnet | WP-2 + WP-3 | S–M | Low | queued |
| WP-7 | Integration playtest + balance (TTK/TTD table, XP curve to level 3–4 before boss, candy placement) | Difficulty curve | Fable + Gemini review | all above | S | Low | queued |

## Active work
| Agent | Packet | Where | Started |
|---|---|---|---|
| Agy (gemini-3.1-pro-high) | WP-1 | `.worktrees/wp1` branch `wp1-critical-path` | 16:00 |
| Codex (gpt-6.1-sol, high) | WP-2 | `.worktrees/wp2` branch `wp2-feel-core` | 16:04 (first attempt failed: `workspace-write` sandbox cannot write `.git`; relaunched with `danger-full-access`) |
| Agy (gemini-3.8-flash-high) | WP-5 | `.worktrees/wp5` branch `wp5-test-harness` | 16:03 |
| Fable | ledger, WP-3/WP-4 briefs, review on landing | main checkout | — |

## Ready for integration
(none yet)

## Verified
(none yet)

## Rejected / reworked
- WP-2 attempt 1 (Codex, `-s workspace-write`): no changes made; sandbox blocked git. Relaunched. Not a quality rejection.

## Next highest-leverage work
1. Land WP-1 → smoke-test New Game → mall → survive → kill → XP → checkpoint → die → respawn → boss → victory with the harness.
2. Land WP-2 → screenshots + feel test; play it myself via harness; verify hit-stop and SFX by log.
3. Dispatch WP-3 on top of WP-1; WP-4 on top of WP-1+WP-2.
4. WP-5 runner becomes the gate for every later merge.

## Anthony decisions
Nothing so far needs human taste. Candidates to surface at the end: (a) walk speed 7.5–9.3 vs. a slower 5–6 m/s walk that makes skates feel like a real upgrade; (b) orthographic vs. perspective camera; (c) whether the dormant NPC/dialogue system stays in the slice.

## Machine-state changes made by the Director
- 2026-10-07 15:48: set `HKCU\Software\Microsoft\Windows\Windows Error Reporting\DontShowUI = 1` (was unset) so Godot crash-at-exit dialogs from headless test runs stop popping on Anthony's screen. Revert with `Remove-ItemProperty` on that key if unwanted.

## Baseline facts
- Build: `py -3 -m SCons platform=windows target=template_debug -j8` works; DLL dated Sep 18 is "up to date".
- Tests (headless, before WP-5): `test_systems`, `test_tapes`, `test_candy_pickup`, `test_flamethrower_particles`, `verify_camera_and_hud` pass. `test_3d_player` and `test_cursor_aiming` crash calling `_ready()` directly (not exposed). `test_5_systems` writes the production save path; `test_grinding` fails on a group assertion; exit codes are always 0.
- Quotas 16:05: Codex 79% 5h / 97% wk; Gemini 92% 5h / 98% wk; Claude 70% 5h / 48% wk (Fable 41%), Claude weekly resets 10/8 00:00.
- Worktrees: `ops/tools/setup_worktree.ps1` copies the engine exe, the whole `godot-cpp` tree (309 MB) and the DLL, then runs a headless import. Agents must not commit `*.import` churn.
