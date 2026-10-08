extends Area3D

## TurretMortar
## Independent physics projectile launched by CorruptedKioskTurret.
## Self-managed physics and lifecycle without lambda closures.

var velocity: Vector3 = Vector3.ZERO
var damage: int = 20
var lifetime: float = 4.0
var fall_gravity: float = 9.8
var shooter: Node = null
var impact_target := Vector3.ZERO
var flight_time := 1.0
var elapsed := 0.0
var exploded := false
var landing_marker: CSGCylinder3D

## Generated streams and burst materials are cached: synthesising a 0.35 s cue costs ~3 ms of GDScript and
## building burst materials compiles new shader pipelines, and both used to run inside physics callbacks on
## every hit, lunge, launch and splash (measured 11 ms physics spikes). Keys are quantised so near-identical
## cues share one stream.
static var _sound_cache: Dictionary = {}
static var _burst_cache: Dictionary = {}

static func sound(duration: float, frequency: float, noise: float = 0.0) -> AudioStreamWAV:
	var key := "%d|%d|%d" % [int(round(duration * 100.0)), int(round(frequency)), int(round(noise * 100.0))]
	var cached = _sound_cache.get(key)
	if cached:
		return cached
	var wav := _synthesize(duration, frequency, noise)
	_sound_cache[key] = wav
	return wav

static func _synthesize(duration: float, frequency: float, noise: float) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(int(duration * wav.mix_rate))
	for i in data.size():
		var t := float(i) / wav.mix_rate
		var envelope := sin(PI * t / duration) * (1.0 - t / duration)
		var sample := (sin(TAU * frequency * t * (1.0 - 0.35 * t / duration)) * (1.0 - noise) + randf_range(-1.0, 1.0) * noise) * envelope
		data[i] = int(clampf(sample, -1.0, 1.0) * 100.0) & 255 # signed PCM8
	wav.data = data
	return wav

static func burst_kit(color: Color) -> Dictionary:
	var key := color.to_html(false)
	var kit = _burst_cache.get(key)
	if kit:
		return kit
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 2.0
	process.initial_velocity_max = 5.0
	process.gravity = Vector3(0, -9.8, 0)
	process.color = color
	var mesh := SphereMesh.new()
	mesh.radius = 0.07
	mesh.height = 0.14
	mesh.radial_segments = 8
	mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	mesh.material = material
	kit = {"process": process, "mesh": mesh}
	_burst_cache[key] = kit
	return kit

static func floor_point(owner_node: Node3D, at: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3.0, at - Vector3.UP * 20.0, 1)
	query.exclude = [owner_node.get_rid()] if owner_node is CollisionObject3D else []
	var hit := owner_node.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position + Vector3.UP * 0.04 if not hit.is_empty() else Vector3(at.x, 0.04, at.z)

static func burst(owner_node: Node3D, color: Color, count: int, duration: float = 0.3, frequency: float = 100.0) -> void:
	var effect := Node3D.new()
	owner_node.get_parent().add_child(effect)
	effect.global_position = owner_node.global_position
	var particles := GPUParticles3D.new()
	particles.amount = count
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 0.45
	var kit := burst_kit(color)
	particles.process_material = kit["process"]
	particles.draw_pass_1 = kit["mesh"]
	effect.add_child(particles)
	var voice := AudioStreamPlayer3D.new()
	voice.stream = sound(duration, frequency, 0.65)
	effect.add_child(voice)
	voice.play()
	var cleanup := effect.create_tween()
	cleanup.tween_interval(0.8)
	cleanup.tween_callback(effect.queue_free)

func setup(spawn_pos: Vector3, target_pos: Vector3, dmg: int, source_shooter: Node = null) -> void:
	if is_inside_tree():
		global_position = spawn_pos
	else:
		position = spawn_pos
	impact_target = target_pos
	var horizontal := target_pos - spawn_pos
	horizontal.y = 0.0
	flight_time = clampf(horizontal.length() / 12.0, 0.65, 1.5)
	velocity = (target_pos - spawn_pos) / flight_time + Vector3.UP * (0.5 * fall_gravity * flight_time)
	damage = dmg
	shooter = source_shooter
	landing_marker = CSGCylinder3D.new()
	landing_marker.radius = 2.2
	landing_marker.height = 0.02
	landing_marker.sides = 48
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 0.05, 0.02, 0.4)
	mat.emission_enabled = true
	mat.emission = Color.RED
	landing_marker.material = mat
	get_parent().add_child(landing_marker)
	landing_marker.global_position = target_pos
	landing_marker.scale = Vector3(0.05, 1, 0.05)
	var tween := landing_marker.create_tween()
	tween.tween_property(landing_marker, "scale", Vector3.ONE, flight_time)
	var voice := AudioStreamPlayer3D.new()
	add_child(voice)
	voice.stream = sound(0.18, 90.0, 0.4)
	voice.play()

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
	mat.albedo_color = Color(1.0, 0.15, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.15, 0.6)
	sphere_mesh.material = mat
	proj_mesh.mesh = sphere_mesh
	add_child(proj_mesh)
	
	# Trail mesh
	var trail_node = MeshInstance3D.new()
	trail_node.name = "TrailVisual"
	var trail_shape = CylinderMesh.new()
	trail_shape.top_radius = 0.2
	trail_shape.bottom_radius = 0.01
	trail_shape.height = 2.0
	trail_node.mesh = trail_shape
	var trail_mat = StandardMaterial3D.new()
	trail_mat.albedo_color = Color(1.0, 0.15, 0.6, 0.5)
	trail_mat.emission_enabled = true
	trail_mat.emission = Color(1.0, 0.15, 0.6)
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_node.material_override = trail_mat
	trail_node.position = Vector3(0, 0, 1.0)
	trail_node.rotation.x = PI / 2.0
	proj_mesh.add_child(trail_node)

	var col = CollisionShape3D.new()
	col.name = "MortarCollision"
	var sphere = SphereShape3D.new()
	sphere.radius = 0.35
	col.shape = sphere
	add_child(col)

func _physics_process(delta: float) -> void:
	if exploded:
		return
	var step := minf(delta, flight_time - elapsed)
	global_position += velocity * step - Vector3.UP * (0.5 * fall_gravity * step * step)
	velocity.y -= fall_gravity * step
	elapsed += step
	if velocity.length_squared() > 0.1:
		var visual = get_node_or_null("MortarVisual")
		if visual:
			visual.look_at(global_position + velocity, Vector3.UP)
	if elapsed >= flight_time - 0.00001:
		_explode()

func _on_body_entered(body: Node) -> void:
	if not is_instance_valid(body) or body == shooter:
		return
	if body.is_in_group("enemies") or body.is_in_group("player"):
		return
	if elapsed > 0.1:
		_explode()

func _explode() -> void:
	if exploded:
		return
	exploded = true
	if is_instance_valid(landing_marker):
		landing_marker.queue_free()
	for player in get_tree().get_nodes_in_group("player"):
		var offset: Vector3 = player.global_position - global_position
		if Vector2(offset.x, offset.z).length() <= 2.2 and absf(offset.y) <= 2.5 and player.has_method("take_damage"):
			player.call("take_damage", damage, offset.normalized())
	burst(self, Color(1, 0.35, 0.02), 8, 0.25, 65.0)
	print_verbose("[TurretMortar] Splash at %s (radius 2.2m)" % global_position)
	queue_free()

func _exit_tree() -> void:
	if is_instance_valid(landing_marker):
		landing_marker.queue_free()
