extends Area3D
class_name FruitCandyPickup

## FruitCandyPickup (Gushers-Style Bio-Fruit Candy Pack)
## Small Y2K bio-snack pickup that heals 10 HP (capped at max_health).
## Features bobbing floating animation, glowing translucent Gusher candy gem,
## and a procedural juicy "YUM!" audio chime upon pickup.

@export var heal_amount: float = 10.0

var is_picked_up: bool = false
var base_y: float = 0.0
var bob_timer: float = 0.0

var visual_root: Node3D = null
var audio_player: AudioStreamPlayer3D = null

func _ready() -> void:
	# Layer 0 (intangible), Mask: 1 | 2 (detects World and Player)
	collision_layer = 0
	collision_mask = 1 | 2
	monitoring = true
	monitorable = false
	add_to_group("pickups")

	base_y = position.y
	bob_timer = randf() * TAU

	_build_visuals()
	_setup_audio()

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_picked_up:
		return

	bob_timer += delta
	if visual_root:
		visual_root.position.y = sin(bob_timer * 3.0) * 0.08
		visual_root.rotate_y(delta * 2.2)

func _setup_audio() -> void:
	if audio_player:
		return
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "YumAudioPlayer"
	audio_player.stream = _generate_yum_sfx()
	audio_player.unit_size = 8.0
	audio_player.max_distance = 25.0
	add_child(audio_player)

func _build_visuals() -> void:
	if visual_root:
		return

	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)

	# 1. Outer Faceted Gusher Candy Shell (Hexagonal diamond jewel)
	var shell = CSGCylinder3D.new()
	shell.name = "GusherShell"
	shell.radius = 0.22
	shell.height = 0.28
	shell.sides = 6
	shell.cone = true

	var shell_mat = StandardMaterial3D.new()
	shell_mat.albedo_color = Color(1.0, 0.15, 0.45, 0.85) # Vibrant ruby-magenta Gusher
	shell_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shell_mat.roughness = 0.15
	shell_mat.metallic = 0.1
	shell_mat.emission_enabled = true
	shell_mat.emission = Color(0.85, 0.1, 0.35, 1.0)
	shell.material = shell_mat
	visual_root.add_child(shell)

	# 2. Inner Liquid Core (Bright neon lime-yellow juice center)
	var core = CSGSphere3D.new()
	core.name = "JuiceCore"
	core.radius = 0.09
	core.radial_segments = 8
	core.rings = 6

	var core_mat = StandardMaterial3D.new()
	core_mat.albedo_color = Color(0.85, 1.0, 0.2, 0.95) # Electric lime juice
	core_mat.emission_enabled = true
	core_mat.emission = Color(0.85, 1.0, 0.2, 1.0)
	core.material = core_mat
	visual_root.add_child(core)

	# 3. Soft Point Light for inviting glow
	var light = OmniLight3D.new()
	light.name = "CandyGlow"
	light.light_color = Color(1.0, 0.25, 0.5)
	light.light_energy = 1.2
	light.omni_range = 2.5
	visual_root.add_child(light)

	# 4. Trigger Collision Shape
	var col = CollisionShape3D.new()
	col.name = "PickupShape"
	var sphere = SphereShape3D.new()
	sphere.radius = 0.75
	col.shape = sphere
	add_child(col)

func _is_player(body: Node) -> bool:
	if not is_instance_valid(body):
		return false
	if body.is_in_group("enemies") or body.is_in_group("boss"):
		return false
	if body.is_in_group("player") or body.name == "Player":
		return true
	if body.has_method("heal") or body.has_method("get_current_health"):
		return true
	return false

func _on_body_entered(body: Node3D) -> void:
	if is_picked_up:
		return
	if not _is_player(body):
		return

	var cur_hp = body.get_current_health() if body.has_method("get_current_health") else (body.current_health if "current_health" in body else 0.0)
	var max_hp = body.get_max_health() if body.has_method("get_max_health") else (body.max_health if "max_health" in body else 100.0)

	# Do not consume candy if already at full health
	if cur_hp >= max_hp:
		return

	is_picked_up = true
	monitoring = false
	set_deferred("monitoring", false)

	# 1. Restore 10 health, capped at max_health
	if body.has_method("heal"):
		body.heal(heal_amount)
	elif "current_health" in body and "max_health" in body:
		body.current_health = min(body.max_health, body.current_health + heal_amount)
		if body.has_signal("health_changed"):
			body.emit_signal("health_changed", body.current_health, body.max_health)

	cur_hp = body.get_current_health() if body.has_method("get_current_health") else (body.current_health if "current_health" in body else 0.0)
	print("[FruitCandy] *YUM!* Devoured fruit candy Gusher pack! Restored %d HP (HP: %d/%d)" % [int(heal_amount), int(cur_hp), int(max_hp)])

	# 2. Play YUM sound effect
	if body.has_method("play_sfx"):
		body.play_sfx("yum")
	elif audio_player:
		audio_player.play()

	# 3. Disappear: hide visual and free node
	if visual_root:
		visual_root.visible = false

	# Brief cleanup delay so local audio can finish cleanly
	var tree = get_tree()
	if not tree:
		tree = Engine.get_main_loop() as SceneTree
	if tree:
		tree.create_timer(0.4).timeout.connect(queue_free)
	else:
		queue_free()

static func _generate_yum_sfx() -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 22050
	wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	var duration: float = 0.35
	var num_samples: int = int(22050 * duration)
	var data = PackedByteArray()
	data.resize(num_samples)
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var val = 0.0
		# Part 1: Juicy Gusher squish pop (0.0 to 0.12s)
		if t < 0.35:
			var t_pop = t / 0.35
			var freq = lerp(440.0, 160.0, t_pop)
			var sine = sin(float(i) * TAU * freq / 22050.0)
			val += sine * (1.0 - t_pop) * 0.45
		# Part 2: Sweet rising "YUM!" harmony chime (0.10 to 0.35s)
		if t >= 0.15:
			var t_chime = (t - 0.15) / 0.85
			var freq = 880.0 if t < 0.55 else 1318.5
			var sine = sin(float(i) * TAU * freq / 22050.0)
			var harm = sin(float(i) * TAU * (freq * 2.0) / 22050.0) * 0.25
			var env = exp(-t_chime * 4.5)
			val += (sine + harm) * env * 0.55
		val = clampf(val, -1.0, 1.0)
		data[i] = int(clampf(val, -1, 1) * 127.0) & 0xFF
	wav.data = data
	return wav
