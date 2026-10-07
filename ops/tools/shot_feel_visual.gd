extends SceneTree
## Optional off-screen visual QA fixture; no production scene/save mutations.

func _init() -> void:
	call_deferred("run")

func shot(index: int) -> void:
	await RenderingServer.frame_post_draw
	var out := "res://ops/runs/shots/wp2-isolated.%d.png" % index
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	var err := root.get_texture().get_image().save_png(out)
	if err != OK:
		push_error("Screenshot failed: " + out)
		quit(1)
	print("FEEL_VISUAL ", out)

func run() -> void:
	var mall := load("res://scenes/FloodedMall_Greybox.tscn").instantiate() as Node3D
	mall.set_script(null)
	for name in ["Enemies", "HUD", "BossEncounterTrigger", "Checkpoint"]:
		var node := mall.get_node_or_null(name)
		if node:
			node.free()
	root.add_child(mall)
	current_scene = mall
	var player: CharacterBody3D = mall.get_node("Player")
	player.global_position = Vector3(0, 0.1, 17)
	await create_timer(1.0).timeout
	await shot(0)
	Input.action_press("move_forward")
	await create_timer(0.5).timeout
	await shot(1)
	Input.action_release("move_forward")
	Input.action_press("attack")
	await create_timer(0.12).timeout
	await shot(2)
	Input.action_release("attack")
	await create_timer(0.5).timeout
	Input.action_press("toggle_skates")
	await process_frame
	await process_frame
	Input.action_release("toggle_skates")
	Input.action_press("move_forward")
	await create_timer(0.9).timeout
	await shot(3)
	Input.action_release("move_forward")
	current_scene = null
	mall.queue_free()
	await process_frame
	await process_frame
	print("FEEL_VISUAL PASS")
	quit(0)
