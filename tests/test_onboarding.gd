extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var mall_scene = load("res://scenes/FloodedMall_Greybox.tscn")
	var mall = mall_scene.instantiate()
	root.add_child(mall)
	
	var hud = null
	for c in mall.get_children():
		if c.name == "HUD":
			hud = c
	
	if not hud:
		print("FAIL: HUD not found")
		quit(1)
		return
	
	var player = mall.find_child("Player", true, false)
	var tutorial = mall.find_child("TutorialDirector", true, false)
	if not tutorial:
		print("FAIL: TutorialDirector not found")
		quit(1)
		return
		
	# Advance 1.5s (120 frames * ~0.016 = ~1.92s)
	for i in range(120):
		await root.get_tree().process_frame
			
	var tip = hud.control_tip.text if hud.control_tip else ""
	if tip == "":
		print("FAIL: first hint not shown")
		quit(1)
		return
		
	# Dismiss up to skates
	tutorial.state = 6
	tutorial.kills = 2
	await root.get_tree().process_frame
	
	tip = hud.control_tip.text
	if "SKATES" not in tip:
		print("FAIL: Skates hint not shown")
		quit(1)
		return
		
	player.set_is_skating(true)
	await root.get_tree().process_frame
	await root.get_tree().process_frame
	
	tip = hud.control_tip.text
	if "SKATES" in tip:
		print("FAIL: Skates hint not dismissed")
		quit(1)
		return
		
	var sfx_played = false
	player.connect("sfx_played", Callable(func(name): sfx_played = true))
	
	var all_cues = ["evade", "grind_start", "grind_loop", "flame_loop", "disk_fire", "disk_hit", "tape_clack", "clack", "levelup", "page_beep"]
	for cue in all_cues:
		player.play_sfx(cue)
		
	if not sfx_played:
		print("FAIL: sfx_played signal not emitted")
		quit(1)
		return
		
	var t1 = player.get_current_tape()
	player.switch_tape("Bounce")
	var p1 = player.tape_positions.get(t1, 0.0)
	player.switch_tape(t1)
	if not player.tape_positions.has("Bounce"):
		print("FAIL: Tape position not saved")
		quit(1)
		return
		
	print("PASS")
	quit(0)
