# Gameplay critique: Y2K Bio-Punk vertical slice (main @ b774119)

Reviewer: independent gameplay critic. I changed nothing in the repo.

Evidence:
- Source read in the order requested.
- `ops/tools/balance_table.gd` ran with exit 0 and printed `BALANCE: PASS`.
- `tests/test_slice_e2e.gd` ran with exit 0 and printed `RESULT: PASS (0 fails)` in 22.25 s. Its output had 6 dummy-renderer `mesh_get_surface_count` errors, which WP-7 already recorded.
- Screenshots `ops/runs/shots/vs11/base.0-13.png` and `base.log`.

Out of scope, as instructed: the camera (12 m, FOV 45), walk vs skate speeds, the audio mix, enemy respawn on death, and the roach cap of 2.

Labels used below:
- **Verified**: read in code, or seen in output or screenshots.
- **Derived**: arithmetic on code constants.
- **Estimate**: a judgement that needs a timed playtest.

---

## Headline

The verbs are good and the telegraphs are mostly honest. Combat has almost no tension: every regular enemy dies in 2-3 swings, which is faster than its own wind-up.

The real problems are at the edges of the loop:
- progression can be lost without any warning;
- a death during the victory moment breaks the ending;
- three pager lines teach something false, and several controls are never taught;
- the Queen's phase 3 demands more escape speed than walking gives.

Each of these has a small, cheap fix.

---

## 1. The first five minutes

### What happens (verified positions)

| When | What |
|---|---|
| t = 0 s | The player spawns at (0, 1, 9) (`FloodedMall_Greybox.tscn:2325`). |
| t = 1 s | The pager shows `MOVE: WASD // SWING: LMB` (`tutorial_director.gd:13,187`). |
| First contact | The two cicadas at (±6.5, 2.5) start 9.2 m away. Detection is 8.5 m (`neon_cicada.gd:23`), so contact comes after a few seconds of wandering. This matches the ledger's "~4 s". |

Other layout facts:
- **The only checkpoint** is an unlabeled glowing cyan box behind the player at (3, 0, 12), bottom centre of `base.0.png`. No pager line mentions it.
- **The roach pack** is 17 m north, at z = -7 to -9.
- **A cicada and roach pair** waits on the mezzanine at x ≈ -17.
- **The two turrets** are at z = -13.5.
- **The boss gate** is at z = -19, right behind the turrets.

Estimate: a first-time player reaches the gate in about 2-4 minutes.

### Timing problems

**1. The EVADE hint arrives after the first fight has started.**
- Hints are shown one at a time (`tutorial_director.gd:168-180`).
- MOVE is dismissed only when the player has moved *and* swung, or after 8 s (`:151`, `:12`).
- A player who walks before swinging keeps MOVE on screen, so EVADE (gate: an enemy within 8 m) often appears after the cicadas have engaged.
- Base.4 shows the EVADE hint with five enemies already lined up behind the player.

**2. The tape hint may never fire, and what it says is false.**
- The gate is HP below 60 % (`:136-139`).
- Cicadas deal 6 and roaches 10 (verified), so a competent player may never drop below 60 HP before the Queen. The Walkman is a headline pillar and can go untaught for the whole plaza.
- The text says "VIT tapes heal-scale" (`:19`). That is false:
  - Switching tapes recomputes max HP and only clamps current HP down (`player_controller.cpp:274-277`).
  - No tape heals. Switching away from FIGHT or Metal actually costs any HP above 100.
- The hint appears exactly when the player is hurt, which invites the wrong conclusion.

**3. The turret hint points at a screen that does not change colour.**
- The text says "watch the screen — green→yellow→RED" (`:22`).
- With the GLB model loaded, `screen_mesh` is never created. It only exists in the CSG fallback (`corrupted_kiosk_turret.gd:351`).
- So `_set_screen_color` only recolours a 3.5 m OmniLight (`:284-293`).
- That light sits next to the orange kiosk lights at (±5.5, 3.5, -15) (`mall_greybox_builder.gd:209-210`), so "yellow" barely reads (base.4, base.5).

**4. Three controls are never taught anywhere (verified).**
- **Jump (Space).** The grind hint says "JUMP" but never names the key. The end-of-tutorial legend `WASD · LMB · RMB/F · Q · K · T · SHIFT · C` (`hud.gd:838`) also leaves Space out.
- **Secondary weapons (RMB/F) and Q.** They are not in `HINT_ORDER` (`tutorial_director.gd:15`). Row 2 of the ledger's definition-of-done table claims they are taught; the code does not teach them.
- **The Bio-Stabilizer.** See section 7.

**5. Smaller issues.**
- The player starts with 1 unspent stat point, but "STAT PTS" only appears after the first XP change (`hud.gd:578`). It is missing in base.0-12 and present in base.13.
- A level-up page hides the active hint for 3 s (`hud.gd:829`) while the hint's 8 s timer keeps counting, so a hint can expire unseen.

**Not annoying.** One line at a time, dismissed by doing the thing, then a compact legend. Keep this structure.

## 2. Movement as a kit

Derived from constants (`player_controller.hpp:86-129`, `.cpp:333-339, 652-660`):

| Move | Numbers |
|---|---|
| Walk | 6 + 0.15·AGI = 8.7 m/s on the default Bubblegum tape |
| Skate | fixed 12 m/s |
| Jump | 7.2 m/s; gravity 22 up / 36 down; apex ~1.2 m; ~0.6 s in the air |
| Evade | 0.22 s at 24 m/s ≈ 4.6 m; 0.18 s of i-frames; 0.35 s cooldown |

The evade can be chained every 0.57 s. That is about 8 m/s average travel with 32 % of the time invulnerable. It is generous, but in a game this easy that is fine.

### The level does not reward skating or grinding (derived)
- Spawn to gate is 28 m: 3.2 s walking against 2.3 s skating.
- The two rails are 17.6 m (atrium) and 7.6 m (mezzanine handrail), about 1.5 s and 0.6 s of grind.
- Grind speed is `max(speed, 12)` (`.cpp:2253`), so grinding gives no speed gain.
- Neither rail crosses a gap or reaches anywhere you cannot walk to.
- What a grind gives you: adrenaline at +10/s (at most about +15 per atrium ride), and the slam.

### The slam payoff misses by 1 HP
- The atrium rail's north end at (6.5, 0.75, -8) is 3.2 m from the roach at (3.5, -7). That is inside the 4.5 m slam radius, so the placement is good.
- Slam damage is 35 + 3·STR + 0.25·adrenaline (`.cpp:2570`). At STR 10 that is 65 + at most 4, about 69.
- A full-health cicada has 70 HP, so the slam fails to kill the most common enemy by 1 HP.

Today the grind is a gimmick: a 1.5 s ride ending in an area hit weaker than one bat combo. The layout is a LATER fix; the slam number is a SHOULD.

### Two texts promise speed the game does not give
- The skates hint says "2x speed" (`tutorial_director.gd:20`). The real gain is 12 / 8.7 = +38 % on the default tape.
- The Skatr tape advertises "Max skate velocity" (`.cpp:1403`), but skating ignores AGI completely (`.cpp:337-338`).

## 3. Combat feel from the numbers

### The bat (`.cpp:1211-1305`)
- Damage is 15 + 2.5·STR = 40 at the start.
- Each swing lasts 0.29 s. Damage lands at 0.10 s (0.06 s on the second hit).
- The next swing can be buffered in the last 0.15 s. The third hit does ×1.5.
- Hit-stop is 60 ms (100 ms on the third hit) of real time, at time-scale 0.05.
- Reach is 2.5 m in a 120° cone.
- A 3-hit combo does 140 damage in about 0.87 s plus 0.22 s of hit-stop: roughly 128 DPS in real time (derived).

This is well built. Do not touch it.

### Time to kill (balance table, verified)

| Enemy | HP | Bat time to kill | Swings |
|---|---:|---:|---:|
| Cicada | 70 | 0.39 s | 2 |
| Roach | 45 | 0.39 s | 2 (1 once STR gives 45 damage) |
| Turret | 120 | 0.68 s | 3 |

**Every regular enemy dies faster than its own telegraph finishes.**
- **The cicada is not a threat.** Any hit sends it to idle (`neon_cicada.gd:332`), and idle immediately chases again (`:160`). Hitting it during its 0.5 s wind-up cancels the lunge. It deals 6 damage about every 2 s, roughly 3 DPS.
- **The turret is harmless up close.** Its mortar target is clamped to at least 6 m from the muzzle (`corrupted_kiosk_turret.gd:219`), so a player in bat range cannot be hit. 120 HP is 3 swings.

### Damage taken (derived)
- The worst plaza mix in base.4/5 is 2 cicadas and 3 roaches, with only 2 roaches attacking at once.
- That is about 2×3 + 2×5 = 16 DPS, or about 6 s to die standing still.
- The player kills that whole group in about 3 s of swinging.
- The two candies heal 10 each (`health_candy_pickup.gd:9`), about 10 % of HP, which is negligible.

### The disk launcher outclasses the bat
- Damage is 25 + 2.2·AGI = 64. It flies at 24 m/s for 2.5 s (about 60 m range), on a 0.45 s cooldown (`.cpp:2825-2827`, `disk_projectile.gd:7-9`).
- That is 142 DPS at range, against about 128 DPS for the bat in melee.
- It one-shots roaches, and kills a turret in 2 shots from outside the turret's 16 m detection, at zero risk.
- In a game about a kid with a bat, the free ranged weapon is the best weapon.

**The flamethrower is fine.** It does 108 DPS at 4.2 m, but each 0.12 s tick knocks the target back with force 2.0, out of range. The table's 0.60 s flame time-to-kill ignores that pushback (estimate). It works as a keep-away hose, which fits the ledger's "protect".

**Roach bites skip the knockback contract.** The bite calls `take_damage(bite_damage)` with no direction (`sludge_roach.gd:246`), so the player is not pushed. The cicada, the mortar and the Queen's screech all pass one, as AGENTS.md requires.

**Verdict: trivial, not unfair.** "Easy" is acceptable for a 15-minute showcase. The cicada should hurt, though, and the disk should not out-damage the bat.

## 4. Enemy fairness and telegraph readability

Assumes about 0.25 s of human reaction and walking at 8.7 m/s.

| Enemy | Telegraph | What the player needs | Verdict |
|---|---|---|---|
| Cicada | 0.5 s wind-up at 2.5 m, then a 0.3 s lunge at 5 m/s; hits within 1.6 m | Step 1.6 m sideways (0.18 s) or evade | Fair, generous |
| Roach | 0.35 s wind-up at 3.5 m plus a noise cue, then a pounce at 11 m/s for up to 0.4 s; hits within 1.4 m | Has 0.35 s + ~0.19 s of travel ≈ 0.54 s; needs 0.25 + 0.16 ≈ 0.41 s | Fair, tight |
| Turret | 0.8 s yellow + 0.8 s red, then 0.65-1.5 s of flight with a 2.2 m marker | At least 2.25 s of warning | Very fair |
| Queen screech | Charge 1.4 / 1.1 / 0.9 s; radius 7 / 9 / 11 m | See section 6 | Phase 3 cannot be escaped on foot after reacting |

### Readability problems

**Red means five different things.**
- The wind-up uses the same red overlay as the hit flash: cicada `:236` → `:290` uses `Color(1, 0.12, 0.12)`; roach `:214` → `:296`.
- The same red also marks the mortar landing marker, the Queen's screech disc and outline, and the turret's charging light.
- Base.10 shows two roaches in red wind-up standing inside the Queen's red charge disc, inside her red outline.
- "Red = I am about to hurt you" and "red = I just got hurt" cannot be told apart.

**The roach's vulnerable window is invisible.**
- After a pounce the roach takes ×1.5 damage for 1.2 s (`sludge_roach.gd:256, 282-283`).
- But entering that state clears its tint (`:258`), so nothing shows it. A player cannot learn a weakness they cannot see.

**The turret marker grows; the Queen's does not.**
- The mortar marker starts at 5 % size and grows during the flight (`turret_mortar.gd:125-127`).
- The Queen's outline is full size from the first frame (`dial_up_queen.gd:227`).
- On a 0.65 s flight the turret marker is small for most of its life. This is minor, because the damage radius never changes.

## 5. Pace to the boss

**XP curve** (`.cpp:282-297`): 50 → 75 → 112, each level ×1.5.

**Roster** (balance table, verified): 3 cicadas × 10 + 4 roaches × 15 + 2 turrets × 40 = 170 XP.
- Level 2 comes around the fourth kill.
- Level 3 needs 125 XP, so it needs at least one turret. The turrets are on the way to the gate, so that works.
- 170 XP gives level 3 with 45/112 left over. Skipping the mezzanine (25 XP) still reaches level 3.
- Each level gives one stat point. Two points in STR make the bat do exactly 45 and one-shot roaches. That is a nice breakpoint, but nothing tells the player.

**Dead time and backtracking are small.** The room is 50 × 50 m and every encounter is in view. The only backtrack is the 31 m walk south to the checkpoint to save, and the game never asks for it (section 7).

**The slice is shorter than the docs say.**
- The ledger frames this as a 15-30 minute slice.
- From the numbers I estimate a first clear at **5-8 minutes**: 9 enemies at under 1 s each, about 2-4 minutes of plaza, a 30-45 s boss and a 6 s card.
- Either the docs say "5-10 minutes", or the boss and cicada numbers below have to stretch it. No new content is needed for either.

**The turrets also cover the boss arena.**
- Turret detection is 16 m. The turret at (-6, -13.5) is 10 m from the Queen's spawn at (0, -21.5) (`FloodedMall_Greybox.tscn:3584`).
- After a death the roster respawns. That is the owner's ruling and I am not contesting it.
- So a player who runs past the turrets fights the Queen under two 20-damage mortars. This is the main way the climax becomes unfair.

## 6. The Queen

### Phase 3 cannot be escaped by walking (derived)
- The player's bat reach on the Queen is 4.8 m (`.cpp:1277`).
- From the edge of melee, the player must cover 2.2 / 4.2 / 6.2 m before detonation in phases 1 / 2 / 3.
- After 0.25 s of reaction, that needs 1.9 / 4.9 / **9.5 m/s**.
- Walking gives 8.7 m/s on Bubblegum and 7.5 m/s on FIGHT. Skating gives 12 m/s, but only after it accelerates.
- Whenever the player is within 6.5 m, the Queen's idle state always picks the screech (`dial_up_queen.gd:156-157`).
- So every phase-3 melee approach forces an evade or 28 damage:
  - An evade plus a short walk takes 0.22 + 1.6/8.7 + 0.25 ≈ 0.65 s, so escape is possible.
  - Dodging through with i-frames needs the evade pressed in the last 0.18 s. The only cue for that is a 0.1 s white flash (`:262-267`), which is shorter than human reaction time.
- **Result:** a player who has not learned the evade takes 28 damage per cycle. At 100 HP that is 4 cycles, about what the bat needs to remove phase 3's 495 HP. Expect coin-flip deaths here.

### The summon has no warning
- With the GLB model loaded, `antenna_array` is null; it is only built in the CSG fallback (`:479`).
- So the 1.5 s summon (`:302-314`) plays no animation and no sound.
- Roaches spawn 3.5 m from the Queen (`:330`), which is inside the player's melee position, and wind up at once (0.35 s).

### Invulnerable phase changes still feel like hits
- During the 1.8 s invulnerability, the Queen silently ignores hits (`:394-396`).
- But the player's swing applies the hit sound, hit-stop and shake before it knows whether damage landed (`.cpp:1278-1293`).

### Fight length (estimate)
- **Bat only:** about 7 s in phase 1 (only **two screech cycles** before the phase changes), about 12 s in phase 2, about 19 s in phase 3, plus 3.6 s of transitions. Roughly **40-45 s** in total.
- **Disk kiting:** standing 12 m or more away while she walks in at 2.5-5.5 m/s, about **20-25 s** at very low risk.
- That is short for the climax. Phase 1 ends before the player has learned the screech.

### Protect
- The outline drawn at full radius from the first frame of every charge, and damage radii that match it.
- The phase colour tint.
- Damage stepping 20 → 28.

**Framing note.** In base.8-12 the Queen is cut off at the bottom-left of the frame. That comes from where the shot harness placed the player, so it is not evidence about the camera. I am not raising the camera.

## 7. Victory, death and respawn, Continue

### Progress can be lost without warning (verified code path)
- New Game clears the save.
- The spawn point (0, 1, 9) is outside the checkpoint's trigger box, which covers x 1.75-4.25 and z 10.75-13.25 (`checkpoint.gd:40-44`).
- The checkpoint saves only when touched. Its only feedback is a one-time colour change from cyan to green; after that, saves show nothing (`:63-67`). The console print is invisible to players.
- On death, the HUD restores progress only `if has_save_data()` (`hud.gd:327-332`).
- So a player who never touches the unlabeled box and then dies to the Queen comes back at **level 1, 0 XP, with the whole roster respawned**.
- The e2e test teleports the player into the checkpoint (`test_slice_e2e.gd:87`), so it never sees this.

### Dying heals; the checkpoint does not
- Respawn restores full HP. Touching the checkpoint does not heal.
- A player who reaches the Queen with 30 HP is better off dying on purpose.

### A death can break the victory (verified code path; not reproduced in a run)
- When the Queen dies, the HUD locks the player's movement (`hud.gd:189`) and waits 6 s before going to the menu (`:192`).
- Only the minions the Queen summoned are removed (`dial_up_queen.gd:426-429`).
- The player can still take damage: `take_damage` ignores the movement lock (`.cpp:1763`). Base.13 shows two roaches in red wind-up next to the victory card.
- If the player dies in those 6 s, the 2.5 s death reload frees the HUD and the timer that goes to the menu. The player respawns in the mall instead, after `slice_complete` was already saved.

### The victory payoff is thin
- The card is three lines: "SIGNAL RESTORED…", "LEVEL: 4", "STATUS: SURVIVED" (`hud.gd:613`). It shows no time, kills or deaths, and needs no input.
- It appears at the same instant the Queen's 1.2 s death animation starts, so the card covers it.
- The Queen's 250 XP fires three level-up pages and beeps over the card (base.13).
- Those points cannot be spent, and they are not saved: `mark_slice_complete` keeps the old checkpoint data (`save_manager.gd:30-41`).

### Continue after victory loads a stale run
- It loads the last checkpoint touch, often level 1 at spawn, into a full mall with the Queen ready to spawn again.
- `slice_complete` is written but never read. A grep finds it only at `hud.gd:186-187` and in `save_manager.gd`.

## 8. Things that make a new player say "prototype"

1. Progress is lost with no warning (section 7).
2. One pager line describes a turret screen that does not change colour; another says tapes heal, which they do not.
3. Jump and the secondary weapons are never taught. The action-bar key labels are 10 pt (`FloodedMall_Greybox.tscn:2923,2938,2953`) and not legible in any base.* shot.
4. The ending is text only and advances on its own, with three level-up beeps over it and live enemies around a frozen player.
5. Red does five jobs at once (base.10).
6. Enemies die faster than they telegraph, so fights read as "click near bugs".
7. The checkpoint is an unlabeled cyan cube (base.0, bottom centre).
8. `base.log` shows `ERROR: Function blocked during in/out signal` when the boss spawns. The Queen is added to the scene inside a `body_entered` callback (`boss_encounter_trigger.gd:112,137`).

---

## Prioritized fixes (polish only, no new content or systems)

### MUST fix before showing people

**1. No silent progress loss.**
- In `boss_encounter_trigger.gd::_on_body_entered`, call `SaveManager.save_player_data` with the checkpoint's position. Entering the arena then saves level, XP and stats, with respawn still at the Bio-Stabilizer.
- In `checkpoint.gd`, page "BIO-STABILIZER // PROGRESS SAVED" on every save and heal to full.

**2. Make victory safe.**
- When the Queen dies, make the player invulnerable (or ignore damage while `victory_shown`).
- Remove every node in the `enemies` group, not only the summoned ones.
- Delay `show_victory_card` by about 1.2 s so the Queen's death animation can be seen.

**3. Make the pager truthful and complete.**
- **Tape hint:** change to "TAPE: T cycles mixtapes — each changes STR/AGI/VIT/VIBE". Gate it on 2 kills or 40 s instead of HP below 60 %.
- **Turret hint:** change to "TURRET: its glow turns yellow then RED — a mortar is coming; watch for the red ring". Alternatively, tint the turret model with the state colour through `EnemyModel.tint`, as the cicada and roach already do, so the current text becomes true.
- **Jump:** the grind hint should say "JUMP (SPACE)". Add SPACE to the legend at `hud.gd:838`.
- **Secondary weapons:** add one hint to the existing director, "SECONDARY: RMB/F fire, Q swaps flame/disk", shown after the first kill.

### SHOULD fix if cheap (one number or one line each)

4. **Phase-3 screech.** Pick one:
   - charge 0.9 → 1.15 s (needed speed drops to about 6.9 m/s, which is walkable), or
   - white flash 0.1 → 0.3 s, so the i-frame dodge can be done on reaction.
5. **Summon warning.** In `_enter_minion_summon`, pulse a tint on the Queen and play a dial-up sound for the 1.5 s; the antenna animation does nothing with the GLB model. Spawn minions on the side away from the player, at least 5 m from them.
6. **Separate wind-up colour from the hit flash.**
   - Use white or yellow for the wind-up (`neon_cicada.gd:236-237`, `sludge_roach.gd:214`); keep red for hits and danger zones.
   - Give the roach's 1.2 s vulnerable window a visible tint.
7. **Disk launcher.** Cooldown 0.45 → 0.8 s (about 80 DPS), so the bat stays the main damage source and the disk is the ranged option.
8. **Slam.** `base_slam_damage` 35 → 40, so a level-1 slam kills a cicada.
9. **Turret positions.** Move them south (for example z -13.5 → -9) so their 16 m range no longer covers the Queen's spawn. Or make them idle while a node in group `boss` exists.
10. **Roach bite.** Pass `pounce_direction` as the knockback (`sludge_roach.gd:246`).
11. **Boss XP and Continue.**
    - Drop the Queen's 250 XP, or suppress level-up pages once `victory_shown` is set.
    - Make Continue after completion sensible: save the current player at victory, or hide Continue when `slice_complete` is set.
12. **Onboarding order and HUD.**
    - Dismiss MOVE on movement alone.
    - Let EVADE replace a less urgent hint when an enemy is within 8 m.
    - Show STAT PTS from the first frame.
    - Correct "2x speed" for skates (actual +38 % on the default tape) and the Skatr "Max skate velocity" text.
13. **Cicada contact damage** 6 → 10, so the first enemy teaches something.

### LATER

- **Boss length.** After fix 7, time real fights. If a bat-only clear stays under about 60 s, raise HP to about 2200. Weight phase 1 so it lasts at least 3-4 screech cycles; today it ends after about 2.
- **Victory card.** Add time, kills and deaths, and replace the 6 s auto-return with "press any key".
- **Rails.** Extend or move the two existing rails so a grind links two areas or deliberately lands on an encounter. This is layout work, not a new system.
- **Invulnerable Queen feedback.** Play a deflect sound and skip hit-stop while she cannot be damaged.
- **Action-bar labels.** Raise from 10 pt to at least 14 pt.
- **Boss spawn error.** Spawn the Queen with `call_deferred` to clear the log error.
- **Docs.** State the slice length honestly (about 5-10 minutes).

### What I would NOT change

- The owner's five rulings: camera 12 m / FOV 45, walk vs skate, the audio mix, enemy respawn, roach cap 2.
- Cicada, roach and turret telegraph times (0.5 / 0.35 / 1.6 s plus flight) and their hit radii. They are fair and readable once the colour clash is fixed.
- Melee timing:
  - 0.29 s swings and the 0.15 s buffer;
  - damage at 0.10 / 0.06 s;
  - 60 / 100 ms hit-stop;
  - the ×1.5 third hit;
  - the 4.8 m reach on the boss.
- Evade numbers, 0.6 s hurt invulnerability, and the 7 m/s knockback when the player is hurt.
- The XP curve and the 170 XP roster. Level 3 before the arena works, and the 2-point STR roach breakpoint is a happy accident.
- The Queen's full-size outline, her honest radii, the phase tint and the 20 → 28 damage step.
- The flamethrower as it is (the ledger says "protect"), the pager as the game's voice, and its one-hint-at-a-time structure.
