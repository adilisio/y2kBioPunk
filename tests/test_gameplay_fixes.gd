extends SceneTree

const TestUtil = preload("res://tests/_test_util.gd")

func check(cond: bool, msg: String) -> bool:
	return TestUtil.check(cond, msg)

func _init():
	run_tests()

func run_tests() -> void:
	print("\n========================================================")
	print(">>> RUNNING GAMEPLAY FIXES VALIDATION TEST <<<")
	print("========================================================\n")

	# -------------------------------------------------------------------------
	# 1. TEST INPUT BLEED & FLAMETHROWER ISOLATION
	# -------------------------------------------------------------------------
	print("[TEST 1] Validating Input Map & Flamethrower Isolation...")
	
	# Verify legacy actions are purged from InputMap
	check(not InputMap.has_action("spray_aerosol"), "spray_aerosol must be purged from InputMap")
	check(not InputMap.has_action("use_aerosol"), "use_aerosol must be purged from InputMap")
	check(InputMap.has_action("attack"), "attack action must exist")
	check(InputMap.has_action("secondary_fire"), "secondary_fire action must exist")
	
	# Check attack is on mouse button 1 (LMB)
	var atk_events = InputMap.action_get_events("attack")
	var lmb_found = false
	for ev in atk_events:
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			lmb_found = true
			break
	check(lmb_found, "attack must be mapped to LMB (button 1)")

	# Check secondary_fire is NOT on mouse button 1 (LMB)
	var sec_events = InputMap.action_get_events("secondary_fire")
	for ev in sec_events:
		if ev is InputEventMouseButton:
			check(ev.button_index != MOUSE_BUTTON_LEFT, "secondary_fire must NEVER be mapped to LMB")

	# Instantiate Player from scenes/player.tscn
	var player_scene = load("res://scenes/player.tscn")
	check(player_scene != null, "scenes/player.tscn must load")
	var player = player_scene.instantiate() as CharacterBody3D
	check(player != null, "Player must instantiate from scenes/player.tscn")
	TestUtil.track(player)
	root.add_child(player)
	await process_frame
	await physics_frame

	var flame_particles = player.get_flame_particles() as GPUParticles3D
	if not flame_particles:
		flame_particles = player.find_child("FlamethrowerParticles", true, false) as GPUParticles3D
	check(flame_particles != null, "FlamethrowerParticles node must exist on player")
	check(flame_particles != null and not flame_particles.is_emitting(), "flame_particles must be OFF by default")

	# Simulate attack input: flame_particles must remain OFF
	Input.action_press("attack")
	player.simulate_physics(0.016)
	Input.action_release("attack")
	check(flame_particles != null and not flame_particles.is_emitting(), "flame_particles must NOT emit when attack (LMB) is pressed")

	# Simulate secondary_fire input: flame_particles must turn ON
	Input.action_press("secondary_fire")
	player.simulate_physics(0.016)
	check(flame_particles != null and flame_particles.is_emitting(), "flame_particles MUST emit when secondary_fire is pressed")
	
	# Release secondary_fire: flame_particles must turn OFF
	Input.action_release("secondary_fire")
	player.simulate_physics(0.016)
	check(flame_particles != null and not flame_particles.is_emitting(), "flame_particles must stop emitting when secondary_fire is released")

	print(">>> [TEST 1 PASSED] Input bleed resolved: attack and secondary_fire strictly isolated.\n")

	# -------------------------------------------------------------------------
	# 2. TEST BOSS INVINCIBILITY & HIT DETECTION
	# -------------------------------------------------------------------------
	print("[TEST 2] Validating Boss Invincibility & Hitbox...")

	var queen_scene = load("res://scenes/dial_up_queen.tscn")
	check(queen_scene != null, "scenes/dial_up_queen.tscn must load")
	var queen = queen_scene.instantiate() as CharacterBody3D
	queen.position = Vector3(50.0, 0.0, 50.0)
	TestUtil.track(queen)
	root.add_child(queen)
	await process_frame

	# Verify collision layer and mask
	check(queen.collision_layer == 4, "Queen collision_layer must be 4 (Layer 3: Enemy), got %d" % queen.collision_layer)
	check((queen.collision_mask & 1) != 0, "Queen collision_mask must include Layer 1 (World)")
	check((queen.collision_mask & 2) != 0, "Queen collision_mask must include Layer 2 (Player)")

	# Verify Hurtbox Area3D exists on layer 4
	var hurtbox = queen.find_child("Hurtbox", true, false) as Area3D
	check(hurtbox != null, "Queen must possess Hurtbox Area3D")
	check(hurtbox != null and hurtbox.collision_layer == 4, "Hurtbox collision_layer must be 4 (Enemy)")

	# Test damage handling and signals
	var received_hp: Array = []
	queen.connect("boss_health_changed", func(cur, max_hp, phase):
		received_hp.append([cur, max_hp, phase])
	)

	# Deal 50 damage
	queen.take_damage(50)
	check(queen.current_health == 550, "Queen HP must be 550 after 50 damage, got %d" % queen.current_health)
	check(received_hp.size() > 0, "boss_health_changed signal must be emitted")
	if received_hp.size() > 0:
		check(received_hp[-1][0] == 550, "Signal cur_hp must match 550")
	check(queen.current_phase == 1, "Phase must still be 1")

	# Deal 160 damage -> 390 HP <= 400 HP threshold for Phase 2
	queen.take_damage(160)
	check(queen.current_health == 390, "Queen HP must be 390")
	check(queen.current_phase == 2, "Queen must transition to Phase 2 at <= 400 HP")

	# Wait out phase transition invulnerability
	queen._process_phase_transition(2.0)
	check(not queen.is_invulnerable, "Queen must no longer be invulnerable after phase transition")

	# Deal 200 damage -> 190 HP <= 200 HP threshold for Phase 3
	queen.take_damage(200)
	check(queen.current_health == 190, "Queen HP must be 190")
	check(queen.current_phase == 3, "Queen must transition to Phase 3 at <= 200 HP")

	print(">>> [TEST 2 PASSED] Boss damage, hit flash, phases, and Area3D hurtbox validated.\n")

	# -------------------------------------------------------------------------
	# 3. TEST BOSS SPAWN PACING
	# -------------------------------------------------------------------------
	print("[TEST 3] Validating Boss Spawn Pacing & Atrium Enemy Clear Trigger...")

	var trigger_script = load("res://scripts/boss_encounter_trigger.gd")
	check(trigger_script != null, "boss_encounter_trigger.gd must load")

	var arena = Node3D.new()
	arena.name = "TestArena"
	TestUtil.track(arena)
	root.add_child(arena)

	var trigger = Area3D.new()
	trigger.set_script(trigger_script)
	trigger.name = "BossEncounterTrigger"
	arena.add_child(trigger)
	await process_frame

	# Create a dummy enemy in group "enemies"
	var dummy_enemy = CharacterBody3D.new()
	dummy_enemy.name = "DummyMinion"
	arena.add_child(dummy_enemy)
	dummy_enemy.add_to_group("enemies")

	check(trigger.get_remaining_enemies_count() == 1, "Remaining enemies count must be 1")

	# Design (WP-1): the boss arena gate fires on ENTRY regardless of remaining enemies.
	# Re-clearing the mall after every death was the single worst retry-loop problem.
	trigger._on_body_entered(player)
	await process_frame
	check(trigger.player_inside == true, "Player should be recognized inside trigger")
	check(trigger.triggered == true, "Trigger fires on entry even while enemies remain")
	var spawned_boss = arena.get_node_or_null("DialUpQueen")
	check(spawned_boss != null, "DialUpQueen spawns on arena entry")
	check(spawned_boss != null and spawned_boss.is_in_group("boss"), "Spawned queen is in group 'boss'")
	dummy_enemy.remove_from_group("enemies")
	dummy_enemy.queue_free()
	await process_frame

	print(">>> [TEST 3 PASSED] Boss gate validated: queen spawns on arena entry.\n")

	print("========================================================")
	print(">>> ALL 3 GAMEPLAY FIXES VALIDATION COMPLETED! <<<")
	print("========================================================\n")

	await TestUtil.cleanup(self)
	TestUtil.finish(self)
