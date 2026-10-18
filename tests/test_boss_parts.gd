extends SceneTree

class BeamTarget:
	extends Area2D
	var hits := 0
	var state := 0
	func _hit_something(_damage: int) -> void:
		hits += 1

var _checks := 0
var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)

func _settle() -> void:
	for frame in 3:
		await physics_frame
		await process_frame

func _shots() -> Array[Node]:
	return get_nodes_in_group("enemy_Shot").filter(func(shot): return not shot.get_meta("pooled", false))

func _recycle() -> void:
	var pool = load("res://scenes/combat/projectile_pool.gd")
	for shot in _shots():
		pool.despawn(shot)
	await process_frame

func _shoot(stage: Node2D, at: Vector2, reflected := false) -> Variant:
	var pool = load("res://scenes/combat/projectile_pool.gd")
	var packed = load("res://scenes/combat/mother_ship_shot.tscn" if reflected else "res://scenes/player/player_shot.tscn")
	var shot = pool.spawn(packed, at, stage)
	shot.damage = 10.0
	if reflected:
		shot.trowbackByShield = true
	else:
		shot.player_Id = "player1"
		shot.setPowerAnim()
	shot.set_physics_process(false)
	return shot

func _test_parts(coop: bool) -> void:
	var globals = root.get_node("global")
	globals.coop = coop
	globals.reset_run(91)
	var stage := Node2D.new()
	root.add_child(stage)
	stage.add_child(load("res://scenes/combat/projectile_pool.gd").new())
	var data = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	boss.run_coop = coop
	boss.position = Vector2(320, 82)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss.get_node("sound_Shooting").stream = null
	boss.get_node("sound_Explode").stream = null
	var port = boss.get_node("PortCannon")
	var starboard = boss.get_node("StarboardCannon")
	var armor = boss.get_node("Armor")
	var expected := 144.0 if coop else 90.0
	_check(port.life == expected and starboard.life == expected, "cannons have independent resource-configured solo/co-op health")
	port._hit_something(10.0)
	_check(port.life == expected, "cannons cannot be damaged during boss entry")
	boss._physics_process(2.0)
	await _settle()
	_check(get_nodes_in_group("enemy").size() == 1, "hit zones do not inflate enemy counts or encounter body caps")
	_check(boss.get_node("CollisionShape2D").shape.size.x == 24.0, "the boss health hitbox is restricted to its central core")
	var core_health: float = boss.life
	var shot = _shoot(stage, port.global_position)
	await _settle()
	_check(port.life == expected - 10.0 and starboard.life == expected and boss.life == core_health, "a real projectile damages only the cannon it touches")
	_check(shot.get_meta("pooled", false), "a cannon hit recycles the player projectile safely after physics")
	var sprite = boss.get_node("Sprite2D")
	_check(sprite.material.shader == boss.PART_HIT_SHADER and sprite.get_instance_shader_parameter(&"port_hit_flash") > 0.0 and sprite.get_instance_shader_parameter(&"starboard_hit_flash") == 0.0, "cannon hits flash only the struck side through its shader parameter")
	shot = _shoot(stage, starboard.global_position, true)
	await _settle()
	_check(starboard.life == expected - 10.0 and boss.life == core_health and shot.get_meta("pooled", false), "shield-reflected enemy projectiles can damage a cannon")
	shot = _shoot(stage, boss.global_position + Vector2(-22, 0))
	await _settle()
	_check(boss.life == core_health and port.life == expected - 10.0 and shot.get_meta("pooled", false), "hull armor absorbs player shots without damaging the boss or its cannons")
	var metallic := get_nodes_in_group("combat_feedback").any(func(effect): return effect.accent == Color("96a5b5"))
	_check(metallic, "armor impacts use a distinct metallic feedback color")
	shot = _shoot(stage, boss.global_position + Vector2(0, 22))
	await _settle()
	_check(boss.life == core_health - 10.0 and port.life == expected - 10.0, "a real core hit reduces the boss health independently of cannon health")
	core_health = boss.life
	var beam = load("res://scenes/player/beam/continuous_beam.tscn").instantiate()
	stage.add_child(beam)
	beam.beam_audio.stream = null
	beam.position = Vector2(port.global_position.x, 400)
	beam.activate("player1", 7.0, false)
	beam.set_physics_process(false)
	await _settle()
	beam._damage_overlaps()
	_check(port.life == expected - 17.0 and boss.life == core_health and starboard.life == expected - 10.0, "the continuous player laser damages a cannon without leaking damage into the core")
	beam.deactivate()
	await _settle()
	beam.free()
	boss._locked_target = boss.global_position + Vector2(0, 300)
	boss._pattern = data.phase_one_patterns[1]
	boss._salvos_left = 3
	boss._fire_salvo()
	_check(_shots().size() == 10, "two intact cannons fire both phase-one fans")
	await _recycle()
	port._hit_something(port.life - 10.0)
	shot = _shoot(stage, port.global_position)
	await _settle()
	_check(shot.get_meta("pooled", false), "a lethal cannon hit safely recycles its projectile during the physics callback")
	_check(port.destroyed and not starboard.destroyed and boss.life == core_health, "destroying a cannon leaves the other cannon and boss health intact")
	_check(boss.get_node("Sprite2D").texture == boss.DAMAGED_HULLS[0], "destroying the port cannon selects the matching persistent wreck atlas")
	await _settle()
	_check(port.get_node("CollisionShape2D").disabled and not port.monitorable, "destroyed cannon collision is disabled through deferred physics-safe changes")
	port._hit_something(1000.0)
	_check(port.life == 0.0, "repeated hits cannot destroy or reward a cannon twice")
	boss._physics_process(boss._pattern.burst_interval)
	_check(_shots().size() == 5 and _shots().all(func(missile): return missile.global_position.x > boss.global_position.x), "remaining salvos fire only from the surviving cannon")
	await _recycle()
	boss._hit_something(boss.life - boss.max_life * 0.49, false)
	boss._physics_process(0.96)
	boss._pattern = data.phase_two_patterns[1]
	boss._salvos_left = 4
	boss._gun_side = 0
	boss._fire_salvo()
	_check(_shots().size() == 7 and boss._gun_side == 1, "phase two selects the surviving cannon instead of a destroyed gun")
	await _recycle()
	starboard._hit_something(1000.0)
	_check(boss._salvos_left == 0 and boss.attack == boss.Attack.RECOVER, "destroying the last cannon interrupts the current missile burst")
	_check(boss.get_node("Sprite2D").texture == boss.DAMAGED_HULLS[2], "both destroyed guns remain visible as wrecks")
	_check(globals.score == 0, "destroying optional cannons does not grant the boss kill reward")
	boss._physics_process(0.4)
	boss._attack_left = 0.0
	boss._attack_cycle = 1
	boss._physics_process(0.01)
	_check(boss.attack == boss.Attack.CHARGE and boss._pattern.kind == BossAttackPattern.Kind.SPIRAL and _shots().is_empty(), "a disarmed boss skips cannon salvos but retains core patterns")
	boss._hit_something(1.0, false)
	_check(boss.phase == 1 and port.destroyed and starboard.destroyed and boss.get_node("Sprite2D").texture == boss.DAMAGED_HULLS[2], "further core damage never restores destroyed cannons")
	boss.attack = boss.Attack.IDLE
	boss._attack_left = 0.0
	boss._attack_cycle = 3
	boss._physics_process(0.01)
	_check(boss.attack == boss.Attack.BEAM_CHARGE and boss._beam.warning, "destroying missile cannons preserves the three-beam attack")
	boss._physics_process(data.beam_charge_time)
	_check(boss._beam.active and boss._beam.offsets == PackedFloat32Array([0.0]), "destroying both cannons leaves only the central beam")
	_check(boss._beam.central_width == 24.0 and boss._beam.width == 12.0, "the central beam remains twice as wide after both cannons are destroyed")
	boss._physics_process(data.beam_fire_time)
	boss._physics_process(0.84)
	boss._attack_left = 0.0
	boss._attack_cycle = 3
	boss._physics_process(0.01)
	_check(boss.attack == boss.Attack.BEAM_CHARGE and boss._beam.warning, "a disarmed boss retains its beam on subsequent cycles")
	var parts: Array = boss.get_cannon_snapshot()
	_check(parts.size() == 2 and parts[0].destroyed and parts[1].health == 0.0, "debug snapshots expose each cannon's actual state")
	boss._hit_something(boss.life, false)
	await _settle()
	_check(boss.destroyed and not boss._beam.active and armor.get_node("PortShape").disabled, "core destruction defeats the boss and disables all remaining zones and hazards")
	stage.free()
	await _settle()

func _test_starboard_and_stop() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var data = load("res://data/bosses/dread_ark.tres")
	var boss = data.scene.instantiate()
	boss.boss_data = data
	boss.position = Vector2(320, 82)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss._physics_process(2.0)
	var port = boss.get_node("PortCannon")
	var starboard = boss.get_node("StarboardCannon")
	boss._beam.set_physics_process(false)
	var targets: Array[BeamTarget] = []
	for x in [280.0, 320.0, 360.0, 340.0, 344.0]:
		var target := BeamTarget.new()
		target.position = Vector2(x, 300)
		target.add_to_group("player")
		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		shape.shape = RectangleShape2D.new()
		shape.shape.size = Vector2(18, 18)
		target.add_child(shape)
		stage.add_child(target)
		targets.append(target)
	boss._beam.fire()
	boss._beam._physics_process(0.01)
	_check(targets[0].hits == 1 and targets[1].hits == 1 and targets[2].hits == 1, "intact cannons retain both side beams alongside the central beam")
	_check(targets[3].hits == 1 and targets[4].hits == 0, "the widened central damage zone matches its larger visual while retaining a narrow safe gap")
	starboard._hit_something(1000.0)
	_check(starboard.destroyed and not port.destroyed and boss._available_guns() == [0], "the right cannon can be destroyed first without affecting the left cannon")
	_check(boss.get_node("Sprite2D").texture == boss.DAMAGED_HULLS[1], "destroying the right cannon first selects its own wreck atlas")
	_check(boss._beam.offsets == PackedFloat32Array([-40.0, 0.0]) and boss._beam.central_width == 24.0, "destroying one cannon removes its beam without shrinking the center")
	boss._beam._physics_process(boss.boss_data.beam_damage_interval + 0.01)
	_check(targets[0].hits == 2 and targets[1].hits == 2 and targets[2].hits == 1, "destroying a cannon cancels damage in its active beam immediately")
	boss._beam.warn()
	boss._salvos_left = 3
	boss.stop_combat()
	var remaining: float = port.life
	port._hit_something(1000.0)
	await _settle()
	_check(port.life == remaining and not boss._beam.warning and boss._salvos_left == 0, "run stop cancels all boss hazards and makes intact cannons harmless")
	_check(port.get_node("CollisionShape2D").disabled and not port.visible, "run stop disables and hides surviving cannon feedback")
	stage.free()
	await _settle()
	boss = data.scene.instantiate()
	boss.boss_data = data
	root.add_child(boss)
	boss.set_physics_process(false)
	_check(not boss.get_node("PortCannon").destroyed and not boss.get_node("StarboardCannon").destroyed and boss.get_node("PortCannon").life == data.cannon_health, "a new boss encounter starts with fresh independent cannon health")
	boss.free()
	await _settle()

func _run() -> void:
	await _test_parts(false)
	await _test_parts(true)
	await _test_starboard_and_stop()
	var data = load("res://data/bosses/dread_ark.tres").duplicate()
	data.cannon_health = 0.0
	_check(not data.is_valid(), "boss definitions require positive cannon durability")
	data.cannon_health = 120.0
	data.central_beam_width = 6.0
	_check(not data.is_valid(), "the central beam cannot be narrower than the side beams")
	print("Boss destructible parts: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)
