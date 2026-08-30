extends Node

const MotherShipScene := preload("res://scenes/enemies/mother_ship.tscn")
const MountedTurretScene := preload("res://scenes/enemies/mother_ship_turret.tscn")
const TurretScene := preload("res://scenes/enemies/turret.tscn")
const TurretShotScene := preload("res://scenes/combat/turret_shot.tscn")
const SpawnerConfig := preload("res://data/waves/wave_spawner_config.tres")
const Layers := preload("res://core/collision_layers.gd")

var _failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	await _test_mother_ship_arrival_and_anchors()
	await _test_spawner_cleanup_and_non_contact_modules()
	await _test_turret_patterns_and_targeting()
	await _test_module_shutdown_and_pool_reset()
	await get_tree().create_timer(0.1).timeout
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	if _failures.is_empty():
		print("Enemy identity harness: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _test_mother_ship_arrival_and_anchors() -> void:
	var world := _new_world()
	var ships: Array[Node] = []
	for _index in range(4):
		var ship := MotherShipScene.instantiate()
		world.add_child(ship)
		ships.append(ship)
	await get_tree().physics_frame

	_expect(get_tree().get_node_count_in_group("mother_ship") == 3, "Only three mothership anchors may be occupied.")
	var expected: Array[Vector2] = ships[0]._anchor_positions()
	for index in range(3):
		_expect(ships[index].anchor_index == index, "Mothership anchors must be claimed center, left, then right.")
		_expect(ships[index].global_position.is_equal_approx(expected[index]), "Mothership must teleport to its claimed anchor.")
	_expect(not is_instance_valid(ships[3]), "A fourth mothership must be discarded without entering combat.")
	_expect(not ships[0].monitoring, "The mothership hull must not monitor collisions during teleport telegraph.")
	_expect((ships[0].get_node("CollisionShape2D") as CollisionShape2D).disabled, "The mothership collider must be disabled during teleport telegraph.")
	_expect(ships[0].modulate.a < 0.6, "The teleport telegraph must visibly fade the complete mothership hierarchy.")
	_expect(get_tree().get_node_count_in_group("enemy_Shot") == 0, "No enemy shot may spawn before materialization.")

	await get_tree().create_timer(0.7).timeout
	await get_tree().physics_frame
	_expect(ships[0].monitoring, "The mothership hull must become active after materialization.")
	_expect(not (ships[0].get_node("CollisionShape2D") as CollisionShape2D).disabled, "The mothership collider must activate after materialization.")
	_expect(ships[0].modulate.is_equal_approx(Color.WHITE), "The mothership must restore its normal modulation after materialization.")
	_expect(ships[0]._mounted_turrets.size() == 2, "Each mothership must create two mounted turrets.")

	var first_module: TurretEnemy = ships[0]._mounted_turrets[0]
	ships[0]._destroy()
	await get_tree().physics_frame
	_expect(not first_module.visible, "Destroying the hull must hide its mounted turrets immediately.")
	_expect(first_module.get_node("ShotDelay").is_stopped(), "Destroying the hull must stop mounted turret timers.")
	_expect(not first_module.monitoring, "Destroying the hull must disable mounted turret monitoring.")
	var replacement := MotherShipScene.instantiate()
	world.add_child(replacement)
	await get_tree().process_frame
	_expect(not is_instance_valid(replacement), "An exploding mothership must reserve its anchor until it leaves the tree.")
	world.queue_free()
	await get_tree().process_frame

func _test_spawner_cleanup_and_non_contact_modules() -> void:
	global.coop = false
	var world := _new_world()
	var spawner := WaveSpawner.new()
	spawner.catalog = WaveCatalog.new()
	spawner.config = SpawnerConfig
	for lane in range(SpawnerConfig.lane_count):
		var marker := Marker2D.new()
		marker.name = "spawnPos" + str(lane)
		marker.position = Vector2(125 + lane * 74, -56)
		spawner.add_child(marker)
	world.add_child(spawner)
	var baseline := spawner._active_enemies.size()
	var rule := SpawnRule.new()
	rule.scene = MotherShipScene
	for lane in range(4):
		spawner._spawn_at(rule, lane, 1.0, false)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(spawner._active_enemies.size() == baseline + 3, "A rejected fourth mothership must leave the WaveSpawner tracker cleanly.")

	var ship := get_tree().get_first_node_in_group("mother_ship")
	var module: TurretEnemy = ship._mounted_turrets[0]
	_expect(module.is_in_group("mounted_turret"), "Mounted turrets must be identifiable by player contact handling.")
	_expect(module.collision_mask == Layers.PLAYER_SHOT, "Mounted turrets must not monitor player contact.")
	rule = null
	spawner.catalog = null
	world.queue_free()
	await get_tree().process_frame

func _test_turret_patterns_and_targeting() -> void:
	global.coop = true
	var world := _new_world()
	var near_player := Node2D.new()
	near_player.position = Vector2(420, 620)
	near_player.add_to_group("player")
	near_player.set_physics_process(true)
	world.add_child(near_player)
	var far_player := Node2D.new()
	far_player.position = Vector2(820, 700)
	far_player.add_to_group("player")
	far_player.set_physics_process(true)
	world.add_child(far_player)

	var turret := TurretScene.instantiate() as TurretEnemy
	turret.position = Vector2(400, 180)
	world.add_child(turret)
	await get_tree().process_frame
	turret.stop_patterns()
	_expect(turret._lock_nearest_target(), "A turret must acquire a living player target.")
	_expect(turret._locked_target == near_player.global_position, "A turret must lock the nearest living player.")
	var second_turret := TurretScene.instantiate() as TurretEnemy
	second_turret.position = Vector2(800, 180)
	world.add_child(second_turret)
	await get_tree().process_frame
	second_turret.stop_patterns()
	_expect(second_turret._lock_nearest_target(), "Each co-op turret must acquire a target independently.")
	_expect(second_turret._locked_target == far_player.global_position, "Independent co-op targeting must allow different nearest players.")

	var before_ring := get_tree().get_nodes_in_group("enemy_Shot").size()
	turret._fire_ring()
	var first_ring := get_tree().get_nodes_in_group("enemy_Shot").slice(before_ring)
	_expect(first_ring.size() == TurretEnemy.RING_SHOT_COUNT, "A radial pattern must contain ten projectiles.")
	var velocity_sum := Vector2.ZERO
	for shot in first_ring:
		var velocity := Vector2(shot.speedX, shot.speedY)
		velocity_sum += velocity
		_expect(is_equal_approx(velocity.length(), TurretEnemy.RING_SPEED * Enemy.PROJECTILE_SPEED_MULTIPLIER), "Every radial projectile must use the configured speed.")
	_expect(velocity_sum.length() < 0.1, "Radial projectile velocities must be evenly distributed.")

	var first_angle := Vector2(first_ring[0].speedX, first_ring[0].speedY).angle()
	turret._fire_ring()
	var second_ring := get_tree().get_nodes_in_group("enemy_Shot").slice(before_ring + TurretEnemy.RING_SHOT_COUNT)
	var second_angle := Vector2(second_ring[0].speedX, second_ring[0].speedY).angle()
	_expect(is_equal_approx(absf(angle_difference(first_angle, second_angle)), deg_to_rad(TurretEnemy.RING_OFFSET_DEGREES)), "Successive radial patterns must alternate by eighteen degrees.")

	var before_burst := get_tree().get_nodes_in_group("enemy_Shot").size()
	turret._has_locked_target = true
	turret._begin_aim_burst()
	turret._continue_aim_burst()
	turret._continue_aim_burst()
	var burst := get_tree().get_nodes_in_group("enemy_Shot").slice(before_burst)
	_expect(burst.size() == 3, "An aimed burst must contain three projectiles.")
	var base_direction: Vector2 = turret.get_node("shootPos").global_position.direction_to(near_player.global_position)
	for index in range(burst.size()):
		var velocity := Vector2(burst[index].speedX, burst[index].speedY)
		var expected_angle: float = base_direction.rotated(deg_to_rad(TurretEnemy.AIM_SPREAD[index])).angle()
		_expect(is_equal_approx(angle_difference(velocity.angle(), expected_angle), 0.0), "Aimed burst spread must be -5, 0, and +5 degrees.")
	world.queue_free()
	await get_tree().process_frame
	global.coop = false

func _test_module_shutdown_and_pool_reset() -> void:
	var world := _new_world()
	var module := MountedTurretScene.instantiate() as TurretEnemy
	world.add_child(module)
	module.activate_patterns()
	module._hit_something(module.life)
	_expect(module.destroyed, "A mounted turret must be independently destructible.")
	_expect(module.get_node("ShotDelay").is_stopped(), "Destroying a mounted turret must stop its pattern timer.")
	_expect(module.is_in_group("mounted_turret"), "Mounted turrets must be identifiable as non-contact enemies.")
	_expect(module.collision_mask == Layers.PLAYER_SHOT, "Mounted turrets must monitor player shots without monitoring players.")

	var first := ProjectilePool.spawn(TurretShotScene, Vector2.ZERO, world)
	first.speedX = 123.0
	first.speedY = 456.0
	ProjectilePool.despawn(first)
	await get_tree().process_frame
	await get_tree().process_frame
	var reused := ProjectilePool.spawn(TurretShotScene, Vector2.ZERO, world)
	_expect(reused == first, "The projectile pool must reuse the released turret projectile.")
	_expect(is_zero_approx(reused.speedX), "A reused turret projectile must reset horizontal speed.")
	_expect(is_equal_approx(reused.speedY, 550.0), "A reused turret projectile must reset vertical speed.")
	world.queue_free()
	await get_tree().process_frame

func _new_world() -> Node2D:
	var world := Node2D.new()
	add_child(world)
	var pool := ProjectilePool.new()
	world.add_child(pool)
	return world

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
