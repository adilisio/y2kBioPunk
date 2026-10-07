extends SceneTree

const TestUtil = preload("res://tests/_test_util.gd")

func check(cond: bool, msg: String) -> bool:
	return TestUtil.check(cond, msg)

func _init():
	run_tests()

func run_tests() -> void:
	print("=== STARTING GRIND TRAVERSAL & ADRENALINE SYSTEM TESTS ===")
	
	# 1. Test PlayerController instancing and State Machine
	var player = ClassDB.instantiate("PlayerController") as CharacterBody3D
	check(player != null, "Failed to instantiate PlayerController")
	TestUtil.track(player)
	
	print("[TEST 1] Testing Initial State & Adrenaline Properties...")
	check(player.get_movement_state() == 0, "Initial state must be STATE_NORMAL (0)")
	check(!player.is_grinding(), "Player must not be grinding initially")
	check(player.get_current_adrenaline() == 0.0, "Initial adrenaline must be 0")
	check(player.get_max_adrenaline() == 100.0, "Max adrenaline must be 100")
	print(" -> PASS: Initial state & adrenaline verified.")
	
	root.add_child(player)
	await process_frame
	await physics_frame

	# 2. Test Signal Emission
	print("[TEST 2] Testing adrenaline_changed signal...")
	var tracker = { "caught": false, "curr": 0.0, "max": 0.0 }
	player.adrenaline_changed.connect(func(curr, max_val):
		tracker.caught = true
		tracker.curr = curr
		tracker.max = max_val
	)
	player.set_current_adrenaline(25.0)
	check(tracker.caught, "adrenaline_changed signal was not emitted")
	check(tracker.curr == 25.0, "Emitted current adrenaline mismatch")
	check(tracker.max == 100.0, "Emitted max adrenaline mismatch")
	print(" -> PASS: adrenaline_changed signal verified.")
	
	# 3. Create a test Path3D rail
	var rail_path = Path3D.new()
	rail_path.name = "TestRail"
	var curve = Curve3D.new()
	curve.add_point(Vector3(0, 1, 0))
	curve.add_point(Vector3(0, 1, 10))
	curve.add_point(Vector3(0, 1, 20))
	rail_path.curve = curve
	TestUtil.track(rail_path)
	root.add_child(rail_path)
	
	var follower = PathFollow3D.new()
	follower.name = "PathFollow3D"
	follower.loop = false
	rail_path.add_child(follower)
	
	# 4. Test Grind Entry Requirements
	print("[TEST 3] Testing Grind Entry Gatekeeping (Skates & Speed Threshold)...")
	# Case A: Without skates equipped, grind must be rejected
	player.set_is_skating(false)
	player.set_velocity(Vector3(0, 0, 10)) # Speed = 10 m/s
	player.position = Vector3(0, 1, 5)
	var entered_no_skates = player.try_start_grind(rail_path)
	check(!entered_no_skates, "Should NOT enter grind if skates are not equipped")
	
	# Case B: With skates equipped but low speed (< 4.0 m/s), grind must be rejected
	player.set_is_skating(true)
	player.set_velocity(Vector3(0, 0, 2.0)) # Speed = 2 m/s (< 4.0 m/s threshold)
	var entered_low_speed = player.try_start_grind(rail_path)
	check(!entered_low_speed, "Should NOT enter grind if speed is below 4.0 m/s threshold")
	
	# Case C: With skates equipped and speed >= 4.0 m/s, grind MUST succeed
	player.set_velocity(Vector3(0, 0, 12.0)) # Speed = 12 m/s
	var entered_success = player.try_start_grind(rail_path)
	check(entered_success, "Must successfully enter grind with skates and >4.0 m/s velocity")
	check(player.is_grinding(), "Player is_grinding() must be true")
	check(player.get_movement_state() == 2, "Movement state must be STATE_GRINDING (2)")
	print(" -> PASS: Gatekeeping and entry conditions verified.")
	
	# 5. Test Traversal Progression & Adrenaline Accrual
	print("[TEST 4] Testing Spline Traversal & Adrenaline Generation...")
	var initial_prog = follower.progress
	var initial_adren = player.get_current_adrenaline()
	
	# Simulate 0.5s of physics process while grinding
	player.simulate_physics(0.5)
	await process_frame
	await physics_frame
	
	check(follower.progress > initial_prog, "Progress along rail must advance during physics ticks")
	check(player.get_current_adrenaline() >= initial_adren + 4.9, "Adrenaline must accrue at +10/sec while grinding")
	check(player.global_position.y >= 0.3 or player.position.y >= 0.3, "Player root must be snapped along the rail elevation")
	print(" -> PASS: Traversal movement & adrenaline accrual verified.")
	
	# 6. Test Dismount Mechanics
	print("[TEST 5] Testing Dismount Mechanics (Momentum & State Reset)...")
	# Force follower to end of rail
	follower.progress_ratio = 1.0
	follower.progress = 20.0
	player.simulate_physics(0.1)
	
	check(!player.is_grinding(), "Player must exit grinding state upon reaching the end of the curve")
	check(player.get_movement_state() == 0 or player.get_movement_state() == 3, "State must return to NORMAL or AIRBORNE (dismount hop) upon dismount")
	check(player.get_velocity().length() >= 10.0, "Exit momentum must be restored upon dismount")
	check(player.get_velocity().y > 0.0, "Dismount hop velocity must be applied")
	print(" -> PASS: Dismount mechanics and momentum restoration verified.")
	
	# 7. Test FloodedMall_Greybox Scene Structure
	print("[TEST 6] Verifying Grind Rails in FloodedMall_Greybox.tscn...")
	var mall_scene = load("res://scenes/FloodedMall_Greybox.tscn")
	check(mall_scene != null, "FloodedMall_Greybox.tscn must be loadable")
	var mall_inst = mall_scene.instantiate()
	TestUtil.track(mall_inst)
	root.add_child(mall_inst)
	await process_frame
	
	var rails_node = mall_inst.get_node_or_null("LevelGeometry/GrindRails")
	check(rails_node != null, "LevelGeometry/GrindRails node must exist in greybox")
	
	var rail_atrium = rails_node.get_node_or_null("Rail_SunkenAtriumCurved")
	check(rail_atrium != null, "Rail_SunkenAtriumCurved must exist")
	check(rail_atrium is Path3D, "Rail_SunkenAtriumCurved must be Path3D")
	check(rail_atrium.get_node_or_null("RailMesh") is CSGPolygon3D, "RailMesh CSGPolygon3D must exist")
	check(rail_atrium.get_node_or_null("GrindArea") is Area3D, "GrindArea Area3D must exist")
	var grind_area = rail_atrium.get_node_or_null("GrindArea")
	# In packed scene, GrindArea is identified by collision_layer == 4 (Layer 3: Grindable bit)
	check(grind_area.collision_layer == 4 or grind_area.is_in_group("grindable"), "GrindArea must have collision_layer 4 (Layer 3) or be in 'grindable' group")
	check(rail_atrium.get_node_or_null("PathFollow3D") is PathFollow3D, "PathFollow3D must exist on rail")
	
	var rail_mezz = rails_node.get_node_or_null("Rail_MezzanineRampHandrail")
	check(rail_mezz != null, "Rail_MezzanineRampHandrail must exist")
	check(rail_mezz is Path3D, "Rail_MezzanineRampHandrail must be Path3D")
	check(rail_mezz.get_node_or_null("GrindArea") is Area3D, "GrindArea must exist on mezzanine rail")
	print(" -> PASS: FloodedMall_Greybox Grind Rails geometry & collision verified.")
	
	print("=== ALL GRIND TRAVERSAL & ADRENALINE TESTS COMPLETED ===")
	await TestUtil.cleanup(self)
	TestUtil.finish(self)
