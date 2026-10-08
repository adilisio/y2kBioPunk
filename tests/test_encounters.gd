extends SceneTree

const Roach = preload("res://scripts/sludge_roach.gd")
const Cicada = preload("res://scripts/neon_cicada.gd")
const Turret = preload("res://scripts/corrupted_kiosk_turret.gd")
const Mortar = preload("res://scripts/turret_mortar.gd")
const Queen = preload("res://scripts/dial_up_queen.gd")
var failures := 0

class Target extends CharacterBody3D:
	var damage_received := 0
	var xp := 0
	func take_damage(amount: int, _direction: Vector3 = Vector3.ZERO) -> void:
		damage_received += amount
	func gain_xp(amount: int) -> void:
		xp += amount

func check(value: bool, label: String) -> void:
	print("%s: %s" % ["PASS" if value else "FAIL", label])
	if not value:
		failures += 1

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== test_encounters ===")
	var pcm := Mortar.sound(0.2, 700.0)
	var has_negative := false
	for byte in pcm.data:
		if byte >= 128:
			has_negative = true
	check(pcm.format == AudioStreamWAV.FORMAT_8_BITS and pcm.data[0] == 0 and has_negative, "enemy SFX uses signed PCM8 with zero silence")
	var world := Node3D.new()
	root.add_child(world)
	var player := Target.new()
	world.add_child(player)
	player.add_to_group("player")
	player.position = Vector3(3.5, 0, 0)
	var roach := Roach.new()
	world.add_child(roach)
	roach.set_physics_process(false)
	roach.target_player = player
	roach._enter_tracking()
	roach._process_tracking(1.0 / 60.0)
	check(roach.current_state == Roach.State.WINDUP, "roach winds up at 3.5 m")
	for i in 18:
		roach._process_windup(1.0 / 60.0)
	check(player.damage_received == 0 and roach.current_state == Roach.State.WINDUP, "roach cannot damage in first 0.3 seconds")
	var pack: Array = [roach]
	for i in 2:
		var other := Roach.new()
		world.add_child(other)
		other.set_physics_process(false)
		other._enter_windup(Vector3.RIGHT)
		pack.append(other)
	check(int(root.get_meta("roach_attack_slots", 0)) == 2 and pack[2].current_state != Roach.State.WINDUP, "pack permits at most two attacks")
	roach._enter_repositioning()
	check(is_equal_approx(roach.state_timer, 1.2) and is_equal_approx(Vector2(roach.velocity.x, roach.velocity.z).length(), 2.0), "roach recovery is 1.2s at 2m/s")
	roach.take_damage(10)
	check(roach.current_health == roach.max_health - 15, "recovery takes 1.5x damage")
	for e in pack:
		e.free()
	check(int(root.get_meta("roach_attack_slots", 0)) == 0, "pack slots released on removal")

	var cicada := Cicada.new()
	world.add_child(cicada)
	cicada.set_physics_process(false)
	cicada.target_player = player
	cicada.position = player.position - Vector3.RIGHT
	cicada._enter_windup(Vector3.RIGHT)
	cicada._process_windup(0.49)
	check(player.damage_received == 0, "cicada wind-up deals no damage")
	cicada._process_windup(0.011)
	for i in 18:
		cicada._process_lunge(1.0 / 60.0)
	check(player.damage_received == 6, "cicada lunge deals six damage exactly once")
	check(cicada.attack_cooldown >= 1.4, "cicada cooldown is at least 1.4s")
	cicada.gravity = 0.0
	for i in 84:
		cicada._physics_process(1.0 / 60.0)
	check(player.damage_received == 6, "cicada cannot deal a second hit during 1.4s cooldown")
	cicada.free()

	var mortar := Mortar.new()
	world.add_child(mortar)
	mortar.set_physics_process(false)
	mortar.setup(Vector3(0, 2, 0), Vector3(10, 0.04, 0), 20)
	var marker := mortar.landing_marker
	check(is_equal_approx(marker.radius, 2.2) and marker.global_position.distance_to(mortar.impact_target) < 0.01, "mortar marks the splash landing point")
	for i in 100:
		if mortar.exploded:
			break
		mortar._physics_process(1.0 / 60.0)
	check(mortar.exploded and mortar.global_position.distance_to(Vector3(10, 0.04, 0)) < 1.0, "ballistic mortar lands within 1m at 10m range")
	await process_frame

	var queen := Queen.new()
	world.add_child(queen)
	queen.set_physics_process(false)
	queen.target_player = player
	for phase in 3:
		queen.current_phase = phase + 1
		queen._enter_aoe_attack()
		check(is_equal_approx(queen.state_timer, [1.4, 1.1, 1.05][phase]), "queen phase %d charge duration" % (phase + 1))
		check(is_equal_approx(queen.aoe_outline.mesh.outer_radius, [7.0, 9.0, 11.0][phase]), "queen phase %d shows full radius immediately" % (phase + 1))
	queen._execute_summon()
	queen._execute_summon()
	var summoned := 0
	for e in get_nodes_in_group("enemies"):
		if e.get_meta("summoned_by_boss", false):
			summoned += 1
			e.set_physics_process(false)
	check(summoned == 4, "queen caps living summons at four")
	queen.free()
	for e in get_nodes_in_group("enemies"):
		e.free()

	for entry in [[Roach, 15], [Cicada, 10], [Turret, 40], [Queen, 250]]:
		var enemy = entry[0].new()
		world.add_child(enemy)
		enemy.set_physics_process(false)
		var before := player.xp
		for i in 5:
			enemy.take_damage(9999)
		enemy._die()
		check(player.xp - before == entry[1], "%s death awards XP once under five rapid hits" % enemy.get_script().resource_path.get_file())
	await create_timer(1.3).timeout
	world.queue_free()
	await process_frame

	var save_manager = root.get_node("SaveManager")
	var had_save := FileAccess.file_exists(save_manager.SAVE_PATH)
	var save_backup := FileAccess.get_file_as_string(save_manager.SAVE_PATH) if had_save else ""
	var mall = load("res://scenes/FloodedMall_Greybox.tscn").instantiate()
	root.add_child(mall)
	var count := 0
	var nearby_cicadas := 0
	var nearby_roaches := 0
	var total_xp := 0
	for e in get_nodes_in_group("enemies"):
		count += 1
		var distance: float = e.global_position.distance_to(Vector3(0, 1, 9))
		if e.get_script() == Cicada:
			total_xp += 10
			if distance < 10:
				nearby_cicadas += 1
		elif e.get_script() == Roach:
			total_xp += 15
			if distance < 10:
				nearby_roaches += 1
		elif e.get_script() == Turret:
			total_xp += 40
	check(count == 9 and nearby_cicadas >= 2 and nearby_roaches == 0, "nine spawns, two nearby cicadas, no nearby roaches")
	check(total_xp >= 125, "pre-boss roster supplies level-three XP (got %d)" % total_xp)
	await create_timer(20.0).timeout
	var live_player = mall.get_node("Player")
	var hp: float = live_player.get_current_health()
	check(hp > 0.0, "standing mall player survives 20s (HP %.0f)" % hp)
	check(hp < 100.0, "cicada contact attacks hit the real player collision body")
	mall.queue_free()
	await process_frame
	if had_save:
		var restored := FileAccess.open(save_manager.SAVE_PATH, FileAccess.WRITE)
		restored.store_string(save_backup)
		restored.close()
	else:
		save_manager.clear_save()
	print("RESULT: %s (%d fails)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
