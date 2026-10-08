extends Area3D
class_name BioCheckpoint

## BioCheckpoint (Bio-Stabilizer Terminal)
## Interactive checkpoint station in the flooded mall.
## Triggers SaveManager to serialize player Level, XP, stats, and tape to JSON.

@export var checkpoint_id: String = "BioStabilizer_01"
@export var respawn_offset: Vector3 = Vector3(0.0, 0.5, 1.5)

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
	if mesh: return
	
	mesh = CSGBox3D.new()
	mesh.name = "Pedestal"
	mesh.size = Vector3(0.9, 0.6, 0.7)
	mesh.position = Vector3(0.0, 0.3, 0.0)
	var mat_pedestal = StandardMaterial3D.new()
	mat_pedestal.albedo_color = Color(0.1, 0.1, 0.15)
	mesh.material = mat_pedestal
	add_child(mesh)
	
	var housing = CSGBox3D.new()
	housing.name = "Housing"
	housing.size = Vector3(0.9, 0.6, 0.7)
	housing.position = Vector3(0.0, 0.8, 0.0)
	housing.rotation_degrees.x = 25.0
	housing.material = mat_pedestal
	add_child(housing)
	
	var screen_mesh = CSGBox3D.new()
	screen_mesh.name = "Screen"
	screen_mesh.size = Vector3(0.8, 0.5, 0.05)
	screen_mesh.position = Vector3(0.0, 0.0, 0.35)
	var mat_screen = StandardMaterial3D.new()
	mat_screen.albedo_color = Color.BLACK
	mat_screen.emission_enabled = true
	mat_screen.emission = Color(0.0, 0.6, 0.8) # cyan
	mat_screen.emission_energy_multiplier = 1.2
	screen_mesh.material = mat_screen
	housing.add_child(screen_mesh)
	
	var lbl = Label3D.new()
	lbl.name = "Label"
	lbl.text = "BIO-STABILIZER"
	lbl.position = Vector3(0.0, 1.3, 0.0)
	lbl.pixel_size = 0.006
	lbl.modulate = Color.CYAN
	lbl.outline_modulate = Color.BLACK
	lbl.outline_size = 4
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.shaded = false
	add_child(lbl)
	
	var pulse_light = OmniLight3D.new()
	pulse_light.name = "PulseLight"
	pulse_light.light_color = Color.CYAN
	pulse_light.light_energy = 1.0
	pulse_light.omni_range = 3.0
	pulse_light.shadow_enabled = false
	pulse_light.position = Vector3(0.0, 1.2, 0.0)
	add_child(pulse_light)
	
	if not Engine.is_editor_hint():
		var tween = create_tween().set_loops()
		tween.tween_property(pulse_light, "light_energy", 1.5, 1.0)
		tween.tween_property(pulse_light, "light_energy", 0.5, 1.0)
	
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
			# Pulse green
			var housing = get_node_or_null("Housing")
			if housing:
				var screen = housing.get_node_or_null("Screen")
				if screen and screen.material:
					(screen.material as StandardMaterial3D).emission = Color(0.2, 1.0, 0.4, 1.0)
			var light = get_node_or_null("PulseLight")
			if light:
				light.light_color = Color(0.2, 1.0, 0.4, 1.0)
			print("[Checkpoint] *** BIO-STABILIZER ACTIVATED *** Progression saved for %s at %s" % [body.name, checkpoint_id])
