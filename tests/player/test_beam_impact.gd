extends SceneTree

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

func _enemy(stage: Node2D, at: Vector2, width := 24.0) -> Variant:
	var enemy = load("res://scenes/enemies/drone.tscn").instantiate()
	enemy.definition = enemy.definition.duplicate()
	enemy.definition.max_health = 100
	enemy.position = at
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 20)
	enemy.get_node("CollisionShape2D").shape = shape
	stage.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy

func _run() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var beam = load("res://scenes/player/beam/continuous_beam.tscn").instantiate()
	stage.add_child(beam)
	beam.position = Vector2(200, 400)
	beam.beam_audio.stream = null
	beam.activate("player1", 3.0, false)
	beam.set_physics_process(false)
	var far = _enemy(stage, Vector2(200, 180))
	var near = _enemy(stage, Vector2(200, 300))
	await _settle()
	beam._update_geometry()
	_check(beam._impact_target == near, "the beam selects the closest obstacle regardless of scene insertion order")
	_check(absf(beam.outer_line.points[1].y + 90.0) < 1.0, "the visible beam ends at the first collider's surface")
	_check(beam.halo_line.points == beam.outer_line.points and is_equal_approx(beam._shape.size.y, -beam.outer_line.points[1].y), "beam artwork, halo and collider share the shortened endpoint")
	beam._damage_overlaps()
	_check(near.life == 97.0 and far.life == 100.0, "only the first enemy takes beam damage")
	_check(not get_nodes_in_group("combat_feedback").is_empty(), "the contact creates localized impact feedback")
	near.position.x = 280
	await _settle()
	beam._damage_overlaps()
	_check(beam._impact_target == far and far.life == 97.0 and near.life == 97.0, "moving the front enemy away reveals the target behind it")
	far.life = 1.0
	beam._damage_overlaps()
	_check(far.destroyed and beam._impact_target == null and is_equal_approx(beam._shape.size.y, 400.0), "a lethal hit immediately extends past the destroyed collider")
	near.free()
	far.free()
	var touching = _enemy(stage, Vector2(200, 400))
	await _settle()
	beam._damage_overlaps()
	_check(beam._impact_target == touching and beam._shape.size.y == 1.0 and touching.life == 97.0, "an obstacle overlapping the emitter blocks and takes damage without revealing targets behind it")
	touching.free()
	await _settle()
	var edge = _enemy(stage, Vector2(214, 260), 12.0)
	await _settle()
	beam._update_geometry()
	_check(beam._impact_target == null, "normal beam width does not hit an obstacle outside its path")
	beam.set_overdrive(true)
	_check(beam._impact_target == edge, "the widened overdrive beam stops on off-center collisions")
	beam._damage_overlaps()
	_check(edge.life == 95.5, "overdrive preserves its configured damage multiplier at the first impact")
	edge.free()
	await _settle()
	beam.set_overdrive(false)
	var boss_data = load("res://data/bosses/dread_ark.tres")
	var boss = boss_data.scene.instantiate()
	boss.boss_data = boss_data
	boss.position = Vector2(200, 150)
	stage.add_child(boss)
	boss.set_physics_process(false)
	boss.attack = boss.Attack.IDLE
	var behind = _enemy(stage, Vector2(178, 60), 12.0)
	beam.position.x = 178
	await _settle()
	beam._damage_overlaps()
	_check(beam._impact_target == boss.get_node("Armor"), "boss armor blocks the beam at the hull rather than letting it pass through")
	_check(boss.life == boss.max_life and behind.life == 100.0, "an armored impact damages neither the core nor an enemy behind it")
	beam.position.x = 200
	await _settle()
	beam._damage_overlaps()
	_check(beam._impact_target == boss and boss.life == boss.max_life - 3.0, "aiming at the core stops and damages the actual boss hitbox")
	beam.position.x = 160
	await _settle()
	beam._damage_overlaps()
	_check(beam._impact_target == boss.get_node("PortCannon") and boss.get_node("PortCannon").life == boss_data.cannon_health - 3.0, "the boss cannon remains a separate beam impact target")
	var blue = load("res://scenes/player/beam/continuous_beam.tscn").instantiate()
	stage.add_child(blue)
	blue.position = Vector2(500, 400)
	blue.beam_audio.stream = null
	blue.activate("player2", 3.0, true)
	blue.set_physics_process(false)
	_check(blue._impact_target == null and blue._shape.size.y == 400.0 and beam._shape.size.y < 400.0, "co-op beams have independent impact targets and lengths")
	_check(blue.impact_cast.shape != beam.impact_cast.shape, "co-op cast widths use independent shape resources")
	beam.deactivate()
	_check(beam._impact_target == null and not beam.visible, "deactivating the beam clears the impact target")
	stage.free()
	await process_frame
	print("Beam impact: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)
