extends SceneTree
## Director smoke test (headless): load the mall, verify spawn safety, XP on kill, boss spawn via trigger.
## Run: Godot --headless --path . -s ops/tools/smoke_mall.gd
var fails := 0
func check(c: bool, msg: String) -> void:
	if c: print("PASS: " + msg)
	else: fails += 1; print("FAIL: " + msg)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var err := change_scene_to_file("res://scenes/FloodedMall_Greybox.tscn")
	check(err == OK, "mall scene loads")
	for i in 30: await process_frame
	var scene := current_scene
	var player := scene.get_node_or_null("Player")
	check(player != null, "player node present")
	check(player.is_in_group("player"), "player is in group 'player'")
	check(int(player.call("get_level")) == 1, "fresh run starts at level 1 (got %d)" % int(player.call("get_level")))
	check(player.call("get_current_health") == player.call("get_max_health"), "fresh run starts at full HP")
	var enemies := get_nodes_in_group("enemies")
	print("enemies spawned: %d" % enemies.size())
	check(enemies.size() >= 5, "enemies spawned")
	var near_roach := 0
	for e in enemies:
		if e.name.begins_with("SludgeRoach") and e.global_position.distance_to(player.global_position) < 10.0:
			near_roach += 1
	check(near_roach == 0, "no roach within 10 m of spawn (got %d)" % near_roach)
	# Stand still 12 s
	await create_timer(12.0).timeout
	check(not player.call("is_dead"), "player alive after 12 s idle at spawn (HP %s)" % str(player.call("get_current_health")))
	# Kill a cicada -> XP 10
	var xp_before := int(player.call("get_current_xp"))
	var cic: Node = null
	for e in get_nodes_in_group("enemies"):
		if e.name.begins_with("NeonDialUpCicada"): cic = e; break
	check(cic != null, "a cicada exists")
	if cic:
		cic.call("take_damage", 999, Vector3.ZERO)
		cic.call("take_damage", 999, Vector3.ZERO)  # second hit must not double-award
		await create_timer(0.3).timeout
		check(int(player.call("get_current_xp")) - xp_before == 10, "cicada kill awards exactly 10 XP (delta %d)" % (int(player.call("get_current_xp")) - xp_before))
	# Boss trigger spawns boss with enemies remaining
	var trig := scene.get_node_or_null("BossEncounterTrigger")
	check(trig != null, "boss trigger exists")
	if trig:
		trig.call("_on_body_entered", player)
		await process_frame
		check(get_nodes_in_group("boss").size() == 1, "boss spawned on trigger with enemies remaining")
	print("RESULT: %s (%d fails)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(0 if fails == 0 else 1)
