class_name WaveSpawner
extends Node2D

@export var catalog: WaveCatalog
@export var formation_gap: float = 0.2

var wave_index := 0
var _rule_timers: Array[Timer] = []
var _master: Timer
var _formation_timer: Timer

func _ready() -> void:
	if catalog == null:
		catalog = load("res://data/waves/wave_catalog.tres")
	_master = Timer.new()
	_master.one_shot = true
	_master.timeout.connect(_on_master_timeout)
	add_child(_master)
	_formation_timer = Timer.new()
	_formation_timer.one_shot = true
	_formation_timer.wait_time = formation_gap
	add_child(_formation_timer)
	_apply_wave(0)

func _apply_wave(index: int) -> void:
	if catalog == null or catalog.waves.is_empty():
		return
	wave_index = clampi(index, 0, catalog.waves.size() - 1)
	global.wave = wave_index + 1
	Events.wave_changed.emit(global.wave)
	var wave: WaveDefinition = catalog.waves[wave_index]
	_clear_rule_timers()
	for rule in wave.rules:
		if rule == null or rule.scene == null:
			continue
		var timer := Timer.new()
		timer.wait_time = maxf(rule.interval, 0.05)
		timer.timeout.connect(_on_rule_timeout.bind(rule))
		add_child(timer)
		timer.start()
		_rule_timers.append(timer)
	_master.wait_time = wave.duration
	_master.start()

func _clear_rule_timers() -> void:
	for t in _rule_timers:
		t.stop()
		t.queue_free()
	_rule_timers.clear()

func _on_rule_timeout(rule: SpawnRule) -> void:
	var count := maxi(rule.formation, 1)
	var center := _random_lane(rule.spawn_min, rule.spawn_max)
	for i in count:
		var lane := center + i - int(count / 2.0)
		_spawn_at(rule.scene, lane)
		if i < count - 1:
			_formation_timer.start()
			await _formation_timer.timeout

func _random_lane(spawn_min: int, spawn_max: int) -> int:
	if spawn_max < spawn_min:
		spawn_max = spawn_min
	return randi_range(spawn_min, spawn_max)

func _spawn_at(packed: PackedScene, lane: int) -> void:
	lane = clampi(lane, 0, 11)
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
