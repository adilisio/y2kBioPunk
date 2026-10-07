extends SceneTree
## Director diagnostic: does camera-relative steering converge to the input direction?
## Prints horizontal velocity every 5 physics frames while holding move_forward with a +45 yaw camera,
## first airborne (no floor), then grounded (static floor).
func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for grounded in [false, true]:
		var player = ClassDB.instantiate("PlayerController")
		var visuals = Node3D.new(); visuals.name = "Visuals"; player.add_child(visuals)
		var col = CollisionShape3D.new(); var cap = CapsuleShape3D.new(); cap.radius = 0.4; cap.height = 1.8
		col.shape = cap; col.position = Vector3(0, 0.9, 0); player.add_child(col)
		root.add_child(player)
		if grounded:
			var floor_body = StaticBody3D.new()
			var fcol = CollisionShape3D.new(); var box = BoxShape3D.new(); box.size = Vector3(200, 1, 200)
			fcol.shape = box; floor_body.add_child(fcol); floor_body.position = Vector3(0, -0.5, 0)
			root.add_child(floor_body)
		var cam = Camera3D.new(); cam.rotation_degrees = Vector3(-30, 45, 0); root.add_child(cam); cam.make_current()
		await process_frame
		await physics_frame
		# Start with +X velocity like the test does
		player.set_velocity(Vector3(8, 0, 0))
		Input.action_press("move_forward")
		print("--- grounded=%s ---" % grounded)
		for i in range(61):
			await physics_frame
			if i % 5 == 0:
				var v = player.get_velocity()
				print("f%02d  vx=%6.2f vz=%6.2f  |v|=%5.2f  angle=%6.1f on_floor=%s" % [i, v.x, v.z, Vector2(v.x, v.z).length(), rad_to_deg(atan2(-v.z, v.x)), player.is_on_floor()])
		Input.action_release("move_forward")
		player.queue_free()
		await process_frame
	quit(0)
