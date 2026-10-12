extends SceneTree

const CONFIG: WaveSpawnerConfig = preload("res://data/waves/wave_spawner_config.tres")
var catalog: WaveCatalog
const STATS: PlayerStats = preload("res://data/player/player_stats.tres")
const DAMAGE: UpgradeDefinition = preload("res://data/upgrades/damage.tres")
const RATE: UpgradeDefinition = preload("res://data/upgrades/fire_rate.tres")
const SIDE: UpgradeDefinition = preload("res://data/upgrades/side_shot.tres")

var failures := 0
var checks := 0
var stage: Node2D
var spawner: Variant
var globals: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func definition(kind: String) -> EnemyDefinition:
	return load("res://data/enemies/%s.tres" % kind)

func make_enemy(kind: String, difficulty: float, elite := false) -> Variant:
	var enemy = load("res://scenes/enemies/%s.tscn" % kind).instantiate()
	var context := EnemySpawnContext.new()
	context.health_multiplier = spawner._health_multiplier(enemy.definition, difficulty)
	context.elite = elite
	context.elite_definition = CONFIG.elite_definition
	enemy.configure_spawn(context)
	stage.add_child(enemy)
	enemy.position = Vector2(300, 100)
	enemy.set_physics_process(false)
	enemy.set_deferred("monitoring", false)
	enemy.set_deferred("monitorable", false)
	for timer in enemy.find_children("*", "Timer", true, false):
		timer.stop()
	for sound in enemy.find_children("*", "AudioStreamPlayer2D", true, false):
		sound.stream = null
	return enemy

func check_health_and_impacts() -> void:
	var kinds := ["drone", "tie", "interceptor", "turret", "mother_ship", "mother_ship_turret", "asteroid", "big_asteroid"]
	var base_health := [2.0, 2.0, 10.0, 56.0, 76.0, 19.0, 2.0, 8.0]
	var coop_scale := [1.25, 1.25, 1.45, 1.6, 1.6, 1.45, 1.0, 1.0]
	for coop in [false, true]:
		globals.coop = coop
		for cycle in [0, 1, 7, 30]:
			spawner._endless_cycle = cycle
			for wave in catalog.waves:
				for index in kinds.size():
					var data := definition(kinds[index])
					var multiplier: float = spawner._health_multiplier(data, wave.difficulty)
					var expected: float = coop_scale[index] if coop else 1.0
					if data.durability in [EnemyDefinition.Durability.SPECIALIST, EnemyDefinition.Durability.HEAVY]:
						var cap := 1.15 if data.durability == EnemyDefinition.Durability.SPECIALIST else 1.2
						expected *= lerpf(1.0, cap, clampf((wave.difficulty - 1.0) / 2.55, 0.0, 1.0)) * minf(1.0 + cycle * 0.03, 1.2)
					check(is_equal_approx(data.max_health * multiplier, base_health[index] * expected), "%s health: coop=%s cycle=%s difficulty=%s" % [kinds[index], coop, cycle, wave.difficulty])
				for kind in ["drone", "tie"]:
					for rank in range(DAMAGE.max_rank + 1):
						var loadout := PlayerLoadout.new(STATS)
						for upgrade_index in rank:
							loadout.apply(DAMAGE)
						var enemy = make_enemy(kind, wave.difficulty)
						var damage := 1.0 + loadout.damage_bonus
						var hits := 0
						while not enemy.destroyed and hits < 4:
							enemy._hit_something(damage, false)
							hits += 1
						check(hits == ceili((2.5 if coop else 2.0) / damage), "%s impacts: coop=%s rank=%s" % [kind, coop, rank])
						enemy.free()
	spawner._endless_cycle = 0
	globals.coop = false
	var fractional = make_enemy("drone", 1.15, true)
	fractional._hit_something(1.25, false)
	check(is_equal_approx(fractional.life, 2.75), "fractional damage must remain in enemy health")
	check(is_equal_approx(fractional._elite_indicator.current_health, 2.75), "elite bar must retain fractional health")
	fractional.free()
	for coop in [false, true]:
		globals.coop = coop
		spawner._endless_cycle = 7
		var carrier = make_enemy("mother_ship", 3.55, true)
		var expected := 76.0 * 1.2 * 1.2 * 2.0 * (1.6 if coop else 1.0)
		check(is_equal_approx(carrier.max_life, expected), "carrier must apply wave, endless, elite and duo once")
		check(carrier._mounted_turrets.size() == 2, "carrier must retain both mounted turrets")
		for turret in carrier._mounted_turrets:
			check(is_equal_approx(turret.max_life, expected / 4.0), "mounted turrets must inherit the complete hull multiplier once")
			turret._hit_something(0.25, false)
			check(is_equal_approx(turret.life, turret.max_life - 0.25), "mounted damage must preserve fractions")
		carrier._hit_something(0.25, false)
		check(is_equal_approx(carrier.life, expected - 0.25), "carrier damage must preserve fractions")
		carrier.free()

func check_intervals_and_lanes() -> void:
	spawner._endless_cycle = 0
	for coop in [false, true]:
		globals.coop = coop
		for index in catalog.waves.size():
			spawner.wave_index = index
			var wave: WaveDefinition = catalog.waves[index]
			for rule in wave.rules:
				var data: EnemyDefinition = spawner._rule_definition(rule)
				check(data != null, "every catalog rule must resolve its enemy definition")
				if data == null:
					continue
				var expected: float = rule.interval * spawner._timeline_scale(wave) * spawner._pace_multiplier(wave.difficulty) * 1.1
				if data.durability in [EnemyDefinition.Durability.FODDER, EnemyDefinition.Durability.FIGHTER]:
					expected *= 0.9 if index >= 8 else (0.95 if index >= 3 else 1.0)
					if coop:
						expected /= 1.1
				check(is_equal_approx(spawner._spawn_interval(rule, wave.difficulty, spawner._timeline_scale(wave)), expected), "only common enemy intervals receive the density bonuses")
				var lanes: Array[int] = spawner._formation_lanes(rule, rule.formation, 0)
				check(lanes.size() <= rule.formation, "duo must not add formation members")
				for lane in lanes:
					check(lane >= rule.spawn_min and lane <= rule.spawn_max, "formation must retain its allowed lanes")
				if rule.pattern == SpawnRule.Pattern.GAP_WALL:
					check(lanes.size() <= rule.spawn_max - rule.spawn_min - 1, "gap walls must preserve two open lanes")
		check(spawner._enemy_cap() == (60 if coop else 45), "enemy cap must follow the run mode")
	spawner.wave_index = 17
	spawner._endless_cycle = 6
	for rule in catalog.waves[17].rules:
		check(spawner._endless_formation_bonus(rule) == (2 if rule.endless_formation_growth else 0), "endless formation growth must remain capped")
		check(spawner._endless_elite_bonus(rule) == (2 if rule.endless_elite_growth else 0), "endless elite growth must remain capped")

func check_upgrades_and_rewards() -> void:
	var loadout := PlayerLoadout.new(STATS)
	for rank in range(1, 11):
		loadout.apply(RATE)
		check(is_equal_approx(loadout.fire_delay, 0.2 - rank * 0.007), "each fire-rate rank must reduce delay by 0.007 seconds")
	check(loadout.apply(RATE).capped, "fire rate must cap at ten ranks")
	for rank in range(1, 11):
		loadout.apply(SIDE)
		check(is_equal_approx(loadout.side_damage_bonus, (rank - 1) * 0.08), "side damage must increase only after unlocking")
	var reward_kinds := ["drone", "tie", "interceptor", "turret", "mother_ship", "mother_ship_turret", "asteroid", "big_asteroid"]
	var power_chances := [5, 3, 12, 15, 16, 3, 1, 3]
	var plasma_chances := [11, 12, 63, 59, 55, 30, 4, 9]
	for index in reward_kinds.size():
		var kind: String = reward_kinds[index]
		var enemy = make_enemy(kind, 1.0)
		var counts := [0, 0, 0]
		for roll in range(100):
			counts[enemy._reward_for_roll(roll)] += 1
		check(counts[enemy.RewardDrop.PLASMA] == plasma_chances[index], "%s plasma probability must remain unchanged" % kind)
		check(counts[enemy.RewardDrop.POWER_UP] == power_chances[index], "%s power-up probability must match the reduced profile" % kind)
		enemy.free()
	var pool := ProjectilePool.new()
	stage.add_child(pool)
	var packed: PackedScene = load("res://scenes/player/player_shot.tscn")
	var shot = ProjectilePool.spawn(packed, Vector2(300, 300), stage)
	shot.player_Id = "player1"
	shot.set_damage_bonus(1.5)
	check(is_equal_approx(shot.damage, 2.5), "primary damage must reach its existing cap")
	ProjectilePool.despawn(shot)
	await process_frame
	var reused = ProjectilePool.spawn(packed, Vector2(300, 300), stage)
	check(reused == shot and is_equal_approx(reused.damage, 1.0), "pooled shots must reset their damage before reuse")
	ProjectilePool.despawn(reused)
	await process_frame
	var player = load("res://scenes/player/player.tscn").instantiate()
	stage.add_child(player)
	check(player.energy == 3 and STATS.energy_max == 12, "players must start with three health while retaining the repair cap")
	player.set_physics_process(false)
	player.shooting_audio.stream = null
	for rank in DAMAGE.max_rank:
		player.apply_upgrade(DAMAGE)
	var previous_score: int = globals.score
	check(player.apply_upgrade(DAMAGE).capped and globals.score == previous_score + 500, "capped damage pickups must retain the 500-point conversion")
	for rank in range(7):
		player.apply_upgrade(SIDE)
	var before := stage.get_child_count()
	player.weapons.fire_primary()
	check(stage.get_child_count() - before == 3, "side rank seven must fire three projectiles")
	player.apply_upgrade(SIDE)
	before = stage.get_child_count()
	player.weapons.fire_primary()
	check(stage.get_child_count() - before == 5, "side rank eight must unlock the extra two projectiles")
	player.hit_audio.stream = null
	player.explosion_audio.stream = null
	for remaining_health in [2, 1, 0]:
		player.touched = false
		player.vitals.hit()
		check(player.energy == remaining_health, "three unprotected hits must exhaust starting health")
	check(player.state == player.State.DYING, "the third unprotected hit must enter the death state")
	player.weapons.player = null
	player.vitals.player = null
	player.free()
	pool.free()

func check_runtime_caps_and_duo_death() -> void:
	globals.coop = true
	spawner._endless_cycle = 0
	var rule: SpawnRule
	for candidate in catalog.waves[0].rules:
		if spawner._is_common(spawner._rule_definition(candidate)):
			rule = candidate.duplicate()
			break
	rule.spawn_gap = 0.0
	var timer := create_timer(10.0)
	for index in range(60):
		spawner._active_enemies[index] = false
	var before: int = spawner.get_child_count()
	await spawner._spawn_formation(rule, 0, spawner._wave_generation, 0, timer, 1.0, true, 1.0)
	check(spawner.get_child_count() == before, "a full enemy cap must block additional formations")
	spawner._active_enemies.clear()
	for index in range(3):
		spawner._active_enemies[index] = true
	await spawner._spawn_formation(rule, 0, spawner._wave_generation, 0, timer, 1.0, true, 1.0)
	check(spawner.get_child_count() - before == rule.formation, "actual duo formations must retain their authored size")
	for child in spawner.get_children():
		if child.is_in_group("enemy"):
			check(not child.elite, "three active elites must prevent another elite")
			check(is_equal_approx(child.max_life, 2.5), "actual spawns must apply duo common health once")
			child.free()
	spawner._active_enemies.clear()
	var world := Node2D.new()
	world.set_script(load("res://scenes/world/world.gd"))
	world.nbr_Player = 2
	world._on_player_died()
	check(world.nbr_Player == 1 and globals.coop, "one-player death must leave the duo run active")
	check(spawner._enemy_cap() == 60 and is_equal_approx(spawner._health_multiplier(definition("drone"), 1.0), 1.25), "future spawns must retain duo durability and caps after death")
	world.free()

func run() -> void:
	globals = root.get_node("global")
	catalog = load("res://data/waves/wave_catalog.tres")
	globals.Debug = false
	stage = Node2D.new()
	root.add_child(stage)
	spawner = load("res://scenes/waves/wave_spawner.gd").new()
	spawner.config = CONFIG
	spawner.catalog = WaveCatalog.new()
	for index in CONFIG.lane_count:
		var marker := Marker2D.new()
		marker.name = "spawnPos%d" % index
		marker.position = Vector2(120 + index * 34, -20)
		spawner.add_child(marker)
	stage.add_child(spawner)
	spawner.catalog = catalog
	check(CONFIG.is_valid(), "approved balance configuration must be valid")
	check(catalog.waves.size() == 18, "catalog must retain 18 waves")
	check_health_and_impacts()
	check_intervals_and_lanes()
	await check_upgrades_and_rewards()
	await check_runtime_caps_and_duo_death()
	stage.queue_free()
	await process_frame
	print("Alpha 9 balance: %s (%d checks)" % ["PASS" if failures == 0 else "FAIL", checks])
	quit(0 if failures == 0 else 1)
