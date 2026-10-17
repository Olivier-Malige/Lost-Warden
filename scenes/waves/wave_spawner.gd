class_name WaveSpawner
extends Node2D

signal enemy_spawned(enemy: Enemy)

@export var catalog: WaveCatalog
@export var config: WaveSpawnerConfig

var director: EncounterDirector
var wave_index := 0
var _seed_override := -1
var _generation := 0
var _pending: Array[Dictionary] = []
var _secondary_pending: Array[Enemy] = []
var _reserved_slots := 0
var _reserved_elites := 0
var _reserved_families: Dictionary[StringName, int] = {}
var _definitions: Dictionary[PackedScene, EnemyDefinition] = {}
var _next_formation_at := 0.0
var _budget_left := 0.0
var _budget_rate := 1.0
var _formation_cycle := 0
var _run_coop := false
var _running := false
var _started := false
var _boss: Enemy
var _boss_data: BossDefinition
var _reserved_boss_adds := 0

func _ready() -> void:
	call_deferred("start_run")

func _exit_tree() -> void:
	for enemy in _secondary_pending:
		if is_instance_valid(enemy):
			enemy.free()
	_secondary_pending.clear()

func start_run() -> void:
	if _started:
		return
	if catalog == null or catalog.waves.is_empty() or config == null or not config.is_valid():
		push_error("WaveSpawner requires a valid encounter catalog and configuration.")
		return
	for lane in config.lane_count:
		if get_node_or_null("spawnPos%d" % lane) is not Node2D:
			push_error("WaveSpawner is missing spawnPos%d." % lane)
			return
	var ids: Array[StringName] = []
	for wave in catalog.waves:
		if wave == null or not wave.is_encounter_valid(config.lane_count) or wave.id in ids:
			push_error("Encounter definitions must be valid and have unique stable identifiers.")
			return
		ids.append(wave.id)
		for rule in wave.rules:
			var definition := _rule_definition(rule)
			if definition == null or definition.id == &"" or definition.threat_cost <= 0.0:
				push_error("Every encounter rule requires an identified enemy family with a positive threat cost.")
				return
	var streams := RunRandom.new(_seed_override) if _seed_override >= 0 else global.run_random
	director = EncounterDirector.new(streams)
	_run_coop = global.coop
	_started = true
	_running = true
	_begin_encounter()

func set_movement_seed(value: int) -> void:
	if not _running:
		_seed_override = value

func stop_run() -> void:
	_running = false
	if is_instance_valid(_boss):
		_boss.stop_combat()
		_clear_combat(true)
	_cancel_formations()

func _cancel_formations() -> void:
	_generation += 1
	for item in _pending:
		_release_reservation(item)
	_pending.clear()

func _physics_process(delta: float) -> void:
	if not _running:
		return
	director.advance(delta)
	_emit_run_time()
	if director.boss_due() and _begin_boss():
		return
	if director.state == EncounterDirector.State.BOSS:
		_flush_pending()
		return
	if director.state != EncounterDirector.State.REGULAR:
		return
	if director.encounter_left <= 0.000001:
		_begin_encounter()
		if not _running:
			return
	if director.elapsed + 0.000001 >= _next_formation_at:
		_schedule_formation()
	_flush_pending()

func _begin_boss(force := false) -> bool:
	var chosen := director.choose_boss(config.bosses, force)
	if chosen == null:
		return false
	_cancel_formations()
	_budget_left = 0.0
	_boss_data = chosen
	_clear_combat(false)
	call_deferred("_materialize_boss", chosen, _generation)
	return true

func _materialize_boss(data: BossDefinition, generation: int) -> void:
	if not _running or generation != _generation or director.state != EncounterDirector.State.BOSS:
		return
	_boss = data.scene.instantiate() as Enemy
	_boss.boss_data = data
	_boss.run_coop = _run_coop
	var context := EnemySpawnContext.new()
	context.movement_seed = director.random.enemies.randi()
	_boss.configure_spawn(context)
	_boss.position = Vector2(320, -60)
	_boss.defeated.connect(_on_boss_defeated)
	_boss.reinforcements_requested.connect(_spawn_boss_reinforcements)
	add_child(_boss)
	Events.boss_phase_thresholds_changed.emit(data.phase_thresholds)
	Events.boss_started.emit(data.id, data.display_name, _boss.max_life)
	enemy_spawned.emit(_boss)

func _on_boss_defeated() -> void:
	if not _running or director.state != EncounterDirector.State.BOSS:
		return
	_cancel_formations()
	_clear_combat(true)
	director.boss_defeated()
	Events.boss_defeated.emit(_boss_data.id)

# Retire combatants outside collision callbacks and recycle shots through their pool.
func _clear_combat(only_adds: bool) -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy == _boss or (only_adds and not enemy.is_in_group("boss_add")):
			continue
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.set_deferred("monitoring", false)
		enemy.set_deferred("monitorable", false)
		enemy.call_deferred("free")
	for shot in get_tree().get_nodes_in_group("enemy_Shot"):
		if not shot.get_meta("pooled", false):
			ProjectilePool.despawn(shot)

func _spawn_boss_reinforcements() -> void:
	if not _running or director.state != EncounterDirector.State.BOSS or not is_instance_valid(_boss) or _boss.destroyed:
		return
	var eligible: Array[SpawnRule] = []
	var weights := PackedFloat32Array()
	for rule in _boss_data.reinforcements:
		if rule.weight > 0.0 and _available_members(_rule_definition(rule)) > 0:
			eligible.append(rule)
			weights.append(rule.weight)
	if eligible.is_empty():
		return
	var rule := eligible[director.random.encounters.rand_weighted(weights)]
	var definition := _rule_definition(rule)
	var formation_size := ceili(rule.formation * (_boss_data.coop_reinforcement_multiplier if _run_coop else 1.0))
	var count := mini(formation_size, _available_members(definition))
	count = mini(count, maxi(_boss_reinforcement_cap() - get_tree().get_node_count_in_group("boss_add") - _reserved_boss_adds, 0))
	var formation_seed := director.random.enemies.randi()
	for index in count:
		var context := EnemySpawnContext.new()
		context.health_multiplier = _health_multiplier(definition)
		context.rule_health_multiplier = rule.health_multiplier
		context.speed_multiplier = director.speed_multiplier() * rule.speed_multiplier
		context.fire_delay_multiplier = director.fire_delay_multiplier()
		context.movement_profile = rule.movement_profile_override
		context.movement_seed = director.random.enemies.randi()
		context.formation_seed = formation_seed
		context.movement_time_offset = index * rule.spawn_gap
		var item := {
			"scene": rule.scene, "position": _boss.position + Vector2(-40 if index % 2 == 0 else 40, 16 + (index / 2) * 12),
			"context": context, "at": director.elapsed + index * rule.spawn_gap,
			"slots": definition.spawn_slots, "family": definition.id,
			"generation": _generation, "boss_add": true,
		}
		_reserve(item)
		_pending.append(item)

func _begin_encounter() -> void:
	var wave := director.choose_encounter(catalog.waves, config.lane_count)
	if wave == null:
		push_error("No encounter is eligible for the current danger.")
		stop_run()
		return
	wave_index = catalog.waves.find(wave)
	_budget_left = director.encounter_budget() * (config.coop_budget_multiplier if _run_coop else 1.0)
	_budget_rate = _budget_left / wave.duration
	_next_formation_at = director.elapsed
	_formation_cycle = 0
	global.wave = director.encounter_number
	Events.wave_changed.emit(global.wave)
	Events.encounter_started.emit(wave.id, global.wave)
	_emit_run_time()

func _emit_run_time() -> void:
	global.survival_time = director.elapsed
	Events.run_time_changed.emit(director.elapsed)

func get_debug_snapshot() -> Dictionary:
	if director == null:
		return {"running": false}
	var families := {}
	var live := 0
	var elites := 0
	for enemy in get_tree().get_nodes_in_group(&"enemy"):
		if enemy is not Enemy:
			continue
		var id := String(enemy.definition.id)
		if not families.has(id):
			families[id] = {"bodies": 0, "alive": 0, "elites": 0, "health": 0.0}
		families[id].bodies += 1
		if not enemy.destroyed:
			live += 1
			families[id].alive += 1
			families[id].health += maxf(enemy.life, 0.0)
			if enemy.elite:
				elites += 1
				families[id].elites += 1
	var rules: Array[Dictionary] = []
	if director.encounter:
		for rule in director.encounter.rules:
			var definition := _rule_definition(rule)
			var weight := rule.weight * definition.weight_at(director.danger()) / rule.interval
			var available := _available_members(definition)
			rules.append({
				"family": String(definition.id), "pattern": SpawnRule.Pattern.keys()[rule.pattern],
				"formation": rule.formation, "lanes": Vector2i(rule.spawn_min, rule.spawn_max),
				"cost": definition.threat_cost,
				"weight": weight, "available": available,
				"affordable": definition.threat_cost <= _budget_left,
				"eligible": weight > 0.0 and available > 0 and definition.threat_cost <= _budget_left,
			})
	var pending_entries := 0
	for count in _reserved_families.values():
		pending_entries += count
	var rng_states := {}
	for key in ["encounters", "enemies", "drops", "upgrades"]:
		rng_states[key] = director.random.get(key).state
	return {
		"running": _running, "coop": _run_coop, "seed": director.random.run_seed,
		"state": EncounterDirector.State.keys()[director.state],
		"elapsed": director.elapsed, "regular_elapsed": director.regular_elapsed,
		"danger": director.danger(), "danger_offset": director.danger_offset,
		"encounter": String(director.encounter.id) if director.encounter else "none",
		"encounter_number": director.encounter_number, "encounter_left": director.encounter_left,
		"recent": director.recent.duplicate(), "budget_left": _budget_left, "budget_rate": _budget_rate,
		"next_formation": maxf(_next_formation_at - director.elapsed, 0.0), "formation_cycle": _formation_cycle,
		"bodies": _active_enemy_count() - _reserved_slots, "reserved": _reserved_slots,
		"pending": pending_entries, "cap": _enemy_cap(),
		"alive": live, "elites": elites, "reserved_elites": _reserved_elites,
		"elite_cap": config.elite_cap, "families": families, "rules": rules,
		"health_scale": director.health_multiplier(), "speed_scale": director.speed_multiplier(),
		"fire_scale": director.fire_delay_multiplier(), "elite_chance": director.elite_chance(),
		"boss_in": maxf(director.next_boss_at - director.regular_elapsed, 0.0),
		"recovery_left": director.recovery_left, "rng_states": rng_states,
		"boss": _boss_snapshot(),
	}

func _boss_reinforcement_cap() -> int:
	return ceili(_boss_data.reinforcement_cap * (_boss_data.coop_reinforcement_multiplier if _run_coop else 1.0))

func _boss_snapshot() -> Dictionary:
	if not is_instance_valid(_boss) or _boss.destroyed:
		return {}
	return {"id": String(_boss_data.id), "name": _boss_data.display_name,
		"health": _boss.life, "maximum": _boss.max_life, "phase": _boss.phase + 1,
		"attack": _boss.Attack.keys()[_boss.attack],
		"cannons": _boss.get_cannon_snapshot(),
		"adds": get_tree().get_node_count_in_group("boss_add"),
		"reserved_adds": _reserved_boss_adds, "add_cap": _boss_reinforcement_cap()}

func _schedule_formation() -> void:
	var eligible: Array[SpawnRule] = []
	var weights := PackedFloat32Array()
	for rule in director.encounter.rules:
		var definition := _rule_definition(rule)
		var weight := rule.weight * definition.weight_at(director.danger()) / rule.interval
		if weight > 0.0 and definition.threat_cost <= _budget_left and _available_members(definition) > 0:
			eligible.append(rule)
			weights.append(weight)
	if eligible.is_empty():
		_next_formation_at = director.elapsed + 0.25
		return
	var rule := eligible[director.random.encounters.rand_weighted(weights)]
	var definition := _rule_definition(rule)
	var count := mini(rule.formation, floori(_budget_left / definition.threat_cost))
	count = mini(count, _available_members(definition))
	var lanes := _formation_lanes(rule, count, _formation_cycle)
	var formation_seed := director.random.enemies.randi()
	var elite_index := -1
	var promotion_chance := director.elite_chance()
	if definition.elite_eligible and promotion_chance > 0.0 and _active_elite_count() < config.elite_cap:
		for index in lanes.size():
			if director.random.enemies.randf() < promotion_chance:
				elite_index = index
				break
	for index in lanes.size():
		var lane := lanes[index]
		var marker := get_node("spawnPos%d" % lane) as Node2D
		var context := EnemySpawnContext.new()
		context.elite = index == elite_index
		context.elite_definition = config.elite_definition if context.elite else null
		context.health_multiplier = _health_multiplier(definition)
		context.speed_multiplier = rule.speed_multiplier * (1.0 if definition.durability == EnemyDefinition.Durability.HAZARD else director.speed_multiplier())
		context.fire_delay_multiplier = director.fire_delay_multiplier()
		context.rule_health_multiplier = rule.health_multiplier
		context.movement_profile = rule.movement_profile_override
		context.formation_seed = formation_seed
		context.movement_seed = director.random.enemies.randi()
		context.movement_time_offset = index * rule.spawn_gap
		var offset := Vector2.ZERO
		if rule.pattern == SpawnRule.Pattern.V:
			offset.y = -absf(lane - lanes[0]) * config.v_formation_depth
		var item := {
			"scene": rule.scene, "position": marker.position + offset,
			"context": context, "at": director.elapsed + index * rule.spawn_gap,
			"slots": definition.spawn_slots, "family": definition.id,
			"elite": context.elite,
			"generation": _generation,
		}
		_reserve(item)
		_pending.append(item)
	var cost := lanes.size() * definition.threat_cost
	_budget_left = maxf(_budget_left - cost, 0.0)
	_next_formation_at = director.elapsed + cost / _budget_rate
	_formation_cycle += 1

func _flush_pending() -> void:
	var index := 0
	while index < _pending.size():
		var item := _pending[index]
		if item.at <= director.elapsed + 0.000001:
			_pending.remove_at(index)
			call_deferred("_materialize", item)
		else:
			index += 1

func _materialize(item: Dictionary) -> void:
	_release_reservation(item)
	if not _running or item.generation != _generation:
		return
	var enemy := (item.scene as PackedScene).instantiate() as Enemy
	if item.get("boss_add", false):
		enemy.add_to_group("boss_add")
	enemy.configure_spawn(item.context)
	enemy.position = item.position
	add_child(enemy)
	enemy_spawned.emit(enemy)

# Debris shares the same reservation accounting as scheduled formations.
func queue_enemy(enemy: Enemy) -> bool:
	if not _running or director.state != EncounterDirector.State.REGULAR or _available_members(enemy.definition) < 1:
		enemy.call_deferred("free")
		return false
	var item := {"slots": enemy.definition.spawn_slots, "family": enemy.definition.id, "generation": _generation}
	_reserve(item)
	_secondary_pending.append(enemy)
	call_deferred("_add_secondary_enemy", enemy, item)
	return true

func _add_secondary_enemy(enemy: Enemy, item: Dictionary) -> void:
	_secondary_pending.erase(enemy)
	_release_reservation(item)
	if not _running or item.generation != _generation:
		enemy.free()
		return
	add_child(enemy)
	enemy_spawned.emit(enemy)

func _reserve(item: Dictionary) -> void:
	_reserved_slots += int(item.slots)
	if item.get("elite", false):
		_reserved_elites += 1
	if item.get("boss_add", false):
		_reserved_boss_adds += 1
	_reserved_families[item.family] = _reserved_families.get(item.family, 0) + 1

func _release_reservation(item: Dictionary) -> void:
	_reserved_slots -= int(item.slots)
	if item.get("elite", false):
		_reserved_elites -= 1
	if item.get("boss_add", false):
		_reserved_boss_adds -= 1
	_reserved_families[item.family] = _reserved_families.get(item.family, 0) - 1

func _active_enemy_count() -> int:
	return get_tree().get_node_count_in_group(&"enemy") + _reserved_slots

func _active_elite_count() -> int:
	var count := _reserved_elites
	for enemy in get_tree().get_nodes_in_group(&"elite"):
		if enemy is Enemy and not enemy.destroyed:
			count += 1
	return count

func _available_members(definition: EnemyDefinition) -> int:
	var count := maxi((_enemy_cap() - _active_enemy_count()) / definition.spawn_slots, 0)
	if definition.active_limit > 0:
		var active := get_tree().get_node_count_in_group(StringName("family_" + String(definition.id)))
		count = mini(count, maxi(definition.active_limit - active - _reserved_families.get(definition.id, 0), 0))
	return count

func _enemy_cap() -> int:
	return config.coop_enemy_cap if _run_coop else config.solo_enemy_cap

func _health_multiplier(definition: EnemyDefinition) -> float:
	if definition.durability == EnemyDefinition.Durability.HAZARD:
		return 1.0
	var coop_scale := 1.0
	if _run_coop:
		match definition.durability:
			EnemyDefinition.Durability.FODDER, EnemyDefinition.Durability.FIGHTER:
				coop_scale = config.coop_common_health_multiplier
			EnemyDefinition.Durability.SPECIALIST:
				coop_scale = config.coop_specialist_health_multiplier
			EnemyDefinition.Durability.HEAVY:
				coop_scale = config.coop_heavy_health_multiplier
	return coop_scale * director.health_multiplier()

func _rule_definition(rule: SpawnRule) -> EnemyDefinition:
	if _definitions.has(rule.scene):
		return _definitions[rule.scene]
	var state := rule.scene.get_state()
	for property in state.get_node_property_count(0):
		if state.get_node_property_name(0, property) == &"definition":
			var definition := state.get_node_property_value(0, property) as EnemyDefinition
			_definitions[rule.scene] = definition
			return definition
	return null

func goto_Previous_Wave() -> void:
	if director:
		director.danger_offset -= 0.2

func goto_Next_Wave() -> void:
	if director:
		director.danger_offset += 0.2

func debug_start_boss() -> void:
	if not global.Debug or not _running or get_tree().paused:
		return
	if director.state == EncounterDirector.State.REGULAR:
		_begin_boss(true)

func debug_skip_encounter() -> void:
	if not global.Debug or not _running or get_tree().paused:
		return
	if director.state != EncounterDirector.State.REGULAR:
		return
	_cancel_formations()
	_begin_encounter()

func _shuffle_lanes(lanes: Array[int]) -> void:
	for index in range(lanes.size() - 1, 0, -1):
		var other := director.random.encounters.randi_range(0, index)
		var lane := lanes[index]
		lanes[index] = lanes[other]
		lanes[other] = lane

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
			_shuffle_lanes(available)
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
			return [available[director.random.encounters.randi_range(0, available.size() - 1)]]

func _line_lanes(available: Array[int], count: int, spacing: int) -> Array[int]:
	while count > 1 and 1 + (count - 1) * spacing > available.size():
		count -= 1
	var maximum_start := available.size() - 1 - (count - 1) * spacing
	var start := director.random.encounters.randi_range(0, maximum_start)
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
	var cluster_start := director.random.encounters.randi_range(0, available.size() - cluster_size)
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
