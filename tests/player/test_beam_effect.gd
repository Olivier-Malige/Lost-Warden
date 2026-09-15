extends SceneTree

var _failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)

func _run() -> void:
	var packed = load("res://scenes/player/beam/continuous_beam.tscn")
	var red = packed.instantiate()
	var blue = packed.instantiate()
	root.add_child(red)
	root.add_child(blue)
	for beam in [red, blue]:
		beam.position = Vector2(200, 400)
		beam.beam_audio.stream = null
	red.activate("player1", 3.0, false)
	blue.activate("player2", 3.0, true)
	red.set_physics_process(false)
	blue.set_physics_process(false)
	await process_frame
	await process_frame
	_check(red.flow_material != blue.flow_material, "co-op beams must have independent materials")
	for beam in [red, blue]:
		_check(is_equal_approx(beam.collision_shape.shape.size.x, beam.outer_line.width * beam.collision_width_multiplier), "collision must follow normal and overdrive width with the configured tolerance")
		_check(beam.collision_shape.position.is_equal_approx(Vector2(0, -200)), "collision must span the visible beam from its origin to the screen top")
	_check(red.flow_material.get_shader_parameter("team_row") == 0.0, "red must use the first atlas row")
	_check(blue.flow_material.get_shader_parameter("team_row") == 1.0, "blue must use the second atlas row")
	red._physics_process(0.08)
	_check(red.flow_material.get_shader_parameter("frame_index") == 0.0, "flow must hold its frame for readability")
	red._physics_process(0.08)
	_check(red.flow_material.get_shader_parameter("frame_index") == 1.0, "flow must advance after 160 ms")
	_check(blue.flow_material.get_shader_parameter("frame_index") == 0.0, "red animation must not affect blue")
	red._physics_process(0.48)
	_check(red.flow_material.get_shader_parameter("frame_index") == 0.0, "flow must loop after four frames")
	blue.set_overdrive(false)
	_check(not blue.flow_material.get_shader_parameter("overdrive"), "overdrive expiry must restore normal art")
	_check(is_equal_approx(blue.outer_line.width, blue.beam_width), "normal width must be restored")
	_check(is_equal_approx(blue.collision_shape.shape.size.x, blue.beam_width * blue.collision_width_multiplier), "collision must shrink when overdrive ends")
	_check(is_equal_approx(blue.collision_shape.shape.size.y, 400.0), "beam must reach the screen top")
	for beam in [red, blue]:
		beam.deactivate()
	await process_frame
	for beam in [red, blue]:
		_check(not beam.visible and not beam.active and beam.collision_shape.disabled, "deactivation must hide and disable the beam")
	red.activate("player1", 3.0, false)
	_check(red.flow_material.get_shader_parameter("frame_index") == 0.0, "reactivation must restart animation")
	red.deactivate()
	red.queue_free()
	blue.queue_free()
	await process_frame
	print("Beam effect: ", "PASS" if _failures == 0 else "FAIL")
	quit(0 if _failures == 0 else 1)
