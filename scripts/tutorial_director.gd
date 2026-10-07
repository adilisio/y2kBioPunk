extends Node

var hud: Node
var player: Node

var state = 0
var timer = 0.0
var step_timer = 0.0
var kills = 0

var has_moved = false
var has_swung = false
var has_evaded = false
var has_taped = false
var has_skated = false
var has_grinded = false

func _ready():
	hud = get_tree().get_first_node_in_group("hud")
	player = get_node_or_null("../../Player")
	if not player and get_tree().current_scene:
		player = get_tree().current_scene.find_child("Player", true, false)
	if not player and hud:
		player = hud.get("player")
	
	if not player:
		set_process(false)
		return

	if player.has_signal("attack_executed"):
		player.connect("attack_executed", Callable(self, "_on_attack"))
	if player.has_signal("evade_started"):
		player.connect("evade_started", Callable(self, "_on_evade"))
	if player.has_signal("tape_switched"):
		player.connect("tape_switched", Callable(self, "_on_tape"))
	if player.has_signal("skates_toggled"):
		player.connect("skates_toggled", Callable(self, "_on_skates"))
	if player.has_signal("grind_started"):
		player.connect("grind_started", Callable(self, "_on_grind"))
	if player.has_signal("xp_changed"):
		player.connect("xp_changed", Callable(self, "_on_xp"))

func _on_attack(dmg):
	has_swung = true
func _on_evade():
	has_evaded = true
func _on_tape(a,b):
	has_taped = true
func _on_skates(a):
	has_skated = true
func _on_grind():
	has_grinded = true
func _on_xp(cur, nxt, lvl):
	kills += 1

func get_distance_to_group(group_name: String) -> float:
	var nodes = get_tree().get_nodes_in_group(group_name)
	var min_dist = 999999.0
	var p_pos = player.global_position
	for n in nodes:
		if is_instance_valid(n) and n.is_inside_tree() and n is Node3D:
			var d = p_pos.distance_to(n.global_position)
			if d < min_dist:
				min_dist = d
	return min_dist

func get_distance_to_turrets() -> float:
	var nodes = get_tree().get_nodes_in_group("enemies")
	var min_dist = 999999.0
	var p_pos = player.global_position
	for n in nodes:
		if is_instance_valid(n) and n.is_inside_tree() and n is Node3D:
			if "turret" in n.name.to_lower() or n.has_method("fire_mortar"):
				var d = p_pos.distance_to(n.global_position)
				if d < min_dist:
					min_dist = d
	return min_dist

func check_rail_dist(max_dist: float) -> bool:
	var nodes = get_tree().get_nodes_in_group("grindable")
	var p_pos = player.global_position
	for area in nodes:
		if is_instance_valid(area) and area.is_inside_tree() and area is Area3D:
			var d = p_pos.distance_to(area.global_position)
			if d <= max_dist:
				return true
	# Also check Layer 3/4 areas
	var path_nodes = get_tree().get_nodes_in_group("paths")
	if path_nodes.size() == 0:
		# Maybe search manually
		var root = get_tree().current_scene
		if root:
			var paths = root.find_children("*", "Path3D", true, false)
			for path in paths:
				if is_instance_valid(path) and path.is_inside_tree():
					var d = p_pos.distance_to(path.global_position)
					if d <= max_dist:
						return true
	return false

func _process(delta):
	if not player or not hud:
		return
		
	timer += delta
	step_timer += delta

	var raw_input = Vector2.ZERO
	if player.has_method("get_raw_input_direction"):
		raw_input = player.call("get_raw_input_direction")
	if raw_input.length_squared() > 0.01:
		has_moved = true

	match state:
		0: # wait 1s
			if timer >= 1.0:
				show_hint("MOVE: WASD   //   SWING: LMB")
				state = 1
		1: # wait for move and swing, or 8s
			if (has_moved and has_swung) or step_timer >= 8.0:
				dismiss_hint()
				state = 2
		2: # first enemy within 8m
			if get_distance_to_group("enemies") <= 8.0:
				show_hint("EVADE: SHIFT or V  (i-frames)")
				state = 3
		3: # wait for evade or 8s
			if has_evaded or step_timer >= 8.0:
				dismiss_hint()
				state = 4
		4: # HP < 60%
			var cur = player.get("current_health")
			var mx = player.get("max_health")
			if cur != null and mx != null and cur < mx * 0.6:
				show_hint("TAPE: T cycles mixtapes — VIT tapes heal-scale")
				state = 5
			elif get_distance_to_group("boss") <= 30.0:
				# Skip to end if near boss
				state = 11
		5: # wait for tape switch or 8s
			if has_taped or step_timer >= 8.0:
				dismiss_hint()
				state = 6
		6: # wait for 2 kills or 25s
			if kills >= 2 or timer >= 25.0:
				show_hint("SKATES: K  — 2x speed, rails become grindable")
				state = 7
		7: # wait for skates or 8s
			if has_skated or step_timer >= 8.0:
				dismiss_hint()
				state = 8
		8: # first time skating within 6m of a rail
			var is_skate = player.get("is_skating")
			if is_skate and check_rail_dist(6.0):
				show_hint("GRIND: skate ALONG the rail and JUMP onto it; JUMP again to slam off")
				state = 9
		9: # wait for grind or 8s
			if has_grinded or step_timer >= 8.0:
				dismiss_hint()
				state = 10
		10: # turret within 14m
			if get_distance_to_turrets() <= 14.0:
				show_hint("TURRET: watch the screen — green→yellow→RED means a mortar is coming")
				state = 11
		11: # wait 8s or boss trigger
			if step_timer >= 8.0 or get_distance_to_group("boss") <= 30.0:
				dismiss_hint()
				state = 12
				finish_tutorial()

func show_hint(msg: String):
	step_timer = 0.0
	if hud:
		hud.set("current_tutorial_hint", msg)
		if hud.has_method("_update_control_tip"):
			hud.call("_update_control_tip")

func dismiss_hint():
	if hud:
		hud.set("current_tutorial_hint", "")
		if hud.has_method("_update_control_tip"):
			hud.call("_update_control_tip")

func finish_tutorial():
	if hud:
		hud.set("tutorial_finished", true)
		if hud.has_method("_update_control_tip"):
			hud.call("_update_control_tip")
	set_process(false)
