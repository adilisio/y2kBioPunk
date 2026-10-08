extends SceneTree
## Headless GLB inspector. Run after `--import`:
##   ./Godot_v4.3-stable_win64.exe --headless --path . -s ops/tools/inspect_glb.gd -- res://assets/models/neon_cicada.glb [more...]
## Prints node tree depth, mesh/material counts, triangle count and AABB so a
## model's native size and facing can be judged before wiring it into a scene.

func _init() -> void:
	var paths: PackedStringArray = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("res://"):
			paths.append(a)
	if paths.is_empty():
		push_error("no model paths given")
		quit(1)
		return
	var holder := Node3D.new()
	root.add_child(holder)
	var fail := false
	for p in paths:
		if not _inspect(p, holder):
			fail = true
	quit(1 if fail else 0)


func _inspect(path: String, holder: Node3D) -> bool:
	if not ResourceLoader.exists(path):
		print("[inspect] MISSING %s" % path)
		return false
	var packed := load(path) as PackedScene
	if packed == null:
		print("[inspect] NOT A SCENE %s" % path)
		return false
	var inst := packed.instantiate() as Node3D
	holder.add_child(inst)
	var meshes := EnemyModel.mesh_instances(inst)
	var tris := 0
	var mats := {}
	for mi in meshes:
		var m := mi.mesh
		if m == null:
			continue
		for s in m.get_surface_count():
			var arrays := m.surface_get_arrays(s)
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			tris += (idx.size() / 3) if idx.size() > 0 else ((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3)
			var mat := mi.get_active_material(s)
			if mat:
				mats[mat.get_instance_id()] = mat
	var box := EnemyModel.bounds(inst)
	print("[inspect] %s" % path)
	print("  meshes=%d materials=%d triangles=%d" % [meshes.size(), mats.size(), tris])
	print("  aabb pos=%s size=%s (height %.2f m, footprint %.2f x %.2f)" % [box.position, box.size, box.size.y, box.size.x, box.size.z])
	print("  centre=%s  min_y=%.3f" % [box.get_center(), box.position.y])
	for mat in mats.values():
		if mat is BaseMaterial3D:
			var bm := mat as BaseMaterial3D
			print("  material %s albedo_tex=%s normal=%s emission=%s" % [bm.resource_name, bm.albedo_texture != null, bm.normal_enabled, bm.emission_enabled])
	inst.queue_free()
	return true
