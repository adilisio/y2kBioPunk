import re

with open('tests/test_presentation.gd', 'r') as f:
    text = f.read()

new_tests = '''	# Extension from VS11-LOOK
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

	if passed:'''

text = text.replace('	if passed:', new_tests)

with open('tests/test_presentation.gd', 'w') as f:
    f.write(text)
