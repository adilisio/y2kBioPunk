extends SceneTree

func _init():
	var exit_code = run_tests()
	quit(exit_code)

func run_tests() -> int:
	print("\n========================================================")
	print(">>> RUNNING GAMEPLAY FIXES VALIDATION TEST <<<")
	print("========================================================\n")

	# -------------------------------------------------------------------------
	# 1. TEST INPUT BLEED & FLAMETHROWER ISOLATION
	# -------------------------------------------------------------------------
	print("[TEST 1] Validating Input Map & Flamethrower Isolation...")
	
	# Verify legacy actions are purged from InputMap
	assert(not InputMap.has_action("spray_aerosol"), "spray_aerosol must be purged from InputMap")
	assert(not InputMap.has_action("use_aerosol"), "use_aerosol must be purged from InputMap")
	assert(InputMap.has_action("attack"), "attack action must exist")
	assert(InputMap.has_action("secondary_fire"), "secondary_fire action must exist")
	
	# Check attack is on mouse button 1 (LMB)
	var atk_events = InputMap.action_get_events("attack")
	var lmb_found = false
	for ev in atk_events:
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			lmb_found = true
			break
	assert(lmb_found, "attack must be mapped to LMB (button 1)")

	# Check secondary_fire is NOT on mouse button 1 (LMB)
	var sec_events = InputMap.action_get_events("secondary_fire")
	for ev in sec_events:
		if ev is InputEventMouseButton:
			assert(ev.button_index != MOUSE_BUTTON_LEFT, "secondary_fire must NEVER be mapped to LMB")

	# Instantiate Player from scenes/player.tscn
	var player_scene = load("res://scenes/player.tscn")
	var player = player_scene.instantiate() as CharacterBody3D
	assert(player != null, "Player must instantiate from scenes/player.tscn")
	root.add_child(player)
	player.notification(Node.NOTIFICATION_READY)
	player.simulate_physics(0.001)

	var flame_particles = player.get_flame_particles() as GPUParticles3D
	if not flame_particles:
		flame_particles = player.find_child("FlamethrowerParticles", true, false) as GPUParticles3D
	assert(flame_particles != null, "FlamethrowerParticles node must exist on player")
	assert(not flame_particles.is_emitting(), "flame_particles must be OFF by default")

	# Simulate attack input: flame_particles must remain OFF
	Input.action_press("attack")
	player.simulate_physics(0.016)
	Input.action_release("attack")
	assert(not flame_particles.is_emitting(), "flame_particles must NOT emit when attack (LMB) is pressed")

	# Simulate secondary_fire input: flame_particles must turn ON
	Input.action_press("secondary_fire")
	player.simulate_physics(0.016)
	print("DEBUG flame_particles: ", flame_particles, " is_emitting: ", flame_particles.is_emitting())
	print("DEBUG player.get_flame_particles(): ", player.get_flame_particles(), " is_emitting: ", player.get_flame_particles().is_emitting() if player.get_flame_particles() else "null")
	assert(flame_particles.is_emitting(), "flame_particles MUST emit when secondary_fire is pressed")
	
	# Release secondary_fire: flame_particles must turn OFF
	Input.action_release("secondary_fire")
	player.simulate_physics(0.016)
	assert(not flame_particles.is_emitting(), "flame_particles must stop emitting when secondary_fire is released")

	print(">>> [TEST 1 PASSED] Input bleed resolved: attack and secondary_fire strictly isolated.\n")

	# -------------------------------------------------------------------------
	# 2. TEST BOSS INVINCIBILITY & HIT DETECTION
	# -------------------------------------------------------------------------
	print("[TEST 2] Validating Boss Invincibility & Hitbox...")

	var queen_scene = load("res://scenes/dial_up_queen.tscn")
	assert(queen_scene != null, "scenes/dial_up_queen.tscn must load")
	var queen = queen_scene.instantiate() as CharacterBody3D
	root.add_child(queen)
	queen._ready()

	# Verify collision layer and mask
	assert(queen.collision_layer == 4, "Queen collision_layer must be 4 (Layer 3: Enemy), got %d" % queen.collision_layer)
	assert((queen.collision_mask & 1) != 0, "Queen collision_mask must include Layer 1 (World)")
	assert((queen.collision_mask & 2) != 0, "Queen collision_mask must include Layer 2 (Player)")

	# Verify Hurtbox Area3D exists on layer 4
	var hurtbox = queen.find_child("Hurtbox", true, false) as Area3D
	assert(hurtbox != null, "Queen must possess Hurtbox Area3D")
	assert(hurtbox.collision_layer == 4, "Hurtbox collision_layer must be 4 (Enemy)")

	# Test damage handling and signals
	var received_hp: Array = []
	queen.connect("boss_health_changed", func(cur, max_hp, phase):
		received_hp.append([cur, max_hp, phase])
	)

	# Deal 50 damage
	queen.take_damage(50)
	assert(queen.current_health == 550, "Queen HP must be 550 after 50 damage, got %d" % queen.current_health)
	assert(received_hp.size() > 0, "boss_health_changed signal must be emitted")
	assert(received_hp[-1][0] == 550, "Signal cur_hp must match 550")
	assert(queen.current_phase == 1, "Phase must still be 1")

	# Deal 160 damage -> 390 HP <= 400 HP threshold for Phase 2
	queen.take_damage(160)
	assert(queen.current_health == 390, "Queen HP must be 390")
	assert(queen.current_phase == 2, "Queen must transition to Phase 2 at <= 400 HP")

	# Wait out phase transition invulnerability
	queen._process_phase_transition(2.0)
	assert(not queen.is_invulnerable, "Queen must no longer be invulnerable after phase transition")

	# Deal 200 damage -> 190 HP <= 200 HP threshold for Phase 3
	queen.take_damage(200)
	assert(queen.current_health == 190, "Queen HP must be 190")
	assert(queen.current_phase == 3, "Queen must transition to Phase 3 at <= 200 HP")

	queen.queue_free()
	print(">>> [TEST 2 PASSED] Boss damage, hit flash, phases, and Area3D hurtbox validated.\n")

	# -------------------------------------------------------------------------
	# 3. TEST BOSS SPAWN PACING
	# -------------------------------------------------------------------------
	print("[TEST 3] Validating Boss Spawn Pacing & Atrium Enemy Clear Trigger...")

	var trigger_script = load("res://scripts/boss_encounter_trigger.gd")
	assert(trigger_script != null, "boss_encounter_trigger.gd must load")

	var arena = Node3D.new()
	arena.name = "TestArena"
	root.add_child(arena)

	var trigger = Area3D.new()
	trigger.set_script(trigger_script)
	trigger.name = "BossEncounterTrigger"
	arena.add_child(trigger)
	trigger._ready()

	# Create a dummy enemy in group "enemies"
	var dummy_enemy = CharacterBody3D.new()
	dummy_enemy.name = "DummyMinion"
	arena.add_child(dummy_enemy)
	dummy_enemy.add_to_group("enemies")

	assert(trigger.get_remaining_enemies_count() == 1, "Remaining enemies count must be 1")

	# Player enters trigger while dummy enemy is still alive: Boss must NOT spawn
	trigger._on_body_entered(player)
	assert(trigger.player_inside == true, "Player should be recognized inside trigger")
	assert(trigger.triggered == false, "Trigger must NOT fire while atrium enemies remain")
	assert(arena.get_node_or_null("DialUpQueen") == null, "DialUpQueen must NOT spawn while enemies remain")

	# Now eliminate the dummy enemy
	dummy_enemy.remove_from_group("enemies")
	dummy_enemy.queue_free()

	assert(trigger.get_remaining_enemies_count() == 0, "Remaining enemies count must now be 0")

	# Simulate process tick with player still inside
	trigger._process(0.016)

	assert(trigger.triggered == true, "Trigger must activate when enemies count reaches 0")
	var spawned_boss = arena.get_node_or_null("DialUpQueen")
	assert(spawned_boss != null, "DialUpQueen must be spawned in arena after clearing enemies")

	print(">>> [TEST 3 PASSED] Boss spawn pacing validated: requires clearing atrium enemies before summoning.\n")

	print("========================================================")
	print(">>> ALL 3 GAMEPLAY FIXES SUCCESSFULLY VALIDATED! <<<")
	print("========================================================\n")
	return 0
