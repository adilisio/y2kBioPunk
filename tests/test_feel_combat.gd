extends SceneTree

class Target extends CharacterBody3D:
	var damages: Array[int] = []
	var impulses: Array[Vector3] = []
	func take_damage(amount: int, knockback_dir: Vector3 = Vector3.ZERO) -> void:
		damages.append(amount)
		impulses.append(knockback_dir)

var failures: Array[String] = []
var player: CharacterBody3D
var mall: Node3D
var evade_ends := 0
var hurts := 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func target_at(position: Vector3) -> Target:
	var target := Target.new()
	target.collision_layer = 4
	target.collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.position.y = 0.8
	target.add_child(shape)
	mall.add_child(target)
	target.global_position = position
	return target

func run() -> void:
	mall = load("res://scenes/FloodedMall_Greybox.tscn").instantiate()
	mall.set_script(null)
	for name in ["Enemies", "HUD", "BossEncounterTrigger", "Checkpoint"]:
		var node := mall.get_node_or_null(name)
		if node:
			node.free()
	root.add_child(mall)
	current_scene = mall
	player = mall.get_node("Player")
	player.global_position = Vector3(0, 0.1, 17)
	await frames(30)
	var rig := player.get_node("IsometricCameraRig")
	rig.set_physics_process(false)
	rig.get_node("Camera3D").free() # Keep scripted trauma hook; disable cursor aim for deterministic tests.
	player.set_facing_direction(Vector3(0, 0, 1))
	var front := target_at(player.global_position + Vector3(0, 0, 1.6))
	var back := target_at(player.global_position + Vector3(0, 0, -1.6))
	await frames(2)
	player.set_critical_chance_override(0.0) # VIBE crits are random; this test checks the base combo
	player.get_attack_sensor().position = Vector3(0, 0.5, -1.2)
	check((player.get_attack_sensor().collision_mask & 1) == 0, "Melee must exclude world layer")
	player.attack()
	check(front.damages.is_empty(), "Damage must not fire on press")
	await frames(3)
	check(front.damages.is_empty(), "Damage must wait for visible impact")
	await create_timer(0.14).timeout
	check(front.damages.size() == 1 and back.damages.is_empty(), "Fresh forward query must hit front only despite stale rear sensor")
	check(rig.trauma > 0, "Confirmed hit must add camera trauma")
	player.attack() # Buffer second punch in final 0.15s.
	await create_timer(0.29).timeout
	player.attack() # Buffer third punch.
	await create_timer(0.50).timeout
	print("FEEL combo_damages=", front.damages, " impulses=", front.impulses)
	var base_dmg := int(player.get_effective_bat_damage())
	check(front.damages == [base_dmg, base_dmg, int(base_dmg * 1.5)], "Three-hit combo must deliver base/base/1.5x damage (base %d)" % base_dmg)
	check(front.impulses.size() == 3 and is_equal_approx(front.impulses[2].length(), 1.5), "Third punch must increase knockback 1.5x")
	check(not player.get_is_attacking(), "Combo must release attack state")
	check(is_equal_approx(Engine.time_scale, 1), "Hit-stop must restore time scale")
	check(is_equal_approx(player.get_effective_bat_damage(), 15.0 + 4.0 * player.get_effective_strength()), "Bound damage getter must match native combo (15 + 4*STR)")
	player.evade_ended.connect(func(): evade_ends += 1)
	check(player.try_evade(), "Evade should begin")
	player.attack()
	check(player.get_movement_state() == 4 and not player.get_is_attacking(), "Melee during evade must be refused")
	await frames(11)
	check(not player.get_is_invincible(), "Evade immunity must end at 0.18s")
	await frames(3)
	check(player.get_movement_state() != 4 and not player.get_is_invincible(), "Evade exit must clear invulnerability")
	check(evade_ends == 1, "Evade exit must emit exactly once")
	await frames(22)
	check(player.try_evade(), "Evade should become available after cooldown")
	player.set_movement_locked(true)
	check(not player.get_is_invincible() and evade_ends == 2, "Movement lock must cancel evade cleanly")
	player.set_movement_locked(false)
	player.player_hurt.connect(func(_amount): hurts += 1)
	var hp: float = player.get_current_health()
	player.take_damage(10, Vector3.RIGHT)
	var mesh := player.find_child("Mesh_0", true, false) as MeshInstance3D
	check(mesh.material_overlay != null and mesh.material_overlay.albedo_color == Color.WHITE, "Hurt must start with white skin overlay")
	await frames(3)
	check(player.velocity.x >= 6.9, "Hurt knockback must survive locomotion update")
	player.take_damage(10)
	check(is_equal_approx(hp - player.get_current_health(), 10) and hurts == 1, "Hurt signal and immunity must reject stacked damage")
	await frames(3)
	check(mesh.material_overlay != null and mesh.material_overlay.albedo_color.r > mesh.material_overlay.albedo_color.g, "Hurt flash must turn red")
	await frames(7)
	check(mesh.material_overlay == null, "Hurt flash must restore original skin overlay")
	player.velocity = Vector3(9, 0, 0)
	await frames(3)
	check(player.velocity.x > 8.9, "External boss-style shove must survive assignment")
	var voices: Array[AudioStreamPlayer] = []
	for child in player.get_children():
		if child is AudioStreamPlayer and String(child.name).begins_with("SFXAudio"):
			voices.append(child)
	check(voices.size() == 4, "SFX must have four voices")
	var cached_hit: AudioStreamWAV
	for cue in ["hit", "swing", "evade", "death", "slam", "yum", "hurt", "jump", "land"]:
		for voice in voices:
			voice.stop()
			voice.stream = null
		player.play_sfx(cue)
		var found := false
		for voice in voices:
			var wav := voice.stream as AudioStreamWAV
			if wav and wav.data.size() > 0:
				if cue == "hit":
					cached_hit = wav
				# Signed PCM should decay to zero, not unsigned midpoint 127.
				var byte: int = wav.data[-1]
				var sample := byte if byte < 128 else byte - 256
				found = found or absi(sample) < 40
		check(found, "SFX must contain decaying signed PCM: " + cue)
	player.play_sfx("hit")
	check(voices.any(func(voice): return voice.stream == cached_hit), "Repeated cue must reuse cached stream")
	current_scene = null
	mall.queue_free()
	await frames(3)
	print("FEEL_COMBAT ", "PASS" if failures.is_empty() else "FAIL", " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
