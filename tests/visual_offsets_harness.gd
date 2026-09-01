extends Node

const MotherShipScene := preload("res://scenes/enemies/mother_ship.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")

var _failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var ship := MotherShipScene.instantiate()
	var player := PlayerScene.instantiate() as Player
	add_child(ship)
	add_child(player)
	player.position = Vector2(533, 400)
	await get_tree().process_frame
	_expect(ship.get_node("LeftTurretMount").position == Vector2(-34, 4), "The left mothership turret must sit closer to the hull.")
	_expect(ship.get_node("RightTurretMount").position == Vector2(34, 4), "The right mothership turret must sit closer to the hull.")
	var beam_particles := player.get_node("BeamChargeParticles") as GPUParticles2D
	_expect(beam_particles.position == Vector2.ZERO, "The plasma emission effect must remain centered on the player sprite.")
	_expect(not beam_particles.visible and not beam_particles.emitting, "An empty plasma reserve must not emit particles.")
	player.beam_charge = 10.0
	player.update_beam_charge()
	_expect(beam_particles.visible and beam_particles.emitting, "Stored plasma must emit particles before the beam is fired.")
	var charge_material := beam_particles.process_material as ParticleProcessMaterial
	var low_charge_radius := charge_material.emission_sphere_radius
	var low_particle_scale := charge_material.scale_min
	player.beam_charge = 100.0
	player.update_beam_charge()
	_expect(charge_material.emission_sphere_radius > low_charge_radius, "The plasma emission radius must grow with the reserve charge.")
	_expect(charge_material.scale_min > low_particle_scale, "The plasma particles themselves must grow with the reserve charge.")
	player.beam_charge = 40.0
	player.update_beam_charge()
	player._start_beam()
	player._stop_beam()
	_expect(beam_particles.visible and beam_particles.emitting, "Stopping the beam must preserve particles while plasma remains.")
	player.beam_charge = 0.0
	player.update_beam_charge()
	_expect(not beam_particles.visible and not beam_particles.emitting, "Draining the reserve to zero must hide its particles.")
	_expect(player.continuous_beam.position == player.primary_origin.position, "The continuous beam must use the central weapon marker.")
	player.continuous_beam.activate(player.id_Player, Player.STATS.beam_damage, false)
	_expect(player.continuous_beam.core_line.modulate.r > player.continuous_beam.core_line.modulate.b, "Player one beam must be red.")
	player.continuous_beam._update_geometry()
	var shape := player.continuous_beam.collision_shape.shape as RectangleShape2D
	_expect(is_equal_approx(shape.size.x, 32.0), "The normal continuous beam must be thirty-two pixels wide.")
	_expect(is_equal_approx(shape.size.y, player.continuous_beam.global_position.y), "The beam collision must reach the top of the visible viewport.")
	_expect(player.continuous_beam.outer_line.points.size() == 2 and player.continuous_beam.outer_line.points[1].y < 0.0, "The beam visual must extend upward from the player.")
	player.continuous_beam.set_overdrive(true)
	_expect(is_equal_approx(shape.size.x, 64.0), "Overdrive must widen the collision to sixty-four pixels.")
	player.continuous_beam.activate("player2", Player.STATS.beam_damage, false)
	_expect(player.continuous_beam.core_line.modulate.b > player.continuous_beam.core_line.modulate.r, "Player two beam must remain blue.")
	player.continuous_beam.deactivate()
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
