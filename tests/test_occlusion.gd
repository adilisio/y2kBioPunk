extends SceneTree
const U = preload("res://tests/_test_util.gd")
const Models = preload("res://scripts/enemy_model.gd")

func _init() -> void:
	call_deferred("run")

func step(seconds: float) -> void:
	await U.await_physics_frames(self, int(ceil(seconds * Engine.physics_ticks_per_second)) + 1)

func registered(fader: Node, visual: GeometryInstance3D) -> bool:
	for entry in fader.occluders:
		if entry.visual == visual:
			return true
	return false

func run() -> void:
	U.reset()
	print("=== test_occlusion ===")
	U.setup_isolated_save(root.get_node("SaveManager"))
	var mall = U.track(load("res://scenes/FloodedMall_Greybox.tscn").instantiate())
	root.add_child(mall)
	current_scene = mall
	var player := mall.get_node("Player") as CharacterBody3D
	player.set_physics_process(false)
	for node_name in ["Enemies", "BossEncounterTrigger", "BioCheckpoint", "TutorialDirector"]:
		var node: Node = mall.get_node_or_null(node_name)
		if node:
			node.process_mode = Node.PROCESS_MODE_DISABLED
	var fader: Node = mall.get_node_or_null("OcclusionFader")
	if not U.check(fader != null, "Real mall creates its occlusion fader"):
		await U.cleanup(self)
		U.finish(self)
		return
	var geo := mall.get_node("LevelGeometry")
	U.check(fader.occluders.size() >= 20, "At least 20 visual occluders registered")
	for name in ["Wall_North", "Wall_West"]:
		U.check(registered(fader, geo.get_node(name)), name + " registered")
	for name in ["DeckFloor", "DeckRail_East", "DeckRail_North"]:
		U.check(registered(fader, geo.get_node("MezzanineTerrace/" + name)), name + " registered")
	for pillar in geo.get_node("StructuralPillars").get_children():
		U.check(registered(fader, pillar), str(pillar.name) + " registered")
	for wall in geo.get_node("StorefrontAlcoves").get_children():
		U.check(registered(fader, wall), str(wall.name) + " registered")
	var prop_meshes := 0
	for prop in geo.get_node("DerelictKiosks").get_children():
		if prop is StaticBody3D:
			continue
		var meshes := Models.mesh_instances(prop)
		U.check(not meshes.is_empty(), str(prop.name) + " has imported meshes")
		for mesh in meshes:
			prop_meshes += 1
			U.check(registered(fader, mesh), str(prop.name) + " mesh registered")
	for mesh in Models.mesh_instances(geo.get_node("SunkenAtriumBasin/FountainSpire")):
		U.check(registered(fader, mesh), "Fountain mesh registered")
	for path in ["MainFloor", "Wall_South", "Wall_East", "MezzanineTerrace/DeckRamp", "SunkenAtriumBasin/BasinCurb_East", "SunkenAtriumBasin/FountainBase", "GrindRails/Rail_SunkenAtriumCurved/RailMesh"]:
		U.check(not registered(fader, geo.get_node(path)), path + " excluded")
	for mesh in Models.mesh_instances(geo.get_node("PlantersAndCurbs")):
		U.check(not registered(fader, mesh), "Planter mesh excluded")
	# Check the one-frame warm-up without requiring a rendered headless frame.
	fader._process(0.0)
	U.check(fader._warm_instances.size() == 3, "Box, cylinder and prop mesh warmed")
	for visual in fader._warm_instances:
		U.check(is_equal_approx(visual.transparency, 0.01), "Warm-up uses instance transparency")
	fader._process(0.0)
	for visual in fader._warm_instances:
		U.check(is_zero_approx(visual.transparency), "Warm-up restored next frame")
	print("REGISTRY visuals=%d kiosk_meshes=%d warm_kinds=%d" % [fader.occluders.size(), prop_meshes, fader._warm_instances.size()])

	var camera := root.get_viewport().get_camera_3d()
	var pillar := geo.get_node("StructuralPillars/Pillar_06") as CSGCylinder3D
	var unrelated := geo.get_node("StructuralPillars/Pillar_01") as CSGCylinder3D
	var original_color: Color = pillar.material.albedo_color
	var original_mode: int = pillar.material.transparency
	# Camera forward is -basis.z: move NW of the pillar, with camera SE behind it.
	var forward := -camera.global_basis.z
	forward.y = 0.0
	player.global_position = pillar.global_position + forward.normalized() * 3.0
	player.global_position.y = 0.1
	await step(1.2)
	U.check(pillar.transparency > 0.5, "Pillar between player and camera fades")
	U.check(is_zero_approx(unrelated.transparency), "Unrelated pillar stays fully opaque")
	U.check(pillar.material.albedo_color == original_color and pillar.material.transparency == original_mode, "Fade never alters the material")
	U.check(fader.aabb_tests_last_tick == fader.occluders.size(), "One AABB test per registered visual per physics tick")
	print("PILLAR faded=%.4f unrelated=%.4f tests/tick=%d" % [pillar.transparency, unrelated.transparency, fader.aabb_tests_last_tick])
	player.global_position.x -= 10.0
	await step(1.2)
	U.check(pillar.transparency < 0.05, "Pillar recovers after moving 10 m away")
	print("PILLAR restored=%.4f" % pillar.transparency)


	# Deterministic simultaneous intersections through the builder's actual registry API.
	var start := camera.global_position
	var end := player.global_position + Vector3.UP
	var mat := StandardMaterial3D.new()
	var first: CSGBox3D = mall._add_box(geo, "TestWallA", Vector3(1, 3, 1), start.lerp(end, 0.4), mat)
	var second: CSGBox3D = mall._add_box(geo, "TestWallB", Vector3(1, 3, 1), start.lerp(end, 0.7), mat)
	fader.finish_build()
	await step(1.1)
	U.check(first.transparency > 0.5 and second.transparency > 0.5, "Both simultaneous occluders fade")
	print("SIMULTANEOUS a=%.4f b=%.4f" % [first.transparency, second.transparency])
	# Freeze the real camera briefly and move only the segment endpoint off both boxes.
	var rig := camera.get_parent()
	rig.set_physics_process(false)
	player.global_position += Vector3(10, 0, -10)
	await step(0.1)
	U.check(first.transparency > 0.65 and second.transparency > 0.65, "Hysteresis holds both fades for at least 0.15 seconds")
	await step(1.1)
	U.check(first.transparency < 0.05 and second.transparency < 0.05, "Both simultaneous occluders restore")
	rig.set_physics_process(true)

	# Check restoration while instances still exist, then the whole-scene teardown.
	first.transparency = 0.7
	second.transparency = 0.7
	var old_fader: WeakRef = weakref(fader)
	fader.queue_free()
	await U.await_frames(self, 2)
	U.check(old_fader.get_ref() == null, "Fader freed")
	U.check(is_zero_approx(first.transparency) and is_zero_approx(second.transparency), "Fader teardown restores surviving visuals")
	# Rebuild also retires the previous registry and constructs a fresh one.
	mall.build_mall_greybox()
	var rebuilt_fader: WeakRef = weakref(mall.get_node("OcclusionFader"))
	await U.await_frames(self, 3)
	U.check(rebuilt_fader.get_ref().occluders.size() >= 20, "Runtime rebuild creates a fresh registry")
	current_scene = null
	await U.cleanup(self)
	U.check(rebuilt_fader.get_ref() == null, "Mall teardown cleans up the rebuilt fader")
	print("CLEANUP fader_freed=true")
	U.finish(self)
