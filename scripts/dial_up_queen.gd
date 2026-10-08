extends CharacterBody3D

## DialUpQueen (Boss Encounter)
## The sovereign biomutated queen cicada rooted in the mall food court servers.
## Features multi-phase state machine with Idle, AoE Modem Screech shockwaves,
## Minion Summoning, and health threshold phase transitions.

signal boss_health_changed(current_hp: int, max_hp: int, phase: int)
signal boss_phase_transition(new_phase: int)
signal boss_defeated()

enum State {
	IDLE,
	TRACKING,
	AOE_ATTACK,
	MINION_SUMMON,
	PHASE_TRANSITION,
	DEFEATED
}

@export_category("Boss Stats & Thresholds")
@export var max_health: int = 1500
var current_health: int = 600
var current_phase: int = 1 # Phase 1: >66% HP, Phase 2: 33-66% HP, Phase 3: <33% HP

@export_category("Pacing & Combat")
@export var hover_height: float = 1.2
@export var phase1_speed: float = 2.5
@export var phase2_speed: float = 4.0
@export var phase3_speed: float = 5.5
@export var aoe_base_damage: int = 20

var current_state: State = State.IDLE
var state_timer: float = 0.0
var target_player: Node3D = null
var is_invulnerable: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# Visual Nodes
@export var model_path: String = "res://assets/models/dial_up_queen.glb"
@export var model_height: float = 4.0
@export var model_yaw: float = 0.0
@export var model_pitch: float = -50.0 # tilt the upright moth forward so the wings read from the isometric camera
var uses_model: bool = false
var body_tint: StandardMaterial3D = null
var queen_body: Node3D = null
var antenna_array: Node3D = null
var wing_left: CSGBox3D = null
var wing_right: CSGBox3D = null
var aoe_telegraph_ring: CSGCylinder3D = null
var hit_tween: Tween = null
var flash_tween: Tween = null
var aoe_outline: MeshInstance3D
var aoe_center := Vector3.ZERO
var aoe_tween: Tween
var aoe_flashing := false
var wing_flap_timer: float = 0.0

const FX = preload("res://scripts/turret_mortar.gd")
var dying := false
var sfx: AudioStreamPlayer3D

func _play_sfx(duration: float, frequency: float, noise: float = 0.0) -> void:
	sfx.stream = FX.sound(duration, frequency, noise)
	sfx.play()

func _ready() -> void:
	sfx = AudioStreamPlayer3D.new()
	add_child(sfx)
	current_health = max_health
	current_phase = 1
	add_to_group("enemies")
	add_to_group("boss")

	# Physics Layer: Layer 3 (bitmask 4: Enemy), Mask: Layer 1 (World) | Layer 2 (Player)
	collision_layer = 4
	collision_mask = 1 | 2

	_build_visuals()
	_enter_idle()
	emit_signal("boss_health_changed", current_health, max_health, current_phase)
	print("[DialUpQueen] *** BOSS SPAWNED *** The Dial-Up Queen looms with %d HP!" % max_health)

func _physics_process(delta: float) -> void:
	if dying:
		return
	# Hover physics
	if not is_on_floor():
		velocity.y -= gravity * delta * 0.5 # Low-gravity hover
	else:
		velocity.y = hover_height

	# Wing flutter animation
	wing_flap_timer += delta * (14.0 if current_phase == 1 else (20.0 if current_phase == 2 else 28.0))
	if wing_left and wing_right:
		var flap_angle = sin(wing_flap_timer) * 0.45
		wing_left.rotation.z = flap_angle
		wing_right.rotation.z = -flap_angle
	elif uses_model and queen_body:
		queen_body.position.y = sin(wing_flap_timer * 0.12) * 0.12 # hover bob stands in for the wing flap

	_find_player()

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.TRACKING:
			_process_tracking(delta)
		State.AOE_ATTACK:
			_process_aoe(delta)
		State.MINION_SUMMON:
			_process_summon(delta)
		State.PHASE_TRANSITION:
			_process_phase_transition(delta)
		State.DEFEATED:
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()

func _find_player() -> void:
	if target_player and is_instance_valid(target_player):
		return
	var player: Node = null
	if get_tree():
		player = get_tree().get_first_node_in_group("player")
		if not player and get_tree().current_scene:
			player = get_tree().current_scene.find_child("Player", true, false)
	if not player and get_parent():
		player = get_parent().get_node_or_null("Player")
		if not player and get_parent().get_parent():
			player = get_parent().get_parent().get_node_or_null("Player")
		if not player:
			player = get_parent().find_child("Player", true, false)
	if not player and get_tree() and get_tree().root:
		player = get_tree().root.find_child("Player", true, false)
	if player and player is Node3D:
		target_player = player

# =============================================================================
# STATE MACHINE IMPLEMENTATIONS
# =============================================================================

func _enter_idle() -> void:
	current_state = State.IDLE
	velocity.x = 0.0
	velocity.z = 0.0
	state_timer = 1.0 if current_phase == 1 else 0.6

func _process_idle(delta: float) -> void:
	state_timer -= delta
	_face_player(delta)

	if state_timer <= 0.0:
		if not target_player or not is_instance_valid(target_player):
			state_timer = 0.8
			return

		var dist = global_position.distance_to(target_player.global_position)
		var rand_choice = randf()

		if dist <= 6.5:
			_enter_aoe_attack()
		elif rand_choice < 0.35:
			_enter_minion_summon()
		else:
			_enter_tracking()

func _enter_tracking() -> void:
	current_state = State.TRACKING
	state_timer = randf_range(2.0, 3.5)

func _process_tracking(delta: float) -> void:
	state_timer -= delta
	if not target_player or not is_instance_valid(target_player):
		_enter_idle()
		return

	var to_player = target_player.global_position - global_position
	to_player.y = 0.0
	var dist = to_player.length()

	# Move toward player
	var speed = phase1_speed if current_phase == 1 else (phase2_speed if current_phase == 2 else phase3_speed)
	var move_dir = to_player.normalized()
	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	_face_player(delta)

	# Within striking range
	if dist <= 4.5 or state_timer <= 0.0:
		if randf() > 0.4:
			_enter_aoe_attack()
		else:
			_enter_minion_summon()

func _face_player(delta: float) -> void:
	if target_player and is_instance_valid(target_player):
		var to_player = target_player.global_position - global_position
		to_player.y = 0.0
		if to_player.length_squared() > 0.001:
			var target_rot_y = atan2(-to_player.x, -to_player.z)
			rotation.y = lerp_angle(rotation.y, target_rot_y, 6.0 * delta)

# =============================================================================
# AOE ATTACK: MODEM SCREECH BIO-SHOCKWAVE
# =============================================================================

func _charge_duration() -> float:
	return [1.4, 1.1, 0.9][current_phase - 1]

func _aoe_radius() -> float:
	return [7.0, 9.0, 11.0][current_phase - 1]

func _clear_telegraph() -> void:
	if aoe_tween and aoe_tween.is_valid():
		aoe_tween.kill()
	if is_instance_valid(aoe_outline):
		aoe_outline.queue_free()
	if aoe_telegraph_ring:
		aoe_telegraph_ring.visible = false

func _outline(radius: float, color: Color) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - 0.07
	mesh.outer_radius = radius
	mesh.rings = 64
	mesh.ring_segments = 8
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mesh.material = mat
	ring.mesh = mesh
	get_parent().add_child(ring)
	ring.global_position = aoe_center
	return ring

func _enter_aoe_attack() -> void:
	_clear_telegraph()
	current_state = State.AOE_ATTACK
	state_timer = _charge_duration()
	aoe_flashing = false
	velocity.x = 0.0
	velocity.z = 0.0
	aoe_center = FX.floor_point(self, global_position)
	var radius := _aoe_radius()
	aoe_outline = _outline(radius, Color(1, 0.05, 0.02, 0.6))
	_play_sfx(0.8, 1600.0, 0.35)
	print_verbose("[DialUpQueen] >>> CHARGING MODEM SCREECH AOE! (Radius: %.1fm, charge %.1fs)" % [radius, state_timer])
	if aoe_telegraph_ring:
		aoe_telegraph_ring.top_level = true
		aoe_telegraph_ring.global_position = aoe_center
		aoe_telegraph_ring.visible = true
		aoe_telegraph_ring.radius = 0.05
		var mat := aoe_telegraph_ring.material as StandardMaterial3D
		mat.albedo_color = Color(1, 0.1, 0.05, 0.25)
		mat.emission = Color.RED
		aoe_tween = create_tween()
		aoe_tween.tween_property(aoe_telegraph_ring, "radius", radius, state_timer - 0.1)

func _process_aoe(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.1 and not aoe_flashing:
		aoe_flashing = true
		if aoe_telegraph_ring:
			var mat := aoe_telegraph_ring.material as StandardMaterial3D
			mat.albedo_color = Color(1, 1, 1, 0.6)
			mat.emission = Color.WHITE
	if state_timer <= 0.0:
		_detonate_aoe()
		_enter_idle()

func _detonate_aoe() -> void:
	var radius := _aoe_radius()
	var damage := aoe_base_damage if current_phase == 1 else int(aoe_base_damage * 1.4)
	_clear_telegraph()
	var shock := _outline(radius, Color(1, 0.4, 0.1, 0.8))
	shock.scale = Vector3(0.05, 1, 0.05)
	var tween := shock.create_tween()
	tween.tween_property(shock, "scale", Vector3.ONE, 0.25)
	tween.tween_callback(shock.queue_free)
	FX.burst(self, Color(1, 0.3, 0.05), 12, 0.35, 45.0)
	var camera := get_viewport().get_camera_3d()
	if camera and camera.get_parent().has_method("add_trauma"):
		camera.get_parent().call("add_trauma", 0.5)
	print_verbose("[DialUpQueen] Modem Screech detonated (%d damage, %.1fm)" % [damage, radius])
	if is_instance_valid(target_player):
		var offset: Vector3 = target_player.global_position - aoe_center
		if Vector2(offset.x, offset.z).length() <= radius and absf(offset.y) <= 3.0 and target_player.has_method("take_damage"):
			target_player.call("take_damage", damage, offset.normalized())

func _exit_tree() -> void:
	_clear_telegraph()

# =============================================================================
# MINION SUMMONING BEHAVIOR
# =============================================================================

func _enter_minion_summon() -> void:
	current_state = State.MINION_SUMMON
	state_timer = 1.5
	velocity.x = 0.0
	velocity.z = 0.0

	print_verbose("[DialUpQueen] >>> TRANSMITTING 56K HANDSHAKE... Summoning bio-minions!")

	# Antenna charge animation
	if antenna_array:
		var tween = create_tween()
		tween.tween_property(antenna_array, "scale", Vector3(1.3, 1.3, 1.3), 0.3)
		tween.tween_property(antenna_array, "scale", Vector3.ONE, 0.3)

func _process_summon(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_execute_summon()
		_enter_idle()

func _execute_summon() -> void:
	var living := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.get_meta("summoned_by_boss", false) and not enemy.is_queued_for_deletion():
			living += 1
	var count := mini(4 - living, 2 if current_phase == 1 else (3 if current_phase == 2 else 4))

	for i in range(count):
		var angle = (TAU / count) * i + randf_range(-0.3, 0.3)
		var spawn_offset = Vector3(cos(angle) * 3.5, 0.5, sin(angle) * 3.5)
		var spawn_pos = global_position + spawn_offset

		# Summon SludgeRoach or NeonCicada
		var roach_script = load("res://scripts/sludge_roach.gd") if ResourceLoader.exists("res://scripts/sludge_roach.gd") else null
		if not roach_script and ResourceLoader.exists("res://sludge_roach.gd"):
			roach_script = load("res://sludge_roach.gd")

		if roach_script:
			var minion = CharacterBody3D.new()
			minion.name = "SummonedRoach_%d" % randi()
			minion.set_script(roach_script)
			minion.set_meta("summoned_by_boss", true)
			get_parent().add_child(minion)
			minion.global_position = spawn_pos
			print_verbose("[DialUpQueen] Spawned bio-minion %s at %s" % [minion.name, spawn_pos])

# =============================================================================
# PHASE TRANSITIONS & DAMAGE
# =============================================================================

func _trigger_phase_transition(new_phase: int) -> void:
	_clear_telegraph()
	current_phase = new_phase
	current_state = State.PHASE_TRANSITION
	state_timer = 1.8
	is_invulnerable = true
	velocity.x = 0.0
	velocity.z = 0.0

	print("[DialUpQueen] !!!!!!! PHASE TRANSITION -> ENTERING PHASE %d !!!!!!!" % current_phase)
	emit_signal("boss_phase_transition", current_phase)

	# Phase visual color updates (Phase 2: toxic amber, Phase 3: enraged neon-magenta)
	if queen_body:
		var phase_mat = StandardMaterial3D.new()
		if current_phase == 2:
			phase_mat.albedo_color = Color(0.9, 0.5, 0.1, 1.0)
			phase_mat.emission_enabled = true
			phase_mat.emission = Color(1.0, 0.6, 0.1, 1.0)
		elif current_phase == 3:
			phase_mat.albedo_color = Color(0.95, 0.1, 0.4, 1.0)
			phase_mat.emission_enabled = true
			phase_mat.emission = Color(1.0, 0.15, 0.5, 1.0)
		if uses_model:
			body_tint = EnemyModel.tint_material(phase_mat.emission, 0.35, 0.5)
			EnemyModel.tint(queen_body, body_tint)
		elif queen_body is CSGSphere3D:
			(queen_body as CSGSphere3D).material = phase_mat

	# Force push wave repelling player
	if target_player and is_instance_valid(target_player):
		var away = (target_player.global_position - global_position).normalized()
		if target_player.has_method("set_velocity"):
			target_player.set_velocity(away * 14.0 + Vector3(0.0, 4.0, 0.0))

func _process_phase_transition(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		is_invulnerable = false
		_enter_idle()

## Public damage entry
func take_damage(amount: int, knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if current_health <= 0:
		return
	if is_invulnerable:
		print_verbose("[DialUpQueen] Invulnerable during phase transition!")
		return

	var dmg: int = int(amount)
	current_health -= dmg
	print_verbose("[DialUpQueen] Boss took %d damage! HP: %d/%d (Phase %d)" % [dmg, max(0, current_health), max_health, current_phase])

	emit_signal("boss_health_changed", max(0, current_health), max_health, current_phase)
	_flash_hit_visual()

	# Check Phase 2 threshold (66% = 400 HP)
	if current_phase == 1 and current_health <= int(max_health * 0.66) and current_health > 0:
		_trigger_phase_transition(2)
		return

	# Check Phase 3 threshold (33% = 200 HP)
	if current_phase == 2 and current_health <= int(max_health * 0.33) and current_health > 0:
		_trigger_phase_transition(3)
		return

	if current_health <= 0:
		_die()

func _flash_hit_visual() -> void:
	if queen_body and is_instance_valid(queen_body):
		var flash_mat := EnemyModel.tint_material(Color(1.0, 0.25, 0.25), 0.55, 0.5)
		EnemyModel.tint(queen_body, flash_mat)

		if flash_tween and flash_tween.is_valid():
			flash_tween.kill()
		flash_tween = create_tween()
		flash_tween.tween_interval(0.25)
		flash_tween.tween_callback(Callable(self, "_reset_flash_visual"))

func _reset_flash_visual() -> void:
	if is_instance_valid(queen_body):
		EnemyModel.tint(queen_body, body_tint)

func _die() -> void:
	if dying:
		return
	_clear_telegraph()
	_find_player()
	dying = true
	current_health = 0
	set_physics_process(false)
	remove_from_group("enemies")
	FX.burst(self, Color(1, 0.1, 0.5), 10, 0.25, 60)
	current_state = State.DEFEATED
	print("[DialUpQueen] *** BOSS DEFEATED! The dial-up carrier frequency has died. ***")
	
	if target_player and is_instance_valid(target_player) and target_player.has_method("gain_xp"):
		target_player.call("gain_xp", 250)
	
	if get_tree():
		for node in get_tree().get_nodes_in_group("enemies"):
			if node.has_meta("summoned_by_boss") and node.get_meta("summoned_by_boss"):
				node.queue_free()
				
	emit_signal("boss_defeated")

	# Dramatic shrink and explosion fade
	if queen_body:
		var death_tween = create_tween()
		death_tween.tween_property(queen_body, "scale", Vector3(1.5, 0.2, 1.5), 0.4)
		death_tween.tween_property(queen_body, "scale", Vector3.ONE * 0.001, 0.8)
		death_tween.tween_callback(queue_free)
	else:
		queue_free()

func _build_visuals() -> void:
	var model := EnemyModel.attach(self, model_path, model_height, 0.0, model_yaw, model_pitch)
	if model:
		queen_body = model
		uses_model = true
		_build_shared_visuals()
		return

	# Main massive Queen thorax
	var thorax := CSGSphere3D.new()
	thorax.name = "QueenThorax"
	thorax.radius = 1.4
	thorax.scale = Vector3(1.1, 1.3, 1.5)
	thorax.position = Vector3(0.0, 1.8, 0.0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.18, 0.63, 1.0) # magenta/violet
	mat.metallic = 0.3
	mat.roughness = 0.5
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.15, 0.5, 1.0)
	thorax.material = mat
	add_child(thorax)
	queen_body = thorax

	# Antenna Array (Dial-Up server rods)
	antenna_array = Node3D.new()
	antenna_array.name = "AntennaArray"
	antenna_array.position = Vector3(0.0, 3.2, 0.5)
	add_child(antenna_array)

	var ant1 = CSGCylinder3D.new()
	ant1.radius = 0.05
	ant1.height = 1.6
	ant1.position = Vector3(-0.5, 0.0, 0.0)
	ant1.rotation.z = deg_to_rad(-25.0)
	antenna_array.add_child(ant1)

	var ant2 = CSGCylinder3D.new()
	ant2.radius = 0.05
	ant2.height = 1.6
	ant2.position = Vector3(0.5, 0.0, 0.0)
	ant2.rotation.z = deg_to_rad(25.0)
	antenna_array.add_child(ant2)

	# Translucent Biopunk Wings
	wing_left = CSGBox3D.new()
	wing_left.name = "WingLeft"
	wing_left.size = Vector3(2.2, 0.04, 1.0)
	wing_left.position = Vector3(-1.8, 2.2, -0.4)
	var wing_mat = StandardMaterial3D.new()
	wing_mat.albedo_color = Color(0.4, 0.9, 1.0, 0.7)
	wing_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wing_mat.emission_enabled = true
	wing_mat.emission = Color(0.2, 0.6, 0.9, 0.5)
	wing_left.material = wing_mat
	add_child(wing_left)

	wing_right = CSGBox3D.new()
	wing_right.name = "WingRight"
	wing_right.size = Vector3(2.2, 0.04, 1.0)
	wing_right.position = Vector3(1.8, 2.2, -0.4)
	wing_right.material = wing_mat
	add_child(wing_right)

	_build_shared_visuals()

func _build_shared_visuals() -> void:
	# AoE Telegraph Ring
	aoe_telegraph_ring = CSGCylinder3D.new()
	aoe_telegraph_ring.name = "AoETelegraph"
	aoe_telegraph_ring.radius = 7.0
	aoe_telegraph_ring.height = 0.05
	aoe_telegraph_ring.sides = 24
	aoe_telegraph_ring.position = Vector3(0.0, 0.05, 0.0)
	aoe_telegraph_ring.visible = false
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.2, 0.2, 0.35)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.2, 0.2, 0.6)
	aoe_telegraph_ring.material = ring_mat
	add_child(aoe_telegraph_ring)

	# Collision Capsule
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var capsule = CapsuleShape3D.new()
	capsule.radius = 1.5
	capsule.height = 3.6
	col.shape = capsule
	col.position = Vector3(0.0, 1.8, 0.0)
	add_child(col)

	# Dedicated Area3D Hurtbox for melee AttackSensor detection
	var hurtbox = Area3D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.collision_layer = 4 # Layer 3 (bitmask 4: Enemy)
	hurtbox.collision_mask = 0
	hurtbox.monitoring = false
	hurtbox.monitorable = true
	var hurtbox_col = CollisionShape3D.new()
	var hurtbox_capsule = CapsuleShape3D.new()
	hurtbox_capsule.radius = 2.0
	hurtbox_capsule.height = 4.0
	hurtbox_col.shape = hurtbox_capsule
	hurtbox_col.position = Vector3(0.0, 1.8, 0.0)
	hurtbox.add_child(hurtbox_col)
	add_child(hurtbox)
