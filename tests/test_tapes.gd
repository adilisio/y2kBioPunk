extends SceneTree

func _init():
	print("=== RUNNING WALKMAN 8-TAPE EXPANSION TESTS ===")

	var player = ClassDB.instantiate("PlayerController")
	assert(player != null, "PlayerController must instantiate")

	# Base stats: 10 STR, 10 AGI, 10 VIT, 10 VIBE
	print("[TEST] Testing 1: Bubblegum")
	player.switch_tape("Bubblegum")
	assert(player.get_current_tape() == "Bubblegum", "Should match Bubblegum")
	assert(player.get_effective_agility() == 18, "Bubblegum gives +8 AGI")
	assert(player.get_effective_vibe() == 14, "Bubblegum gives +4 VIBE")

	print("[TEST] Testing 2: Bounce")
	player.switch_tape("Bounce")
	assert(player.get_current_tape() == "Bounce", "Should match Bounce")
	assert(player.get_effective_strength() == 18, "Bounce gives +8 STR")

	print("[TEST] Testing 3: Metal")
	player.switch_tape("Metal")
	assert(player.get_current_tape() == "Metal", "Should match Metal")
	assert(player.get_effective_strength() == 15, "Metal gives +5 STR")
	assert(player.get_effective_vitality() == 15, "Metal gives +5 VIT")

	print("[TEST] Testing 4: Eurodance")
	player.switch_tape("Eurodance")
	assert(player.get_current_tape() == "Eurodance", "Should match Eurodance")
	assert(player.get_effective_agility() == 15, "Eurodance gives +5 AGI")
	assert(player.get_effective_vibe() == 20, "Eurodance gives +10 VIBE")

	print("[TEST] Testing 5: Skatr")
	player.switch_tape("Skatr")
	assert(player.get_current_tape() == "Skatr", "Should match Skatr")
	assert(player.get_effective_agility() == 22, "Skatr gives +12 AGI")
	assert(player.get_effective_strength() == 13, "Skatr gives +3 STR")

	print("[TEST] Testing 6: FIGHT")
	player.switch_tape("FIGHT")
	assert(player.get_current_tape() == "FIGHT", "Should match FIGHT")
	assert(player.get_effective_strength() == 20, "FIGHT gives +10 STR")
	assert(player.get_effective_vitality() == 16, "FIGHT gives +6 VIT")

	print("[TEST] Testing 7: Big-Beat")
	player.switch_tape("Big-Beat")
	assert(player.get_current_tape() == "Big-Beat", "Should match Big-Beat")
	assert(player.get_effective_vibe() == 22, "Big-Beat gives +12 VIBE")
	assert(player.get_effective_agility() == 16, "Big-Beat gives +6 AGI")

	print("[TEST] Testing 8: Anthem")
	player.switch_tape("Anthem")
	assert(player.get_current_tape() == "Anthem", "Should match Anthem")
	assert(player.get_effective_vitality() == 18, "Anthem gives +8 VIT")
	assert(player.get_effective_vibe() == 18, "Anthem gives +8 VIBE")

	print("[TEST] Testing 8-track cycling with empty switch_tape()")
	# Cycling from Anthem should wrap back to Bubblegum
	player.switch_tape()
	assert(player.get_current_tape() == "Bubblegum", "Cycle from #8 should wrap back to #1")

	print("=== ALL 8 WALKMAN TAPE TESTS PASSED SUCCESSFULLY! ===")
	quit()
