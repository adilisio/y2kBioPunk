extends SceneTree

func _init():
	var exit_code = run_tests()
	quit(exit_code)

func run_tests() -> int:
	print("\n========================================================")
	print(">>> RUNNING FLAMETHROWER PARTICLES VERIFICATION TEST <<<")
	print("========================================================\n")

	var player_scene = load("res://scenes/player.tscn")
	assert(player_scene != null, "scenes/player.tscn must load successfully")

	var player = player_scene.instantiate() as CharacterBody3D
	assert(player != null, "Player must instantiate from player.tscn")
	root.add_child(player)

	var particles = player.find_child("FlamethrowerParticles", true, false) as GPUParticles3D
	assert(particles != null, "FlamethrowerParticles GPUParticles3D must exist on player")

	# 1. Draw pass mesh is QuadMesh
	var mesh = particles.draw_pass_1
	assert(mesh != null, "particles.draw_pass_1 must not be null")
	assert(mesh is QuadMesh, "draw_pass_1 must be a QuadMesh, got: %s" % mesh.get_class())
	print("[PASS] draw_pass_1 is QuadMesh.")

	# 2. Material properties
	var mat = mesh.material as StandardMaterial3D
	assert(mat != null, "QuadMesh material must be StandardMaterial3D")
	assert(mat.billboard_mode == BaseMaterial3D.BILLBOARD_PARTICLES or mat.billboard_mode == 2, "billboard_mode must be billboard mode (2 or 3), got: %d" % mat.billboard_mode)
	assert(mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "transparency must be TRANSPARENCY_ALPHA (1), got: %d" % mat.transparency)
	assert(mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "shading_mode must be SHADING_MODE_UNSHADED (0), got: %d" % mat.shading_mode)
	assert(mat.vertex_color_use_as_albedo == true, "vertex_color_use_as_albedo must be true")
	print("[PASS] Material transparency, shading_mode, and billboard_mode verified.")

	# 3. Albedo texture is soft radial gradient texture
	var tex = mat.albedo_texture
	assert(tex != null, "albedo_texture must not be null")
	assert(tex is GradientTexture2D, "albedo_texture must be GradientTexture2D, got: %s" % tex.get_class())
	var grad_tex = tex as GradientTexture2D
	assert(grad_tex.fill == 1, "GradientTexture2D fill must be FILL_RADIAL (1), got: %d" % grad_tex.fill)
	print("[PASS] Albedo texture is soft radial gradient.")

	# 4. ParticleProcessMaterial: Scale Curve, Color Ramp, Spread
	var proc_mat = particles.process_material as ParticleProcessMaterial
	assert(proc_mat != null, "process_material must be ParticleProcessMaterial")
	assert(proc_mat.scale_curve != null, "scale_curve must be assigned on process_material")
	assert(proc_mat.color_ramp != null, "color_ramp must be assigned on process_material")
	assert(proc_mat.spread > 15.0, "spread must be widened (> 15 deg), got: %f" % proc_mat.spread)
	print("[PASS] ParticleProcessMaterial scale curve, color ramp, and spread verified.")

	print("========================================================")
	print(">>> ALL FLAMETHROWER PARTICLE TESTS PASSED! <<<")
	print("========================================================\n")
	return 0
