class_name WaveSpawner
extends Node2D

@export var catalog: WaveCatalog
@export var config: WaveSpawnerConfig

var wave_index := 0
var _master: Timer
var _wave_generation := 0
var _endless_cycle := 0
var _active_enemies: Dictionary[int, bool] = {}
var _movement_seed := 0
var _movement_seed_overridden := false

func _ready() -> void:
	if catalog == null or config == null:
		push_error("WaveSpawner requires a catalog and a WaveSpawnerConfig.")
		return
	if not config.is_valid():
		push_error("WaveSpawnerConfig contains invalid difficulty, pacing, cap, or elite values.")
		return
	if not _has_all_spawn_markers():
		return
	if not _movement_seed_overridden:
		_movement_seed = config.movement_seed
	_master = Timer.new()
	_master.one_shot = true
	_master.timeout.connect(_on_master_timeout)
	add_child(_master)
	_apply_wave(0)

func _apply_wave(index: int) -> void:
	if catalog == null or catalog.waves.is_empty():
		return
	_wave_generation += 1
	_master.stop()
	wave_index = clampi(index, 0, catalog.waves.size() - 1)
	global.wave = wave_index + 1
	Events.wave_changed.emit(global.wave)
	var wave: WaveDefinition = catalog.waves[wave_index]
	if wave == null or not wave.is_valid(config.lane_count):
		push_error("Wave %d contains an invalid definition or spawn rule." % (wave_index + 1))
		return
	var timeline_scale := _timeline_scale(wave)
	for rule_index in range(wave.rules.size()):
		var rule: SpawnRule = wave.rules[rule_index]
		if rule == null or rule.scene == null:
			continue
		_run_rule(rule, rule_index, _wave_generation, wave.difficulty, timeline_scale)
	_master.wait_time = config.wave_duration + config.inter_wave_delay
	_master.start()

func set_movement_seed(value: int) -> void:
	_movement_seed = value
	_movement_seed_overridden = true

func _run_rule(rule: SpawnRule, rule_index: int, generation: int, difficulty: float, timeline_scale: float) -> void:
	var start_delay := rule.start_delay * timeline_scale
	if start_delay > 0.0:
		await get_tree().create_timer(start_delay, false).timeout
	if generation != _wave_generation:
		return
	var active_duration := maxf(rule.active_duration * timeline_scale, 0.0)
	if active_duration <= 0.0:
		return
	var active_timer := get_tree().create_timer(active_duration, false)
	var interval := maxf(rule.interval * timeline_scale * _pace_multiplier(difficulty) * config.spawn_interval_multiplier, 0.05)
	if global.coop and rule.formation < 4 and interval < active_duration:
		interval *= 0.9
	var cycle := 0
	var elites_remaining := maxi(rule.elite_count + _endless_elite_bonus(rule), 0)
	var next_spawn_elapsed := 0.0
	while generation == _wave_generation and active_timer.time_left > 0.0:
		var elapsed := active_duration - active_timer.time_left
		if elapsed < next_spawn_elapsed:
			await get_tree().create_timer(minf(next_spawn_elapsed - elapsed, active_timer.time_left), false).timeout
			if generation != _wave_generation or active_timer.time_left <= 0.0:
				return
		var elite_spawned := await _spawn_formation(rule, rule_index, generation, cycle, active_timer, difficulty, elites_remaining > 0, timeline_scale)
		if elite_spawned:
			elites_remaining -= 1
		cycle += 1
		next_spawn_elapsed += interval
		elapsed = active_duration - active_timer.time_left
		if next_spawn_elapsed <= elapsed:
			next_spawn_elapsed = elapsed

func _spawn_formation(rule: SpawnRule, rule_index: int, generation: int, cycle: int, active_timer: SceneTreeTimer, difficulty: float, can_spawn_elite: bool, timeline_scale: float) -> bool:
	var count := maxi(rule.formation + _endless_formation_bonus(rule), 1)
	if global.coop and count >= 4:
		count += 1
	var lanes := _formation_lanes(rule, count, cycle)
	var spawn_elite := can_spawn_elite and _active_elite_count() < 3
	for i in range(lanes.size()):
		if generation != _wave_generation or active_timer.time_left <= 0.0:
			return false
		if _active_enemy_count() >= _enemy_cap():
			return false
		_spawn_at(rule, rule_index, cycle, lanes[i], i, difficulty, spawn_elite and i == 0, i * rule.spawn_gap * timeline_scale)
		if i < lanes.size() - 1 and rule.spawn_gap > 0.0:
			await get_tree().create_timer(minf(rule.spawn_gap * timeline_scale, active_timer.time_left), false).timeout
	return spawn_elite

func _timeline_scale(wave: WaveDefinition) -> float:
	return config.wave_duration / wave.duration

func _formation_lanes(rule: SpawnRule, requested_count: int, cycle: int) -> Array[int]:
	var minimum := clampi(mini(rule.spawn_min, rule.spawn_max), 0, config.lane_count - 1)
	var maximum := clampi(maxi(rule.spawn_min, rule.spawn_max), 0, config.lane_count - 1)
	var available: Array[int] = []
	for lane in range(minimum, maximum + 1):
		available.append(lane)
	var count := mini(maxi(requested_count, 1), available.size())
	match rule.pattern:
		SpawnRule.Pattern.LINE:
			return _line_lanes(available, count, maxi(rule.lane_spacing, 1))
		SpawnRule.Pattern.V:
			return _v_lanes(available, count)
		SpawnRule.Pattern.ALTERNATING_EDGES:
			return _alternating_edge_lanes(available, count, cycle)
		SpawnRule.Pattern.SCATTER:
			available.shuffle()
			available.resize(count)
			return available
		SpawnRule.Pattern.OFFSET_GROUP:
			return _offset_group_lanes(available, count, maxi(rule.lane_spacing, 1), cycle)
		SpawnRule.Pattern.CENTER_OUT:
			return _center_out_lanes(available, count)
		SpawnRule.Pattern.EDGE_IN:
			return _edge_in_lanes(available, count)
		SpawnRule.Pattern.SWEEP:
			return _sweep_lanes(available, count, cycle)
		SpawnRule.Pattern.GAP_WALL:
			return _gap_wall_lanes(available, count, cycle)
		_:
			return [available.pick_random()]

func _line_lanes(available: Array[int], count: int, spacing: int) -> Array[int]:
	while count > 1 and 1 + (count - 1) * spacing > available.size():
		count -= 1
	var maximum_start := available.size() - 1 - (count - 1) * spacing
	var start := randi_range(0, maximum_start)
	var lanes: Array[int] = []
	for i in range(count):
		lanes.append(available[start + i * spacing])
	return lanes

func _v_lanes(available: Array[int], count: int) -> Array[int]:
	var block := _line_lanes(available, count, 1)
	var lanes: Array[int] = []
	var left := int((block.size() - 1) / 2.0)
	var right := left + 1
	lanes.append(block[left])
	while lanes.size() < block.size():
		if right < block.size():
			lanes.append(block[right])
			right += 1
		if left > 0 and lanes.size() < block.size():
			left -= 1
			lanes.append(block[left])
	return lanes

func _alternating_edge_lanes(available: Array[int], count: int, cycle: int) -> Array[int]:
	var cluster_size := mini(available.size(), count + 1)
	var cluster_start := randi_range(0, available.size() - cluster_size)
	var cluster: Array[int] = []
	for i in range(cluster_size):
		cluster.append(available[cluster_start + i])
	var lanes: Array[int] = []
	var left := 0
	var right := cluster.size() - 1
	var from_left := cycle % 2 == 0
	while lanes.size() < count:
		if from_left:
			lanes.append(cluster[left])
			left += 1
		else:
			lanes.append(cluster[right])
			right -= 1
		from_left = not from_left
	return lanes

func _offset_group_lanes(available: Array[int], count: int, spacing: int, cycle: int) -> Array[int]:
	while count > 1 and 1 + (count - 1) * spacing > available.size():
		count -= 1
	var maximum_start := available.size() - 1 - (count - 1) * spacing
	var start := 0 if cycle % 2 == 0 else maximum_start
	var lanes: Array[int] = []
	for i in range(count):
		lanes.append(available[start + i * spacing])
	return lanes

func _center_out_lanes(available: Array[int], count: int) -> Array[int]:
	var lanes: Array[int] = []
	var left := int((available.size() - 1) / 2.0)
	var right := left + 1
	lanes.append(available[left])
	while lanes.size() < count:
		if right < available.size():
			lanes.append(available[right])
			right += 1
		if left > 0 and lanes.size() < count:
			left -= 1
			lanes.append(available[left])
	return lanes

func _edge_in_lanes(available: Array[int], count: int) -> Array[int]:
	var lanes: Array[int] = []
	var left := 0
	var right := available.size() - 1
	while lanes.size() < count and left <= right:
		lanes.append(available[left])
		left += 1
		if left <= right and lanes.size() < count:
			lanes.append(available[right])
			right -= 1
	return lanes

func _sweep_lanes(available: Array[int], count: int, cycle: int) -> Array[int]:
	var maximum_start := available.size() - count
	var start := _ping_pong_index(maximum_start, cycle)
	var lanes: Array[int] = []
	for i in range(count):
		lanes.append(available[start + i])
	return lanes

func _gap_wall_lanes(available: Array[int], count: int, cycle: int) -> Array[int]:
	if available.size() <= 2:
		return _sweep_lanes(available, count, cycle)
	var gap_size := 2
	var spawn_count := mini(count, available.size() - gap_size)
	var gap_start := _ping_pong_index(available.size() - gap_size, cycle)
	var lanes: Array[int] = []
	for i in range(available.size()):
		if i < gap_start or i >= gap_start + gap_size:
			lanes.append(available[i])
			if lanes.size() == spawn_count:
				break
	return lanes

func _ping_pong_index(maximum: int, cycle: int) -> int:
	if maximum <= 0:
		return 0
	var period := maximum * 2
	var phase := cycle % period
	return phase if phase <= maximum else period - phase

func _active_enemy_count() -> int:
	return _active_enemies.size()

func _active_elite_count() -> int:
	var count := 0
	for elite in _active_enemies.values():
		if elite:
			count += 1
	return count

func _enemy_cap() -> int:
	return config.coop_enemy_cap if global.coop else config.solo_enemy_cap

func _spawn_at(rule: SpawnRule, rule_index: int, cycle: int, lane: int, formation_index: int, difficulty: float, elite: bool, movement_time_offset: float) -> void:
	lane = clampi(lane, 0, config.lane_count - 1)
	var marker := get_node_or_null("spawnPos" + str(lane)) as Node2D
	if marker == null:
		return
	var enemy := rule.scene.instantiate()
	if enemy is Enemy:
		var health_multiplier := lerpf(1.0, _durability_health_cap(enemy.definition), _difficulty_progress(difficulty)) * _endless_health_multiplier()
		var context := EnemySpawnContext.new()
		context.health_multiplier = health_multiplier
		context.elite = elite
		context.elite_definition = config.elite_definition
		context.speed_multiplier = rule.speed_multiplier
		context.rule_health_multiplier = rule.health_multiplier
		context.movement_profile = rule.movement_profile_override
		context.formation_seed = _spawn_seed(rule_index, cycle, -1, -1)
		context.movement_seed = _spawn_seed(rule_index, cycle, lane, formation_index)
		context.movement_time_offset = movement_time_offset
		enemy.configure_spawn(context)
	enemy.position = marker.position
	add_child(enemy)
	if enemy is Enemy:
		_active_enemies[enemy.get_instance_id()] = elite
		enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy.get_instance_id()), CONNECT_ONE_SHOT)

func _spawn_seed(rule_index: int, cycle: int, lane: int, formation_index: int) -> int:
	var value := _movement_seed & 0x7fffffff
	for part in [wave_index, _endless_cycle, rule_index, cycle, lane, formation_index, int(global.coop)]:
		value = int((value * 1103515245 + int(part) * 12345 + 1013904223) & 0x7fffffff)
	return value

func _has_all_spawn_markers() -> bool:
	for lane in range(config.lane_count):
		if get_node_or_null("spawnPos" + str(lane)) is not Node2D:
			push_error("WaveSpawner is missing spawnPos%d." % lane)
			return false
	return true

func _difficulty_progress(difficulty: float) -> float:
	return clampf(inverse_lerp(config.difficulty_start, config.difficulty_end, difficulty), 0.0, 1.0)

func _pace_multiplier(difficulty: float) -> float:
	var wave_pace := lerpf(1.0, config.max_wave_pace_multiplier, _difficulty_progress(difficulty))
	var endless_pace := maxf(1.0 - _endless_cycle * config.pace_step, config.pace_cap)
	return wave_pace * endless_pace

func _endless_health_multiplier() -> float:
	return minf(1.0 + _endless_cycle * config.health_step, config.health_cap)

func _endless_formation_bonus(rule: SpawnRule) -> int:
	if not _is_endless_finale() or not rule.endless_formation_growth:
		return 0
	return mini(floori(float(_endless_cycle) / float(config.formation_step_cycles)), config.formation_bonus_cap)

func _endless_elite_bonus(rule: SpawnRule) -> int:
	if not _is_endless_finale() or not rule.endless_elite_growth:
		return 0
	return mini(floori(float(_endless_cycle) / float(config.elite_step_cycles)), config.elite_bonus_cap)

func _is_endless_finale() -> bool:
	return catalog != null and wave_index == catalog.waves.size() - 1 and _endless_cycle > 0

func _on_master_timeout() -> void:
	goto_Next_Wave()

func goto_Previous_Wave() -> void:
	if wave_index > 0:
		if wave_index <= config.loop_start_index:
			_endless_cycle = 0
		_apply_wave(wave_index - 1)

func goto_Next_Wave() -> void:
	if wave_index < catalog.waves.size() - 1:
		_apply_wave(wave_index + 1)
	else:
		_endless_cycle += 1
		_apply_wave(mini(config.loop_start_index, catalog.waves.size() - 1))

func _on_enemy_tree_exited(instance_id: int) -> void:
	_active_enemies.erase(instance_id)

func _durability_health_cap(definition: EnemyDefinition) -> float:
	match definition.durability:
		EnemyDefinition.Durability.FODDER:
			return 1.15
		EnemyDefinition.Durability.FIGHTER:
			return 1.25
		EnemyDefinition.Durability.SPECIALIST:
			return 1.3
		EnemyDefinition.Durability.HEAVY:
			return 1.3
		_:
			return 1.0
