extends SceneTree
## Critical-path regression test (headless). Exits 1 on any failure.
## Covers: save clear/roundtrip, fresh-run defaults, XP on kill (exactly once), spawn safety,
## boss spawn on trigger with enemies remaining, knockback clamp, victory wiring.
## Run: Godot_v4.3-stable_win64.exe --headless --path . -s tests/test_critical_path.gd

const TEST_SAVE := "user://test_critical_path_save.json"
var fails := 0

func check(c: bool, msg: String) -> void:
	if c:
		print("PASS: " + msg)
	else:
		fails += 1
		print("FAIL: " + msg)

func _init() -> void:
	print("=== test_critical_path ===")
	call_deferred("_run")

func _run() -> void:
	var sm = root.get_node_or_null("SaveManager")
	if not sm:
		sm = load("res://scripts/save_manager.gd").new()
		sm.name = "SaveManager"
		root.add_child(sm)
	# SAVE_PATH is a const on SaveManager, so back up and restore the production file around the test.
	var using_prod_path := true
	var prod_backup := ""
	if using_prod_path and FileAccess.file_exists(sm.SAVE_PATH):
		prod_backup = FileAccess.get_file_as_string(sm.SAVE_PATH)

	# (a) + (b): save at level 3, load, expect xp_to_level 112 and full HP
	var p = ClassDB.instantiate("PlayerController")
	root.add_child(p)
	await process_frame
	p.set_level(3)
	p.set_xp_to_level(50) # deliberately inconsistent; load must repair it
	p.set_current_health(10.0)
	check(sm.save_player_data(p, "TestCP", Vector3(3, 0, 12)), "save_player_data succeeds")
	check(sm.has_save_data(), "save file exists after save")
	var p2 = ClassDB.instantiate("PlayerController")
	root.add_child(p2)
	await process_frame
	check(sm.apply_save_data_to_player(p2), "apply_save_data_to_player succeeds")
	check(int(p2.get_level()) == 3, "level restored to 3 (got %d)" % int(p2.get_level()))
	check(int(p2.get_xp_to_level()) == 112, "xp_to_level repaired to 112 (got %d)" % int(p2.get_xp_to_level()))
	check(is_equal_approx(p2.get_current_health(), p2.get_max_health()), "HP restored to max on load")
	sm.clear_save()
	check(not sm.has_save_data(), "clear_save removes the file")
	p.queue_free(); p2.queue_free()
	await process_frame

	# (c)-(e): the mall as a fresh run
	check(change_scene_to_file("res://scenes/FloodedMall_Greybox.tscn") == OK, "mall scene loads")
	for i in 30:
		await process_frame
	var scene := current_scene
	var player := scene.get_node_or_null("Player")
	check(player != null, "player node present")
	if player == null:
		return _finish(sm, using_prod_path, prod_backup)
	check(player.is_in_group("player"), "player is in group 'player'")
	check(int(player.call("get_level")) == 1, "fresh run starts at level 1")
	check(is_equal_approx(player.call("get_current_health"), player.call("get_max_health")), "fresh run starts at full HP")
	var near_roach := 0
	for e in get_nodes_in_group("enemies"):
		if e.name.begins_with("SludgeRoach") and e.global_position.distance_to(player.global_position) < 10.0:
			near_roach += 1
	check(near_roach == 0, "no roach within 10 m of spawn (got %d)" % near_roach)
	# (d) XP exactly once
	var xp_before := int(player.call("get_current_xp"))
	var roach: Node = null
	for e in get_nodes_in_group("enemies"):
		if e.name.begins_with("SludgeRoach"):
			roach = e
			break
	check(roach != null, "a roach exists")
	if roach:
		# (f) knockback clamp: a slam-sized vector (length 12) must yield <= 1.6 x impulse (10)
		roach.call("take_damage", 1, Vector3(0, 0, 12))
		var kb: Vector3 = roach.get("knockback_velocity")
		check(kb.length() <= 16.01, "knockback clamped to <= 1.6 x impulse (got %.1f)" % kb.length())
		roach.call("take_damage", 999, Vector3.ZERO)
		roach.call("take_damage", 999, Vector3.ZERO)
		await create_timer(0.3).timeout
		var delta := int(player.call("get_current_xp")) - xp_before
		check(delta == 15, "roach kill awards exactly 15 XP (delta %d)" % delta)
	# (e) boss spawns on trigger with enemies remaining
	var trig := scene.get_node_or_null("BossEncounterTrigger")
	check(trig != null, "boss trigger exists")
	if trig:
		trig.call("_on_body_entered", player)
		await process_frame
		check(get_nodes_in_group("boss").size() == 1, "boss spawned with enemies remaining")
	# Victory wiring: HUD must react to boss_defeated by showing the victory card
	var hud := scene.get_node_or_null("HUD")
	check(hud != null and hud.has_method("show_victory_card"), "HUD has show_victory_card")
	_finish(sm, using_prod_path, prod_backup)

func _finish(sm, using_prod_path: bool, prod_backup: String) -> void:
	sm.clear_save()
	if using_prod_path and prod_backup != "":
		var f = FileAccess.open(sm.SAVE_PATH, FileAccess.WRITE)
		if f:
			f.store_string(prod_backup)
			f.close()
	print("RESULT: %s (%d fails)" % ["PASS" if fails == 0 else "FAIL", fails])
	await process_frame
	quit(0 if fails == 0 else 1)
