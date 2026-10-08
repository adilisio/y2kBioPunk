extends SceneTree
const TestUtil = preload("res://tests/_test_util.gd")

## WP-6 onboarding + audio verification (headless).
## Part A: tutorial director hint sequence/gates driven through the real player signals.
## Part B: audio buses, every SFX cue, per-tape resume, loop cues stop on state exit.

const CUES := ["evade", "grind_start", "grind_loop", "flame_loop", "disk_fire", "disk_hit", "tape_clack", "clack", "levelup", "page_beep"]

var player: Node
var hud: Node
var tutorial: Node
var played: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _tip() -> String:
	return hud.control_tip.text if hud.control_tip else ""

func _on_sfx(cue_name: String) -> void:
	played.append(cue_name)

func _active_music() -> AudioStreamPlayer:
	var a := player.get_node("WalkmanAudio") as AudioStreamPlayer
	var b := player.get_node("WalkmanAudioB") as AudioStreamPlayer
	if b.playing and (not a.playing or b.volume_db > a.volume_db):
		return b
	return a

func _stub_enemy(enemy_name: String, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = enemy_name
	n.add_to_group("enemies")
	current_scene.add_child(n)
	n.global_position = pos
	return n

func _run() -> void:
	TestUtil.reset()
	var mall := load("res://scenes/FloodedMall_Greybox.tscn").instantiate() as Node3D
	root.add_child(mall)
	current_scene = mall
	TestUtil.track(mall)

	hud = mall.get_node_or_null("HUD")
	player = mall.get_node_or_null("Player")
	tutorial = mall.find_child("TutorialDirector", true, false)
	TestUtil.check(hud != null and player != null, "HUD and Player exist")
	TestUtil.check(tutorial != null, "TutorialDirector exists after mall load")
	if not (hud and player and tutorial):
		TestUtil.finish(self)
		return
	player.sfx_played.connect(_on_sfx)

	# Isolate the hint gates from live enemy AI: real enemies are removed, stubs drive the gates.
	for e in get_nodes_in_group("enemies"):
		e.free()
	player.global_position = Vector3(0, 0.1, 17)

	TestUtil.check("STAT PTS:" in hud.level_xp_label.text and "[b]1[/b]" in hud.level_xp_label.text, "Starting HUD shows the one unspent stat point")

	# --- Part A: hint sequence ---------------------------------------------------------------
	await create_timer(1.5).timeout
	TestUtil.check("MOVE" in _tip(), "First hint (MOVE) visible within 1.5 s; tip=%s" % _tip())
	TestUtil.check(played.has("page_beep"), "Hint plays the page_beep cue")

	Input.action_press("move_forward")
	await _frames(2)
	Input.action_release("move_forward")
	TestUtil.check("MOVE" not in _tip(), "MOVE hint dismissed by movement alone; tip=%s" % _tip())

	var stub := _stub_enemy("StubBug", player.global_position + Vector3(20, 0, 0))
	await _frames(2)
	TestUtil.check("EVADE" not in _tip(), "Evade hint must not show for an enemy 20 m away")
	stub.global_position = player.global_position + Vector3(5, 0, 0)
	await _frames(2)
	TestUtil.check("EVADE" in _tip(), "Evade hint shows with an enemy within 6 m; tip=%s" % _tip())
	player.emit_signal("evade_started", Vector3.FORWARD, 10.0)
	await _frames(2)
	TestUtil.check("EVADE" not in _tip(), "Evade hint dismissed by evade_started; tip=%s" % _tip())
	stub.free()

	player.current_health = float(player.max_health) * 0.5
	await _frames(2)
	TestUtil.check("TAPE" not in _tip(), "Low HP alone does not show the tape hint")
	var old_elapsed: float = tutorial.elapsed
	tutorial.elapsed = 25.0
	TestUtil.check(tutorial._is_gate_open("tape"), "Tape hint fallback opens at 25 seconds")
	tutorial.elapsed = old_elapsed
	player.gain_xp(1)
	await _frames(2)
	TestUtil.check("TAPE" not in _tip(), "Tape hint waits through the first kill")
	player.gain_xp(1)
	await _frames(2)
	TestUtil.check("each tape shifts STR/AGI/VIT/VIBE" in _tip(), "Truthful tape hint shows after the second kill; tip=%s" % _tip())

	# Urgent evade interrupts a pending hint, which returns after the action.
	tutorial.done.erase("evade")
	tutorial.has_evaded = false
	stub = _stub_enemy("StubBug", player.global_position + Vector3(5, 0, 0))
	await _frames(2)
	TestUtil.check("EVADE" in _tip() and "SWING: LMB" in _tip(), "Evade takes priority over pending tape hint and teaches swing")
	player.emit_signal("evade_started", Vector3.FORWARD, 10.0)
	await _frames(2)
	TestUtil.check("TAPE" in _tip(), "Interrupted tape hint resumes after evading")
	stub.free()

	# --- Part B (tape resume) shares the tape hint dismissal: a real switch_tape ---------------
	player.switch_tape("Bubblegum")
	await _frames(2)
	TestUtil.check("TAPE" not in _tip(), "Tape hint dismissed by tape switch; tip=%s" % _tip())

	TestUtil.check("SKATES" in _tip() and "+38% speed" in _tip(), "Skates hint follows tape with truthful speed; tip=%s" % _tip())
	player.set_is_skating(true)
	await _frames(2)
	TestUtil.check("SKATES" not in _tip(), "Skates hint dismissed by skates_toggled; tip=%s" % _tip())

	TestUtil.check("SECONDARY: RMB or F fires; Q swaps flamethrower / disks" in _tip(), "Secondary hint follows skates")
	player.fire_disk_launcher()
	await _frames(2)
	TestUtil.check("SECONDARY" not in _tip(), "Secondary hint dismissed by real firing signal")

	var rail: Path3D = null
	for area in get_nodes_in_group("grindable"):
		if area.get_parent() is Path3D:
			rail = area.get_parent()
			break
	TestUtil.check(rail != null, "Mall has grindable rails")
	if rail:
		var rail_pt := rail.to_global(rail.curve.get_point_position(0))
		player.global_position = rail_pt + Vector3(0, 6.0, 3.0)
		await _frames(2)
		TestUtil.check("GRIND" not in _tip(), "Grind hint must not show 6+ m from the rail")
		player.global_position = rail_pt + Vector3(0, 3.0, 0)
		await _frames(2)
		TestUtil.check("GRIND" in _tip() and "SPACE" in _tip(), "Grind hint names SPACE and shows when skating within 6 m of a rail; tip=%s" % _tip())
		player.emit_signal("grind_started", rail, 10.0)
		await _frames(2)
		TestUtil.check("GRIND" not in _tip(), "Grind hint dismissed by grind_started; tip=%s" % _tip())
		player.global_position = Vector3(0, 0.1, 17)

	_stub_enemy("CorruptedKioskTurret_Stub", player.global_position + Vector3(10, 0, 0))
	await _frames(2)
	TestUtil.check("its light ramps green→yellow→RED" in _tip() and "red marker" in _tip(), "Truthful turret hint shows with a turret within 14 m; tip=%s" % _tip())
	tutorial.active_age = tutorial.HINT_SECS
	await _frames(3)
	TestUtil.check(bool(hud.tutorial_finished), "Tutorial finishes after the last hint")
	var legend := _tip()
	TestUtil.check("WASD" in legend and "LMB" in legend and "SHIFT" in legend and "SPACE" in legend and "RMB/F" in legend and "Q" in legend and "TURRET" not in legend, "Legend replaces hints when finished; tip=%s" % legend)

	# --- Part B: audio -----------------------------------------------------------------------
	var music_idx := AudioServer.get_bus_index("Music")
	var sfx_idx := AudioServer.get_bus_index("SFX")
	TestUtil.check(music_idx >= 0 and sfx_idx >= 0, "Music and SFX buses exist")
	if music_idx >= 0 and sfx_idx >= 0:
		TestUtil.check(is_equal_approx(AudioServer.get_bus_volume_db(music_idx), -8.0), "Music bus is -8 dB")
		TestUtil.check(is_equal_approx(AudioServer.get_bus_volume_db(sfx_idx), 0.0), "SFX bus is 0 dB")
	TestUtil.check((player.get_node("WalkmanAudio") as AudioStreamPlayer).bus == &"Music", "WalkmanAudio on Music bus")
	TestUtil.check((player.get_node("WalkmanAudioB") as AudioStreamPlayer).bus == &"Music", "WalkmanAudioB on Music bus")
	TestUtil.check((player.get_node("SFXAudio") as AudioStreamPlayer).bus == &"SFX", "SFXAudio on SFX bus")

	played.clear()
	for cue in CUES:
		player.play_sfx(cue)
	for cue in CUES:
		TestUtil.check(played.has(cue), "sfx_played fired for cue '%s'" % cue)
	player.get_node("SFXGrindLoop").stop()
	player.get_node("SFXFlameLoop").stop()

	# Tape resume: A (listen) -> B -> C -> back to A must resume A, not restart it.
	player.switch_tape("Bubblegum")
	await create_timer(0.7).timeout
	var pos_a := _active_music().get_playback_position()
	TestUtil.check(_active_music().playing and pos_a > 0.3, "First tape is playing (pos=%.2f)" % pos_a)
	player.switch_tape("Bounce")
	await create_timer(0.4).timeout
	player.switch_tape("Metal")
	await create_timer(0.4).timeout
	player.switch_tape("Bubblegum")
	await create_timer(0.4).timeout
	var resumed := _active_music()
	var pos_resumed := resumed.get_playback_position()
	print("TAPE pos_before=%.2f pos_after_return=%.2f" % [pos_a, pos_resumed])
	TestUtil.check(resumed.playing, "First tape playing after returning to it")
	TestUtil.check(pos_resumed >= pos_a, "First tape resumes at >= its saved position (%.2f vs %.2f), not 0" % [pos_resumed, pos_a])
	var a_node := player.get_node("WalkmanAudio") as AudioStreamPlayer
	var b_node := player.get_node("WalkmanAudioB") as AudioStreamPlayer
	TestUtil.check(not (a_node.playing and b_node.playing and absf(a_node.volume_db - b_node.volume_db) < 1.0), "Crossfade settled: only one music player audible")

	# Flame loop: starts with RMB/F spray, stops when released.
	player.global_position = Vector3(0, 0.1, 17)
	var key := InputEventKey.new()
	key.keycode = KEY_F
	key.physical_keycode = KEY_F
	key.pressed = true
	Input.parse_input_event(key)
	await _frames(4)
	var flame := player.get_node("SFXFlameLoop") as AudioStreamPlayer
	TestUtil.check(flame.playing, "flame_loop plays while spraying")
	key = InputEventKey.new()
	key.keycode = KEY_F
	key.physical_keycode = KEY_F
	key.pressed = false
	Input.parse_input_event(key)
	await _frames(4)
	TestUtil.check(not flame.playing, "flame_loop stops when spray ends")

	# Grind loop: starts with grind_started, stops when the grinding state exits.
	player.set_is_skating(true)
	var path := Path3D.new()
	path.curve = Curve3D.new()
	path.curve.add_point(Vector3(-15, 0.75, 17))
	path.curve.add_point(Vector3(15, 0.75, 17))
	mall.add_child(path)
	player.global_position = Vector3(0, 1.2, 17)
	await _frames(2)
	player.velocity = Vector3(12, 0, 0)
	Input.action_press("jump")
	var grind_loop := player.get_node("SFXGrindLoop") as AudioStreamPlayer
	TestUtil.check(player.try_start_grind(path), "Grind starts for the loop-cue check")
	await _frames(5)
	TestUtil.check(player.is_grinding() and grind_loop.playing, "grind_loop plays while grinding")
	await _frames(6)
	Input.action_release("jump")
	await _frames(2)
	Input.action_press("attack")
	await _frames(1)
	Input.action_release("attack")
	TestUtil.check(not player.is_grinding(), "Player dismounted the rail")
	TestUtil.check(not grind_loop.playing, "grind_loop stops when the grind state exits")

	current_scene = null
	await TestUtil.cleanup(self)
	TestUtil.finish(self)
