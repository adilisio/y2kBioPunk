extends SceneTree
const TestUtil = preload("res://tests/_test_util.gd")

## VS1.1 character sheet pause semantics (headless).
## Opening the sheet pauses the tree (player and enemies freeze), closing resumes,
## Esc closes, death / victory force-unpause and hide the sheet, guards refuse to open it.

const MALL := "res://scenes/FloodedMall_Greybox.tscn"

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, msg: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + msg)
	TestUtil.check(ok, msg)

func _frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _load_mall() -> Node3D:
	var mall := load(MALL).instantiate() as Node3D
	root.add_child(mall)
	current_scene = mall
	TestUtil.track(mall)
	await _frames(3)
	return mall

func _nearest_enemy(player: Node3D) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for e in get_nodes_in_group("enemies"):
		if not (e is Node3D):
			continue
		var d := (e as Node3D).global_position.distance_to(player.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func _key_event(action: StringName) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev

func _run() -> void:
	TestUtil.reset()
	var started := Time.get_ticks_msec()
	var sm = root.get_node_or_null("SaveManager")
	if sm:
		sm.respawn_pending = false
		sm.pending_load = false

	# --- Mall A: open, freeze, resume, Esc, death ---
	var mall := await _load_mall()
	var hud = mall.get_node_or_null("HUD")
	var player = mall.get_node_or_null("Player")
	_check(hud != null and player != null, "HUD and Player exist")
	if not (hud and player):
		TestUtil.finish(self)
		return
	var sheet: Control = hud.character_sheet
	var dim: Control = hud.get_node_or_null("HUDOverlay/PauseDim")
	_check(sheet != null and not sheet.visible, "sheet starts hidden")
	_check(dim != null and not dim.visible, "dim overlay exists and starts hidden")
	_check(not paused, "tree starts unpaused")
	_check(hud.process_mode == Node.PROCESS_MODE_ALWAYS, "HUD process_mode is ALWAYS")
	var walkman := player.get_node_or_null("WalkmanAudio") as Node
	_check(walkman != null and walkman.process_mode == Node.PROCESS_MODE_ALWAYS, "WalkmanAudio keeps playing while paused")

	var enemy := _nearest_enemy(player)
	_check(enemy != null, "an enemy exists in the mall")
	if enemy == null:
		TestUtil.finish(self)
		return
	var enemy_start := enemy.global_position

	hud.toggle_character_sheet()
	await _frames(1)
	_check(paused, "opening the sheet pauses the tree")
	_check(sheet.visible, "sheet is visible")
	_check(dim.visible, "dim overlay is visible")
	_check(player.get_movement_locked(), "player movement is locked")
	var title := sheet.find_child("TitleLabel", true, false) as Label
	_check(title != null and title.text.contains("PAUSED"), "header says PAUSED")

	var player_start: Vector3 = player.global_position
	Input.action_press("move_forward")
	await _frames(30)
	Input.action_release("move_forward")
	_check(player.global_position.distance_to(player_start) <= 0.01, "player does not move while paused (%.4f m)" % player.global_position.distance_to(player_start))
	_check(is_instance_valid(enemy) and enemy.global_position.distance_to(enemy_start) <= 0.01, "enemy does not move while paused")

	hud.toggle_character_sheet()
	await _frames(1)
	_check(not paused, "closing the sheet unpauses")
	_check(not sheet.visible and not dim.visible, "sheet and dim hidden after close")
	_check(not player.get_movement_locked(), "movement unlocked after close")

	player_start = player.global_position
	Input.action_press("move_forward")
	await _frames(30)
	Input.action_release("move_forward")
	_check(player.global_position.distance_to(player_start) > 0.5, "player moves after resume (%.2f m)" % player.global_position.distance_to(player_start))

	# Close button also resumes
	hud.toggle_character_sheet()
	await _frames(1)
	hud.sheet_btn_close.emit_signal("pressed")
	await _frames(1)
	_check(not paused and not sheet.visible and not player.get_movement_locked(), "CLOSE button resumes")

	# Esc (ui_cancel) closes through the real input path
	hud.toggle_character_sheet()
	await _frames(1)
	_check(paused and sheet.visible, "reopened for Esc test")
	Input.parse_input_event(_key_event(&"ui_cancel"))
	await _frames(2)
	_check(not paused and not sheet.visible and not dim.visible, "ui_cancel closes the sheet and resumes")
	_check(not player.get_movement_locked(), "movement unlocked after Esc")

	# Esc with the sheet closed does nothing
	Input.parse_input_event(_key_event(&"ui_cancel"))
	await _frames(2)
	_check(not paused and not sheet.visible, "ui_cancel with sheet closed is inert")

	# Pager messages must not tick down while paused
	hud.page_message("[b]PAUSE TEST[/b]")
	var count_before: int = hud.pager_messages.size()
	var time_before: float = hud.pager_messages[count_before - 1].time if count_before > 0 else -1.0
	hud.toggle_character_sheet()
	await _frames(30)
	var time_after: float = hud.pager_messages[count_before - 1].time if hud.pager_messages.size() >= count_before else -2.0
	_check(count_before > 0 and is_equal_approx(time_before, time_after), "pager message timer holds while paused (%.3f -> %.3f)" % [time_before, time_after])
	hud.toggle_character_sheet()
	await _frames(1)

	# Death with the sheet open
	hud.toggle_character_sheet()
	await _frames(1)
	_check(paused, "sheet open before lethal damage")
	player.take_damage(9999)
	await _frames(2)
	_check(player.is_dead(), "player is dead")
	_check(not paused, "tree unpaused after death with sheet open")
	_check(not sheet.visible and not dim.visible, "sheet hidden after death")
	# Guard: cannot open while dead
	hud.toggle_character_sheet()
	await _frames(1)
	_check(not paused and not sheet.visible, "sheet refuses to open while dead")
	if sm:
		sm.respawn_pending = false
	root.remove_child(mall)
	mall.free()
	current_scene = null
	await _frames(2)

	# --- Mall B: victory with the sheet open ---
	mall = await _load_mall()
	hud = mall.get_node("HUD")
	player = mall.get_node("Player")
	sheet = hud.character_sheet
	dim = hud.get_node("HUDOverlay/PauseDim")
	hud.toggle_character_sheet()
	await _frames(1)
	_check(paused and sheet.visible, "sheet open before victory")
	hud.show_victory_card()
	await _frames(1)
	_check(not paused, "tree unpaused by show_victory_card")
	_check(not sheet.visible and not dim.visible, "sheet hidden by show_victory_card")
	hud.toggle_character_sheet()
	await _frames(1)
	_check(not paused and not sheet.visible, "sheet refuses to open over the victory card")

	# --- Safety net: HUD leaving the tree unpauses ---
	paused = true
	mall.remove_child(hud)
	await _frames(1)
	_check(not paused, "HUD _exit_tree unpauses the tree")
	hud.free()
	paused = false

	if sm:
		sm.respawn_pending = false
		sm.pending_load = false
	var elapsed := (Time.get_ticks_msec() - started) / 1000.0
	_check(elapsed < 40.0, "runtime %.2fs < 40s (9-19s observed; two mall loads)" % elapsed)
	var live: Array[Node] = []
	for n in TestUtil.tracked_nodes:
		if is_instance_valid(n):
			live.append(n)
	TestUtil.tracked_nodes = live
	await TestUtil.cleanup(self)
	TestUtil.finish(self)
