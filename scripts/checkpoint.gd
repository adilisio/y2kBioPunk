extends Area3D
class_name BioCheckpoint

## BioCheckpoint (Bio-Stabilizer Terminal)
## Interactive checkpoint station in the flooded mall.
## Triggers SaveManager to serialize player Level, XP, stats, and tape to JSON.

@export var checkpoint_id: String = "BioStabilizer_01"
@export var respawn_offset: Vector3 = Vector3(0.0, 0.5, 1.5)

var _last_save_msec: int = -1000
var activated: bool = false
var mesh: CSGBox3D = null

func _ready() -> void:
	# Layer 0, mask 2 (Player)
	collision_layer = 0
	collision_mask = 2
	add_to_group("checkpoints")
	_build_visuals()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _build_visuals() -> void:
	if mesh:
		return
	mesh = CSGBox3D.new()
	mesh.name = "TerminalMesh"
	mesh.size = Vector3(1.0, 1.8, 0.8)
	mesh.position = Vector3(0.0, 0.9, 0.0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.2, 0.25, 1.0)
	mat.metallic = 0.5
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = Color(0.0, 0.6, 0.8, 1.0) # Cyber cyan glow
	mesh.material = mat
	add_child(mesh)

	var col = CollisionShape3D.new()
	col.name = "TriggerCol"
	var box = BoxShape3D.new()
	box.size = Vector3(2.5, 2.2, 2.5)
	col.shape = box
	col.position = Vector3(0.0, 1.1, 0.0)
	add_child(col)

func _on_body_entered(body: Node3D) -> void:
	if not (body.is_in_group("player") or body.name == "Player" or body is CharacterBody3D):
		return

	if Time.get_ticks_msec() - _last_save_msec < 1000:
		return

	var spawn_pos = global_position + respawn_offset

	# Access SaveManager autoload
	var sm = get_node_or_null("/root/SaveManager")
	if not sm:
		var script = load("res://scripts/save_manager.gd")
		if script:
			sm = script.new()
			get_tree().root.add_child(sm)

	if sm and sm.has_method("save_player_data"):
		var success = sm.call("save_player_data", body, checkpoint_id, spawn_pos)
		if success:
			_last_save_msec = Time.get_ticks_msec()
			if body.has_method("set_current_health") and body.has_method("get_max_health"):
				body.set_current_health(body.get_max_health())
			var hud = get_tree().get_first_node_in_group("hud")
			if hud and hud.has_method("page_message"):
				hud.page_message("PROGRESS SAVED // BIO-STABILIZER")
		if success and mesh and mesh.material is StandardMaterial3D:
			# Pulse green
			var mat = mesh.material as StandardMaterial3D
			mat.emission = Color(0.2, 1.0, 0.4, 1.0)
			print("[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for %s at %s" % [body.name, checkpoint_id])
