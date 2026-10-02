extends SceneTree

func _init():
	print("=== RUNNING Y2K ARPG SYSTEM TESTS ===")

	# 1. Test PlayerController instancing
	var player = ClassDB.instantiate("PlayerController")
	assert(player != null, "PlayerController should instantiate")
	print("[TEST] PlayerController created successfully.")

	# 2. Test initial level, xp, and stat points
	assert(player.get_level() == 1, "Initial level should be 1")
	assert(player.get_current_xp() == 0, "Initial XP should be 0")
	assert(player.get_unspent_stat_points() == 1, "Initial unspent points should be 1")
	print("[TEST] Initial stats verified: Level 1, 0 XP, 1 Stat Point.")

	# 3. Test XP gain and Leveling
	player.gain_xp(35)
	assert(player.get_current_xp() == 35, "XP should be 35 after 1 kill")
	assert(player.get_level() == 1, "Level should still be 1")

	player.gain_xp(35) # 35 + 35 = 70 >= 50 threshold -> Level up!
	assert(player.get_level() == 2, "Level should now be 2")
	assert(player.get_unspent_stat_points() == 2, "Unspent points should now be 2")
	print("[TEST] Level up verified: Level 2 reached with 2 Stat Points!")

	# 4. Test spending stat points
	var old_str = player.get_strength()
	var spent = player.spend_stat_point("strength")
	assert(spent == true, "Spend stat point should return true")
	assert(player.get_strength() == old_str + 1, "Strength should have increased by 1")
	assert(player.get_unspent_stat_points() == 1, "Remaining points should be 1")
	print("[TEST] Stat allocation verified: Base STR increased to ", player.get_strength())

	# 5. Test Movement Lock
	assert(player.get_movement_locked() == false, "Player should not be locked initially")
	player.set_movement_locked(true)
	assert(player.get_movement_locked() == true, "Player movement should be locked")
	player.set_movement_locked(false)
	assert(player.get_movement_locked() == false, "Player movement should be unlocked")
	print("[TEST] Movement locking verified.")

	# 6. Test StrandedSoldierNPC & Dialogue Vibe Skill Check
	var soldier = ClassDB.instantiate("StrandedSoldierNPC")
	assert(soldier != null, "StrandedSoldierNPC should instantiate")

	# Initial vibe: Base Vibe 10, default tape "Bubblegum Pop" (+4) -> Effective Vibe = 14 < 15
	var check_fail = soldier.evaluate_vibe_check(player)
	assert(check_fail == false, "Skill check should fail with 14 Vibe")
	print("[TEST] Vibe check failure verified (14/15).")

	# Switch tape to "Eurodance Radio" (+10 Vibe) -> Effective Vibe = 10 + 10 = 20 >= 15
	player.switch_tape("Eurodance Radio")
	var eff_vibe = player.get_effective_vibe()
	assert(eff_vibe >= 15, "Eurodance Radio should give >= 15 effective vibe")
	var check_success = soldier.evaluate_vibe_check(player)
	assert(check_success == true, "Skill check should pass with Eurodance Radio (Eff Vibe: %d)" % eff_vibe)
	assert(soldier.get_already_persuaded() == true, "Soldier should now be persuaded")
	print("[TEST] Vibe check success with Eurodance Radio verified!")

	print("=== ALL Y2K ARPG SYSTEM TESTS PASSED SUCCESSFULLY! ===")
	quit()
