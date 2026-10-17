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

func _target(at: Vector2) -> BeamTarget:
	var target := BeamTarget.new()
	target.position = at
	target.add_to_group("player")
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(18, 18)
	target.add_child(shape)
	root.add_child(target)
	return target

func _test_beam() -> void:
	var beam = load("res://scenes/bosses/dread_ark_beam.gd").new()
	root.add_child(beam)
	beam.set_physics_process(false)
	beam.position = Vector2(320, 100)
	beam.offsets = PackedFloat32Array([-40, 0, 40])
	var inside := _target(Vector2(320, 300))
	var port := _target(Vector2(280, 300))
	var starboard := _target(Vector2(360, 300))
	var gap := _target(Vector2(340, 300))
	var outside := _target(Vector2(400, 300))
	var wide := _target(Vector2(320, 350))
	wide.get_node("CollisionShape2D").shape.size = Vector2(110, 18)
	beam.warn()
	beam._physics_process(1.0)
	_check(inside.hits == 0 and outside.hits == 0, "beam preparation never damages a player")
	_check(port.hits == 0 and starboard.hits == 0, "both side beam warnings are harmless")
	beam.fire()
	beam._physics_process(0.01)
	_check(inside.hits == 1 and outside.hits == 0, "only collision shapes intersecting the beam's bright core take damage")
	_check(port.hits == 1 and starboard.hits == 1, "both side beams damage players simultaneously with the central beam")
	_check(gap.hits == 0, "the space between beam cores remains safe")
	_check(wide.hits == 1, "overlapping multiple lanes causes only one damage application per tick")
	beam._physics_process(0.05)
	_check(inside.hits == 1, "beam damage has a bounded tick interval")
	inside.position.x = 400
	beam._physics_process(0.2)
	_check(inside.hits == 1, "moving out of the locked lane avoids beam damage")
	inside.position.x = 320
	inside.state = 2
	beam._physics_process(0.2)
	_check(inside.hits == 1, "dying players are not hit again")
	inside.state = 0
	inside.get_node("CollisionShape2D").disabled = true
	beam._physics_process(0.2)
	_check(inside.hits == 1, "disabled player colliders are ignored")
	beam.set_physics_process(true)
	paused = true
	var before: float = beam._elapsed
	await create_timer(0.1).timeout
	_check(beam._elapsed == before, "pause stops beam flow and its damage clock")
	beam.set_physics_process(false)
	paused = false
	beam.stop()
	inside.get_node("CollisionShape2D").disabled = false
	beam._physics_process(1.0)
	_check(not beam.active and not beam.visible and inside.hits == 1, "stopping the beam cancels damage immediately")
	var side_hits := port.hits
	beam._physics_process(1.0)
	_check(port.hits == side_hits and starboard.hits == side_hits and gap.hits == 0, "stopping cancels every beam lane together")
	beam.free()
	inside.free()
	port.free()
	starboard.free()
	gap.free()
	wide.free()
	outside.free()

func _chaser(stage: Node2D, seed_value: int) -> Variant:
	var enemy = load("res://scenes/enemies/drone.tscn").instantiate()
	var context := EnemySpawnContext.new()
	context.movement_profile = load("res://data/enemies/movement/boss_drone_chase.tres")
	context.movement_seed = seed_value
	enemy.configure_spawn(context)
	enemy.position = Vector2(250, 110)
	stage.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.set_deferred("monitoring", false)
	enemy.set_deferred("monitorable", false)
	return enemy

func _test_chase() -> void:
	var stage := Node2D.new()
	root.add_child(stage)
	var first := _target(Vector2(350, 340))
	var second := _target(Vector2(180, 340))
	var left = _chaser(stage, 0)
	var right = _chaser(stage, 1)
	left._update_movement(0.1)
	right._update_movement(0.1)
	_check(left.speedX > 0 and right.speedX < 0, "seeded co-op assignments split pursuit across living players")
	first.position.x = 150
	left._update_movement(0.2)
	_check(left.speedX < 0, "a distant drone steers toward the player's current position")
	left.position = Vector2(200, 230)
	first.position = Vector2(205, 345)
	left._update_movement(0.1)
	_check(left._chase_target.get_ref() == first, "nearby drones retain their selected living target")
	var before_turn: float = left.speedX
	first.position = Vector2(450, 345)
	left._update_movement(0.2)
	_check(left.speedX > before_turn, "a drone keeps steering while the player remains outside its final approach")
	left.position = Vector2(280, 380)
	first.position = Vector2(300, 300)
	left.speedY = 125.0
	var exit_velocity := Vector2(left.speedX, left.speedY)
	var turned_up := false
	for index in 300:
		left._update_movement(1.0 / 60.0)
		turned_up = turned_up or left.speedY < 0.0
	_check(not turned_up and left._chase_committed, "a drone never turns upward after committing its final approach")
	_check(left.global_position.y > root.get_visible_rect().end.y, "a missed drone exits through the bottom of the screen")
	first.position = left.position + Vector2(200, 100)
	left._update_movement(0.2)
	_check(Vector2(left.speedX, left.speedY) == exit_velocity and left.speedY > 0.0, "a committed drone preserves its heading even when the player moves ahead again")
	_check(left._movement_profile.chase_speed == 125.0, "boss drones use the slightly increased pursuit speed")
	second.state = 2
	right._update_movement(0.1)
	_check(right._chase_target.get_ref() == first, "a pursuing drone retargets a surviving co-op partner")
	first.free()
	second.free()
	right._update_movement(0.1)
	_check(right._chase_target == null, "drones continue safely when no players remain")
	stage.free()

func _test_hud(coop: bool) -> void:
	root.get_node("global").coop = coop
	var events = root.get_node("Events")
	var world = load("res://scenes/world/world.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var spawner = world.get_node("waveGenerator")
	spawner.set_physics_process(false)
	var hud = world.get_node("hud/BossHealth")
	_check(not hud.visible, "boss health stays hidden during normal encounters")
	spawner.debug_start_boss()
	await process_frame
	await process_frame
	var boss = spawner._boss
	boss.set_physics_process(false)
	_check(boss._beam.offsets == PackedFloat32Array([-40, 0, 40]), "the boss scene places beams under its left, central and right emitters")
	_check(hud.visible and hud.get_node("Bar").max_value == boss.max_life, "boss entry displays the correct solo/co-op maximum health")
	boss._physics_process(2.0)
	boss._hit_something(boss.max_life * 0.36, false)
	_check(is_equal_approx(hud.get_node("Bar").value, boss.life) and hud.get_node("Header/Title").text == "DREAD ARK", "the boss bar follows health while displaying only its name")
	_check(hud.get_node_or_null("Header/Health") == null and not hud.get_node("Bar").show_percentage, "gameplay boss health has no numeric or phase text")
	_check(hud.get_node("Bar/Segments").thresholds == boss.boss_data.phase_thresholds, "bar segmentation uses the actual resource thresholds")
	world._layout_for_width(960.0)
	_check(is_equal_approx(hud.get_global_transform_with_canvas().origin.x + hud.size.x * 0.5, 480.0), "the boss bar stays centered over the combat area on wider viewports")
	world._layout_for_width(640.0)
	var expected := 6 if coop else 4
	boss._physics_process(0.78)
	boss._attack_left = 0.0
	boss._physics_process(0.01)
	_check(boss.attack == boss.Attack.LAUNCH and spawner._pending.is_empty(), "the boss announces reinforcements with the launch animation")
	boss._physics_process(0.35)
	_check(spawner._pending.is_empty(), "reinforcements wait until the running lights reach the launch frame")
	boss._physics_process(0.02)
	_check(spawner._pending.size() == expected, "reinforcement waves contain four solo or six co-op drones")
	boss._physics_process(0.36)
	_check(spawner._pending.size() == expected, "one launch animation emits only one reinforcement wave")
	_check(spawner._pending.all(func(item): return item.context.movement_profile.mode == MovementProfile.Mode.CHASE), "every boss reinforcement receives the chase profile without changing normal drones")
	boss._beam.fire()
	boss._hit_something(boss.max_life, false)
	_check(not hud.visible and not boss._beam.active, "boss defeat hides the bar and stops beam damage immediately")
	events.boss_started.emit(&"test", "Test Boss", 123.5)
	events.boss_phase_thresholds_changed.emit(PackedFloat32Array([0.8, 0.3]))
	events.boss_health_changed.emit(61.25, 123.5, 4)
	_check(hud.visible and is_equal_approx(hud.get_node("Bar").value, 61.25), "the bar preserves fractional health and can reset for a later boss")
	_check(hud.get_node("Bar/Segments").thresholds == PackedFloat32Array([0.8, 0.3]), "a different boss can change the segment positions through events")
	events.game_over_requested.emit()
	_check(not hud.visible, "game over hides an interrupted boss bar")
	spawner.stop_run()
	world.free()
	await process_frame

func _run() -> void:
	root.get_node("global").Debug = true
	await _test_beam()
	_test_chase()
	await _test_hud(false)
	await _test_hud(true)
	var data = load("res://data/bosses/dread_ark.tres")
	_check(data.is_valid() and data.phase_thresholds.size() == 2, "the revised three-phase boss data is valid")
	data = data.duplicate()
	data.salvo_count = 0
	_check(not data.is_valid(), "boss bursts require at least one salvo")
	data.salvo_count = 3
	data.salvo_interval = 0.1
	_check(not data.is_valid(), "salvos leave enough time for the firing animation")
	data.salvo_interval = 0.25
	data.phase_thresholds = PackedFloat32Array([0.3, 0.65])
	_check(not data.is_valid(), "phase thresholds must decrease strictly")
	await process_frame
	print("Boss pressure: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)
