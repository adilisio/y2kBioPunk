extends SceneTree

var failures: Array[String] = []
var slam_count := 0
var slam_on_floor := false
var player: CharacterBody3D

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func on_slam(_position: Vector3, _direction: Vector3, _damage: float) -> void:
	slam_count += 1
	slam_on_floor = player.is_on_floor()

func run() -> void:
	var mall := load("res://scenes/FloodedMall_Greybox.tscn").instantiate() as Node3D
	mall.set_script(null)
	for name in ["Enemies", "HUD", "BossEncounterTrigger", "Checkpoint"]:
		var node := mall.get_node_or_null(name)
		if node:
			node.free()
	root.add_child(mall)
	current_scene = mall
	player = mall.get_node("Player")
	player.global_position = Vector3(0, 0.1, 17)
	await frames(30)
	player.set_is_skating(true)
	var path := Path3D.new()
	path.curve = Curve3D.new()
	path.curve.add_point(Vector3(-15, 0.75, 17))
	path.curve.add_point(Vector3(15, 0.75, 17))
	mall.add_child(path)
	player.velocity = Vector3(12, 0, 0)
	check(not player.try_start_grind(path), "Grounded entry without a recent jump must be refused")
	player.global_position.y = 1.2
	await frames(2)
	player.velocity = Vector3(0, 0, 12)
	check(not player.try_start_grind(path), "Perpendicular approach must be refused")
	player.set_movement_locked(true)
	check(not player.try_start_grind(path), "Locked entry must be refused")
	player.set_movement_locked(false)
	player.velocity = Vector3(12, 0, 0)
	Input.action_press("jump")
	var entry := player.global_position
	check(player.try_start_grind(path), "Airborne aligned entry must succeed")
	check(player.global_position.is_equal_approx(entry), "Grind entry must not teleport")
	await frames(5)
	check(player.is_grinding(), "Entry grace must ignore held jump")
	await frames(6)
	check(player.is_grinding(), "Held jump after grace must not dismount")
	Input.action_release("jump")
	await frames(2)
	player.grind_slam_executed.connect(on_slam)
	Input.action_press("attack")
	await frames(1)
	Input.action_release("attack")
	check(not player.is_grinding() and slam_count == 0, "Manual dismount must defer slam until landing")
	var exit_speed := Vector2(player.velocity.x, player.velocity.z).length()
	check(exit_speed >= 14.9, "Grind exit must carry boosted horizontal momentum")
	for i in 100:
		await frames(1)
		if slam_count > 0:
			break
	check(slam_count == 1 and slam_on_floor, "Slam must fire once on the first landing frame")
	var disc := mall.get_node_or_null("GrindSlamShockwave") as MeshInstance3D
	check(disc != null, "Landing slam must create a shockwave disc")
	if disc:
		check(absf(disc.global_position.y - player.global_position.y) < 0.1, "Shockwave must be at floor height")
	check(Vector2(player.velocity.x, player.velocity.z).length() > 10, "Landing must preserve rail glide")
	print("FEEL grind_exit_speed=", exit_speed, " landing_speed=", Vector2(player.velocity.x, player.velocity.z).length())
	await create_timer(0.15, true, false, true).timeout
	check(is_equal_approx(Engine.time_scale, 1), "Slam hit-stop must restore time scale in real time")
	current_scene = null
	mall.queue_free()
	await frames(3)
	print("FEEL_TRAVERSAL ", "PASS" if failures.is_empty() else "FAIL", " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
