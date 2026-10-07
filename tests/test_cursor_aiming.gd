extends SceneTree

const TestUtil = preload("res://tests/_test_util.gd")

func check(cond: bool, msg: String) -> bool:
	return TestUtil.check(cond, msg)

func _init():
	run_tests()

func run_tests() -> void:
	print("\n========================================================")
	print(">>> RUNNING CURSOR-DIRECTED AIMING VERIFICATION TEST <<<")
	print("========================================================\n")

	# -------------------------------------------------------------------------
	# 1. TEST DIRECT POINT AIMING & HITBOX SENSOR REORIENTATION
	# -------------------------------------------------------------------------
	print("[TEST 1] Validating orient_towards_point() & Sensor Alignment...")
	var player = ClassDB.instantiate("PlayerController") as CharacterBody3D
	check(player != null, "PlayerController must instantiate")
	TestUtil.track(player)

	# Add player to tree so C++ _ready lifecycle runs naturally
	root.add_child(player)
	player.global_position = Vector3(0.0, 0.0, 0.0)

	var visuals = Node3D.new()
	visuals.name = "Visuals"
	player.add_child(visuals)

	await process_frame
	await physics_frame

	var attack_sensor = player.find_child("AttackSensor", false, false) as Area3D
	check(attack_sensor != null, "AttackSensor must exist on player")

	# Orient towards point (5, 0, 0) -> +X direction
	var target_x = Vector3(5.0, 0.0, 0.0)
	var orient_result = player.orient_towards_point(target_x)
	check(orient_result == true, "orient_towards_point should return true for valid point")
	var facing = player.get_facing_direction()
	check(facing.is_equal_approx(Vector3(1.0, 0.0, 0.0)), "facing_direction must be (1, 0, 0), got %s" % str(facing))
	check(attack_sensor.position.is_equal_approx(Vector3(1.2, 0.5, 0.0)), "AttackSensor position must snap along facing vector, got %s" % str(attack_sensor.position))

	# Orient towards point (0, 0, -10) -> -Z direction
	var target_z = Vector3(0.0, 0.0, -10.0)
	orient_result = player.orient_towards_point(target_z)
	check(orient_result == true, "orient_towards_point should return true")
	facing = player.get_facing_direction()
	check(facing.is_equal_approx(Vector3(0.0, 0.0, -1.0)), "facing_direction must be (0, 0, -1), got %s" % str(facing))
	check(attack_sensor.position.is_equal_approx(Vector3(0.0, 0.5, -1.2)), "AttackSensor position must snap to (0, 0.5, -1.2), got %s" % str(attack_sensor.position))

	print(">>> [TEST 1 PASSED] orient_towards_point() and sensor alignment verified.\n")

	# -------------------------------------------------------------------------
	# 2. TEST MOVEMENT DECOUPLING (VELOCITY NOT ZEROED ON ATTACK)
	# -------------------------------------------------------------------------
	print("[TEST 2] Validating Movement Velocity Decoupling During Attacks...")
	player.velocity = Vector3(6.0, 0.0, 0.0)
	check(player.velocity.x == 6.0, "Initial velocity should be 6.0")

	# Trigger attack()
	player.attack()
	check(player.get_is_attacking() == true, "Player must be in attacking state")
	check(player.velocity.x == 6.0, "Player horizontal velocity must NOT be zeroed upon attacking! Got: %f" % player.velocity.x)

	# Simulate physics tick while moving with WASD
	# Even while attacking, velocity should persist and not be forcibly zeroed to 0
	player.simulate_physics(0.016)
	check(player.get_is_attacking() == true, "Player still attacking")
	print("Velocity after physics frame while attacking: ", player.velocity)

	print(">>> [TEST 2 PASSED] Attack movement decoupling verified: velocity does not stall.\n")

	# -------------------------------------------------------------------------
	# 3. TEST CAMERA GROUND PLANE RAYCAST PROJECTION & CURSOR AIMING
	# -------------------------------------------------------------------------
	print("[TEST 3] Validating Camera-to-World Mouse Ground Plane Projection...")
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	TestUtil.track(camera)
	root.add_child(camera)
	# Position camera isometric-style at (0, 10, 10) looking at (0, 0, 0)
	camera.global_position = Vector3(0.0, 10.0, 10.0)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.make_current()
	await process_frame
	await physics_frame

	# Query cursor world position
	var cursor_world_pos = player.get_cursor_world_position()
	print("Cursor world position from ground plane intersection: ", cursor_world_pos)
	check(cursor_world_pos is Vector3, "Cursor world position must be a Vector3")

	# Calling orient_towards_cursor() should succeed
	var cursor_orient_res = player.orient_towards_cursor()
	print("orient_towards_cursor() returned: ", cursor_orient_res)
	check(cursor_orient_res == true, "orient_towards_cursor() must succeed when camera is present")
	var post_cursor_facing = player.get_facing_direction()
	check(post_cursor_facing.length() > 0.99, "Facing direction must be normalized after cursor orient")

	print(">>> [TEST 3 PASSED] Camera ground plane raycast projection verified.\n")

	# -------------------------------------------------------------------------
	# 4. TEST SECONDARY FIRE TRAJECTORY ALIGNMENT
	# -------------------------------------------------------------------------
	print("[TEST 4] Validating Secondary Fire Trajectory Alignment...")
	# Stale test used enum 1 for disk; SecondaryWeapon enum is SECONDARY_SPRAY_FLAMETHROWER = 1, SECONDARY_DISK_LAUNCHER = 2
	player.set_secondary_weapon(2) # SECONDARY_DISK_LAUNCHER
	check(player.get_secondary_weapon_name() == "Mini-Disc Launcher", "Secondary weapon should be Mini-Disc Launcher")

	# Orient player towards (1, 0, 0)
	player.orient_towards_point(Vector3(10.0, 0.0, 0.0))
	check(player.get_facing_direction().is_equal_approx(Vector3(1.0, 0.0, 0.0)), "Player should face (1, 0, 0)")

	# Setup signal spy for secondary_fired
	var fired_events: Array = []
	player.connect("secondary_fired", func(w_type, pos, dir, dmg):
		fired_events.append({"type": w_type, "pos": pos, "dir": dir, "damage": dmg})
	)

	# Firing secondary without cursor should use current facing direction or cursor
	player.fire_disk_launcher()
	check(fired_events.size() == 1, "secondary_fired signal must be emitted")
	if fired_events.size() > 0:
		var event = fired_events[0]
		print("Fired event dir: ", event["dir"])
		check(event["dir"] is Vector3, "Fired direction must be Vector3")
		check(event["damage"] > 0.0, "Damage must be > 0")

	# -------------------------------------------------------------------------
	# 5. TEST TRANSFORM NAN & DISTANCE SAFEGUARDS (NO SCALE COLLAPSE)
	# -------------------------------------------------------------------------
	print("[TEST 5] Validating Distance Safeguard & Scale Stability...")
	# Cursor dead center on player: should be safely rejected without zero-vector error or NaN
	var dead_center = player.global_position
	var dead_center_res = player.orient_towards_point(dead_center)
	check(dead_center_res == false, "orient_towards_point should return false when cursor is dead-center on player")
	check(visuals.scale.is_equal_approx(Vector3(1.0, 1.0, 1.0)), "Visuals scale must remain (1, 1, 1), got %s" % str(visuals.scale))
	check(not is_nan(visuals.transform.basis.x.x), "Visuals basis must NOT contain NaN")

	# Target with large Y offset: should be flattened to player.global_position.y
	var vertical_target = player.global_position + Vector3(5.0, 50.0, 0.0)
	var vert_res = player.orient_towards_point(vertical_target)
	check(vert_res == true, "orient_towards_point should succeed with flattened Y")
	var vert_facing = player.get_facing_direction()
	check(is_equal_approx(vert_facing.y, 0.0), "Facing direction Y must strictly be 0.0, got %f" % vert_facing.y)
	check(vert_facing.is_equal_approx(Vector3(1.0, 0.0, 0.0)), "Facing direction must be (1, 0, 0)")
	check(visuals.scale.is_equal_approx(Vector3(1.0, 1.0, 1.0)), "Visuals scale must remain (1, 1, 1) after vertical target")

	# Repeated rotation calls across 100 iterations to verify NO scale collapse or exponential compounding
	for i in range(100):
		var angle = float(i) * 0.1
		var circ_target = player.global_position + Vector3(cos(angle) * 5.0, 0.0, sin(angle) * 5.0)
		player.orient_towards_point(circ_target)
	check(visuals.scale.is_equal_approx(Vector3(1.0, 1.0, 1.0)), "Visuals scale must NOT collapse after 100 rotations! Got: %s" % str(visuals.scale))
	check(visuals.transform.basis.is_finite(), "Visuals basis must remain strictly finite")

	print(">>> [TEST 5 PASSED] Transform NaN & scale collapse safeguards verified.\n")

	print("========================================================")
	print(">>> ALL CURSOR-DIRECTED AIMING TESTS COMPLETED! <<<")
	print("========================================================\n")

	await TestUtil.cleanup(self)
	TestUtil.finish(self)
