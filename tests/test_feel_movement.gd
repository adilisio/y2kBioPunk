extends SceneTree

var failures: Array[String] = []
var player: CharacterBody3D
var mall: Node3D
const DT := 1.0 / 60.0

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

func speed() -> float:
	return Vector2(player.velocity.x, player.velocity.z).length()

func reset(skates: bool = false) -> void:
	Input.action_release("move_forward")
	Input.action_release("jump")
	player.set_is_skating(skates)
	player.set_movement_state(0)
	player.global_position = Vector3(0, 0.1, 17)
	player.velocity = Vector3.ZERO
	await frames(30)

func run() -> void:
	mall = load("res://scenes/FloodedMall_Greybox.tscn").instantiate()
	# Keep the authored floor, rails and model; isolate from encounters/save UI.
	mall.set_script(null)
	for name in ["Enemies", "HUD", "BossEncounterTrigger", "Checkpoint"]:
		var node := mall.get_node_or_null(name)
		if node:
			node.free()
	root.add_child(mall)
	current_scene = mall
	player = mall.get_node("Player")
	await reset()
	var skeleton := player.find_child("Skeleton3D", true, false) as Skeleton3D
	var toe := skeleton.find_bone("mixamorig_LeftToe_End")
	var toe_y := (skeleton.global_transform * skeleton.get_bone_global_pose(toe).origin).y
	var query := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP * 0.2, player.global_position + Vector3.DOWN * 2, 1, [player.get_rid()])
	var floor_hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	check(not floor_hit.is_empty(), "Floor must be under player")
	var gap: float = toe_y - floor_hit.get("position", player.global_position).y
	print("FEEL toe_floor_gap=", gap)
	check(absf(gap) < 0.1, "Toe/floor gap must be < 0.1m")
	Input.action_press("move_forward")
	var walk_time := -1.0
	for i in 12:
		await frames(1)
		if walk_time < 0 and speed() >= 7:
			walk_time = (i + 1) * DT
	print("FEEL walk_to_7=", walk_time)
	check(walk_time > 0 and walk_time <= 0.15, "Walk must reach 7m/s within 0.15s")
	await reset(true)
	Input.action_press("move_forward")
	var skate_time := -1.0
	for i in 60:
		await frames(1)
		if skate_time < 0 and speed() >= 7:
			skate_time = (i + 1) * DT
	Input.action_release("move_forward")
	await frames(30)
	var coast_speed := speed()
	print("FEEL skate_to_7=", skate_time, " coast_after_0.5=", coast_speed)
	# 7 / 16 = 0.4375s: preserve the brief's acceleration table. Its 0.5s
	# threshold conflicts with that table; require >=0.40s with 60Hz sampling.
	check(skate_time >= 0.4, "Skates at 16m/s² must take >= 0.40s to reach 7m/s")
	check(coast_speed > 6, "Skate coast must retain > 6m/s after 0.5s")
	await reset()
	var ground_y := player.global_position.y
	Input.action_press("jump")
	var apex := 0.0
	var airtime := 0.0
	var left_floor := false
	for i in 100:
		await frames(1)
		apex = maxf(apex, player.global_position.y - ground_y)
		if not player.is_on_floor():
			left_floor = true
		if left_floor:
			airtime += DT
			if player.is_on_floor():
				break
	Input.action_release("jump")
	print("FEEL jump_apex=", apex, " airtime=", airtime)
	check(apex >= 1.0 and apex <= 1.4, "Jump apex must be 1.0-1.4m")
	check(left_floor and airtime < 0.75, "Jump airtime must be < 0.75s")
	await reset()
	ground_y = player.global_position.y
	Input.action_press("jump")
	await frames(3)
	Input.action_release("jump")
	var cut_apex := 0.0
	for i in 50:
		await frames(1)
		cut_apex = maxf(cut_apex, player.global_position.y - ground_y)
		if player.is_on_floor():
			break
	print("FEEL cut_jump_apex=", cut_apex)
	check(cut_apex < 0.65, "Early jump release must cut jump height")
	await reset()
	player.global_position.y += 0.15 # Simulate leaving a ledge.
	await frames(2)
	check(not player.is_on_floor(), "Coyote fixture must be airborne")
	Input.action_press("jump")
	await frames(1)
	check(player.velocity.y > 6, "Jump inside coyote window must launch")
	Input.action_release("jump")
	await reset()
	player.global_position.y += 1.0
	player.velocity.y = -5
	await frames(7) # Expire coyote time before queuing the landing jump.
	check(not player.is_on_floor() and player.velocity.y < 0, "Buffer fixture must still be falling")
	Input.action_press("jump") # Buffer just before landing.
	var buffered_launch := false
	for i in 12:
		await frames(1)
		if player.velocity.y > 6:
			buffered_launch = true
			break
	check(buffered_launch, "Buffered jump must launch after touchdown")
	Input.action_release("jump")
	await reset()
	player.global_position.y += 5
	player.velocity = Vector3(10, 0, 0)
	await frames(9) # Expire the explicit external-shove hold.
	var before_hv := Vector3(player.velocity.x, 0, player.velocity.z)
	Input.action_press("move_forward")
	await frames(1)
	var after_hv := Vector3(player.velocity.x, 0, player.velocity.z)
	check(before_hv.distance_to(after_hv) <= 20 * DT + 0.001, "Air steering must respect 20m/s² acceleration")
	check(before_hv.angle_to(after_hv) <= deg_to_rad(180) * DT + 0.001, "Air steering must respect 180deg/s turn limit")
	await reset()
	var hp: float = player.get_current_health()
	player.take_damage(10)
	await frames(1)
	player.take_damage(10)
	print("FEEL hp_delta_two_hits=", hp - player.get_current_health())
	check(is_equal_approx(hp - player.get_current_health(), 10), "Two hits in two frames must damage only once")
	await frames(14) # Let the overlay restore before freeing the skinned meshes.
	# Release native references while the tree/physics world still exist.
	current_scene = null
	mall.queue_free()
	await frames(3)
	print("FEEL_MOVEMENT ", "PASS" if failures.is_empty() else "FAIL", " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
