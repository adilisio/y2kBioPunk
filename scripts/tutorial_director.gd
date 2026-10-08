extends Node

## TutorialDirector
## Pager-driven, event-gated onboarding. Added to the mall at runtime by
## mall_greybox_builder.gd::_ready. Each hint is shown once in the HUD ControlTip line
## (with a page_beep), dismissed by doing the thing or after HINT_SECS, and the HUD
## reverts to a compact permanent legend when the tutorial finishes.
##
## Hints are independent gates (not a linear chain): a hint whose gate opens is queued
## behind the active hint, and a hint whose action was already performed is skipped.

const HINT_SECS := 8.0
const FIRST_HINT_DELAY := 1.0
const SKATES_FALLBACK_SECS := 25.0
const HINT_ORDER := ["move", "evade", "tape", "skates", "secondary", "grind", "turret"]
const HINT_TEXT := {
	"move": "MOVE: WASD",
	"evade": "EVADE: SHIFT or V  (i-frames) // SWING: LMB",
	"tape": "TAPE: T — each tape shifts STR/AGI/VIT/VIBE (VIBE = crit chance)",
	"skates": "SKATES: K  — +38% speed, rails become grindable",
	"secondary": "SECONDARY: RMB or F fires; Q swaps flamethrower / disks",
	"grind": "GRIND: skate along the rail and press SPACE to hop on; SPACE again to slam off",
	"turret": "TURRET: its light ramps green→yellow→RED, then a mortar drops on the red marker",
}

var hud: Node
var player: Node

var elapsed: float = 0.0
var active_id: String = ""
var active_age: float = 0.0
var done: Dictionary = {}
var finished: bool = false
var kills: int = 0

var has_moved: bool = false
var has_swung: bool = false
var has_evaded: bool = false
var has_taped: bool = false
var has_skated: bool = false
var has_grinded: bool = false
var has_fired: bool = false

var _last_xp: int = -1
var _last_level: int = -1

func _ready() -> void:
	hud = get_tree().get_first_node_in_group("hud")
	player = get_node_or_null("../Player")
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if not player and hud:
		player = hud.get("player")
	if not hud or not player:
		set_process(false)
		return

	_connect_signal("attack_executed", "_on_attack")
	_connect_signal("evade_started", "_on_evade")
	_connect_signal("tape_switched", "_on_tape")
	_connect_signal("skates_toggled", "_on_skates")
	_connect_signal("grind_started", "_on_grind")
	_connect_signal("xp_changed", "_on_xp")
	_connect_signal("secondary_fired", "_on_secondary")
	_last_xp = int(player.get("current_xp")) if player.get("current_xp") != null else -1
	_last_level = int(player.get("level")) if player.get("level") != null else -1

func _connect_signal(sig: String, method: String) -> void:
	if player.has_signal(sig) and not player.is_connected(sig, Callable(self, method)):
		player.connect(sig, Callable(self, method))

# Signal handlers accept the full argument list of the matching player signal.
func _on_attack(_damage: float = 0.0) -> void:
	has_swung = true

func _on_evade(_direction: Vector3 = Vector3.ZERO, _speed: float = 0.0) -> void:
	has_evaded = true

func _on_tape(_tape_name: String = "", _buff_desc: String = "") -> void:
	has_taped = true

func _on_skates(_equipped: bool = true) -> void:
	has_skated = true

func _on_grind(_rail: Node = null, _speed: float = 0.0) -> void:
	has_grinded = true

func _on_secondary(_weapon: int, _position: Vector3, _direction: Vector3, _damage: float) -> void:
	has_fired = true

func _on_xp(cur_xp: int, _next_xp: int, lvl: int) -> void:
	# xp_changed also fires for non-kill reasons; only an XP/level increase counts as a kill.
	if _last_xp >= 0 and (lvl > _last_level or cur_xp > _last_xp):
		kills += 1
	_last_xp = cur_xp
	_last_level = lvl

func _nearest_enemy_dist(turrets_only: bool = false) -> float:
	var min_dist := INF
	var p_pos: Vector3 = player.global_position
	for n in get_tree().get_nodes_in_group("enemies"):
		if not (is_instance_valid(n) and n is Node3D and n.is_inside_tree()):
			continue
		if turrets_only and not ("turret" in String(n.name).to_lower()):
			continue
		min_dist = minf(min_dist, p_pos.distance_to(n.global_position))
	return min_dist

func _boss_near() -> bool:
	var p_pos: Vector3 = player.global_position
	for n in get_tree().get_nodes_in_group("boss"):
		if is_instance_valid(n) and n is Node3D and n.is_inside_tree() and p_pos.distance_to(n.global_position) <= 30.0:
			return true
	return false

func _near_rail(max_dist: float) -> bool:
	var p_pos: Vector3 = player.global_position
	for area in get_tree().get_nodes_in_group("grindable"):
		if not is_instance_valid(area) or not area.is_inside_tree():
			continue
		var path := area.get_parent() as Path3D
		if path == null or path.curve == null or path.curve.point_count < 2:
			continue
		var closest_local: Vector3 = path.curve.get_closest_point(path.to_local(p_pos))
		if p_pos.distance_to(path.to_global(closest_local)) <= max_dist:
			return true
	return false

func _track_movement() -> void:
	if has_moved:
		return
	var move_vec := Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
	if move_vec.length_squared() > 0.01:
		has_moved = true

func _is_gate_open(id: String) -> bool:
	match id:
		"move":
			return elapsed >= FIRST_HINT_DELAY
		"evade":
			return _nearest_enemy_dist() <= 6.0
		"tape":
			return kills >= 2 or elapsed >= SKATES_FALLBACK_SECS
		"skates":
			return kills >= 2 or elapsed >= SKATES_FALLBACK_SECS
		"secondary":
			return done.has("skates")
		"grind":
			return bool(player.get("is_skating")) and _near_rail(6.0)
		"turret":
			return _nearest_enemy_dist(true) <= 14.0
	return false

func _is_dismissed(id: String) -> bool:
	match id:
		"move":
			return has_moved
		"evade":
			return has_evaded
		"tape":
			return has_taped
		"skates":
			return has_skated
		"secondary":
			return has_fired
		"grind":
			return has_grinded
	return false # turret: timed only

func _process(delta: float) -> void:
	if finished or not player or not hud:
		return
	elapsed += delta
	_track_movement()

	# A nearby threat interrupts the pending hint; that hint remains eligible afterward.
	if elapsed >= FIRST_HINT_DELAY and not _boss_near() and active_id != "evade" and not done.has("evade") and not has_evaded and _is_gate_open("evade"):
		_show("evade")
		return

	if active_id != "":
		active_age += delta
		if _is_dismissed(active_id) or active_age >= HINT_SECS:
			done[active_id] = true
			active_id = ""
			_set_hint("")
		elif _boss_near():
			done[active_id] = true
			active_id = ""
			_finish()
			return
		else:
			return

	if _boss_near() or done.size() >= HINT_ORDER.size():
		_finish()
		return

	# Hints begin at t+1 s; urgent EVADE can take priority over MOVE.
	if elapsed < FIRST_HINT_DELAY:
		return

	for id in HINT_ORDER:
		if done.has(id) or not _is_gate_open(id):
			continue
		if _is_dismissed(id):
			done[id] = true # already did it; do not nag
			continue
		_show(id)
		return

func _show(id: String) -> void:
	active_id = id
	active_age = 0.0
	_set_hint(HINT_TEXT[id])
	if player.has_method("play_sfx"):
		player.call("play_sfx", "page_beep")

func _set_hint(msg: String) -> void:
	hud.set("current_tutorial_hint", msg)
	if hud.has_method("_update_control_tip"):
		hud.call("_update_control_tip")

func _finish() -> void:
	finished = true
	active_id = ""
	hud.set("current_tutorial_hint", "")
	hud.set("tutorial_finished", true)
	if hud.has_method("_update_control_tip"):
		hud.call("_update_control_tip")
	set_process(false)
