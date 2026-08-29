class_name WaveSpawner
extends Node2D

@export var catalog: WaveCatalog

const LANE_COUNT := 12
const SOLO_ENEMY_CAP := 45
const COOP_ENEMY_CAP := 60

var wave_index := 0
var _master: Timer
var _wave_generation := 0

func _ready() -> void:
	if catalog == null:
		catalog = load("res://data/waves/wave_catalog.tres")
	_master = Timer.new()
	_master.one_shot = true
	_master.timeout.connect(_on_master_timeout)
	add_child(_master)
	_apply_wave(0)

func _apply_wave(index: int) -> void:
	if catalog == null or catalog.waves.is_empty():
		return
	_wave_generation += 1
	wave_index = clampi(index, 0, catalog.waves.size() - 1)
	global.wave = wave_index + 1
	Events.wave_changed.emit(global.wave)
	var wave: WaveDefinition = catalog.waves[wave_index]
	_master.stop()
	for rule in wave.rules:
		if rule == null or rule.scene == null:
			continue
		_run_rule(rule, _wave_generation)
	_master.wait_time = wave.duration
	_master.start()

func _run_rule(rule: SpawnRule, generation: int) -> void:
	if rule.start_delay > 0.0:
		await get_tree().create_timer(rule.start_delay, false).timeout
	if generation != _wave_generation:
		return
	var end_time := Time.get_ticks_msec() + int(maxf(rule.active_duration, 0.0) * 1000.0)
	var interval := maxf(rule.interval, 0.05)
	if global.coop and rule.formation < 4 and interval < rule.active_duration:
		interval *= 0.9
	var cycle := 0
	while generation == _wave_generation and Time.get_ticks_msec() < end_time:
		await _spawn_formation(rule, generation, cycle, end_time)
		cycle += 1
		var remaining := float(end_time - Time.get_ticks_msec()) / 1000.0
		if generation != _wave_generation or remaining <= 0.0:
			return
		await get_tree().create_timer(minf(interval, remaining), false).timeout

func _spawn_formation(rule: SpawnRule, generation: int, cycle: int, end_time: int) -> void:
	var count := maxi(rule.formation, 1)
	if global.coop and count >= 4:
		count += 1
	var lanes := _formation_lanes(rule, count, cycle)
	for i in range(lanes.size()):
		if generation != _wave_generation or Time.get_ticks_msec() >= end_time:
			return
		if _active_enemy_count() >= _enemy_cap():
			return
		_spawn_at(rule.scene, lanes[i])
		if i < lanes.size() - 1 and rule.spawn_gap > 0.0:
			await get_tree().create_timer(rule.spawn_gap, false).timeout

func _formation_lanes(rule: SpawnRule, requested_count: int, cycle: int) -> Array[int]:
	var minimum := clampi(mini(rule.spawn_min, rule.spawn_max), 0, LANE_COUNT - 1)
	var maximum := clampi(maxi(rule.spawn_min, rule.spawn_max), 0, LANE_COUNT - 1)
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
	var lanes: Array[int] = []
	var left := 0
	var right := available.size() - 1
	var from_left := cycle % 2 == 0
	while lanes.size() < count:
		if from_left:
			lanes.append(available[left])
			left += 1
		else:
			lanes.append(available[right])
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

func _active_enemy_count() -> int:
	return get_tree().get_nodes_in_group("enemy").size()

func _enemy_cap() -> int:
	return COOP_ENEMY_CAP if global.coop else SOLO_ENEMY_CAP

func _spawn_at(packed: PackedScene, lane: int) -> void:
	lane = clampi(lane, 0, LANE_COUNT - 1)
	var marker := get_node_or_null("spawnPos" + str(lane))
	if marker == null:
		return
	var enemy = packed.instantiate()
	enemy.position = marker.global_position
	add_child(enemy)

func _on_master_timeout() -> void:
	goto_Next_Wave()

func goto_Previous_Wave() -> void:
	if wave_index > 0:
		_apply_wave(wave_index - 1)

func goto_Next_Wave() -> void:
	if wave_index < catalog.waves.size() - 1:
		_apply_wave(wave_index + 1)
	else:
		_apply_wave(wave_index)
