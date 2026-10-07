# WP-4 — Encounters: fair telegraphs, enemies that matter, combat beats
Agent: codex (gpt-6.1-sol, effort medium). Slot: CODE. Worktree `C:\y2k-biopunk-rpg\.worktrees\wp4` on branch `wp4-encounters` (branched from main AFTER WP-1 and WP-2 merged). Stay there.

Read `AGENTS.md`, `ops/CONTEXT.md`, `ops/reports/AUDIT-PX.md` section 2 and 6, `ops/reports/AUDIT-FEEL.md` section 4 items 3, 5, 8 and the "Also noted" mortar line, then this brief.

## Why this matters
Today the roach pounces with a 0.09 s reaction window, the cicada never attacks, mortars fly over the player's head with no landing marker, the queen's ring hides its true radius until detonation, and enemies vanish silently. Combat needs to be readable before it can be fun. The player now (after WP-2) has 0.6 s hurt i-frames, hit-stop, shake and a 0.22 s evade; tune to that.

## You own (allowed files)
- `scripts/neon_cicada.gd`, `scripts/sludge_roach.gd`, `scripts/corrupted_kiosk_turret.gd`, `scripts/turret_mortar.gd`, `scripts/dial_up_queen.gd` — AI/attack/telegraph/death logic. Visual CONSTRUCTION functions belong to WP-3 (running in parallel); if you must change a visual, do it via emission/scale tweens on existing nodes, do not restructure meshes.
- `scripts/mall_greybox_builder.gd` — `_spawn_enemies` only (counts and positions; keep roaches north as WP-1 set).
- New: `tests/test_encounters.gd`.

## Do not touch
`src/**`, `scripts/hud.gd`, `scripts/isometric_camera.gd`, save/checkpoint/trigger scripts, scenes.

## Scope
1. **Roach.** Trigger pounce at 3.5 m. Wind-up 0.35 s: stop, squash to (1.3, 0.5, 1.3), emission to red, small hiss SFX. Pounce 11 m/s for 0.4 s, bite 10 on contact, then 1.2 s recovery during which it is slow (2 m/s) and takes 1.5× damage (reward the dodge). Pack behavior: at most 2 roaches may be in wind-up/pounce at once (simple shared counter via group meta).
2. **Cicada.** Give it a contact attack: 0.5 s wind-up (wings flare, emission pulse), lunge 1.5 m, 6 damage, 1.5 s cooldown. Keep it the "first contact" enemy: slow (3 m/s chase), fragile (50 HP), awards 10 XP.
3. **Turret.** Replace the fixed mortar velocity with a ballistic solve for the player's predicted position (lead by 0.6 × player velocity), clamp range 6–18 m; spawn a red floor decal (CSG cylinder, alpha 0.4, grows over the flight time) at the predicted impact; splash radius 2.2 m, 20 damage, splash VFX (8 particles, orange) and a thud SFX. Keep the existing green→yellow→red screen ramp (it is good).
4. **Queen.** Telegraph honesty: at charge start show the full-radius outline ring (thin, red, alpha 0.6) at floor height (anchor to floor, not to her hover), fill the disc over the charge, 0.1 s white flash, detonation = expanding shock ring over 0.25 s + 12 particles + camera trauma 0.5 via `get_tree().get_first_node_in_group("camera")` if present (add the camera rig to group `camera` in `isometric_camera.gd`? No — not your file. Use `get_viewport().get_camera_3d().get_parent()` and `has_method("add_trauma")`). Phase 3 radius 12 m over 0.7 s is unreactable: make phase durations 1.4 / 1.1 / 0.9 s with radii 7 / 9 / 11. Minion summons: cap living summoned roaches at 4; summoned roaches tagged `summoned_by_boss` (WP-1 did this — keep).
5. **Death beats** (WP-1 added XP + a 0.15 s scale pop). Add: a 10-particle burst in the enemy's color, a `pop`/`crunch` SFX (procedural, signed 8-bit), and a 0.04 s hit-stop is NOT yours (player does hit-stop on hit). Ensure `_die()` runs exactly once (guard flag) even under flame ticks.
6. **Enemy SFX** (procedural, short, signed 8-bit, own `AudioStreamPlayer3D` per enemy): roach hiss (wind-up), cicada chirp (lunge), turret charge whine (ramp during yellow/red), mortar launch thump + impact thud, queen screech (charge) + detonation boom. Keep each under 0.4 s except the queen screech (0.8 s).
7. **Spawn pacing** in `_spawn_enemies`: first contact = 2 cicadas near spawn plaza (z 4–8, x ±6); roach pack of 3 north of the basin (z −6 to −10); 2 turrets as placed; add one roach + cicada mixed group on the mezzanine approach. Total ≈ 9 enemies before the boss. Target: level 3 reached (XP 50+75 = 125) by the time the boss trigger is reached with XP values 10/15/40.

## Verification
- `tests/test_encounters.gd` (headless, `quit(1)` on fail): roach enters wind-up state at 3.5 m and does not damage before 0.3 s; cicada deals damage ≤ 6 with cooldown ≥ 1.4 s; mortar `setup` with a target 10 m away lands within 1.0 m of the target in a simulated flight; queen phase charge durations as specified; every `_die()` awards XP exactly once under 5 rapid `take_damage` calls; spawn count 9 with ≥ 2 cicadas within 10 m of (0,1,9) and 0 roaches within 10 m.
- Run CONTEXT.md allowed tests plus `tests/test_critical_path.gd` and `tests/test_feel_*.gd` if present — all pass.
- Harness smoke (headless): `-s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn "steps=wait:20,quit"` — the standing player must not die within 20 s; log must show cicada wind-up/lunge lines.

## Commits
On `wp4-encounters`, per scope item, trailers:
```
Agent: codex/gpt-6.1-sol
Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>
```

## Report
`ops/reports/WP-4.md`: TTK/TTD table after your changes (bat, flame, disk vs each enemy; each enemy vs player at 100 HP), test output, skipped items.
