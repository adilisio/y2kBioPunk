# AUDIT-PX: Player-Experience & Encounter Report

## 1. ASCII Level Map
```text
  [N]  Z=-25
   +-----------------------------------------------+
   |                      [Boss Spawn]             |
   |                                               |
   |        [Kiosk 1]     [Trigger]    [Kiosk 2]   |
   |          [T]                        [T]       |
   |                                               |
   |     [Mezzanine]     +----------+              |
   |          |          |          |              |
   |          |          |  Basin   |              |
   |          V          | (Roach)  |   [Kiosk 3]  |
[W]|         ===         |          |              |[E]
   |                     +----------+              |
   |                         [CP]                  |
   |                                               |
   |                         [P]                   |
   |                                               |
   |                                               |
   +-----------------------------------------------+
  [S]  Z=25

Legend: 
[P] = Player Spawn (0, 1, 9)
[CP] = Checkpoint (0, 0, 4)
[T] = Turret (x2)
=== = Grind Rail
```

## 2. Encounter Table
| Enemy | HP | Dmg | Speed | Telegraph | Bat TTK | Flame TTK | Threat | Readability |
|-------|----|-----|-------|-----------|---------|-----------|--------|-------------|
| Neon Cicada | 50 | 0* | 2.0/3.8 | Red flash & mesh squash | 1.15s | 0.60s | None | Med |
| Sludge Roach | 30 | 10 | 5.5/8.5 | Flanking wave + leap squash | 0.0s | 0.24s | Med | High |
| Corrupted Turret | 120 | 20 | 0.0 | CRT Screen (Grn->Ylw->Red) | 2.30s | 1.20s | High | High |
| Dial-Up Queen | 600 | 20-28 | 2.5-5.5 | Ring expand, Antenna swell, Phase Colors | 16.1s | 6.48s | Deadly | High |
*\*Neon Cicada does not have any attack or damage logic implemented.*

## 3. First-Five-Minutes Walkthrough & Failure Points
1. **Boot & Menu:** Player clicks "New Game" and is dropped into `scenes/main.tscn` (an empty 100x100 box) instead of the actual level. **(Failure Point: Unreachable game content)**
2. **Spawn & Controls:** Assuming they manually load `FloodedMall_Greybox.tscn`, they spawn at `(0, 1, 9)`. The HUD shows `[C] Character Sheet`, `[T] Tape`, and `[RMB] FLAME`. They try to grind the rail but fail because the `[K]` key to toggle skates is never taught. **(Failure Point: Hidden mechanics)**
3. **First Combat:** They encounter a Neon Cicada and kill it easily (it deals 0 damage). However, the Cicada drops 0 XP. The player proceeds to kill Sludge Roaches and Turrets—also 0 XP. **(Failure Point: Broken progression loop; leveling is impossible)**
4. **Checkpoint:** They hit the BioCheckpoint at `(0, 0, 4)`. Game saves. 
5. **Boss Gating:** They reach the North side to fight the boss. The trigger requires 0 remaining enemies. They hunt down every hidden Cicada.
6. **Death Loop:** They die to the boss. The scene reloads. ALL enemies respawn. The boss trigger resets. The player must kill all 10 enemies *again* to re-summon the boss. **(Failure Point: Excruciating retry loop)**

## 4. "Already Fun" List (Protect These)
- **High-Velocity Movement:** Snappy, instant acceleration with 12m/s skates and momentum-based rail traversal.
- **Grind Dismount Slams:** Visually and mechanically rewarding AoE shockwaves.
- **Walkman Tape System:** Swapping stats and audio tracks on the fly is highly thematic and engaging.
- **Secondary Arsenal:** Spraying the flamethrower to melt swarms feels powerful (91+ DPS).
- **Telegraph Readability:** The use of CRT screen colors (Turret) and expanding rings/colors (Boss) is fantastic.

## 5. Top 3 Highest-Leverage Changes

1. **Fix New Game Button to Load the Mall**
   - **Problem:** `MenuController` loads an empty test floor (`main.tscn`), meaning real players never see the game.
   - **Fix:** Change `MenuController` scene transition to `res://scenes/FloodedMall_Greybox.tscn`.
   - **Why it matters:** The game is literally unplayable without this.
   - **Measure:** Successful transitions from Main Menu to the Mall.

2. **Grant XP on GDScript Enemy Death**
   - **Problem:** `_die()` in `neon_cicada.gd`, `sludge_roach.gd`, and `corrupted_kiosk_turret.gd` calls `queue_free()` without awarding XP.
   - **Fix:** Add `if player: player.gain_xp(amount)` before `queue_free()` in enemy scripts.
   - **Why it matters:** The ARPG stat and leveling system cannot be used if enemies give 0 XP.
   - **Measure:** Player level upon reaching the Boss Trigger.

3. **Remove Enemy-Clear Requirement for Boss Trigger**
   - **Problem:** `boss_encounter_trigger.gd` requires 0 remaining enemies. Because `get_tree()->reload_current_scene()` respawns all enemies on death, players must re-clear the entire mall every time they die to the boss.
   - **Fix:** Remove the `get_remaining_enemies_count() == 0` check, or persist enemy death states in `SaveManager`.
   - **Why it matters:** Forces a tedious 5-minute chore before every boss attempt, causing players to quit.
   - **Measure:** Time from respawn to re-engaging the boss.

## 6. Ranked List of 10 Further Issues
1. **Health Restore Bug:** `apply_save_data_to_player` sets `vitality` but fails to update `current_health`, causing players to respawn with partial HP. (`scripts/save_manager.gd:100`)
2. **Pacifist Cicadas:** `neon_cicada.gd` has no attack capability and poses zero threat. (`scripts/neon_cicada.gd`)
3. **Missing Onboarding:** The HUD lacks tooltips for Skates (`[K]`), Evade (`[Shift]`), and Secondary Swap (`[Q]`). (`scripts/hud.gd:738`)
4. **Checkpoint Placement:** `BioCheckpoint` is inside the Sludge Roach basin; respawning there can lead to immediate swarm aggro. (`scenes/FloodedMall_Greybox.tscn`)
5. **Missing Traversal Audio:** `play_sfx()` lacks sounds for jumping and grinding, making traversal feel floaty. (`src/player_controller.cpp:679`)
6. **Save State Enemy Respawn:** `SaveManager` only saves player data; reloading effectively revives the entire level around the player's saved position. (`scripts/save_manager.gd`)
7. **Phase Transition Exploit:** Boss phase transition force-push can be dodged with Evade invincibility frames. (`scripts/dial_up_queen.gd:301`)
8. **Turret Mortar Ceilings:** The 4.5m Y-velocity of turret mortars may clip into the 4.5m high walls. (`scripts/corrupted_kiosk_turret.gd:213`)
9. **No Kill SFX/VFX:** Enemies silently vanish with `queue_free()` instead of playing death particles/audio.
10. **Dead Code:** `MutatedBugEnemy` C++ class and `main.tscn` exist but clutter the project hierarchy unnecessarily. (`ops/CONTEXT.md`)
