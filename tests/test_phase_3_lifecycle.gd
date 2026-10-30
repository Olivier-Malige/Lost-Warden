extends SceneTree

const CATALOG: UpgradeTable = preload("res://data/upgrades/foundation_catalog.tres")
const BUILDS := [
	[&"side_shot", &"critical_hits", &"micro_missiles"],
	[&"impact_explosions", &"energy_chains", &"ricochet"],
	[&"micro_missiles", &"escort_drone", &"orbiting_satellites"],
	[&"guard_blades", &"orbiting_satellites", &"impact_explosions"],
]

var globals: Node
var world: Node2D
var duration := 10.0
var coop := false
var failures: Array[String] = []
var frames: Array[float] = []
var samples: Array = []
var peaks := {"xp": 0, "roots": 0, "requests": 0, "parked": 0, "nodes": 0, "missiles": 0, "bolts": 0, "shards": 0}
var boss_patterns := {}

func _initialize() -> void:
	call_deferred("run")

func require(condition: bool, message: String) -> void:
	if not condition and message not in failures:
		failures.append(message)
		push_error(message)

func start_world(seed_value: int) -> void:
	globals.coop = coop
	world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	globals.reset_run(seed_value)
	world.progression.start(world.progression.players, globals.run_random.upgrades)
	world.hit_effects.start(world.progression.players, globals.run_random)
	for player in world.progression.players:
		player.collision_layer = 0
		player.collision_mask = 0
		player.position.y = 330
	apply_build(0)

func apply_build(index: int) -> void:
	for player in world.progression.players:
		player.weapons.stop_support()
		player.loadout.reset()
		for id in BUILDS[index] + [&"damage", &"fire_rate", &"orb_magnet"]:
			for upgrade in CATALOG.upgrades:
				if upgrade.id == id:
					for rank in upgrade.max_rank:
						require(player.loadout.apply_foundation(id).applied, "stress loadouts must remain legal")
		player.setShootingDelay()
		player.weapons.sync_support()
		player.publish_build()

func inspect(elapsed: float) -> void:
	var effects: Dictionary = world.hit_effects.get_debug_snapshot()
	var pool: Dictionary = world.get_node("projectilePool").get_debug_snapshot()
	var xp: Dictionary = world.progression.pool.snapshot()
	require(xp.active + xp.reserved <= 128, "XP pool cap")
	peaks.xp = maxi(peaks.xp, xp.active + xp.reserved)
	for field in ["roots", "requests"]: peaks[field] = maxi(peaks[field], effects[field])
	peaks.parked = maxi(peaks.parked, pool.parked)
	peaks.nodes = maxi(peaks.nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	for player in world.progression.players:
		var owner := StringName(player.id_Player)
		var counts := {"missiles": 0, "bolts": 0, "shards": 0}
		for key in world.hit_effects._reservations:
			if not String(key).begins_with(String(owner) + ":"): continue
			var kind := "shards" if "ricochet" in String(key) else "missiles" if "missile" in String(key) else "bolts"
			counts[kind] += int(world.hit_effects._reservations[key])
		for kind in counts: peaks[kind] = maxi(peaks[kind], counts[kind])
		require(counts.missiles <= 3 and counts.bolts <= 6 and counts.shards <= 4, "personal projectile reservation caps")
		require(player.weapons.escorts.size() <= 2, "personal escort cap")
		if is_instance_valid(player.weapons.satellites):
			require(player.weapons.satellites._orbiters.size() <= 3, "personal satellite cap")
		var state: Dictionary = player.loadout.foundation_snapshot()
		require(state.offensive_count <= 3 and state.utility_count <= 3, "stress slot limits")
	samples.append({"seconds": elapsed, "effects": effects, "pool": pool, "xp": xp, "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT)})

func run() -> void:
	globals = root.get_node("global")
	globals.Debug = false
	for arg in OS.get_cmdline_user_args():
		if arg == "--coop": coop = true
		if arg.begins_with("--seconds="): duration = maxf(1.0, float(arg.trim_prefix("--seconds=")))
	root.size = Vector2i(640, 400)
	Engine.max_fps = 120
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	AudioServer.set_bus_mute(0, true)
	start_world(1400)
	await process_frame
	var started := Time.get_ticks_usec()
	var previous := started
	var next_sample := 0.0
	var last_build := 0
	var boss_started := false
	var phase_changed := false
	var defeated := false
	var elapsed := 0.0
	while elapsed < duration:
		await process_frame
		var now := Time.get_ticks_usec()
		elapsed = float(now - started) / 1000000.0
		frames.append(float(now - previous) / 1000.0)
		previous = now
		var build_index := mini(3, int(elapsed / maxf(1.0, duration / 4.0)))
		if build_index != last_build:
			apply_build(build_index)
			last_build = build_index
		for index in world.progression.players.size():
			var player = world.progression.players[index]
			player.energy = 12
			player.position.x = 320.0 + sin(elapsed * 0.7 + index * PI) * 150.0
			if player.canShooting: player.weapons.fire_primary()
		var spawner = world.get_node("waveGenerator")
		if not boss_started and elapsed >= duration * 0.2:
			boss_started = spawner._begin_boss(true)
		var boss = spawner._boss
		if is_instance_valid(boss) and not boss.destroyed:
			boss_patterns["%d:%s" % [boss.phase, boss.get_attack_pattern_name()]] = true
			if elapsed >= duration * 0.7:
				boss._hit_something(100000.0)
				defeated = boss.destroyed
			elif not phase_changed and elapsed >= duration * 0.4:
				boss._hit_something(boss.max_life * 0.6)
				phase_changed = boss.phase > 0
			else:
				boss.life = boss.max_life * (0.49 if phase_changed else 1.0)
				for cannon in boss._cannons:
					if not cannon.destroyed: cannon.life = cannon.max_life
		if elapsed >= next_sample:
			inspect(elapsed)
			next_sample += 1.0
			if int(elapsed) % 30 == 0: print("Native stress %s: %.0f/%.0f seconds" % ["coop" if coop else "solo", elapsed, duration])
		if int(elapsed) in [30, 100, 160, 250] and samples.size() > 0 and samples[-1].get("capture", false) == false:
			samples[-1].capture = true
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("user://stress_%s_%d.png" % ["coop" if coop else "solo", int(elapsed)])
	frames.sort()
	var percentiles := {}
	for percentile in [0.5, 0.95, 0.99]: percentiles[str(percentile)] = frames[mini(frames.size() - 1, ceili(frames.size() * percentile) - 1)]
	world.free()
	for frame in 8: await process_frame
	var baselines: Array[int] = []
	for cycle in 5:
		start_world(1401 + cycle)
		await create_timer(0.15).timeout
		world.free()
		for frame in 8: await process_frame
		baselines.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	require(baselines.max() - baselines.min() <= 2, "world teardown must not accumulate nodes")
	if duration >= 300:
		require(boss_started and phase_changed and defeated, "stress completes boss phases and defeat")
		require(boss_patterns.has("1:BEAM"), "stress observes the phase-two beam")
	var report := {"native": DisplayServer.get_name() != "headless", "mode": "coop" if coop else "solo", "seed": 1400,
		"duration_wall_seconds": elapsed, "renderer": RenderingServer.get_current_rendering_method(), "gpu": RenderingServer.get_video_adapter_name(),
		"resolution": [640, 400], "frame_cap": 120, "vsync": false, "frames": frames.size(), "frame_ms": percentiles,
		"peaks": peaks, "teardown_nodes": baselines, "boss_patterns": boss_patterns.keys(), "boss_phase_changed": phase_changed, "boss_defeated": defeated,
		"samples": samples, "failures": failures}
	var output := FileAccess.open("user://phase_3_stress_%s.json" % report.mode, FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("Native stress completed: %s; frame ms %s; failures %s" % [report.mode, JSON.stringify(percentiles), failures])
	quit(0 if failures.is_empty() else 1)
