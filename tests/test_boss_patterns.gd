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

func _stage(coop := false, seed_value := 42) -> Node2D:
	var stage := Node2D.new()
	root.add_child(stage)
	stage.add_child(load("res://scenes/combat/projectile_pool.gd").new())
	var target := Node2D.new()
	target.name = "Target"
	target.position = Vector2(320, 350)
	target.add_to_group("player")
	stage.add_child(target)
	var data = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.name = "Boss"
	boss.boss_data = data
	boss.run_coop = coop
	var context := EnemySpawnContext.new()
	context.movement_seed = seed_value
	boss.configure_spawn(context)
	boss.position = Vector2(320, 82)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss._physics_process(0.01)
	boss._physics_process(0.78)
	boss._movement_pause = 10000.0
	return stage

func _shots(boss: Variant) -> Array[Node]:
	var shots: Array[Node] = []
	for shot in get_nodes_in_group("enemy_Shot"):
		if not shot.get_meta("pooled", false) and shot.get_meta("boss_owner_id", 0) == boss.get_instance_id():
			if shot.is_physics_processing():
				shot.set_physics_process(false)
				shot.set_deferred("monitoring", false)
				shot.set_deferred("monitorable", false)
			shots.append(shot)
	return shots

func _start(boss: Variant, kind: int) -> void:
	boss._clear_missiles()
	boss._beam.stop()
	boss.attack = boss.Attack.IDLE
	boss._attack_left = 0.0
	var patterns: Array = boss.attack_patterns()
	for index in patterns.size():
		if patterns[index].kind == kind:
			boss._attack_cycle = index
			break
	boss._physics_process(0.001)

func _test_circular() -> void:
	for phase_index in 2:
		var stage := _stage()
		var boss = stage.get_node("Boss")
		boss.phase = phase_index
		_start(boss, BossAttackPattern.Kind.RINGS)
		_check(boss.attack == boss.Attack.CHARGE and _shots(boss).is_empty(), "ring charge remains harmless before emission")
		var gap: float = boss._gap_angle
		var initial_aim: float = boss._pattern_angle
		_check(is_equal_approx(absf(wrapf(gap - initial_aim, -PI, PI)), deg_to_rad(35.0)), "the initial opening is offset from the locked player position")
		boss._physics_process(0.6)
		for burst in boss._pattern.burst_count:
			if burst > 0:
				boss._clear_missiles()
				boss._physics_process(boss._pattern.burst_interval + 0.000001)
			var shots := _shots(boss)
			_check(shots.size() == (22 if phase_index == 0 else 29), "each ring omits the projectile slots inside its smaller opening")
			for shot in shots:
				var velocity := Vector2(shot.speedX, shot.speedY)
				_check(is_equal_approx(velocity.length(), 145.0 if phase_index == 0 else 165.0), "circular missiles use their slower readable speed")
				_check(absf(wrapf(velocity.angle() - (gap + burst * deg_to_rad(15.0)), -PI, PI)) > deg_to_rad(15.0), "the full 30-degree opening remains empty in every shifted ring")
				_check(shot.global_position.is_equal_approx(boss.get_node("MainMuzzle").global_position), "circular projectiles originate from the main cannon mouth")
		_start(boss, BossAttackPattern.Kind.RINGS)
		_check(signf(wrapf(boss._gap_angle - boss._pattern_angle, -PI, PI)) != signf(wrapf(gap - initial_aim, -PI, PI)), "successive ring attacks alternate the opening side")
		var directions: Array[float] = []
		for repeat_index in 2:
			_start(boss, BossAttackPattern.Kind.SPIRAL)
			boss._physics_process(0.6)
			var shots := _shots(boss)
			_check(shots.size() == 2, "spirals start with two opposed arms")
			var first_angle := Vector2(shots[0].speedX, shots[0].speedY).angle()
			_check(is_equal_approx(absf(wrapf(first_angle - Vector2(shots[1].speedX, shots[1].speedY).angle(), -PI, PI)), PI), "the spiral arms are 180 degrees apart")
			for burst in range(1, boss._pattern.burst_count):
				boss._clear_missiles()
				boss._physics_process(boss._pattern.burst_interval + 0.000001)
				shots = _shots(boss)
				_check(shots.size() == 2, "each spiral emission adds exactly two missiles")
				var angle := Vector2(shots[0].speedX, shots[0].speedY).angle()
				var change := wrapf(angle - first_angle, -PI, PI)
				_check(is_equal_approx(absf(change), deg_to_rad(12.0 if phase_index == 0 else 18.0)), "spiral emissions rotate by their authored angular step")
				if burst == 1:
					directions.append(signf(change))
				first_angle = angle
		_check(directions[0] == -directions[1], "successive spirals reverse rotation direction")
		stage.free()

func _test_cycles_and_cancellation() -> void:
	for coop in [false, true]:
		for phase_index in 2:
			var stage := _stage(coop)
			var boss = stage.get_node("Boss")
			boss.phase = phase_index
			_check(boss.max_life == (1040.0 if coop else 650.0), "the two phases preserve solo and co-op health")
			var sequence: Array[int] = []
			var launches := {"count": 0}
			boss.reinforcements_requested.connect(func(): launches.count += 1)
			for frame in 1800:
				var idle: bool = boss.attack == boss.Attack.IDLE
				var before := _shots(boss).size()
				boss._physics_process(1.0 / 60.0)
				if idle and boss.attack != boss.Attack.IDLE:
					sequence.append(boss._pattern.kind)
				if boss.attack in [boss.Attack.BEAM_CHARGE, boss.Attack.BEAM_FIRE, boss.Attack.BEAM_RECOVER]:
					_check(_shots(boss).size() == before, "beam states never emit new missiles")
				if sequence.size() == boss.attack_patterns().size() and boss.attack == boss.Attack.IDLE:
					break
			var expected := [1, 0, 2, 0, 3] if phase_index == 0 else [1, 0, 2, 4, 0, 3]
			_check(sequence == expected and launches.count == 1, "each phase completes its exact authored cycle with one drone launch")
			_start(boss, BossAttackPattern.Kind.SPIRAL)
			boss._physics_process(0.6)
			_check(not _shots(boss).is_empty(), "the cancellation check starts with live missiles")
			boss.stop_combat()
			boss._physics_process(10.0)
			_check(_shots(boss).is_empty() and not boss._beam.active and not boss.combat_active, "run stop cancels emission schedules and recycles boss missiles")
			stage.free()
	var stage := _stage()
	var boss = stage.get_node("Boss")
	_start(boss, BossAttackPattern.Kind.RINGS)
	boss._physics_process(0.6)
	var unrelated = load("res://scenes/combat/projectile_pool.gd").spawn(load("res://scenes/combat/mother_ship_shot.tscn"), Vector2(500, 200), stage)
	unrelated.set_physics_process(false)
	boss._hit_something(boss.max_life * 0.75, false)
	_check(boss.phase == 1 and boss.attack == boss.Attack.TRANSITION and _shots(boss).is_empty(), "a large hit triggers one half-health transition and clears missiles immediately")
	_check(not unrelated.get_meta("pooled", false), "phase cleanup preserves missiles belonging to other combatants")
	boss._physics_process(0.96)
	_check(boss.attack == boss.Attack.IDLE and boss._visual == "phase_3", "the single transition opens the core for phase two")
	_start(boss, BossAttackPattern.Kind.SPIRAL)
	boss._physics_process(0.6)
	var timer: float = boss._attack_left
	var count := _shots(boss).size()
	boss.set_physics_process(true)
	paused = true
	await create_timer(0.04).timeout
	_check(boss._attack_left == timer and _shots(boss).size() == count, "pause freezes spiral emission timing")
	paused = false
	boss.set_physics_process(false)
	boss._hit_something(boss.life, false)
	_check(boss.destroyed and _shots(boss).is_empty(), "boss death cancels all remaining pattern missiles")
	stage.free()

func _test_disarmed() -> void:
	var stage := _stage()
	var boss = stage.get_node("Boss")
	_start(boss, BossAttackPattern.Kind.RINGS)
	boss.get_node("PortCannon")._hit_something(1000.0)
	boss.get_node("StarboardCannon")._hit_something(1000.0)
	_check(boss.attack == boss.Attack.CHARGE, "destroying the cannons does not interrupt core patterns")
	boss._physics_process(0.6)
	_check(_shots(boss).size() == 22, "both destroyed cannons leave the circular emitter functional")
	_start(boss, BossAttackPattern.Kind.AIMED)
	_check(boss._pattern.kind == BossAttackPattern.Kind.SPIRAL, "a disarmed boss skips targeted salvos and advances its cycle")
	boss.phase = 1
	_start(boss, BossAttackPattern.Kind.BEAM)
	_check(boss._beam.offsets == PackedFloat32Array([0.0]) and boss._beam.warning, "the disarmed boss retains only its wide central beam")
	stage.free()

func _trace(seed_value: int, noise: bool) -> Array[String]:
	var stage := _stage(false, seed_value)
	var boss = stage.get_node("Boss")
	boss._movement_pause = 0.0
	var seen := {}
	var trace: Array[String] = []
	for frame in 900:
		if noise:
			randf()
		boss._physics_process(1.0 / 60.0)
		for shot in _shots(boss):
			if not seen.has(shot.get_instance_id()):
				seen[shot.get_instance_id()] = true
				trace.append("%d|%s|%.4f|%.4f|%.4f|%.4f" % [frame, boss.get_attack_pattern_name(), shot.position.x, shot.position.y, shot.speedX, shot.speedY])
	stage.free()
	return trace

func _test_data_and_timing() -> void:
	var data = load("res://data/bosses/dread_ark.tres")
	_check(data.phase_one_patterns.map(func(p): return p.kind) == [1, 0, 2, 0, 3], "phase one is authored as rings, salvos, spiral, salvos and drones")
	_check(data.phase_two_patterns.map(func(p): return p.kind) == [1, 0, 2, 4, 0, 3], "phase two adds a dedicated beam attack to the cycle")
	_check(data.phase_one_patterns[2].burst_count == 16 and data.phase_two_patterns[2].burst_count == 20, "spirals extend to sixteen and twenty emissions without changing their cadence")
	for property in ["projectile_count", "burst_count", "burst_interval", "projectile_speed", "telegraph_time", "recovery_time"]:
		var invalid = data.phase_one_patterns[0].duplicate()
		invalid.set(property, 0)
		_check(not invalid.is_valid(), "invalid pattern counts, speeds and timings are rejected")
	var invalid = data.duplicate()
	var illegal: Array[BossAttackPattern] = [data.phase_two_patterns[3]]
	invalid.phase_one_patterns = illegal
	_check(not invalid.is_valid(), "beam patterns cannot be placed in phase one")
	var stage := _stage()
	var boss = stage.get_node("Boss")
	_start(boss, BossAttackPattern.Kind.SPIRAL)
	boss._physics_process(0.6)
	boss._physics_process(0.305)
	_check(_shots(boss).size() == 8 and boss._burst_index == 4, "long frames preserve every scheduled spiral emission")
	boss.can_launch_reinforcements = func(): return false
	_start(boss, BossAttackPattern.Kind.DRONES)
	_check(boss._pattern.kind == BossAttackPattern.Kind.RINGS and boss.attack == boss.Attack.CHARGE, "a full reinforcement slot is skipped immediately instead of interrupting the cycle")
	stage.free()
	var trace := _trace(42, false)
	_check(trace == _trace(42, true), "the same seed reproduces pattern timing, origins and velocities despite cosmetic RNG noise")
	_check(trace != _trace(43, false), "different seeds vary the route and initial pattern direction")

func _run() -> void:
	_test_circular()
	await _test_cycles_and_cancellation()
	_test_disarmed()
	_test_data_and_timing()
	await process_frame
	print("Boss attack patterns: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)
