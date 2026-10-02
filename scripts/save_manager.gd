extends Node

## SaveManager (Persistent Checkpoint & Progression System)
## Serializes and deserializes player's Level, XP, Stats (STR, AGI, VIT, VIBE),
## and active Walkman tape to JSON via FileAccess.
## Preserves progression upon checkpoints and reloads state upon player death.

signal game_saved(checkpoint_name: String)
signal game_loaded(data: Dictionary)

const SAVE_PATH: String = "user://y2k_save_data.json"

var cached_save_data: Dictionary = {}

func _ready() -> void:
	if has_save_data():
		cached_save_data = load_player_data()

func has_save_data() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_player_data(player: Node, checkpoint_id: String = "BioStabilizer_01", spawn_pos: Vector3 = Vector3.ZERO) -> bool:
	if not player or not is_instance_valid(player):
		push_warning("[SaveManager] Cannot save: invalid player node reference.")
		return false

	var data: Dictionary = {
		"version": 1,
		"timestamp": Time.get_datetime_string_from_system(),
		"checkpoint_id": checkpoint_id,
		"player": {
			"level": int(player.call("get_level")) if player.has_method("get_level") else 1,
			"current_xp": int(player.call("get_current_xp")) if player.has_method("get_current_xp") else 0,
			"xp_to_level": int(player.call("get_xp_to_level")) if player.has_method("get_xp_to_level") else 50,
			"unspent_stat_points": int(player.call("get_unspent_stat_points")) if player.has_method("get_unspent_stat_points") else 0,
			"strength": int(player.call("get_strength")) if player.has_method("get_strength") else 10,
			"agility": int(player.call("get_agility")) if player.has_method("get_agility") else 10,
			"vitality": int(player.call("get_vitality")) if player.has_method("get_vitality") else 10,
			"vibe": int(player.call("get_vibe")) if player.has_method("get_vibe") else 10,
			"current_tape": str(player.get("current_tape")) if player.get("current_tape") != null else "Bubblegum"
		},
		"checkpoint_position": {
			"x": spawn_pos.x,
			"y": spawn_pos.y,
			"z": spawn_pos.z
		}
	}

	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		var err = FileAccess.get_open_error()
		push_error("[SaveManager] Failed to open save file for writing at '%s'. Error code: %d" % [SAVE_PATH, err])
		return false

	file.store_string(json_string)
	file.flush()
	file.close()

	cached_save_data = data
	print("[SaveManager] *** GAME SAVED *** Checkpoint '%s' | Level %d | XP %d/%d | Tape '%s'" % [
		checkpoint_id,
		data["player"]["level"],
		data["player"]["current_xp"],
		data["player"]["xp_to_level"],
		data["player"]["current_tape"]
	])
	emit_signal("game_saved", checkpoint_id)
	return true

func load_player_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		var err = FileAccess.get_open_error()
		push_error("[SaveManager] Failed to open save file for reading at '%s'. Error: %d" % [SAVE_PATH, err])
		return {}

	var content = file.get_as_text()
	file.close()

	if content.strip_edges().is_empty():
		return {}

	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		push_error("[SaveManager] JSON parse error: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return {}

	if not (json.data is Dictionary):
		push_error("[SaveManager] Save data root is not a Dictionary.")
		return {}

	cached_save_data = json.data
	return json.data

func apply_save_data_to_player(player: Node, save_data: Dictionary = {}) -> bool:
	if not player or not is_instance_valid(player):
		return false

	var data = save_data if not save_data.is_empty() else cached_save_data
	if data.is_empty():
		data = load_player_data()
	if data.is_empty() or not data.has("player"):
		return false

	var p_data: Dictionary = data["player"]

	if p_data.has("level") and player.has_method("set_level"):
		player.call("set_level", int(p_data["level"]))
	if p_data.has("current_xp") and player.has_method("set_current_xp"):
		player.call("set_current_xp", int(p_data["current_xp"]))
	if p_data.has("xp_to_level") and player.has_method("set_xp_to_level"):
		player.call("set_xp_to_level", int(p_data["xp_to_level"]))
	if p_data.has("unspent_stat_points") and player.has_method("set_unspent_stat_points"):
		player.call("set_unspent_stat_points", int(p_data["unspent_stat_points"]))

	if p_data.has("strength") and player.has_method("set_strength"):
		player.call("set_strength", int(p_data["strength"]))
	if p_data.has("agility") and player.has_method("set_agility"):
		player.call("set_agility", int(p_data["agility"]))
	if p_data.has("vitality") and player.has_method("set_vitality"):
		player.call("set_vitality", int(p_data["vitality"]))
	if p_data.has("vibe") and player.has_method("set_vibe"):
		player.call("set_vibe", int(p_data["vibe"]))

	if p_data.has("current_tape") and player.has_method("switch_tape"):
		player.call("switch_tape", str(p_data["current_tape"]))

	if data.has("checkpoint_position") and player is Node3D:
		var pos_dict = data["checkpoint_position"]
		var spawn_v = Vector3(float(pos_dict.get("x", 0.0)), float(pos_dict.get("y", 0.0)), float(pos_dict.get("z", 0.0)))
		if spawn_v.length_squared() > 0.1:
			player.global_position = spawn_v

	print("[SaveManager] Restored player save state! Level %d | Unspent Pts: %d | Tape: '%s'" % [
		player.call("get_level") if player.has_method("get_level") else 1,
		player.call("get_unspent_stat_points") if player.has_method("get_unspent_stat_points") else 0,
		player.get("current_tape") if player.get("current_tape") != null else "None"
	])
	emit_signal("game_loaded", data)
	return true
