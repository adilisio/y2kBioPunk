extends SceneTree
## Headless diagnostic: spawns each enemy, reports whether its GLB model attached
## (vs. CSG fallback), the model's fitted bounds, and that hit flash + reset run
## without errors.
##   ./Godot_v4.3-stable_win64.exe --headless --path . -s ops/tools/check_enemy_models.gd

func _init() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	var specs := [
		["cicada", "res://scenes/neon_cicada.tscn", null],
		["roach", null, "res://scripts/sludge_roach.gd"],
		["turret", null, "res://scripts/corrupted_kiosk_turret.gd"],
		["queen", null, "res://scripts/dial_up_queen.gd"],
	]
	var ok := true
	for spec in specs:
		var node: Node3D = null
		if spec[1]:
			node = (load(spec[1]) as PackedScene).instantiate()
		else:
			node = CharacterBody3D.new()
			node.set_script(load(spec[2]))
		holder.add_child(node)
		await process_frame
		var model := node.find_child("Model", true, false) as Node3D
		if model == null:
			print("[check] %s: NO MODEL (CSG fallback)" % spec[0])
			ok = false
		else:
			var box := EnemyModel.bounds(model)
			var geo := EnemyModel.geometry(model)
			print("[check] %s: model attached, geometry=%d, fitted bounds pos=%s size=%s" % [spec[0], geo.size(), box.position, box.size])
		if node.has_method("_flash_hit_visual"):
			node.call("_flash_hit_visual")
			await process_frame
			var tinted := 0
			for g in EnemyModel.geometry(node):
				if g.material_overlay != null:
					tinted += 1
			node.call("_reset_flash_visual")
			await process_frame
			var still := 0
			for g in EnemyModel.geometry(node):
				if g.material_overlay != null:
					still += 1
			print("[check] %s: flash tinted %d surfaces, after reset %d remain tinted" % [spec[0], tinted, still])
			if tinted == 0:
				ok = false
		node.queue_free()
	await process_frame
	# Props placed by the mall builder: each should be a model root (Node3D named like the greybox box) plus a collider.
	var mall := (load("res://scenes/FloodedMall_Greybox.tscn") as PackedScene).instantiate()
	holder.add_child(mall)
	await process_frame
	await process_frame
	for prop_name in ["Kiosk_BeeperWorld", "Kiosk_NeonJulius", "Kiosk_CassetteVault", "FountainSpire", "Planter_SouthWest", "Planter_SouthEast", "Planter_EastWing"]:
		var n := mall.find_child(prop_name, true, false)
		var col := mall.find_child(prop_name + "_Collision", true, false)
		if n == null:
			print("[check] prop %s: MISSING" % prop_name)
			ok = false
		elif n is CSGShape3D:
			print("[check] prop %s: CSG fallback" % prop_name)
			ok = false
		else:
			var box := EnemyModel.bounds(n)
			print("[check] prop %s: model, size=%s, collider=%s" % [prop_name, box.size, col != null])
			if col == null:
				ok = false
	mall.queue_free()
	await process_frame
	print("[check] RESULT: %s" % ("OK" if ok else "PROBLEMS"))
	quit(0 if ok else 1)
