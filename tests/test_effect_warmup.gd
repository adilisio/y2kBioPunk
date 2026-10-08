extends SceneTree
## Headless validates lifecycle, cached resources and gameplay safety only.
## Dummy cannot compile GPU pipelines or measure the first-use rendering hitch.

const U = preload("res://tests/_test_util.gd")
const FX = preload("res://scripts/turret_mortar.gd")
const WARMUP = preload("res://scripts/effect_warmup.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	U.reset()
	var save := root.get_node_or_null("SaveManager")
	if save:
		save.pending_load = false
		save.respawn_pending = false
	var mall := load("res://scenes/FloodedMall_Greybox.tscn").instantiate() as Node3D
	U.track(mall)
	var warmup := mall.get_node_or_null("EffectWarmup")
	U.check(warmup != null and warmup.get_script() == WARMUP, "mall contains EffectWarmup with the assigned script")
	var bus_name: StringName = warmup.muted_bus if warmup else &"missing"
	root.add_child(mall)
	current_scene = mall
	var player := get_first_node_in_group("player")
	U.check(player != null, "mall has a player")
	var health: float = player.get_current_health() if player else -1
	var enemies := get_nodes_in_group("enemies")
	var enemy_health := {}
	for enemy in enemies:
		enemy_health[enemy.get_instance_id()] = enemy.current_health
	U.check(enemies.size() == 9, "test exercises the complete pre-boss roster")
	await create_timer(1.0).timeout
	U.check(mall.get_node_or_null("EffectWarmup") == null, "EffectWarmup frees itself within one second")
	U.check(root.find_children("WarmupProbes", "", true, false).is_empty(), "no warm-up probe remains anywhere in the tree")
	U.check(player != null and player.get_current_health() == health, "warm-up leaves player health unchanged")
	U.check(get_nodes_in_group("enemies").size() == enemies.size(), "warm-up neither spawns nor removes enemies")
	for enemy in enemies:
		U.check(is_instance_valid(enemy) and enemy.current_health == enemy_health[enemy.get_instance_id()], "warm-up leaves %s health unchanged" % enemy.name)
	U.check(not paused, "warm-up does not pause the tree")
	U.check(is_equal_approx(Engine.time_scale, 1.0), "warm-up does not invoke hit-stop")
	U.check(AudioServer.get_bus_index(bus_name) == -1, "temporary muted audio bus is removed")
	for recipe in WARMUP.SOUND_RECIPES:
		var key := "%d|%d|%d" % [int(round(recipe.x * 100)), int(round(recipe.y)), int(round(recipe.z * 100))]
		U.check(FX._sound_cache.has(key), "real SFX recipe %s is cached" % recipe)
	for color in WARMUP.BURST_COLORS:
		U.check(FX._burst_cache.has(color.to_html(false)), "real burst kit %s is cached" % color)
	print("[EffectWarmup] lifecycle, player/enemy health, time scale and cached resources checked after 1 s")
	await U.cleanup(self)
	U.finish(self)
