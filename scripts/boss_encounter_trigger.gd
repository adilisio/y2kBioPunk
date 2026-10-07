extends Area3D
class_name BossEncounterTrigger

@export var boss_scene: PackedScene = preload("res://scenes/dial_up_queen.tscn")
@export var spawn_position: Vector3 = Vector3(0.0, 1.5, -15.0)
@export var trigger_once: bool = true

var triggered: bool = false
var player_inside: bool = false

func _ready() -> void:
	monitoring = true
	# Mask covers World (1), Player (2), Entities (3/4)
	collision_mask = 1 | 2 | 4
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	# Check if player is already inside the area
	if get_overlapping_bodies().size() > 0:
		for body in get_overlapping_bodies():
			if _is_player(body):
				player_inside = true
				if get_remaining_enemies_count() == 0:
					_spawn_boss()
				break

func _is_player(body: Node) -> bool:
	if not is_instance_valid(body):
		return false
	if body.is_in_group("enemies") or body.is_in_group("boss"):
		return false
	if body.is_in_group("player") or body.name == "Player":
		return true
	if body.has_method("switch_tape") or body.has_method("get_effective_strength"):
		return true
	return false

func get_remaining_enemies_count() -> int:
	var tree: SceneTree = get_tree()
	if not tree:
		tree = Engine.get_main_loop() as SceneTree
	
	var count: int = 0
	var counted_nodes: Array[Node] = []

	# 1. Query scene tree enemies group
	if tree:
		var enemy_nodes = tree.get_nodes_in_group("enemies")
		for node in enemy_nodes:
			if not is_instance_valid(node) or node.is_queued_for_deletion():
				continue
			if node.is_in_group("boss") or node.name.contains("DialUpQueen") or (node.get_parent() and node.get_parent().is_in_group("boss")):
				continue
			if "current_health" in node and node.current_health <= 0:
				continue
			if "is_dead" in node and node.is_dead:
				continue
			if not counted_nodes.has(node):
				counted_nodes.append(node)
				count += 1

	# 2. Hierarchy fallback (check parent arena or Enemies container)
	if get_parent():
		var candidates: Array = []
		var p = get_parent()
		var enemies_node = p.get_node_or_null("Enemies")
		if enemies_node:
			candidates.append_array(enemies_node.get_children())
		candidates.append_array(p.get_children())
		for node in candidates:
			if not is_instance_valid(node) or node == self or node.is_queued_for_deletion():
				continue
			if counted_nodes.has(node):
				continue
			if node.is_in_group("boss") or node.name.contains("DialUpQueen") or (node.get_parent() and node.get_parent().is_in_group("boss")):
				continue
			if node.is_in_group("enemies") or node.name.begins_with("NeonDialUpCicada") or node.name.begins_with("SludgeRoach") or node.name.begins_with("CorruptedKioskTurret"):
				if "current_health" in node and node.current_health <= 0:
					continue
				if "is_dead" in node and node.is_dead:
					continue
				counted_nodes.append(node)
				count += 1

	return count

func _process(_delta: float) -> void:
	pass

func _on_body_entered(body: Node3D) -> void:
	if triggered:
		return
	if not _is_player(body):
		return

	player_inside = true
	var remaining: int = get_remaining_enemies_count()
	
	var tree: SceneTree = get_tree()
	if not tree:
		tree = Engine.get_main_loop() as SceneTree
	var hud = tree.get_first_node_in_group("hud") if tree else null
	if not hud and tree and tree.current_scene:
		hud = tree.current_scene.find_child("HUD", true, false)
		
	if remaining > 0:
		if hud and hud.has_method("show_message"):
			hud.call("show_message", "[color=#ff2222][b]QUARANTINE BREACH // DIAL-UP QUEEN AWAKENS[/b][/color]")

	_spawn_boss()

func _on_body_exited(body: Node3D) -> void:
	if not _is_player(body):
		return
	player_inside = false

func _spawn_boss() -> void:
	if triggered:
		return
	print("[BossTrigger] Awakening Dial-Up Queen...")

	var boss: Node3D = null
	if boss_scene and boss_scene.can_instantiate():
		boss = boss_scene.instantiate()
	else:
		var script = load("res://scripts/dial_up_queen.gd")
		if script:
			boss = CharacterBody3D.new()
			boss.set_script(script)

	if boss:
		boss.name = "DialUpQueen"
		var parent_node = get_parent()
		if parent_node:
			parent_node.add_child(boss)
			boss.global_position = spawn_position
		
		# Hook up to HUD
		var tree: SceneTree = get_tree()
		if not tree:
			tree = Engine.get_main_loop() as SceneTree
		var hud = tree.get_first_node_in_group("hud") if tree else null
		if not hud and tree and tree.current_scene:
			hud = tree.current_scene.find_child("HUD", true, false)
		if hud and hud.has_method("setup_boss_bar"):
			hud.call("setup_boss_bar", boss)
		
		boss.add_to_group("boss")
		triggered = true

	if trigger_once:
		monitoring = false
		set_process(false)
