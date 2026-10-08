extends Node
## Draw the combat shader variants before the first encounter. Hidden/out-of-frustum
## meshes do not submit draw calls. These subpixel probes sit just inside the camera's
## upper-left corner, in front of world geometry and underneath the pager.
## This warms resources only: never invoke damage, hit-stop, or an enemy's state machine.

const FX = preload("res://scripts/turret_mortar.gd")
const DISK = preload("res://scripts/disk_projectile.gd")
const SCRIPT_BUDGET_USEC := 3000
const MUTED_BUS := &"EffectWarmupMuted"
# Retain one material per warmed shader feature set after the probes are freed.
# Otherwise the last material can release the generated shader before combat.
# These are never handed to gameplay, where tint tweens must stay independent.
static var _shader_materials: Dictionary = {}
const SOUND_RECIPES := [
	Vector3(0.16, 1800, 0.2), # cicada lunge
	Vector3(0.25, 1300, 0.85), # roach wind-up
	Vector3(0.35, 500, 0), Vector3(0.35, 1000, 0), # turret tracking/charge
	Vector3(0.18, 90, 0.4), # mortar launch
	Vector3(0.8, 1600, 0.35), # Queen charge
	Vector3(1.5, 950, 0.55), # Queen summon handshake
	Vector3(0.25, 700, 0.65), Vector3(0.25, 90, 0.65), # cicada/roach death
	Vector3(0.25, 80, 0.65), Vector3(0.25, 65, 0.65), # turret death/splash
	Vector3(0.35, 45, 0.65), Vector3(0.25, 60, 0.65), # Queen blast/death
]
const BURST_COLORS := [
	Color(0.1, 1, 0.7), Color(0.4, 0.7, 0.1), Color(1, 0.5, 0.05),
	Color(1, 0.35, 0.02), Color(1, 0.3, 0.05), Color(1, 0.1, 0.5),
]

# Also used by the harness's firstuse diagnostic; ordinary scene entry uses _ready.
var auto_start := true
var muted_bus := StringName("%s_%d" % [MUTED_BUS, get_instance_id()])
var _stage: Node3D
var _player: Node3D
var _camera: Camera3D
var _owns_bus := false

func _ready() -> void:
	if auto_start:
		_begin.call_deferred()

func _begin() -> void:
	# Child _ready runs before the mall builder's _ready. Wait for the completed build.
	await get_tree().process_frame
	prepare(get_tree().get_first_node_in_group("player") as Node3D)
	var jobs := make_jobs()
	var slice_start := Time.get_ticks_usec()
	for job in jobs:
		(job.run as Callable).call()
		if Time.get_ticks_usec() - slice_start >= SCRIPT_BUDGET_USEC:
			await get_tree().process_frame
			slice_start = Time.get_ticks_usec()
	# Keep every probe alive through two render submissions (also works with Dummy).
	await get_tree().process_frame
	await get_tree().process_frame
	queue_free()

func prepare(player: Node3D) -> void:
	_player = player
	_stage = Node3D.new()
	_stage.name = "WarmupProbes"
	add_child(_stage)
	_camera = get_viewport().get_camera_3d()
	if _camera:
		_stage.global_position = _camera.project_position(Vector2(2, 2), 1.0)
	else:
		_stage.position = Vector3(0, -1000, 0)
	_stage.scale = Vector3.ONE * 0.0001
	if AudioServer.get_bus_index(muted_bus) == -1:
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, muted_bus)
		AudioServer.set_bus_volume_db(index, -80)
		AudioServer.set_bus_mute(index, true)
		_owns_bus = true

func _process(_delta: float) -> void:
	# Follow startup camera settling so a probe cannot slip outside the frustum.
	if is_instance_valid(_stage) and is_instance_valid(_camera):
		_stage.global_position = _camera.project_position(Vector2(2, 2), 1.0)

func make_jobs() -> Array[Dictionary]:
	var jobs: Array[Dictionary] = [
		{"label": "enemy overlays", "run": _overlays},
		{"label": "player hurt overlay", "run": _hurt_overlay},
		{"label": "mortar + landing marker", "run": _mortar},
		{"label": "disk projectile", "run": _disk},
		{"label": "Queen outline + telegraph + blast rings", "run": _queen_rings},
		{"label": "native grind slam material", "run": _slam},
		{"label": "player flamethrower particles", "run": _flame},
	]
	# Dummy has no GPU to warm; avoid its unsupported skinned-mesh operations.
	# Still synthesize the exact streams and fill the real burst resource cache.
	var headless := DisplayServer.get_name() == "headless"
	if headless:
		jobs.clear()
	for color in BURST_COLORS:
		var build := FX.burst_kit.bind(color) if headless else _burst.bind(color)
		jobs.append({"label": "burst " + color.to_html(false), "run": build})
	for recipe in SOUND_RECIPES:
		jobs.append({"label": "sound %s" % recipe, "run": _sound.bind(recipe)})
	return jobs

func _mesh(material: Material, mesh: Mesh = null) -> MeshInstance3D:
	var probe := MeshInstance3D.new()
	probe.mesh = mesh if mesh else SphereMesh.new()
	probe.material_override = material
	_retain(material)
	_stage.add_child(probe)
	return probe

func _retain(material: Material) -> void:
	if material is StandardMaterial3D:
		var key := "%d|%d|%d|%d" % [material.transparency, material.shading_mode, material.cull_mode, int(material.emission_enabled)]
		if not _shader_materials.has(key):
			_shader_materials[key] = material

func _overlays() -> void:
	# Wind-up uses the hit tint; recovery untints. Turret ramp changes its light,
	# not an overlay. Colors/alpha/energy are uniforms, all share one shader variant.
	var materials := [
		EnemyModel.tint_material(Color(1, 0.12, 0.12), 0.55, 0.45),
		EnemyModel.tint_material(Color(1, 0.2, 0.15), 0.55, 0.5),
		EnemyModel.tint_material(Color(1, 0.25, 0.1), 0.55, 0.5),
		EnemyModel.tint_material(Color(1, 0.25, 0.25), 0.55, 0.5),
		EnemyModel.tint_material(Color(1, 0.6, 0.1), 0.35, 0.5),
		EnemyModel.tint_material(Color(1, 0.15, 0.5), 0.35, 0.5),
	]
	for mat in materials:
		_retain(mat)
		var probe := _mesh(null)
		EnemyModel.tint(probe, mat)
	# Submit the imported vertex format as well as the primitive fallback format.
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var meshes := EnemyModel.mesh_instances(enemy)
		if not meshes.is_empty():
			var probe := _mesh(null, meshes[0].mesh)
			EnemyModel.tint(probe, materials[0])
			break
	var tween := _stage.create_tween()
	tween.tween_property(materials[0], "emission_energy_multiplier", 0.9, 0.02)

func _hurt_overlay() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_retain(mat)
	var probe := _mesh(null)
	probe.material_overlay = mat
	if not is_instance_valid(_player):
		return
	var visuals := _player.get_node_or_null("Visuals") as Node3D
	if visuals:
		# Keep the mesh's relative skeleton paths and vertex format intact. The
		# duplicate owns its skeleton; never bind probes to the live player's bones.
		var copy := visuals.duplicate(0) as Node3D
		copy.process_mode = Node.PROCESS_MODE_DISABLED
		_stage.add_child(copy)
		for skin_probe in copy.find_children("Mesh_*", "MeshInstance3D", true, false):
			skin_probe.material_overlay = mat

func _disable_area(area: Area3D) -> void:
	area.process_mode = Node.PROCESS_MODE_DISABLED
	area.collision_layer = 0
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = false

func _mortar() -> void:
	var mortar := FX.new()
	_disable_area(mortar)
	_stage.add_child(mortar) # Real _ready builds the projectile and trail.
	_disable_area(mortar) # _ready sets masks; clear again before any physics tick.
	for visual in EnemyModel.mesh_instances(mortar):
		_retain(visual.material_override)
		for surface in visual.mesh.get_surface_count():
			_retain(visual.mesh.surface_get_material(surface))
	# setup() also plays audio and schedules an explosion. Only draw its marker.
	var marker := CSGCylinder3D.new()
	marker.radius = 2.2
	marker.height = 0.02
	marker.sides = 48
	marker.material = _ring_material(Color(1, 0.05, 0.02, 0.4), Color.RED)
	_stage.add_child(marker)

func _disk() -> void:
	var disk := DISK.new()
	_disable_area(disk)
	_stage.add_child(disk)
	_disable_area(disk)
	disk.is_active = false
	_retain(disk.visual_disc.material)

func _ring_material(color: Color, emission: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = emission
	_retain(mat)
	return mat

func _queen_rings() -> void:
	# Match _outline / _build_shared_visuals without spawning a boss or signals.
	for color in [Color(1, 0.05, 0.02, 0.6), Color(1, 0.4, 0.1, 0.8)]:
		var torus := TorusMesh.new()
		torus.inner_radius = 6.93
		torus.outer_radius = 7
		torus.rings = 64
		torus.ring_segments = 8
		_mesh(_ring_material(color, color), torus)
	var ring := CSGCylinder3D.new()
	ring.radius = 7
	ring.height = 0.05
	ring.sides = 24
	ring.material = _ring_material(Color(1, 0.1, 0.05, 0.25), Color.RED)
	_stage.add_child(ring)

func _slam() -> void:
	# Native execute_grind_slam() also damages enemies and changes time_scale.
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1
	mesh.bottom_radius = 1
	mesh.height = 0.06
	mesh.radial_segments = 32
	mesh.rings = 1
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.15, 0.95, 1, 0.85)
	_mesh(mat, mesh)

func _particles(particles: GPUParticles3D) -> void:
	_stage.add_child(particles)
	# Keep particles within the frustum probe instead of spraying across the view.
	particles.speed_scale = 0.001
	particles.preprocess = 0.05
	particles.emitting = true

func _flame() -> void:
	if not is_instance_valid(_player):
		return
	var source := _player.find_child("FlamethrowerParticles", true, false) as GPUParticles3D
	if source:
		var particles := source.duplicate(0) as GPUParticles3D
		particles.position = Vector3.ZERO
		_particles(particles)

func _burst(color: Color) -> void:
	var kit := FX.burst_kit(color)
	var particles := GPUParticles3D.new()
	particles.amount = 12
	particles.one_shot = true
	particles.explosiveness = 1
	particles.lifetime = 0.45
	particles.process_material = kit.process
	particles.draw_pass_1 = kit.mesh
	_particles(particles)

func _sound(recipe: Vector3) -> void:
	var voice := AudioStreamPlayer.new()
	voice.bus = muted_bus
	voice.stream = FX.sound(recipe.x, recipe.y, recipe.z)
	add_child(voice)
	voice.play()

func _exit_tree() -> void:
	if _owns_bus:
		var index := AudioServer.get_bus_index(muted_bus)
		if index != -1:
			AudioServer.remove_bus(index)
