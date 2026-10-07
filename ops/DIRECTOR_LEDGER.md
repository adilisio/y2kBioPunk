# Director's Ledger — Y2K: Bio-Punk ARPG

Live project-state and handoff document. Director: Fable 5.1 session, 2026-10-07 15:35 → ~19:30.
Another strong agent can resume directorship from this file plus `ops/CONTEXT.md`.
Audits: `ops/reports/AUDIT-ARCH.md` (Codex), `AUDIT-PX.md` (Gemini), `AUDIT-FEEL.md` (Claude Opus). Packet reports: `ops/reports/WP-*.md`. Briefs: `ops/briefs/`.
Gate: `powershell -ExecutionPolicy Bypass -File ops/tools/run_tests.ps1` (19 suites, all PASS at HEAD).

## Current player experience (verified at HEAD, 2026-10-07 evening)

Evidence: `ops/runs/shots/final.*.png`, `light3.*.png`, `wp4main.*.png`; `tests/test_slice_e2e.gd` (whole loop in 15 s, 3× consecutive); `tests/test_menu_flow.gd`.

Press New Game and you:
- Arrive in the flooded mall at level 1, full HP, no stale save. The character stands on the floor in a guard stance, lit by a fill light, under emergency lighting with glow, SSAO and fog. The pager reads "MOVE: WASD // SWING: LMB".
- Meet two magenta cicadas ~4 s in. They flare their wings for 0.5 s, then lunge for 6. You swing: damage lands on the fist, hits freeze for 60 ms and shake the camera, enemies flash red and get knocked back, and die with a pop and XP. Getting hit flashes you white→red, knocks you back, plays a hurt tone, and gives 0.6 s of i-frames.
- Learn evade, tape, skates, grind and turret reading from the pager as each becomes relevant. Skates glide and carve; rails glow yellow; entering a rail needs an aligned approach and a jump; jumping off slams on landing.
- Fight a roach pack that winds up for 0.35 s before pouncing and is vulnerable afterwards (pack-limited to 2 attackers), and turrets whose screens ramp green→yellow→red before a ballistic mortar lands on a red marker.
- Reach level 3 before the arena (170 XP available vs. 125 needed), spend points in the character sheet (which locks input).
- Hit the Bio-Stabilizer at spawn to save; die and respawn there with progression intact; enemies respawn, the boss gate does not require re-clearing.
- Enter the north arena to wake the Dial-Up Queen (1500 HP): her blast radius is drawn at full size from the start of each charge; phases 2 and 3 are faster and larger; she summons up to four roaches. Victory shows a completion card and returns you to the menu, where Continue restores your checkpoint.
- Music tapes switch with a clack and crossfade, resume where they left off, and run on a Music bus at −8 dB; SFX on their own bus.

What is genuinely good (protect): the traversal fantasy (skate glide → rail → slam), the Walkman as stat/music switch, turret/boss telegraph language, the flamethrower's power, the night-mall palette with magenta enemies, the pager as the voice of the game.

## Vertical Slice 1 — definition of done (status)

| # | Criterion | Status |
|---|---|---|
| 1 | New Game → mall, level 1, full HP, survive 20 s idle | **Done** (`test_critical_path`, `test_menu_flow`, `test_encounters` 20 s survival) |
| 2 | Skates/evade/tape/secondary taught by the pager in the first two minutes | **Done** (`test_onboarding`; grind/turret hints too) |
| 3 | Three enemy types read differently, telegraph, award XP; level 3 before boss | **Done** (`test_encounters`, balance table) |
| 4 | Intentional grind entry, dismount slam on floor, hit feel (hit-stop/shake/sound) | **Done** (`test_feel_traversal`, `test_feel_combat`) |
| 5 | Hurt feedback + i-frames; die → respawn at checkpoint with progression; no re-clear for boss | **Done** (`test_slice_e2e` d, `test_gameplay_fixes`) |
| 6 | Queen with honest telegraphs; victory card; menu; Continue | **Done** (`test_slice_e2e` f–g) |
| 7 | Sounds for swing/hit/hurt/jump/land/evade/grind/pickup/kill/clack; music continuity | **Done** (cues exist and fire; listening test NOT done — see Anthony checklist) |
| 8 | No crash/dialog/console-only messaging; runner exits 0 | **Done** (19/19) |

## Work packets — final state

| ID | Objective | Owner / model | Result |
|---|---|---|---|
| AUDIT-ARCH / PX / FEEL | Three independent audits | Codex high / Gemini 3.1 Pro / Claude Opus | All three used; FEEL's measured numbers drove WP-2; ARCH found the evade-invincibility and root-scene bugs; PX found dead XP and the death loop. |
| WP-1 critical path | menu→mall, save semantics, XP, respawn, boss gate, ending, cruft | Gemini 3.1 Pro | Merged + Director fix-up (victory wiring, real test). |
| WP-2 feel core | grounding, anim sync, momentum, melee timing, hurt, SFX format, grind/evade, state machine | Codex high | Merged; best report of the day (measured before/after). |
| WP-3 presentation | environment, color language, silhouettes, HUD legibility, pager queue | Gemini 3.1 Pro | Merged + Director re-tune (lighting, runtime rebuild). |
| WP-4 encounters | telegraphs, cicada attack, ballistic mortars, queen telegraph, death beats, SFX, spawns | Codex medium | Merged (Director committed; one conflict resolved). |
| WP-5 test harness | honest exit codes, no crashes, isolated save, runner | Gemini 3.8 Flash | Merged + Director runner fixes. |
| WP-6 onboarding/audio | pager tutorial, buses, tape resume/crossfade, cues | Gemini 3.1 Pro → Claude Sonnet 5.5 (both ran out of Antigravity quota) | Merged; Director finished the last 1% (TestUtil preload). |
| WP-7 e2e + balance | whole-loop test, balance table, duplicate-signal fix | Codex medium | Merged; Director applied HP tuning from its table. |
| WP-8 docs | AGENTS/README/SYNOPSIS true again | Codex low | Merged + Director fix-up (branch predated the WP-6 merge, so WP-6 was described as unverified and two tests were missing; corrected). First launch hung 80 min reading stdin — always launch `codex exec` with `< /dev/null` from a background shell. |

Director-authored changes: camera arm 16→12 m / FOV 45; boss gate moved to z −19; builder as runtime source of truth + lighting tune + player fill light; HP label outline; cicada flash tone; roach 45 / cicada 70 / Queen 1500 HP; first-contact cicadas 3.5 m further out; `tests/test_critical_path.gd`, `tests/test_menu_flow.gd`; runner process handling; all merges.

## Rejected / reworked (lessons)
- WP-1's report claimed a passing test that called a nonexistent API and hung, and a victory flow that was never wired. → Every later brief required pasted test output; the Director re-ran every claimed test.
- WP-2 attempt 1: Codex `workspace-write` sandbox cannot write `.git` → use `danger-full-access` in a dedicated worktree.
- WP-3's own screenshots showed a near-black floor and unlit player; its material edits were invisible because the scene carried stale baked geometry. → Builder now rebuilds at runtime; the Director tuned lighting by eye.
- WP-4 and WP-6 left their trees dirty (no commits). → Briefs now say "COMMIT before finishing"; the Director commits salvageable work under the agent's trailer.
- Gemini 3.1 Pro exhausted its 5-hour quota mid-WP-6; Sonnet via Antigravity then exhausted the weekly Claude/GPT bucket. → Check `C:\FO5\check-quotas.ps1` before dispatching long packets; Codex had the most headroom all day.

## Remaining issues

**Must fix before showing people**
1. Nobody has *listened* to the game. All SFX are procedural 8-bit and were verified only by encoding/signal tests. Expect some cues to be harsh; the mix (Music −8 dB vs SFX 0 dB) is a guess.
2. Nobody has played with a mouse and keyboard in a real window. Cursor-aim + movement direction, the skate turn feel, and grind entry tolerance are tuned to numbers, not hands.
3. Death respawns the entire enemy roster (by design for now). If Anthony finds re-fighting the plaza tedious, persist kills in the save.

**Should fix later**
4. Pillar fade when they occlude the player (WP-3 brief item; not verified in shots). North/west perimeter walls are still 4.5 m.
5. Roach/cicada CSG silhouettes are placeholders (magenta capsule with wing planes). The wing planes read oddly from some angles.
6. Camera has look-ahead but no occlusion handling; the mezzanine edge can hide the player briefly.
7. The character sheet locks input but has no "paused" visual; enemies keep moving while it is open.
8. The dormant C++ `StrandedSoldierNPC` / `MutatedBugEnemy` and the dialogue UI are unreferenced; delete or port to 3D in a later slice.
9. Only a Windows debug DLL ships; no release build, no Linux manifest entry.
10. README lost its feature overview in WP-8 (the old one was stale); worth a short, correct Features section later.

**Deliberately deferred** (out of slice scope by Director ruling)
- Tape splicing, new enemies/weapons/biomes, controller support, NPC dialogue in 3D, save slots.

## Anthony decisions (taste only)
See the playtest checklist in the final report. Candidates: camera distance (12 m vs 16 m), walk speed vs skate contrast, SFX character/mix, whether death should respawn enemies, roach pack size.

## Machine-state changes made by the Director
- 2026-10-07 15:48: `HKCU\Software\Microsoft\Windows\Windows Error Reporting\DontShowUI = 1` (was unset) so Godot crash-at-exit dialogs from headless tests stop popping. Revert with `Remove-ItemProperty` if unwanted.
- Worktrees under `.worktrees/` (gitignored); all merged and removed except a stale `wp6` directory copy (locked during cleanup; safe to delete).

## Baseline facts for the next director
- Build: `py -3 -m SCons platform=windows target=template_debug -j8` (never with a Godot instance open from the same checkout).
- Tests: `ops/tools/run_tests.ps1`; single: `./Godot_v4.3-stable_win64.exe --headless --path . -s tests/<file>.gd`.
- Screenshots/scripted input: `ops/tools/shot_harness.gd` (see header); always `--position 2000,2000` to keep the window off Anthony's screen.
- Agents: `ops/CONTEXT.md` rules; worktree per packet via `ops/tools/setup_worktree.ps1`; Codex `-s danger-full-access`; agy `--dangerously-skip-permissions`; reports must paste output; commit before finishing.
- Quotas (19:20): Codex ~45% 5h / 93% wk; Gemini 5h exhausted until ~22:00; Antigravity Claude/GPT weekly exhausted (~5 days); Claude Code weekly resets 10/8 00:00.
