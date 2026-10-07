extends SceneTree
## Real mall integration, bounded wall-clock polling, production save restored on exit.
const MALL := "res://scenes/FloodedMall_Greybox.tscn"
var fails := 0
var sm: Node
var backup := PackedByteArray()
var had_save := false
var finishing := false
var started := 0
var ended := 0
var slams := 0
var defeated := 0
var phases: Array[int] = []

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> bool:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		fails += 1
	return ok

func frames(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame

func poll(predicate: Callable, seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await frames(1)
	return predicate.call()

func total_xp(player: Node) -> int:
	var total := int(player.get_current_xp())
	var threshold := 50
	for level in range(1, player.get_level()):
		total += threshold
		threshold = int(threshold * 1.5)
	return total

func run() -> void:
	started = Time.get_ticks_msec()
	print("=== test_slice_e2e ===")
	sm = root.get_node("SaveManager")
	had_save = FileAccess.file_exists(sm.SAVE_PATH)
	if had_save:
		backup = FileAccess.get_file_as_bytes(sm.SAVE_PATH)
	create_timer(55.0, true, false, true).timeout.connect(func():
		check(false, "55s watchdog expired")
		finish()
	)
	sm.clear_save()
	sm.pending_load = false
	sm.respawn_pending = false
	if not check(change_scene_to_file(MALL) == OK, "a: load real mall"):
		await finish()
		return
	await frames(3)
	var mall := current_scene
	var p = mall.get_node("Player")
	check(p.get_level() == 1 and is_equal_approx(p.get_current_health(), p.get_max_health()) and p.is_in_group("player"), "a: level 1, full HP, player group")
	var cicadas := 0
	var roaches := 0
	var near_c := 0
	var near_r := 0
	for enemy in get_nodes_in_group("enemies"):
		var script_path: String = enemy.get_script().resource_path
		var near: bool = enemy.global_position.distance_to(p.global_position) < 10
		if script_path.ends_with("neon_cicada.gd"):
			cicadas += 1
			near_c += int(near)
		elif script_path.ends_with("sludge_roach.gd"):
			roaches += 1
			near_r += int(near)
	check(near_c >= 2 and near_r == 0, "a: nearby cicadas=%d, roaches=%d" % [near_c, near_r])
	for enemy in get_nodes_in_group("enemies"):
		if enemy.get_script().resource_path.ends_with("neon_cicada.gd") or enemy.get_script().resource_path.ends_with("sludge_roach.gd"):
			enemy.take_damage(999, Vector3.ZERO)
	check(total_xp(p) == 10 * cicadas + 15 * roaches and p.get_level() >= 2, "b: exact earned XP=%d (%d cicadas, %d roaches), level=%d" % [total_xp(p), cicadas, roaches, p.get_level()])
	var damage: float = p.get_effective_bat_damage()
	check(p.spend_stat_point("strength") and p.get_effective_bat_damage() > damage, "b: strength point increases bat damage")
	var cp = get_first_node_in_group("checkpoints")
	p.global_position = cp.global_position + Vector3(0, 0.5, 0)
	p.velocity = Vector3.ZERO
	await frames(2)
	var saved_level: int = p.get_level()
	var saved_xp: int = p.get_current_xp()
	var saved_strength: int = p.get_strength()
	var saved_points: int = p.get_unspent_stat_points()
	check(sm.has_save_data() and int(sm.cached_save_data.get("player", {}).get("level", -1)) == saved_level, "c: checkpoint collision saves current level")
	var cp_position: Vector3 = cp.global_position
	var old_id := mall.get_instance_id()
	p.take_damage(9999)
	check(p.is_dead(), "d: real lethal damage enters dead state")
	var reloaded := await poll(func(): return current_scene != null and current_scene.get_instance_id() != old_id, 4)
	if not check(reloaded, "d: death reloads scene within 4s"):
		await finish()
		return
	await frames(2)
	mall = current_scene
	p = mall.get_node("Player")
	check(p.get_level() == saved_level and is_equal_approx(p.get_current_health(), p.get_max_health()) and p.global_position.distance_to(cp_position) < 3, "d: respawn restores saved level, full HP, checkpoint position")
	check(p.get_current_xp() == saved_xp and p.get_strength() == saved_strength and p.get_unspent_stat_points() == saved_points, "d: respawn preserves XP, spent strength and unspent points")
	# Real rail, real sensor. Teleport outside its area first, then enter airborne/aligned.
	var rail: Path3D = mall.get_node("LevelGeometry/GrindRails/Rail_SunkenAtriumCurved")
	var offset := rail.curve.get_baked_length() * 0.65
	var point := rail.to_global(rail.curve.sample_baked(offset))
	var tangent := (rail.to_global(rail.curve.sample_baked(offset + 0.25)) - rail.to_global(rail.curve.sample_baked(offset - 0.25))).normalized()
	tangent.y = 0
	tangent = tangent.normalized()
	p.grind_ended.connect(func(_v): ended += 1)
	p.grind_slam_executed.connect(func(_pos, _dir, _damage): slams += 1)
	p.set_is_skating(true)
	p.global_position = point + Vector3(3, 2, 0)
	p.velocity = Vector3.ZERO
	await frames(2)
	p.global_position = point + Vector3(0, 0.35, 0)
	p.velocity = tangent * 8
	Input.action_press("jump")
	var grinding := await poll(func(): return p.is_grinding(), 0.5)
	Input.action_release("jump")
	check(grinding, "e: real atrium sensor enters grind within 0.5s")
	if grinding:
		await create_timer(0.18).timeout
		Input.action_press("jump")
		await frames(1)
		Input.action_release("jump")
		await poll(func(): return slams > 0, 3)
	check(ended == 1 and slams == 1, "e: jump dismount emits grind_ended and one landing slam")
	p.global_position = Vector3(0, 1, 17)
	p.velocity = Vector3.ZERO
	var trigger = mall.get_node("BossEncounterTrigger")
	trigger._on_body_entered(p)
	await frames(1)
	if not check(get_nodes_in_group("boss").size() == 1, "f: real trigger spawns exactly one Queen"):
		await finish()
		return
	var queen = get_first_node_in_group("boss")
	queen.boss_phase_transition.connect(func(phase): phases.append(phase))
	queen.boss_defeated.connect(func(): defeated += 1)
	queen.take_damage(210, Vector3.ZERO)
	check(queen.current_phase == 2 and phases == [2], "f: phase 2 signal/state in order")
	check(await poll(func(): return not queen.is_invulnerable, 2.5), "f: phase 2 invulnerability expires")
	queen.take_damage(200, Vector3.ZERO)
	check(queen.current_phase == 3 and phases == [2, 3], "f: phase 3 signal/state in order")
	check(await poll(func(): return not queen.is_invulnerable, 2.5), "f: phase 3 invulnerability expires")
	# Force the real summon state rather than depending on a random AI choice.
	queen._enter_minion_summon()
	var summons: Array[Node] = []
	check(await poll(func():
		for enemy in get_nodes_in_group("enemies"):
			if enemy.get_meta("summoned_by_boss", false):
				return true
		return false, 2.5), "f: real summon state creates minions")
	for enemy in get_nodes_in_group("enemies"):
		if enemy.get_meta("summoned_by_boss", false):
			summons.append(enemy)
	queen.take_damage(999, Vector3.ZERO)
	check(defeated == 1, "f: boss_defeated fires once")
	await frames(2)
	var freed := not summons.is_empty()
	for minion in summons:
		freed = freed and not is_instance_valid(minion)
	check(freed, "f: summoned minions freed on victory")
	var victory := false
	for label in mall.get_node("HUD").find_children("*", "RichTextLabel", true, false):
		if label.text.contains("SIGNAL RESTORED // MALL QUARANTINE LIFTED") and label.get_parent().get_parent() is PanelContainer:
			victory = true
	check(victory, "f: HUD victory card node exists")
	var menu := await poll(func(): return current_scene != null and current_scene.scene_file_path == "res://scenes/main_menu.tscn", 7)
	check(menu, "f: victory returns to main_menu within 7s")
	if menu:
		await frames(2)
		check(current_scene.get_node("VBoxContainer/LoadGameButton").is_visible_in_tree(), "g: Continue button visible")
	check(sm.cached_save_data.get("slice_complete", false) == true, "g: saved slice_complete is true")
	await finish()

func finish() -> void:
	if finishing:
		return
	finishing = true
	Input.action_release("jump")
	sm.clear_save()
	if had_save:
		var file := FileAccess.open(sm.SAVE_PATH, FileAccess.WRITE)
		file.store_buffer(backup)
		file.close()
	Engine.time_scale = 1
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	await frames(3)
	var elapsed := (Time.get_ticks_msec() - started) / 1000.0
	check(elapsed < 60, "runtime %.2fs < 60s" % elapsed)
	print("RESULT: %s (%d fails)" % ["PASS" if fails == 0 else "FAIL", fails])
	quit(0 if fails == 0 else 1)
