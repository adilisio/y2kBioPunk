class_name EnemyModel
extends RefCounted
## Helpers for swapping CSG placeholder bodies for imported GLB models.
##
## Meshy exports face +Z with Y up and arbitrary size, so `attach` instances the
## scene under `parent`, scales it uniformly to `fit_height` metres, turns it to
## face Godot's -Z forward (plus `yaw_degrees` / `pitch_degrees` for per-asset correction) and
## grounds it so the model's lowest point sits at `ground_y`. The returned root
## Node3D is what enemy scripts tween (scale, squash) in place of the old CSG
## node. `tint` / `untint` apply a translucent emissive overlay across every
## GeometryInstance3D under a root, so textures stay visible through hit flashes
## and state colours; it works on CSG placeholders too.


## Loaded GLB scenes are kept alive here. Without this, `load()` drops the PackedScene (and its
## embedded textures) as soon as the last instance is spawned, so every Queen summon or enemy
## respawn re-read the 20 MB .scn from disk and re-uploaded its textures: a measured 560 ms stall.
static var _scene_cache: Dictionary = {}

static func packed_scene(path: String) -> PackedScene:
	var cached = _scene_cache.get(path)
	if cached:
		return cached
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	if packed:
		_scene_cache[path] = packed
	return packed

static func attach(parent: Node, path: String, fit_height: float, ground_y: float = 0.0, yaw_degrees: float = 0.0, pitch_degrees: float = 0.0, node_name: String = "Model") -> Node3D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var packed := packed_scene(path)
	if packed == null:
		push_warning("EnemyModel: %s is not a PackedScene" % path)
		return null
	var model := packed.instantiate() as Node3D
	if model == null:
		push_warning("EnemyModel: %s has no Node3D root" % path)
		return null
	var root := Node3D.new()
	root.name = node_name
	root.add_child(model)
	parent.add_child(root)

	var box := bounds(model)
	if box.size.y > 0.0001:
		model.scale = Vector3.ONE * (fit_height / box.size.y)
	model.rotation = Vector3(deg_to_rad(pitch_degrees), PI + deg_to_rad(yaw_degrees), 0.0)
	box = bounds(model)
	var centre := box.get_center()
	model.position += Vector3(-centre.x, ground_y - box.position.y, -centre.z)
	return root


## Axis-aligned bounds of every MeshInstance3D under `node`, in the space of
## `node`'s parent (so it accounts for node's own transform).
static func bounds(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mi in mesh_instances(node):
		var xf: Transform3D = _relative_transform(mi, node.get_parent())
		var box: AABB = xf * mi.get_aabb()
		if first:
			result = box
			first = false
		else:
			result = result.merge(box)
	return result


static func _relative_transform(node: Node3D, ancestor: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != ancestor and n is Node3D:
		xf = (n as Node3D).transform * xf
		n = n.get_parent()
	return xf


static func mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(mesh_instances(c))
	return out


static func geometry(node: Node) -> Array[GeometryInstance3D]:
	var out: Array[GeometryInstance3D] = []
	if node is GeometryInstance3D:
		out.append(node)
	for c in node.get_children():
		out.append_array(geometry(c))
	return out


## Builds a translucent emissive overlay material for `tint`.
static func tint_material(color: Color, alpha: float = 0.55, emission_energy: float = 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = emission_energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


static func tint(root: Node, mat: Material) -> void:
	if root == null or not is_instance_valid(root):
		return
	for g in geometry(root):
		g.material_overlay = mat


static func untint(root: Node) -> void:
	tint(root, null)
