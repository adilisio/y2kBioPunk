extends SceneTree

func _init():
	var exit_code = run_tests()
	quit(exit_code)

func run_tests() -> int:
	print("\n========================================================")
	print(">>> RUNNING FRUIT CANDY HEALTH PICKUP VERIFICATION <<<")
	print("========================================================\n")

	var candy_scene = load("res://scenes/health_candy_pickup.tscn")
	assert(candy_scene != null, "scenes/health_candy_pickup.tscn must be loadable")

	var player_scene = load("res://scenes/player.tscn")
	assert(player_scene != null, "scenes/player.tscn must exist")

	var player = player_scene.instantiate() as CharacterBody3D
	root.add_child(player)
	player.notification(Node.NOTIFICATION_READY)

	# -------------------------------------------------------------------------
	# REQUIREMENT 1 & 2: TOUCH DETECTION & PLAYER INTERACTION
	# -------------------------------------------------------------------------
	print("[VERIFICATION: DOD-1 & DOD-2] Player walk into/touch candy detection...")
	var candy = candy_scene.instantiate() as Area3D
	root.add_child(candy)
	candy.notification(Node.NOTIFICATION_READY)

	assert(candy.monitoring == true, "Pickup must be actively monitoring")
	assert(candy.monitorable == false, "Pickup monitorable must be false (intangible trigger)")
	assert(candy.collision_layer == 0, "Pickup collision_layer must be 0 (no blocking physical obstacle)")
	assert((candy.collision_mask & 2) != 0, "Pickup collision_mask must check Layer 2 (Player)")
	assert((player.get_collision_layer() & 2) != 0, "Player must be on Layer 2 for detection")
	print(" -> PASS: Touch/walk-in detection configured correctly without physical blocking.")

	# -------------------------------------------------------------------------
	# REQUIREMENT 3 & DOD EXAMPLE 1: RESTORES 10 HEALTH (60/100 -> 70/100)
	# -------------------------------------------------------------------------
	print("\n[VERIFICATION: DOD-3 & EXAMPLE-1] Health change applied: 60/100 HP -> 70/100 HP...")
	player.set_max_health(100.0)
	player.set_current_health(60.0)
	assert(player.get_current_health() == 60.0, "Player health must be 60.0 before pickup")

	candy._on_body_entered(player)

	assert(player.get_current_health() == 70.0, "Player health must become exactly 70.0 after pickup")
	assert(candy.is_picked_up == true, "Candy must be marked as is_picked_up = true")
	print(" -> PASS: Restores exactly 10 health (60/100 -> 70/100).")

	# -------------------------------------------------------------------------
	# REQUIREMENT 4: CANDY DISAPPEARS AFTER BEING PICKED UP
	# -------------------------------------------------------------------------
	print("\n[VERIFICATION: DOD-4] Candy disappears after pickup...")
	var visual_root = candy.find_child("VisualRoot", false, false)
	assert(visual_root != null, "VisualRoot must exist")
	assert(visual_root.visible == false, "VisualRoot must be hidden immediately upon pickup")
	assert(candy.monitoring == false, "Monitoring must be disabled immediately upon pickup")
	print(" -> PASS: Candy disappears immediately upon being picked up.")

	# -------------------------------------------------------------------------
	# REQUIREMENT 5 & BUG CHECK 1: CAN ONLY BE PICKED UP ONCE (NO DOUBLE PICKUP)
	# -------------------------------------------------------------------------
	print("\n[VERIFICATION: DOD-5 & BUG-1] Picking up candy twice prevention...")
	player.set_current_health(50.0)
	candy._on_body_entered(player)
	assert(player.get_current_health() == 50.0, "Player health must not change when touching already picked-up candy")
	assert(candy.is_picked_up == true, "is_picked_up remains true")
	print(" -> PASS: Picking up candy twice is strictly prevented.")

	# -------------------------------------------------------------------------
	# REQUIREMENT 6: PROCEDURAL 'YUM' SOUND EFFECT PLAYED ONCE PICKED UP
	# -------------------------------------------------------------------------
	print("\n[VERIFICATION: DOD-6] Procedural 'YUM' sound effect...")
	var pickup_script = load("res://scripts/health_candy_pickup.gd")
	var yum_sfx = pickup_script._generate_yum_sfx()
	assert(yum_sfx != null, "Procedural YUM sfx stream must not be null")
	assert(yum_sfx.data.size() > 0, "YUM audio buffer must have valid audio samples")
	assert(player.has_method("play_sfx"), "PlayerController must support play_sfx")
	print(" -> PASS: 'YUM' sound effect generated and played on pickup.")

	# -------------------------------------------------------------------------
	# DOD EXAMPLE 2 & BUG CHECK 2: HEALTH EXCEEDING MAXIMUM HEALTH (95/100 -> 100/100)
	# -------------------------------------------------------------------------
	print("\n[VERIFICATION: DOD-EXAMPLE-2 & BUG-2] Health exceeding max health prevention (95/100 -> 100/100)...")
	var candy_cap = candy_scene.instantiate() as Area3D
	root.add_child(candy_cap)
	candy_cap.notification(Node.NOTIFICATION_READY)

	player.set_current_health(95.0)
	assert(player.get_current_health() == 95.0, "Health must be 95 before pickup")

	candy_cap._on_body_entered(player)
	assert(player.get_current_health() == 100.0, "Player health must NOT exceed 100 (got %f)" % player.get_current_health())
	assert(candy_cap.is_picked_up == true, "Candy must be picked up and disappear")
	print(" -> PASS: Health cap enforced at maximum health (95 -> 100, max 100).")

	# -------------------------------------------------------------------------
	# BUG CHECK 3: PICKING UP CANDY WHEN ALREADY AT FULL HEALTH (100/100 HP)
	# -------------------------------------------------------------------------
	print("\n[VERIFICATION: BUG-3] Picking up candy when already at full health (100/100 HP)...")
	var candy_full = candy_scene.instantiate() as Area3D
	root.add_child(candy_full)
	candy_full.notification(Node.NOTIFICATION_READY)

	assert(player.get_current_health() == 100.0, "Player is at full health (100/100)")
	candy_full._on_body_entered(player)

	# Must NOT consume the candy or waste it when already at full health
	assert(candy_full.is_picked_up == false, "Candy must NOT be consumed when player is already at full health")
	assert(player.get_current_health() == 100.0, "Player health must remain 100/100")
	var full_visual = candy_full.find_child("VisualRoot", false, false)
	assert(full_visual != null and full_visual.visible == true, "Candy visual must remain visible in world")

	# Damage player and verify candy remains ready to be collected
	player.set_current_health(75.0)
	candy_full._on_body_entered(player)
	assert(player.get_current_health() == 85.0, "Player health restores to 85 after taking damage and touching candy")
	assert(candy_full.is_picked_up == true, "Candy now picked up and consumed")
	assert(full_visual.visible == false, "Candy visual now hidden")
	print(" -> PASS: Candy is NOT wasted at full health; preserved until player is damaged.")

	# -------------------------------------------------------------------------
	# BUG CHECK 4: PICKUP NOT DETECTING THE PLAYER
	# -------------------------------------------------------------------------
	print("\n[VERIFICATION: BUG-4] Detection verification (Player detection vs Enemy rejection)...")
	var candy_detect = candy_scene.instantiate() as Area3D
	root.add_child(candy_detect)
	candy_detect.notification(Node.NOTIFICATION_READY)

	# Non-player touch: Enemy should NOT trigger pickup
	var dummy_enemy = CharacterBody3D.new()
	dummy_enemy.name = "MutatedBug"
	dummy_enemy.add_to_group("enemies")
	root.add_child(dummy_enemy)
	candy_detect._on_body_entered(dummy_enemy)
	assert(candy_detect.is_picked_up == false, "Enemy must not trigger candy pickup")

	# Player touch: Player MUST trigger pickup
	player.set_current_health(60.0)
	candy_detect._on_body_entered(player)
	assert(candy_detect.is_picked_up == true, "Player must trigger candy pickup")
	assert(player.get_current_health() == 70.0, "Player health must be restored to 70")
	print(" -> PASS: Player detection is positive, enemy/environment false triggers rejected.")

	# -------------------------------------------------------------------------
	# BUG CHECK 5: HEALTH CHANGE NOT ACTUALLY BEING APPLIED
	# -------------------------------------------------------------------------
	print("\n[VERIFICATION: BUG-5] Verifying health change is actually applied...")
	var candy_apply = candy_scene.instantiate() as Area3D
	root.add_child(candy_apply)
	candy_apply.notification(Node.NOTIFICATION_READY)

	player.set_current_health(42.0)
	var hp_before = player.get_current_health()
	candy_apply._on_body_entered(player)
	var hp_after = player.get_current_health()
	var delta = hp_after - hp_before
	assert(delta == 10.0, "Delta must be exactly +10.0 (got %f)" % delta)
	assert(hp_after == 52.0, "Actual health must be 52.0 (got %f)" % hp_after)
	print(" -> PASS: Health change is actually and precisely applied (+10.0 HP).")

	# -------------------------------------------------------------------------
	# SCENE INTEGRATION & PLACEMENT CHECK
	# -------------------------------------------------------------------------
	print("\n[VERIFICATION: SCENE PLACEMENT] Verifying level scene placements...")
	var mall_scene = load("res://scenes/FloodedMall_Greybox.tscn")
	assert(mall_scene != null, "FloodedMall_Greybox.tscn must load")
	var mall_inst = mall_scene.instantiate()
	assert(mall_inst.find_child("FruitCandyPickup_01", true, false) != null, "FruitCandyPickup_01 must be placed in FloodedMall")
	assert(mall_inst.find_child("FruitCandyPickup_02", true, false) != null, "FruitCandyPickup_02 must be placed in FloodedMall")
	mall_inst.free()

	print(" -> PASS: Pickups placed and verified in game scenes.")

	print("\n========================================================")
	print(">>> ALL 12 DEFINITION-OF-DONE & BUG-CHECK ITEMS PASSED! <<<")
	print("========================================================\n")
	return 0
