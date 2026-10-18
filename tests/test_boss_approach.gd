extends SceneTree

var _checks := 0
var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)

func _spawner() -> Variant:
	var spawner = load("res://scenes/waves/wave_spawner.gd").new()
	spawner.config = load("res://data/waves/wave_spawner_config.tres")
	spawner.catalog = load("res://data/waves/wave_catalog.tres")
	for index in 12:
		var marker := Marker2D.new()
		marker.name = "spawnPos%d" % index
		spawner.add_child(marker)
	spawner.add_child(load("res://scenes/combat/projectile_pool.gd").new())
	root.add_child(spawner)
	spawner.start_run()
	spawner.set_physics_process(false)
	spawner._cancel_formations()
	return spawner

func _enemy(spawner: Variant, scene: String, at: Vector2) -> Variant:
	var enemy = load("res://scenes/enemies/%s.tscn" % scene).instantiate()
	enemy.position = at
	spawner.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy

func _settle() -> void:
	await process_frame
	await process_frame

func _test_natural() -> void:
	var spawner = _spawner()
	var drone = _enemy(spawner, "drone", Vector2(280, 100))
	var turret = _enemy(spawner, "turret", Vector2(400, 80))
	var asteroid = _enemy(spawner, "big_asteroid", Vector2(200, 150))
	var pool = load("res://scenes/combat/projectile_pool.gd")
	var shot = pool.spawn(load("res://scenes/combat/mother_ship_shot.tscn"), Vector2(300, 200), spawner)
	shot.set_physics_process(false)
	spawner.director.regular_elapsed = 300.0
	spawner._physics_process(0.0)
	_check(spawner.director.state == EncounterDirector.State.BOSS_APPROACH and not is_instance_valid(spawner._boss), "the natural milestone starts approach without materializing the boss")
	_check(is_instance_valid(drone) and is_instance_valid(turret) and is_instance_valid(asteroid) and not shot.get_meta("pooled", false), "visible enemies and their missiles survive the handoff")
	var state: int = spawner.director.random.encounters.state
	var regular: float = spawner.director.regular_elapsed
	var elapsed: float = spawner.director.elapsed
	var old_position: Vector2 = drone.position
	drone._update_movement(0.1)
	_check(drone.position != old_position and drone.process_mode != Node.PROCESS_MODE_DISABLED, "existing enemies keep moving during approach")
	turret._update_movement(0.1)
	_check(turret.process_mode != Node.PROCESS_MODE_DISABLED and not turret.destroyed, "patrolling turrets are left alive")
	spawner._physics_process(5.0)
	_check(spawner.director.random.encounters.state == state and spawner._pending.is_empty(), "the approach selects once and schedules no regular formations")
	_check(spawner.director.regular_elapsed == regular and spawner.director.elapsed == elapsed + 5.0, "survival time continues while regular scheduling is frozen")
	_check(spawner.get_debug_snapshot().state == "BOSS_APPROACH", "the debug snapshot exposes the approach state")
	asteroid._hit_something(10000.0, false)
	await _settle()
	_check(spawner._active_enemy_count() > 3, "asteroid fragments still materialize through normal reservation accounting")
	for enemy in get_nodes_in_group("enemy"):
		if spawner.is_ancestor_of(enemy):
			enemy._on_screen_exited()
	await _settle()
	spawner._physics_process(2.0)
	_check(not is_instance_valid(spawner._boss) and not shot.get_meta("pooled", false), "remaining enemy projectiles postpone the boss even after enemies have exited")
	pool.despawn(shot)
	await _settle()
	spawner._physics_process(0.3)
	var late_shot = pool.spawn(load("res://scenes/combat/mother_ship_shot.tscn"), Vector2(300, 250), spawner)
	late_shot.set_physics_process(false)
	spawner._physics_process(0.1)
	_check(is_equal_approx(spawner._boss_clear_left, 0.5), "a late enemy missile restarts the full calm window")
	pool.despawn(late_shot)
	await _settle()
	var player_shot = pool.spawn(load("res://scenes/player/player_shot.tscn"), Vector2(300, 250), spawner)
	player_shot.set_physics_process(false)
	spawner._physics_process(0.49)
	_check(spawner.director.state == EncounterDirector.State.BOSS_APPROACH, "a clear arena must remain calm for half a second")
	spawner.set_physics_process(true)
	paused = true
	var clear_left: float = spawner._boss_clear_left
	await create_timer(0.04).timeout
	_check(spawner._boss_clear_left == clear_left, "pause freezes the calm window")
	spawner.set_physics_process(false)
	paused = false
	spawner._physics_process(0.01)
	await _settle()
	_check(is_instance_valid(spawner._boss) and spawner.director.state == EncounterDirector.State.BOSS, "the boss arrives after the calm window without waiting for player shots")
	_check(not player_shot.get_meta("pooled", false), "the natural handoff preserves player shots")
	spawner.stop_run()
	spawner.free()
	await _settle()

func _test_cancel_and_debug() -> void:
	var spawner = _spawner()
	var enemy = _enemy(spawner, "drone", Vector2(300, 150))
	spawner.director.regular_elapsed = 300.0
	spawner._physics_process(0.0)
	spawner.stop_run()
	enemy.free()
	spawner._physics_process(10.0)
	await _settle()
	_check(not is_instance_valid(spawner._boss), "stopping the run cancels a waiting approach")
	spawner.free()
	spawner = _spawner()
	spawner.director.regular_elapsed = 300.0
	spawner._physics_process(0.0)
	spawner._physics_process(0.5)
	spawner.stop_run()
	await _settle()
	_check(not is_instance_valid(spawner._boss), "stop also cancels already-deferred boss materialization")
	spawner.free()
	spawner = _spawner()
	var wrapper := Node2D.new()
	root.add_child(wrapper)
	spawner.reparent(wrapper)
	var notifications := {"count": 0}
	var on_boss := func(_id, _name, _health): notifications.count += 1
	root.get_node("Events").boss_started.connect(on_boss)
	spawner.director.regular_elapsed = 300.0
	spawner._physics_process(0.0)
	spawner._physics_process(0.5)
	wrapper.queue_free()
	await _settle()
	_check(notifications.count == 0, "a screen queued for removal cannot publish a late boss arrival")
	root.get_node("Events").boss_started.disconnect(on_boss)
	spawner = _spawner()
	enemy = _enemy(spawner, "drone", Vector2(300, 150))
	spawner.debug_start_boss()
	await _settle()
	_check(is_instance_valid(spawner._boss) and not is_instance_valid(enemy), "F12 retains its immediate debug-only arena cleanup")
	spawner.stop_run()
	spawner.free()
	await _settle()

func _run() -> void:
	await _test_natural()
	await _test_cancel_and_debug()
	print("Boss natural approach: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)
