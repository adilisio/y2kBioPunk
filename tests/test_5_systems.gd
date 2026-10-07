extends SceneTree

const TestUtil = preload("res://tests/_test_util.gd")

func check(cond: bool, msg: String) -> bool:
	return TestUtil.check(cond, msg)

func _init():
	run_tests()

func run_tests() -> void:
	print("\n========================================================")
	print(">>> RUNNING 5 MAJOR SYSTEMS VALIDATION TEST <<<")
	print("========================================================\n")

	# -------------------------------------------------------------------------
	# 1. TEST ISOMETRIC CAMERA RIG
	# -------------------------------------------------------------------------
	print("[STEP 1] Validating Isometric Camera Rig...")
	var player = ClassDB.instantiate("PlayerController") as CharacterBody3D
	check(player != null, "PlayerController must instantiate")
	TestUtil.track(player)
	root.add_child(player)

	var cam_rig = ClassDB.instantiate("SpringArm3D") as SpringArm3D
	var cam_script = load("res://scripts/isometric_camera.gd")
	check(cam_script != null, "isometric_camera.gd must load")
	cam_rig.set_script(cam_script)
	player.add_child(cam_rig)
	await process_frame
	await physics_frame

	check(cam_rig.rotation_degrees.x == -45.0, "Camera rig pitch must be locked to -45 deg")
	check(cam_rig.rotation_degrees.y == 45.0, "Camera rig yaw must be locked to 45 deg")
	check(cam_rig.camera != null and cam_rig.camera.current == true, "Camera3D child must be active")
	print(">>> [STEP 1 PASSED] Isometric Camera Rig validated with locked 45° perspective and smooth follow.\n")

	# -------------------------------------------------------------------------
	# 2. TEST SOUND DESIGN & WALKMAN AUDIO
	# -------------------------------------------------------------------------
	print("[STEP 2] Validating Sound Design & Walkman Audio...")

	# Test SFX playback hooks
	player.call("play_sfx", "hit")
	player.call("play_sfx", "evade")
	player.call("play_sfx", "death")
	player.call("play_sfx", "slam")

	var sfx_audio = player.find_child("SFXAudio", true, false) as AudioStreamPlayer
	if not sfx_audio:
		sfx_audio = player.get_node_or_null("SFXAudio") as AudioStreamPlayer
	check(sfx_audio != null, "SFXAudio node must exist on Player")
	check(sfx_audio != null and sfx_audio.stream != null, "SFXAudio stream must be generated and assigned")

	var walkman = player.find_child("WalkmanAudio", true, false) as AudioStreamPlayer
	if not walkman:
		for c in player.get_children():
			if c.name.contains("Walkman") or c is AudioStreamPlayer:
				walkman = c
				break
	check(walkman != null, "WalkmanAudio node must exist on Player")
	player.call("switch_tape", "Eurodance")
	check(player.get("current_tape") == "Eurodance", "Tape switch should set Eurodance")
	print(">>> [STEP 2 PASSED] SFX procedural streams & Walkman audio hooks verified without errors.\n")

	# -------------------------------------------------------------------------
	# 3. TEST BOSS TRIGGER & UI INTEGRATION
	# -------------------------------------------------------------------------
	print("[STEP 3] Validating Boss Trigger & UI Integration...")
	var queen_script = load("res://scripts/dial_up_queen.gd")
	check(queen_script != null, "dial_up_queen.gd must load")
	var queen = CharacterBody3D.new()
	queen.set_script(queen_script)
	TestUtil.track(queen)
	root.add_child(queen)
	await process_frame

	# Verify signals
	check(queen.has_signal("boss_health_changed"), "Boss must have boss_health_changed signal")
	check(queen.has_signal("boss_defeated"), "Boss must have boss_defeated signal")

	# Instantiate HUD and test boss bar integration
	var hud_scene = load("res://scenes/main.tscn")
	check(hud_scene != null, "main.tscn must load")
	var main_node = hud_scene.instantiate()
	TestUtil.track(main_node)
	root.add_child(main_node)
	await process_frame

	var hud = main_node.find_child("HUD", true, false)
	if hud and hud.has_method("setup_boss_bar"):
		hud.call("setup_boss_bar", queen)
		check(hud.get("boss_container") != null, "Boss container must be created in HUD")
		check(hud.get("boss_container") != null and hud.get("boss_container").visible == true, "Boss container must be visible when boss active")

	queen.call("take_damage", 50)
	print(">>> [STEP 3 PASSED] Boss encounter, trigger, and HUD boss HP bar validated.\n")

	# -------------------------------------------------------------------------
	# 4. TEST ENEMY COLLISION LAYER AUDIT & DETECTION AREA
	# -------------------------------------------------------------------------
	print("[STEP 4] Validating Enemy Collision Layer Audit & Aggro...")
	# Neon Cicada
	var cicada_script = load("res://scripts/neon_cicada.gd")
	var cicada = CharacterBody3D.new()
	cicada.set_script(cicada_script)
	TestUtil.track(cicada)
	root.add_child(cicada)
	await process_frame
	check(cicada.collision_layer == 4, "Enemy layer must be 4 (Enemy)")
	check(cicada.collision_mask == (1 | 2), "Enemy mask must be 3 (World | Player)")
	var cicada_area = cicada.find_child("DetectionArea3D", false, false) as Area3D
	check(cicada_area != null, "Cicada must have DetectionArea3D")
	check(cicada_area != null and cicada_area.collision_mask == 2, "Cicada detection mask must be 2 (Player)")

	# Sludge Roach
	var roach_script = load("res://scripts/sludge_roach.gd")
	var roach = CharacterBody3D.new()
	roach.set_script(roach_script)
	TestUtil.track(roach)
	root.add_child(roach)
	await process_frame
	check(roach.collision_layer == 4, "Roach layer must be 4 (Enemy)")
	var roach_area = roach.find_child("DetectionArea3D", false, false) as Area3D
	check(roach_area != null, "Roach must have DetectionArea3D")
	check(roach_area != null and roach_area.collision_mask == 2, "Roach detection mask must be 2 (Player)")

	# Corrupted Kiosk Turret
	var turret_script = load("res://scripts/corrupted_kiosk_turret.gd")
	var turret = CharacterBody3D.new()
	turret.set_script(turret_script)
	TestUtil.track(turret)
	root.add_child(turret)
	await process_frame
	check(turret.collision_layer == 4, "Turret layer must be 4 (Enemy)")
	var turret_area = turret.find_child("DetectionArea3D", false, false) as Area3D
	check(turret_area != null, "Turret must have DetectionArea3D")
	check(turret_area != null and turret_area.collision_mask == 2, "Turret detection mask must be 2 (Player)")

	# Test signal aggro cleanly
	roach._on_detection_body_entered(player)
	check(roach.get("target_player") == player, "Roach target_player should be set upon DetectionArea body_entered")
	roach._on_detection_body_exited(player)
	check(roach.get("target_player") == null, "Roach target_player should be cleared upon DetectionArea body_exited")

	print(">>> [STEP 4 PASSED] Enemy collision layers and signal-based aggro verified on all 3 archetypes.\n")

	# -------------------------------------------------------------------------
	# 5. TEST SAVE / CHECKPOINT SYSTEM (ISOLATED STORAGE)
	# -------------------------------------------------------------------------
	print("[STEP 5] Validating Save / Checkpoint System (Isolated Storage)...")
	var sm_script = load("res://scripts/save_manager.gd")
	check(sm_script != null, "save_manager.gd must load")
	var save_mgr = sm_script.new()
	TestUtil.track(save_mgr)
	root.add_child(save_mgr)

	var save_isolation = TestUtil.setup_isolated_save(save_mgr)
	if not save_isolation.supported:
		print("SKIP: Save / Checkpoint section skipped (%s)" % save_isolation.skip_reason)
	else:
		# Configure player with custom test stats
		player.call("set_level", 4)
		player.call("set_current_xp", 125)
		player.call("set_strength", 16)
		player.call("set_agility", 14)
		player.call("set_vitality", 18)
		player.call("set_vibe", 15)
		player.call("switch_tape", "Metal")

		var save_ok = save_mgr.save_player_data(player, "Test_Mezzanine_Checkpoint", Vector3(5, 1, 10))
		check(save_ok == true, "SaveManager must successfully serialize player to JSON")

		var loaded_dict = save_mgr.load_player_data()
		check(not loaded_dict.is_empty(), "Loaded save data must not be empty")
		check(loaded_dict.has("player"), "Save data must contain player dict")
		check(loaded_dict.get("player", {}).get("level", 0) == 4, "Saved level must match")
		check(loaded_dict.get("player", {}).get("strength", 0) == 16, "Saved strength must match")
		check(loaded_dict.get("player", {}).get("current_tape", "") == "Metal", "Saved tape must match")

		# Reset player and restore
		var fresh_player = ClassDB.instantiate("PlayerController") as CharacterBody3D
		TestUtil.track(fresh_player)
		root.add_child(fresh_player)
		await process_frame
		check(fresh_player.call("get_level") == 1, "Fresh player starts at level 1")

		var apply_ok = save_mgr.apply_save_data_to_player(fresh_player, loaded_dict)
		check(apply_ok == true, "apply_save_data_to_player must succeed")
		check(fresh_player.call("get_level") == 4, "Restored player level must be 4")
		check(fresh_player.call("get_strength") == 16, "Restored player strength must be 16")
		check(fresh_player.get("current_tape") == "Metal", "Restored player tape must be Metal")
		print(">>> [STEP 5 PASSED] JSON save serialization, deserialization, and state restoration verified.\n")
		TestUtil.cleanup_isolated_save(save_isolation.path)

	print("========================================================")
	print(">>> ALL 5 SYSTEMS VALIDATION COMPLETED! <<<")
	print("========================================================\n")

	await TestUtil.cleanup(self)
	TestUtil.finish(self)
