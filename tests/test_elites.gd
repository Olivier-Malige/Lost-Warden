extends SceneTree

var CONFIG: WaveSpawnerConfig
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

func _make_spawner(seed_value: int, coop := false, kind := "drone", count := 6):
	_globals.coop = coop
	_globals.reset_run(seed_value)
	var rule := SpawnRule.new()
	rule.scene = load("res://scenes/enemies/%s.tscn" % kind)
	rule.formation = count
	rule.pattern = SpawnRule.Pattern.LINE
	rule.spawn_gap = 0.6
	var wave := WaveDefinition.new()
	wave.id = &"elite_test"
	wave.rules.append(rule)
	var catalog := WaveCatalog.new()
	catalog.waves.append(wave)
	var spawner = load("res://scenes/waves/wave_spawner.gd").new()
	spawner.config = CONFIG
	spawner.catalog = catalog
	for index in CONFIG.lane_count:
		var marker := Marker2D.new()
		marker.name = "spawnPos%d" % index
		marker.position = Vector2(116 + index * 32, -28)
		spawner.add_child(marker)
	root.add_child(spawner)
	spawner.start_run()
	spawner.set_physics_process(false)
	spawner.enemy_spawned.connect(_freeze_enemy)
	return spawner

func _freeze_enemy(enemy: Variant) -> void:
	enemy.set_physics_process(false)
	for node in enemy.find_children("*", "Timer", true, false):
		node.stop()
	for node in enemy.find_children("*", "AudioStreamPlayer2D", true, false):
		node.stream = null
	enemy.set_deferred("monitoring", false)
	enemy.set_deferred("monitorable", false)

func _cancel_pending(spawner: Variant) -> void:
	for item in spawner._pending:
		spawner._release_reservation(item)
	spawner._pending.clear()

func _trace(seed_value: int, noise: bool, seconds: float, count := 6) -> Array[String]:
	var spawner = _make_spawner(seed_value, false, "drone", count)
	spawner.director.elapsed = seconds
	var trace: Array[String] = []
	for formation in 500:
		if noise:
			randf()
			spawner.director.random.drops.randf()
			spawner.director.random.upgrades.randf()
		spawner._budget_left = 1000.0
		spawner._schedule_formation()
		var promoted := 0
		for item in spawner._pending:
			if item.context.elite:
				promoted += 1
			trace.append("%s|%s|%s" % [item.position, item.context.elite, item.context.movement_seed])
		_check(promoted <= 1, "a formation promotes at most one member")
		_cancel_pending(spawner)
	spawner.stop_run()
	spawner.free()
	return trace

func _test_caps(coop: bool) -> void:
	var spawner = _make_spawner(98, coop)
	spawner.director.elapsed = 720.0
	for formation in 100:
		spawner._budget_left = 1000.0
		spawner._schedule_formation()
		_check(spawner._reserved_elites <= 3, "delayed formations reserve elite capacity in both modes")
		_check(spawner._active_enemy_count() <= spawner._enemy_cap(), "elite reservations also respect total body capacity")
	_check(spawner._reserved_elites == 3, "queued formations reach the three-elite cap")
	var pending: Array[Dictionary] = spawner._pending.duplicate()
	spawner._pending.clear()
	for item in pending:
		spawner._materialize(item)
	_check(spawner._active_elite_count() == 3 and spawner._reserved_elites == 0, "materializing converts reserved elites to active elites")
	var elite = get_first_node_in_group("elite")
	elite._hit_something(elite.life, false)
	_check(spawner._active_elite_count() == 2 and not elite._elite_indicator.visible, "a defeated elite frees its capacity and hides its bar")
	for enemy in spawner.get_children():
		if enemy.is_in_group("enemy") and not enemy.elite:
			enemy.free()
	for formation in 100:
		spawner._budget_left = 1000.0
		spawner._schedule_formation()
	_check(spawner._active_elite_count() == 3, "only the released elite slot can be reserved again")
	spawner.stop_run()
	_check(spawner._reserved_elites == 0, "stopping releases pending elite reservations")
	spawner.free()

func _test_ineligible() -> void:
	for kind in ["asteroid", "big_asteroid", "mother_ship_turret"]:
		var spawner = _make_spawner(42, false, kind)
		spawner.director.elapsed = 720.0
		for formation in 100:
			spawner._budget_left = 1000.0
			spawner._schedule_formation()
			_check(spawner._reserved_elites == 0, "hazards and mounted turrets never promote")
			_cancel_pending(spawner)
		spawner.stop_run()
		spawner.free()

func _test_stats() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	for kind in ["drone", "tie", "interceptor", "turret", "mother_ship"]:
		var scene = load("res://scenes/enemies/%s.tscn" % kind)
		var normal: Variant = scene.instantiate()
		stage.add_child(normal)
		_freeze_enemy(normal)
		var elite: Variant = scene.instantiate()
		var context := EnemySpawnContext.new()
		context.elite = true
		context.elite_definition = CONFIG.elite_definition
		context.health_multiplier = 1.2
		context.speed_multiplier = 1.1
		context.fire_delay_multiplier = 0.9
		elite.configure_spawn(context)
		stage.add_child(elite)
		_freeze_enemy(elite)
		_check(is_equal_approx(elite.max_life, elite.definition.max_health * 1.2 * 3.0), kind + ": elite health stacks once with director health")
		_check(is_equal_approx(elite.fire_delay_multiplier, 0.9 * 0.7), kind + ": elite attack delay stacks once")
		_check(is_equal_approx(elite._movement_speed_scale(), 1.1 * 1.1), kind + ": elite movement stacks once")
		_check(elite.points == normal.points * 3, kind + ": elite score is tripled")
		var normal_shape: CollisionShape2D = normal.get_node("CollisionShape2D")
		var elite_shape: CollisionShape2D = elite.get_node("CollisionShape2D")
		_check(normal_shape.shape == elite_shape.shape and normal_shape.transform == elite_shape.transform, kind + ": elite art preserves collision geometry")
		var sprite: Sprite2D = elite.get_node("Sprite2D")
		_check(sprite.texture == elite.definition.elite_texture and sprite.self_modulate == Color.WHITE, kind + ": approved localized markings retain their palette")
		_check(sprite.hframes == elite.definition.elite_frame_grid.x and sprite.vframes == elite.definition.elite_frame_grid.y, kind + ": frame layout matches the elite atlas")
		_check(not elite._elite_indicator.is_processing(), kind + ": health bar does not animate an aura")
		elite._hit_something(1.25, false)
		_check(is_equal_approx(elite._elite_indicator.current_health, elite.max_life - 1.25), kind + ": health bar retains fractional damage")
		if kind == "mother_ship":
			for turret in elite._mounted_turrets:
				_freeze_enemy(turret)
				_check(not turret.elite and is_equal_approx(turret.max_life, turret.definition.max_health * 1.2 * 3.0), "mounted turrets inherit elite hull health without a second elite multiplier")
				_check(is_equal_approx(turret.fire_delay_multiplier, 0.9 * 0.7), "mounted turrets inherit the hull fire-delay multiplier once")
		elite.free()
		normal.free()
	stage.free()

func _test_fire_timing() -> void:
	for kind in ["tie", "interceptor"]:
		for promoted in [false, true]:
			var enemy = load("res://scenes/enemies/%s.tscn" % kind).instantiate()
			var timer: Timer = enemy.get_node(enemy.shoot_timer_paths[0])
			var original_delay := timer.wait_time
			timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
			var context := EnemySpawnContext.new()
			context.fire_delay_multiplier = 0.2
			context.elite = promoted
			context.elite_definition = CONFIG.elite_definition
			enemy.configure_spawn(context)
			enemy.position = Vector2(320, 100)
			for audio in enemy.find_children("*", "AudioStreamPlayer2D", true, false):
				audio.stream = null
			root.add_child(enemy)
			enemy.set_physics_process(false)
			var expected_delay := original_delay * 0.2 * (0.7 if promoted else 1.0)
			_check(is_equal_approx(timer.time_left, expected_delay), "%s: initial countdown uses director and elite multipliers" % kind)
			var fired := {"count": 0}
			timer.timeout.connect(func(): fired.count += 1)
			for tick in ceili(expected_delay * Engine.physics_ticks_per_second) + 2:
				await physics_frame
			_check(fired.count == 1, "%s: the actual first timeout uses the scaled delay" % kind)
			timer.stop()
			enemy._apply_spawn_context()
			_check(timer.is_stopped(), "%s: scaling does not start a stopped shooting timer" % kind)
			enemy.free()
	for shot in get_nodes_in_group("enemy_Shot"):
		shot.queue_free()
	await process_frame

func _test_cancellation() -> void:
	var spawner = _make_spawner(98)
	spawner.director.elapsed = 720.0
	for formation in 20:
		spawner._budget_left = 1000.0
		spawner._schedule_formation()
	_check(spawner._reserved_elites > 0, "skip fixture contains pending elites")
	spawner.debug_skip_encounter()
	_check(spawner._reserved_elites == 0, "debug skip cancels pending elite slots")
	for formation in 20:
		spawner._budget_left = 1000.0
		spawner._schedule_formation()
	spawner.director.elapsed += 10.0
	spawner._flush_pending()
	spawner.stop_run()
	await process_frame
	_check(spawner._reserved_elites == 0 and spawner._active_elite_count() == 0, "stopping invalidates deferred elite materialization and releases its slots")
	spawner.free()

func _test_rewards() -> void:
	_globals.coop = false
	_globals.reset_run(120)
	var stage := Node2D.new()
	root.add_child(stage)
	var enemy: Variant = load("res://scenes/enemies/drone.tscn").instantiate()
	var xp: Array[int] = []
	root.get_node("Events").xp_spawn_requested.connect(func(amount, _position): xp.append(amount), CONNECT_ONE_SHOT)
	var context := EnemySpawnContext.new()
	context.elite = true
	context.elite_definition = CONFIG.elite_definition
	enemy.configure_spawn(context)
	stage.add_child(enemy)
	_freeze_enemy(enemy)
	enemy.hitByPlayerShot = true
	enemy._hit_something(enemy.max_life, false)
	await process_frame
	var powerups := 0
	var plasma := 0
	for child in stage.get_children():
		if child.scene_file_path == "res://scenes/ui/power_up.tscn":
			powerups += 1
		if child.scene_file_path == "res://scenes/ui/plasma_cell.tscn" and is_equal_approx(child.charge_amount, 25.0):
			plasma += 1
	_check(powerups == 0 and plasma == 1 and xp == [6], "player elite kills guarantee six XP and large plasma without direct power-ups")
	_check(_globals.score == 30, "the first elite drone awards triple its base score")
	stage.free()

func _run() -> void:
	CONFIG = load("res://data/waves/wave_spawner_config.tres")
	_globals = root.get_node("global")
	_globals.Debug = true
	var early := _trace(17, false, 119.99, 1)
	_check(early.all(func(item): return item.contains("|false|")), "there are no elite promotions before two minutes")
	var original := _trace(314, false, 720.0)
	_check(original == _trace(314, true, 720.0), "cosmetic and reward randomness cannot change seeded promotions or movement")
	_check(original != _trace(315, false, 720.0), "different seeds produce different promotion traces")
	var single := _trace(71, false, 720.0, 1)
	var promotions := single.filter(func(item): return item.contains("|true|")).size()
	_check(promotions > 90 and promotions < 160, "twelve-minute single-member promotions follow the 25 percent model")
	_test_caps(false)
	_test_caps(true)
	_test_ineligible()
	_test_stats()
	await _test_fire_timing()
	await _test_cancellation()
	await _test_rewards()
	await process_frame
	print("Elites: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)
