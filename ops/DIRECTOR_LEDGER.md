# Director's Ledger — Y2K: Bio-Punk ARPG

Live project-state and handoff document. Directors: Fable 5.1 sessions, 2026-10-07 (VS1) and 2026-10-08 13:00 → 15:00 (VS1.1).
Another strong agent can resume directorship from this file plus `ops/CONTEXT.md`.
Reports: `ops/reports/` (audits, `WP-*` for VS1, `VS11-*` for VS1.1, `CRITIC-*` for the independent critiques). Briefs: `ops/briefs/`.
Gate: `powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1` (23 suites, all PASS at HEAD).

## VS1.1 — Showable build (status: complete except the owner playtest)

Milestone artifact: `build/Y2K-BioPunk-VS1.1-win64.zip` (244 MB) produced by `ops/tools/build_release.ps1` from main at `38f59ba`+docs; contents `build/release/` = `Y2K-BioPunk.exe` (84 MB release template), `Y2K-BioPunk.pck` (224 MB, 100 entries, no ops/tests/src/godot-cpp files), `libbiopunk.windows.template_release.x86_64.dll`, `Y2K-BioPunk.console.exe` (log-capturing launcher), `BUILD-INFO.txt`, `MUSIC-CREDITS.txt`. A second preset builds `build/qa/` (debug template, includes `tests/` and the shot harness) for packaged verification. Saves land in `%APPDATA%\Godot\app_userdata\Y2K- Bio-Punk\`.

### Definition of done (status at HEAD)
| # | Criterion | Status / evidence |
|---|---|---|
| 1 | All required tests pass | **23/23** (`ops/runs/tests/` latest log; VS1's 19 plus `test_occlusion`, `test_character_sheet`, `test_tune`, `test_effect_warmup`) |
| 2 | C++ release target builds | `scons target=template_release` clean; release DLL committed in `bin/` |
| 3 | Standalone Windows build produced | zip above; `build_release.ps1` exit 0 |
| 4 | Launches without the editor | `smoke_packaged.ps1`: release exe 600 frames off-screen, zero error lines; intro video → menu verified in `ops/runs/pkg_release_launch2.log` |
| 5-7 | New Game / Continue / death-respawn | `test_slice_e2e` + `test_menu_flow` run INSIDE the QA pack: PASS (`ops/runs/smoke_final.log`) |
| 8 | Final visual models | Meshy GLBs accepted (Director review + two critiques); tints/screens adjusted, no regeneration |
| 9 | Player occlusion | `scripts/occlusion_fader.gd` (AABB registry, per-instance transparency 0.7, 8/s in 5/s out, 0.15 s hold, warm-up); accepted in `ops/runs/shots/vs11/occ_grid.png` |
| 10 | Character sheet deliberate | Pauses the tree, dim overlay, `PAUSED // BIO-STATS`, C/Esc/close resume, Walkman keeps playing, guarded on death/victory; `test_character_sheet` |
| 11 | Telegraphs readable | Wind-ups amber, hits red, roach vulnerable pale cyan, turret body screen ramps, Queen blast magenta-white (no blow-out), phase-3 charge 1.05 s / flash 0.3 s |
| 12-13 | 60 fps stable, no recurring combat stutter | See performance table; one 27 ms frame in 24 s under a 60 cap at the first cicada lunge, none in the arena |
| 14 | No missing assets/errors in package | Smoke filter PASS; pck proof in `ops/reports/VS11-EXPORT.md` |
| 15-16 | Full run reaches/defeats Queen, victory → menu | e2e inside the pack; victory flow re-shot `ops/runs/shots/vs11/tune_grid.png` |
| 17 | Two independent critics triaged | `CRITIC-VISUAL-BASELINE-VS11.md`, `CRITIC-GAMEPLAY-VS11.md` (Opus), `CRITIC-VISUAL-ROUND2-VS11.md`; triage below |
| 18 | Owner playtest | **PENDING** — checklist in the handoff message / bottom of this file |
| 19 | Docs match reality | This file, README, GAME_SYNOPSIS, AGENTS, CONTEXT updated 2026-10-08 |
| 20 | Remaining problems classified | Section "Remaining issues" below |

### What changed in VS1.1 (all merged on main, each verified by the Director re-running its tests and taking own screenshots)
| Packet | Agent | Result |
|---|---|---|
| VS11-SHEET | Claude Sonnet 5.5 | Character sheet pauses the game (overlay, Esc, guards, Walkman keeps playing); project name "Y2K: Bio-Punk" (was "Y2"); menu title fixed, dead Options/Credits removed; boss-trigger `set_deferred` error gone; e2e step c polls instead of 2 frames. |
| VS11-OCC | Codex high | General occlusion fader (see DoD 9); builder registers tall boxes/cylinders/props; old pillar hack removed. |
| VS11-EXPORT | Codex high | `export_presets.cfg` (release + QA), `build_release.ps1`, `smoke_packaged.ps1` (pck reader, forbidden-path check, packaged tests, off-screen launch), `ops/runs/.gdignore`. |
| VS11-LOOK | Gemini 3.1 Pro | Tiled floor (runtime texture, triplanar), wall value split + cyan trims, pillar plinths/caps, kiosk/storefront/food-court signage, Queen arena (dark pit, magenta ring, strip light, server racks, "MEGABYTE ELECTRONICS / 56K // NO CARRIER"), checkpoint terminal, menu with in-game background, HUD action bar un-overlapped, health bar restyle, softer state tints, turret body screen, water normal map. Director fix-ups: it had rewritten `project.godot` (dropped shadow 4096 and flush settings — restored), put pillars under a `CSGCombiner3D` (breaks per-pillar fading — reverted), hand-written a wrong `.import` + loader script for the menu background (replaced with a real texture import), committed eight Python helper scripts (deleted), and made the arena a solid magenta disc (now dark disc + thin ring, lights 1.5→0.7). |
| VS11-TUNE | Codex high | Director triage of the Opus gameplay critique: arena entry saves progression (respawn stays at the Bio-Stabilizer, pager "PROGRESS SAVED"); Bio-Stabilizer heals and pages; victory = invincible + every enemy freed + card after 1.2 s + no level-up spam; pager truthful/complete (secondary hint, SPACE, +38 % skates, tape text, evade priority, STAT PTS from start); amber wind-ups; summon warning + 5 m minion spacing; phase-3 timing; disk cooldown 0.45→0.8; slam base +5; cicada contact 6→10; turrets idle during the boss; roach bite knockback. |
| VS11-WARM | Codex high | `scripts/effect_warmup.gd`: sub-pixel in-frustum probes draw every combat shader variant (tints, bursts, mortar/marker, Queen ring, slam material, flame particles) and cache all SFX recipes before the first fight. Found a real 294 ms first draw of the native slam material and 180 ms first draw of a new variant. The original 131 ms frame was not reproduced (it was measured while other agents' windowed runs shared the GPU). |
| Director | Fable | Harness steps `tp/heal/invuln/dmg/shadow*`; HUD honours `--windowed`; shadow atlas 4096 + blur 1.6 (measured free); release DLL committed; 190 MB of unreferenced player GLB variants/sprite dupes/root test files removed; all merges, conflict resolution, fix-ups, measurements, critic triage. |

### Accepted visual decisions
Night-mall teal palette, magenta enemies, yellow rails, orange kiosk pools, magenta boss arena; camera 12 m / FOV 45 (owner); FSR 0.75 at 1080p, MSAA 2x, SSAO very-low, glow, fog 0.004; shadow atlas 4096, 2 PSSM splits, 45 m, blur 1.6; occlusion fade target 0.7; signage via unshaded Label3D with outline; no Meshy regeneration (credits ~210/437 used).

### Critic triage
MUST (done): silent progress loss, unsafe victory window, false/missing pager lines. SHOULD (done): phase-3 screech timing, summon warning, telegraph colours, disk cooldown, slam damage, turrets during boss, roach knockback, onboarding fixes, cicada damage, HUD overlap, menu, checkpoint terminal, arena dressing, surfaces, tints, turret screen, water, health bar, shadow softness.
LATER (post-VS1.1 polish): Queen HP / fight length (critic estimates 40-45 s bat-only; owner taste), rails as a gimmick (relocation), victory card art and key-press dismissal, Continue after victory still loads the checkpoint run, deflect sound on invulnerable Queen, action-bar label size (10 pt, clipped at the right edge at 1080p), stylised action-bar icons, floor roughness/normal maps, stronger light pools.
REJECTED: volumetric fog and higher SSAO (GPU budget on the target laptop), lowering the directional light (player readability), CRT curvature, any change to the owner's five rulings.

### Performance (final build, 2026-10-08 14:45; GTX 1060 Max-Q verified at 1670 MHz P0 during the runs via `nvidia-smi`; engine binary, window off-screen, 3D 1440x810 FSR → 1080p)
| Spot | avg fps | 1 %-low | worst frame | render_gpu | draw calls |
|---|---:|---:|---:|---:|---:|
| Spawn, first cicadas | 121.5 | 91.6 | 12.8 ms | 7.31 ms | 373 |
| Basin, roaches | 125.1 | 106.6 | 12.7 ms | 7.57 ms | 340 |
| Arena, Queen awake | 124.4 | 102.7 | 10.6 ms | 7.70 ms | 409 |
| 60 fps cap + vsync (not the shipped config), spawn 12 s | 60.0 | 54.4 | 27.2 ms (one frame) | 8.08 ms | 372 |
| 60 fps cap + vsync, arena 12 s | 60.0 | 54.9 | 19.3 ms | 8.33 ms | 408 |
| Packaged QA exe, spawn | 120.6 | 104.4 | 9.8 ms | 7.82 ms | 373 |
VS1.1 added ~0.4 ms GPU over the VS1 baseline (7.3 ms). Lessons that still hold: hidden/parked GPU and other GPU users invalidate absolutes (two 97 ms and 14 ms readings this session were contention from agents' off-screen runs); `TIME_PHYSICS_PROCESS` folds the vsync wait; never cap `max_fps` with vsync on; hot-path `print()` is 3 ms a line.

### Remaining issues (classified)
- **Blocker:** none known.
- **Post-VS1.1 polish:** the LATER list above; the packaged exe resolves `bin/*.dll` relative to its own folder (launch from the folder, as a double-click does; launching via a relative path from another cwd failed to load the extension); `BUILD-INFO.txt` reports "Working tree modified" when any untracked file exists; one ~27 ms frame at the first cicada lunge survives the warm-up on some runs; `test_slice_e2e` steps c/g flake when two checkouts run suites at once (shared `user://` save) and `test_presentation` crashed at exit once under that load.
- **Phase 2:** tape splicing, new enemies/weapons/biomes, controller support, NPC dialogue, save slots, kill persistence (owner rejected for the slice).
- **Rejected:** see triage.

### Owner checklist (Anthony, taste only — answers are final)
1. Do the new enemies and the Queen look good in actual play, not just in screenshots?
2. Is the player ever hard to see (pillars, mezzanine edge, arena)?
3. Does the mall now feel like one place (signs, arena, checkpoint), or still a greybox with stickers?
4. Does the Queen fight look and feel like a boss, and is the phase-3 screech dodgeable?
5. Did anything still scream "prototype" (HUD, menu, victory card, sounds)?
6. Did you notice any stutter or hitch, especially in the first fight?
7. Did any pager hint annoy, confuse, or arrive too late?
8. Would you hand `build/Y2K-BioPunk-VS1.1-win64.zip` to a stranger as is?

## VS1 history (2026-10-07, condensed)
Experience and DoD: New Game → flooded mall → telegraphed cicadas/roaches/turrets → XP/levels/character sheet → Bio-Stabilizer → death/respawn with progression → skate/rail/slam → three-phase Dial-Up Queen → victory card → menu → Continue. Packets WP-1..8 (audits by Codex/Gemini/Opus; critical path, feel core, presentation, encounters, test harness, onboarding/audio, e2e + balance, docs) all merged; details in `ops/reports/WP-*.md`.
Lessons: agents must paste real test output (one fabricated pass, one hung test); Codex needs `danger-full-access` in a worktree and `< /dev/null` when launched from a background shell; Gemini/Sonnet via Antigravity hit quotas mid-packet; agents leave dirty trees unless the brief says "COMMIT before finishing"; re-run every claimed test and look at the agent's screenshots before merging; never let an agent open a window on Anthony's screen (`--position 2000,2000`).
Owner decisions (2026-10-08 playtest, all **keep**): camera 12 m / FOV 45; walk and skate both; SFX and Music −8 dB; enemies respawn on death; roach cap of 2 attackers.
Performance history: thermal throttling on the laptop was the root cause of the original fps complaint (Dell Power Manager "Quiet" → "Ultra Performance"); game-side cuts (no omni shadows, 2-split directional shadow, FSR 0.75, hot-path prints → `print_verbose`, cached FX, primitive colliders) halved GPU time and removed the missed vblanks.

## Machine-state changes made by the Director
- 2026-10-08: Godot 4.3 stable export templates installed to `%APPDATA%\Godot\export_templates\4.3.stable\` (Windows release/debug + console variants, from the official tpz).
- 2026-10-08: stale editor layout entries for the deleted `scenes/main.tscn` removed from `.godot/editor/` (local, gitignored) so the headless import no longer errors.
- 2026-10-08 10:50: Dell Power Manager thermal mode Quiet → Ultra Performance (Anthony); background apps closed for measurements.
- 2026-10-07: `HKCU\...\Windows Error Reporting\DontShowUI = 1` so crash-at-exit dialogs from headless tests stop popping.

## Baseline facts for the next director
- Build: `py -3 -m SCons platform=windows target=template_debug -j8` and `target=template_release` (never with a Godot instance open from the same checkout). Both DLLs are committed.
- Tests: `ops/tools/run_tests.ps1`; single: `./Godot_v4.3-stable_win64.exe --headless --path . -s tests/<file>.gd`. Do not run suites in two checkouts at once.
- Package: `powershell -NoProfile -ExecutionPolicy Bypass -File ops/tools/build_release.ps1` then `ops/tools/smoke_packaged.ps1`; artifacts under `build/` (gitignored).
- Screenshots/scripted input/perf: `ops/tools/shot_harness.gd` (header lists steps: `tp/heal/invuln/dmg/fps/profile/bench/firstuse/shadow*` and A/B toggles); always `--position 2000,2000`; the GPU must be unshared and at full clock for absolutes.
- Agents: `ops/CONTEXT.md` rules; worktree per packet via `ops/tools/setup_worktree.ps1`; Codex `-s danger-full-access` + `< /dev/null`; `agy --dangerously-skip-permissions` (Gemini writes helper scripts and rewrites `project.godot` — diff everything); reports must paste output; commit before finishing.
- Quotas (2026-10-08 13:15): Codex 100 % 5 h / 91 % week; Gemini 100 % / 83 %; Antigravity Claude/GPT weekly exhausted; Claude Code 96 % / 94 %.
