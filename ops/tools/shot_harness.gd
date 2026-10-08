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
			"fps":
				await _measure_fps(float(parts[1]))
			"scale":
				root.get_viewport().scaling_3d_scale = float(parts[1])
				await process_frame
			"msaa":
				root.get_viewport().msaa_3d = int(parts[1]) as Viewport.MSAA
				await process_frame
			"ssao", "glow", "fog", "ssil", "sdfgi":
				var env := _env()
				if env:
					env.set(parts[0] + "_enabled", parts[1] == "1")
				await process_frame
			"shadows":
				for n in _all(current_scene):
					if n is Light3D:
						(n as Light3D).shadow_enabled = parts[1] == "1"
				await process_frame
			"omni":
				for n in _all(current_scene):
					if n is OmniLight3D and n.name != "FillLight":
						(n as OmniLight3D).visible = parts[1] == "1"
				await process_frame
			_:
				push_warning("[HARNESS] unknown step: %s" % s)

func _env() -> Environment:
	for n in _all(current_scene):
		if n is WorldEnvironment and (n as WorldEnvironment).environment:
			return (n as WorldEnvironment).environment
	return null

func _all(node: Node) -> Array:
	var out: Array = []
	if node == null:
		return out
	out.append(node)
	for c in node.get_children():
		out.append_array(_all(c))
	return out

## Samples frame times for `seconds` with vsync off and prints avg / 1%-low fps plus the render setup.
func _measure_fps(seconds: float) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport().get_viewport_rid(), true)
	for i in 20:
		await process_frame
	var times: Array[float] = []
	var t0 := Time.get_ticks_usec()
	var last := t0
	while (Time.get_ticks_usec() - t0) / 1_000_000.0 < seconds:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
	times.sort()
	var sum := 0.0
	for t in times:
		sum += t
	var avg_ms: float = sum / max(1, times.size())
	var p99_ms: float = times[int(floor(times.size() * 0.99))] if times.size() > 1 else avg_ms
	var worst_ms: float = times[times.size() - 1] if times.size() > 0 else 0.0
	var vp := root.get_viewport()
	var size := vp.get_visible_rect().size * vp.scaling_3d_scale
	print("[FPS] frames=%d avg=%.1f fps (%.2f ms)  1%%low=%.1f fps (%.2f ms)  worst=%.1f ms  3d=%dx%d scale=%.2f msaa=%d method=%s" % [
		times.size(), 1000.0 / avg_ms, avg_ms, 1000.0 / p99_ms, p99_ms, worst_ms,
		int(size.x), int(size.y), vp.scaling_3d_scale, vp.msaa_3d,
		str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))])
	print("[FPS] process=%.2f ms physics=%.2f ms render_cpu=%.2f ms render_gpu=%.2f ms objects=%d primitives=%d draw_calls=%d" % [
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		RenderingServer.viewport_get_measured_render_time_cpu(vp.get_viewport_rid()),
		RenderingServer.viewport_get_measured_render_time_gpu(vp.get_viewport_rid()),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	var env := _env()
	if env:
		print("[FPS] env ssao=%s glow=%s fog=%s" % [env.ssao_enabled, env.glow_enabled, env.fog_enabled])
	var shadow_lights := 0
	var lights := 0
	for n in _all(current_scene):
		if n is Light3D and (n as Light3D).visible:
			lights += 1
			if (n as Light3D).shadow_enabled:
				shadow_lights += 1
	print("[FPS] lights=%d shadow_casting=%d" % [lights, shadow_lights])

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
