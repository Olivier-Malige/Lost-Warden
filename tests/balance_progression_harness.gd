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
const WaveCatalogResource := preload("res://data/waves/wave_catalog.tres")
const INTERCEPTOR_SCENE_PATH := "res://scenes/enemies/interceptor.tscn"
const TIE_SCENE_PATH := "res://scenes/enemies/tie.tscn"

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
	_test_wave_patterns()
	_test_interceptor_lane_bounds()
	_test_endless_finale()
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
	_expect(is_equal_approx(InterceptorDefinition.lateral_frequency, 0.45), "Interceptor lateral movement must remain readable.")
	_expect(TurretDefinition.max_health == 30, "A standalone turret must have thirty base health.")
	_expect(MotherShipDefinition.max_health == 40, "A mothership must retain forty base health.")
	_expect(MountedTurretDefinition.max_health == 10, "A mounted turret must retain ten base health.")
	_expect(is_equal_approx(SpawnerConfig.elite_definition.health_multiplier, 2.5), "Elites must have a substantial health multiplier.")
	_expect(is_equal_approx(SpawnerConfig.elite_definition.speed_multiplier, 0.8), "Elites must move slower than their base enemy.")
	_expect(_effective_health(spawner, DroneDefinition, 1.0) == 2, "Wave-one drones must retain two health.")
	_expect(_effective_health(spawner, TieDefinition, 1.0) == 2, "Wave-one fighters must retain two health.")
	_expect(_effective_health(spawner, DroneDefinition, 3.55) == 3, "First-cycle final drones must have three health.")
	_expect(_effective_health(spawner, TieDefinition, 3.55) == 3, "First-cycle final fighters must have three health.")
	spawner._endless_cycle = 20
	_expect(is_equal_approx(spawner._endless_health_multiplier(), 1.75), "Endless health scaling must stop at 1.75x.")
	_expect(is_equal_approx(spawner._durability_health_cap(TurretDefinition), 1.3), "Heavy health scaling must stop at 1.30x.")
	spawner.free()

func _test_wave_timing() -> void:
	var spawner := WaveSpawner.new()
	spawner.config = SpawnerConfig
	_expect(WaveCatalogResource.waves.size() == 18, "The campaign must contain eighteen waves.")
	_expect(is_equal_approx(SpawnerConfig.wave_duration, 36.0), "Runtime waves must last thirty-six seconds.")
	for wave in WaveCatalogResource.waves:
		_expect(is_equal_approx(wave.duration, 36.0), "Wave resources must retain their thirty-six-second authored baseline.")
		_expect(is_equal_approx(spawner._timeline_scale(wave), 1.0), "Authored wave timelines must not need runtime stretching.")
		for act in [0.0, 9.0, 18.0, 27.0]:
			_expect(_has_act_coverage(wave, act), "Every wave act must start with an active stream at %.0f seconds." % act)
	spawner.free()

func _test_wave_patterns() -> void:
	var spawner := WaveSpawner.new()
	spawner.config = SpawnerConfig
	var patterns := [
		SpawnRule.Pattern.CENTER_OUT,
		SpawnRule.Pattern.EDGE_IN,
		SpawnRule.Pattern.SWEEP,
		SpawnRule.Pattern.GAP_WALL,
	]
	for pattern in patterns:
		var rule := SpawnRule.new()
		rule.pattern = pattern
		rule.spawn_min = 4
		rule.spawn_max = 7
		rule.formation = 9
		for cycle in range(8):
			var lanes := spawner._formation_lanes(rule, rule.formation, cycle)
			_expect(_has_unique_lanes(lanes), "Pattern %d must not repeat a lane." % pattern)
			for lane in lanes:
				_expect(lane >= rule.spawn_min and lane <= rule.spawn_max, "Pattern %d must stay within its lane range." % pattern)
			if pattern == SpawnRule.Pattern.GAP_WALL:
				_expect(lanes.size() <= 2, "Gap walls must leave a two-lane corridor in a four-lane range.")
	var narrow_rule := SpawnRule.new()
	narrow_rule.spawn_min = 5
	narrow_rule.spawn_max = 6
	narrow_rule.pattern = SpawnRule.Pattern.GAP_WALL
	_expect(spawner._formation_lanes(narrow_rule, 8, 0).size() == 2, "Narrow gap walls must fall back to valid lanes.")
	spawner.free()

func _test_endless_finale() -> void:
	var spawner := WaveSpawner.new()
	spawner.catalog = WaveCatalogResource
	spawner.config = SpawnerConfig
	spawner.wave_index = 17
	var final_wave: WaveDefinition = WaveCatalogResource.waves[17]
	var growing_formation: SpawnRule = final_wave.rules[0]
	var growing_elite: SpawnRule = final_wave.rules[1]
	spawner._endless_cycle = 0
	_expect(spawner._endless_formation_bonus(growing_formation) == 0, "The first final wave must not receive endless growth.")
	spawner._endless_cycle = 4
	_expect(is_equal_approx(spawner._endless_health_multiplier(), 1.32), "Endless health must gain eight percent per cycle.")
	_expect(is_equal_approx(spawner._pace_multiplier(3.55), 0.82 * 0.84), "Endless pacing must gain four percent per cycle.")
	_expect(spawner._endless_formation_bonus(growing_formation) == 2, "Formation growth must stop at two extra enemies.")
	_expect(spawner._endless_elite_bonus(growing_elite) == 1, "Elite growth must add one elite every three cycles.")
	spawner._endless_cycle = 12
	_expect(spawner._endless_elite_bonus(growing_elite) == 2, "Elite growth must stop at two extra elites.")
	_expect(SpawnerConfig.loop_start_index == 17, "The endless loop must restart from the final wave.")
	spawner.free()

func _test_interceptor_lane_bounds() -> void:
	for wave in WaveCatalogResource.waves:
		for rule in wave.rules:
			if rule.scene.resource_path == INTERCEPTOR_SCENE_PATH:
				_expect(rule.spawn_min >= 2 and rule.spawn_max <= 9, "Interceptors must keep two outer lanes clear on each side.")
			if rule.scene.resource_path == TIE_SCENE_PATH:
				_expect(rule.spawn_min >= 1 and rule.spawn_max <= 10, "TIE fighters must keep the outermost lanes clear.")

func _test_drop_curve() -> void:
	_expect(AsteroidDefinition.power_up_chance == 1, "Asteroid drop chance must be one percent at the denser wave pace.")
	_expect(BigAsteroidDefinition.power_up_chance == 3, "Large asteroid drop chance must be three percent at the denser wave pace.")
	_expect(DroneDefinition.power_up_chance == 4, "Drone drop chance must be four percent at the denser wave pace.")
	_expect(InterceptorDefinition.power_up_chance == 25, "Interceptor drop chance must be twenty-five percent.")
	_expect(MotherShipDefinition.power_up_chance == 35, "Mothership drop chance must be thirty-five percent.")
	_expect(TurretDefinition.power_up_chance == 30, "Turret drop chance must be thirty percent.")
	_expect(TieDefinition.power_up_chance == 0, "Fighters must not drop power-ups.")
	_expect(MountedTurretDefinition.power_up_chance == 0, "Mounted turrets must not drop power-ups.")
	_expect(AsteroidDefinition.plasma_drop_chance == 4, "Asteroids must have a four-percent plasma chance at the denser wave pace.")
	_expect(BigAsteroidDefinition.plasma_drop_chance == 9, "Large asteroids must have a nine-percent plasma chance at the denser wave pace.")
	_expect(DroneDefinition.plasma_drop_chance == 12, "Drones must have a twelve-percent plasma chance at the denser wave pace.")
	_expect(TieDefinition.plasma_drop_chance == 13, "Fighters must have a thirteen-percent plasma chance at the denser wave pace.")
	_expect(InterceptorDefinition.plasma_drop_chance == 63, "Interceptors must have a sixty-three-percent plasma chance.")
	_expect(MountedTurretDefinition.plasma_drop_chance == 30, "Mounted turrets must have a thirty-percent plasma chance.")
	_expect(TurretDefinition.plasma_drop_chance == 59, "Turrets must have a fifty-nine-percent plasma chance.")
	_expect(MotherShipDefinition.plasma_drop_chance == 55, "Motherships must have a fifty-five-percent plasma chance.")
	var drop_probe := Enemy.new()
	drop_probe.definition = TieDefinition
	_expect(drop_probe._reward_for_roll(0) == Enemy.RewardDrop.PLASMA, "A fighter reward must be plasma.")
	_expect(drop_probe._reward_for_roll(18) == Enemy.RewardDrop.NONE, "A fighter must not create a power-up after its plasma interval.")
	drop_probe.definition = AsteroidDefinition
	_expect(drop_probe._reward_for_roll(3) == Enemy.RewardDrop.PLASMA, "Asteroid plasma must occupy the first four roll values.")
	_expect(drop_probe._reward_for_roll(4) == Enemy.RewardDrop.POWER_UP, "Asteroid power-ups must follow the plasma interval.")
	_expect(drop_probe._reward_for_roll(5) == Enemy.RewardDrop.NONE, "A normal enemy must produce at most one exclusive reward.")
	drop_probe.free()

	var rng := RandomNumberGenerator.new()
	rng.seed = 0x5EEDB4A1
	var first_three_power_total := 0
	var first_five_power_total := 0
	var first_five_plasma_total := 0
	var first_five_coop_plasma_total := 0
	for _run in range(DROP_SIMULATION_RUNS):
		var first_three := _simulate_wave_range_drops(rng, 0, 3, false)
		var next_two := _simulate_wave_range_drops(rng, 3, 5, false)
		var coop_five := _simulate_wave_range_drops(rng, 0, 5, true)
		first_three_power_total += first_three.y
		first_five_power_total += first_three.y + next_two.y
		first_five_plasma_total += first_three.x + next_two.x
		first_five_coop_plasma_total += coop_five.x
	var first_three_mean := float(first_three_power_total) / DROP_SIMULATION_RUNS
	var first_five_mean := float(first_five_power_total) / DROP_SIMULATION_RUNS
	var first_five_plasma_mean := float(first_five_plasma_total) / DROP_SIMULATION_RUNS
	var first_five_coop_plasma_mean := float(first_five_coop_plasma_total) / DROP_SIMULATION_RUNS
	_expect(first_three_mean >= 2.0 and first_three_mean <= 4.0, "The first three waves must average two to four power-ups, got %.2f." % first_three_mean)
	_expect(first_five_mean >= 7.0 and first_five_mean <= 10.0, "The first five waves must average seven to ten power-ups, got %.2f." % first_five_mean)
	var solo_recharge_seconds := 5.0 * SpawnerConfig.wave_duration * 100.0 / (first_five_plasma_mean * 12.5)
	var coop_recharge_seconds := 5.0 * SpawnerConfig.wave_duration * 100.0 / (first_five_coop_plasma_mean * 12.5)
	_expect(solo_recharge_seconds >= 35.0 and solo_recharge_seconds <= 50.0, "Solo plasma must refill in 35-50 seconds, got %.2f." % solo_recharge_seconds)
	_expect(coop_recharge_seconds >= 35.0 and coop_recharge_seconds <= 50.0, "Shared co-op plasma must refill in 35-50 seconds, got %.2f." % coop_recharge_seconds)
	var solo_uptime := 5.0 / (solo_recharge_seconds + 5.0)
	var coop_uptime := 5.0 / (coop_recharge_seconds + 5.0)
	_expect(solo_uptime < 0.2 and coop_uptime < 0.2, "Plasma income must keep theoretical beam uptime below twenty percent.")

func _test_upgrade_power_curve() -> void:
	var loadout := PlayerLoadout.new(Player.STATS)
	var base_dps := PRIMARY_BASE_DAMAGE / loadout.fire_delay
	for _rank in range(DamageUpgrade.max_rank):
		loadout.apply(DamageUpgrade)
	for _rank in range(SideUpgrade.max_rank):
		loadout.apply(SideUpgrade)
	for _rank in range(FireRateUpgrade.max_rank):
		loadout.apply(FireRateUpgrade)
	var primary_damage := PRIMARY_BASE_DAMAGE + loadout.damage_bonus
	var side_damage := SIDE_BASE_DAMAGE + loadout.side_damage_bonus
	var beam_tick_damage := Player.STATS.beam_damage + loadout.damage_bonus
	var maximum_dps := (primary_damage + side_damage * 2.0) / loadout.fire_delay
	_expect(is_equal_approx(base_dps, 1.0 / 0.18), "Base primary DPS must remain tied to the 0.18-second cadence.")
	_expect(is_equal_approx(primary_damage, 2.2), "Maximum primary damage must be 2.20.")
	_expect(is_equal_approx(side_damage, 0.88), "Each maximum-rank side cannon must deal 0.88 damage.")
	_expect(is_equal_approx(beam_tick_damage, 4.2), "The standard damage upgrade must raise beam tick damage to 4.20.")
	_expect(is_equal_approx(loadout.fire_delay, 0.13), "Maximum fire rate must stop at 0.13 seconds.")
	_expect(maximum_dps > 30.0 and maximum_dps < 31.0, "Maximum sustained cannon DPS must remain near 30.5, got %.2f." % maximum_dps)
	_test_upgrade_distribution()

func _test_upgrade_distribution() -> void:
	var expected_weight := 0
	for upgrade in UpgradeTableResource.upgrades:
		expected_weight += upgrade.weight
	_expect(expected_weight == 86, "Removing beam ranks must leave the six existing upgrade weights unchanged.")
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
	for wave_index in range(WaveCatalogResource.waves.size()):
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
	_expect(_scene_rule_count(10, "res://scenes/enemies/tie.tscn") == 0, "Wave 11 must keep its alternating drone and interceptor identity.")
	for wave_index in [5, 8, 11, 12, 15, 16, 17]:
		_expect(_elite_count(wave_index) >= 1, "Wave %d must schedule at least one elite." % (wave_index + 1))
	_expect(_scene_rule_count(17, "res://scenes/enemies/mother_ship.tscn") == 1, "The final gauntlet must end with one mothership.")
	_expect(_scene_rule_count(17, "res://scenes/enemies/turret.tscn") == 1, "The final gauntlet must contain one standalone turret.")

func _effective_health(spawner: WaveSpawner, definition: EnemyDefinition, difficulty: float) -> int:
	var progress := spawner._difficulty_progress(difficulty)
	var multiplier := lerpf(1.0, spawner._durability_health_cap(definition), progress)
	return ceili(definition.max_health * multiplier)

func _simulate_wave_range_drops(rng: RandomNumberGenerator, start_index: int, end_index: int, coop: bool) -> Vector2i:
	var plasma_drops := 0
	var power_drops := 0
	for wave_index in range(start_index, end_index):
		var wave: WaveDefinition = WaveCatalogResource.waves[wave_index]
		for rule in wave.rules:
			var definition: EnemyDefinition = DEFINITIONS_BY_SCENE.get(rule.scene.resource_path)
			if definition == null:
				continue
			var interval := rule.interval * (0.9 if coop and rule.formation < 4 else 1.0)
			var formation_size := _formation_size(rule) + (1 if coop and rule.formation >= 4 else 0)
			var spawn_count := ceili(rule.active_duration / interval) * formation_size
			for _spawn in range(spawn_count):
				var roll := rng.randi_range(0, 99)
				if roll < definition.plasma_drop_chance:
					plasma_drops += 1
				elif roll < definition.plasma_drop_chance + definition.power_up_chance:
					power_drops += 1
	return Vector2i(plasma_drops, power_drops)

func _formation_size(rule: SpawnRule) -> int:
	var available_lanes := rule.spawn_max - rule.spawn_min + 1
	return mini(rule.formation, available_lanes)

func _has_act_coverage(wave: WaveDefinition, act: float) -> bool:
	for rule in wave.rules:
		if rule.start_delay <= act and rule.start_delay + rule.active_duration > act:
			return true
	return false

func _has_unique_lanes(lanes: Array[int]) -> bool:
	var seen: Dictionary[int, bool] = {}
	for lane in lanes:
		if seen.has(lane):
			return false
		seen[lane] = true
	return true

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
