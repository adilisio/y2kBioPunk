extends SceneTree

const T = preload("res://tests/_test_util.gd")
const Turret = preload("res://scripts/corrupted_kiosk_turret.gd")
const Queen = preload("res://scripts/dial_up_queen.gd")
const Roach = preload("res://scripts/sludge_roach.gd")
const Cicada = preload("res://scripts/neon_cicada.gd")
const STEP := 1.0 / 60.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	T.reset()
	print("=== test_identity (deterministic 60 Hz visual samples) ===")
	var world := Node3D.new()
	root.add_child(world)
	T.track(world)
	var player := Node3D.new()
	world.add_child(player)
	player.add_to_group("player")
	player.position = Vector3(20.0, 0.0, 20.0)
	for fallback in [false, true]:
		var variant := "CSG" if fallback else "GLB"
		var turret := Turret.new()
		if fallback:
			turret.model_path = ""
		world.add_child(turret)
		turret.set_physics_process(false)
		turret.set_process(false)
		var beacon_light := turret.get_node("TurretHead/Beacon/BeaconLight") as OmniLight3D
		T.check(beacon_light != null and turret.has_node("HazardRing") and turret.has_node("HazardRingBlack"), "%s turret has beacon and yellow-black hazard ring" % variant)
		var lights := turret.find_children("*", "OmniLight3D", true, false)
		T.check(lights.size() == 2, "%s turret has exactly two cheap lights" % variant)
		for light in lights:
			T.check(not light.shadow_enabled, "%s turret light has no shadows" % variant)
		T.check(is_equal_approx(beacon_light.omni_range, 4.0) and is_equal_approx(beacon_light.light_energy, 1.2), "%s beacon cost settings" % variant)
		T.check(turret.screen_mesh.size.is_equal_approx(Vector3(0.9, 0.675, 0.1)) and is_equal_approx(turret.screen_mat.emission_energy_multiplier, 2.0), "%s enlarged CRT emission" % variant)
		for color in [Color.RED, Color(0.2, 0.8, 0.4), Color(0.9, 0.7, 0.1)]:
			turret._set_screen_color(color)
			T.check(turret.screen_mat.emission == color and turret.screen_light.light_color == color, "%s CRT and glow follow state ramp exactly" % variant)
		var start_yaw: float = turret.head_pivot.rotation.y
		var start_beacon: float = turret.beacon.rotation.y
		for i in 120:
			turret._process(STEP)
			T.check(absf(turret.head_pivot.rotation.y) <= deg_to_rad(35.0) + 0.001, "%s scan stays within 35 degrees" % variant)
		T.check(not is_equal_approx(start_yaw, turret.head_pivot.rotation.y) and turret.beacon.rotation.y > start_beacon, "%s idle head and beacon move after two seconds" % variant)
		turret.target_player = player
		turret.head_pivot.rotation.y = 0.7
		turret._process(STEP)
		T.check(is_equal_approx(turret.head_pivot.rotation.y, 0.7), "%s cosmetic scan yields to tracking" % variant)
		turret.free()

		var queen := Queen.new()
		if fallback:
			queen.model_path = ""
		world.add_child(queen)
		queen.set_physics_process(false)
		queen.set_process(false)
		queen.target_player = player
		var spawn: Vector3 = queen.global_position
		var visual_spawn: Vector3 = queen.queen_body.global_position
		for i in 180:
			queen._face_player(STEP)
			queen._process(STEP)
		T.check(queen.queen_body.global_position.distance_to(visual_spawn) >= 1.0, "%s Queen visual drifts at least 1m after three seconds" % variant)
		T.check(queen.global_position == spawn and queen.get_node("CollisionShape3D").position == Vector3(0, 1.8, 0), "%s hover leaves body and collision centre unchanged" % variant)
		for phase in 3:
			queen.current_phase = phase + 1
			T.check(is_equal_approx(queen._aoe_radius(), [7.0, 9.0, 11.0][phase]) and is_equal_approx(queen._charge_duration(), [1.4, 1.1, 1.05][phase]), "%s Queen phase %d radius and charge unchanged" % [variant, phase + 1])
		queen._enter_aoe_attack()
		var centre: Vector3 = queen.aoe_center
		for i in 60:
			queen._process(STEP)
		T.check(queen.hover_rise > 0.59 and queen.aoe_center == centre and queen.aoe_telegraph_ring.global_position == centre, "%s charge rises 0.6m without moving AoE centre" % variant)
		queen._detonate_aoe()
		queen._enter_idle()
		queen._process(STEP)
		T.check(is_equal_approx(queen.visual_motion.scale.y, 0.85) and is_zero_approx(queen.hover_rise), "%s detonation drops and squashes visual" % variant)
		for i in 10:
			queen._process(STEP)
		T.check(is_equal_approx(queen.visual_motion.scale.y, 1.0), "%s squash recovers after 0.15 seconds" % variant)
		queen._enter_minion_summon()
		queen.state_timer = 0.0
		queen._process(STEP)
		T.check(is_equal_approx(queen.visual_motion.rotation.y, PI * 0.5), "%s summon turns visual 90 degrees" % variant)
		queen._trigger_phase_transition(2)
		queen.state_timer = 0.9
		for i in 30:
			queen._process(STEP)
		T.check(is_equal_approx(queen.visual_motion.rotation.y, PI) and queen.hover_rise > 0.58, "%s phase transition spins and rises" % variant)
		queen.free()

		var roach := Roach.new()
		if fallback:
			roach.model_path = ""
		world.add_child(roach)
		roach.set_physics_process(false)
		roach.set_process(false)
		roach.velocity = Vector3(5.5, 0.0, 0.0)
		roach._process(1.0)
		var roach_y: float = roach.visual_mesh.position.y
		roach._process(STEP)
		T.check(not is_equal_approx(roach_y, roach.visual_mesh.position.y), "%s moving roach bob varies between frames after 1s" % variant)
		roach._enter_windup(Vector3.RIGHT)
		var windup_scale: Vector3 = roach.visual_mesh.scale
		roach._process(STEP)
		T.check(roach.visual_mesh.scale == windup_scale and is_equal_approx(roach.visual_mesh.position.y, roach.visual_rest_position.y), "%s roach preserves wind-up squash" % variant)
		roach.free()

		var cicada = load("res://scenes/neon_cicada.tscn").instantiate()
		if fallback:
			cicada.model_path = ""
		world.add_child(cicada)
		cicada.set_physics_process(false)
		cicada.set_process(false)
		cicada.velocity = Vector3(3.0, 0.0, 0.0)
		cicada._process(1.0)
		var cicada_y: float = cicada.visual_mesh.position.y
		cicada._process(STEP)
		T.check(not is_equal_approx(cicada_y, cicada.visual_mesh.position.y), "%s cicada hover bob varies between frames after 1s" % variant)
		T.check(cicada.visual_mesh.scale.x >= cicada.visual_rest_scale_x and cicada.visual_mesh.scale.x <= cicada.visual_rest_scale_x * 1.08, "%s moving cicada flutter stays within 1.0-1.08 scale" % variant)
		cicada._enter_windup(Vector3.RIGHT)
		var cue_scale: Vector3 = cicada.visual_mesh.scale
		cicada._process(STEP)
		T.check(cicada.visual_mesh.scale == cue_scale, "%s cicada preserves wind-up scale" % variant)
		cicada.free()
	await T.cleanup(self)
	print("Checked GLB and CSG identity, motion, combat centres and timing contracts.")
	T.finish(self)
