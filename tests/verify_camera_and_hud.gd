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

	print("--- ALL SCENE VALIDATION CHECKS PASSED ---")
	quit(0)
