extends Node

const MotherShipScene := preload("res://scenes/enemies/mother_ship.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")

var _failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var ship := MotherShipScene.instantiate()
	var player := PlayerScene.instantiate()
	add_child(ship)
	add_child(player)
	await get_tree().process_frame

	_expect(ship.get_node("LeftTurretMount").position == Vector2(-34, 4), "The left mothership turret must sit closer to the hull.")
	_expect(ship.get_node("RightTurretMount").position == Vector2(34, 4), "The right mothership turret must sit closer to the hull.")
	_expect(player.get_node("BeamChargeParticles").position == Vector2(0, -28), "The beam charge effect must remain above the player sprite.")
	_expect(PlayerWeapons.BEAM_ORIGIN_OFFSET == Vector2(0, -16), "Fired beams must start above the standard weapon markers.")
	_expect(player.primary_origin.position == Vector2(0, -18.4036), "The beam offset must not move the primary weapon marker.")
	var shot_count := get_tree().get_node_count_in_group("player_Shot")
	player.weapons._spawn_beam(Player.WEAPON_BEAM_MINI.projectile, player.primary_origin)
	var spawned_shots := get_tree().get_nodes_in_group("player_Shot").slice(shot_count)
	var lowest_segment_y := -INF
	for shot in spawned_shots:
		lowest_segment_y = maxf(lowest_segment_y, shot.global_position.y)
	_expect(spawned_shots.size() == 2, "The mini beam must still create both configured segments.")
	_expect(lowest_segment_y <= player.primary_origin.global_position.y - 32.0, "The lowest fired beam segment must remain visibly clear of the player.")
	for shot in spawned_shots:
		shot.queue_free()

	ship.queue_free()
	player.queue_free()
	await get_tree().process_frame
	if _failures.is_empty():
		print("Visual offsets harness: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
