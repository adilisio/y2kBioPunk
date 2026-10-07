extends SpringArm3D
class_name IsometricCameraRig

## Dynamic Isometric Follow Camera Rig
## Uses SpringArm3D to maintain distance and prevent clipping through geometry.
## Interpolates smoothly to follow the player with a locked 45-degree isometric angle.

@export var target: Node3D = null
@export var smooth_speed: float = 9.0
@export var pitch_angle_deg: float = -45.0
@export var yaw_angle_deg: float = 45.0
@export var arm_length: float = 16.0
@export var offset_height: float = 1.0

var camera: Camera3D = null
var trauma: float = 0.0

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func _ready() -> void:
	set_as_top_level(true)
	spring_length = arm_length
	margin = 0.0
	collision_mask = 0 # Completely disable raycast collisions to maintain stable 45-degree isometric distance
	rotation_degrees = Vector3(pitch_angle_deg, yaw_angle_deg, 0.0)
	
	if not target:
		var p = get_parent()
		if p is Node3D:
			target = p
			
	camera = get_node_or_null("Camera3D")
	if not camera:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		camera.current = true
		add_child(camera)
	else:
		camera.current = true
		
	if target and is_instance_valid(target):
		global_position = target.global_position + Vector3(0.0, offset_height, 0.0)

func _physics_process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		if get_tree():
			var p = get_tree().get_first_node_in_group("player")
			if p is Node3D:
				target = p
			else:
				return
		else:
			return

	var target_pos = target.global_position + Vector3(0.0, offset_height, 0.0)
	if target is CharacterBody3D:
		var hv := Vector3(target.velocity.x, 0.0, target.velocity.z)
		target_pos += (hv * 0.18).limit_length(2.5)
	var t = clampf(smooth_speed * delta, 0.0, 1.0)
	global_position = Vector3(lerpf(global_position.x, target_pos.x, t), lerpf(global_position.y, target_pos.y, clampf(3.0 * delta, 0.0, 1.0)), lerpf(global_position.z, target_pos.z, t))
	rotation_degrees = Vector3(pitch_angle_deg, yaw_angle_deg, 0.0)
	if camera:
		var shake := trauma * trauma * 0.35
		camera.h_offset = shake * randf_range(-1.0, 1.0)
		camera.v_offset = shake * randf_range(-1.0, 1.0)
	trauma = maxf(0.0, trauma - 1.8 * delta)
