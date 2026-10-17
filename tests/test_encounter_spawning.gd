extends SceneTree

const CONFIG: WaveSpawnerConfig = preload("res://data/waves/wave_spawner_config.tres")
var CATALOG: WaveCatalog

var _checks := 0
var _failures := 0
var _globals: Node

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)

func _make_spawner(seed_value: int, coop := false):
	_globals.coop = coop
	_globals.reset_run(seed_value)
	var spawner = load("res://scenes/waves/wave_spawner.gd").new()
	spawner.config = CONFIG
	spawner.catalog = CATALOG
	for index in CONFIG.lane_count:
		var marker := Marker2D.new()
		marker.name = "spawnPos%d" % index
		marker.position = Vector2(116 + index * 37, -28)
		spawner.add_child(marker)
	root.add_child(spawner)
	spawner.start_run()
	spawner.set_physics_process(false)
	spawner.enemy_spawned.connect(_freeze_enemy)
	return spawner

func _freeze_enemy(enemy) -> void:
	var enemies: Array[Node] = [enemy]
	enemies.append_array(enemy.find_children("*", "Area2D", true, false))
	for candidate in enemies:
		candidate.set_physics_process(false)
		if candidate is Area2D:
			candidate.set_deferred("monitoring", false)
			candidate.set_deferred("monitorable", false)
	for timer in enemy.find_children("*", "Timer", true, false):
		timer.stop()
	for sound in enemy.find_children("*", "AudioStreamPlayer2D", true, false):
		sound.stream = null

func _clear_enemies(spawner) -> void:
	for child in spawner.get_children():
		if child.is_in_group("enemy"):
			child.free()

func _trace(seed_value: int, noise: bool, coop := false, start_time := 0.0, duration := 80.0) -> Array[String]:
	var spawner = _make_spawner(seed_value, coop)
	if start_time > 0.0:
		spawner.director.elapsed = start_time
		spawner.director.regular_elapsed = start_time
		spawner._begin_encounter()
	var trace: Array[String] = []
	spawner.enemy_spawned.connect(func(enemy):
		trace.append("%s|%s|%s|%s|%s" % [spawner.director.encounter.id, enemy.definition.id, enemy.position, enemy._spawn_context.movement_seed, enemy.max_life])
	)
	var previous_encounter: int = spawner.director.encounter_number
	for tick in roundi(duration / 0.25):
		if noise:
			for draw in 7:
				randf()
				_globals.run_random.drops.randi()
				_globals.run_random.upgrades.randi()
		spawner._physics_process(0.25)
		_check(spawner._budget_left >= 0.0, "threat spending cannot exceed the encounter budget")
		_check(spawner._active_enemy_count() <= spawner._enemy_cap(), "live enemies and pending reservations respect the cap")
		if spawner.director.encounter_number != previous_encounter:
			_check(spawner.director.encounter_left >= 20.0, "encounters chain immediately without a transition pause")
			previous_encounter = spawner.director.encounter_number
		await process_frame
		if tick % 12 == 11:
			_clear_enemies(spawner)
	_check(trace.size() > 20, "the integrated spawner produces actual enemies")
	_check(spawner.director.encounter_number >= 3, "the run advances through several encounters")
	spawner.stop_run()
	await process_frame
	_check(spawner._reserved_slots == 0, "stopping cancels every deferred reservation")
	spawner.free()
	return trace

func _test_catalog() -> void:
	var spawner = _make_spawner(12)
	var ids: Array[StringName] = []
	var patterns: Array[int] = []
	_check(CATALOG.waves.size() == 18, "all eighteen original encounter compositions are retained")
	for wave in CATALOG.waves:
		_check(wave.is_encounter_valid(CONFIG.lane_count), "encounter metadata, duration and formations are valid")
		_check(wave.id not in ids, "encounter identifiers are unique")
		ids.append(wave.id)
		for rule in wave.rules:
			var definition: EnemyDefinition = spawner._rule_definition(rule)
			_check(definition != null and definition.id != &"" and definition.threat_cost > 0.0, "every composition resolves a configured enemy family")
			patterns.append(rule.pattern)
			for cycle in 3:
				var lanes: Array[int] = spawner._formation_lanes(rule, rule.formation, cycle)
				_check(lanes.size() <= rule.formation, "formations respect authored sizes")
				for lane in lanes:
					_check(lane >= rule.spawn_min and lane <= rule.spawn_max, "formation positions remain in authored lanes")
				if rule.pattern == SpawnRule.Pattern.GAP_WALL:
					_check(lanes.size() <= rule.spawn_max - rule.spawn_min - 1, "gap walls preserve two open lanes")
	for pattern in [SpawnRule.Pattern.LINE, SpawnRule.Pattern.V, SpawnRule.Pattern.SCATTER, SpawnRule.Pattern.ALTERNATING_EDGES, SpawnRule.Pattern.OFFSET_GROUP]:
		_check(pattern in patterns, "the catalog contains every required formation type")
	spawner.stop_run()
	spawner.free()

func _test_caps(coop: bool) -> void:
	var spawner = _make_spawner(77, coop)
	var cap := 90 if coop else 70
	_check(spawner._enemy_cap() == cap, "solo/co-op caps match the roadmap")
	var blocker := Node.new()
	root.add_child(blocker)
	for index in cap - 2:
		var member := Node.new()
		blocker.add_child(member)
		member.add_to_group(&"enemy")
	var carrier: EnemyDefinition = load("res://data/enemies/mother_ship.tres")
	_check(spawner._available_members(carrier) == 0, "carrier and two mounted turrets require three free slots")
	var debris = load("res://scenes/enemies/asteroid.tscn").instantiate()
	_check(spawner.queue_enemy(debris), "secondary spawn reserves a free slot")
	var second = load("res://scenes/enemies/asteroid.tscn").instantiate()
	_check(spawner.queue_enemy(second), "second secondary spawn reserves the final slot")
	var rejected = load("res://scenes/enemies/asteroid.tscn").instantiate()
	_check(not spawner.queue_enemy(rejected), "pending debris cannot exceed the cap")
	spawner._schedule_formation()
	_check(spawner._active_enemy_count() == cap, "scheduled formations cannot bypass pending debris reservations")
	await process_frame
	_check(spawner._active_enemy_count() == cap and spawner._reserved_slots == 0, "deferred materialization converts reservations into live enemies")
	blocker.free()
	_clear_enemies(spawner)
	var rule := SpawnRule.new()
	rule.scene = load("res://scenes/enemies/mother_ship.tscn")
	rule.formation = 1
	var only_carriers := WaveDefinition.new()
	only_carriers.id = &"carrier_test"
	only_carriers.rules.append(rule)
	spawner.director.encounter = only_carriers
	spawner.director.elapsed = 720.0
	spawner._budget_left = 1000.0
	for index in 4:
		spawner._schedule_formation()
	_check(spawner._reserved_slots == 9, "three carrier hulls reserve all nine hull/turret slots")
	spawner._flush_pending()
	await process_frame
	_check(get_node_count_in_group(&"enemy") == 9, "mounted turrets are counted after carrier materialization")
	_check(spawner._available_members(carrier) == 0, "carrier family limit prevents unavailable anchor spawns")
	for enemy in get_nodes_in_group(&"enemy"):
		_check(is_equal_approx(enemy.fire_delay_multiplier, 0.8), "mounted turrets inherit the hull firing multiplier exactly once")
		if enemy.is_in_group("mounted_turret"):
			var expected: float = enemy.definition.max_health * enemy.get_parent().max_life / enemy.get_parent().definition.max_health
			_check(is_equal_approx(enemy.max_life, expected), "mounted health inherits the complete hull multiplier once")
	spawner.stop_run()
	spawner.free()

func _test_state_and_mode() -> void:
	var spawner = _make_spawner(8, true)
	_globals.coop = false
	_check(spawner._enemy_cap() == 90, "run-level co-op caps remain fixed after partner death")
	var common: EnemyDefinition = load("res://data/enemies/drone.tres")
	_check(is_equal_approx(spawner._health_multiplier(common), 1.25), "run-level co-op health remains fixed")
	var before: float = spawner.director.elapsed
	paused = true
	await process_frame
	_check(is_equal_approx(spawner.director.elapsed, before), "pausing cannot advance encounter time")
	paused = false
	spawner._physics_process(0.25)
	spawner.stop_run()
	await process_frame
	_check(get_node_count_in_group(&"enemy") == 0 and spawner._reserved_slots == 0, "stopping rejects queued deferred spawns")
	spawner.free()

func _debris_trace(noise: bool) -> Array[Vector2]:
	var spawner = _make_spawner(15)
	var asteroid = load("res://scenes/enemies/big_asteroid.tscn").instantiate()
	var context := EnemySpawnContext.new()
	context.movement_seed = 77
	asteroid.configure_spawn(context)
	asteroid.position = Vector2(320, 100)
	spawner.queue_enemy(asteroid)
	await process_frame
	if noise:
		for index in 20:
			randf()
	asteroid._drop_debris()
	await process_frame
	var positions: Array[Vector2] = []
	for child in spawner.get_children():
		if child != asteroid and child.is_in_group("enemy"):
			positions.append(child.position)
	_check(positions.size() == 5, "destroyed large asteroids preserve all five debris spawns when capacity allows")
	spawner.stop_run()
	spawner.free()
	return positions

func _test_debug_skip() -> void:
	var spawner = _make_spawner(17)
	var main := Node.new()
	root.add_child(main)
	main.set_script(load("res://scenes/main/main.gd"))
	main.worldScreen = true
	var world := Node2D.new()
	world.name = "world"
	main.add_child(world)
	spawner.name = "waveGenerator"
	spawner.reparent(world)
	var existing = load("res://scenes/enemies/drone.tscn").instantiate()
	spawner.queue_enemy(existing)
	await process_frame
	spawner._physics_process(0.25)
	var number: int = spawner.director.encounter_number
	var elapsed: float = spawner.director.elapsed
	var regular_elapsed: float = spawner.director.regular_elapsed
	var offset: float = spawner.director.danger_offset
	var encounter_id: StringName = spawner.director.encounter.id
	var event := InputEventKey.new()
	event.keycode = KEY_N
	event.pressed = true
	_check(event.is_action_pressed("debug_next_wave"), "N retains the existing debug skip binding")
	main._input(event)
	_check(spawner.director.encounter_number == number, "normal builds cannot skip encounters")
	_globals.Debug = true
	main._input(event)
	_check(spawner.director.encounter_number == number + 1, "N advances exactly one encounter through the main input handler")
	_check(spawner.director.encounter.id != encounter_id, "debug skip follows normal encounter selection rules")
	_check(is_equal_approx(spawner.director.elapsed, elapsed) and is_equal_approx(spawner.director.regular_elapsed, regular_elapsed), "debug skipping does not fabricate survival or boss scheduling time")
	_check(is_equal_approx(spawner.director.danger_offset, offset), "debug skip does not change danger")
	_check(is_equal_approx(spawner.director.encounter_left, spawner.director.encounter.duration), "debug skip starts a full new encounter")
	await process_frame
	_check(spawner._reserved_slots == 0 and spawner._pending.is_empty(), "debug skip cancels pending and already-deferred spawns from the previous encounter")
	_check(is_instance_valid(existing) and existing.is_inside_tree(), "debug skip preserves enemies already in play")
	event.echo = true
	main._input(event)
	_check(spawner.director.encounter_number == number + 1, "holding N does not repeatedly skip encounters")
	event.echo = false
	event.pressed = false
	main._input(event)
	_check(spawner.director.encounter_number == number + 1, "releasing N cannot skip encounters")
	event.pressed = true
	paused = true
	main._input(event)
	_check(spawner.director.encounter_number == number + 1, "pause prevents debug skipping")
	paused = false
	for state in [EncounterDirector.State.BOSS, EncounterDirector.State.RECOVERY]:
		spawner.director.state = state
		main._input(event)
		_check(spawner.director.encounter_number == number + 1, "boss encounters and recovery cannot be bypassed")
	spawner.director.state = EncounterDirector.State.REGULAR
	spawner.stop_run()
	main._input(event)
	_check(spawner.director.encounter_number == number + 1, "a stopped run cannot restart through debug skip")
	_globals.Debug = false
	main.free()

func _run() -> void:
	_globals = root.get_node("global")
	_globals.Debug = false
	CATALOG = load("res://data/waves/wave_catalog.tres")
	_test_catalog()
	var expected := await _trace(42, false)
	_check(expected == await _trace(42, true), "same seed reproduces encounter families, positions, movement seeds and health despite cosmetic noise")
	_check(expected != await _trace(43, false), "different seeds produce different actual spawn traces")
	var early := await _trace(91, false, false, 0.0, 120.0)
	var late := await _trace(91, false, false, 720.0, 120.0)
	var advanced := 0
	var common := 0
	for entry in late:
		if entry.contains("talon_interceptor") or entry.contains("siege_turret") or entry.contains("grave_carrier"):
			advanced += 1
		if entry.contains("razor_wing") or entry.contains("razor_fighter"):
			common += 1
	var early_advanced := 0
	for entry in early:
		if entry.contains("talon_interceptor") or entry.contains("siege_turret") or entry.contains("grave_carrier"):
			early_advanced += 1
	_check(float(advanced) / late.size() > float(early_advanced) / early.size(), "advanced families become more frequent as danger rises")
	_check(common > 0, "common enemies remain in high-danger encounters")
	await _trace(55, false, true)
	await _test_caps(false)
	await _test_caps(true)
	await _test_state_and_mode()
	_check(await _debris_trace(false) == await _debris_trace(true), "debris positions are independent of cosmetic randomness")
	await _test_debug_skip()
	print("Encounter spawning: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)
