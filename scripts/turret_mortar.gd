extends Area3D

## TurretMortar
## Independent physics projectile launched by CorruptedKioskTurret.
## Self-managed physics and lifecycle without lambda closures.

var velocity: Vector3 = Vector3.ZERO
var damage: int = 20
var lifetime: float = 4.0
var fall_gravity: float = 9.8
var shooter: Node = null

func setup(spawn_pos: Vector3, init_vel: Vector3, dmg: int, source_shooter: Node = null) -> void:
	if is_inside_tree():
		global_position = spawn_pos
	else:
		position = spawn_pos
	velocity = init_vel
	damage = dmg
	shooter = source_shooter

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 2 # World & Player
	body_entered.connect(_on_body_entered)

	# Lightweight visual mesh
	var proj_mesh = MeshInstance3D.new()
	proj_mesh.name = "MortarVisual"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.32
	sphere_mesh.height = 0.64
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.95, 0.2, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.8, 0.2, 1.0)
	sphere_mesh.material = mat
	proj_mesh.mesh = sphere_mesh
	add_child(proj_mesh)

	var col = CollisionShape3D.new()
	col.name = "MortarCollision"
	var sphere = SphereShape3D.new()
	sphere.radius = 0.35
	col.shape = sphere
	add_child(col)

func _physics_process(delta: float) -> void:
	velocity.y -= fall_gravity * delta
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0 or global_position.y < -2.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(body) or body == shooter:
		return
	if body.is_in_group("enemies"):
		return
	if body.has_method("take_damage"):
		body.call("take_damage", damage)
		print("[TurretMortar] Direct impact! Dealt %d damage to %s" % [damage, body.name])
	queue_free()
