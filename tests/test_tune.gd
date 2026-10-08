extends SceneTree
## VS11 tuning contracts, isolated actors, real native player and checkpoint save.
const TestUtil = preload("res://tests/_test_util.gd")
const Roach = preload("res://scripts/sludge_roach.gd")
const Cicada = preload("res://scripts/neon_cicada.gd")
const Queen = preload("res://scripts/dial_up_queen.gd")
const Turret = preload("res://scripts/corrupted_kiosk_turret.gd")
const Trigger = preload("res://scripts/boss_encounter_trigger.gd")
const Checkpoint = preload("res://scripts/checkpoint.gd")

class Target extends CharacterBody3D:
	var damage_received := 0
	var direction := Vector3.ZERO
	func take_damage(amount: int, knockback: Vector3 = Vector3.ZERO) -> void:
		damage_received += amount
		direction = knockback

class Pager extends Node:
	var pages: Array[String] = []
	func page_message(msg: String) -> void:
		pages.append(msg)

var fired := 0

func _init() -> void:
	call_deferred("_run")

func overlay(node: Node) -> StandardMaterial3D:
	return EnemyModel.geometry(node)[0].material_overlay as StandardMaterial3D

func _run() -> void:
	TestUtil.reset()
	var started := Time.get_ticks_msec()
	var sm = root.get_node("SaveManager")
	var had_save: bool = sm.has_save_data()
	var backup := FileAccess.get_file_as_bytes(sm.SAVE_PATH) if had_save else PackedByteArray()
	var cached: Dictionary = sm.cached_save_data.duplicate(true)
	var world := Node3D.new()
	root.add_child(world)
	TestUtil.track(world)
	var target := Target.new()
	world.add_child(target)
	target.add_to_group("player")
	target.position = Vector3(1, 0, 0)

	var roach := Roach.new()
	world.add_child(roach)
	roach.set_physics_process(false)
	roach.target_player = target
	roach._enter_windup(Vector3.RIGHT)
	TestUtil.check(overlay(roach.visual_mesh).emission.is_equal_approx(Color(1.0, 0.75, 0.2)), "Roach windup is amber")
	roach._enter_pouncing(Vector3.RIGHT * 3.0)
	roach._process_pouncing(0.01)
	TestUtil.check(target.direction.length() > 0.0 and is_equal_approx(target.direction.length(), 1.0), "Roach bite passes non-zero normalized knockback")
	TestUtil.check(overlay(roach.visual_mesh).emission.is_equal_approx(Color(0.5, 1.0, 1.0)), "Roach recovery is pale cyan")
	roach.take_damage(1)
	TestUtil.check(overlay(roach.visual_mesh).emission.is_equal_approx(Color(1.0, 0.2, 0.15)), "Roach hit flash stays red during recovery")
	roach._reset_flash_visual()
	TestUtil.check(overlay(roach.visual_mesh).emission.is_equal_approx(Color(0.5, 1.0, 1.0)), "Recovery tint returns after hit flash")
	roach._enter_tracking()
	TestUtil.check(overlay(roach.visual_mesh) == null, "Recovery tint clears on tracking")
	roach.free()

	var cicada := Cicada.new()
	world.add_child(cicada)
	cicada.set_physics_process(false)
	cicada.target_player = target
	cicada._enter_windup(Vector3.RIGHT)
	TestUtil.check(overlay(cicada.visual_mesh).emission.is_equal_approx(Color(1.0, 0.75, 0.2)), "Cicada windup is amber")
	cicada._process_windup(0.5)
	target.damage_received = 0
	cicada._process_lunge(0.01)
	cicada._process_lunge(0.01)
	TestUtil.check(target.damage_received == 10, "Cicada contact deals ten damage exactly once")
	cicada.take_damage(1)
	TestUtil.check(overlay(cicada.visual_mesh).emission.is_equal_approx(Color(1.0, 0.12, 0.12)), "Cicada hit flash stays red")
	cicada.free()

	var queen := Queen.new()
	world.add_child(queen)
	queen.set_physics_process(false)
	queen.target_player = target
	for phase in 3:
		queen.current_phase = phase + 1
		TestUtil.check(is_equal_approx(queen._charge_duration(), [1.4, 1.1, 1.05][phase]), "Queen phase %d charge duration" % (phase + 1))
		queen._enter_aoe_attack()
		queen._process_aoe(queen._charge_duration() - (0.31 if phase == 2 else 0.11))
		TestUtil.check(not queen.aoe_flashing, "Queen phase %d waits for pre-blast flash" % (phase + 1))
		queen._process_aoe(0.02)
		TestUtil.check(queen.aoe_flashing, "Queen phase %d flashes in final %.1fs" % [phase + 1, queen._pre_blast_duration()])
	queen._clear_telegraph()
	queen._enter_minion_summon()
	TestUtil.check(queen.sfx.stream != null and is_equal_approx(queen.sfx.stream.get_length(), 1.5), "Summon plays a 1.5s cue")
	var alpha: float = overlay(queen.queen_body).albedo_color.a
	queen._process_summon(0.1)
	TestUtil.check(not is_equal_approx(overlay(queen.queen_body).albedo_color.a, alpha), "Summon warning tint pulses on the model")
	# Exercise the closest, coincident and distant target positions.
	for pos in [Vector3.ZERO, Vector3(3.5, 0, 0), Vector3(20, 0, 0)]:
		target.position = pos
		queen._execute_summon()
		var count := 0
		for enemy in get_nodes_in_group("enemies"):
			if enemy.get_meta("summoned_by_boss", false):
				count += 1
				var gap: Vector3 = enemy.global_position - target.global_position
				TestUtil.check(Vector2(gap.x, gap.z).length() >= 5.0, "Summoned minion starts at least 5m from player")
				enemy.free()
		TestUtil.check(count == 4, "Phase-three summon creates four minions")

	var turret := Turret.new()
	world.add_child(turret)
	turret.set_physics_process(false)
	turret.target_player = target
	turret._enter_charging()
	turret._physics_process(1.0)
	TestUtil.check(turret.current_state == Turret.State.IDLE, "Turret cancels its charge while a boss exists")
	turret._on_detection_body_entered(target)
	for i in 3:
		turret._physics_process(1.0)
	TestUtil.check(turret.current_state == Turret.State.IDLE, "Turret remains idle during boss encounter")
	TestUtil.check(world.find_children("TurretMortar*", "", false, false).is_empty(), "Boss encounter fires no turrets")
	queen.free()
	target.position = Vector3(10, 0, 0)
	turret._physics_process(1.0)
	TestUtil.check(turret.current_state == Turret.State.TRACKING, "Turret resumes normal tracking after boss removal")
	turret.free()
	target.free()

	var player = load("res://scenes/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	player.secondary_fired.connect(func(_weapon, _pos, _dir, _damage): fired += 1)
	player.fire_disk_launcher()
	player.fire_disk_launcher()
	TestUtil.check(fired == 1, "Cooldown refuses a second immediate disk")
	player.simulate_physics(0.79)
	player.fire_disk_launcher()
	TestUtil.check(fired == 1, "Disk cooldown still blocks at 0.79s")
	player.simulate_physics(0.02)
	player.fire_disk_launcher()
	TestUtil.check(fired == 2, "Disk cooldown expires at 0.8s")
	var victim := Target.new()
	victim.add_to_group("enemies")
	world.add_child(victim)
	victim.position = player.position + Vector3(1, 0, 0)
	player.execute_grind_slam(Vector3.RIGHT)
	TestUtil.check(victim.damage_received >= 70, "Level-one slam deals enough damage to kill a 70HP cicada")
	victim.free()

	var pager := Pager.new()
	pager.add_to_group("hud")
	world.add_child(pager)
	var trigger := Trigger.new()
	world.add_child(trigger)
	player.position = Vector3(2, 1, 3)
	trigger._on_body_entered(player)
	var pos: Dictionary = sm.cached_save_data.get("checkpoint_position", {})
	TestUtil.check(sm.cached_save_data.get("checkpoint_id", "") == "ArenaGate" and Vector3(pos.get("x", 0), pos.get("y", 0), pos.get("z", 0)).is_equal_approx(player.global_position), "Arena save falls back to player position when no checkpoint exists")
	TestUtil.check(pager.pages == ["PROGRESS SAVED // ARENA GATE"], "Arena save pages successful progress save")
	for boss in get_nodes_in_group("boss"):
		boss.free()
	trigger.free()
	pager.pages.clear()
	var checkpoint := Checkpoint.new()
	world.add_child(checkpoint)
	player.set_current_health(20)
	checkpoint._on_body_entered(player)
	TestUtil.check(is_equal_approx(player.get_current_health(), player.get_max_health()), "Checkpoint restores full HP")
	TestUtil.check(pager.pages == ["PROGRESS SAVED // BIO-STABILIZER"], "Checkpoint pages successful save")
	TestUtil.check(sm.cached_save_data.get("checkpoint_id", "") == checkpoint.checkpoint_id, "Checkpoint writes its own id")
	checkpoint._on_body_entered(player)
	TestUtil.check(pager.pages.size() == 1, "Checkpoint cooldown suppresses repeated immediate saves")
	var cooldown_end := Time.get_ticks_msec() + 1050
	while Time.get_ticks_msec() < cooldown_end:
		await process_frame
	player.set_current_health(20)
	checkpoint._on_body_entered(player)
	TestUtil.check(pager.pages.size() == 2 and is_equal_approx(player.get_current_health(), player.get_max_health()), "Checkpoint heals and pages again after 1s cooldown")

	sm.clear_save()
	if had_save:
		var file := FileAccess.open(sm.SAVE_PATH, FileAccess.WRITE)
		file.store_buffer(backup)
		file.close()
	sm.cached_save_data = cached
	await TestUtil.cleanup(self)
	TestUtil.check(Time.get_ticks_msec() - started < 15000, "Tuning regression runtime stays below 15s")
	TestUtil.finish(self)
