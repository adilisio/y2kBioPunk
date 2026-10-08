extends Node
## Static visual registry: bounds are captured after construction, never queried in combat.

const FADED_TRANSPARENCY := 0.7
const FADE_IN_SPEED := 8.0
const FADE_OUT_SPEED := 5.0
const HOLD_SECONDS := 0.15

class Occluder:
	extends RefCounted
	var visual: GeometryInstance3D
	var bounds_space: Node3D
	var local_bounds: AABB
	var world_bounds: AABB
	var hold_remaining := 0.0

var occluders: Array[Occluder] = []
var _warm_instances: Array[GeometryInstance3D] = []
var _warm_kinds: Array[StringName] = []
var _player: Node3D
var _camera: Camera3D
var _warm_stage := 0
var aabb_tests_last_tick := 0

func register_occluder(visual: GeometryInstance3D, bounds_space: Node3D, local_bounds: AABB) -> void:
	var entry := Occluder.new()
	entry.visual = visual
	entry.bounds_space = bounds_space
	entry.local_bounds = local_bounds
	occluders.append(entry)
	var kind := visual.get_class()
	if not _warm_kinds.has(kind):
		_warm_kinds.append(kind)
		_warm_instances.append(visual)

func finish_build() -> void:
	# Also supports a builder constructed outside the tree (editor tooling/tests).
	if not is_inside_tree():
		return
	for entry in occluders:
		if is_instance_valid(entry.bounds_space):
			entry.world_bounds = entry.bounds_space.global_transform * entry.local_bounds
			entry.bounds_space = null
	_warm_stage = 0
	set_process(true)

func _process(_delta: float) -> void:
	if _warm_stage == 0:
		# First process frame after the whole build, including final prop transforms.
		for entry in occluders:
			if is_instance_valid(entry.bounds_space):
				entry.world_bounds = entry.bounds_space.global_transform * entry.local_bounds
				entry.bounds_space = null
		for visual in _warm_instances:
			if is_instance_valid(visual):
				visual.transparency = 0.01
		_warm_stage = 1
	elif _warm_stage == 1:
		for visual in _warm_instances:
			if is_instance_valid(visual):
				visual.transparency = 0.0
		_warm_stage = 2
		set_process(false)

func _physics_process(delta: float) -> void:
	aabb_tests_last_tick = 0
	if _warm_stage < 2:
		return
	if not is_instance_valid(_player) or not _player.is_inside_tree():
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if not is_instance_valid(_camera) or not _camera.is_inside_tree():
		_camera = get_viewport().get_camera_3d()
	var has_targets := is_instance_valid(_player) and is_instance_valid(_camera)
	var start := Vector3.ZERO
	var end := Vector3.ZERO
	if has_targets:
		start = _camera.global_position
		end = _player.global_position + Vector3(0.0, 1.0, 0.0)
	var fade_in_weight := 1.0 - exp(-FADE_IN_SPEED * delta)
	var fade_out_weight := 1.0 - exp(-FADE_OUT_SPEED * delta)
	for entry in occluders:
		if not is_instance_valid(entry.visual):
			continue
		var intersects := false
		if has_targets:
			aabb_tests_last_tick += 1
			# Godot 4.3 returns the hit position (Vector3), or null for no hit.
			intersects = entry.world_bounds.intersects_segment(start, end) != null
		if intersects:
			entry.hold_remaining = HOLD_SECONDS
		else:
			entry.hold_remaining = maxf(0.0, entry.hold_remaining - delta)
		var fading := intersects or entry.hold_remaining > 0.0
		var target := FADED_TRANSPARENCY if fading else 0.0
		var weight := fade_in_weight if fading else fade_out_weight
		var value := lerpf(entry.visual.transparency, target, weight)
		# Exponential tails converge to exactly opaque instead of staying transparent forever.
		entry.visual.transparency = target if absf(value - target) < 0.001 else value

func restore_all() -> void:
	for entry in occluders:
		if is_instance_valid(entry.visual):
			entry.visual.transparency = 0.0
		entry.hold_remaining = 0.0

func _exit_tree() -> void:
	restore_all()
	occluders.clear()
	_warm_instances.clear()
	_warm_kinds.clear()
