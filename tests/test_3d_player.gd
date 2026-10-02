extends SceneTree

func _init():
	print("=== RUNNING 3D PLAYER CONTROLLER TESTS ===")

	var player = ClassDB.instantiate("PlayerController")
	assert(player != null, "PlayerController must instantiate")
	assert(player is CharacterBody3D, "PlayerController must inherit from CharacterBody3D")
	print("[TEST 1 PASSED] PlayerController successfully instantiates as CharacterBody3D.")

	# Setup a Visuals Node3D child
	var visuals = Node3D.new()
	visuals.name = "Visuals"
	player.add_child(visuals)

	# Setup an AnimationPlayer with 'Walking' and 'walk' animations nested inside Visuals
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	var anim_lib = AnimationLibrary.new()
	
	var walk_anim = Animation.new()
	walk_anim.length = 0.8
	anim_lib.add_animation("Walking", walk_anim)
	anim_lib.add_animation("walk", walk_anim)

	var swing_anim = Animation.new()
	swing_anim.length = 0.8
	anim_lib.add_animation("Punch_Combo_1", swing_anim)
	anim_lib.add_animation("Attack", swing_anim)
	anim_lib.add_animation("BatSwing", swing_anim)
	anim_lib.add_animation("attack", swing_anim)

	anim_player.add_animation_library("", anim_lib)
	visuals.add_child(anim_player)

	# Call _ready
	player._ready()
	assert(player.get_visuals() == visuals, "Visuals node should be retrieved in _ready()")
	assert(player.get_animation_player() == anim_player, "AnimationPlayer should be retrieved safely in _ready() via find_child")
	print("[TEST 2 PASSED] Visuals and nested AnimationPlayer references retrieved in _ready().")

	# Test stationary: should be paused
	player._physics_process(0.016)
	assert(anim_player.is_playing() == false, "Stationary player should pause AnimationPlayer to freeze character in place")
	print("[TEST 3 PASSED] Stationary animation paused as expected.")

	# Test 3D facing_direction property
	var facing = player.get_facing_direction()
	assert(facing is Vector3, "facing_direction must be a Vector3")
	player.set_facing_direction(Vector3(1, 0, 0))
	assert(player.get_facing_direction() == Vector3(1, 0, 0), "facing_direction setter/getter should work")
	print("[TEST 4 PASSED] facing_direction is Vector3 and behaves correctly.")

	# Test 3D velocity
	var vel = player.get_velocity()
	assert(vel is Vector3, "velocity must be a Vector3")
	print("[TEST 5 PASSED] velocity is Vector3.")

	# Test roller-skates toggling in 3D
	assert(player.get_is_skating() == false, "Skates default to false")
	assert(player.is_skating == false, "is_skating property defaults to false")
	assert(player.get_skate_speed() == 12.0, "skate_speed default to 12.0")
	assert(player.skate_speed == 12.0, "skate_speed property defaults to 12.0")
	player.set_is_skating(true)
	assert(player.get_is_skating() == true, "Skates toggled to true")
	assert(player.is_skating == true, "is_skating property is true")
	assert(player.get_is_equipped_skates() == true, "Backwards compatible is_equipped_skates is true")
	player.set_is_skating(false)
	assert(player.get_is_skating() == false, "Skates toggled to false")
	print("[TEST 6 PASSED] Skates toggle and skate_speed state properties verified.")

	# Test moving with input action -> 'Walking' plays, Root CharacterBody3D basis stays unrotated, Visuals rotates!
	InputMap.add_action("move_right")
	var ev = InputEventKey.new()
	ev.physical_keycode = KEY_D
	InputMap.action_add_event("move_right", ev)
	Input.action_press("move_right")

	var root_basis_before = player.transform.basis
	var visuals_basis_before = visuals.transform.basis

	# Run a few physics steps to allow rotation slerp to turn visuals
	for i in range(5):
		player._physics_process(0.016)

	assert(player.get_velocity().x > 0.0, "Player should have positive X velocity moving right")
	assert(anim_player.get_current_animation() == "Walking", "Moving player must play 'Walking'")
	assert(anim_player.is_playing() == true, "Moving player animation must be playing")
	assert(player.transform.basis == root_basis_before, "Root CharacterBody3D basis must NOT rotate with movement")
	assert(visuals.transform.basis != visuals_basis_before, "Visuals node basis MUST rotate with movement")
	print("[TEST 7 PASSED] Visuals rotated independently; 'Walking' animation playing while moving.")

	# Stop input and verify pause
	Input.action_release("move_right")
	player.set_velocity(Vector3(0, 0, 0))
	player._physics_process(0.016)
	assert(anim_player.is_playing() == false, "When velocity is zero, AnimationPlayer must pause to freeze character")
	print("[TEST 8 PASSED] AnimationPlayer paused when velocity is zero.")

	# Test 9: 3D Gravity and Y velocity preservation
	assert(player.get_gravity() > 0.0, "Gravity should be positive")
	player.set_velocity(Vector3(0, 0, 0))
	assert(player.is_on_floor() == false, "Player in air should not be on floor")

	var delta = 0.1
	player._physics_process(delta)
	var expected_y1 = -player.get_gravity() * delta
	assert(abs(player.get_velocity().y - expected_y1) < 0.01, "Velocity.y should decrease by gravity * delta")
	assert(player.get_velocity().x == 0.0, "Velocity.x should be 0 when stationary")

	Input.action_press("move_right")
	player._physics_process(delta)
	Input.action_release("move_right")

	var expected_y2 = expected_y1 - player.get_gravity() * delta
	assert(player.get_velocity().x > 0.0, "Velocity.x should be positive from input")
	assert(abs(player.get_velocity().y - expected_y2) < 0.02, "Velocity.y must be preserved and continue accumulating gravity, not reset to 0")
	print("[TEST 9 PASSED] 3D Gravity applied and Y velocity preserved during horizontal movement.")

	# Test 10: Scaled 3D movement speed
	var speed = player.get_movement_speed()
	assert(speed >= 5.0 and speed <= 8.5, "Movement speed should be scaled down to 5.0-8.5 m/s range in 3D (got %f)" % speed)
	print("[TEST 10 PASSED] 3D movement speed verified in 5.0 - 8.5 m/s range (Actual: %f m/s)." % speed)

	# Test 11: Skate Toggle Mechanic and Speed Application
	if not InputMap.has_action("equip_skates"):
		InputMap.add_action("equip_skates")
		var skate_key = InputEventKey.new()
		skate_key.physical_keycode = KEY_K
		InputMap.action_add_event("equip_skates", skate_key)

	# Action press toggles is_skating
	Input.action_press("equip_skates")
	player._physics_process(0.016)
	Input.action_release("equip_skates")
	assert(player.is_skating == true, "equip_skates action must toggle is_skating to true")

	# While skating, horizontal velocity applies skate_speed (12.0 m/s)
	Input.action_press("move_right")
	player._physics_process(0.016)
	Input.action_release("move_right")
	assert(abs(player.get_velocity().x - 12.0) < 0.01, "Movement velocity while skating must use skate_speed (12.0 m/s), got %f" % player.get_velocity().x)

	# Action press again toggles is_skating back to false
	Input.action_press("equip_skates")
	player._physics_process(0.016)
	Input.action_release("equip_skates")
	assert(player.is_skating == false, "equip_skates action must toggle is_skating to false")

	# While walking, velocity uses walking speed (not 12.0 m/s)
	Input.action_press("move_right")
	player._physics_process(0.016)
	Input.action_release("move_right")
	assert(player.get_velocity().x < 10.0 and player.get_velocity().x >= 5.0, "Movement velocity while walking must use standard walk speed, got %f" % player.get_velocity().x)
	print("[TEST 11 PASSED] Skate toggle via equip_skates action and velocity speed application verified!")

	# Test 12: Dynamic Animation Playback Speed Scaling
	# 1. While moving and walking (is_skating == false), speed_scale must be 1.0f
	player.is_skating = false
	Input.action_press("move_right")
	player._physics_process(0.016)
	Input.action_release("move_right")
	assert(anim_player.speed_scale == 1.0, "Animation speed_scale must be 1.0f when walking, got %f" % anim_player.speed_scale)

	# 2. While moving and skating (is_skating == true), speed_scale must be 2.0f
	player.is_skating = true
	Input.action_press("move_right")
	player._physics_process(0.016)
	Input.action_release("move_right")
	assert(anim_player.speed_scale == 2.0, "Animation speed_scale must be 2.0f when skating, got %f" % anim_player.speed_scale)

	# 3. Reset when switching back to walking
	player.is_skating = false
	Input.action_press("move_right")
	player._physics_process(0.016)
	Input.action_release("move_right")
	assert(anim_player.speed_scale == 1.0, "Animation speed_scale must reset to 1.0f when walking again, got %f" % anim_player.speed_scale)
	print("[TEST 12 PASSED] Dynamic animation playback speed scaling (2.0f skating, 1.0f walking) verified!")

	# Test 13: Bat Swing Attack State, Velocity Lock, Animation, and Cooldown
	assert(player.is_attacking == false, "is_attacking property must default to false")
	assert(player.get_is_attacking() == false, "get_is_attacking() must return false initially")

	if not InputMap.has_action("bat_swing"):
		InputMap.add_action("bat_swing")
		var space_ev = InputEventKey.new()
		space_ev.physical_keycode = KEY_SPACE
		InputMap.action_add_event("bat_swing", space_ev)

	# Start moving first so player has non-zero velocity
	Input.action_press("move_right")
	player._physics_process(0.016)
	Input.action_release("move_right")
	assert(player.get_velocity().x > 0.0, "Player had velocity before swinging")

	# Trigger bat_swing
	Input.action_press("bat_swing")
	player._physics_process(0.016)
	Input.action_release("bat_swing")

	assert(player.is_attacking == true, "Initiating bat_swing must set is_attacking to true")
	assert(player.get_velocity().x == 0.0, "Initiating bat_swing must set movement velocity to 0")
	assert(anim_player.get_current_animation() == "Punch_Combo_1", "Initiating bat_swing must trigger attack animation ('Punch_Combo_1')")
	assert(anim_player.is_playing() == true, "Attack animation must be playing")

	# While is_attacking is true, player cannot run with WASD input
	Input.action_press("move_right")
	player._physics_process(0.016)
	Input.action_release("move_right")
	assert(player.is_attacking == true, "Player should still be in attacking state")
	assert(player.get_velocity().x == 0.0, "Movement velocity must stay 0 while swinging even if WASD is pressed")

	# At 0.5s (10 steps of 0.05s = 0.5s), cooldown is NOT yet elapsed (0.8s required)
	for i in range(10):
		player._physics_process(0.05)
	assert(player.is_attacking == true, "is_attacking must still be true before 0.8s has elapsed")

	# Step forward another 8 steps of 0.05s = 0.4s (total 0.9s > 0.8s) -> resets
	for i in range(8):
		player._physics_process(0.05)

	assert(player.is_attacking == false, "is_attacking must reset to false after 0.8s cooldown")
	assert(anim_player.is_playing() == false, "When resetting stationary state, AnimationPlayer must pause()")

	# After attack finishes, standard movement works again
	Input.action_press("move_right")
	player._physics_process(0.016)
	Input.action_release("move_right")
	assert(player.get_velocity().x > 0.0, "Movement works again after bat swing finishes")
	print("[TEST 13 PASSED] Bat swing attack state, velocity stop, 'Attack' animation trigger, and 0.8s cooldown reset verified!")

	# Test 14: Camera-Relative Movement
	root.add_child(player)
	var camera = Camera3D.new()
	camera.name = "TestCamera3D"
	camera.rotation_degrees = Vector3(-30, 45, 0)
	root.add_child(camera)
	camera.current = true

	# Ensure move_forward action exists
	if not InputMap.has_action("move_forward"):
		InputMap.add_action("move_forward")
		var w_ev = InputEventKey.new()
		w_ev.physical_keycode = KEY_W
		InputMap.action_add_event("move_forward", w_ev)

	# Press move_forward (W)
	Input.action_press("move_forward")
	player._physics_process(0.016)
	Input.action_release("move_forward")

	var cam_vel = player.get_velocity()
	# In world space, moving forward relative to a camera rotated 45 deg around Y means both X and Z are negative
	assert(cam_vel.x < -0.1, "Velocity X should be negative when moving forward relative to 45 deg camera (got %f)" % cam_vel.x)
	assert(cam_vel.z < -0.1, "Velocity Z should be negative when moving forward relative to 45 deg camera (got %f)" % cam_vel.z)
	# X and Z magnitudes should be roughly equal (sin(45) == cos(45))
	assert(abs(abs(cam_vel.x) - abs(cam_vel.z)) < 0.2, "Velocity X and Z should be approximately equal for 45 degree camera")
	print("[TEST 14 PASSED] Camera-relative movement converted raw WASD input to camera basis and flattened Y-axis correctly!")

	print("=== ALL 3D PLAYER CONTROLLER TESTS PASSED SUCCESSFULLY! ===")
	quit()
