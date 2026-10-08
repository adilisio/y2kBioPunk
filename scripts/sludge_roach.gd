extends CharacterBody3D

## SludgeRoach (Swarming/Tracking Bio-Pest)
## Fast-scuttling cockroach mutated by toxic mall runoff.
## Swarms targets in groups, flanking and pouncing with high-velocity leaps.
## Uses DetectionArea3D signal-based aggro and explicit collision layers.

enum State {
	IDLE,
	TRACKING,
	WINDUP,
	POUNCING,
	REPOSITIONING
}

@export_category("Combat & Stats")
@export var max_health: int = 45
var current_health: int = 45
@export var scuttle_speed: float = 5.5
@export var pounce_speed: float = 11.0
@export var detection_radius: float = 12.0
@export var attack_reach: float = 3.5
@export var bite_damage: int = 10

var current_state: State = State.IDLE
var state_timer: float = 0.0
var target_player: Node3D = null
var knockback_velocity: Vector3 = Vector3.ZERO
var knockback_timer: float = 0.0
var pounce_direction: Vector3 = Vector3.ZERO
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# Visual references
@export var model_path: String = "res://assets/models/sludge_roach.glb"
@export var model_height: float = 0.8
@export var model_yaw: float = 0.0
var visual_mesh: Node3D = null
var rest_scale: Vector3 = Vector3.ONE
var hit_tween: Tween = null
var flash_tween: Tween = null
var owns_pounce_slot := false
var flank_offset_phase: float = 0.0
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
	flank_offset_phase = randf() * TAU
	add_to_group("enemies")

	# Physics Layer: Layer 3 (bit 4: Enemy), Mask: Layer 1 (World) | Layer 2 (Player)
	collision_layer = 4
	collision_mask = 1 | 2

	_build_visuals()
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
	if body.is_in_group("player") or body.name == "Player" or body.is_class("PlayerController"):
		target_player = body
		_enter_tracking()

func _on_detection_body_exited(body: Node3D) -> void:
	if body == target_player:
		target_player = null
		_enter_idle()

func _physics_process(delta: float) -> void:
	if dying:
		return
	# 1. 3D Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# 2. Knockback override
	if knockback_timer > 0.0:
		knockback_timer -= delta
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		knockback_velocity.x = lerpf(knockback_velocity.x, 0.0, 9.0 * delta)
		knockback_velocity.z = lerpf(knockback_velocity.z, 0.0, 9.0 * delta)
		move_and_slide()
		return

	# 3. State Machine (driven by signal-based target_player)
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.TRACKING:
			_process_tracking(delta)
		State.WINDUP:
			_process_windup(delta)
		State.POUNCING:
			_process_pouncing(delta)
		State.REPOSITIONING:
			_process_repositioning(delta)

	move_and_slide()

func _enter_idle() -> void:
	_release_slot()
	current_state = State.IDLE
	velocity.x = 0.0
	velocity.z = 0.0
	state_timer = randf_range(0.3, 0.8)

func _process_idle(delta: float) -> void:
	state_timer -= delta
	if target_player and is_instance_valid(target_player):
		_enter_tracking()
		return

	if state_timer <= 0.0:
		state_timer = randf_range(0.5, 1.2)

func _enter_tracking() -> void:
	current_state = State.TRACKING
	state_timer = randf_range(2.0, 4.0)

func _process_tracking(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		target_player = null
		_enter_idle()
		return

	var to_player = target_player.global_position - global_position
	to_player.y = 0.0
	var dist = to_player.length()

	if dist > detection_radius * 1.5:
		target_player = null
		_enter_idle()
		return

	# Ready to pounce
	if dist <= attack_reach:
		_enter_windup(to_player.normalized())
		return

	# Fast scuttling movement with flanking wave
	flank_offset_phase += delta * 6.0
	var forward = to_player.normalized()
	var lateral = Vector3(-forward.z, 0.0, forward.x) * sin(flank_offset_phase) * 0.4
	var move_dir = (forward + lateral).normalized()

	velocity.x = move_dir.x * scuttle_speed
	velocity.z = move_dir.z * scuttle_speed

	# Rotate toward movement
	if move_dir.length_squared() > 0.001:
		var target_rot_y = atan2(-move_dir.x, -move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, 10.0 * delta)

func _release_slot() -> void:
	if owns_pounce_slot and is_inside_tree():
		var pack := get_tree().root
		pack.set_meta("roach_attack_slots", maxi(0, int(pack.get_meta("roach_attack_slots", 0)) - 1))
	owns_pounce_slot = false

func _exit_tree() -> void:
	_release_slot()

func _enter_windup(dir: Vector3) -> void:
	var pack := get_tree().root
	var slots := int(pack.get_meta("roach_attack_slots", 0))
	if slots >= 2:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	pack.set_meta("roach_attack_slots", slots + 1)
	owns_pounce_slot = true
	current_state = State.WINDUP
	state_timer = 0.35
	pounce_direction = dir
	velocity.x = 0.0
	velocity.z = 0.0
	_play_sfx(0.25, 1300.0, 0.85)
	if visual_mesh:
		_flash_hit_visual(true)
		var cue := create_tween()
		cue.tween_property(visual_mesh, "scale", rest_scale * Vector3(1.3, 0.5, 1.3), 0.1)
	print_verbose("[SludgeRoach] wind-up (0.35s)")

func _process_windup(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_enter_pouncing(pounce_direction)

func _enter_pouncing(dir: Vector3) -> void:
	current_state = State.POUNCING
	pounce_direction = dir
	state_timer = 0.4
	velocity.x = pounce_direction.x * pounce_speed
	velocity.z = pounce_direction.z * pounce_speed
	velocity.y = 2.0 # Little leap

	# Quick squash visual
	if visual_mesh:
		var tween = create_tween()
		tween.tween_property(visual_mesh, "scale", rest_scale * Vector3(0.7, 1.4, 0.7), 0.1)
		tween.tween_property(visual_mesh, "scale", rest_scale * Vector3(1.3, 0.7, 1.3), 0.15)

func _process_pouncing(delta: float) -> void:
	state_timer -= delta

	# Check contact with player during pounce
	if target_player and is_instance_valid(target_player):
		var offset := target_player.global_position - global_position
		if Vector2(offset.x, offset.z).length() <= 1.4 and absf(offset.y) <= 2.0:
			if target_player.has_method("take_damage"):
				target_player.call("take_damage", bite_damage)
				print_verbose("[SludgeRoach] %s pounce bit player! Dealt %d damage" % [name, bite_damage])
			_enter_repositioning()
			return

	if state_timer <= 0.0 or is_on_wall():
		_enter_repositioning()

func _enter_repositioning() -> void:
	current_state = State.REPOSITIONING
	state_timer = 1.2
	_release_slot()
	_reset_flash_visual()
	if visual_mesh:
		var recover := create_tween()
		recover.tween_property(visual_mesh, "scale", rest_scale, 0.15)
	# Scuttle backward or to the side
	var away_dir = -pounce_direction
	if randf() > 0.5:
		away_dir = Vector3(-pounce_direction.z, 0.0, pounce_direction.x)
	velocity.x = away_dir.x * 2.0
	velocity.z = away_dir.z * 2.0

func _process_repositioning(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		if target_player and is_instance_valid(target_player):
			_enter_tracking()
		else:
			_enter_idle()

## Public damage reception
func take_damage(amount: int, knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if current_health <= 0:
		return

	if current_state == State.REPOSITIONING:
		amount = int(ceil(amount * 1.5))
	current_health -= amount
	print_verbose("[SludgeRoach] %s took %d damage! HP: %d/%d" % [name, amount, max(0, current_health), max_health])

	_flash_hit_visual()
	_apply_squash_and_stretch()
	_apply_knockback(knockback_dir)

	if current_health <= 0:
		_die()

func _flash_hit_visual(is_state: bool = false) -> void:
	if visual_mesh and is_instance_valid(visual_mesh):
		var alpha = 0.3 if is_state else 0.55
		var energy = 0.9 if is_state else 0.5
		var flash_mat := EnemyModel.tint_material(Color(1.0, 0.2, 0.15), alpha, energy)
		EnemyModel.tint(visual_mesh, flash_mat)

		if flash_tween and flash_tween.is_valid():
			flash_tween.kill()
		flash_tween = create_tween()
		flash_tween.tween_interval(0.75 if current_state == State.WINDUP else 0.25)
		flash_tween.tween_callback(Callable(self, "_reset_flash_visual"))

func _reset_flash_visual() -> void:
	if is_instance_valid(visual_mesh):
		EnemyModel.untint(visual_mesh)

func _apply_squash_and_stretch() -> void:
	if visual_mesh and is_instance_valid(visual_mesh):
		if hit_tween and hit_tween.is_valid():
			hit_tween.kill()
		hit_tween = create_tween()
		hit_tween.tween_property(visual_mesh, "scale", rest_scale * Vector3(1.3, 0.6, 1.3), 0.06)
		hit_tween.tween_property(visual_mesh, "scale", rest_scale * Vector3(0.8, 1.3, 0.8), 0.1)
		hit_tween.tween_property(visual_mesh, "scale", rest_scale, 0.1)

func _apply_knockback(override_dir: Vector3 = Vector3.ZERO) -> void:
	var impulse = 10.0 # Fragile roach gets launched back
	if override_dir != Vector3.ZERO:
		knockback_velocity = override_dir.normalized() * impulse * clampf(override_dir.length(), 1.0, 1.6)
	else:
		var dir = Vector3.ZERO
		if target_player and is_instance_valid(target_player):
			var away = global_position - target_player.global_position
			away.y = 0.0
			dir = away.normalized() if away.length_squared() > 0.001 else -transform.basis.z
		else:
			dir = -transform.basis.z
		knockback_velocity = dir * impulse

	knockback_timer = 0.22

func _build_visuals() -> void:
	var model := EnemyModel.attach(self, model_path, model_height, 0.0, model_yaw)
	if model:
		visual_mesh = model
	else:
		_build_csg_visuals()

	# Collision
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.8, 0.5, 1.1)
	col.shape = box
	col.position = Vector3(0.0, 0.25, 0.0)
	add_child(col)

func _build_csg_visuals() -> void:
	var csg := CSGSphere3D.new()
	csg.name = "RoachMesh"
	csg.radius = 0.45
	csg.radial_segments = 8
	csg.rings = 6
	rest_scale = Vector3(0.8, 0.4, 1.3) * 1.4 # Flattened beetle form
	csg.scale = rest_scale
	csg.position = Vector3(0.0, 0.25, 0.0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("#c9541a") # orange-brown
	mat.metallic = 0.5
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.18, 0.63, 1.0) # magenta underglow
	csg.material = mat
	add_child(csg)
	
	var head_wedge = CSGBox3D.new()
	head_wedge.name = "HeadWedge"
	head_wedge.size = Vector3(0.5, 0.2, 0.4)
	head_wedge.position = Vector3(0, 0, -0.6) # Front facing (Z is backwards usually? No, in Godot forward is -Z)
	head_wedge.material = mat.duplicate()
	(head_wedge.material as StandardMaterial3D).emission_energy_multiplier = 2.0
	csg.add_child(head_wedge)
	visual_mesh = csg

func _die() -> void:
	if dying:
		return
	_release_slot()
	dying = true
	current_health = 0
	set_physics_process(false)
	remove_from_group("enemies")
	FX.burst(self, Color(0.4, 0.7, 0.1), 10, 0.25, 90)
	print_verbose("[SludgeRoach] %s squashed! Sludge splattered." % name)
	var tree = get_tree()
	if tree:
		var p = tree.get_first_node_in_group("player")
		if not p and tree.current_scene:
			p = tree.current_scene.find_child("Player", true, false)
		if p and p.has_method("gain_xp"):
			p.call("gain_xp", 15)

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 0.001, 0.15)
	tween.tween_callback(queue_free)
