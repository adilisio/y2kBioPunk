extends Area3D

## DiskProjectile (Y2K Optical Mini-Disc Projectile)
## Fired by the PlayerController Disk Launcher off-hand weapon.
## High-velocity spinning projectile dealing impact damage and directional knockback.

@export var speed: float = 24.0
@export var damage: float = 25.0
@export var lifetime: float = 2.5

var direction: Vector3 = Vector3.FORWARD
var shooter: Node = null
var is_active: bool = true
var visual_disc: CSGCylinder3D = null

func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1 | 2 | 4 # World, entities, enemies

	# Generate low-poly spinning CD disc visual
	_create_visuals()

	body_entered.connect(_on_body_entered)
	# area_entered.connect(_on_area_entered) # Excluded to ignore rail GrindArea and world sensors

func setup_projectile(p_direction: Vector3, p_speed: float, p_damage: float, p_shooter: Node = null) -> void:
	direction = p_direction.normalized()
	speed = p_speed
	damage = p_damage
	shooter = p_shooter
	look_at(global_position + direction, Vector3.UP)

func _process(delta: float) -> void:
	if not is_active:
		return

	# Move forward along trajectory
	global_position += direction * speed * delta

	# Spin the mini-disc at high RPM
	if visual_disc:
		visual_disc.rotation.y += 35.0 * delta

	lifetime -= delta
	if lifetime <= 0.0:
		_destroy()

func _create_visuals() -> void:
	visual_disc = CSGCylinder3D.new()
	visual_disc.name = "DiscMesh"
	visual_disc.radius = 0.28
	visual_disc.height = 0.02
	visual_disc.sides = 12

	# Rainbow holographic CD material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.9, 1.0, 1.0)
	mat.metallic = 0.95
	mat.roughness = 0.15
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.6, 1.0, 1.0)
	visual_disc.material = mat
	add_child(visual_disc)

	# Collision Shape
	var col_shape = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 0.35
	col_shape.shape = sphere
	add_child(col_shape)

func _on_body_entered(body: Node3D) -> void:
	if not is_active or body == shooter or body == self:
		return
	_apply_hit(body)

func _on_area_entered(area: Area3D) -> void:
	if not is_active or area == shooter or area == self:
		return
	var target = area.get_parent() if area.get_parent() else area
	if target != shooter:
		_apply_hit(target)

func _apply_hit(target: Node) -> void:
	is_active = false
	if shooter and is_instance_valid(shooter) and shooter.has_method("play_sfx"):
		shooter.call("play_sfx", "disk_hit")
	if target and is_instance_valid(target):
		if target.has_method("take_damage"):
			target.call("take_damage", int(damage), direction * 8.5)
			print("[DiskProjectile] Impact! Dealt %d damage to %s" % [int(damage), target.name])
		elif target.is_in_group("enemies"):
			if target.has_method("take_damage"):
				target.call("take_damage", int(damage))
	_destroy()

func _destroy() -> void:
	is_active = false
	queue_free()
