extends SceneTree

var _globals: Node
var _events: Node
var _checks := 0
var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)

func _freeze(enemy: Variant) -> void:
	enemy.set_physics_process(false)
	enemy.set_deferred("monitoring", false)
	enemy.set_deferred("monitorable", false)
	for sound in enemy.find_children("*", "AudioStreamPlayer2D", true, false):
		sound.stream = null
	for timer in enemy.find_children("*", "Timer", true, false):
		timer.stop()

func _make_spawner(seed_value := 91, coop := false, parent: Node = null) -> Variant:
	_globals.coop = coop
	_globals.reset_run(seed_value)
	var spawner = load("res://scenes/waves/wave_spawner.gd").new()
	spawner.config = load("res://data/waves/wave_spawner_config.tres")
	spawner.catalog = load("res://data/waves/wave_catalog.tres")
	for index in spawner.config.lane_count:
		var marker := Marker2D.new()
		marker.name = "spawnPos%d" % index
		marker.position = Vector2(116 + index * 32, -28)
		spawner.add_child(marker)
	var pool = load("res://scenes/combat/projectile_pool.gd").new()
	spawner.add_child(pool)
	(root if parent == null else parent).add_child(spawner)
	spawner.start_run()
	spawner.set_physics_process(false)
	spawner.enemy_spawned.connect(_freeze)
	return spawner

func _start_boss(spawner: Variant) -> void:
	spawner.director.elapsed = 299.0
	spawner.director.regular_elapsed = 299.0
	spawner._physics_process(0.5)
	_check(spawner.director.state == EncounterDirector.State.REGULAR, "the boss does not start before five regular minutes")
	spawner._physics_process(0.5)
	_check(spawner.director.state == EncounterDirector.State.BOSS_APPROACH, "five regular minutes trigger the natural approach")
	for enemy in get_nodes_in_group("enemy"):
		if spawner.is_ancestor_of(enemy):
			enemy._on_screen_exited()
	await process_frame
	spawner._physics_process(0.49)
	_check(spawner.director.state == EncounterDirector.State.BOSS_APPROACH, "boss entry waits for the calm window")
	spawner._physics_process(0.01)
	await process_frame
	await process_frame
	_check(is_instance_valid(spawner._boss) and get_nodes_in_group("boss").size() == 1, "one boss materializes through the deferred spawn path")
	_check(spawner._reserved_slots == 0 and is_zero_approx(spawner._budget_left), "boss entry cancels normal formations and their budget")
	_check(spawner._active_enemy_count() == 1, "boss entry starts after the regular enemies finish exiting")

func _shots() -> Array[Node]:
	var result: Array[Node] = []
	for shot in get_nodes_in_group("enemy_Shot"):
		if not shot.get_meta("pooled", false):
			result.append(shot)
	return result

func _recycle() -> void:
	var service = load("res://scenes/combat/projectile_pool.gd")
	for shot in _shots():
		service.despawn(shot)
	await process_frame

func _volley(boss: Variant, target: Node2D) -> void:
	boss.attack = boss.Attack.IDLE
	boss._attack_left = 0.0
	boss._attack_cycle = 1
	boss._physics_process(0.01)
	_check(boss.attack == boss.Attack.CHARGE and _shots().is_empty(), "each volley has a harmless preparation window")
	target.position.x = 640.0 - target.position.x
	boss._physics_process(boss._pattern.telegraph_time)
	_check(boss.attack == boss.Attack.FIRE, "shots fire only after the telegraph")
	_check(boss._locked_target == target.global_position, "the first salvo updates its aim after the player moves during charging")
	for shot in _shots():
		shot.set_physics_process(false)
		shot.set_deferred("monitoring", false)
		shot.set_deferred("monitorable", false)

func _finish_burst(boss: Variant, target: Node2D) -> void:
	var per_salvo := _shots().size()
	for index in range(1, boss._pattern.burst_count):
		var previous := _shots()
		var previous_velocity := Vector2(previous[0].speedX, previous[0].speedY)
		target.position.x = 120.0 if index % 2 else 520.0
		boss._physics_process(boss._pattern.burst_interval * 0.5)
		_check(_shots().size() == per_salvo * index, "successive salvos wait for their configured interval")
		boss._physics_process(boss._pattern.burst_interval * 0.5)
		_check(boss.attack == boss.Attack.FIRE and _shots().size() == per_salvo * (index + 1), "each repeated salvo fires the complete missile fan")
		_check(boss._locked_target == target.global_position, "each salvo aims at the player's updated position")
		var aimed := false
		for shot in _shots():
			if shot not in previous:
				var direction := Vector2(shot.speedX, shot.speedY).normalized()
				aimed = aimed or direction.dot(shot.global_position.direction_to(target.global_position)) > 0.99999
		_check(aimed, "new missile velocities point at the moving player")
		_check(Vector2(previous[0].speedX, previous[0].speedY) == previous_velocity, "missiles already fired retain their dodgeable trajectory")
	_check(boss._salvos_left == 0, "a missile burst ends after its configured salvo count")
	boss._physics_process(0.21)
	_check(boss.attack == boss.Attack.RECOVER, "recovery starts only after the last salvo finishes")
	boss._physics_process(boss._pattern.recovery_time)
	_check(boss.attack == boss.Attack.IDLE, "a completed burst leaves a rest window before the next attack")

func _test_fight(coop: bool) -> void:
	var spawner = _make_spawner(91, coop)
	await _start_boss(spawner)
	var boss = spawner._boss
	_check(is_equal_approx(boss.max_life, 1040.0 if coop else 650.0), "reduced boss durability is fixed for the run's solo/co-op mode")
	_check(not boss.elite and boss.is_in_group("boss"), "the boss is a separate encounter, never an elite promotion")
	var health_before: float = boss.life
	boss._hit_something(100.0, false)
	_check(boss.life == health_before, "the arriving boss cannot take damage before entering the arena")
	boss._physics_process(2.0)
	_check(boss._visual == "open_bays", "entry opens the hangars before the first combat cycle")
	boss._physics_process(0.78)
	_check(boss.attack == boss.Attack.IDLE and is_equal_approx(boss.position.y, 82.0), "the boss enters the upper combat area before attacking")
	var target := Node2D.new()
	target.add_to_group("player")
	target.position = Vector2(300, 370)
	root.add_child(target)
	await _volley(boss, target)
	_check(_shots().size() == 10, "phase one fires two aimed five-shot fans")
	_check(boss._locked_target == target.global_position, "the first salvo targets a real player position")
	_check(boss._pattern.burst_count == 3 and is_equal_approx(boss._pattern.burst_interval, 0.25), "phase one fires three salvos a quarter second apart")
	var remaining: int = boss._salvos_left
	var before_pause: float = boss._attack_left
	boss.set_physics_process(true)
	paused = true
	await create_timer(0.1).timeout
	_check(boss._salvos_left == remaining and boss._attack_left == before_pause and _shots().size() == 10, "pause freezes an in-progress missile burst")
	boss.set_physics_process(false)
	paused = false
	_finish_burst(boss, target)
	var ids: Array[int] = []
	for shot in _shots():
		ids.append(shot.get_instance_id())
		_check(is_equal_approx(Vector2(shot.speedX, shot.speedY).length(), 230.0), "boss projectile speed uses its revised configured value")
	await _recycle()
	spawner._spawn_boss_reinforcements()
	_check(not spawner._pending.is_empty(), "the transition fixture has reserved reinforcements")
	boss._hit_something(boss.max_life * 0.51, false)
	_check(boss.phase == 1 and boss.attack == boss.Attack.TRANSITION, "crossing half health starts the only combat phase transition")
	_check(spawner._pending.is_empty() and spawner._reserved_boss_adds == 0, "the phase transition cancels pending reinforcements and releases their reservations")
	boss._physics_process(0.96)
	_check(boss.attack == boss.Attack.IDLE and boss._visual == "phase_3", "opening the core ends in the second phase idle")
	await _volley(boss, target)
	_check(_shots().size() == 7, "phase two fires an aimed broadside with seven shots")
	_check(_shots().all(func(shot): return shot.get_instance_id() in ids), "boss volleys reuse pooled projectiles")
	var first_side: int = boss._gun_side
	_finish_burst(boss, target)
	await _recycle()
	await _volley(boss, target)
	_check(boss._gun_side == 1 - first_side and boss._visual == boss._gun_tag("fire") and _shots().size() == 7, "completed broadsides alternate to the other gun and its authored animation")
	_finish_burst(boss, target)
	await _recycle()
	boss._attack_left = 0.0
	boss._attack_cycle = 3
	boss._physics_process(0.01)
	_check(boss.attack == boss.Attack.BEAM_CHARGE and boss._beam.warning and not boss._beam.active, "the final phase warns the beam corridor without dealing damage")
	spawner._spawn_boss_reinforcements()
	_check(spawner._pending.is_empty(), "beam preparation rejects new reinforcement launches")
	var beam_x: float = boss.global_position.x
	boss._physics_process(0.5)
	_check(boss.global_position.x == beam_x, "beam preparation locks its lane instead of chasing the player")
	boss._physics_process(boss.boss_data.beam_charge_time - 0.5 + 0.001)
	_check(boss._beam.active and boss._visual == "beam_fire", "the beam starts only at the firing animation")
	spawner._spawn_boss_reinforcements()
	_check(spawner._pending.is_empty(), "beam fire rejects new reinforcement launches")
	boss._physics_process(boss.boss_data.beam_fire_time)
	_check(not boss._beam.active and boss._visual == "beam_recover", "the beam ends before its cooling animation")
	boss._physics_process(0.84)
	await _volley(boss, target)
	_check(_shots().size() == 7, "the final phase alternates the beam with seven-shot broadsides")
	_finish_burst(boss, target)
	await _recycle()
	for clip in boss.VISUALS.values():
		_check(clip[0] >= 0 and clip[1] < 87 and clip[2] > 0, "boss animation ranges stay within the approved atlas")
	var phase_before: int = boss.phase
	boss._hit_something(0.25, false)
	_check(boss.phase == phase_before, "ordinary hits never restart or reverse a completed phase transition")
	for index in 20:
		spawner._spawn_boss_reinforcements()
	var add_cap := 12 if coop else 8
	_check(spawner._reserved_boss_adds == add_cap and spawner._active_enemy_count() == add_cap + 1, "reinforcement reservations respect the solo/co-op caps")
	_check(spawner._pending.all(func(item): return item.boss_add and not item.context.elite), "boss formations contain only declared ordinary reinforcements")
	spawner.director.elapsed += 5.0
	spawner._flush_pending()
	await process_frame
	await process_frame
	_check(get_nodes_in_group("boss_add").size() == add_cap and spawner._reserved_boss_adds == 0, "reinforcements materialize from both launch bays")
	spawner._spawn_boss_reinforcements()
	_check(spawner._pending.is_empty(), "the live reinforcement cap prevents catch-up bursts")
	var encounter_before: int = spawner.director.encounter_number
	var regular_before: float = spawner.director.regular_elapsed
	spawner._physics_process(12.0)
	spawner.debug_skip_encounter()
	_check(spawner.director.encounter_number == encounter_before and spawner.director.regular_elapsed == regular_before, "boss time and debug skip cannot advance regular encounters")
	_check(get_nodes_in_group("boss").size() == 1, "a prolonged boss cannot overlap another milestone boss")
	spawner.set_physics_process(true)
	boss.set_physics_process(true)
	var elapsed_before: float = spawner.director.elapsed
	var position_before: Vector2 = boss.position
	paused = true
	await create_timer(0.1).timeout
	_check(spawner.director.elapsed == elapsed_before and boss.position == position_before, "pause freezes boss combat and the survival clock together")
	spawner.set_physics_process(false)
	boss.set_physics_process(false)
	paused = false
	var snapshot: Dictionary = spawner.get_debug_snapshot().boss
	_check(snapshot.phase == 2 and snapshot.adds == add_cap and snapshot.health == boss.life, "debug diagnostics expose actual boss health, phase and adds")
	target.free()
	var defeats := {"count": 0}
	var on_defeat := func(_id): defeats.count += 1
	_events.boss_defeated.connect(on_defeat)
	boss.hitByPlayerShot = true
	boss._hit_something(boss.life, false)
	boss._hit_something(1.0, false)
	_check(defeats.count == 1 and spawner.director.state == EncounterDirector.State.RECOVERY, "a boss death starts recovery exactly once")
	_check(not boss.combat_active and not boss.get_node("Sprite2D").visible and boss.get_node("ExplosionSprite").visible, "death stops attacks and plays the dedicated explosion")
	await process_frame
	await process_frame
	_check(get_nodes_in_group("boss_add").is_empty() and _shots().is_empty() and spawner._reserved_slots == 0, "boss defeat retires reinforcements and enemy projectiles safely")
	spawner._physics_process(7.99)
	_check(spawner.director.state == EncounterDirector.State.RECOVERY, "recovery keeps spawning suspended for eight seconds")
	spawner._physics_process(0.01)
	_check(spawner.director.state == EncounterDirector.State.REGULAR and spawner.director.encounter_number == encounter_before + 1, "a fresh normal encounter follows the recovery window")
	_check(is_equal_approx(spawner.director.regular_elapsed, regular_before), "recovery adds no regular scheduling time")
	boss.free()
	spawner.director.regular_elapsed = spawner.director.next_boss_at - 0.01
	spawner._physics_process(0.01)
	await process_frame
	await process_frame
	spawner._physics_process(0.5)
	await process_frame
	await process_frame
	_check(spawner.director.state == EncounterDirector.State.BOSS and spawner._boss != boss, "the single-boss catalog can launch a new fight after five more regular minutes")
	spawner.stop_run()
	_check(not spawner._boss.combat_active, "stopping the run disables the boss immediately")
	_events.boss_defeated.disconnect(on_defeat)
	spawner.free()
	await process_frame

func _test_cancellation() -> void:
	var spawner = _make_spawner()
	spawner._physics_process(300.0)
	spawner.stop_run()
	await process_frame
	_check(get_nodes_in_group("boss").is_empty(), "run stop cancels deferred boss materialization")
	spawner.free()
	spawner = _make_spawner()
	var scene = load("res://scenes/enemies/drone.tscn")
	for index in 70:
		spawner.queue_enemy(scene.instantiate())
	await process_frame
	await process_frame
	_check(spawner._active_enemy_count() == 70, "the boss-entry fixture fills the normal body cap")
	await _start_boss(spawner)
	_check(spawner._active_enemy_count() == 1, "retirement frees normal bodies before materializing the boss at a full cap")
	for index in 10:
		spawner._spawn_boss_reinforcements()
	spawner._flush_pending()
	spawner.stop_run()
	await process_frame
	await process_frame
	_check(spawner._reserved_slots == 0 and get_nodes_in_group("boss_add").is_empty(), "run stop cancels both pending and already-deferred reinforcements")
	_check(not spawner._boss.combat_active and _shots().is_empty(), "run stop leaves no active boss attacks or enemy projectiles")
	spawner.free()

func _test_partner_death() -> void:
	_globals.coop = true
	var world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var spawner = world.get_node("waveGenerator")
	spawner.set_physics_process(false)
	spawner.enemy_spawned.connect(_freeze)
	spawner.director.regular_elapsed = 299.99
	spawner.debug_start_boss()
	await process_frame
	await process_frame
	var boss = spawner._boss
	world.get_node("player2").free()
	world._on_player_died()
	_check(spawner._running and boss.combat_active and boss.max_life == 1040.0, "one partner's death preserves the fight and its original co-op health")
	world.get_node("player").free()
	world._on_player_died()
	_check(not spawner._running and not boss.combat_active, "the run and boss stop only after the last player dies")
	world.free()
	await process_frame

func _seeded_trace(seed_value: int, noise: bool) -> Array[String]:
	var spawner = _make_spawner(seed_value)
	spawner.director.elapsed = 299.99
	spawner.director.regular_elapsed = 299.99
	if noise:
		for index in 30:
			randf()
			spawner.director.random.drops.randf()
			spawner.director.random.upgrades.randf()
	spawner._physics_process(0.01)
	await process_frame
	await process_frame
	spawner._physics_process(0.5)
	await process_frame
	await process_frame
	var boss = spawner._boss
	boss._physics_process(2.0)
	boss._hit_something(boss.max_life * 0.75, false)
	_check(boss.phase == 1 and boss._visual == "open_bays", "one large hit crosses the single threshold without losing the hangar opening")
	boss._physics_process(0.78)
	_check(boss._visual == "core_transition", "the core opens after the hangars before phase two")
	boss._physics_process(0.96)
	var trace: Array[String] = ["%s|%s|%s" % [spawner._boss_data.id, boss._movement_leg, boss.position]]
	for index in 3:
		spawner._spawn_boss_reinforcements()
	for item in spawner._pending:
		trace.append("%s|%s|%s" % [item.context.movement_seed, item.position, item.at])
	spawner.stop_run()
	spawner.free()
	await process_frame
	return trace

func _test_debug_shortcut(coop: bool) -> void:
	var main := Node.new()
	root.add_child(main)
	main.set_script(load("res://scenes/main/main.gd"))
	main.process_mode = Node.PROCESS_MODE_ALWAYS
	main.worldScreen = true
	var world := Node2D.new()
	world.name = "world"
	main.add_child(world)
	var spawner = _make_spawner(81, coop, world)
	spawner.name = "waveGenerator"
	var key := InputEventKey.new()
	key.keycode = KEY_F12
	key.pressed = true
	_check(key.is_action_pressed("debug_boss"), "F12 maps to the boss shortcut")
	_globals.Debug = false
	main._input(key)
	_check(spawner.director.state == EncounterDirector.State.REGULAR, "F12 is disabled outside debug mode")
	_globals.Debug = true
	main._transitioning = true
	main._input(key)
	_check(spawner.director.state == EncounterDirector.State.REGULAR, "F12 cannot launch during a screen transition")
	main._transitioning = false
	paused = true
	main._input(key)
	_check(spawner.director.state == EncounterDirector.State.REGULAR and paused, "F12 cannot launch or resume a paused game")
	paused = false
	var inspector_key := InputEventKey.new()
	inspector_key.keycode = KEY_F10
	inspector_key.pressed = true
	main._input(inspector_key)
	main._input(key)
	_check(spawner.director.state == EncounterDirector.State.REGULAR and paused, "F12 leaves the paused full inspector unchanged")
	main._input(inspector_key)
	spawner._budget_left = 1000.0
	spawner._schedule_formation()
	var player = load("res://scenes/player/player.tscn").instantiate()
	world.add_child(player)
	player.set_physics_process(false)
	player.apply_upgrade(load("res://data/upgrades/damage.tres"))
	_globals.score = 1234
	var elapsed: float = spawner.director.elapsed
	var regular: float = spawner.director.regular_elapsed
	var danger: float = spawner.director.danger()
	main._input(key)
	_check(spawner.director.state == EncounterDirector.State.BOSS and spawner._pending.is_empty(), "F12 immediately selects the boss and cancels normal formations")
	_check(spawner.director.elapsed == elapsed and spawner.director.regular_elapsed == regular and spawner.director.danger() == danger, "debug launch does not invent survival/regular time or danger")
	_check(_globals.score == 1234 and player.get_debug_snapshot().ranks.DAMAGE == 1, "debug launch preserves score and the current player build")
	var random_state: int = spawner.director.random.encounters.state
	key.echo = true
	main._input(key)
	key.echo = false
	main._input(key)
	_check(spawner.director.random.encounters.state == random_state, "held or repeated F12 cannot reroll a pending boss")
	await process_frame
	await process_frame
	_check(is_instance_valid(spawner._boss) and get_nodes_in_group("boss").size() == 1, "F12 materializes exactly one boss")
	_check(spawner._boss.max_life == (1040.0 if coop else 650.0), "debug launch retains the correct solo/co-op boss health")
	spawner._boss._physics_process(2.0)
	spawner._boss._hit_something(spawner._boss.life, false)
	main._input(key)
	_check(spawner.director.state == EncounterDirector.State.RECOVERY, "F12 cannot overlap a fight with its recovery window")
	_check(spawner.director.next_boss_at == regular + 300.0, "a debug boss still schedules the next natural boss normally")
	spawner.stop_run()
	main._input(key)
	_check(not spawner._running and spawner.director.state == EncounterDirector.State.RECOVERY, "F12 cannot restart a stopped run")
	main.free()
	await process_frame

func _run() -> void:
	_globals = root.get_node("global")
	_events = root.get_node("Events")
	_globals.Debug = true
	var data = load("res://data/bosses/dread_ark.tres")
	_check(data.is_valid(), "the shipped Dread Ark resource is valid")
	await _test_fight(false)
	await _test_fight(true)
	await _test_cancellation()
	await _test_partner_death()
	var trace := await _seeded_trace(81, false)
	_check(trace == await _seeded_trace(81, true), "identical seeds reproduce boss movement and reinforcements despite cosmetic/reward RNG noise")
	_check(trace != await _seeded_trace(82, false), "different run seeds produce different boss reinforcement traces")
	await _test_debug_shortcut(false)
	await _test_debug_shortcut(true)
	await process_frame
	print("Boss encounters: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)
