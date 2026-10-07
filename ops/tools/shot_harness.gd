extends SceneTree
## In-engine screenshot + scripted-input harness (Director tooling, not shipped).
## Usage (windowed, NOT headless):
##   Godot_v4.3-stable_win64.exe --path . --windowed --resolution 1280x720 -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn out=ops/runs/shots/greybox steps="wait:2,shot,hold:move_forward:1.5,shot,press:toggle_skates,hold:move_forward:2,shot,press:attack,wait:0.3,shot"
## Steps: wait:<s> | shot | press:<action> | hold:<action>:<s> | release:<action> | key:<keyname> | quit
## Each 'shot' writes <out>.<n>.png. The harness quits at the end of the step list.

var _out := "ops/runs/shots/shot"
var _steps: Array = []
var _shot_index := 0
var _scene_path := ""

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		var kv := a.split("=", true, 1)
		if kv.size() != 2:
			continue
		match kv[0]:
			"scene": _scene_path = kv[1]
			"out": _out = kv[1]
			"steps": _steps = kv[1].split(",", false)
	if _steps.is_empty():
		_steps = ["wait:3", "shot"]
	call_deferred("_start")

func _start() -> void:
	if _scene_path != "":
		var err := change_scene_to_file(_scene_path)
		if err != OK:
			push_error("[HARNESS] change_scene_to_file failed: %d" % err)
			quit(1)
			return
	# Let the scene load and settle a few frames before running steps
	for i in 10:
		await process_frame
	await _run_steps()
	print("[HARNESS] done; %d shots" % _shot_index)
	await process_frame
	quit(0)

func _run_steps() -> void:
	for raw in _steps:
		var s: String = String(raw).strip_edges()
		var parts := s.split(":")
		match parts[0]:
			"wait":
				await create_timer(float(parts[1])).timeout
			"shot":
				await _shot()
			"press":
				Input.action_press(parts[1])
				await process_frame
				await process_frame
				Input.action_release(parts[1])
				await process_frame
			"hold":
				Input.action_press(parts[1])
				await create_timer(float(parts[2])).timeout
				Input.action_release(parts[1])
				await process_frame
			"release":
				Input.action_release(parts[1])
				await process_frame
			"key":
				var ev := InputEventKey.new()
				ev.keycode = OS.find_keycode_from_string(parts[1])
				ev.pressed = true
				Input.parse_input_event(ev)
				await process_frame
				ev = ev.duplicate()
				ev.pressed = false
				Input.parse_input_event(ev)
				await process_frame
			"quit":
				return
			_:
				push_warning("[HARNESS] unknown step: %s" % s)

func _shot() -> void:
	await process_frame
	await process_frame
	var img := root.get_viewport().get_texture().get_image()
	var path := "res://%s.%d.png" % [_out, _shot_index]
	var dir := path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var err := img.save_png(path)
	print("[HARNESS] shot %d -> %s (err=%d)" % [_shot_index, path, err])
	_shot_index += 1
