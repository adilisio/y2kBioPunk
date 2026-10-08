import re

with open('scripts/mall_greybox_builder.gd', 'r') as f:
    text = f.read()

# Add _generate_tile_texture and _generate_water_texture
texture_funcs = '''var tile_tex: ImageTexture
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

func _create_material'''

text = text.replace('func _create_material', texture_funcs)

# Update materials
mat_replacements = '''	_generate_tile_texture()
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
	var mat_trim = _create_material(Color(0.0, 0.4, 0.4), 0.5, 0.0, 1.0, Color(0.0, 0.4, 0.4), 1.0)'''

text = re.sub(r'	var mat_floor = _create_material\(Color\("#3b454d"\), 0\.9\).*?var mat_high_wall = _create_material\(Color\(0\.14, 0\.16, 0\.19\), 0\.75\)', mat_replacements, text, flags=re.DOTALL)

# Replace walls
wall_original = '''	# 2. Outer Perimeter Enclosure Walls (4.5m high)
	var half_x = plaza_size.x * 0.5
	var half_z = plaza_size.y * 0.5
	_add_box(level_root, "Wall_North", Vector3(plaza_size.x, high_wall_height, 1.0), Vector3(0, high_wall_height * 0.5, -half_z), mat_high_wall)
	_add_box(level_root, "Wall_South", Vector3(plaza_size.x, 1.0, 1.0), Vector3(0, 0.5, half_z), mat_high_wall)
	_add_box(level_root, "Wall_West", Vector3(1.0, high_wall_height, plaza_size.y), Vector3(-half_x, high_wall_height * 0.5, 0), mat_high_wall)
	_add_box(level_root, "Wall_East", Vector3(1.0, 1.0, plaza_size.y), Vector3(half_x, 0.5, 0), mat_high_wall)'''

wall_new = '''	# 2. Outer Perimeter Enclosure Walls (4.5m high)
	var half_x = plaza_size.x * 0.5
	var half_z = plaza_size.y * 0.5
	_add_box(level_root, "Wall_North", Vector3(plaza_size.x, 2.6, 1.0), Vector3(0, 1.3, -half_z), mat_high_wall)
	_add_box(level_root, "Wall_North_Upper", Vector3(plaza_size.x, high_wall_height - 2.6, 1.0), Vector3(0, 2.6 + (high_wall_height - 2.6)*0.5, -half_z), mat_high_wall_upper)
	_add_box(level_root, "Wall_North_Trim", Vector3(plaza_size.x, 0.05, 1.1), Vector3(0, 2.6, -half_z), mat_trim)
	
	_add_box(level_root, "Wall_South", Vector3(plaza_size.x, 1.0, 1.0), Vector3(0, 0.5, half_z), mat_high_wall)
	
	_add_box(level_root, "Wall_West", Vector3(1.0, 2.6, plaza_size.y), Vector3(-half_x, 1.3, 0), mat_high_wall)
	_add_box(level_root, "Wall_West_Upper", Vector3(1.0, high_wall_height - 2.6, plaza_size.y), Vector3(-half_x, 2.6 + (high_wall_height - 2.6)*0.5, 0), mat_high_wall_upper)
	_add_box(level_root, "Wall_West_Trim", Vector3(1.1, 0.05, plaza_size.y), Vector3(-half_x, 2.6, 0), mat_trim)
	
	_add_box(level_root, "Wall_East", Vector3(1.0, 1.0, plaza_size.y), Vector3(half_x, 0.5, 0), mat_high_wall)'''
text = text.replace(wall_original, wall_new)

# Pillars
pillar_original = '''		for z in z_coords:
			_add_cylinder(pillars_parent, "Pillar_%02d" % p_idx, pillar_radius, pillar_height, Vector3(x, pillar_height * 0.5, z), mat_pillar.duplicate())
			p_idx += 1'''
pillar_new = '''		for z in z_coords:
			var cyl = _add_cylinder(pillars_parent, "Pillar_%02d" % p_idx, pillar_radius, pillar_height, Vector3(x, pillar_height * 0.5, z), mat_pillar.duplicate())
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
			p_idx += 1'''
text = text.replace(pillar_original, pillar_new)

# Mezzanine Planter & Food Court Sign
mezz_original = '''	# Low guard wall / railing overlooking the main plaza
	_add_box(mezz_parent, "DeckRail_East", Vector3(0.3, 0.9, 16.0), Vector3(-13.65, 1.65, -6.0), mat_low_wall)'''
mezz_new = '''	# Mezzanine prop & sign
	_add_prop_or_box(mezz_parent, "Planter_Mezzanine", "res://assets/models/mall_planter.glb", Vector3(4.0, low_wall_height, 2.0), Vector3(-17.0, 1.2 + low_wall_height * 0.5, -6.0), mat_low_wall, true, 0.0)
	var lbl_food = _add_label3d(mezz_parent, "Sign_FoodCourt", "FOOD COURT ->", Vector3(-18.4, 3.5, -6.0), Color("#ffaa33"), 1.2)
	lbl_food.rotation_degrees.y = 90
	
	# Low guard wall / railing overlooking the main plaza
	_add_box(mezz_parent, "DeckRail_East", Vector3(0.3, 0.9, 16.0), Vector3(-13.65, 1.65, -6.0), mat_low_wall)'''
text = text.replace(mezz_original, mezz_new)

# Kiosk signage
kiosk_original = '''	_add_prop_or_box(kiosks_parent, "Kiosk_BeeperWorld", "res://assets/models/mall_kiosk.glb", Vector3(4.2, 2.8, 3.2), Vector3(-5.5, 1.4, -15.0), mat_kiosk, false, 0.0)
	_add_prop_or_box(kiosks_parent, "Kiosk_NeonJulius", "res://assets/models/mall_kiosk.glb", Vector3(4.5, 2.8, 3.4), Vector3(5.5, 1.4, -15.0), mat_kiosk, false, 180.0)
	_add_prop_or_box(kiosks_parent, "Kiosk_CassetteVault", "res://assets/models/mall_kiosk.glb", Vector3(4.8, 2.8, 3.0), Vector3(16.5, 1.4, 5.0), mat_kiosk, false, 90.0)'''

kiosk_new = '''	_add_prop_or_box(kiosks_parent, "Kiosk_BeeperWorld", "res://assets/models/mall_kiosk.glb", Vector3(4.2, 2.8, 3.2), Vector3(-5.5, 1.4, -15.0), mat_kiosk, false, 0.0)
	_add_label3d(kiosks_parent, "Sign_BeeperWorld", "BEEPER WORLD", Vector3(-5.5, 3.8, -15.0), Color("#ffaa33"), 1.2)
	
	_add_prop_or_box(kiosks_parent, "Kiosk_NeonJulius", "res://assets/models/mall_kiosk.glb", Vector3(4.5, 2.8, 3.4), Vector3(5.5, 1.4, -15.0), mat_kiosk, false, 180.0)
	_add_label3d(kiosks_parent, "Sign_NeonJulius", "NEON JULIUS", Vector3(5.5, 3.8, -15.0), Color("#ffaa33"), 1.2)
	
	_add_prop_or_box(kiosks_parent, "Kiosk_CassetteVault", "res://assets/models/mall_kiosk.glb", Vector3(4.8, 2.8, 3.0), Vector3(16.5, 1.4, 5.0), mat_kiosk, false, 90.0)
	var lbl_cass = _add_label3d(kiosks_parent, "Sign_CassetteVault", "CASSETTE VAULT", Vector3(16.5, 3.8, 5.0), Color("#ffaa33"), 1.2)
	lbl_cass.rotation_degrees.y = -90'''
text = text.replace(kiosk_original, kiosk_new)

# Storefront walls and signage
storefront_original = '''	# North-East Storefront ("MegaByte Electronics")
	_add_box(storefronts_parent, "Store_NE_Back", Vector3(12.0, 4.0, 0.6), Vector3(18.0, 2.0, -22.0), mat_high_wall)
	_add_box(storefronts_parent, "Store_NE_Divider", Vector3(0.6, 4.0, 8.0), Vector3(12.0, 2.0, -18.0), mat_high_wall)
	_add_box(storefronts_parent, "Store_NE_FrontWall", Vector3(4.0, 4.0, 0.6), Vector3(16.0, 2.0, -14.0), mat_high_wall)

	# South-West Storefront ("Subway Arcade")
	_add_box(storefronts_parent, "Store_SW_Back", Vector3(10.0, 4.0, 0.6), Vector3(-19.0, 2.0, 22.0), mat_high_wall)
	_add_box(storefronts_parent, "Store_SW_Divider", Vector3(0.6, 4.0, 6.5), Vector3(-14.0, 2.0, 18.75), mat_high_wall)'''

storefront_new = '''	# North-East Storefront ("MegaByte Electronics")
	_add_box(storefronts_parent, "Store_NE_Back", Vector3(12.0, 2.6, 0.6), Vector3(18.0, 1.3, -22.0), mat_high_wall)
	_add_box(storefronts_parent, "Store_NE_Back_Upper", Vector3(12.0, 1.4, 0.6), Vector3(18.0, 3.3, -22.0), mat_high_wall_upper)
	_add_box(storefronts_parent, "Store_NE_Back_Trim", Vector3(12.0, 0.05, 0.7), Vector3(18.0, 2.6, -22.0), mat_trim)
	
	_add_box(storefronts_parent, "Store_NE_Divider", Vector3(0.6, 4.0, 8.0), Vector3(12.0, 2.0, -18.0), mat_high_wall)
	_add_box(storefronts_parent, "Store_NE_FrontWall", Vector3(4.0, 4.0, 0.6), Vector3(16.0, 2.0, -14.0), mat_high_wall)

	# South-West Storefront ("Subway Arcade")
	_add_box(storefronts_parent, "Store_SW_Back", Vector3(10.0, 2.6, 0.6), Vector3(-19.0, 1.3, 22.0), mat_high_wall)
	_add_box(storefronts_parent, "Store_SW_Back_Upper", Vector3(10.0, 1.4, 0.6), Vector3(-19.0, 3.3, 22.0), mat_high_wall_upper)
	_add_box(storefronts_parent, "Store_SW_Back_Trim", Vector3(10.0, 0.05, 0.7), Vector3(-19.0, 2.6, 22.0), mat_trim)
	
	var lbl_subway = _add_label3d(storefronts_parent, "Sign_SubwayArcade", "SUBWAY ARCADE", Vector3(-19.0, 3.2, 21.6), Color("#ff7a1a"), 1.5)
	lbl_subway.rotation_degrees.y = 180
	_add_box(storefronts_parent, "Store_SW_Divider", Vector3(0.6, 4.0, 6.5), Vector3(-14.0, 2.0, 18.75), mat_high_wall)'''
text = text.replace(storefront_original, storefront_new)

# Queen Arena Dressing (add right before Grind Rails)
queen_arena_code = '''	# Queen Arena Dressing
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

	# 9. Grind Rails (Momentum Spline Traversal)'''

text = text.replace('	# 9. Grind Rails (Momentum Spline Traversal)', queen_arena_code)

with open('scripts/mall_greybox_builder.gd', 'w') as f:
    f.write(text)
