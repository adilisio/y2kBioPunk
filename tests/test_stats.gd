extends SceneTree
## VS11-STATS: real native damage, XP and sheet contracts with isolated actors.
const TestUtil = preload("res://tests/_test_util.gd")
const Roach = preload("res://scripts/sludge_roach.gd")
const Cicada = preload("res://scripts/neon_cicada.gd")
const Queen = preload("res://scripts/dial_up_queen.gd")
var cues: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	TestUtil.check(ok, message)
	if ok:
		print("PASS: ", message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func strike(player: Node3D) -> void:
	player.position = Vector3.ZERO
	player.velocity = Vector3.ZERO
	player.set_facing_direction(Vector3.FORWARD)
	player.attack()
	player.simulate_physics(0.11) # Real first punch reaches its visible impact frame.
	player.set_is_attacking(false)

func _run() -> void:
	TestUtil.reset()
	var started := Time.get_ticks_msec()
	var world := Node3D.new()
	root.add_child(world)
	TestUtil.track(world)
	var player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.add_to_group("player")
	player.set_physics_process(false)
	player.position = Vector3.ZERO
	player.get_node("IsometricCameraRig").set_physics_process(false)
	player.get_node("IsometricCameraRig/Camera3D").free() # No cursor aim in scripted strikes.
	player.set_facing_direction(Vector3.FORWARD)
	player.sfx_played.connect(func(cue: String): cues.append(cue))
	player.set_unspent_stat_points(4)
	var damage: float = player.get_effective_bat_damage()
	check(player.spend_stat_point("strength") and is_equal_approx(player.get_effective_bat_damage() - damage, 4.0), "STR point adds exactly 4 strike damage")
	var hp: float = player.get_max_health()
	check(player.spend_stat_point("vitality") and is_equal_approx(player.get_max_health() - hp, 12.0), "VIT point adds exactly 12 max HP")
	var speed: float = player.get_movement_speed()
	check(player.spend_stat_point("agility") and is_equal_approx(player.get_movement_speed() / speed, 1.03), "AGI point multiplies walking speed by 1.03")
	player.set_is_skating(true)
	speed = player.get_movement_speed()
	check(player.spend_stat_point("agility") and is_equal_approx(player.get_movement_speed() / speed, 1.03), "AGI point multiplies skating speed by 1.03")
	player.set_is_skating(false)
	# Metal has no VIBE bonus, so forced base VIBE is the effective crit stat.
	player.switch_tape("Metal")
	var roach := Roach.new()
	world.add_child(roach)
	roach.set_physics_process(false)
	roach.collision_layer = 4
	roach.collision_mask = 0
	roach.position = Vector3(0, 0, -1.6)
	roach.current_health = 10000
	await frames(2)
	player.set_vibe(0)
	damage = player.get_effective_bat_damage()
	check(is_zero_approx(player.get_critical_chance()), "VIBE 0 has zero crit chance")
	for i in 12:
		var before := roach.current_health
		strike(player)
		check(before - roach.current_health == int(damage), "VIBE 0 strike %d never crits" % (i + 1))
	check(not cues.has("crit_pop") and cues.has("hit"), "Noncritical hits use ordinary hit SFX")
	player.set_vibe(50)
	check(is_equal_approx(player.get_critical_chance(), 1.0), "VIBE 50 has 100% crit chance")
	var before := roach.current_health
	strike(player)
	check(before - roach.current_health == int(damage * 1.75), "VIBE 50 strike deals x1.75 damage through integer roach interface")
	check(cues.back() == "crit_pop", "Critical hit plays distinct synthesized pop")
	var pops: Array[Node] = player.find_children("SFXAudio*", "AudioStreamPlayer", false, false)
	check(pops.any(func(voice): return voice.stream != null and is_equal_approx(voice.stream.get_length(), 0.08)), "Pop is a short cached 80ms sound")
	# Restore hit-stop before timers, cleanup and UI checks.
	while not is_equal_approx(Engine.time_scale, 1.0):
		await process_frame
	roach.free()
	player.set_vibe(10)
	check(is_equal_approx(player.get_critical_chance(), 0.2), "VIBE 10 gives 20% crit chance")
	player.set_vibe(100)
	check(is_equal_approx(player.get_critical_chance(), 1.0), "Crit chance caps at 100%")
	player.set_vibe(10)

	player.set_level(1)
	player.set_current_xp(0)
	player.set_xp_to_level(50)
	for enemy_script in [Roach, Cicada]:
		var minion = enemy_script.new()
		minion.set_meta("summoned_by_boss", true)
		world.add_child(minion)
		minion._die()
		minion._die()
		check(player.get_current_xp() == 0, "Summoned %s awards zero XP, including repeated death" % enemy_script.resource_path.get_file())
		minion.free()
	var normal := Roach.new()
	world.add_child(normal)
	normal._die()
	normal._die()
	check(player.get_current_xp() == 15, "Normal roach awards exactly 15 XP once")
	normal.free()
	player.set_current_xp(0)
	player.gain_xp(170)
	check(player.get_level() == 3 and player.get_current_xp() == 45 and player.get_xp_to_level() == 112, "170 plaza XP reaches level 3 with 45/112 XP")
	var queen := Queen.new()
	world.add_child(queen)
	queen.set_physics_process(false)
	queen._die()
	queen._die()
	check(player.get_level() == 4 and player.get_current_xp() == 53 and player.get_xp_to_level() == 168, "Queen grants exactly 120 XP once: level 4, 53/168 XP; one arena level")
	queen.free()

	var skeletons: Array[Node] = player.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		print("SKIP: headless player model could not resolve Skeleton3D")
	else:
		var attachment := player.find_child("HandBatAttachment", true, false) as BoneAttachment3D
		check(attachment != null and attachment.get_parent() is Skeleton3D and attachment.get_bone_idx() >= 0, "Bat attachment uses a real skeleton hand bone")
		check(attachment != null and attachment.get_node_or_null("HeldBat/WoodBarrel") is MeshInstance3D, "Bat mesh exists beneath the hand attachment")
		if attachment:
			print("BAT BONE: ", attachment.bone_name)

	# Use the actual scene HUD without starting the mall builder or encounters.
	var mall = load("res://scenes/FloodedMall_Greybox.tscn").instantiate()
	var hud = mall.get_node("HUD")
	mall.remove_child(hud)
	mall.free()
	world.add_child(hud)
	hud._refresh_character_sheet()
	check("STRIKE" in hud.sheet_str_label.text, "Sheet names STRIKE damage")
	for label in [hud.sheet_str_label, hud.sheet_agi_label, hud.sheet_vit_label, hud.sheet_vibe_label]:
		check("per point" in label.text, "Sheet explains per-point effect: " + label.text)
	check("20%" in hud.sheet_vibe_label.text and "×1.75" in hud.sheet_vibe_label.text, "Sheet displays live crit chance and multiplier")
	check(hud.character_sheet.get_node("Margin/VBox/TipLabel").text.begins_with("Tapes shift these numbers while they play."), "Sheet explains tape-shifted numbers")
	for path in ["res://scripts/hud.gd", "res://src/player_controller.cpp"]:
		var source := FileAccess.get_file_as_string(path)
		check(not source.contains("Bat " + "DMG"), "No legacy damage label in " + path)
	hud._on_leveled_up(4, 9)
	check("+1 STAT PT — press C to grow stronger" in hud.pager_messages.back().text, "Level-up copy describes one newly earned point")
	await TestUtil.cleanup(self)
	check(Time.get_ticks_msec() - started < 15000, "Stats regression runtime stays below 15s")
	TestUtil.finish(self)
