# tests/_test_util.gd
## Shared test utility providing honest assertion checking, node lifecycle management,
## leak-free teardown, and isolated save storage redirection.

class_name TestUtil
extends RefCounted

static var failure_count: int = 0
static var failure_messages: Array[String] = []
static var tracked_nodes: Array[Node] = []
static var active_test_save_path: String = ""

## Reset global failure counters and tracked nodes
static func reset() -> void:
	failure_count = 0
	failure_messages.clear()
	tracked_nodes.clear()
	active_test_save_path = ""

## Honest assertion helper: logs failures instead of crashing, records count
static func check(cond: bool, msg: String) -> bool:
	if not cond:
		failure_count += 1
		failure_messages.append(msg)
		print("FAIL: %s" % msg)
		return false
	return true

## Returns number of recorded failures
static func get_failure_count() -> int:
	return failure_count

## Print final summary line (RESULT: PASS or RESULT: FAIL (n))
static func print_summary() -> void:
	if failure_count == 0:
		print("RESULT: PASS")
	else:
		print("RESULT: FAIL (%d)" % failure_count)

## Finish test with honest exit code
static func finish(tree: SceneTree) -> void:
	print_summary()
	if tree:
		if failure_count == 0:
			tree.quit(0)
		else:
			tree.quit(1)

## Track a node for guaranteed teardown before quitting
static func track(node: Node) -> Node:
	if node and not tracked_nodes.has(node):
		tracked_nodes.append(node)
	return node

static func stop_all_audio(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is AudioStreamPlayer:
		node.stop()
		node.stream = null
	for child in node.get_children():
		stop_all_audio(child)

## Cleanly free all tracked nodes and wait for frames to flush ObjectDB & PhysicsServer RIDs
static func cleanup(tree: SceneTree) -> void:
	# Delete temporary save if one was created
	if active_test_save_path != "":
		cleanup_isolated_save(active_test_save_path)
		active_test_save_path = ""

	# Stop all AudioStreamPlayers across root and tracked nodes
	if tree and tree.root:
		stop_all_audio(tree.root)
	for node in tracked_nodes:
		stop_all_audio(node)

	# Queue-free tracked nodes while in the tree so engine cleans them up properly
	for i in range(tracked_nodes.size() - 1, -1, -1):
		var node = tracked_nodes[i]
		if is_instance_valid(node):
			node.queue_free()
	tracked_nodes.clear()

	# Also free any remaining untracked children spawned into root (e.g. projectiles)
	if tree and tree.root:
		for child in tree.root.get_children():
			if is_instance_valid(child):
				child.queue_free()

	if tree:
		for i in range(30):
			await tree.process_frame
			await tree.physics_frame

## Static frame awaiting helper
static func await_frames(tree: SceneTree, count: int = 1) -> void:
	for i in range(count):
		await tree.process_frame

## Static physics frame awaiting helper
static func await_physics_frames(tree: SceneTree, count: int = 1) -> void:
	for i in range(count):
		await tree.physics_frame

## Scope 3: Isolated save storage helper.
## Redirects SaveManager.SAVE_PATH to user://test_save_<pid>.json if writable,
## else returns supported = false so the caller can SKIP the section.
static func setup_isolated_save(save_mgr: Object) -> Dictionary:
	var pid = OS.get_process_id()
	var test_path = "user://test_save_%d.json" % pid

	if not save_mgr:
		return {
			"supported": false,
			"path": "",
			"skip_reason": "SaveManager instance is null"
		}

	# Check if SAVE_PATH is writable by attempting to set it
	var original_val = save_mgr.get("SAVE_PATH")
	save_mgr.set("SAVE_PATH", test_path)
	var updated_val = save_mgr.get("SAVE_PATH")

	if updated_val == test_path and test_path != original_val:
		active_test_save_path = test_path
		return {
			"supported": true,
			"path": test_path,
			"skip_reason": ""
		}
	else:
		return {
			"supported": false,
			"path": "",
			"skip_reason": "SaveManager.SAVE_PATH is a constant/read-only property; skipping to avoid overwriting production save"
		}

## Deletes the isolated test save file
static func cleanup_isolated_save(test_path: String) -> void:
	if test_path == "":
		return
	if FileAccess.file_exists(test_path):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove(test_path.get_file())
