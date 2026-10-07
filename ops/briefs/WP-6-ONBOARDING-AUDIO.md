# WP-6 — Onboarding and audio pass: teach the controls through the pager, give every action a sound, keep the music playing
Agent: agy / gemini-3.1-pro-high. Slot: CODE. Worktree `C:\y2k-biopunk-rpg\.worktrees\wp6` on branch `wp6-onboarding-audio` (branched from main AFTER WP-3 merged). Stay there.

Read `AGENTS.md`, `ops/CONTEXT.md`, `ops/reports/AUDIT-PX.md` section 3 (onboarding failures) and `ops/reports/AUDIT-FEEL.md` section 4 item 10 (missing SFX, tape restart), `ops/reports/WP-3.md` (the `page_message` API you will use), then this brief.

## Why this matters
Nothing teaches skates (K), evade (Shift/V), tape (T), secondary (Q/RMB) or that grinding requires skates and an aligned approach. The game is silent except for a handful of procedural cues. Players who do not discover K never see the best part of the game.

## You own (allowed files)
- New: `scripts/tutorial_director.gd` (a Node added to the mall scene by `mall_greybox_builder.gd::_ready` at runtime — do NOT edit the .tscn) and `tests/test_onboarding.gd`.
- `scripts/mall_greybox_builder.gd`: ONLY the few lines in `_ready` that instantiate the tutorial director.
- `scripts/hud.gd`: ONLY `page_message` (extend with an optional `key_hint` argument if useful) and `_update_control_tip` (replace the static tip with the tutorial's current hint).
- `src/player_controller.cpp`: ONLY inside `switch_tape()` (music continuity) and the `create_sfx_stream` family / `play_sfx` (new cue names). Rebuild the DLL with SCons; include it in your commit since this packet changes native code.
- `scripts/sludge_roach.gd`, `scripts/neon_cicada.gd`, `scripts/corrupted_kiosk_turret.gd`, `scripts/turret_mortar.gd`, `scripts/dial_up_queen.gd`: ONLY if WP-4 did not already add their SFX (check `git log`/code first); if present, do not touch.

## Scope
1. **Tutorial director (pager-driven, event-gated, no modal).** Lines appear in the pager via `page_message`, each shown once, each dismissed by doing the thing or after 8 s, with a 0.5 s beep. Sequence and gates:
   - t+1 s: `MOVE: WASD   //   SWING: LMB` → dismissed on first move + first swing.
   - first enemy within 8 m: `EVADE: SHIFT or V  (i-frames)` → dismissed on first evade.
   - first time HP < 60%: `TAPE: T cycles mixtapes — VIT tapes heal-scale` → dismissed on tape switch.
   - after 2 kills or 25 s: `SKATES: K  — 2x speed, rails become grindable` → dismissed on skates toggle.
   - first time skating within 6 m of a rail: `GRIND: skate ALONG the rail and JUMP onto it; JUMP again to slam off` → dismissed on first grind.
   - first time a turret is within 14 m: `TURRET: watch the screen — green→yellow→RED means a mortar is coming` → dismissed after 8 s.
   - on entering the boss trigger: nothing (WP-1 pages the quarantine line).
   Signals to use: player `tape_switched`, `skates_toggled`, `evade_started`, `grind_started`, `attack_executed`, `health_changed`; enemies group `enemies`.
2. **Control tip replacement.** The pager's static `ControlTip` line becomes the tutorial's current hint, and reverts to a compact permanent legend `WASD · LMB · RMB/F · Q · K · T · SHIFT · C` after the tutorial finishes.
3. **Music continuity.** `switch_tape` must not restart the track from 0 each time: keep a per-tape playback position (`Dictionary` of tape → seconds) and resume from it; crossfade 0.25 s using a second `AudioStreamPlayer` (`WalkmanAudioB`) with a volume tween. The tape "clack" becomes a real short SFX (`clack`, 60 ms noise burst + click).
4. **SFX coverage (procedural, signed 8-bit, same style as the existing cues).** Add to the native cue table: `evade` (if missing), `grind_start`, `grind_loop` (looping 0.4 s metallic rasp, started/stopped with `grind_started`/`grind_ended`), `flame_loop` (looping hiss while spraying), `disk_fire`, `disk_hit`, `tape_clack`, `levelup` (3-note rising arpeggio), `page_beep`. Loops must stop cleanly on state exit (use the state exit hooks WP-2 added).
5. **Volume.** Music −8 dB default, SFX 0 dB, on separate buses `Music` and `SFX` (add via `AudioServer` at runtime if `default_bus_layout.tres` does not exist; do not add new resource files unless needed).

## Verification
- `tests/test_onboarding.gd` (headless, `quit(1)` on fail): tutorial node exists after mall load; first hint appears within 1.5 s; the skates hint is dismissed by `skates_toggled`; `switch_tape` twice then back resumes the first tape at > 0 s position; every cue name in the list exists in the native cue table (`play_sfx` returns without error and a `sfx_played(name)` signal fires — add that signal).
- `ops/tools/run_tests.ps1` all PASS.
- Harness screenshot `ops/runs/shots/wp6.*` showing a pager hint on screen.

## Commits
On `wp6-onboarding-audio`, per scope item, trailers `Agent: gemini/gemini-3.1-pro-high` + `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. Include the rebuilt DLL in the commit that changes `src/`.

## Report
`ops/reports/WP-6.md` with pasted test output.
