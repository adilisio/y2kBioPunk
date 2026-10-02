extends CharacterBody3D

## NeonCicada (Neon Dial-Up Cicada)
## Early bio-fauna enemy prototype for Godot 4.3 isometric ARPG.
## Features wandering AI, DetectionArea3D aggro tracking, 3D gravity, and health/damage handling.

enum State {
	IDLE,
	WANDERING,
	CHASING
}

@export_category("Combat & Stats")
@export var max_health: int = 50
var current_health: int = 50

@export_category("Locomotion & AI")
@export var move_speed: float = 2.0
@export var chase_speed: float = 3.8
@export var wander_radius: float = 6.0
@export var detection_radius: float = 8.5
@export var pause_duration_min: float = 1.5
@export var pause_duration_max: float = 3.5
@export var wander_duration_max: float = 4.0

var current_state: State = State.IDLE
var state_timer: float = 0.0
var target_position: Vector3 = Vector3.ZERO
var home_position: Vector3 = Vector3.ZERO
var target_player: Node3D = null

# Knockback handling
var knockback_velocity: Vector3 = Vector3.ZERO
var knockback_timer: float = 0.0

# Standard 3D physics gravity
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

@onready var visual_mesh: GeometryInstance3D = get_node_or_null("CSGCylinder3D")
var hit_tween: Tween
var flash_tween: Tween
var detection_area: Area3D = null

func _ready() -> void:
	current_health = max_health
	home_position = global_position
	add_to_group("enemies")

	# Physics Layer: Layer 3 (bit 4: Enemy), Mask: Layer 1 (World) | Layer 2 (Player)
	collision_layer = 4
	collision_mask = 1 | 2

	_setup_detection_area()
	_enter_idle()

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
	if body.is_in_group("player") or body.name == "Player" or body is CharacterBody3D:
		target_player = body
		_enter_chasing()

func _on_detection_body_exited(body: Node3D) -> void:
	if body == target_player:
		target_player = null
		_enter_idle()

func _physics_process(delta: float) -> void:
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

	var move_dir = to_player.normalized()
	velocity.x = move_dir.x * chase_speed
	velocity.z = move_dir.z * chase_speed

	if move_dir.length_squared() > 0.001:
		var target_rot_y = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, 9.0 * delta)

## Public damage interface called by C++ PlayerController and combat volumes
func take_damage(amount: int, knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if current_health <= 0:
		return

	current_health -= amount
	print("[NeonDialUpCicada] %s took %d damage! HP: %d/%d" % [name, amount, max(0, current_health), max_health])

	_flash_hit_visual()
	_apply_squash_and_stretch()
	_apply_knockback(knockback_dir)

	if current_health <= 0:
		_die()

func _flash_hit_visual() -> void:
	if not visual_mesh or not is_instance_valid(visual_mesh):
		visual_mesh = get_node_or_null("CSGCylinder3D")
	if visual_mesh and is_instance_valid(visual_mesh):
		var flash_mat = StandardMaterial3D.new()
		flash_mat.albedo_color = Color(1.0, 0.1, 0.1, 1.0)
		flash_mat.emission_enabled = true
		flash_mat.emission = Color(1.0, 0.25, 0.25, 1.0)
		visual_mesh.material_override = flash_mat

		if flash_tween and flash_tween.is_valid():
			flash_tween.kill()
		flash_tween = create_tween()
		flash_tween.tween_interval(0.3)
		flash_tween.tween_callback(Callable(self, "_reset_flash_visual"))

func _reset_flash_visual() -> void:
	if is_instance_valid(visual_mesh):
		visual_mesh.material_override = null

func _apply_squash_and_stretch() -> void:
	if not visual_mesh or not is_instance_valid(visual_mesh):
		visual_mesh = get_node_or_null("CSGCylinder3D")
	if visual_mesh and is_instance_valid(visual_mesh):
		if hit_tween and hit_tween.is_valid():
			hit_tween.kill()
		hit_tween = create_tween()
		hit_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		hit_tween.tween_property(visual_mesh, "scale", Vector3(1.25, 0.65, 1.25), 0.07)
		hit_tween.tween_property(visual_mesh, "scale", Vector3(0.85, 1.25, 0.85), 0.11)
		hit_tween.tween_property(visual_mesh, "scale", Vector3.ONE, 0.12)

func _apply_knockback(override_dir: Vector3 = Vector3.ZERO) -> void:
	var dir = override_dir
	if dir == Vector3.ZERO:
		if target_player and is_instance_valid(target_player):
			var away = global_position - target_player.global_position
			away.y = 0.0
			if away.length_squared() > 0.001:
				dir = away.normalized()
		if dir == Vector3.ZERO:
			dir = -transform.basis.z

	var knockback_impulse: float = 7.5
	knockback_velocity = dir * knockback_impulse
	knockback_timer = 0.25
	velocity.x = knockback_velocity.x
	velocity.z = knockback_velocity.z

	_enter_idle()
	state_timer = 0.6

func _die() -> void:
	print("[NeonDialUpCicada] %s was defeated! Dial-up carrier frequency severed." % name)
	queue_free()
