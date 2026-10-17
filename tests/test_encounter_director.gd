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

func _wave(id: StringName, weight := 1.0) -> WaveDefinition:
	var wave := WaveDefinition.new()
	wave.id = id
	wave.duration = 25.0
	wave.selection_weight = weight
	var rule := SpawnRule.new()
	rule.scene = PackedScene.new()
	wave.rules.append(rule)
	return wave

func _boss(id: StringName) -> BossDefinition:
	var boss := BossDefinition.new()
	boss.id = id
	boss.scene = PackedScene.new()
	return boss

func _sequence(seed_value: int, noise: bool) -> Array[StringName]:
	var streams := RunRandom.new(seed_value)
	var director := EncounterDirector.new(streams)
	var waves: Array[WaveDefinition] = [_wave(&"line"), _wave(&"scatter"), _wave(&"edges"), _wave(&"offset")]
	var sequence: Array[StringName] = []
	for index in 100:
		if noise:
			for unused in 7:
				randf()
				streams.enemies.randi()
				streams.drops.randi()
				streams.upgrades.randi()
		var chosen := director.choose_encounter(waves)
		_check(chosen.id not in sequence.slice(maxi(sequence.size() - 2, 0)), "avoid both previous encounters when alternatives exist")
		_check(is_equal_approx(director.encounter_left, 25.0), "retain authored encounter duration")
		sequence.append(chosen.id)
	return sequence

func _test_randomness() -> void:
	var expected := _sequence(42, false)
	_check(expected == _sequence(42, false), "same seed reproduces encounter choices")
	_check(expected == _sequence(42, true), "cosmetic and other gameplay streams cannot change encounters")
	_check(expected != _sequence(43, false), "different seeds change encounter sequence")
	var first := RunRandom.new(123)
	var second := RunRandom.new(123)
	_check(first.encounters.seed != first.enemies.seed and first.drops.seed != first.upgrades.seed, "streams use distinct seeds")
	for index in 30:
		first.encounters.randi()
		first.enemies.randi()
	_check(first.drops.randi() == second.drops.randi(), "enemy draws cannot change drops")
	_check(first.upgrades.randi() == second.upgrades.randi(), "encounter draws cannot change upgrade offers")

func _test_curves() -> void:
	var director := EncounterDirector.new(RunRandom.new(1))
	var times := [0.0, 120.0, 300.0, 480.0, 600.0, 720.0, 780.0, 1320.0]
	var dangers := [1.0, 1.4, 2.4, 3.4, 4.2, 5.0, 5.2, 7.0]
	for index in times.size():
		director.elapsed = times[index]
		_check(is_equal_approx(director.danger(), dangers[index]), "danger curve at %s seconds" % times[index])
	_check(is_equal_approx(EncounterDirector.danger_at(210.0), 1.9), "danger interpolates between milestones")
	var elite_times := [0.0, 119.0, 120.0, 180.0, 300.0, 480.0, 720.0, 1200.0]
	var chances := [0.0, 0.0, 0.0, 0.05, 0.10, 0.18, 0.25, 0.25]
	for index in elite_times.size():
		director.elapsed = elite_times[index]
		_check(is_equal_approx(director.elite_chance(), chances[index]), "elite curve at %s seconds" % elite_times[index])
	_check(is_equal_approx(director.health_multiplier(), 1.5), "health scaling is capped")
	_check(is_equal_approx(director.speed_multiplier(), 1.2), "movement scaling is capped")
	_check(is_equal_approx(director.fire_delay_multiplier(), 0.8), "firing delay scaling is capped")
	director.danger_offset = -100.0
	_check(is_equal_approx(director.danger(), 1.0), "debug offset cannot reduce danger below one")
	var common := EnemyDefinition.new()
	var heavy := EnemyDefinition.new()
	heavy.minimum_danger = 2.0
	heavy.danger_weight_growth = 2.0
	_check(is_zero_approx(heavy.weight_at(1.0)), "family minimum danger gates eligibility")
	_check(heavy.weight_at(5.0) > heavy.weight_at(2.0), "higher danger favors authored advanced-family weights")
	_check(common.weight_at(5.0) > 0.0, "common enemies remain eligible at high danger")

func _test_selection() -> void:
	var director := EncounterDirector.new(RunRandom.new(7))
	var first := _wave(&"first")
	var locked := _wave(&"locked")
	locked.minimum_danger = 3.0
	var disabled := _wave(&"disabled", 0.0)
	var waves: Array[WaveDefinition] = [first, locked, disabled, null]
	for index in 5:
		_check(director.choose_encounter(waves) == first, "single eligible encounter can repeat without stalling")
	_check(is_equal_approx(director.encounter_budget(), 30.0), "initial threat budget")
	director.elapsed = 720.0
	_check(is_equal_approx(director.encounter_budget(), 150.0), "threat budget grows with danger")
	var empty: Array[WaveDefinition] = []
	_check(director.choose_encounter(empty) == null, "empty eligibility is handled")

func _test_boss_timeline() -> void:
	var director := EncounterDirector.new(RunRandom.new(5))
	var bosses: Array[BossDefinition] = [_boss(&"carrier"), _boss(&"alternative")]
	_check(director.choose_boss(bosses) == null, "boss cannot start at run opening")
	director.advance(299.0)
	_check(not director.boss_due(), "no boss before five regular minutes")
	director.advance(1.0)
	_check(director.boss_due(), "first boss due at five regular minutes")
	var first := director.choose_boss(bosses)
	_check(first != null and director.state == EncounterDirector.State.BOSS, "eligible boss starts")
	_check(director.choose_boss(bosses) == null, "boss encounters cannot overlap")
	var waves: Array[WaveDefinition] = [_wave(&"regular")]
	_check(director.choose_encounter(waves) == null, "normal encounters are suspended during a boss")
	director.advance(90.0)
	_check(is_equal_approx(director.regular_elapsed, 300.0), "boss time does not count toward next milestone")
	director.boss_defeated()
	director.advance(7.0)
	_check(director.state == EncounterDirector.State.RECOVERY, "recovery lasts eight seconds")
	_check(director.choose_encounter(waves) == null, "recovery suspends regular encounters")
	director.advance(1.0)
	_check(director.state == EncounterDirector.State.REGULAR, "regular encounters resume after recovery")
	director.boss_defeated()
	_check(director.state == EncounterDirector.State.REGULAR, "duplicate defeat does not restart recovery")
	director.advance(299.0)
	_check(not director.boss_due(), "recovery time is excluded from boss schedule")
	director.advance(1.0)
	var second := director.choose_boss(bosses)
	_check(second != null and second.id != first.id, "next boss uses five more regular minutes and avoids the previous boss")
	director.boss_defeated()
	director.advance(8.0)
	director.advance(300.0)
	var single: Array[BossDefinition] = [bosses[0]]
	_check(director.choose_boss(single) == bosses[0], "single-boss launch catalog remains playable")
	var invalid := BossDefinition.new()
	_check(not invalid.is_valid(), "incomplete boss definitions are rejected")
	invalid = _boss(&"invalid_cadence")
	invalid.volley_intervals = PackedFloat32Array([2.0, 0.0, 1.0])
	_check(not invalid.is_valid(), "boss cadence must stay positive in every phase")

func _test_weighted_selection() -> void:
	var director := EncounterDirector.new(RunRandom.new(81))
	var common := _wave(&"common", 1.0)
	var favored := _wave(&"favored", 9.0)
	var waves: Array[WaveDefinition] = [common, favored]
	var favored_count := 0
	for index in 1000:
		director.recent.clear()
		if director.choose_encounter(waves) == favored:
			favored_count += 1
	_check(favored_count > 850 and favored_count < 950, "authored encounter weights affect observed frequency")
	common.maximum_danger = 1.2
	director.elapsed = 300.0
	_check(director.choose_encounter(waves) == favored, "encounter maximum danger is respected")
	var invalid := _wave(&"invalid")
	invalid.duration = 36.0
	var invalid_waves: Array[WaveDefinition] = [invalid]
	_check(director.choose_encounter(invalid_waves) == null, "legacy 36-second waves require explicit encounter migration")
	var boss_director := EncounterDirector.new(RunRandom.new(1))
	boss_director.advance(300.0)
	var locked := _boss(&"locked")
	locked.minimum_danger = 10.0
	var locked_bosses: Array[BossDefinition] = [locked]
	_check(boss_director.choose_boss(locked_bosses) == null, "ineligible bosses cannot start")
	_check(boss_director.state == EncounterDirector.State.REGULAR, "empty boss eligibility cannot stall normal encounters")

func _run() -> void:
	_test_randomness()
	_test_curves()
	_test_selection()
	_test_boss_timeline()
	_test_weighted_selection()
	print("Encounter director: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)
