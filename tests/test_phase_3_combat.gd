extends "res://tests/test_energy_chains.gd"

const REFERENCE_BUILDS := {
	"precision": [&"side_shot", &"critical_hits", &"micro_missiles"],
	"propagation": [&"impact_explosions", &"energy_chains", &"ricochet"],
	"autonomous": [&"micro_missiles", &"escort_drone", &"orbiting_satellites"],
	"proximity": [&"guard_blades", &"orbiting_satellites", &"impact_explosions"],
}

func run() -> void:
	globals = root.get_node("global")
	events = root.get_node("Events")
	globals.Debug = false
	globals.coop = false
	globals.reset_run(14)
	root.size = Vector2i(640, 400)
	stage = Node2D.new()
	root.add_child(stage)
	pool = load("res://scenes/combat/projectile_pool.gd").new()
	stage.add_child(pool)
	effects = load("res://scenes/combat/player_hit_effects.gd").new()
	effects.name = "PlayerHitEffects"
	stage.add_child(effects)
	for index in 2:
		var player = load("res://scenes/player/player.tscn").instantiate()
		player.set_Player_2 = index == 1
		stage.add_child(player)
		player.set_physics_process(false)
		player.set_process(false)
		for kind in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
			for audio in player.find_children("*", kind, true, false): audio.stream = null
		if index == 0: p1 = player
		else: p2 = player
	effects.hit_accepted.connect(func(hit, target, position, first): accepted.append({"hit": hit, "target": target, "position": position, "first": first}))
	AudioServer.set_bus_mute(0, true)
	Engine.time_scale = 8.0
	Engine.physics_ticks_per_second = 480
	var runs: Array = []
	for seed_value in [0, 29, 69]:
		for build in REFERENCE_BUILDS:
			for layout in ["focused", "cluster"]:
				for distance in ["ranged", "close"]:
					runs.append(await measure(seed_value, build, layout, distance))
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	var report := {"seeds": [0, 29, 69], "physics_step": "1/60 gameplay second", "accelerated": 8,
		"seconds_per_case": 8, "layouts": {"focused": "one stationary 20-HP real drone", "cluster": "nine stationary 6-HP real drones, 28px grid"},
		"positions": {"ranged": [320, 350], "close": [320, 215]}, "builds": REFERENCE_BUILDS,
		"common_utilities": ["damage", "fire_rate", "orb_magnet"], "runs": runs, "checks": checks, "failures": failures}
	var output := FileAccess.open("user://phase_3_combat.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	p1.weapons.stop_support()
	p2.weapons.stop_support()
	await settle()
	stage.free()
	await process_frame
	print("Phase 3 reference combat: %d cases, %d checks, %d failures" % [runs.size(), checks, failures])
	quit(1 if failures else 0)

func measure(seed_value: int, build: String, layout: String, distance: String) -> Dictionary:
	p1.weapons.stop_support()
	p2.weapons.stop_support()
	await settle()
	await reset_case()
	globals.coop = false
	globals.reset_run(seed_value)
	effects.start([p1], globals.run_random)
	p1.position = Vector2(320, 350 if distance == "ranged" else 215)
	p1.canShooting = true
	p1.shooting_delay_timer.stop()
	p1.weapons.missile_wait = 0.0
	for id in REFERENCE_BUILDS[build] + [&"damage", &"fire_rate", &"orb_magnet"]:
		for definition in CATALOG.upgrades:
			if definition.id == id:
				for rank in definition.max_rank:
					check(p1.loadout.apply_foundation(id).applied, "reference builds use only normally eligible ranks")
	var targets: Array = []
	if layout == "focused":
		targets.append(enemy(&"focused", Vector2(320, 180), 20.0))
	else:
		for row in 3:
			for column in 3:
				targets.append(enemy(StringName("cluster_%d_%d" % [row, column]), Vector2(292 + column * 28, 124 + row * 28), 6.0))
	await settle()
	p1.setShootingDelay()
	p1.weapons.sync_support()
	var initial_hp := 20.0 if layout == "focused" else 6.0
	var kills := 0
	var elapsed := 0.0
	var all_killed: Variant = null
	var early: Dictionary = {}
	for tick in 480:
		await physics_frame
		p1.weapons.update_autonomous(1.0 / 60.0)
		if p1.canShooting: p1.weapons.fire_primary()
		elapsed = float(tick + 1) / 60.0
		kills = targets.filter(func(target): return not is_instance_valid(target) or target.destroyed).size()
		if tick == 119 or kills == targets.size():
			if early.is_empty():
				var damage := 0.0
				var coverage := 0
				for target in targets:
					var hp: float = maxf(target.life, 0.0) if is_instance_valid(target) else 0.0
					damage += initial_hp - hp
					if hp < initial_hp: coverage += 1
				early = {"seconds": elapsed, "kills": kills, "damaged": coverage, "effective_damage": damage}
		if kills == targets.size():
			all_killed = elapsed
			break
	var damaged := 0
	var effective := 0.0
	for target in targets:
		var remaining_hp: float = maxf(target.life, 0.0) if is_instance_valid(target) else 0.0
		if remaining_hp < initial_hp: damaged += 1
		effective += initial_hp - remaining_hp
	var state: Dictionary = p1.loadout.foundation_snapshot()
	check(state.offensive_count == 3 and state.utility_count == 3, "every measured case respects three plus three slots")
	check(accepted.all(func(record): return record.hit.owner_id() == &"player1"), "measured damage retains player ownership")
	return {"seed": seed_value, "build": build, "layout": layout, "distance": distance, "clear_seconds": all_killed,
		"observed_seconds": elapsed, "kills": kills, "targets": targets.size(), "damaged": damaged,
		"effective_damage": effective, "accepted_impacts": accepted.size(), "early": early}
