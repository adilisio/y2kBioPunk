extends SceneTree
## Code-derived ideal bounds, not combat benchmarks. No enemies enter the tree.
var errors := 0

func _init() -> void:
	call_deferred("run")

# Non-exported timing/damage/XP constants are read from live source, never duplicated.
func number(source: String, pattern: String) -> float:
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		errors += 1
		return 0
	var found := regex.search(source)
	if not found:
		push_error("Balance source pattern missing: " + pattern)
		errors += 1
		return 0
	return found.get_string(1).to_float()

func section(source: String, function_name: String) -> String:
	return source.split("func " + function_name + "(")[1].split("\nfunc ")[0]

func bat_ttk(hp: float, damage: float, combo: bool, duration: float, delay: float, delay2: float, multiplier: float) -> float:
	var hit := 0
	while hp > 0:
		var index := hit % 3 if combo else 0
		hp -= damage * (multiplier if index == 2 else 1.0)
		if hp <= 0:
			return hit * duration + (delay2 if index == 1 else delay)
		hit += 1
	return 0

func run() -> void:
	var names := ["Cicada", "Roach", "Turret", "Queen"]
	var files := ["neon_cicada", "sludge_roach", "corrupted_kiosk_turret", "dial_up_queen"]
	var enemies: Array[Node] = []
	var sources: Array[String] = []
	for file in files:
		enemies.append(load("res://scripts/" + file + ".gd").new())
		sources.append(FileAccess.get_file_as_string("res://scripts/" + file + ".gd"))
	var p = ClassDB.instantiate("PlayerController")
	p.switch_tape("Bubblegum")
	var cpp := FileAccess.get_file_as_string("res://src/player_controller.cpp")
	var c := sources[0]
	var r := sources[1]
	var t := sources[2]
	var q := sources[3]
	var damage := [number(c, 'call\\("take_damage", ([0-9.]+)'), float(enemies[1].bite_damage), float(enemies[2].mortar_damage), float(enemies[3].aoe_base_damage)]
	var speeds := [enemies[0].chase_speed, enemies[1].scuttle_speed, 0.0, enemies[3].phase3_speed]
	var telegraphs := [number(section(c, "_enter_windup"), 'state_timer = ([0-9.]+)'), number(section(r, "_enter_windup"), 'state_timer = ([0-9.]+)'), number(section(t, "_enter_tracking"), 'state_timer = ([0-9.]+)') + enemies[2].charge_time, 0.0]
	enemies[3].current_phase = 3
	telegraphs[3] = enemies[3]._charge_duration()
	damage[3] *= number(q, 'int\\(aoe_base_damage \\* ([0-9.]+)')
	var xp: Array[int] = []
	for source in sources:
		xp.append(int(number(source, 'call\\("gain_xp", ([0-9.]+)')))
	print("| Enemy | HP | Damage | Speed (m/s) | Telegraph (s) | XP |")
	print("|---|---:|---:|---:|---:|---:|")
	for i in 4:
		print("| %s | %d | %d | %.2f | %.2f | %d |" % [names[i], enemies[i].max_health, damage[i], speeds[i], telegraphs[i], xp[i]])
	var bat: float = p.get_effective_bat_damage()
	var duration := number(cpp, 'attack_timer = ([0-9.]+)f;')
	var delay2 := number(cpp, 'pending_hit_timer = p_hit == 2 \\? ([0-9.]+)f')
	var delay := number(cpp, 'pending_hit_timer = p_hit == 2 \\? [0-9.]+f : ([0-9.]+)f')
	var multiplier := number(cpp, 'multiplier = combo_hit == 3 \\? ([0-9.]+)f')
	var flame := int(number(cpp, 'flame_damage = ([0-9.]+)f') + p.get_effective_vibe() * number(cpp, 'get_effective_vibe\\(\\)\\) \\* ([0-9.]+)f'))
	var flame_tick := number(cpp, 'flame_tick_timer = ([0-9.]+)f')
	var disk := int(number(cpp, 'disk_damage = ([0-9.]+)f') + p.get_effective_agility() * number(cpp.split('void PlayerController::fire_disk_launcher()')[1], 'get_effective_agility\\(\\)\\) \\* ([0-9.]+)f'))
	var disk_tick := number(cpp.split('void PlayerController::fire_disk_launcher()')[1], 'secondary_cooldown = ([0-9.]+)f')
	print("")
	print("Player: level %d, Bubblegum, HP %.0f, bat %.0f, flame %d/tick (%.2f DPS), disk %d." % [p.get_level(), p.get_max_health(), bat, flame, flame / flame_tick, disk])
	print("")
	print("| Enemy | Repeated 1-hit bat TTK (s) | 3-hit combo TTK (s) | Flame TTK (s) | Disk TTK (s + travel) |")
	print("|---|---:|---:|---:|---:|")
	for i in 4:
		var hp: float = enemies[i].max_health
		print("| %s | %.2f | %.2f | %.2f | %.2f |" % [names[i], bat_ttk(hp, bat, false, duration, delay, delay2, multiplier), bat_ttk(hp, bat, true, duration, delay, delay2, multiplier), (ceil(hp / flame) - 1) * flame_tick, (ceil(hp / disk) - 1) * disk_tick])
	var recovery := number(section(r, "_enter_repositioning"), 'state_timer = ([0-9.]+)')
	var roach_cycle: float = telegraphs[1] + recovery
	var iframe := number(cpp, 'hurt_invuln_timer = ([0-9.]+)f')
	var hits: int = int(ceil(p.get_max_health() / damage[1]))
	var turret_hits := int(ceil(p.get_max_health() / damage[2]))
	var queen_hits := int(ceil(p.get_max_health() / damage[3]))
	var idle := number(section(q, "_enter_idle"), 'else ([0-9.]+)')
	print("")
	print("| Threat | Ideal player TTD lower bound (s) |")
	print("|---|---:|")
	print("| 1 roach | %.2f |" % (telegraphs[1] + (hits - 1) * roach_cycle))
	print("| 3 roaches (staggered; hurt i-frames included) | %.2f |" % (telegraphs[1] + maxf((hits - 1) * roach_cycle / 3, (hits - 1) * iframe)))
	print("| Turret (excluding initial idle and mortar flight) | %.2f + flight |" % (telegraphs[2] + (turret_hits - 1) * (telegraphs[2] + enemies[2].cooldown_time)))
	print("| Queen phase 3 (repeated AoE, excluding tracking/summons) | %.2f |" % (telegraphs[3] + (queen_hits - 1) * (telegraphs[3] + idle)))
	var transition := number(section(q, "_trigger_phase_transition"), 'state_timer = ([0-9.]+)')
	print("")
	print("Queen TTK above excludes two %.2fs invulnerable transitions (add at least %.2fs)." % [transition, 2 * transition])
	print("Roach recovery flame TTK: %.2fs (%.2fx vulnerability)." % [(ceil(enemies[1].max_health / ceil(flame * number(section(r, "take_damage"), 'ceil\\(amount \\* ([0-9.]+)'))) - 1) * flame_tick, number(section(r, "take_damage"), 'ceil\\(amount \\* ([0-9.]+)')])
	# Inspect scene enemy overrides off-tree and use real gain_xp on an off-tree player.
	var mall = load("res://scenes/FloodedMall_Greybox.tscn").instantiate()
	mall._spawn_enemies(mall.get_node("Enemies"))
	var counts := [0, 0, 0]
	for enemy in mall.get_node("Enemies").get_children():
		for i in 3:
			if enemy.get_script() == enemies[i].get_script():
				counts[i] += 1
	var roster_xp: int = counts[0] * xp[0] + counts[1] * xp[1] + counts[2] * xp[2]
	p.gain_xp(roster_xp)
	print("Roster: %d cicadas + %d roaches + %d turrets = %d XP; real gain_xp yields level %d, XP %d/%d." % [counts[0], counts[1], counts[2], roster_xp, p.get_level(), p.get_current_xp(), p.get_xp_to_level()])
	mall.free()
	for enemy in enemies:
		enemy.free()
	p.free()
	print("BALANCE: %s (%d source errors)" % ["PASS" if errors == 0 else "FAIL", errors])
	quit(0 if errors == 0 else 1)
