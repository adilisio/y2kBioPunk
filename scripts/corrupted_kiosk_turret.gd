extends CharacterBody3D

## CorruptedKioskTurret (Stationary Artillery Enemy)
## A derelict mall photo/beeper kiosk overtaken by bio-organic mutation.
## Roots into the floor and launches arcing bio-sludge artillery mortars at the player.
## Uses DetectionArea3D signal-based aggro and explicit collision layers.

enum State {
	IDLE,
	TRACKING,
	CHARGING,
	FIRING,
	COOLDOWN
}

@export_category("Combat & Stats")
@export var max_health: int = 120
var current_health: int = 120
@export var detection_range: float = 16.0
@export var min_attack_range: float = 6.0
@export var mortar_damage: int = 20
@export var charge_time: float = 0.8
@export var cooldown_time: float = 2.2
@export var mortar_scene: PackedScene

var current_state: State = State.IDLE
var state_timer: float = 0.0
var target_player: Node3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# Visual Nodes
@export var model_path: String = "res://assets/models/kiosk_turret.glb"
@export var model_height: float = 1.8
@export var model_yaw: float = 0.0
var visual_root: Node3D = null
var screen_light: OmniLight3D = null
var body_mesh: CSGBox3D = null
var head_pivot: Node3D = null
var barrel_mesh: CSGCylinder3D = null
var screen_mesh: CSGBox3D = null
var screen_mat: StandardMaterial3D = null
var hit_tween: Tween = null
var flash_tween: Tween = null
var charge_tween: Tween = null
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
		sphere.radius = detection_range
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
		if current_state == State.IDLE:
			_enter_tracking()

func _on_detection_body_exited(body: Node3D) -> void:
	if body == target_player:
		target_player = null
		_enter_idle()

func _physics_process(delta: float) -> void:
	if dying:
		return
	# 1. Apply gravity (stationary, but settles on floor)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	velocity.x = 0.0
	velocity.z = 0.0

	# 2. State machine (driven cleanly by target_player signals)
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.TRACKING:
			_process_tracking(delta)
		State.CHARGING:
			_process_charging(delta)
		State.FIRING:
			_process_firing(delta)
		State.COOLDOWN:
			_process_cooldown(delta)

	move_and_slide()

func _enter_idle() -> void:
	current_state = State.IDLE
	state_timer = 0.5
	_set_screen_color(Color(0.2, 0.8, 0.4, 1.0))

func _process_idle(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0 and target_player and is_instance_valid(target_player):
		var dist = global_position.distance_to(target_player.global_position)
		if dist <= detection_range and dist >= min_attack_range:
			_enter_tracking()

func _enter_tracking() -> void:
	current_state = State.TRACKING
	state_timer = 0.8
	_play_sfx(0.35, 500.0)
	_set_screen_color(Color(0.9, 0.7, 0.1, 1.0))

func _process_tracking(delta: float) -> void:
	state_timer -= delta
	if not target_player or not is_instance_valid(target_player):
		_enter_idle()
		return

	var to_player = target_player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() > 0.001 and head_pivot and is_instance_valid(head_pivot):
		var target_rot = atan2(to_player.x, to_player.z)
		head_pivot.rotation.y = lerp_angle(head_pivot.rotation.y, target_rot, 6.0 * delta)

	if state_timer <= 0.0:
		_enter_charging()

func _enter_charging() -> void:
	current_state = State.CHARGING
	state_timer = charge_time
	_play_sfx(0.35, 1000.0)
	_set_screen_color(Color(1.0, 0.1, 0.1, 1.0))

	if head_pivot and is_instance_valid(head_pivot):
		if charge_tween and charge_tween.is_valid():
			charge_tween.kill()
		charge_tween = create_tween()
		charge_tween.tween_property(head_pivot, "scale", Vector3(1.2, 0.8, 1.2), charge_time * 0.5)
		charge_tween.tween_property(head_pivot, "scale", Vector3(0.9, 1.3, 0.9), charge_time * 0.5)

func _process_charging(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_enter_firing()

func _enter_firing() -> void:
	current_state = State.FIRING
	_launch_mortar()
	_enter_cooldown()

func _process_firing(_delta: float) -> void:
	pass

func _enter_cooldown() -> void:
	current_state = State.COOLDOWN
	state_timer = cooldown_time
	_set_screen_color(Color(0.3, 0.3, 0.4, 1.0))
	if charge_tween and charge_tween.is_valid():
		charge_tween.kill()
	if head_pivot and is_instance_valid(head_pivot):
		head_pivot.scale = Vector3.ONE

func _process_cooldown(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		if target_player and is_instance_valid(target_player):
			_enter_tracking()
		else:
			_enter_idle()

func _launch_mortar() -> void:
	if not target_player or not is_instance_valid(target_player):
		return

	var target_pos = target_player.global_position
	var forward_dir = head_pivot.global_transform.basis.z.normalized() if head_pivot else transform.basis.z.normalized()
	var spawn_pos = (head_pivot.global_position if head_pivot else global_position) + (forward_dir * 1.1) + Vector3(0.0, 0.4, 0.0)
	if target_player is CharacterBody3D:
		target_pos += target_player.velocity * 0.6
	var offset: Vector3 = target_pos - spawn_pos
	offset.y = 0.0
	if offset.length_squared() < 0.001:
		offset = forward_dir
	target_pos = spawn_pos + offset.normalized() * clampf(offset.length(), 6.0, 18.0)
	target_pos = FX.floor_point(self, target_pos)

	print_verbose("[CorruptedKioskTurret] %s FIRED bio-sludge artillery at %s!" % [name, target_pos])

	var mortar: Node3D = null
	if mortar_scene and mortar_scene.can_instantiate():
		mortar = mortar_scene.instantiate()
	else:
		var mortar_script = load("res://scripts/turret_mortar.gd") if ResourceLoader.exists("res://scripts/turret_mortar.gd") else null
		if not mortar_script and ResourceLoader.exists("res://turret_mortar.gd"):
			mortar_script = load("res://turret_mortar.gd")
		if mortar_script:
			mortar = mortar_script.new()
		else:
			mortar = Area3D.new()

	mortar.name = "TurretMortar_%d" % randi()


	var spawn_parent = get_tree().current_scene if (get_tree() and get_tree().current_scene) else get_parent()
	if spawn_parent:
		spawn_parent.add_child(mortar)
		if mortar.has_method("setup"):
			mortar.call("setup", spawn_pos, target_pos, mortar_damage, self)
		else:
			mortar.global_position = spawn_pos

## Public damage reception
func take_damage(amount: int, knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if current_health <= 0:
		return

	current_health -= amount
	print_verbose("[CorruptedKioskTurret] %s took %d damage! HP: %d/%d" % [name, amount, max(0, current_health), max_health])

	_flash_hit_visual()
	_shake_hit_reaction()

	if current_health <= 0:
		_die()

func _flash_hit_visual() -> void:
	if visual_root and is_instance_valid(visual_root):
		var flash_mat := EnemyModel.tint_material(Color(1.0, 0.25, 0.1), 0.55, 0.5)
		EnemyModel.tint(visual_root, flash_mat)

		if flash_tween and flash_tween.is_valid():
			flash_tween.kill()
		flash_tween = create_tween()
		flash_tween.tween_interval(0.25)
		flash_tween.tween_callback(Callable(self, "_reset_flash_visual"))

func _reset_flash_visual() -> void:
	if visual_root and is_instance_valid(visual_root):
		EnemyModel.untint(visual_root)

func _shake_hit_reaction() -> void:
	if head_pivot and is_instance_valid(head_pivot):
		if hit_tween and hit_tween.is_valid():
			hit_tween.kill()
		hit_tween = create_tween()
		hit_tween.tween_property(head_pivot, "position", Vector3(randf_range(-0.1, 0.1), 1.6, randf_range(-0.1, 0.1)), 0.05)
		hit_tween.tween_property(head_pivot, "position", Vector3(0.0, 1.6, 0.0), 0.1)

func _set_screen_color(col: Color) -> void:
	if screen_light and is_instance_valid(screen_light):
		screen_light.light_color = col
	if screen_mesh and is_instance_valid(screen_mesh):
		if not screen_mat:
			screen_mat = StandardMaterial3D.new()
			screen_mat.emission_enabled = true
			screen_mesh.material = screen_mat
		screen_mat.albedo_color = col
		screen_mat.emission = col

func _build_visuals() -> void:
	if visual_root:
		return

	head_pivot = Node3D.new()
	head_pivot.name = "TurretHead"
	head_pivot.position = Vector3(0.0, 1.6, 0.0)
	add_child(head_pivot)

	# Screen glow light follows the state colour (idle green, tracking amber, charging red).
	screen_light = OmniLight3D.new()
	screen_light.name = "ScreenGlow"
	screen_light.position = Vector3(0.0, 0.2, 0.8)
	screen_light.omni_range = 3.5
	screen_light.light_energy = 1.4
	screen_light.shadow_enabled = false
	head_pivot.add_child(screen_light)

	screen_mesh = CSGBox3D.new()
	screen_mesh.name = "CRTScreen"
	screen_mesh.size = Vector3(0.6, 0.45, 0.1)
	screen_mesh.position = Vector3(0.0, 0.25, 0.6)
	head_pivot.add_child(screen_mesh)

	var model := EnemyModel.attach(head_pivot, model_path, model_height, -1.6, model_yaw)
	if model:
		visual_root = model
		_add_collision()
		return

	body_mesh = CSGBox3D.new()
	body_mesh.name = "KioskBody"
	body_mesh.size = Vector3(1.4, 1.6, 1.4)
	body_mesh.position = Vector3(0.0, 0.8, 0.0)
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.1, 0.1, 0.12, 1.0) # dark chassis
	body_mat.metallic = 0.4
	body_mat.roughness = 0.7
	body_mesh.material = body_mat
	add_child(body_mesh)
	visual_root = body_mesh

	
	var antenna = CSGCylinder3D.new()
	antenna.name = "Antenna"
	antenna.radius = 0.05
	antenna.height = 0.8
	antenna.position = Vector3(0.4, 0.4, -0.4)
	var antenna_light = CSGSphere3D.new()
	antenna_light.name = "AntennaLight"
	antenna_light.radius = 0.12
	antenna_light.position = Vector3(0.0, 0.4, 0.0)
	var antenna_mat = StandardMaterial3D.new()
	antenna_mat.albedo_color = Color(1.0, 0.18, 0.63, 1.0) # magenta
	antenna_mat.emission_enabled = true
	antenna_mat.emission = Color(1.0, 0.18, 0.63, 1.0)
	antenna_mat.emission_energy_multiplier = 2.0
	antenna_light.material = antenna_mat
	antenna.add_child(antenna_light)
	head_pivot.add_child(antenna)

	barrel_mesh = CSGCylinder3D.new()
	barrel_mesh.name = "BioBarrel"
	barrel_mesh.radius = 0.18
	barrel_mesh.height = 0.9
	barrel_mesh.rotation.x = deg_to_rad(75.0)
	barrel_mesh.position = Vector3(0.0, 0.35, 0.3)
	var barrel_mat = StandardMaterial3D.new()
	barrel_mat.albedo_color = Color(0.18, 0.55, 0.22, 1.0)
	barrel_mesh.material = barrel_mat
	head_pivot.add_child(barrel_mesh)

	_add_collision()

func _add_collision() -> void:
	var col_shape = CollisionShape3D.new()
	var box_col = BoxShape3D.new()
	box_col.size = Vector3(1.5, 2.2, 1.5)
	col_shape.shape = box_col
	col_shape.position = Vector3(0.0, 1.1, 0.0)
	add_child(col_shape)

func _die() -> void:
	if dying:
		return
	dying = true
	current_health = 0
	set_physics_process(false)
	remove_from_group("enemies")
	FX.burst(self, Color(1, 0.5, 0.05), 10, 0.25, 80)
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()
	if hit_tween and hit_tween.is_valid():
		hit_tween.kill()
	if charge_tween and charge_tween.is_valid():
		charge_tween.kill()
	print_verbose("[CorruptedKioskTurret] %s collapsed! Bio-circuitry breached." % name)
	
	var tree = get_tree()
	if tree:
		var p = tree.get_first_node_in_group("player")
		if not p and tree.current_scene:
			p = tree.current_scene.find_child("Player", true, false)
		if p and p.has_method("gain_xp"):
			p.call("gain_xp", 40)

	var t = create_tween()
	t.tween_property(self, "scale", Vector3.ONE * 0.001, 0.15)
	t.tween_callback(queue_free)
