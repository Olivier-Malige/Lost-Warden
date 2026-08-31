extends Node

const SpawnerConfig := preload("res://data/waves/wave_spawner_config.tres")
const DroneDefinition := preload("res://data/enemies/drone.tres")
const TieDefinition := preload("res://data/enemies/tie.tres")
const InterceptorDefinition := preload("res://data/enemies/interceptor.tres")
const TurretDefinition := preload("res://data/enemies/turret.tres")
const MotherShipDefinition := preload("res://data/enemies/mother_ship.tres")
const MountedTurretDefinition := preload("res://data/enemies/mother_ship_turret.tres")
const AsteroidDefinition := preload("res://data/enemies/asteroid.tres")
const BigAsteroidDefinition := preload("res://data/enemies/big_asteroid.tres")
const UpgradeTableResource := preload("res://data/upgrades/upgrade_table.tres")
const DamageUpgrade := preload("res://data/upgrades/damage.tres")
const SideUpgrade := preload("res://data/upgrades/side_shot.tres")
const FireRateUpgrade := preload("res://data/upgrades/fire_rate.tres")
const BeamUpgrade := preload("res://data/upgrades/beam.tres")
const WaveCatalogResource := preload("res://data/waves/wave_catalog.tres")

const DROP_SIMULATION_RUNS := 10000
const PRIMARY_BASE_DAMAGE := 1.0
const SIDE_BASE_DAMAGE := 0.4
const PATTERN_FAMILIES := {
	"res://scenes/enemies/mother_ship.tscn": "mother_ship",
	"res://scenes/enemies/turret.tscn": "turret",
	"res://scenes/enemies/interceptor.tscn": "interceptor",
}
const DEFINITIONS_BY_SCENE := {
	"res://scenes/enemies/asteroid.tscn": AsteroidDefinition,
	"res://scenes/enemies/big_asteroid.tscn": BigAsteroidDefinition,
	"res://scenes/enemies/drone.tscn": DroneDefinition,
	"res://scenes/enemies/interceptor.tscn": InterceptorDefinition,
	"res://scenes/enemies/mother_ship.tscn": MotherShipDefinition,
	"res://scenes/enemies/tie.tscn": TieDefinition,
	"res://scenes/enemies/turret.tscn": TurretDefinition,
}

var _failures: Array[String] = []

func _ready() -> void:
	_test_enemy_health_curve()
	_test_wave_timing()
	_test_drop_curve()
	_test_upgrade_power_curve()
	_test_late_wave_choreography()
	if _failures.is_empty():
		print("Balance progression harness: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _test_enemy_health_curve() -> void:
	var spawner := WaveSpawner.new()
	spawner.config = SpawnerConfig
	_expect(DroneDefinition.max_health == 2, "A base drone must require two primary impacts.")
	_expect(TieDefinition.max_health == 2, "A base fighter must require two primary impacts.")
	_expect(InterceptorDefinition.max_health == 6, "An interceptor must have six base health.")
	_expect(TurretDefinition.max_health == 30, "A standalone turret must have thirty base health.")
	_expect(MotherShipDefinition.max_health == 40, "A mothership must retain forty base health.")
	_expect(MountedTurretDefinition.max_health == 10, "A mounted turret must retain ten base health.")
	_expect(_effective_health(spawner, DroneDefinition, 1.0) == 2, "Wave-one drones must retain two health.")
	_expect(_effective_health(spawner, TieDefinition, 1.0) == 2, "Wave-one fighters must retain two health.")
	_expect(_effective_health(spawner, DroneDefinition, 2.8) == 3, "First-cycle final drones must have three health.")
	_expect(_effective_health(spawner, TieDefinition, 2.8) == 3, "First-cycle final fighters must have three health.")
	spawner._endless_cycle = 20
	_expect(is_equal_approx(spawner._endless_health_multiplier(), 1.35), "Endless health scaling must stop at 1.35x.")
	_expect(is_equal_approx(spawner._durability_health_cap(TurretDefinition), 1.3), "Heavy health scaling must stop at 1.30x.")
	spawner.free()

func _test_wave_timing() -> void:
	var spawner := WaveSpawner.new()
	spawner.config = SpawnerConfig
	_expect(is_equal_approx(SpawnerConfig.wave_duration, 28.0), "Runtime waves must last twenty-eight seconds.")
	for wave in WaveCatalogResource.waves:
		_expect(is_equal_approx(wave.duration, 24.0), "Wave resources must retain their twenty-four-second authored baseline.")
		_expect(is_equal_approx(spawner._timeline_scale(wave), 28.0 / 24.0), "Every authored timeline must scale proportionally to the configured duration.")
	spawner.free()

func _test_drop_curve() -> void:
	_expect(AsteroidDefinition.power_up_chance == 2, "Asteroid drop chance must be two percent.")
	_expect(BigAsteroidDefinition.power_up_chance == 4, "Large asteroid drop chance must be four percent.")
	_expect(DroneDefinition.power_up_chance == 6, "Drone drop chance must be six percent.")
	_expect(InterceptorDefinition.power_up_chance == 25, "Interceptor drop chance must be twenty-five percent.")
	_expect(MotherShipDefinition.power_up_chance == 35, "Mothership drop chance must be thirty-five percent.")
	_expect(TurretDefinition.power_up_chance == 30, "Turret drop chance must be thirty percent.")
	_expect(TieDefinition.power_up_chance == 0, "Fighters must not drop power-ups.")
	_expect(MountedTurretDefinition.power_up_chance == 0, "Mounted turrets must not drop power-ups.")
	var drop_probe := Enemy.new()
	drop_probe.definition = TieDefinition
	_expect(not drop_probe._should_drop_power_up(0), "A normal fighter with zero drop chance must not create a power-up.")
	drop_probe.definition = AsteroidDefinition
	_expect(drop_probe._should_drop_power_up(1), "A small asteroid must accept both successful rolls of its two-percent chance.")
	_expect(not drop_probe._should_drop_power_up(2), "A small asteroid must reject the first roll outside its two-percent chance.")
	drop_probe.elite = true
	_expect(drop_probe._should_drop_power_up(99), "An elite must guarantee one power-up regardless of its base drop chance.")
	drop_probe.free()

	var rng := RandomNumberGenerator.new()
	rng.seed = 0x5EEDB4A1
	var first_three_total := 0
	var first_five_total := 0
	for _run in range(DROP_SIMULATION_RUNS):
		var first_three := _simulate_wave_range_drops(rng, 0, 3)
		var next_two := _simulate_wave_range_drops(rng, 3, 5)
		first_three_total += first_three
		first_five_total += first_three + next_two
	var first_three_mean := float(first_three_total) / DROP_SIMULATION_RUNS
	var first_five_mean := float(first_five_total) / DROP_SIMULATION_RUNS
	_expect(first_three_mean >= 2.0 and first_three_mean <= 4.0, "The first three waves must average two to four power-ups, got %.2f." % first_three_mean)
	_expect(first_five_mean >= 7.0 and first_five_mean <= 10.0, "The first five waves must average seven to ten power-ups, got %.2f." % first_five_mean)

func _test_upgrade_power_curve() -> void:
	var loadout := PlayerLoadout.new(Player.STATS)
	var base_dps := PRIMARY_BASE_DAMAGE / loadout.fire_delay
	for _rank in range(DamageUpgrade.max_rank):
		loadout.apply(DamageUpgrade)
	for _rank in range(SideUpgrade.max_rank):
		loadout.apply(SideUpgrade)
	for _rank in range(FireRateUpgrade.max_rank):
		loadout.apply(FireRateUpgrade)
	for _rank in range(BeamUpgrade.max_rank):
		loadout.apply(BeamUpgrade)
	var primary_damage := PRIMARY_BASE_DAMAGE + loadout.damage_bonus
	var side_damage := SIDE_BASE_DAMAGE + loadout.side_damage_bonus
	var maximum_dps := (primary_damage + side_damage * 2.0) / loadout.fire_delay
	_expect(is_equal_approx(base_dps, 1.0 / 0.18), "Base primary DPS must remain tied to the 0.18-second cadence.")
	_expect(is_equal_approx(primary_damage, 2.2), "Maximum primary damage must be 2.20.")
	_expect(is_equal_approx(side_damage, 0.88), "Each maximum-rank side cannon must deal 0.88 damage.")
	_expect(is_equal_approx(loadout.beam_damage_bonus, 1.2), "Maximum beam-specific bonus must be 1.20.")
	_expect(is_equal_approx(loadout.fire_delay, 0.13), "Maximum fire rate must stop at 0.13 seconds.")
	_expect(maximum_dps > 30.0 and maximum_dps < 31.0, "Maximum sustained cannon DPS must remain near 30.5, got %.2f." % maximum_dps)
	_test_upgrade_distribution()

func _test_upgrade_distribution() -> void:
	var expected_weight := 0
	for upgrade in UpgradeTableResource.upgrades:
		expected_weight += upgrade.weight
	_expect(expected_weight == 100, "Upgrade weights must retain their one-hundred-point distribution.")
	seed(0xB41A4CE)
	var counts: Dictionary[StringName, int] = {}
	for _roll in range(DROP_SIMULATION_RUNS):
		var upgrade: UpgradeDefinition = UpgradeTableResource.pick()
		counts[upgrade.id] = int(counts.get(upgrade.id, 0)) + 1
	for upgrade in UpgradeTableResource.upgrades:
		var observed := float(counts.get(upgrade.id, 0)) / DROP_SIMULATION_RUNS
		var expected := float(upgrade.weight) / expected_weight
		_expect(absf(observed - expected) < 0.02, "%s pickup weight must stay within two percentage points of its configured share." % upgrade.id)

func _test_late_wave_choreography() -> void:
	for wave_index in range(8, 13):
		var wave: WaveDefinition = WaveCatalogResource.waves[wave_index]
		var families_by_act: Dictionary[int, Dictionary] = {}
		for rule in wave.rules:
			var act := roundi(rule.start_delay)
			if not families_by_act.has(act):
				families_by_act[act] = {}
			var scene_path := rule.scene.resource_path
			if PATTERN_FAMILIES.has(scene_path):
				families_by_act[act][PATTERN_FAMILIES[scene_path]] = true
		for act in families_by_act:
			_expect(families_by_act[act].size() <= 1, "Wave %d act %d must introduce at most one pattern family." % [wave_index + 1, act])
	_expect(_scene_rule_count(8, "res://scenes/enemies/mother_ship.tscn") == 1, "Wave 9 must schedule one mothership.")
	_expect(_scene_rule_count(9, "res://scenes/enemies/turret.tscn") == 1, "Wave 10 must schedule one standalone turret rule.")
	_expect(_scene_rule_count(10, "res://scenes/enemies/tie.tscn") == 0, "Wave 11 climax support must use drones instead of fighters.")
	_expect(_scene_rule_count(11, "res://scenes/enemies/turret.tscn") == 0, "Wave 12 must not schedule a standalone turret.")
	_expect(_scene_rule_count(12, "res://scenes/enemies/turret.tscn") == 0, "Wave 13 must not schedule a standalone turret.")
	for wave_index in [5, 8, 11, 12]:
		_expect(_elite_count(wave_index) == 1, "Wave %d must retain exactly one scheduled elite." % (wave_index + 1))

func _effective_health(spawner: WaveSpawner, definition: EnemyDefinition, difficulty: float) -> int:
	var progress := spawner._difficulty_progress(difficulty)
	var multiplier := lerpf(1.0, spawner._durability_health_cap(definition), progress)
	return ceili(definition.max_health * multiplier)

func _simulate_wave_range_drops(rng: RandomNumberGenerator, start_index: int, end_index: int) -> int:
	var drops := 0
	for wave_index in range(start_index, end_index):
		var wave: WaveDefinition = WaveCatalogResource.waves[wave_index]
		for rule in wave.rules:
			var definition: EnemyDefinition = DEFINITIONS_BY_SCENE.get(rule.scene.resource_path)
			if definition == null or definition.power_up_chance <= 0:
				continue
			var spawn_count := ceili(rule.active_duration / rule.interval) * _formation_size(rule)
			for _spawn in range(spawn_count):
				if rng.randi_range(0, 99) < definition.power_up_chance:
					drops += 1
	return drops

func _formation_size(rule: SpawnRule) -> int:
	var available_lanes := rule.spawn_max - rule.spawn_min + 1
	return mini(rule.formation, available_lanes)

func _scene_rule_count(wave_index: int, scene_path: String) -> int:
	var count := 0
	for rule in WaveCatalogResource.waves[wave_index].rules:
		if rule.scene.resource_path == scene_path:
			count += 1
	return count

func _elite_count(wave_index: int) -> int:
	var count := 0
	for rule in WaveCatalogResource.waves[wave_index].rules:
		count += rule.elite_count
	return count

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
