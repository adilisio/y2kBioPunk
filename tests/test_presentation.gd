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
				if rail_mat.emission != Color("#ffd23f") or not is_equal_approx(rail_mat.emission_energy_multiplier, 0.6):
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

	var f = FileAccess.open("res://test_out.txt", FileAccess.WRITE)
	if passed:
		my_print("RESULT: PASS")
		f.store_string(log_text)
		f.close()
		quit(0)
	else:
		my_print("RESULT: FAIL")
		f.store_string(log_text)
		f.close()
		quit(1)
