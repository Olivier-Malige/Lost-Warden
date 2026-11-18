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
var _combat_sequence := 0
var _boss: Enemy
var _boss_data: BossDefinition
var _reserved_boss_adds := 0
var _boss_clear_left := 0.0

func _ready() -> void:
	call_deferred("start_run")

func _exit_tree() -> void:
	_running = false
	_boss_clear_left = 0.0
	_generation += 1
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
	director = EncounterDirector.new(streams, config.enemy_health_curve)
	_run_coop = global.coop
	_started = true
	_running = true
	_begin_encounter()
	_next_formation_at = director.elapsed + config.initial_spawn_delay

func set_movement_seed(value: int) -> void:
	if not _running:
		_seed_override = value

func _next_combat_identity() -> StringName:
	_combat_sequence += 1
	return StringName("actor_%09d" % _combat_sequence)

func stop_run() -> void:
	_running = false
	_boss_clear_left = 0.0
	if is_instance_valid(_boss):
		_boss.stop_combat()
		_clear_combat(true)
	_cancel_formations()

func _cancel_formations() -> void:
	_generation += 1
	for item in _pending:
		_release_reservation(item)
	_pending.clear()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not _running:
		return
	director.advance(delta)
	_emit_run_time()
	if director.boss_due() and _begin_boss():
		return
	if director.state == EncounterDirector.State.BOSS_APPROACH:
		_advance_boss_approach(delta)
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
	queue_redraw()

func _begin_boss(force := false) -> bool:
	var chosen := director.choose_boss(config.bosses, force)
	if chosen == null:
		return false
	_cancel_formations()
	_budget_left = 0.0
	_boss_data = chosen
	if force:
		_clear_combat(false)
		call_deferred("_materialize_boss", chosen, _generation)
	else:
		_boss_clear_left = config.boss_approach_clear_time
	return true

func _advance_boss_approach(delta: float) -> void:
	var occupied := _active_enemy_count() > 0
	for shot in get_tree().get_nodes_in_group("enemy_Shot"):
		if not shot.get_meta("pooled", false) and not shot.is_queued_for_deletion():
			occupied = true
			break
	if occupied:
		_boss_clear_left = config.boss_approach_clear_time
		return
	_boss_clear_left = maxf(_boss_clear_left - delta, 0.0)
	if _boss_clear_left <= 0.000001:
		director.boss_entered()
		call_deferred("_materialize_boss", _boss_data, _generation)

func _materialize_boss(data: BossDefinition, generation: int) -> void:
	if not is_inside_tree() or is_queued_for_deletion() or get_parent().is_queued_for_deletion():
		return
	if not _running or generation != _generation or director.state != EncounterDirector.State.BOSS:
		return
	_boss = data.scene.instantiate() as Enemy
	_boss.boss_data = data
	_boss.run_coop = _run_coop
	_boss.can_launch_reinforcements = _can_launch_boss_reinforcements
	var context := EnemySpawnContext.new()
	context.combat_id = _next_combat_identity()
	context.movement_seed = director.random.enemies.randi()
	_boss.configure_spawn(context)
	_boss.position = Vector2(320, -60)
	_boss.defeated.connect(_on_boss_defeated)
	_boss.reinforcements_requested.connect(_spawn_boss_reinforcements)
	_boss.phase_transition_started.connect(_cancel_formations)
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

func _can_launch_boss_reinforcements() -> bool:
	if not _running or director.state != EncounterDirector.State.BOSS or not is_instance_valid(_boss) or _boss.destroyed:
		return false
	if _boss.attack in [_boss.Attack.BEAM_CHARGE, _boss.Attack.BEAM_FIRE, _boss.Attack.BEAM_RECOVER]:
		return false
	var slots := _boss_reinforcement_cap() - get_tree().get_node_count_in_group("boss_add") - _reserved_boss_adds
	for rule in _boss_data.reinforcements:
		var count := ceili(rule.formation * (_boss_data.coop_reinforcement_multiplier if _run_coop else 1.0))
		if rule.weight > 0.0 and slots >= count and _available_members(_rule_definition(rule)) >= count:
			return true
	return false

func _spawn_boss_reinforcements() -> void:
	if not _can_launch_boss_reinforcements():
		return
	var eligible: Array[SpawnRule] = []
	var weights := PackedFloat32Array()
	for rule in _boss_data.reinforcements:
		var required := ceili(rule.formation * (_boss_data.coop_reinforcement_multiplier if _run_coop else 1.0))
		if rule.weight > 0.0 and _available_members(_rule_definition(rule)) >= required and _boss_reinforcement_cap() - get_tree().get_node_count_in_group("boss_add") - _reserved_boss_adds >= required:
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
		context.combat_id = _next_combat_identity()
		context.health_multiplier = _health_multiplier(definition)
		context.rule_health_multiplier = rule.health_multiplier
		context.speed_multiplier = director.speed_multiplier() * rule.speed_multiplier
		context.fire_delay_multiplier = director.fire_delay_multiplier()
		context.movement_profile = rule.movement_profile_override
		context.movement_seed = director.random.enemies.randi()
		context.formation_seed = formation_seed
		context.movement_time_offset = index * rule.spawn_gap
		var item := {
			"scene": rule.scene, "position": _boss.position + Vector2(-40 if index % 2 == 0 else 40, 16 + floori(float(index) / 2.0) * 12),
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
		"survival_tier": director.survival_tier(), "survival_combat_time": director.survival_combat_time,
		"encounter_family": WaveDefinition.Family.keys()[director.encounter.family] if director.encounter else "NONE",
		"recent": director.recent.duplicate(), "budget_left": _budget_left, "budget_rate": _budget_rate,
		"next_formation": maxf(_next_formation_at - director.elapsed, 0.0), "formation_cycle": _formation_cycle,
		"bodies": _active_enemy_count() - _reserved_slots, "reserved": _reserved_slots,
		"pending": pending_entries, "cap": _enemy_cap(),
		"alive": live, "elites": elites, "reserved_elites": _reserved_elites,
		"elite_cap": config.elite_cap, "families": families, "rules": rules,
		"health_scale": director.health_multiplier(), "speed_scale": director.speed_multiplier(),
		"fire_scale": director.fire_delay_multiplier(), "elite_chance": director.elite_chance(),
		"boss_in": maxf(director.next_boss_at - director.regular_elapsed, 0.0),
		"boss_approach_clear_left": _boss_clear_left,
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
		"pattern": _boss.get_attack_pattern_name(),
		"cannons": _boss.get_cannon_snapshot(),
		"adds": get_tree().get_node_count_in_group("boss_add"),
		"reserved_adds": _reserved_boss_adds, "add_cap": _boss_reinforcement_cap()}

func _schedule_formation() -> void:
	var wave := director.encounter
	if wave.family == WaveDefinition.Family.DEBRIS:
		if _formation_cycle == 0:
			_schedule_debris(wave.rules[0])
			director.encounter_left = wave.duration
		return
	if wave.family == WaveDefinition.Family.REENTRY and _formation_cycle > 0:
		return
	if wave.family != WaveDefinition.Family.OPENING and _offensive_formations() >= (2 if director.survival_tier() >= 3 else 1):
		_next_formation_at = director.elapsed + 0.25
		return
	var eligible: Array[SpawnRule] = []
	var weights := PackedFloat32Array()
	for rule in wave.rules:
		if rule.minimum_combat_time > director.regular_elapsed or rule.minimum_survival_time > director.survival_combat_time:
			continue
		var definition := _rule_definition(rule)
		var weight := rule.weight * definition.weight_at(director.danger()) / rule.interval
		if wave.family != WaveDefinition.Family.OPENING:
			weight = rule.weight / rule.interval
		if wave.minimum_combat_time > 0.0 and _formation_cycle == 0 and rule != wave.rules[0]:
			continue
		if rule.reinforcement_scene:
			var escort := SpawnRule.new()
			escort.scene = rule.reinforcement_scene
			var escort_definition := _rule_definition(escort)
			if escort_definition == null or _available_members(escort_definition) < 4 or _budget_left < definition.threat_cost + 4.0 * escort_definition.threat_cost \
					or _enemy_cap() - _active_enemy_count() < definition.spawn_slots + 4 * escort_definition.spawn_slots:
				continue
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
	if wave.family == WaveDefinition.Family.REENTRY and count < rule.formation:
		_next_formation_at = director.elapsed + 0.25
		return
	var lanes := _formation_lanes(rule, count, _formation_cycle)
	var start := _pending.size()
	var formation_id := _combat_sequence + 1
	var formation_seed := director.random.enemies.randi()
	var elite_index := _elite_index(definition, lanes.size())
	var side := 1 if formation_seed % 2 == 0 else -1
	for index in lanes.size():
		var edge := rule.entry
		if edge == SpawnRule.Entry.SIDE or edge == SpawnRule.Entry.PINCER:
			var mirror := side * (-1 if edge == SpawnRule.Entry.PINCER and index % 2 == 1 else 1)
			edge = SpawnRule.Entry.LEFT if mirror > 0 else SpawnRule.Entry.RIGHT
		var marker := _entry_position(edge, lanes[index])
		if rule.entry == SpawnRule.Entry.PINCER and index % 2 == 1:
			marker.y = _entry_position(edge, lanes[index - 1]).y
		if rule.pattern == SpawnRule.Pattern.V and edge == SpawnRule.Entry.TOP:
			marker.y -= absf(lanes[index] - lanes[0]) * config.v_formation_depth
		var item := _queue_member(rule, definition, marker, index * rule.spawn_gap, formation_id, formation_seed, index == elite_index, edge)
		if rule.reinforcement_scene:
			item["squad"] = {}
	var cost := lanes.size() * definition.threat_cost
	if rule.reinforcement_scene:
		var commander := _pending[start]
		var extra_cost := _schedule_reinforcements(rule, commander.squad, cost, formation_id, formation_seed)
		if extra_cost <= 0.0:
			while _pending.size() > start:
				_release_reservation(_pending.pop_back())
			_next_formation_at = director.elapsed + 0.25
			return
		cost += extra_cost
	var heavy_escort := wave.family == WaveDefinition.Family.FLEET and definition.durability == EnemyDefinition.Durability.HEAVY
	if (heavy_escort or (wave.coordinated and director.survival_tier() >= 5)) and not rule.reinforcement_scene:
		var extra_cost := _schedule_followup(eligible, rule, cost, formation_id, formation_seed)
		if extra_cost <= 0.0:
			while _pending.size() > start:
				_release_reservation(_pending.pop_back())
			_next_formation_at = director.elapsed + 0.25
			return
		cost += extra_cost
	if elite_index >= 0:
		director.elite_due = false
	_budget_left = maxf(_budget_left - cost, 0.0)
	var interval := cost / _budget_rate
	if wave.family != WaveDefinition.Family.OPENING:
		interval = maxf(0.85 * director.formation_interval_scale(), interval)
	_next_formation_at = director.elapsed + interval
	_formation_cycle += 1

func _elite_index(definition: EnemyDefinition, count: int) -> int:
	if not definition.elite_eligible or count <= 0 or _active_elite_count() >= config.elite_cap:
		return -1
	if director.elite_due:
		return 0
	var chance := director.elite_chance()
	if director.encounter.family != WaveDefinition.Family.OPENING:
		chance = minf(0.4, chance + 0.06 + 0.015 * director.survival_tier())
	if chance > 0.0:
		for index in count:
			if director.random.enemies.randf() < chance:
				return index
	return -1

func _entry_position(edge: SpawnRule.Entry, lane: int) -> Vector2:
	var marker := get_node("spawnPos%d" % lane) as Node2D
	var arena := get_viewport_rect().size
	match edge:
		SpawnRule.Entry.LEFT:
			return Vector2((get_node("spawnPos0") as Node2D).position.x - 24.0, lerpf(78.0, 158.0, float(lane) / maxi(1, config.lane_count - 1)))
		SpawnRule.Entry.RIGHT:
			return Vector2((get_node("spawnPos%d" % (config.lane_count - 1)) as Node2D).position.x + 24.0, lerpf(78.0, 158.0, float(lane) / maxi(1, config.lane_count - 1)))
		SpawnRule.Entry.BOTTOM:
			return Vector2(marker.position.x, arena.y + 22.0)
	return marker.position

func _queue_member(rule: SpawnRule, definition: EnemyDefinition, marker: Vector2, delay: float, formation_id: int, formation_seed: int, elite: bool, edge := SpawnRule.Entry.TOP) -> Dictionary:
	var context := EnemySpawnContext.new()
	context.combat_id = _next_combat_identity()
	context.elite = elite
	context.elite_definition = config.elite_definition if elite else null
	context.health_multiplier = _health_multiplier(definition)
	context.speed_multiplier = rule.speed_multiplier * (1.0 if definition.durability == EnemyDefinition.Durability.HAZARD else director.speed_multiplier())
	context.fire_delay_multiplier = director.fire_delay_multiplier()
	context.rule_health_multiplier = rule.health_multiplier
	context.movement_profile = rule.movement_profile_override
	context.formation_seed = formation_seed
	context.movement_seed = director.random.enemies.randi()
	context.movement_time_offset = delay
	var item := {
		"scene": rule.scene, "position": marker, "context": context,
		"at": director.elapsed + delay + (1.0 if edge == SpawnRule.Entry.BOTTOM else 0.0),
		"edge": edge, "slots": definition.spawn_slots, "family": definition.id,
		"elite": elite, "formation": formation_id, "generation": _generation,
	}
	_reserve(item)
	_pending.append(item)
	return item

func _schedule_reinforcements(rule: SpawnRule, squad: Dictionary, cost: float, formation_id: int, formation_seed: int) -> float:
	var escort := SpawnRule.new()
	escort.scene = rule.reinforcement_scene
	var definition := _rule_definition(escort)
	var extra_cost := 4.0 * definition.threat_cost
	if _available_members(definition) < 4 or cost + extra_cost > _budget_left:
		return 0.0
	for index in 4:
		var edge := SpawnRule.Entry.LEFT if (index + formation_seed) % 2 == 0 else SpawnRule.Entry.RIGHT
		var item := _queue_member(escort, definition, _entry_position(edge, index * 3), 0.0, formation_id, formation_seed, false, edge)
		item.at = INF
		item["squad"] = squad
		item["reinforcement"] = true
		item["signal_delay"] = floori(index / 2.0)
	return extra_cost

func _schedule_followup(rules: Array[SpawnRule], primary: SpawnRule, cost: float, formation_id: int, formation_seed: int) -> float:
	for rule in rules:
		if rule == primary or rule.reinforcement_scene or rule.entry == SpawnRule.Entry.BOTTOM:
			continue
		var definition := _rule_definition(rule)
		if definition.durability == EnemyDefinition.Durability.HEAVY:
			continue
		var count := mini(2, rule.formation)
		var extra_cost := count * definition.threat_cost
		if _available_members(definition) < count or _budget_left < cost + extra_cost:
			continue
		var lanes := _formation_lanes(rule, count, _formation_cycle + 1)
		var edge := rule.entry
		if edge == SpawnRule.Entry.SIDE or edge == SpawnRule.Entry.PINCER:
			edge = SpawnRule.Entry.RIGHT if formation_seed % 2 == 0 else SpawnRule.Entry.LEFT
		for index in lanes.size():
			var delay := maxf(director.encounter.coordinated_delay, (primary.formation - 1) * primary.spawn_gap + 0.35)
			_queue_member(rule, definition, _entry_position(edge, lanes[index]), delay + index * rule.spawn_gap, formation_id, formation_seed, false, edge)
		return lanes.size() * definition.threat_cost
	return 0.0

func _offensive_formations() -> int:
	var formations := {}
	for enemy in get_tree().get_nodes_in_group(&"enemy"):
		if enemy.has_meta(&"survival_formation") and not enemy.destroyed:
			formations[enemy.get_meta(&"survival_formation")] = true
	for item in _pending:
		if item.has("formation"):
			formations[item.formation] = true
	return formations.size()

func _schedule_debris(rule: SpawnRule) -> void:
	var definition := _rule_definition(rule)
	var openings := 4
	var members := (config.lane_count - openings) * 3
	var cost := members * definition.threat_cost
	if config.lane_count < 8 or _active_enemy_count() > 0 or _available_members(definition) < members or _budget_left < cost:
		_next_formation_at = director.elapsed + 0.25
		return
	for shot in get_tree().get_nodes_in_group(&"enemy_Shot"):
		if not shot.get_meta(&"pooled", false) and not shot.is_queued_for_deletion():
			_next_formation_at = director.elapsed + 0.25
			return
	var formation_id := _combat_sequence + 1
	var formation_seed := director.random.enemies.randi()
	var opens_right := director.encounter.id == &"debris_right"
	var start_lane := config.lane_count - 5 if opens_right else 1
	var shift := 1 if opens_right else -1
	for row in 3:
		var gap_start := start_lane + (shift if row == 1 else 0)
		for lane in config.lane_count:
			if lane >= gap_start and lane < gap_start + openings:
				continue
			_queue_member(rule, definition, _entry_position(SpawnRule.Entry.TOP, lane), row * 0.78, formation_id, formation_seed, false)
	if director.survival_tier() >= 4 and director.encounter.rules.size() > 1:
		var bomber_rule := director.encounter.rules[1]
		var bomber := _rule_definition(bomber_rule)
		if _available_members(bomber) > 0 and _budget_left >= cost + bomber.threat_cost:
			var outside_lane := 0 if opens_right else config.lane_count - 1
			_queue_member(bomber_rule, bomber, _entry_position(SpawnRule.Entry.TOP, outside_lane), 0.35, formation_id, formation_seed, false)
			cost += bomber.threat_cost
	_budget_left -= cost
	_formation_cycle += 1

func _draw() -> void:
	if not _running:
		return
	var edge_y := get_viewport_rect().size.y - 17.0
	for item in _pending:
		if item.get("edge", SpawnRule.Entry.TOP) != SpawnRule.Entry.BOTTOM or item.at - director.elapsed > 1.0:
			continue
		var center := Vector2(item.position.x, edge_y)
		var warning := Color("#ff9e68")
		draw_polyline(PackedVector2Array([center + Vector2(-9, 5), center + Vector2(0, -5), center + Vector2(9, 5)]), warning, 2.0)
		draw_line(center + Vector2(-10, 8), center + Vector2(10, 8), warning, 1.0)

func _flush_pending() -> void:
	var index := 0
	while index < _pending.size():
		var item := _pending[index]
		if item.get("reinforcement", false) and item.squad.has("commander"):
			var commander = item.squad.commander
			if not is_instance_valid(commander) or commander.destroyed:
				_pending.remove_at(index)
				_release_reservation(item)
				continue
			if item.squad.has("signal_at"):
				item.at = item.squad.signal_at + item.signal_delay
		if item.at <= director.elapsed + 0.000001:
			_pending.remove_at(index)
			call_deferred("_materialize", item)
		else:
			index += 1

func _materialize(item: Dictionary) -> void:
	_release_reservation(item)
	if not _running or item.generation != _generation:
		return
	if item.get("reinforcement", false):
		var commander = item.squad.get("commander")
		if not is_instance_valid(commander) or commander.destroyed:
			return
	var enemy := (item.scene as PackedScene).instantiate() as Enemy
	if item.has("formation") and director.encounter.family != WaveDefinition.Family.OPENING:
		enemy.set_meta(&"survival_formation", item.formation)
	if item.has("squad") and not item.get("reinforcement", false):
		var squad: Dictionary = item.squad
		squad["commander"] = enemy
		enemy.connect(&"reinforcement_signal", func() -> void: squad["signal_at"] = director.elapsed, CONNECT_ONE_SHOT)
	if item.get("boss_add", false):
		enemy.add_to_group("boss_add")
	enemy.configure_spawn(item.context)
	enemy.position = item.position
	add_child(enemy)
	enemy_spawned.emit(enemy)

# Debris shares the same reservation accounting as scheduled formations.
func queue_enemy(enemy: Enemy) -> bool:
	if enemy._spawn_context.combat_id == &"":
		enemy._spawn_context.combat_id = _next_combat_identity()
	if not _running or director.state not in [EncounterDirector.State.REGULAR, EncounterDirector.State.BOSS_APPROACH] or _available_members(enemy.definition) < 1:
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
	var count := maxi(floori(float(_enemy_cap() - _active_enemy_count()) / float(definition.spawn_slots)), 0)
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
	var maximum := 1.20
	match definition.durability:
		EnemyDefinition.Durability.FODDER, EnemyDefinition.Durability.FIGHTER:
			maximum = 1.12
		EnemyDefinition.Durability.HEAVY:
			maximum = 1.35
	return coop_scale * director.health_multiplier(maximum)

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
