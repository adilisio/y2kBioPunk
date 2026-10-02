extends SceneTree

func _init():
	print("=== ASSEMBLING FLOODED MALL GREYBOX SCENE ===")

	var root_node = Node3D.new()
	root_node.name = "FloodedMall_Greybox"

	# Attach builder script to root node so it can be re-run in editor
	var builder_script = load("res://scripts/mall_greybox_builder.gd")
	root_node.set_script(builder_script)

	# 1. Environment & Lighting
	var env_node = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.12, 0.15, 1.0) # Deep industrial sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.42, 0.48, 1.0)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env_node.environment = env
	root_node.add_child(env_node)
	env_node.owner = root_node

	var dir_light = DirectionalLight3D.new()
	dir_light.name = "DirectionalLight3D"
	# 45-degree isometric sunlight angle
	dir_light.rotation_degrees = Vector3(-45.0, 45.0, 0.0)
	dir_light.light_color = Color(0.98, 0.96, 0.92)
	dir_light.light_energy = 1.15
	dir_light.shadow_enabled = true
	dir_light.shadow_bias = 0.03
	root_node.add_child(dir_light)
	dir_light.owner = root_node

	# 2. Build CSG Level Geometry
	root_node.build_mall_greybox()
	var level_geom = root_node.get_node("LevelGeometry")
	level_geom.owner = root_node
	_set_owner_recursive(level_geom, root_node)

	# 3. Load and instantiate Player from main.tscn template
	var main_scene = load("res://scenes/main.tscn")
	var main_instance = main_scene.instantiate()
	var player_node = main_instance.get_node("Player")
	main_instance.remove_child(player_node)
	player_node.position = Vector3(0.0, 1.0, 9.0) # Spawn facing the plaza
	root_node.add_child(player_node)
	player_node.owner = root_node
	_set_owner_recursive(player_node, root_node)

	# 4. Attach HUD
	var hud_node = main_instance.get_node("HUD")
	main_instance.remove_child(hud_node)
	root_node.add_child(hud_node)
	hud_node.owner = root_node
	_set_owner_recursive(hud_node, root_node)

	main_instance.queue_free()

	# Save as PackedScene
	var packed = PackedScene.new()
	var pack_result = packed.pack(root_node)
	if pack_result != OK:
		printerr("Failed to pack FloodedMall_Greybox scene: ", pack_result)
		quit(1)
		return

	var save_result = ResourceSaver.save(packed, "res://scenes/FloodedMall_Greybox.tscn")
	if save_result != OK:
		printerr("Failed to save FloodedMall_Greybox.tscn: ", save_result)
		quit(1)
		return

	print("[SUCCESS] FloodedMall_Greybox.tscn assembled and saved successfully!")
	quit(0)

func _set_owner_recursive(node: Node, scene_owner: Node) -> void:
	for child in node.get_children():
		child.owner = scene_owner
		_set_owner_recursive(child, scene_owner)
