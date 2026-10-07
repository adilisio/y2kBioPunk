@tool
extends Node3D

## MallGreyboxBuilder
## Procedural greybox generator for the "Flooded Mall Plaza" blockout in Godot 4.3.
## Can be triggered from the Godot Editor Inspector via the 'rebuild_level' button,
## or executed at runtime when the scene loads.

@export_category("Level Generator")
@export var auto_build_on_ready: bool = false
@export var cicada_scene: PackedScene

@export var rebuild_level: bool = false:
	set(val):
		if val:
			build_mall_greybox()
			rebuild_level = false

@export var clear_level: bool = false:
	set(val):
		if val:
			_clear_existing_geometry()
			clear_level = false

@export_category("Dimensions")
@export var plaza_size: Vector2 = Vector2(50.0, 50.0)
@export var high_wall_height: float = 4.5
@export var low_wall_height: float = 0.85
@export var pillar_radius: float = 0.6
@export var pillar_height: float = 5.0

func _ready() -> void:
	# At runtime the builder is the single source of truth for level geometry and materials:
	# always rebuild so material/lighting changes in this script show up without regenerating the .tscn.
	if auto_build_on_ready or not Engine.is_editor_hint():
		build_mall_greybox()
		if not Engine.is_editor_hint():
			_connect_runtime_rails()
	elif not Engine.is_editor_hint():
		var enemies_node = get_node_or_null("Enemies")
		if enemies_node and enemies_node.get_child_count() == 0:
			_spawn_enemies(enemies_node)
		_connect_runtime_rails()

	if not Engine.is_editor_hint():
		set_process(true)
		var p = get_node_or_null("../Player")
		if not p:
			p = get_tree().current_scene.find_child("Player", true, false) if get_tree() and get_tree().current_scene else null
		if p:
			p.add_to_group("player")

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var p = players[0]
	var cam = get_viewport().get_camera_3d()
	if not cam: return
	
	var cam_pos = cam.global_position
	var p_pos = p.global_position + Vector3(0, 1.0, 0)
	var dir = p_pos - cam_pos
	var dist = cam_pos.distance_to(p_pos)
	var dir_norm = dir / dist
	
	var pillars = get_node_or_null("LevelGeometry/StructuralPillars")
	if not pillars: return
	
	for pillar in pillars.get_children():
		if pillar is CSGCylinder3D:
			var mat = pillar.material as StandardMaterial3D
			if not mat: continue
			
			var center = pillar.global_position
			var to_center = center - cam_pos
			var t = to_center.dot(dir_norm)
			var fade = false
			if t > 0.0 and t < dist:
				var proj = cam_pos + dir_norm * t
				var dist_to_line = proj.distance_to(Vector3(center.x, clampf(proj.y, center.y - pillar.height*0.5, center.y + pillar.height*0.5), center.z))
				if dist_to_line < pillar.radius + 1.0:
					fade = true
			
			if fade:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.albedo_color.a = 0.25
			else:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				mat.albedo_color.a = 1.0

func _clear_existing_geometry() -> void:
	var existing = get_node_or_null("LevelGeometry")
	if existing:
		# Detach immediately so the rebuilt node can reuse the name; free safely afterwards.
		remove_child(existing)
		if Engine.is_editor_hint():
			existing.free()
		else:
			existing.queue_free()

	var existing_enemies = get_node_or_null("Enemies")
	if existing_enemies:
		remove_child(existing_enemies)
		if Engine.is_editor_hint():
			existing_enemies.free()
		else:
			existing_enemies.queue_free()

func build_mall_greybox() -> void:
	_clear_existing_geometry()

	var level_root = Node3D.new()
	level_root.name = "LevelGeometry"
	add_child(level_root)
	if Engine.is_editor_hint():
		level_root.owner = get_tree().edited_scene_root if get_tree() else self

	var enemies_root = Node3D.new()
	enemies_root.name = "Enemies"
	add_child(enemies_root)
	if Engine.is_editor_hint():
		enemies_root.owner = get_tree().edited_scene_root if get_tree() else self

	# Create Materials
	var mat_floor = _create_material(Color("#3b454d"), 0.9)
	var mat_flooded = _create_material(Color("#0a3a3a"), 0.1, 0.2, 0.85)
	var mat_high_wall = _create_material(Color(0.14, 0.16, 0.19), 0.75)
	var mat_low_wall = _create_material(Color(0.42, 0.46, 0.52), 0.65)
	var mat_pillar = _create_material(Color("#7f8a94"), 0.55)
	var mat_kiosk = _create_material(Color("#d7a042"), 0.55, 0.0, 0.6, Color("#ff7a1a"), 0.3)
	var mat_ramp = _create_material(Color(0.30, 0.38, 0.45), 0.60)
	var mat_strip = _create_material(Color.CYAN, 0.5, 0.0, 1.0, Color.CYAN, 1.5)

	# 1. Main Plaza Floor (50x50m)
	_add_box(level_root, "MainFloor", Vector3(plaza_size.x, 1.0, plaza_size.y), Vector3(0, -0.5, 0), mat_floor)

	# 2. Outer Perimeter Enclosure Walls (4.5m high)
	var half_x = plaza_size.x * 0.5
	var half_z = plaza_size.y * 0.5
	_add_box(level_root, "Wall_North", Vector3(plaza_size.x, high_wall_height, 1.0), Vector3(0, high_wall_height * 0.5, -half_z), mat_high_wall)
	_add_box(level_root, "Wall_South", Vector3(plaza_size.x, 1.0, 1.0), Vector3(0, 0.5, half_z), mat_high_wall)
	_add_box(level_root, "Wall_West", Vector3(1.0, high_wall_height, plaza_size.y), Vector3(-half_x, high_wall_height * 0.5, 0), mat_high_wall)
	_add_box(level_root, "Wall_East", Vector3(1.0, 1.0, plaza_size.y), Vector3(half_x, 0.5, 0), mat_high_wall)

	# 3. Sunken "Flooded Basin" Plaza (Atrium Pool)
	var basin_parent = Node3D.new()
	basin_parent.name = "SunkenAtriumBasin"
	level_root.add_child(basin_parent)
	if Engine.is_editor_hint():
		basin_parent.owner = get_tree().edited_scene_root if get_tree() else self

	# Sunken pool surface (micro-offset +0.03m to Y=-0.22 to eliminate co-planar Z-fighting with MainFloor)
	_add_box(basin_parent, "WaterFloor", Vector3(16.0, 0.5, 16.0), Vector3(0, -0.22, 0), mat_flooded)

	# Basin edge curbs
	_add_box(basin_parent, "BasinCurb_West", Vector3(0.6, 0.7, 16.0), Vector3(-8.3, 0.05, 0), mat_low_wall)
	_add_box(basin_parent, "BasinCurb_East", Vector3(0.6, 0.7, 16.0), Vector3(8.3, 0.05, 0), mat_low_wall)

	# Entry Ramps into the sunken basin (North & South)
	var ramp_s = _add_box(basin_parent, "BasinRamp_South", Vector3(5.0, 0.25, 3.5), Vector3(0, -0.15, 8.5), mat_ramp)
	ramp_s.rotation_degrees.x = -11.0
	var ramp_n = _add_box(basin_parent, "BasinRamp_North", Vector3(5.0, 0.25, 3.5), Vector3(0, -0.15, -8.5), mat_ramp)
	ramp_n.rotation_degrees.x = 11.0

	# Central fountain sculpture pedestal inside the flooded basin
	_add_cylinder(basin_parent, "FountainBase", 2.4, 0.8, Vector3(0, 0.1, 0), mat_low_wall)
	_add_cylinder(basin_parent, "FountainSpire", 1.0, 2.4, Vector3(0, 1.7, 0), mat_pillar)

	# 4. Raised Mezzanine Terrace & Skate Ramp (West Wing)
	var mezz_parent = Node3D.new()
	mezz_parent.name = "MezzanineTerrace"
	level_root.add_child(mezz_parent)
	if Engine.is_editor_hint():
		mezz_parent.owner = get_tree().edited_scene_root if get_tree() else self

	# Raised deck (+1.2m elevation)
	_add_box(mezz_parent, "DeckFloor", Vector3(10.0, 1.2, 16.0), Vector3(-18.5, 0.6, -6.0), mat_floor)

	# Wide access ramp (slope from Y=0 to Y=1.2 over 6m length)
	var mezz_ramp = _add_box(mezz_parent, "DeckRamp", Vector3(4.5, 0.25, 6.5), Vector3(-18.5, 0.6, 5.0), mat_ramp)
	mezz_ramp.rotation_degrees.x = -11.0

	# Low guard wall / railing overlooking the main plaza
	_add_box(mezz_parent, "DeckRail_East", Vector3(0.3, 0.9, 16.0), Vector3(-13.65, 1.65, -6.0), mat_low_wall)
	_add_box(mezz_parent, "DeckRail_North", Vector3(10.0, 0.9, 0.3), Vector3(-18.5, 1.65, -14.15), mat_low_wall)
	_add_box(mezz_parent, "MezzanineStripLight", Vector3(0.1, 0.1, 16.0), Vector3(-13.4, 1.15, -6.0), mat_strip)

	# 5. Grand Structural Pillars (Colonnade Slalom for 12.0 m/s Skate Traversal)
	var pillars_parent = Node3D.new()
	pillars_parent.name = "StructuralPillars"
	level_root.add_child(pillars_parent)
	if Engine.is_editor_hint():
		pillars_parent.owner = get_tree().edited_scene_root if get_tree() else self

	var z_coords = [-16.0, -7.0, 7.0, 16.0]
	var x_coords = [-11.0, 11.0]
	var p_idx = 1
	for x in x_coords:
		for z in z_coords:
			_add_cylinder(pillars_parent, "Pillar_%02d" % p_idx, pillar_radius, pillar_height, Vector3(x, pillar_height * 0.5, z), mat_pillar.duplicate())
			p_idx += 1

	# 6. Derelict Retail Kiosks & Vendor Islands (Obstacles for cornering)
	var kiosks_parent = Node3D.new()
	kiosks_parent.name = "DerelictKiosks"
	level_root.add_child(kiosks_parent)
	if Engine.is_editor_hint():
		kiosks_parent.owner = get_tree().edited_scene_root if get_tree() else self

	_add_box(kiosks_parent, "Kiosk_BeeperWorld", Vector3(4.2, 2.8, 3.2), Vector3(-5.5, 1.4, -15.0), mat_kiosk)
	_add_box(kiosks_parent, "Kiosk_NeonJulius", Vector3(4.5, 2.8, 3.4), Vector3(5.5, 1.4, -15.0), mat_kiosk)
	_add_box(kiosks_parent, "Kiosk_CassetteVault", Vector3(4.8, 2.8, 3.0), Vector3(16.5, 1.4, 5.0), mat_kiosk)
	
	var lights_parent = Node3D.new()
	lights_parent.name = "EmergencyLights"
	level_root.add_child(lights_parent)
	if Engine.is_editor_hint(): lights_parent.owner = get_tree().edited_scene_root if get_tree() else self
	
	_add_light(lights_parent, "Light_Kiosk1", Color("#ff7a1a"), 2.0, 9.0, Vector3(-5.5, 3.5, -15.0))
	_add_light(lights_parent, "Light_Kiosk2", Color("#ff7a1a"), 2.0, 9.0, Vector3(5.5, 3.5, -15.0))
	_add_light(lights_parent, "Light_Kiosk3", Color("#ff7a1a"), 2.0, 9.0, Vector3(16.5, 3.5, 5.0))
	_add_light(lights_parent, "Light_Checkpoint", Color.CYAN, 2.0, 9.0, Vector3(3.0, 3.0, 12.0))

	# 7. Hip-Height Planters & Seating Curbs (Low Walls for Camera Occlusion Tests)
	var planters_parent = Node3D.new()
	planters_parent.name = "PlantersAndCurbs"
	level_root.add_child(planters_parent)
	if Engine.is_editor_hint():
		planters_parent.owner = get_tree().edited_scene_root if get_tree() else self

	_add_box(planters_parent, "Planter_SouthWest", Vector3(6.5, low_wall_height, 2.0), Vector3(-5.5, low_wall_height * 0.5, 13.5), mat_low_wall)
	_add_box(planters_parent, "Planter_SouthEast", Vector3(6.5, low_wall_height, 2.0), Vector3(5.5, low_wall_height * 0.5, 13.5), mat_low_wall)
	_add_box(planters_parent, "Planter_EastWing", Vector3(2.0, low_wall_height, 6.5), Vector3(19.0, low_wall_height * 0.5, -6.0), mat_low_wall)
	_add_box(planters_parent, "CenterBenchDivider", Vector3(3.5, 0.55, 0.8), Vector3(0, 0.275, 14.5), mat_low_wall)

	# 8. Storefront Alcoves (High Walls to test 45° Camera Occlusion & Clipping)
	var storefronts_parent = Node3D.new()
	storefronts_parent.name = "StorefrontAlcoves"
	level_root.add_child(storefronts_parent)
	if Engine.is_editor_hint():
		storefronts_parent.owner = get_tree().edited_scene_root if get_tree() else self

	# North-East Storefront ("MegaByte Electronics")
	_add_box(storefronts_parent, "Store_NE_Back", Vector3(12.0, 4.0, 0.6), Vector3(18.0, 2.0, -22.0), mat_high_wall)
	_add_box(storefronts_parent, "Store_NE_Divider", Vector3(0.6, 4.0, 8.0), Vector3(12.0, 2.0, -18.0), mat_high_wall)
	_add_box(storefronts_parent, "Store_NE_FrontWall", Vector3(4.0, 4.0, 0.6), Vector3(16.0, 2.0, -14.0), mat_high_wall)

	# South-West Storefront ("Subway Arcade")
	_add_box(storefronts_parent, "Store_SW_Back", Vector3(10.0, 4.0, 0.6), Vector3(-19.0, 2.0, 22.0), mat_high_wall)
	_add_box(storefronts_parent, "Store_SW_Divider", Vector3(0.6, 4.0, 6.5), Vector3(-14.0, 2.0, 18.75), mat_high_wall)

	# 9. Grind Rails (Momentum Spline Traversal)
	var rails_parent = Node3D.new()
	rails_parent.name = "GrindRails"
	level_root.add_child(rails_parent)
	if Engine.is_editor_hint():
		rails_parent.owner = get_tree().edited_scene_root if get_tree() else self

	var mat_rail = _create_material(Color("#ffd23f"), 0.3, 0.0, 1.0, Color("#ffd23f"), 2.2)

	# Rail 1: Curving around the Sunken Atrium Basin
	var basin_curve_pts: Array[Vector3] = [
		Vector3(6.5, 0.75, -8.0),
		Vector3(8.8, 0.75, -4.5),
		Vector3(9.5, 0.75, 0.0),
		Vector3(8.8, 0.75, 4.5),
		Vector3(6.5, 0.75, 8.0)
	]
	_add_grind_rail(rails_parent, "Rail_SunkenAtriumCurved", basin_curve_pts, mat_rail)

	# Rail 2: Straight handrail down the Mezzanine Terrace ramp
	var mezz_ramp_pts: Array[Vector3] = [
		Vector3(-16.0, 1.95, 1.0),
		Vector3(-16.0, 1.45, 4.5),
		Vector3(-16.0, 0.75, 8.5)
	]
	_add_grind_rail(rails_parent, "Rail_MezzanineRampHandrail", mezz_ramp_pts, mat_rail)

	# 10. Spawn Enemy Prototypes
	_spawn_enemies(enemies_root)

	print("[FloodedMall] Greybox blockout successfully constructed with %d structural sections!" % level_root.get_child_count())

func _spawn_enemies(enemies_container: Node3D = null) -> void:
	var container = enemies_container if enemies_container else get_node_or_null("Enemies")
	if not container:
		return

	var scene_to_spawn = cicada_scene
	if not scene_to_spawn:
		if ResourceLoader.exists("res://scenes/neon_cicada.tscn"):
			scene_to_spawn = load("res://scenes/neon_cicada.tscn")

	if scene_to_spawn and scene_to_spawn.can_instantiate():
		var spawn_points: Array[Vector3] = [
			Vector3(-6.0, 1.0, 6.0),
			Vector3(6.0, 1.0, 6.0),
			Vector3(-17.0, 2.3, 2.0)
		]

		for i in range(spawn_points.size()):
			var enemy = scene_to_spawn.instantiate()
			if not enemy:
				continue
			enemy.name = "NeonDialUpCicada_%02d" % (i + 1)
			if enemy is Node3D:
				enemy.position = spawn_points[i]
			elif enemy is Node2D:
				enemy.position = Vector2(spawn_points[i].x, spawn_points[i].z)
			container.add_child(enemy)
			if Engine.is_editor_hint():
				enemy.owner = get_tree().edited_scene_root if get_tree() else self

	# 2. Spawn Corrupted Kiosk Turrets near derelict kiosks
	var turret_script_res = load("res://scripts/corrupted_kiosk_turret.gd") if ResourceLoader.exists("res://scripts/corrupted_kiosk_turret.gd") else null
	if turret_script_res:
		var turret_positions: Array[Vector3] = [
			Vector3(-6.0, 1.0, -13.5),
			Vector3(8.0, 1.0, -13.5)
		]
		for j in range(turret_positions.size()):
			var turret = turret_script_res.new()
			turret.name = "CorruptedKioskTurret_%02d" % (j + 1)
			turret.position = turret_positions[j]
			container.add_child(turret)
			if Engine.is_editor_hint():
				turret.owner = get_tree().edited_scene_root if get_tree() else self

	# 3. Spawn Sludge Roaches swarming near the Sunken Atrium Basin
	var roach_script_res = load("res://scripts/sludge_roach.gd") if ResourceLoader.exists("res://scripts/sludge_roach.gd") else null
	if roach_script_res:
		var roach_positions: Array[Vector3] = [
			Vector3(1.0, 0.5, -8.0),
			Vector3(-2.0, 0.5, -9.0),
			Vector3(3.5, 0.5, -7.0),
			Vector3(-18.0, 1.3, 1.0)
		]
		for k in range(roach_positions.size()):
			var roach = roach_script_res.new()
			roach.name = "SludgeRoach_%02d" % (k + 1)
			roach.position = roach_positions[k]
			container.add_child(roach)
			if Engine.is_editor_hint():
				roach.owner = get_tree().edited_scene_root if get_tree() else self

func _create_material(albedo: Color, roughness: float = 0.8, metallic: float = 0.0, alpha: float = 1.0, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = roughness
	mat.metallic = metallic
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = alpha
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat

func _add_light(parent: Node, node_name: String, color: Color, energy: float, range_val: float, pos: Vector3) -> OmniLight3D:
	var light = OmniLight3D.new()
	light.name = node_name
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_val
	light.position = pos
	light.shadow_enabled = true
	parent.add_child(light)
	if Engine.is_editor_hint():
		light.owner = get_tree().edited_scene_root if get_tree() else self
	return light

func _add_box(parent: Node, node_name: String, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> CSGBox3D:
	var box = CSGBox3D.new()
	box.name = node_name
	box.size = size
	box.position = pos
	box.use_collision = true
	box.material = mat
	parent.add_child(box)
	if Engine.is_editor_hint():
		box.owner = get_tree().edited_scene_root if get_tree() else self
	return box

func _add_cylinder(parent: Node, node_name: String, radius: float, height: float, pos: Vector3, mat: StandardMaterial3D) -> CSGCylinder3D:
	var cyl = CSGCylinder3D.new()
	cyl.name = node_name
	cyl.radius = radius
	cyl.height = height
	cyl.sides = 16
	cyl.position = pos
	cyl.use_collision = true
	cyl.material = mat
	parent.add_child(cyl)
	if Engine.is_editor_hint():
		cyl.owner = get_tree().edited_scene_root if get_tree() else self
	return cyl

func _add_grind_rail(parent: Node, rail_name: String, points: Array[Vector3], mat: StandardMaterial3D) -> Path3D:
	var path_node = Path3D.new()
	path_node.name = rail_name
	var curve = Curve3D.new()
	for pt in points:
		curve.add_point(pt)
	path_node.curve = curve
	parent.add_child(path_node)
	if Engine.is_editor_hint():
		path_node.owner = get_tree().edited_scene_root if get_tree() else self

	# 1. Visual CSGPolygon3D mapped along the Path3D curve
	var poly = CSGPolygon3D.new()
	poly.name = "RailMesh"
	poly.mode = CSGPolygon3D.MODE_PATH
	poly.path_node = NodePath("..")
	poly.path_interval_type = CSGPolygon3D.PATH_INTERVAL_DISTANCE
	poly.path_interval = 0.25
	poly.path_rotation = CSGPolygon3D.PATH_ROTATION_PATH
	poly.path_local = true
	poly.material = mat
	# Octagonal tubular cross section (radius 0.08m)
	var radius = 0.08
	var poly_pts: PackedVector2Array = []
	for i in range(8):
		var angle = i * (PI * 2.0 / 8.0)
		poly_pts.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	poly.polygon = poly_pts
	path_node.add_child(poly)
	if Engine.is_editor_hint():
		poly.owner = get_tree().edited_scene_root if get_tree() else self

	# 2. PathFollow3D node for tracking progression along the spline
	var follower = PathFollow3D.new()
	follower.name = "PathFollow3D"
	follower.loop = false
	path_node.add_child(follower)
	if Engine.is_editor_hint():
		follower.owner = get_tree().edited_scene_root if get_tree() else self

	# 3. Area3D collision volume along the path assigned to Grindable layer
	var area = Area3D.new()
	area.name = "GrindArea"
	# Layer 3 = bit 2 (value 4), Layer 4 = bit 3 (value 8)
	area.collision_layer = 4 # Layer 3: Grindable
	area.collision_mask = 1 | 2 # Detects World/Player
	area.add_to_group("grindable")
	path_node.add_child(area)
	if Engine.is_editor_hint():
		area.owner = get_tree().edited_scene_root if get_tree() else self

	# Connect body_entered to trigger grind on any visiting PlayerController
	area.body_entered.connect(_on_rail_body_entered.bind(path_node))

	# Segmented BoxShape3D volumes along the curve length
	var baked_len = curve.get_baked_length()
	var step_size = 2.0
	var num_segments = max(1, int(ceil(baked_len / step_size)))
	for i in range(num_segments):
		var t0 = (float(i) / num_segments) * baked_len
		var t1 = (float(i + 1) / num_segments) * baked_len
		var p0 = curve.sample_baked(t0)
		var p1 = curve.sample_baked(t1)
		var mid = (p0 + p1) * 0.5
		var seg_len = p0.distance_to(p1)

		var col = CollisionShape3D.new()
		col.name = "Col_%02d" % i
		var box = BoxShape3D.new()
		box.size = Vector3(0.9, 1.2, max(0.5, seg_len + 0.3))
		col.shape = box
		col.position = mid
		var seg_dir = (p1 - mid).normalized()
		if p0.distance_to(p1) > 0.01 and abs(seg_dir.dot(Vector3.UP)) < 0.99:
			col.look_at_from_position(mid, p1, Vector3.UP)
		area.add_child(col)
		if Engine.is_editor_hint():
			col.owner = get_tree().edited_scene_root if get_tree() else self

	# 4. Support vertical posts down to ground
	for i in range(points.size()):
		var pt = points[i]
		var post = CSGCylinder3D.new()
		post.name = "SupportPost_%02d" % i
		post.radius = 0.05
		post.height = pt.y
		post.position = Vector3(pt.x, pt.y * 0.5, pt.z)
		post.material = mat
		path_node.add_child(post)
		if Engine.is_editor_hint():
			post.owner = get_tree().edited_scene_root if get_tree() else self

	return path_node

func _connect_runtime_rails() -> void:
	var rails_parent = get_node_or_null("LevelGeometry/GrindRails")
	if not rails_parent:
		return
	for path_node in rails_parent.get_children():
		if path_node is Path3D:
			var area = path_node.get_node_or_null("GrindArea")
			if area and area is Area3D:
				var cb = _on_rail_body_entered.bind(path_node)
				if not area.body_entered.is_connected(cb):
					area.body_entered.connect(cb)

func _on_rail_body_entered(body: Node, path_node: Path3D) -> void:
	if is_instance_valid(body) and body.has_method("try_start_grind"):
		body.call("try_start_grind", path_node)
