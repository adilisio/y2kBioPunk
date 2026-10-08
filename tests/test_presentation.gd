extends SceneTree

var log_text: String = ""

func my_print(s: String) -> void:
	print(s)
	log_text += s + "\n"

func _init() -> void:
	my_print("--- Running WP-3 Presentation Tests ---")
	
	var passed = true
	var mall_scene = load("res://scenes/FloodedMall_Greybox.tscn")
	var mall = mall_scene.instantiate()
	if mall.has_method("build_mall_greybox"):
		mall.build_mall_greybox()
	
	# Test 1: WorldEnvironment
	var env = mall.get_node("WorldEnvironment")
	if env and env.environment:
		if not env.environment.glow_enabled:
			my_print("FAIL: Glow is not enabled on WorldEnvironment.")
			passed = false
		if not env.environment.ssao_enabled:
			my_print("FAIL: SSAO is not enabled on WorldEnvironment.")
			passed = false
	else:
		my_print("FAIL: WorldEnvironment not found or missing environment.")
		passed = false

	# Find the newest LevelGeometry
	var level_geo = null
	var cnames = []
	for c in mall.get_children():
		cnames.append(c.name)
		if not c.is_queued_for_deletion() and c.has_node("Wall_South"):
			level_geo = c
	my_print("Mall children: " + str(cnames))

	# Test 2: South/East wall height <= 1.1
	var wall_s = level_geo.get_node_or_null("Wall_South") if level_geo else null
	var wall_e = level_geo.get_node_or_null("Wall_East") if level_geo else null
	if wall_s and wall_s.size.y > 1.1:
		my_print("FAIL: Wall_South height is greater than 1.1 (actual: %f)" % wall_s.size.y)
		passed = false
	if wall_e and wall_e.size.y > 1.1:
		my_print("FAIL: Wall_East height is greater than 1.1 (actual: %f)" % wall_e.size.y)
		passed = false

	var builder = mall
	if builder:
		if not level_geo:
			my_print("LEVEL_GEO IS NULL!!!")
		else:
			var cnames_lg = []
			for c in level_geo.get_children():
				cnames_lg.append(c.name)
			my_print("LevelGeo children: " + str(cnames_lg))
		
		var grind_rails = level_geo.get_node_or_null("GrindRails") if level_geo else null
		var rail_node = grind_rails.get_node_or_null("Rail_SunkenAtriumCurved") if grind_rails else null
		if rail_node:
			my_print("Rail node children: " + str(rail_node.get_children()))
		
		var rail_mesh = level_geo.get_node_or_null("GrindRails/Rail_SunkenAtriumCurved/RailMesh") if level_geo else null
		if rail_mesh:
			var rail_mat = rail_mesh.material
			if rail_mat and rail_mat is StandardMaterial3D:
				if not rail_mat.emission_enabled:
					my_print("FAIL: Rails material emission is not enabled.")
					passed = false
				if rail_mat.emission != Color("#ffd23f") or rail_mat.emission_energy_multiplier < 0.5:
					my_print("FAIL: Rails material emission color is incorrect. %s %s" % [rail_mat.emission, rail_mat.emission_energy_multiplier])
					passed = false
			else:
				my_print("FAIL: mat_rail missing or wrong type.")
				passed = false
		else:
			my_print("FAIL: RailMesh not found.")
			passed = false

	# Test 4: HUD control scale < 1.0 (checking HUD in player scene)
	var hud = mall.get_node_or_null("HUD")
	if hud:
		# Test 5: page_message exists
		if not hud.has_method("page_message"):
			my_print("FAIL: HUD missing page_message method.")
			passed = false
		
		var pager_box = hud.get_node_or_null("HUDOverlay/PagerBox")
		if pager_box and (pager_box.scale.x < 1.0 or pager_box.scale.y < 1.0):
			my_print("FAIL: PagerBox scale is less than 1.0.")
			passed = false
			
		var walkman_box = hud.get_node_or_null("HUDOverlay/WalkmanBox")
		if walkman_box and (walkman_box.scale.x < 1.0 or walkman_box.scale.y < 1.0):
			my_print("FAIL: WalkmanBox scale is less than 1.0.")
			passed = false
	else:
		my_print("FAIL: HUD not found in mall.")
		passed = false

	# Extension from VS11-LOOK
	var arena = level_geo.get_node_or_null("QueenArena") if level_geo else null
	if arena:
		var arena_lbl = arena.get_node_or_null("ArenaSign_Title")
		if not arena_lbl or not (arena_lbl is Label3D):
			my_print("FAIL: Arena signage Label3D exists on the north wall missing.")
			passed = false
			
		var light_count = 0
		for c in arena.get_children():
			if c is OmniLight3D: light_count += 1
		if light_count < 2:
			my_print("FAIL: >= 2 arena lights exist failed.")
			passed = false
	else:
		my_print("FAIL: QueenArena not found.")
		passed = false
		
	var checkpoint = mall.find_child("BioStabilizer*", true, false)
	if checkpoint and checkpoint.has_method("_build_visuals"):
		checkpoint._build_visuals()
		var cp_lbl = checkpoint.find_child("Label", true, false)
		if not cp_lbl or not (cp_lbl is Label3D):
			my_print("FAIL: Checkpoint Label3D missing.")
			passed = false
		var cp_light = checkpoint.find_child("PulseLight", true, false)
		if not cp_light or not (cp_light is OmniLight3D):
			my_print("FAIL: Checkpoint OmniLight3D missing.")
			passed = false
	
	var floor_box = level_geo.get_node_or_null("MainFloor") if level_geo else null
	if floor_box and floor_box.material is StandardMaterial3D:
		var mat = floor_box.material as StandardMaterial3D
		if not mat.uv1_triplanar:
			my_print("FAIL: Floor material uv1_triplanar is not on.")
			passed = false
		if not mat.albedo_texture:
			my_print("FAIL: Floor material missing albedo texture.")
			passed = false
			
	var menu_scene = load("res://scenes/main_menu.tscn")
	var menu = menu_scene.instantiate()
	var menu_bg = menu.get_node_or_null("Background")
	if not menu_bg or not (menu_bg is TextureRect):
		my_print("FAIL: Menu scene TextureRect background missing.")
		passed = false
	var btn1 = menu.find_child("NewGameButton", true, false)
	var btn2 = menu.find_child("LoadGameButton", true, false)
	var btn3 = menu.find_child("ExitButton", true, false)
	if not btn1 or not btn2 or not btn3:
		my_print("FAIL: Menu scene named buttons missing.")
		passed = false

	if passed:
		my_print("RESULT: PASS")
		quit(0)
	else:
		my_print("RESULT: FAIL")
		quit(1)
