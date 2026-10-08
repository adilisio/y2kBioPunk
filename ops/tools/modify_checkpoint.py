with open('scripts/checkpoint.gd', 'r') as f:
    text = f.read()

new_visuals = '''func _build_visuals() -> void:
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
	lbl.pixel_size = 0.015
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
	add_child(col)'''

import re
text = re.sub(r'func _build_visuals\(\) -> void:.*?add_child\(col\)', new_visuals, text, flags=re.DOTALL)

text = text.replace('if success and mesh and mesh.material is StandardMaterial3D:', 'if success:')
text = text.replace('var mat = mesh.material as StandardMaterial3D\n\t\t\tmat.emission = Color(0.2, 1.0, 0.4, 1.0)', '''var housing = get_node_or_null("Housing")
			if housing:
				var screen = housing.get_node_or_null("Screen")
				if screen and screen.material:
					(screen.material as StandardMaterial3D).emission = Color(0.2, 1.0, 0.4, 1.0)
			var light = get_node_or_null("PulseLight")
			if light:
				light.light_color = Color(0.2, 1.0, 0.4, 1.0)''')

with open('scripts/checkpoint.gd', 'w') as f:
    f.write(text)
