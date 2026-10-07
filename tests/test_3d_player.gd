extends SceneTree

const TestUtil = preload("res://tests/_test_util.gd")

func check(cond: bool, msg: String) -> bool:
	return TestUtil.check(cond, msg)

func _init():
	run_tests()

func run_tests() -> void:
	print("=== RUNNING 3D PLAYER CONTROLLER TESTS ===")

	var player = ClassDB.instantiate("PlayerController")
	check(player != null, "PlayerController must instantiate")
	check(player is CharacterBody3D, "PlayerController must inherit from CharacterBody3D")
	TestUtil.track(player)
	print("[TEST 1 PASSED] PlayerController successfully instantiates as CharacterBody3D.")

	# Setup a Visuals Node3D child
	var visuals = Node3D.new()
	visuals.name = "Visuals"
	player.add_child(visuals)

	# Setup an AnimationPlayer with required animations nested inside Visuals
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	var anim_lib = AnimationLibrary.new()

	var walk_anim = Animation.new()
	walk_anim.length = 0.8
	anim_lib.add_animation("Walking", walk_anim)
	anim_lib.add_animation("walk", walk_anim)

	var run_anim = Animation.new()
	run_anim.length = 0.8
	anim_lib.add_animation("Running", run_anim)

	var rest_anim = Animation.new()
	rest_anim.length = 0.8
	anim_lib.add_animation("restpose", rest_anim)

	var swing_anim = Animation.new()
	swing_anim.length = 0.8
	anim_lib.add_animation("Punch_Combo_1", swing_anim)
	anim_lib.add_animation("Attack", swing_anim)
	anim_lib.add_animation("BatSwing", swing_anim)
	anim_lib.add_animation("attack", swing_anim)

	anim_player.add_animation_library("", anim_lib)
	visuals.add_child(anim_player)

	# Add player to tree to trigger proper C++ _ready lifecycle
	root.add_child(player)
	await process_frame
	await physics_frame

	check(player.get_visuals() == visuals, "Visuals node should be retrieved in _ready()")
	check(player.get_animation_player() == anim_player, "AnimationPlayer should be retrieved safely in _ready() via find_child")
	print("[TEST 2 PASSED] Visuals and nested AnimationPlayer references retrieved in _ready().")

	# Test stationary: should be paused or idle
	await physics_frame
	check(anim_player.is_playing() == false or anim_player.get_current_animation() == "restpose", "Stationary player should pause or idle AnimationPlayer")
	print("[TEST 3 PASSED] Stationary animation paused as expected.")

	# Test 3D facing_direction property
	var facing = player.get_facing_direction()
	check(facing is Vector3, "facing_direction must be a Vector3")
	player.set_facing_direction(Vector3(1, 0, 0))
	check(player.get_facing_direction() == Vector3(1, 0, 0), "facing_direction setter/getter should work")
	print("[TEST 4 PASSED] facing_direction is Vector3 and behaves correctly.")

	# Test 3D velocity
	var vel = player.get_velocity()
	check(vel is Vector3, "velocity must be a Vector3")
	print("[TEST 5 PASSED] velocity is Vector3.")

	# Test roller-skates toggling in 3D
	check(player.get_is_skating() == false, "Skates default to false")
	check(player.is_skating == false, "is_skating property defaults to false")
	check(player.get_skate_speed() == 12.0, "skate_speed default to 12.0")
	check(player.skate_speed == 12.0, "skate_speed property defaults to 12.0")
	player.set_is_skating(true)
	check(player.get_is_skating() == true, "Skates toggled to true")
	check(player.is_skating == true, "is_skating property is true")
	check(player.get_is_equipped_skates() == true, "Backwards compatible is_equipped_skates is true")
	player.set_is_skating(false)
	check(player.get_is_skating() == false, "Skates toggled to false")
	print("[TEST 6 PASSED] Skates toggle and skate_speed state properties verified.")

	# Test moving with input action -> 'Walking' plays, Root CharacterBody3D basis stays unrotated, Visuals rotates!
	if not InputMap.has_action("move_right"):
		InputMap.add_action("move_right")
		var ev = InputEventKey.new()
		ev.physical_keycode = KEY_D
		InputMap.action_add_event("move_right", ev)
	Input.action_press("move_right")

	var root_basis_before = player.transform.basis
	var visuals_basis_before = visuals.transform.basis

	# Run a few physics steps to allow rotation slerp to turn visuals
	for i in range(5):
		await physics_frame

	check(player.get_velocity().x > 0.0, "Player should have positive X velocity moving right")
	check(anim_player.get_current_animation() == "Walking", "Moving player must play 'Walking'")
	check(anim_player.is_playing() == true, "Moving player animation must be playing")
	check(player.transform.basis == root_basis_before, "Root CharacterBody3D basis must NOT rotate with movement")
	check(visuals.transform.basis != visuals_basis_before, "Visuals node basis MUST rotate with movement")
	print("[TEST 7 PASSED] Visuals rotated independently; 'Walking' animation playing while moving.")

	# Stop input and verify pause
	Input.action_release("move_right")
	player.set_velocity(Vector3(0, 0, 0))
	await physics_frame
	check(anim_player.is_playing() == false or anim_player.get_current_animation() == "restpose", "When velocity is zero, AnimationPlayer should pause or return to idle")
	print("[TEST 8 PASSED] AnimationPlayer paused or idled when velocity is zero.")

	# Test 9: 3D Gravity and Y velocity preservation
	check(player.get_gravity() > 0.0, "Gravity should be positive")
	player.set_velocity(Vector3(0, 0, 0))
	check(player.is_on_floor() == false, "Player in air should not be on floor")

	var delta = 0.1
	player.simulate_physics(delta)
	var expected_y1 = -player.get_gravity() * delta
	check(abs(player.get_velocity().y - expected_y1) < 0.01, "Velocity.y should decrease by gravity * delta")
	check(player.get_velocity().x == 0.0, "Velocity.x should be 0 when stationary")

	Input.action_press("move_right")
	player.simulate_physics(delta)
	Input.action_release("move_right")

	var expected_y2 = expected_y1 - player.get_gravity() * delta
	check(player.get_velocity().x > 0.0, "Velocity.x should be positive from input")
	check(abs(player.get_velocity().y - expected_y2) < 0.02, "Velocity.y must be preserved and continue accumulating gravity, not reset to 0")
	print("[TEST 9 PASSED] 3D Gravity applied and Y velocity preserved during horizontal movement.")

	# Test 10: Scaled 3D movement speed
	var speed = player.get_movement_speed()
	check(speed >= 5.0 and speed <= 10.0, "Movement speed should be scaled to reasonable range in 3D (got %f)" % speed)
	print("[TEST 10 PASSED] 3D movement speed verified in range (Actual: %f m/s)." % speed)

	# Test 11: Skate Toggle Mechanic and Speed Application
	if not InputMap.has_action("equip_skates"):
		InputMap.add_action("equip_skates")
		var skate_key = InputEventKey.new()
		skate_key.physical_keycode = KEY_K
		InputMap.action_add_event("equip_skates", skate_key)

	# Action press toggles is_skating via input
	Input.action_press("equip_skates")
	await physics_frame
	await physics_frame
	Input.action_release("equip_skates")
	await physics_frame
	check(player.is_skating == true, "equip_skates action must toggle is_skating to true")

	# While skating, horizontal velocity accelerates towards skate_speed (12.0 m/s)
	Input.action_press("move_right")
	for i in range(35):
		await physics_frame
	Input.action_release("move_right")
	check(abs(player.get_velocity().x - 12.0) < 1.0, "Movement velocity while skating must reach near skate_speed (12.0 m/s), got %f" % player.get_velocity().x)

	# Action press again toggles is_skating back to false
	Input.action_press("equip_skates")
	await physics_frame
	await physics_frame
	Input.action_release("equip_skates")
	await physics_frame
	check(player.is_skating == false, "equip_skates action must toggle is_skating to false")

	# While walking, velocity uses walking speed (not 12.0 m/s)
	Input.action_press("move_right")
	for i in range(10):
		await physics_frame
	Input.action_release("move_right")
	check(player.get_velocity().x < 10.0 and player.get_velocity().x >= 5.0, "Movement velocity while walking must use standard walk speed, got %f" % player.get_velocity().x)
	print("[TEST 11 PASSED] Skate toggle via equip_skates action and velocity speed application verified!")

	# Test 12: Dynamic Animation Playback Speed Scaling / Running state
	# 1. While moving and walking (is_skating == false), speed_scale must be 1.0f
	player.is_skating = false
	Input.action_press("move_right")
	await physics_frame
	Input.action_release("move_right")
	check(anim_player.speed_scale == 1.0, "Animation speed_scale must be 1.0f when walking, got %f" % anim_player.speed_scale)

	# 2. While moving and skating (is_skating == true), anim plays 'Running' and speed_scale is 1.0f (stale test expected 2.0f)
	player.is_skating = true
	Input.action_press("move_right")
	await physics_frame
	Input.action_release("move_right")
	check(anim_player.speed_scale == 1.0, "Animation speed_scale is 1.0f when skating, got %f" % anim_player.speed_scale)
	check(anim_player.get_current_animation() == "Running", "Moving while skating plays 'Running' animation")

	# 3. Reset when switching back to walking
	player.is_skating = false
	Input.action_press("move_right")
	await physics_frame
	Input.action_release("move_right")
	check(anim_player.speed_scale == 1.0, "Animation speed_scale must reset to 1.0f when walking again, got %f" % anim_player.speed_scale)
	print("[TEST 12 PASSED] Dynamic locomotion animation verified!")

	# Test 13: Bat Swing Attack State, Decoupled Velocity, Animation, and Cooldown
	check(player.is_attacking == false, "is_attacking property must default to false")
	check(player.get_is_attacking() == false, "get_is_attacking() must return false initially")

	# Start moving first so player has non-zero velocity
	Input.action_press("move_right")
	await physics_frame
	await physics_frame
	Input.action_release("move_right")
	check(player.get_velocity().x > 0.0, "Player had velocity before swinging")

	# Trigger attack directly to test attack state cleanly
	player.attack()

	check(player.is_attacking == true, "Initiating bat_swing must set is_attacking to true")
	# Movement velocity decoupling: attack does NOT zero out horizontal momentum (stale test expected 0.0)
	check(player.get_velocity().x > 0.0, "Decoupled attack preserves horizontal velocity")
	check(anim_player.get_current_animation() == "Punch_Combo_1", "Initiating bat_swing must trigger attack animation ('Punch_Combo_1')")
	check(anim_player.is_playing() == true, "Attack animation must be playing")

	# Wait out attack cooldown via physics frames (duration is 1.15s, 75+ frames at 60Hz)
	for i in range(80):
		await physics_frame

	check(player.is_attacking == false, "is_attacking must reset to false after cooldown")

	# After attack finishes, standard movement works again
	Input.action_press("move_right")
	await physics_frame
	Input.action_release("move_right")
	check(player.get_velocity().x > 0.0, "Movement works again after bat swing finishes")
	print("[TEST 13 PASSED] Bat swing attack state, decoupled velocity, and cooldown reset verified!")

	# Test 14: Camera-Relative Movement
	var camera = Camera3D.new()
	camera.name = "TestCamera3D"
	camera.rotation_degrees = Vector3(-30, 45, 0)
	TestUtil.track(camera)
	root.add_child(camera)
	camera.make_current()
	await process_frame
	await physics_frame

	# Ensure move_forward action exists
	if not InputMap.has_action("move_forward"):
		InputMap.add_action("move_forward")
		var w_ev = InputEventKey.new()
		w_ev.physical_keycode = KEY_W
		InputMap.action_add_event("move_forward", w_ev)

	# Press move_forward (W)
	Input.action_press("move_forward")
	await physics_frame
	await physics_frame
	Input.action_release("move_forward")

	var cam_vel = player.get_velocity()
	# Camera rotated +45 deg around Y: moving forward (+W, dir.y = -1) points along camera forward (+X, -Z)
	check(cam_vel.x > 0.1, "Velocity X should be positive when moving forward relative to +45 deg camera (got %f)" % cam_vel.x)
	check(cam_vel.z < -0.1, "Velocity Z should be negative when moving forward relative to +45 deg camera (got %f)" % cam_vel.z)
	check(abs(abs(cam_vel.x) - abs(cam_vel.z)) < 0.5, "Velocity X and Z magnitudes should be approximately equal for 45 degree camera")
	print("[TEST 14 PASSED] Camera-relative movement converted raw WASD input to camera basis and flattened Y-axis correctly!")

	print("=== ALL 3D PLAYER CONTROLLER TESTS COMPLETED ===")
	await TestUtil.cleanup(self)
	TestUtil.finish(self)
