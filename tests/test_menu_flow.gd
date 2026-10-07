extends SceneTree
## The literal first action: Main Menu -> New Game must load the mall; Continue must be hidden
## without a save and visible with one. Exits 1 on failure.
var fails := 0
func check(c: bool, msg: String) -> void:
	if c:
		print("PASS: " + msg)
	else:
		fails += 1
		print("FAIL: " + msg)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var sm = root.get_node_or_null("SaveManager")
	if not sm:
		sm = load("res://scripts/save_manager.gd").new()
		sm.name = "SaveManager"
		root.add_child(sm)
	var backup := ""
	if FileAccess.file_exists(sm.SAVE_PATH):
		backup = FileAccess.get_file_as_string(sm.SAVE_PATH)
	sm.clear_save()

	# No save: Continue hidden
	check(change_scene_to_file("res://scenes/main_menu.tscn") == OK, "main menu loads")
	for i in 5:
		await process_frame
	var btn_new = current_scene.find_child("NewGameButton", true, false)
	var btn_cont = current_scene.find_child("LoadGameButton", true, false)
	check(btn_new != null, "NewGameButton exists")
	check(btn_cont != null and not btn_cont.visible, "Continue hidden without a save")

	# New Game -> mall
	if btn_new:
		btn_new.emit_signal("pressed")
	for i in 15:
		await process_frame
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/FloodedMall_Greybox.tscn", "New Game loads the mall (got %s)" % (current_scene.scene_file_path if current_scene else "null"))
	var player = current_scene.get_node_or_null("Player") if current_scene else null
	check(player != null and int(player.call("get_level")) == 1, "fresh player at level 1 in the mall")

	# A checkpoint save exists -> Continue visible
	if player:
		sm.save_player_data(player, "TestCP", Vector3(3, 0, 12))
	check(change_scene_to_file("res://scenes/main_menu.tscn") == OK, "back to menu")
	for i in 5:
		await process_frame
	btn_cont = current_scene.find_child("LoadGameButton", true, false)
	check(btn_cont != null and btn_cont.visible and btn_cont.text == "CONTINUE", "Continue visible and labelled with a save")

	sm.clear_save()
	if backup != "":
		var f = FileAccess.open(sm.SAVE_PATH, FileAccess.WRITE)
		if f:
			f.store_string(backup)
			f.close()
	print("RESULT: %s (%d fails)" % ["PASS" if fails == 0 else "FAIL", fails])
	await process_frame
	quit(0 if fails == 0 else 1)
