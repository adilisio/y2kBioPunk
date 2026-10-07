extends SceneTree

func _init() -> void:
	print("--- Running test_critical_path.gd ---")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var root = self.root
	var save_mgr = root.get_node_or_null("SaveManager")
	if not save_mgr:
		save_mgr = load("res://scripts/save_manager.gd").new()
		save_mgr.name = "SaveManager"
		root.add_child(save_mgr)
	
	# (a) SaveManager.clear_save() removes the file
	save_mgr.save_game(Vector3.ZERO, "res://scenes/FloodedMall_Greybox.tscn")
	if not FileAccess.file_exists(save_mgr.SAVE_PATH):
		print("Fail: Save file not created")
		quit(1)
		return
	save_mgr.clear_save()
	if FileAccess.file_exists(save_mgr.SAVE_PATH):
		print("Fail: clear_save did not remove file")
		quit(1)
		return
		
	# (b) saving at level 3 and loading yields xp_to_level == 112 and current_health == max_health
	save_mgr.level = 3
	save_mgr.current_health = 10
	save_mgr.max_health = 100
	save_mgr.current_xp = 0
	save_mgr.save_game(Vector3.ZERO, "res://scenes/FloodedMall_Greybox.tscn")
	save_mgr.level = 1
	save_mgr.load_game()
	if save_mgr.xp_to_level != 112 or save_mgr.current_health != save_mgr.max_health:
		print("Fail: loading level 3 did not yield xp_to_level 112 and full health. Got XP: %s, HP: %s" % [save_mgr.xp_to_level, save_mgr.current_health])
		quit(1)
		return
	save_mgr.clear_save()

	# (c) instancing the mall scene with no save leaves the player at level 1 with full HP
	var mall_scene = load("res://scenes/FloodedMall_Greybox.tscn")
	var mall = mall_scene.instantiate()
	root.add_child(mall)
	
	var player = self.get_first_node_in_group("player")
	if not player:
		player = mall.find_child("Player", true, false)
	
	if not player:
		print("Fail: player not found in mall scene")
		quit(1)
		return
	
	if player.get("level") != 1 or player.get("current_health") != player.get("max_health"):
		print("Fail: player not at level 1 with full HP. Level: %s, HP: %s/%s" % [player.get("level"), player.get("current_health"), player.get("max_health")])
		quit(1)
		return
		
	# (d) killing a roach via take_damage(999, Vector3.ZERO) awards 15 XP to the player node
	var script = load("res://scripts/sludge_roach.gd")
	var roach = script.new()
	mall.add_child(roach)

	var initial_xp = player.get("current_xp")
	roach.take_damage(999, Vector3.ZERO)
	if player.get("current_xp") != initial_xp + 15:
		print("Fail: killing roach did not award exactly 15 XP. initial: %s, final: %s" % [initial_xp, player.get("current_xp")])
		quit(1)
		return

	# (e) BossEncounterTrigger._spawn_boss() spawns a node in group 'boss' even when enemies remain
	var trigger = null
	for node in mall.find_children("*", "Area3D", true, false):
		if node.name == "BossEncounterTrigger" or node.has_method("_spawn_boss"):
			trigger = node
			break
			
	if not trigger:
		print("Fail: BossEncounterTrigger not found")
		quit(1)
		return
		
	var fake_enemy = Node3D.new()
	fake_enemy.add_to_group("enemies")
	mall.add_child(fake_enemy)
	
	trigger._spawn_boss()
	var bosses = self.get_nodes_in_group("boss")
	if bosses.size() == 0:
		print("Fail: Boss not spawned")
		quit(1)
		return

	# (f) a slam-sized knockback vector of length 12 yields receiver velocity <= 1.6 * impulse
	var test_roach = script.new()
	mall.add_child(test_roach)
	test_roach.take_damage(1, Vector3(12, 0, 0))
	var speed = Vector3(test_roach.velocity.x, 0, test_roach.velocity.z).length()
	# The roach impulse is 7.5, so 7.5 * 1.6 = 12.0
	if speed > 12.1:
		print("Fail: Knockback vector length too high: %s (expected <= ~12.0)" % speed)
		quit(1)
		return
	
	print("All tests passed.")
	quit(0)
