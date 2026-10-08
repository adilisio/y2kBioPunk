@tool
extends Node3D

## MallGreyboxBuilder
## Procedural greybox generator for the "Flooded Mall Plaza" blockout in Godot 4.3.
## Can be triggered from the Godot Editor Inspector via the 'rebuild_level' button,
## or executed at runtime when the scene loads.

const OcclusionFader = preload("res://scripts/occlusion_fader.gd")
var occlusion_fader: Node

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
		var p = get_node_or_null("Player")
		if not p:
			p = get_node_or_null("../Player")
		if not p:
			p = get_tree().current_scene.find_child("Player", true, false) if get_tree() and get_tree().current_scene else null
		if p:
			p.add_to_group("player")
			
		var tut = get_node_or_null("../TutorialDirector")
		if not tut:
			tut = get_tree().current_scene.find_child("TutorialDirector", true, false) if get_tree() and get_tree().current_scene else null
		if not tut:
			var tut_script = load("res://scripts/tutorial_director.gd")
			if tut_script:
				tut = Node.new()
				tut.name = "TutorialDirector"
				tut.set_script(tut_script)
				add_child(tut)

func _clear_existing_geometry() -> void:
	if is_instance_valid(occlusion_fader):
		occlusion_fader.restore_all()
		if occlusion_fader.get_parent() == self:
			remove_child(occlusion_fader)
		occlusion_fader.queue_free()
	occlusion_fader = null

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
	# Offline tooling builds geometry only; _ready rebuilds with runtime systems.
	if not Engine.is_editor_hint() and is_inside_tree():
		occlusion_fader = OcclusionFader.new()
		occlusion_fader.name = "OcclusionFader"
		add_child(occlusion_fader)

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
	_generate_tile_texture()
	_generate_water_texture()
	var mat_floor = _create_material(Color(0.24, 0.26, 0.28), 0.9)
	mat_floor.albedo_texture = tile_tex
	mat_floor.uv1_triplanar = true
	mat_floor.uv1_scale = Vector3(0.5, 0.5, 0.5)
	
	var mat_flooded = _create_material(Color("#0a3a3a"), 0.15, 0.6, 0.85)
	mat_flooded.normal_enabled = true
	mat_flooded.normal_texture = water_tex
	if not Engine.is_editor_hint():
		var tween = create_tween().set_loops()
		tween.tween_property(mat_flooded, "uv1_offset", Vector3(1, 1, 0), 20.0).as_relative()
		
	var mat_high_wall = _create_material(Color(0.12, 0.14, 0.17), 0.75)
	var mat_high_wall_upper = _create_material(Color(0.10, 0.12, 0.14), 0.75)
	var mat_trim = _create_material(Color(0.0, 0.4, 0.4), 0.5, 0.0, 1.0, Color(0.0, 0.4, 0.4), 1.0)
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
	_add_box(level_root, "Wall_North", Vector3(plaza_size.x, 2.6, 1.0), Vector3(0, 1.3, -half_z), mat_high_wall)
	_add_box(level_root, "Wall_North_Upper", Vector3(plaza_size.x, high_wall_height - 2.6, 1.0), Vector3(0, 2.6 + (high_wall_height - 2.6)*0.5, -half_z), mat_high_wall_upper)
	_add_box(level_root, "Wall_North_Trim", Vector3(plaza_size.x, 0.05, 1.1), Vector3(0, 2.6, -half_z), mat_trim)
	
	_add_box(level_root, "Wall_South", Vector3(plaza_size.x, 1.0, 1.0), Vector3(0, 0.5, half_z), mat_high_wall)
	
	_add_box(level_root, "Wall_West", Vector3(1.0, 2.6, plaza_size.y), Vector3(-half_x, 1.3, 0), mat_high_wall)
	_add_box(level_root, "Wall_West_Upper", Vector3(1.0, high_wall_height - 2.6, plaza_size.y), Vector3(-half_x, 2.6 + (high_wall_height - 2.6)*0.5, 0), mat_high_wall_upper)
	_add_box(level_root, "Wall_West_Trim", Vector3(1.1, 0.05, plaza_size.y), Vector3(-half_x, 2.6, 0), mat_trim)
	
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
	if _add_prop(basin_parent, "FountainSpire", "res://assets/models/fountain_sculpture.glb", Vector3(2.0, 2.6, 2.0), Vector3(0, 1.8, 0)) == null:
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

	# Mezzanine prop & sign
	_add_prop_or_box(mezz_parent, "Planter_Mezzanine", "res://assets/models/mall_planter.glb", Vector3(4.0, low_wall_height, 2.0), Vector3(-17.0, 1.2 + low_wall_height * 0.5, -6.0), mat_low_wall, true, 0.0)
	var lbl_food = _add_label3d(mezz_parent, "Sign_FoodCourt", "FOOD COURT ->", Vector3(-18.4, 3.5, -6.0), Color("#ffaa33"), 1.2)
	lbl_food.rotation_degrees.y = 90
	
	# Low guard wall / railing overlooking the main plaza
	_add_box(mezz_parent, "DeckRail_East", Vector3(0.3, 0.9, 16.0), Vector3(-13.65, 1.65, -6.0), mat_low_wall)
	_add_box(mezz_parent, "DeckRail_North", Vector3(10.0, 0.9, 0.3), Vector3(-18.5, 1.65, -14.15), mat_low_wall)
	_add_box(mezz_parent, "MezzanineStripLight", Vector3(0.1, 0.1, 16.0), Vector3(-13.4, 1.15, -6.0), mat_strip)

	# 5. Grand Structural Pillars (Colonnade Slalom for 12.0 m/s Skate Traversal)
	var pillars_parent = CSGCombiner3D.new()
	pillars_parent.name = "StructuralPillars"
	level_root.add_child(pillars_parent)
	if Engine.is_editor_hint():
		pillars_parent.owner = get_tree().edited_scene_root if get_tree() else self

	var z_coords = [-16.0, -7.0, 7.0, 16.0]
	var x_coords = [-11.0, 11.0]
	var p_idx = 1
	for x in x_coords:
		for z in z_coords:
			var cyl = _add_cylinder(pillars_parent, "Pillar_%02d" % p_idx, pillar_radius, pillar_height, Vector3(x, pillar_height * 0.5, z), mat_pillar)
			var plinth = CSGCylinder3D.new()
			plinth.radius = pillar_radius + 0.15
			plinth.height = 0.4
			plinth.position = Vector3(0, -pillar_height*0.5 + 0.2, 0)
			plinth.material = mat_pillar
			cyl.add_child(plinth)
			var cap = CSGCylinder3D.new()
			cap.radius = pillar_radius + 0.1
			cap.height = 0.2
			cap.position = Vector3(0, pillar_height*0.5 - 0.1, 0)
			cap.material = mat_pillar
			cyl.add_child(cap)
			p_idx += 1

	# 6. Derelict Retail Kiosks & Vendor Islands (Obstacles for cornering)
	var kiosks_parent = Node3D.new()
	kiosks_parent.name = "DerelictKiosks"
	level_root.add_child(kiosks_parent)
	if Engine.is_editor_hint():
		kiosks_parent.owner = get_tree().edited_scene_root if get_tree() else self

	_add_prop_or_box(kiosks_parent, "Kiosk_BeeperWorld", "res://assets/models/mall_kiosk.glb", Vector3(4.2, 2.8, 3.2), Vector3(-5.5, 1.4, -15.0), mat_kiosk, false, 0.0)
	_add_label3d(level_root, "Sign_BeeperWorld", "BEEPER WORLD", Vector3(-5.5, 3.8, -15.0), Color("#ffaa33"), 1.2)
	
	_add_prop_or_box(kiosks_parent, "Kiosk_NeonJulius", "res://assets/models/mall_kiosk.glb", Vector3(4.5, 2.8, 3.4), Vector3(5.5, 1.4, -15.0), mat_kiosk, false, 180.0)
	_add_label3d(level_root, "Sign_NeonJulius", "NEON JULIUS", Vector3(5.5, 3.8, -15.0), Color("#ffaa33"), 1.2)
	
	_add_prop_or_box(kiosks_parent, "Kiosk_CassetteVault", "res://assets/models/mall_kiosk.glb", Vector3(4.8, 2.8, 3.0), Vector3(16.5, 1.4, 5.0), mat_kiosk, false, 90.0)
	var lbl_cass = _add_label3d(level_root, "Sign_CassetteVault", "CASSETTE VAULT", Vector3(16.5, 3.8, 5.0), Color("#ffaa33"), 1.2)
	lbl_cass.rotation_degrees.y = -90
	
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

	_add_prop_or_box(planters_parent, "Planter_SouthWest", "res://assets/models/mall_planter.glb", Vector3(6.5, low_wall_height, 2.0), Vector3(-5.5, low_wall_height * 0.5, 13.5), mat_low_wall, true, 0.0)
	_add_prop_or_box(planters_parent, "Planter_SouthEast", "res://assets/models/mall_planter.glb", Vector3(6.5, low_wall_height, 2.0), Vector3(5.5, low_wall_height * 0.5, 13.5), mat_low_wall, true, 0.0)
	_add_prop_or_box(planters_parent, "Planter_EastWing", "res://assets/models/mall_planter.glb", Vector3(2.0, low_wall_height, 6.5), Vector3(19.0, low_wall_height * 0.5, -6.0), mat_low_wall, true, 90.0)
	_add_box(planters_parent, "CenterBenchDivider", Vector3(3.5, 0.55, 0.8), Vector3(0, 0.275, 14.5), mat_low_wall)

	# 8. Storefront Alcoves (High Walls to test 45° Camera Occlusion & Clipping)
	var storefronts_parent = Node3D.new()
	storefronts_parent.name = "StorefrontAlcoves"
	level_root.add_child(storefronts_parent)
	if Engine.is_editor_hint():
		storefronts_parent.owner = get_tree().edited_scene_root if get_tree() else self

	# North-East Storefront ("MegaByte Electronics")
	_add_box(storefronts_parent, "Store_NE_Back", Vector3(12.0, 2.6, 0.6), Vector3(18.0, 1.3, -22.0), mat_high_wall)
	_add_box(storefronts_parent, "Store_NE_Back_Upper", Vector3(12.0, 1.4, 0.6), Vector3(18.0, 3.3, -22.0), mat_high_wall_upper)
	_add_box(level_root, "Store_NE_Back_Trim", Vector3(12.0, 0.05, 0.7), Vector3(18.0, 2.6, -22.0), mat_trim)
	
	_add_box(storefronts_parent, "Store_NE_Divider", Vector3(0.6, 4.0, 8.0), Vector3(12.0, 2.0, -18.0), mat_high_wall)
	_add_box(storefronts_parent, "Store_NE_FrontWall", Vector3(4.0, 4.0, 0.6), Vector3(16.0, 2.0, -14.0), mat_high_wall)

	# South-West Storefront ("Subway Arcade")
	_add_box(storefronts_parent, "Store_SW_Back", Vector3(10.0, 2.6, 0.6), Vector3(-19.0, 1.3, 22.0), mat_high_wall)
	_add_box(storefronts_parent, "Store_SW_Back_Upper", Vector3(10.0, 1.4, 0.6), Vector3(-19.0, 3.3, 22.0), mat_high_wall_upper)
	_add_box(level_root, "Store_SW_Back_Trim", Vector3(10.0, 0.05, 0.7), Vector3(-19.0, 2.6, 22.0), mat_trim)
	
	var lbl_subway = _add_label3d(level_root, "Sign_SubwayArcade", "SUBWAY ARCADE", Vector3(-19.0, 3.2, 21.6), Color("#ff7a1a"), 1.5)
	lbl_subway.rotation_degrees.y = 180
	_add_box(storefronts_parent, "Store_SW_Divider", Vector3(0.6, 4.0, 6.5), Vector3(-14.0, 2.0, 18.75), mat_high_wall)

	# Queen Arena Dressing
	var arena_parent = Node3D.new()
	arena_parent.name = "QueenArena"
	level_root.add_child(arena_parent)
	if Engine.is_editor_hint():
		arena_parent.owner = get_tree().edited_scene_root if get_tree() else self

	var mat_arena_ring = _create_material(Color(0.2, 0.0, 0.2), 0.8, 0.0, 1.0, Color(0.4, 0.0, 0.4), 1.0)
	var arena_ring = CSGCylinder3D.new()
	arena_ring.name = "ArenaRing"
	arena_ring.radius = 7.0
	arena_ring.height = 0.04
	arena_ring.position = Vector3(0, 0.02, -21.5)
	arena_ring.material = mat_arena_ring
	arena_ring.use_collision = false
	arena_parent.add_child(arena_ring)
	
	var mat_magenta_strip = _create_material(Color.MAGENTA, 0.5, 0.0, 1.0, Color.MAGENTA, 2.0)
	_add_box(arena_parent, "ArenaBaseStrip", Vector3(14.0, 0.1, 0.2), Vector3(0, 0.05, -24.4), mat_magenta_strip)
	_add_light(arena_parent, "Light_Modem1", Color.MAGENTA, 1.5, 10.0, Vector3(-5.0, 2.0, -23.0))
	_add_light(arena_parent, "Light_Modem2", Color.MAGENTA, 1.5, 10.0, Vector3(5.0, 2.0, -23.0))
	_add_light(arena_parent, "Light_Modem3", Color.MAGENTA, 1.5, 10.0, Vector3(0.0, 2.0, -20.0))
	
	var lbl1 = _add_label3d(arena_parent, "ArenaSign_Title", "MEGABYTE ELECTRONICS", Vector3(0, 3.8, -24.4), Color.CYAN, 1.5)
	var lbl2 = _add_label3d(arena_parent, "ArenaSign_Sub", "56K // NO CARRIER", Vector3(0, 3.1, -24.4), Color.MAGENTA, 1.0)
	
	if not Engine.is_editor_hint():
		var tween = create_tween().set_loops()
		tween.tween_property(lbl2, "modulate:a", 0.2, 0.1)
		tween.tween_property(lbl2, "modulate:a", 1.0, 0.2)
		tween.tween_interval(1.5)
		tween.tween_property(lbl2, "modulate:a", 0.5, 0.05)
		tween.tween_property(lbl2, "modulate:a", 1.0, 0.05)
		tween.tween_interval(0.8)
		
	var mat_server_rack = _create_material(Color(0.1, 0.1, 0.1), 0.5)
	var mat_server_lights = _create_material(Color(0.0, 0.8, 0.0), 0.5, 0.0, 1.0, Color(0.0, 1.0, 0.0), 1.5)
	var sr1 = _add_box(arena_parent, "ServerRack1", Vector3(0.8, 2.2, 0.6), Vector3(-7.5, 1.1, -24.0), mat_server_rack)
	var slit1 = CSGBox3D.new()
	slit1.size = Vector3(0.6, 2.0, 0.05)
	slit1.position = Vector3(0, 0, 0.3)
	slit1.material = mat_server_lights
	sr1.add_child(slit1)
	
	var sr2 = _add_box(arena_parent, "ServerRack2", Vector3(0.8, 2.2, 0.6), Vector3(7.5, 1.1, -24.0), mat_server_rack)
	var slit2 = CSGBox3D.new()
	slit2.size = Vector3(0.6, 2.0, 0.05)
	slit2.position = Vector3(0, 0, 0.3)
	slit2.material = mat_server_lights
	sr2.add_child(slit2)

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

	if is_instance_valid(occlusion_fader):
		occlusion_fader.finish_build()

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
			Vector3(-6.5, 1.0, 2.5),
			Vector3(6.5, 1.0, 2.5),
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

var tile_tex: ImageTexture
var water_tex: NoiseTexture2D

func _generate_tile_texture() -> void:
	if tile_tex: return
	var img = Image.create(256, 256, false, Image.FORMAT_L8)
	var noise = FastNoiseLite.new()
	noise.seed = 1234
	noise.frequency = 0.05
	for y in range(256):
		for x in range(256):
			var val = 0.90 + (noise.get_noise_2d(x, y) * 0.03)
			if x % 64 < 2 or y % 64 < 2:
				val += 0.10
			img.set_pixel(x, y, Color(val, val, val, 1.0))
	tile_tex = ImageTexture.create_from_image(img)

func _generate_water_texture() -> void:
	if water_tex: return
	water_tex = NoiseTexture2D.new()
	water_tex.width = 256
	water_tex.height = 256
	water_tex.as_normal_map = true
	water_tex.bump_strength = 2.0
	var noise = FastNoiseLite.new()
	noise.seed = 4321
	noise.frequency = 0.02
	water_tex.noise = noise

func _add_label3d(parent: Node, node_name: String, text_str: String, pos: Vector3, color: Color, size: float = 1.0) -> Label3D:
	var lbl = Label3D.new()
	lbl.name = node_name
	lbl.text = text_str
	lbl.position = pos
	lbl.pixel_size = size * 0.01
	lbl.modulate = color
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 4
	lbl.double_sided = false
	lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lbl.shaded = false
	lbl.no_depth_test = false
	parent.add_child(lbl)
	return lbl

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
	light.shadow_enabled = false # mood lights; omni shadow cubemaps re-render the scene six times each
	parent.add_child(light)
	if Engine.is_editor_hint():
		light.owner = get_tree().edited_scene_root if get_tree() else self
	return light

## Places a Meshy prop fitted to the greybox volume `size` at `pos` (box centre, like `_add_box`), with an
## invisible StaticBody3D box collider matching that volume so traversal is unchanged. `stretch_footprint`
## scales x/z to fill the box (long planters); `yaw_degrees` turns the model. Returns null when the GLB is
## missing so the caller can keep the CSG box.
func _add_prop(parent: Node, node_name: String, model_path: String, size: Vector3, pos: Vector3, stretch_footprint: bool = false, yaw_degrees: float = 0.0) -> Node3D:
	var root := EnemyModel.attach(parent, model_path, size.y, 0.0, yaw_degrees, 0.0, node_name)
	if root == null:
		return null
	root.position = Vector3(pos.x, pos.y - size.y * 0.5, pos.z)
	if stretch_footprint:
		var box := EnemyModel.bounds(root)
		if box.size.x > 0.01 and box.size.z > 0.01:
			root.scale = Vector3(size.x / box.size.x, 1.0, size.z / box.size.z)

	var body := StaticBody3D.new()
	body.name = node_name + "_Collision"
	body.position = pos
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	parent.add_child(body)
	if Engine.is_editor_hint():
		var scene_owner = get_tree().edited_scene_root if get_tree() else self
		root.owner = scene_owner
		body.owner = scene_owner
		shape.owner = scene_owner
	if size.y > 1.2 and is_instance_valid(occlusion_fader):
		# EnemyModel.bounds(root) includes root placement/scale in its parent space.
		var prop_bounds := EnemyModel.bounds(root)
		for mesh in EnemyModel.mesh_instances(root):
			occlusion_fader.register_occluder(mesh, parent, prop_bounds)
	return root

func _add_prop_or_box(parent: Node, node_name: String, model_path: String, size: Vector3, pos: Vector3, mat: StandardMaterial3D, stretch_footprint: bool = false, yaw_degrees: float = 0.0) -> Node3D:
	var prop := _add_prop(parent, node_name, model_path, size, pos, stretch_footprint, yaw_degrees)
	if prop:
		return prop
	return _add_box(parent, node_name, size, pos, mat)

func _add_box(parent: Node, node_name: String, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> CSGBox3D:
	var box = CSGBox3D.new()
	box.name = node_name
	box.size = size
	box.position = pos
	box.use_collision = false # CSG collision is a trimesh; a BoxShape3D is ~10x cheaper for the enemy CharacterBodies
	box.material = mat
	parent.add_child(box)
	var shape := BoxShape3D.new()
	shape.size = size
	_add_static_body(box, shape)
	if Engine.is_editor_hint():
		box.owner = get_tree().edited_scene_root if get_tree() else self
	# Elevated deck/guards can occlude despite their individual height being <= 1.2 m.
	if (size.y > 1.2 or node_name == "DeckFloor" or node_name.begins_with("DeckRail_")) and is_instance_valid(occlusion_fader):
		occlusion_fader.register_occluder(box, box, AABB(-size * 0.5, size))
	return box

func _add_cylinder(parent: Node, node_name: String, radius: float, height: float, pos: Vector3, mat: StandardMaterial3D) -> CSGCylinder3D:
	var cyl = CSGCylinder3D.new()
	cyl.name = node_name
	cyl.radius = radius
	cyl.height = height
	cyl.sides = 16
	cyl.position = pos
	cyl.use_collision = false
	cyl.material = mat
	parent.add_child(cyl)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	_add_static_body(cyl, shape)
	if Engine.is_editor_hint():
		cyl.owner = get_tree().edited_scene_root if get_tree() else self
	if height > 1.2 and is_instance_valid(occlusion_fader):
		var bounds_size := Vector3(radius * 2.0, height, radius * 2.0)
		occlusion_fader.register_occluder(cyl, cyl, AABB(-bounds_size * 0.5, bounds_size))
	return cyl

## Primitive-shape StaticBody3D parented to a CSG visual so it follows the visual's transform (ramps rotate after creation).
func _add_static_body(visual: Node3D, shape: Shape3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Body"
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	visual.add_child(body)
	if Engine.is_editor_hint():
		var scene_owner = get_tree().edited_scene_root if get_tree() else self
		body.owner = scene_owner
		col.owner = scene_owner
	return body

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
