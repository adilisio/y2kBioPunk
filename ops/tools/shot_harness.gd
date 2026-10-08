extends SceneTree
## In-engine screenshot + scripted-input harness (Director tooling, not shipped).
## Usage (windowed, NOT headless):
##   Godot_v4.3-stable_win64.exe --path . --windowed --resolution 1280x720 -s ops/tools/shot_harness.gd -- scene=res://scenes/FloodedMall_Greybox.tscn out=ops/runs/shots/greybox steps="wait:2,shot,hold:move_forward:1.5,shot,press:toggle_skates,hold:move_forward:2,shot,press:attack,wait:0.3,shot"
## Steps: wait:<s> | shot | press:<action> | hold:<action>:<s> | release:<action> | key:<keyname> | quit
##        tp:<x>:<y>:<z> | heal | invuln:<0|1> | dmg:<name>:<amount> | fps:<s> | profile:<s> | firstuse | plus A/B toggles (see match below)
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
			"tp":
				# tp:<x>:<y>:<z> teleports the player (Director shot tooling)
				var pl: Node = get_first_node_in_group("player")
				if pl is Node3D:
					(pl as Node3D).global_position = Vector3(float(parts[1]), float(parts[2]), float(parts[3]))
					if pl is CharacterBody3D:
						(pl as CharacterBody3D).velocity = Vector3.ZERO
				await process_frame
				await process_frame
			"heal":
				var pl: Node = get_first_node_in_group("player")
				if pl and pl.has_method("set_current_health") and pl.has_method("get_max_health"):
					pl.call("set_current_health", pl.call("get_max_health"))
				await process_frame
			"invuln":
				var pl: Node = get_first_node_in_group("player")
				if pl and pl.has_method("set_is_invincible"):
					pl.call("set_is_invincible", parts[1] == "1")
				await process_frame
			"dmg":
				# dmg:<name-substring>:<amount> damages matching enemies/boss (e.g. dmg:queen:99999 for the victory card)
				var hit := 0
				for n in get_nodes_in_group("enemies") + get_nodes_in_group("boss"):
					if is_instance_valid(n) and n.has_method("take_damage") and (String(n.name).containsn(parts[1]) or (n.get_script() and String(n.get_script().resource_path).containsn(parts[1]))):
						n.call("take_damage", int(parts[2]), Vector3.ZERO)
						hit += 1
				print("[HARNESS] dmg:%s:%s hit %d" % [parts[1], parts[2], hit])
				await process_frame
			"shadowatlas":
				RenderingServer.directional_shadow_atlas_set_size(int(parts[1]), true)
				await process_frame
			"shadowdist", "shadowblur", "shadowsplits":
				for n in _all(current_scene):
					if n is DirectionalLight3D:
						var l := n as DirectionalLight3D
						if parts[0] == "shadowdist":
							l.directional_shadow_max_distance = float(parts[1])
						elif parts[0] == "shadowblur":
							l.shadow_blur = float(parts[1])
						else:
							l.directional_shadow_mode = int(parts[1]) as DirectionalLight3D.ShadowMode
				await process_frame
			"fps":
				await _measure_fps(float(parts[1]))
			"cap":
				Engine.max_fps = int(parts[1])
				await process_frame
			"off":
				# off:<substring> frees every node whose name or script path contains the substring (subtraction A/B)
				var removed := 0
				for n in _all(current_scene):
					if not is_instance_valid(n) or n == current_scene:
						continue
					var sp := String(n.get_script().resource_path) if n.get_script() else ""
					if String(n.name).containsn(parts[1]) or sp.containsn(parts[1]):
						n.queue_free()
						removed += 1
				print("[HARNESS] off:%s removed %d nodes" % [parts[1], removed])
				await process_frame
				await process_frame
			"vsync":
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if parts[1] == "1" else DisplayServer.VSYNC_DISABLED)
				await process_frame
			"enemies":
				if parts[1] == "0":
					for n in get_nodes_in_group("enemies"):
						n.queue_free()
				await process_frame
			"profile":
				await _profile_physics(float(parts[1]))
			"bench":
				await _bench_cue_path()
			"firstuse":
				await _first_use_effects()
			"allareas":
				var count := 0
				for a in _all(current_scene):
					if a is Area3D:
						(a as Area3D).monitoring = parts[1] == "1"
						count += 1
				print("[HARNESS] allareas:%s touched %d areas" % [parts[1], count])
				await process_frame
			"enemyareas":
				var count := 0
				for e in get_nodes_in_group("enemies"):
					for a in _all(e):
						if a is Area3D:
							(a as Area3D).monitoring = parts[1] == "1"
							(a as Area3D).monitorable = parts[1] == "1"
							count += 1
				print("[HARNESS] enemyareas:%s touched %d areas" % [parts[1], count])
				await process_frame
			"bodies":
				# bodies:<parent-name-substring>:<0|1> toggles StaticBody3D collision under matching parents
				var count := 0
				for n in _all(current_scene):
					if n is StaticBody3D and n.get_parent() and String(n.get_parent().name).containsn(parts[1]):
						(n as StaticBody3D).collision_layer = 1 if parts[2] == "1" else 0
						count += 1
				print("[HARNESS] bodies:%s:%s touched %d bodies" % [parts[1], parts[2], count])
				await process_frame
			"kill":
				var removed := 0
				for n in get_nodes_in_group("enemies"):
					if String(n.name).containsn(parts[1]) or (n.get_script() and String(n.get_script().resource_path).containsn(parts[1])):
						n.queue_free()
						removed += 1
				print("[HARNESS] kill:%s removed %d" % [parts[1], removed])
				await process_frame
			"railcol", "csgcol":
				for n in _all(current_scene):
					if n is CSGShape3D and (parts[0] == "csgcol" or n is CSGPolygon3D):
						(n as CSGShape3D).use_collision = parts[1] == "1"
				await process_frame
				await process_frame
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

## Attributes physics-tick time to script groups by ordering `_physics_process` with process_physics_priority:
## marker nodes stamp the clock between groups. Enemies are re-prioritised cicada=10, turret=20, roach=30,
## boss=40; everything left at 0 (player, camera, mortars, pickups) lands in the first bucket. The gap between
## the summed script time and Performance.TIME_PHYSICS_PROCESS is the physics server step itself.
func _profile_physics(seconds: float) -> void:
	var groups := {"cicada": 10, "turret": 20, "roach": 30, "queen": 40}
	for n in get_nodes_in_group("enemies"):
		var path := String(n.get_script().resource_path) if n.get_script() else ""
		for g in groups:
			if path.containsn(g) or String(n.name).containsn(g):
				n.process_physics_priority = groups[g]
	var marker_src := GDScript.new()
	marker_src.source_code = "extends Node\nvar stamps: Array = []\nfunc _physics_process(_d):\n\tstamps.append(Time.get_ticks_usec())\n"
	marker_src.reload()
	var order := [["start", -100], ["after_default", 5], ["after_cicada", 15], ["after_turret", 25], ["after_roach", 35], ["after_queen", 45]]
	var markers: Array = []
	for o in order:
		var m := Node.new()
		m.name = "ProfMarker_%s" % o[0]
		m.set_script(marker_src)
		m.process_physics_priority = o[1]
		root.add_child(m)
		markers.append(m)
	var tick_total := 0.0
	var tick_max := 0.0
	var ticks := 0
	# Phase split: physics_frame signal (start of SceneTree physics) -> first marker = pre-callback work;
	# last marker -> next process_frame = server step + post-callback flush (+ loop overhead).
	var pf_stamps: Array = []
	var idle_stamps: Array = []
	var draw_stamps: Array = []
	var on_pf := func(): pf_stamps.append(Time.get_ticks_usec())
	var on_idle := func(): idle_stamps.append(Time.get_ticks_usec())
	var on_draw := func(): draw_stamps.append(Time.get_ticks_usec())
	physics_frame.connect(on_pf)
	process_frame.connect(on_idle)
	RenderingServer.frame_post_draw.connect(on_draw)
	var t0 := Time.get_ticks_usec()
	while (Time.get_ticks_usec() - t0) / 1_000_000.0 < seconds:
		await physics_frame
		var ph: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		tick_total += ph
		tick_max = max(tick_max, ph)
		ticks += 1
	physics_frame.disconnect(on_pf)
	process_frame.disconnect(on_idle)
	RenderingServer.frame_post_draw.disconnect(on_draw)
	# Frame anatomy: idle(process_frame) -> post_draw = render+present; post_draw -> next physics_frame = limiter sleep + pre-physics engine work
	var a_sum := 0.0
	var b_sum := 0.0
	var a_max := 0.0
	var n_ab := 0
	for d in draw_stamps:
		var prev_idle: int = -1
		for s in idle_stamps:
			if s <= d and s > prev_idle:
				prev_idle = s
		var next_pf: int = -1
		for s in pf_stamps:
			if s > d and (next_pf < 0 or s < next_pf):
				next_pf = s
		if prev_idle < 0 or next_pf < 0:
			continue
		b_sum += (d - prev_idle) / 1000.0
		var a: float = (next_pf - d) / 1000.0
		a_sum += a
		a_max = max(a_max, a)
		n_ab += 1
	print("[PROF] frame anatomy over %d frames: idle->post_draw (render+present) avg=%.2f ms | post_draw->next physics_frame (sleep+pre-physics) avg=%.2f ms max=%.2f ms" % [n_ab, b_sum / max(1, n_ab), a_sum / max(1, n_ab), a_max])
	var pre_sum := 0.0
	var post_sum := 0.0
	var post_max := 0.0
	var split_n := 0
	for i in min(markers[0].stamps.size(), markers[5].stamps.size()):
		# pre-callback: gap from the latest physics_frame signal at or before this tick's first marker
		var m0: int = markers[0].stamps[i]
		var best: int = -1
		for s in pf_stamps:
			if s <= m0 and s > best:
				best = s
		if best < 0 or m0 - best > 50000:
			continue
		pre_sum += (m0 - best) / 1000.0
		# next idle frame after this tick's last marker
		var last_stamp: int = markers[5].stamps[i]
		for s in idle_stamps:
			if s > last_stamp:
				var d: float = (s - last_stamp) / 1000.0
				post_sum += d
				post_max = max(post_max, d)
				break
		split_n += 1
	print("[PROF] split over %d ticks: pre-callback avg=%.2f ms | last-marker->next idle frame avg=%.2f ms max=%.2f ms" % [split_n, pre_sum / max(1, split_n), post_sum / max(1, split_n), post_max])
	var n_ticks: int = markers[0].stamps.size()
	var labels := ["default(player,camera,mortars)", "cicadas", "turrets", "roaches", "queen"]
	var sums := [0.0, 0.0, 0.0, 0.0, 0.0]
	var maxes := [0.0, 0.0, 0.0, 0.0, 0.0]
	for i in n_ticks:
		for b in 5:
			if markers[b + 1].stamps.size() > i and markers[b].stamps.size() > i:
				var d: float = (markers[b + 1].stamps[i] - markers[b].stamps[i]) / 1000.0
				sums[b] += d
				maxes[b] = max(maxes[b], d)
	var script_sum := 0.0
	for b in 5:
		script_sum += sums[b]
	print("[PROF] ticks=%d physics tick avg=%.2f ms max=%.2f ms | scripts avg=%.2f ms | server+rest avg=%.2f ms | tps=%d max_fps=%d vsync=%d steps/frame=%d" % [
		n_ticks, tick_total / max(1, ticks), tick_max, script_sum / max(1, n_ticks), tick_total / max(1, ticks) - script_sum / max(1, n_ticks),
		Engine.physics_ticks_per_second, Engine.max_fps, DisplayServer.window_get_vsync_mode(), Engine.max_physics_steps_per_frame])
	for b in 5:
		print("[PROF]   %-32s avg=%.2f ms max=%.2f ms" % [labels[b], sums[b] / max(1, n_ticks), maxes[b]])
	for m in markers:
		m.queue_free()

## Times the individual operations of an enemy attack cue in the live scene (real renderer + audio).
func _bench_cue_path() -> void:
	var cicada: Node = null
	for n in get_nodes_in_group("enemies"):
		if String(n.name).containsn("cicada"):
			cicada = n
			break
	if cicada == null:
		print("[BENCH] no cicada")
		return
	var FX = load("res://scripts/turret_mortar.gd")
	var model: Node = cicada.get("visual_mesh")
	var player: Node = get_first_node_in_group("player")
	var results := {}
	var timed := func(label: String, fn: Callable):
		var t0 := Time.get_ticks_usec()
		fn.call()
		results[label] = (Time.get_ticks_usec() - t0) / 1000.0
	for rep in 3:
		await process_frame
		timed.call("tint_material+tint (new mat)", func():
			var m = EnemyModel.tint_material(Color(1.0, 0.12, 0.12), 0.55, 0.45)
			EnemyModel.tint(model, m))
		await process_frame
		timed.call("untint", func(): EnemyModel.untint(model))
		await process_frame
		var mat = EnemyModel.tint_material(Color(1.0, 0.12, 0.12), 0.55, 0.45)
		timed.call("tint (reused mat)", func(): EnemyModel.tint(model, mat))
		await process_frame
		EnemyModel.untint(model)
		await process_frame
		timed.call("sfx stream (cached) + play", func():
			var sfx: AudioStreamPlayer3D = cicada.get("sfx")
			sfx.stream = FX.sound(0.25, 900.0, 0.2)
			sfx.play())
		await process_frame
		timed.call("AudioStreamPlayer3D new+add+play", func():
			var v := AudioStreamPlayer3D.new()
			cicada.add_child(v)
			v.stream = FX.sound(0.25, 900.0, 0.2)
			v.play()
			v.queue_free())
		await process_frame
		timed.call("print x3", func():
			print("[BENCH] print cost probe 1")
			print("[BENCH] print cost probe 2")
			print("[BENCH] print cost probe 3"))
		await process_frame
		timed.call("2 tweens on model scale", func():
			var t := cicada.create_tween()
			t.tween_property(model, "scale", Vector3(1.4, 0.8, 1.4), 0.25)
			t.tween_property(model, "scale", Vector3.ONE, 0.25)
			var p := cicada.create_tween()
			p.tween_property(model, "position", model.position, 0.1))
		await process_frame
		if player and player.has_method("take_damage"):
			timed.call("player.take_damage(0)", func(): player.call("take_damage", 0, Vector3.ZERO))
		await process_frame
		timed.call("FX.burst (cached kit)", func(): FX.burst(cicada, Color.RED, 8, 0.25, 90))
		await process_frame
		var line := "[BENCH] rep %d:" % rep
		for k in results:
			line += " | %s=%.2f ms" % [k, results[k]]
		print(line)

func _first_use_effects() -> void:
	# For a cold attribution run, remove EffectWarmup from the scene before launch.
	# CPU creation is timed separately from submission: shader work is deferred until
	# a visible mesh draws. Full-frame intervals include the rest of the mall workload.
	if DisplayServer.get_name() == "headless":
		print("[FIRSTUSE] GPU diagnostic requires the off-screen windowed renderer")
		return
	var automatic_warmup := current_scene.get_node_or_null("EffectWarmup")
	if automatic_warmup:
		await automatic_warmup.tree_exited
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var warmup = load("res://scripts/effect_warmup.gd").new()
	warmup.auto_start = false
	current_scene.add_child(warmup)
	warmup.prepare(get_first_node_in_group("player") as Node3D)
	var jobs: Array = warmup.make_jobs()
	var lines: Array[String] = []
	# Use a unique shader so this visibility check is independent of persistent
	# driver caches. This artificial probe is not attribution to a gameplay effect.
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded; void fragment() { ALBEDO = vec3(%.9f); }" % (0.1 + float(Time.get_ticks_usec() % 1000000) / 2000000.0)
	var material := ShaderMaterial.new()
	material.shader = shader
	var probe: MeshInstance3D = warmup._mesh(material)
	probe.visible = false
	var previous_mode := current_scene.process_mode
	current_scene.process_mode = Node.PROCESS_MODE_DISABLED
	for state in ["hidden", "first drawn", "drawn again"]:
		await process_frame
		probe.visible = state != "hidden"
		var frame_max := 0.0
		for frame in 3:
			var start := Time.get_ticks_usec()
			await RenderingServer.frame_post_draw
			frame_max = maxf(frame_max, (Time.get_ticks_usec() - start) / 1000.0)
			await process_frame
		lines.append("[FIRSTUSE] unique shader %s draw_wait_max=%.3f ms draw_calls=%d" % [state, frame_max, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	current_scene.process_mode = previous_mode
	probe.queue_free()
	for job in jobs:
		for rep in 2:
			await process_frame
			var t0 := Time.get_ticks_usec()
			(job.run as Callable).call()
			var cpu_ms := (Time.get_ticks_usec() - t0) / 1000.0
			var frame_max := 0.0
			for frame in 3:
				var start := Time.get_ticks_usec()
				await RenderingServer.frame_post_draw
				frame_max = maxf(frame_max, (Time.get_ticks_usec() - start) / 1000.0)
				await process_frame
			lines.append("[FIRSTUSE] %s rep=%d cpu=%.3f ms draw_wait_max=%.3f ms" % [job.label, rep, cpu_ms, frame_max])
	# Buffer output so the ~3 ms stdout cost cannot contaminate the next probe.
	for line in lines:
		print(line)
	warmup.queue_free()
	await process_frame

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
	if Engine.max_fps == 0:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED) # uncapped: measure headroom
	RenderingServer.viewport_set_measure_render_time(root.get_viewport().get_viewport_rid(), true)
	for i in 20:
		await process_frame
	var times: Array[float] = []
	var phys_max := 0.0
	var phys_sum := 0.0
	var proc_max := 0.0
	var t0 := Time.get_ticks_usec()
	var last := t0
	var slow_threshold_ms := 1000.0 / 60.0 * 1.3 # a frame that missed a 60 Hz vblank
	while (Time.get_ticks_usec() - t0) / 1_000_000.0 < seconds:
		await process_frame
		var now := Time.get_ticks_usec()
		var ft: float = (now - last) / 1000.0
		times.append(ft)
		last = now
		if ft > slow_threshold_ms:
			# Printed in stream order, so the gameplay lines just above it are the events of that frame.
			print("[FPS] SLOW FRAME t=%.2fs %.1f ms (objects=%d draw_calls=%d)" % [(now - t0) / 1_000_000.0, ft,
				Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
		var ph: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		phys_sum += ph
		phys_max = max(phys_max, ph)
		proc_max = max(proc_max, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	var unsorted_avg := 0.0
	for t in times:
		unsorted_avg += t
	unsorted_avg /= max(1, times.size())
	var spikes := 0
	for t in times:
		if t > unsorted_avg * 2.0:
			spikes += 1
	print("[FPS] physics avg=%.2f ms max=%.2f ms | process max=%.2f ms | frames over 2x avg: %d of %d | active_objects=%d collision_pairs=%d islands=%d" % [
		phys_sum / max(1, times.size()), phys_max, proc_max, spikes, times.size(),
		Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
		Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS),
		Performance.get_monitor(Performance.PHYSICS_3D_ISLAND_COUNT)])
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
