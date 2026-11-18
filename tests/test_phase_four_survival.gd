extends SceneTree

var _failures := 0
var _checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)

func _make_spawner(coop: bool) -> Variant:
	var globals := root.get_node("global")
	globals.coop = coop
	globals.reset_run(2048)
	var spawner = load("res://scenes/waves/wave_spawner.gd").new()
	spawner.config = load("res://data/waves/wave_spawner_config.tres")
	spawner.catalog = load("res://data/waves/wave_catalog.tres")
	for index in 12:
		var marker := Marker2D.new()
		marker.name = "spawnPos%d" % index
		marker.position = Vector2(116 + 37 * index, -28)
		spawner.add_child(marker)
	root.add_child(spawner)
	spawner.start_run()
	spawner.set_physics_process(false)
	spawner.enemy_spawned.connect(func(enemy: Variant) -> void: enemy.set_physics_process(false))
	return spawner

func _clear_field(spawner: Variant) -> void:
	for enemy in get_nodes_in_group(&"enemy"):
		if spawner.is_ancestor_of(enemy):
			enemy.free()

func _simulate(coop: bool) -> Array[StringName]:
	var spawner = _make_spawner(coop)
	var director: EncounterDirector = spawner.director
	var seen: Array[int] = []
	var trace: Array[StringName] = []
	var spawned := {}
	var hunt_distance := 0
	var last_encounter := 0
	var max_tier := 0
	var defeats := 0
	var reentries := 0
	var had_elite := false
	var reserved_bottom := false
	var saw_pair := false
	spawner.enemy_spawned.connect(func(enemy: Variant) -> void:
		spawned[enemy.definition.id] = spawned.get(enemy.definition.id, 0) + 1
	)
	# Advance scheduling and deferred materialization while replacing player clears with timed despawns.
	for tick in 1970:
		if director.state == EncounterDirector.State.BOSS_APPROACH:
			_clear_field(spawner)
			director.boss_entered()
			director.boss_defeated()
			defeats += 1
		spawner._physics_process(2.0)
		if not spawner._running:
			_check(false, "the catalog must stay eligible throughout long runs")
			break
		if director.encounter_number != last_encounter:
			last_encounter = director.encounter_number
			var family := director.encounter.family
			trace.append(director.encounter.id)
			if director.victories > 0:
				if family not in seen:
					seen.append(family)
				if family == WaveDefinition.Family.REENTRY:
					reentries += 1
				elif family == WaveDefinition.Family.ELITE_HUNT:
					hunt_distance = 0
				else:
					hunt_distance += 1
				_check(hunt_distance <= 4, "an elite hunt is offered at least every five encounters")
		if director.victories > 0 and spawner._active_elite_count() > 0:
			had_elite = true
		for item in spawner._pending:
			if item.get("edge") == SpawnRule.Entry.BOTTOM:
				reserved_bottom = true
		_check(spawner._active_enemy_count() <= spawner._enemy_cap(), "reservations and bodies fit the cap")
		_check(spawner._active_elite_count() <= spawner.config.elite_cap, "promotions fit the elite cap")
		_check(spawner._budget_left >= 0.0, "formations fit the available budget")
		max_tier = maxi(max_tier, director.survival_tier())
		if spawner._offensive_formations() == 2:
			saw_pair = true
			_check(director.survival_tier() >= 3, "two formations require tier three")
		await process_frame
		if tick % 3 == 2:
			_clear_field(spawner)
	_check(director.regular_elapsed >= 3600.0 and defeats > 2, "one hour advances through recurring bosses")
	_check(max_tier >= 18 and reentries == 1 and seen.size() == 6, "all families appear and first reentry is unique")
	_check(had_elite and reserved_bottom and saw_pair, "long runs produce elite, rear and overlapping threats")
	for id in [&"dive_hunter", &"bomber", &"sniper", &"rear_stalker", &"bastion", &"assault_commander"]:
		_check(spawned.has(id), "%s materializes in the run" % id)
	spawner.stop_run()
	await process_frame
	_check(spawner._reserved_slots == 0 and spawner._reserved_elites == 0, "stopping releases all reservations")
	spawner.free()
	return trace

func _test_special_formations() -> void:
	var spawner = _make_spawner(false)
	var director: EncounterDirector = spawner.director
	director.victories = 1
	director.elapsed = 850.0
	director.survival_combat_time = 730.0
	director.encounter = load("res://data/waves/debris_right.tres")
	spawner._budget_left = 200.0
	spawner._schedule_debris(director.encounter.rules[0])
	var masks := [0, 0, 0]
	for item in spawner._pending:
		if item.family == &"asteroid_small":
			var row := roundi((item.at - director.elapsed) / 0.78)
			var lane := roundi((item.position.x - 116.0) / 37.0)
			masks[row] |= 1 << lane
	var blocked: int = masks[0] | masks[1] | masks[2]
	var shared_openings := 0
	for lane in 12:
		if blocked & (1 << lane) == 0:
			shared_openings += 1
	_check(shared_openings == 3 and spawner._reserved_slots == 25, "three fast rows keep three common openings with the advanced bomber")
	spawner._cancel_formations()
	director.encounter = load("res://data/waves/ambush_rear.tres")
	spawner._formation_cycle = 0
	var rule := director.encounter.rules[0]
	var definition: EnemyDefinition = spawner._rule_definition(rule)
	var position: Vector2 = spawner._entry_position(SpawnRule.Entry.BOTTOM, 6)
	spawner._queue_member(rule, definition, position, 0.0, 100, 12, false, SpawnRule.Entry.BOTTOM)
	spawner._flush_pending()
	_check(spawner._pending.size() == 1 and spawner._reserved_slots == 1, "the bottom warning reserves a slot before spawning")
	director.advance(0.99)
	spawner._flush_pending()
	_check(spawner._pending.size() == 1, "a rear stalker waits the full warning duration")
	spawner.stop_run()
	_check(spawner._reserved_slots == 0 and spawner._pending.is_empty(), "stopping cancels an in-progress warning")
	spawner.free()

func _test_commander() -> void:
	var spawner = _make_spawner(false)
	var director: EncounterDirector = spawner.director
	director.victories = 1
	director.elapsed = 1000.0
	director.survival_combat_time = 421.0
	director.encounter = load("res://data/waves/fleet_command.tres")
	var rule := director.encounter.rules[0]
	var definition: EnemyDefinition = spawner._rule_definition(rule)
	spawner._budget_left = 100.0
	var commander_item: Dictionary = spawner._queue_member(rule, definition, Vector2(280, -28), 0.0, 1, 8, false)
	var squad := {}
	commander_item.squad = squad
	spawner._schedule_reinforcements(rule, squad, definition.threat_cost, 1, 8)
	spawner._flush_pending()
	await process_frame
	_check(spawner._pending.size() == 4 and spawner._reserved_slots == 4, "both reinforcement groups are reserved before the signal")
	var commander = squad.get("commander")
	_check(is_instance_valid(commander), "the commander spawns first")
	if is_instance_valid(commander):
		commander._physics_process(1.0)
		commander._physics_process(0.71)
		spawner._flush_pending()
		await process_frame
		_check(spawner._pending.size() == 2 and spawner._active_enemy_count() == 5, "the signal sends two hunters and holds two more")
		commander._destroy()
		director.advance(1.0)
		spawner._flush_pending()
		_check(spawner._pending.is_empty() and spawner._reserved_slots == 0, "destroying the commander cancels the remaining hunters")
	spawner.stop_run()
	spawner.free()

func _test_attack_windows() -> void:
	var spawner = _make_spawner(false)
	var sniper = load("res://scenes/enemies/sniper.tscn").instantiate()
	sniper.position = Vector2(110, -28)
	spawner.add_child(sniper)
	sniper._physics_process(1.0)
	sniper._physics_process(0.35)
	_check(get_node_count_in_group(&"enemy_Shot") == 0, "the sniper tracks before firing")
	sniper._physics_process(0.79)
	_check(get_node_count_in_group(&"enemy_Shot") == 0, "the locked shot leaves an escape window")
	sniper._physics_process(0.02)
	_check(get_node_count_in_group(&"enemy_Shot") == 1, "the sniper fires exactly one pooled projectile")
	var bomber = load("res://scenes/enemies/bomber.tscn").instantiate()
	spawner.position.x = 64.0
	bomber.position = Vector2(116, -28)
	spawner.add_child(bomber)
	bomber._physics_process(1.0)
	var centers: Array[Vector2] = bomber._bombs
	_check(centers.size() == 2 and centers[0].distance_to(centers[1]) > 72.0, "bomb markers leave an opening")
	_check(is_equal_approx(bomber._bomb_world_position(centers[0]).x, centers[0].x + 64.0), "bomb damage follows the centered playfield")
	bomber._physics_process(0.89)
	_check(bomber._stage == 1, "the bomber leaves the marker before the impact")
	bomber._physics_process(0.02)
	_check(bomber._stage == 2, "the bomber impacts after the warning")
	spawner.stop_run()
	spawner.free()

func _run() -> void:
	_test_attack_windows()
	_test_special_formations()
	await _test_commander()
	var solo := await _simulate(false)
	var coop := await _simulate(true)
	_check(not solo.is_empty() and not coop.is_empty(), "both modes create encounters")
	var waves: WaveCatalog = load("res://data/waves/wave_catalog.tres")
	var first := EncounterDirector.new(RunRandom.new(19))
	var second := EncounterDirector.new(RunRandom.new(19))
	for director in [first, second]:
		director.victories = 1
		director.elapsed = 320.0
	for index in 200:
		var a := first.choose_encounter(waves.waves)
		var b := second.choose_encounter(waves.waves)
		_check(a != null and a == b, "identical streams select identical survival encounters")
		first.advance(25.0)
		second.advance(25.0)
	print("Phase four survival: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
