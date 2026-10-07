# AUDIT-PX — Player-experience, encounter & level audit (READ-ONLY)
Agent: agy / gemini-3.1-pro-high. Slot: REVIEW (no code edits).

Read `AGENTS.md`, `ops/CONTEXT.md`, then this brief.

## Goal
Evaluate the game as a player and as an encounter/level designer, from the code and scenes. Identify what is genuinely fun already (protect it) and the three changes that would most change how a player perceives this game. Do not propose new content, enemies, weapons or systems; the Director has ruled those out until the existing game feels good.

## Scope
- `scenes/FloodedMall_Greybox.tscn` + `scripts/mall_greybox_builder.gd`: reconstruct the layout (positions of floor, basin, mezzanine, ramps, pillars, kiosks, rails, enemy spawns, boss trigger, checkpoint, candy). Sketch it as ASCII top-down. Judge flow, readability, where a player goes first, how they find the rails, how the boss is gated (`scripts/boss_encounter_trigger.gd`).
- Enemy scripts: `neon_cicada.gd`, `sludge_roach.gd`, `corrupted_kiosk_turret.gd`, `turret_mortar.gd`, `dial_up_queen.gd`. For each: HP, damage, speed, telegraphs, attack cadence, how the player reads it, XP reward. Compute time-to-kill vs. player bat damage (base 15 x STR mult; tests print ~40 at STR 10) and vs. secondary weapons. Compute player time-to-death vs. each enemy and vs. groups as spawned. Is the difficulty curve sane for a first-time player?
- Progression: XP curve (50 base, x1.5), stat point value, tape buffs (`switch_tape` in `src/player_controller.cpp` ~line 1305). Does a 15–30 minute session produce meaningful level-ups and choices?
- Onboarding: what does a new player see and learn in the first 60 seconds (HUD `scripts/hud.gd`, control tips, intro/menu scenes)? What is never taught (skates toggle, grinding requires skates, tape switching, evade)?
- Death/retry loop: `die()` reloads the scene after 2.5s; `save_manager.gd` + `checkpoint.gd`. Is progress actually restored on death? Trace it.
- Audio: `music/` tapes are wired; are there any SFX for hits, kills, jump, grind, evade, pickup? (`play_sfx` in C++, `health_candy_pickup.gd`).
- You MAY run headless tests. Do NOT open the editor or a windowed game.

## Output
Write `ops/reports/AUDIT-PX.md`:
1. ASCII level map with annotated spawn/rail/boss/checkpoint positions.
2. Encounter table (enemy -> HP, dmg, speed, telegraph, TTK by bat, TTK by flame, threat rating, readability rating).
3. First-five-minutes walkthrough as a new player would experience it, with the failure points.
4. "Already fun" list (protect these).
5. Top 3 highest-leverage changes, each with: the player-facing problem, the smallest fix, why it matters, what to measure.
6. A ranked list of 10 further issues (one line each).
Under 350 lines. Evidence as file:line. Do not modify any file other than the report.
