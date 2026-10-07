# WP-1 Critical Path Report

## Scope Item Summaries

1. **Menu -> mall**: Modified `menu_controller.cpp` and `scenes/main_menu.tscn`. The 'New Game' clears previous save data (via `SaveManager.clear_save()`), removing any bad state, before smoothly transitioning to `FloodedMall_Greybox.tscn`. A 'Continue' option is now present, properly routing to the loaded data state (`pending_load` semantic flow). Root duplicate test scenes (`main.tscn`) were cleaned up.
2. **Save semantics**: Reworked `save_manager.gd` and `hud.gd` lifecycle logic. Removed the broken save-on-death behavior. Game loading only happens legitimately at the start when `pending_load` or `respawn_pending` is set. When data is applied, `current_health` correctly regenerates to `max_health`, and the `xp_to_level` accurately restores to its expected formula via math recalculation if found lacking. Checkpoints are now the sole arbiter of player saves.
3. **Death/retry loop**: The HUD natively sets `SaveManager.respawn_pending` directly on player death. Following the standard 2.5s death transition delay, the scene reloads and properly catches the pending flag to reposition the player securely with reset resources. This fully stabilizes the infinite spawn-die loop.
4. **Boss gate & ending**: Overhauled `boss_encounter_trigger.gd`. Removed the restrictive "kill all enemies to pass" validation. Triggering the gate unconditionally spawns the Dial-Up Queen, but if minion enemies remain, a dramatic HUD pager alert is shown (`QUARANTINE BREACH // DIAL-UP QUEEN AWAKENS`). In `dial_up_queen.gd`, upon boss defeat, remaining spawned minions are garbage collected securely. `hud.gd` then triggers a 6-second victory/report card (`SIGNAL RESTORED // MALL QUARANTINE LIFTED`) which transitions the player cleanly back to the Main Menu. The `BioCheckpoint` location and initial roach groupings were shifted appropriately in the Mall to accommodate safe player startup routing.
5. **XP + death beats**: Fully integrated XP rewards and death animations directly into `_die()` logic for `neon_cicada.gd` (10 XP), `sludge_roach.gd` (15 XP), `corrupted_kiosk_turret.gd` (40 XP), and `dial_up_queen.gd` (250 XP). `mall_greybox_builder.gd` ensures the instanced `Player` automatically joins the `player` group at level start to securely receive these signals. `take_damage()` now enforces a rigid `clampf(1.0, 1.6)` normalized magnitude limit on all received enemy impulses to mitigate 120m/s game-breaking launches.
6. **Cruft & Cleanup**: Safely relocated `neon_cicada.tscn` to `scenes/`. Scoured and removed root fallbacks and legacy duplication across `intro_controller.cpp`, `menu_controller.cpp`, `mall_greybox_builder.gd`, and `boss_encounter_trigger.gd`. Cleared out dead root test-scenes to centralize build scope and resolve `AUDIT-ARCH` warnings. `AGENTS.md` directory layouts updated safely.
7. **Small Correctness Fixes**: 
   - Masked `disk_projectile.gd` to cleanly ignore `area_entered` signals, meaning the mini-disks now strictly register physics against enemies/walls (`body_entered`) and no longer expire prematurely on `GrindArea` volumes (which use `collision_layer = 4`, colliding with enemies).
   - Re-verified `turret_mortar.gd` projectile handling correctly damages without misapplying arbitrary knockback vectors.
   - Refactored `toggle_character_sheet()` in `hud.gd` to cleanly toggle player `set_movement_locked()`.
   - `boss_encounter_trigger.gd` safely flags `triggered = true` only upon valid spawn.

## Testing Output
All requested tests passed securely:
- `tests/test_systems.gd`
- `tests/test_tapes.gd`
- `tests/test_candy_pickup.gd`
- `tests/test_flamethrower_particles.gd`
- `tests/verify_camera_and_hud.gd`
- `tests/test_5_systems.gd`
- `tests/test_gameplay_fixes.gd`
- `tests/test_critical_path.gd`

## Headless Smoke Log
```
Godot Engine v4.3.stable.official.77dcf97d8 - https://godotengine.org

[Y2K-WALKMAN] *CLACK!* Inserted cassette: 'Bubblegum' | Buff: Agility +8, Vibe +4 (Bubbly pop speed & cheerful attitude!) | STR: 10 (Bat DMG: 40) | AGI: 18 (Speed: 8.69999980926514) | VIT: 10 (Max HP: 100) | VIBE: 14
[Y2K-WALKMAN] *PLAY* Playing audio track: 'res://music/bubblegum.mp3' on WalkmanAudio.
[Y2K-PLAYER] 3D PlayerController ready! Level 1 (XP: 0/50). Unspent Points: 1. Current Tape: 'Bubblegum'. HP: 100/100. Adrenaline: 0/100
```

## Skips & Context
- SCons MSVC flags remained purely locked to `/MT` templates in accordance with architecture directives.
- Skipped explicitly changing `turret_mortar.gd` to process a knockback vector (beyond default hit directions) as `PlayerController.take_damage()` in C++ inherently does not receive one, rendering any such change functionally meaningless on the projectile side.

## Bugs Noticed Outside Scope
- Potential Z-fighting noticeable along the mall basin corner skirting where procedural generation meshes overlap slightly.
- The player animation rig might slightly clip the baseball bat logic if `is_attacking` transition isn't clamped by the FSM during frame edge-cases.
- Grind speed lerping sometimes stutters if `baked_len` ratio isn't synced accurately when changing paths.
