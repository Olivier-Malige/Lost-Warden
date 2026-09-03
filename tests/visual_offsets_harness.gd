extends Node

const MotherShipScene := preload("res://scenes/enemies/mother_ship.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")
const PlayerShotScene := preload("res://scenes/player/player_shot.tscn")
const PlayerSideShotScene := preload("res://scenes/player/player_side_shot.tscn")
const EnemyShotScenes: Array[PackedScene] = [
	preload("res://scenes/combat/interceptor_shot.tscn"),
	preload("res://scenes/combat/interceptor_side_shot.tscn"),
	preload("res://scenes/combat/mother_ship_shot.tscn"),
	preload("res://scenes/combat/tie_shot.tscn"),
	preload("res://scenes/combat/turret_shot.tscn"),
]

var _failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	await _test_player_laser_appearance()
	await _test_enemy_projectile_appearance()
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
	_expect(player.continuous_beam.core_line.modulate.g < 0.2, "Player one beam core must remain saturated red instead of turning pink.")
	_expect(player.continuous_beam.halo_line.width > player.continuous_beam.outer_line.width, "The beam glow must extend beyond both sides of the beam.")
	_expect((player.continuous_beam.halo_line.material as CanvasItemMaterial).blend_mode == CanvasItemMaterial.BLEND_MODE_ADD, "The beam glow must use additive blending.")
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


func _test_player_laser_appearance() -> void:
	var laser_scenes: Array[PackedScene] = [PlayerShotScene, PlayerSideShotScene]
	for packed_scene in laser_scenes:
		var shot: Area2D = packed_scene.instantiate()
		shot.player_Id = "player1"
		add_child(shot)
		shot.setPowerAnim()
		var sprites: Array = shot.get_children().filter(func(child: Node) -> bool: return child is Sprite2D)
		var trails: Array = shot.get_children().filter(func(child: Node) -> bool: return child is Line2D)
		var source_sprite := shot.get_child(0) as Sprite2D
		var glow := shot.get_node_or_null("LaserGlow") as Sprite2D
		_expect(sprites.size() == 2, "Player lasers must use exactly one glow copy around the authored sprite.")
		_expect(trails.is_empty(), "Player lasers must keep their original appearance without procedural trails.")
		_expect(source_sprite.modulate == Color.WHITE, "Player laser sprites must keep their authored colors.")
		_expect(source_sprite.self_modulate.r > 1.0 and source_sprite.self_modulate.r == source_sprite.self_modulate.g and source_sprite.self_modulate.g == source_sprite.self_modulate.b, "Player laser cores must receive a neutral brightness boost.")
		var source_width := source_sprite.texture.get_width() / source_sprite.hframes * source_sprite.scale.x
		var source_height := source_sprite.texture.get_height() / source_sprite.vframes * source_sprite.scale.y
		var glow_width := glow.texture.get_width() * glow.scale.x if glow != null else 0.0
		var glow_height := glow.texture.get_height() * glow.scale.y if glow != null else 0.0
		_expect(glow != null and glow_width > source_width, "Player laser glow must be wider than the authored sprite.")
		_expect(glow != null and glow_width / source_width > glow_height / source_height, "Player laser glow must favor the sides instead of surrounding the sprite evenly.")
		_expect(glow != null and glow.modulate.a <= 0.55, "Player laser glow must remain restrained.")
		var glow_material := glow.material as CanvasItemMaterial if glow != null else null
		_expect(glow_material != null and glow_material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD, "Player laser glow must use additive blending.")
		shot.queue_free()
		await get_tree().process_frame


func _test_enemy_projectile_appearance() -> void:
	for packed_scene in EnemyShotScenes:
		var shot := packed_scene.instantiate() as Area2D
		add_child(shot)
		var source_sprite := shot.get_node("Sprite2D") as Sprite2D
		var glow := shot.get_node_or_null("ProjectileGlow") as Sprite2D
		_expect(source_sprite.self_modulate.r > 1.0, "Enemy projectile cores must be brighter than their authored sprites.")
		_expect(glow != null and glow.modulate.a <= 0.5, "Enemy projectiles must use a restrained glow.")
		var glow_material := glow.material as CanvasItemMaterial if glow != null else null
		_expect(glow_material != null and glow_material.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD, "Enemy projectile glow must use additive blending.")
		shot.queue_free()
		await get_tree().process_frame

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
