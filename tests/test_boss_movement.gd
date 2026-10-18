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

func _boss(seed_value: int, phase_index := 0) -> Variant:
	var data = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	var context := EnemySpawnContext.new()
	context.movement_seed = seed_value
	boss.configure_spawn(context)
	boss.position = Vector2(320, 82)
	root.add_child(boss)
	boss.set_physics_process(false)
	boss.attack = boss.Attack.IDLE
	boss.phase = phase_index
	return boss

func _trace(seed_value: int, noise: bool) -> Array[Vector2]:
	var boss = _boss(seed_value)
	var trace: Array[Vector2] = []
	for tick in 1200:
		if noise:
			randf()
		boss._move_between_positions(1.0 / 60.0)
		if tick % 15 == 0:
			trace.append(boss.position)
	boss.free()
	return trace

func _run() -> void:
	var data = load("res://data/bosses/dread_ark.tres")
	_check(data.is_valid() and data.phase_thresholds == PackedFloat32Array([0.5]) and data.health == 650.0 and data.cannon_health == 90.0, "the boss has two phases at half health with unchanged durability")
	var boss = _boss(0)
	boss._move_between_positions(1.0 / 60.0)
	_check(boss._reposition_velocity.length() > 0.0 and boss._reposition_velocity.length() < 4.0, "repositioning accelerates from rest instead of jumping straight to cruise speed")
	var speed_values: Array[int] = []
	var paused_frames := 0
	var min_y := INF
	var max_y := -INF
	var direction_changes := 0
	var previous_direction := 1.0
	for tick in 1200:
		boss._move_between_positions(1.0 / 60.0)
		min_y = minf(min_y, boss.position.y)
		max_y = maxf(max_y, boss.position.y)
		var speed := roundi(boss._reposition_velocity.length())
		if speed not in speed_values:
			speed_values.append(speed)
		if boss._movement_pause > 0.0:
			paused_frames += 1
		if absf(boss._reposition_velocity.x) > 1.0:
			var direction := signf(boss._reposition_velocity.x)
			if direction != previous_direction:
				direction_changes += 1
			previous_direction = direction
		_check(absf(boss.position.x - 320.0) <= data.movement_ranges[0] + 0.01 and absf(boss.position.y - 82.0) <= data.vertical_movement_range + 0.01, "dynamic movement remains inside its phase's combat area")
	_check(speed_values.size() > 10 and paused_frames > 0, "the motion includes acceleration, braking and brief arrival rests")
	_check(max_y - min_y > 10.0 and direction_changes >= 3, "the boss changes height and lateral destination throughout combat")
	boss.free()
	var first := _trace(42, false)
	_check(first == _trace(42, true), "movement is reproducible despite cosmetic random noise")
	_check(first != _trace(43, false), "different movement seeds change the initial repositioning route")
	var peak_speeds: Array[float] = []
	for phase_index in 2:
		boss = _boss(0, phase_index)
		var peak := 0.0
		for tick in 120:
			boss._move_between_positions(1.0 / 60.0)
			peak = maxf(peak, boss._reposition_velocity.length())
		peak_speeds.append(peak)
		boss.free()
	_check(peak_speeds[0] < peak_speeds[1], "repositioning becomes faster in the second combat phase")
	boss = _boss(0, 1)
	for attack in [boss.Attack.BEAM_CHARGE, boss.Attack.BEAM_FIRE, boss.Attack.BEAM_RECOVER]:
		boss.attack = attack
		boss._reposition_velocity = Vector2(60, 12)
		var before: Vector2 = boss.position
		boss._move_between_positions(0.5)
		_check(boss.position == before and boss._reposition_velocity == Vector2.ZERO, "beam warning, firing and cooling lock both movement axes")
	boss.free()
	var invalid = data.duplicate()
	invalid.movement_acceleration = 0.0
	_check(not invalid.is_valid(), "movement data requires positive acceleration")
	invalid.movement_acceleration = 180.0
	invalid.movement_arrival_pause = -1.0
	_check(not invalid.is_valid(), "movement data rejects negative rest durations")
	await process_frame
	print("Boss movement: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)
