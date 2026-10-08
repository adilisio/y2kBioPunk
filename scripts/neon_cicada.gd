extends CharacterBody3D

## NeonCicada (Neon Dial-Up Cicada)
## Early bio-fauna enemy prototype for Godot 4.3 isometric ARPG.
## Features wandering AI, DetectionArea3D aggro tracking, 3D gravity, and health/damage handling.

enum State {
	IDLE,
	WANDERING,
	CHASING,
	WINDUP,
	LUNGING
}

@export_category("Combat & Stats")
@export var max_health: int = 70
var current_health: int = 70

@export_category("Locomotion & AI")
@export var move_speed: float = 2.0
@export var chase_speed: float = 3.0
@export var wander_radius: float = 6.0
@export var detection_radius: float = 8.5
@export var pause_duration_min: float = 1.5
@export var pause_duration_max: float = 3.5
@export var wander_duration_max: float = 4.0

var current_state: State = State.IDLE
var state_timer: float = 0.0
var attack_cooldown := 0.0
var lunge_direction := Vector3.ZERO
var lunge_hit := false
var target_position: Vector3 = Vector3.ZERO
var home_position: Vector3 = Vector3.ZERO
var target_player: Node3D = null

# Knockback handling
var knockback_velocity: Vector3 = Vector3.ZERO
var knockback_timer: float = 0.0

# Standard 3D physics gravity
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

@export var model_path: String = "res://assets/models/neon_cicada.glb"
@export var model_height: float = 1.2
@export var model_yaw: float = 0.0
var visual_mesh: Node3D = null
var flash_mat: StandardMaterial3D = null
var hit_tween: Tween
var flash_tween: Tween
var detection_area: Area3D = null

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
	home_position = global_position
	add_to_group("enemies")

	# Physics Layer: Layer 3 (bit 4: Enemy), Mask: Layer 1 (World) | Layer 2 (Player)
	collision_layer = 4
	collision_mask = 1 | 2

	_setup_visuals()
	_setup_detection_area()
	_enter_idle()

func _setup_visuals() -> void:
	var csg := get_node_or_null("CSGCylinder3D")
	# Capsule collider spans y -1..1, so the floor sits 1 m below the body origin.
	var model := EnemyModel.attach(self, model_path, model_height, -1.0, model_yaw)
	if model:
		visual_mesh = model
		if csg:
			csg.queue_free()
	else:
		visual_mesh = csg as Node3D

func _setup_detection_area() -> void:
	detection_area = get_node_or_null("DetectionArea3D") as Area3D
	if not detection_area:
		detection_area = Area3D.new()
		detection_area.name = "DetectionArea3D"
		detection_area.collision_layer = 0
		detection_area.collision_mask = 2 # Detect Player layer (2)
		detection_area.monitorable = false
		detection_area.monitoring = true

		var col = CollisionShape3D.new()
		col.name = "DetectionShape"
		var sphere = SphereShape3D.new()
		sphere.radius = detection_radius
		col.shape = sphere
		detection_area.add_child(col)
		add_child(detection_area)

	if not detection_area.body_entered.is_connected(_on_detection_body_entered):
		detection_area.body_entered.connect(_on_detection_body_entered)
	if not detection_area.body_exited.is_connected(_on_detection_body_exited):
		detection_area.body_exited.connect(_on_detection_body_exited)

func _on_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player" or body.is_class("PlayerController"):
		target_player = body
		_enter_chasing()

func _on_detection_body_exited(body: Node3D) -> void:
	if body == target_player:
		target_player = null
		_enter_idle()

func _physics_process(delta: float) -> void:
	if dying:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	# 1. Apply standard 3D gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# 2. Knockback impulse override or State Machine Logic
	if knockback_timer > 0.0:
		knockback_timer -= delta
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		knockback_velocity.x = lerpf(knockback_velocity.x, 0.0, 8.0 * delta)
		knockback_velocity.z = lerpf(knockback_velocity.z, 0.0, 8.0 * delta)
	else:
		match current_state:
			State.IDLE:
				_process_idle(delta)
			State.WANDERING:
				_process_wandering(delta)
			State.CHASING:
				_process_chasing(delta)
			State.WINDUP:
				_process_windup(delta)
			State.LUNGING:
				_process_lunge(delta)

	# 3. Apply physics locomotion
	move_and_slide()

func _enter_idle() -> void:
	current_state = State.IDLE
	velocity.x = 0.0
	velocity.z = 0.0
	state_timer = randf_range(pause_duration_min, pause_duration_max)

func _process_idle(delta: float) -> void:
	if target_player and is_instance_valid(target_player):
		_enter_chasing()
		return

	state_timer -= delta
	if state_timer <= 0.0:
		_enter_wandering()

func _enter_wandering() -> void:
	current_state = State.WANDERING
	state_timer = wander_duration_max

	var angle = randf() * TAU
	var dist = randf_range(1.5, wander_radius)
	var offset = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	target_position = home_position + offset
	target_position.y = global_position.y

func _process_wandering(delta: float) -> void:
	if target_player and is_instance_valid(target_player):
		_enter_chasing()
		return

	state_timer -= delta

	var to_target = target_position - global_position
	to_target.y = 0.0
	var dist = to_target.length()

	if dist < 0.3 or state_timer <= 0.0:
		_enter_idle()
		return

	var move_dir = to_target.normalized()
	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed

	if move_dir.length_squared() > 0.001:
		var target_rot_y = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, 8.0 * delta)

func _enter_chasing() -> void:
	current_state = State.CHASING

func _process_chasing(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		target_player = null
		_enter_idle()
		return

	var to_player = target_player.global_position - global_position
	to_player.y = 0.0
	var dist = to_player.length()

	if dist > detection_radius * 1.3:
		target_player = null
		_enter_idle()
		return

	if dist <= 2.5 and attack_cooldown <= 0.0:
		_enter_windup(to_player.normalized())
		return
	var move_dir = to_player.normalized()
	velocity.x = move_dir.x * chase_speed
	velocity.z = move_dir.z * chase_speed

	if move_dir.length_squared() > 0.001:
		var target_rot_y = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, 9.0 * delta)

func _enter_windup(dir: Vector3) -> void:
	current_state = State.WINDUP
	state_timer = 0.5
	lunge_direction = dir
	velocity.x = 0.0
	velocity.z = 0.0
	if visual_mesh:
		_flash_hit_visual()
		var cue := create_tween()
		cue.tween_property(visual_mesh, "scale", Vector3(1.4, 0.8, 1.4), 0.25)
		cue.tween_property(visual_mesh, "scale", Vector3.ONE, 0.25)
		if flash_mat:
			var pulse := create_tween()
			pulse.tween_property(flash_mat, "emission_energy_multiplier", 0.9, 0.25)
			pulse.tween_property(flash_mat, "emission_energy_multiplier", 0.45, 0.25)
	print_verbose("[NeonDialUpCicada] wind-up (0.5s)")

func _process_windup(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = State.LUNGING
		state_timer = 0.3
		attack_cooldown = 1.5
		lunge_hit = false
		_play_sfx(0.16, 1800.0, 0.2)
		print_verbose("[NeonDialUpCicada] lunge (1.5m, 6 damage)")

func _process_lunge(delta: float) -> void:
	state_timer -= delta
	velocity.x = lunge_direction.x * 5.0
	velocity.z = lunge_direction.z * 5.0
	var contact := false
	if is_instance_valid(target_player):
		var offset := target_player.global_position - global_position
		contact = Vector2(offset.x, offset.z).length() <= 1.6 and absf(offset.y) <= 2.2
	if not lunge_hit and contact:
		lunge_hit = true
		if target_player.has_method("take_damage"):
			target_player.call("take_damage", 6, lunge_direction)
	if state_timer <= 0.0:
		_enter_chasing()

## Public damage interface called by C++ PlayerController and combat volumes
func take_damage(amount: int, knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if current_health <= 0:
		return

	current_health -= amount
	print_verbose("[NeonDialUpCicada] %s took %d damage! HP: %d/%d" % [name, amount, max(0, current_health), max_health])

	_flash_hit_visual()
	_apply_squash_and_stretch()
	_apply_knockback(knockback_dir)

	if current_health <= 0:
		_die()

func _flash_hit_visual() -> void:
	if visual_mesh and is_instance_valid(visual_mesh):
		# Translucent overlay keeps the model texture visible; low energy so ACES + glow does not blow it out to white.
		flash_mat = EnemyModel.tint_material(Color(1.0, 0.12, 0.12), 0.55, 0.45)
		EnemyModel.tint(visual_mesh, flash_mat)

		if flash_tween and flash_tween.is_valid():
			flash_tween.kill()
		flash_tween = create_tween()
		flash_tween.tween_interval(0.5 if current_state == State.WINDUP else 0.3)
		flash_tween.tween_callback(Callable(self, "_reset_flash_visual"))

func _reset_flash_visual() -> void:
	if is_instance_valid(visual_mesh):
		EnemyModel.untint(visual_mesh)

func _apply_squash_and_stretch() -> void:
	if visual_mesh and is_instance_valid(visual_mesh):
		if hit_tween and hit_tween.is_valid():
			hit_tween.kill()
		hit_tween = create_tween()
		hit_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		hit_tween.tween_property(visual_mesh, "scale", Vector3(1.25, 0.65, 1.25), 0.07)
		hit_tween.tween_property(visual_mesh, "scale", Vector3(0.85, 1.25, 0.85), 0.11)
		hit_tween.tween_property(visual_mesh, "scale", Vector3.ONE, 0.12)

func _apply_knockback(override_dir: Vector3 = Vector3.ZERO) -> void:
	var knockback_impulse: float = 7.5
	if override_dir != Vector3.ZERO:
		knockback_velocity = override_dir.normalized() * knockback_impulse * clampf(override_dir.length(), 1.0, 1.6)
	else:
		var dir = Vector3.ZERO
		if target_player and is_instance_valid(target_player):
			var away = global_position - target_player.global_position
			away.y = 0.0
			if away.length_squared() > 0.001:
				dir = away.normalized()
		if dir == Vector3.ZERO:
			dir = -transform.basis.z
		knockback_velocity = dir * knockback_impulse

	knockback_timer = 0.25
	velocity.x = knockback_velocity.x
	velocity.z = knockback_velocity.z

	_enter_idle()
	state_timer = 0.6

func _die() -> void:
	if dying:
		return
	dying = true
	current_health = 0
	set_physics_process(false)
	remove_from_group("enemies")
	FX.burst(self, Color(0.1, 1, 0.7), 10, 0.25, 700)
	print_verbose("[NeonDialUpCicada] %s was defeated! Dial-up carrier frequency severed." % name)
	var tree = get_tree()
	if tree:
		var p = tree.get_first_node_in_group("player")
		if not p and tree.current_scene:
			p = tree.current_scene.find_child("Player", true, false)
		if p and p.has_method("gain_xp"):
			p.call("gain_xp", 10)

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 0.001, 0.15)
	tween.tween_callback(queue_free)
