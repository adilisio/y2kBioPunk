extends SceneTree

func _init():
	print("--- VALIDATING SCENE LOADING & CAMERA/PAGER FIXES ---")
	
	# 1. Test player.tscn
	var player_scene = load("res://scenes/player.tscn")
	assert(player_scene != null, "scenes/player.tscn failed to load")
	var player_inst = player_scene.instantiate()
	assert(player_inst != null, "scenes/player.tscn failed to instantiate")
	var cam_rig = player_inst.find_child("IsometricCameraRig", true, false)
	assert(cam_rig != null, "IsometricCameraRig missing from player")
	assert(cam_rig.collision_mask == 0, "IsometricCameraRig collision_mask must be 0")
	player_inst.free()
	print("PASS: scenes/player.tscn loaded and camera collision_mask is 0.")

	# 2. Test scenes/main.tscn
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "scenes/main.tscn failed to load")
	var main_inst = main_scene.instantiate()
	assert(main_inst != null, "scenes/main.tscn failed to instantiate")
	var main_cam = main_inst.find_child("IsometricCameraRig", true, false)
	assert(main_cam != null, "IsometricCameraRig missing from main.tscn")
	assert(main_cam.collision_mask == 0, "main.tscn camera collision_mask must be 0")
	var pager_box = main_inst.find_child("PagerBox", true, false) as PanelContainer
	assert(pager_box != null, "PagerBox missing from main.tscn")
	assert(pager_box.custom_minimum_size.y == 0, "PagerBox custom_minimum_size.y must be 0")
	assert(pager_box.size_flags_vertical == Control.SIZE_SHRINK_BEGIN or pager_box.size_flags_vertical == 0, "PagerBox vertical flag must shrink/top-align")
	assert(pager_box.anchor_bottom == 0.0, "PagerBox anchor_bottom must be 0.0")
	main_inst.free()
	print("PASS: scenes/main.tscn loaded and camera/pager verified.")

	# 3. Test scenes/FloodedMall_Greybox.tscn
	var mall_scene = load("res://scenes/FloodedMall_Greybox.tscn")
	assert(mall_scene != null, "scenes/FloodedMall_Greybox.tscn failed to load")
	var mall_inst = mall_scene.instantiate()
	assert(mall_inst != null, "scenes/FloodedMall_Greybox.tscn failed to instantiate")
	var mall_cam = mall_inst.find_child("IsometricCameraRig", true, false)
	assert(mall_cam != null, "IsometricCameraRig missing from FloodedMall")
	assert(mall_cam.collision_mask == 0, "FloodedMall camera collision_mask must be 0")
	var mall_pager = mall_inst.find_child("PagerBox", true, false) as PanelContainer
	assert(mall_pager != null, "PagerBox missing from FloodedMall")
	assert(mall_pager.custom_minimum_size.y == 0, "Mall PagerBox custom_minimum_size.y must be 0")
	assert(mall_pager.size_flags_vertical == Control.SIZE_SHRINK_BEGIN or mall_pager.size_flags_vertical == 0, "Mall PagerBox vertical flag must shrink/top-align")
	assert(mall_pager.anchor_bottom == 0.0, "Mall PagerBox anchor_bottom must be 0.0")
	mall_inst.free()
	print("PASS: scenes/FloodedMall_Greybox.tscn loaded and camera/pager verified.")

	# 4. Test main.tscn
	var root_main_scene = load("res://main.tscn")
	assert(root_main_scene != null, "main.tscn failed to load")
	var root_main_inst = root_main_scene.instantiate()
	assert(root_main_inst != null, "main.tscn failed to instantiate")
	var root_pager = root_main_inst.find_child("PagerBox", true, false) as PanelContainer
	assert(root_pager != null, "PagerBox missing from main.tscn")
	assert(root_pager.custom_minimum_size.y == 0, "Root main.tscn PagerBox custom_minimum_size.y must be 0")
	assert(root_pager.size_flags_vertical == Control.SIZE_SHRINK_BEGIN or root_pager.size_flags_vertical == 0, "Root main.tscn PagerBox vertical flag must shrink/top-align")
	assert(root_pager.anchor_bottom == 0.0, "Root main.tscn PagerBox anchor_bottom must be 0.0")
	root_main_inst.free()
	print("PASS: main.tscn loaded and camera/pager verified.")

	print("--- ALL SCENE VALIDATION CHECKS PASSED ---")
	quit(0)
