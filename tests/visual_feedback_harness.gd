extends Node

const ForegroundSpeedParticlesScene := preload("res://scenes/world/foreground_speed_particles.tscn")
const CombatFeedbackScript := preload("res://scenes/world/combat_feedback.gd")
const Save := preload("res://core/save_service.gd")
const TEST_SAVE_PATH := "res://.godot/visual_feedback_harness_data.json"
const TEST_TEMP_PATH := "res://.godot/visual_feedback_harness_data.json.tmp"

var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_foreground_speed_particles()
	await _test_combat_feedback()
	_test_removed_graphics_setting()
	if _failures.is_empty():
		print("Visual feedback harness: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _test_foreground_speed_particles() -> void:
	var particles := ForegroundSpeedParticlesScene.instantiate() as GPUParticles2D
	add_child(particles)
	await get_tree().process_frame
	_expect(particles.amount == 40, "Foreground speed particles must keep the bounded forty-particle budget.")
	_expect(particles.local_coords, "Foreground speed particles must remain screen-relative.")
	_expect(particles.texture is GradientTexture2D, "Foreground speed particles must generate a streak texture.")
	particles._on_player_motion_changed("player1", 1.0)
	_expect(is_equal_approx(particles._target_speed_scale, 1.25), "Forward motion must select maximum foreground speed.")
	particles._on_player_motion_changed("player2", -1.0)
	_expect(is_equal_approx(particles._target_speed_scale, 1.025), "Opposing co-op inputs must average foreground speed.")
	particles._process(1.0)
	_expect(is_equal_approx(particles.speed_scale, 1.025), "Foreground speed must converge smoothly on its co-op target.")
	particles.queue_free()
	await get_tree().process_frame


func _test_combat_feedback() -> void:
	var feedback_layer := CanvasLayer.new()
	feedback_layer.name = "FeedbackLayer"
	var flash := ColorRect.new()
	flash.name = "Flash"
	feedback_layer.add_child(flash)
	add_child(feedback_layer)
	var camera := Camera2D.new()
	camera.name = "CombatFeedback"
	camera.set_script(CombatFeedbackScript)
	add_child(camera)
	await get_tree().process_frame
	camera._on_screen_shake_requested(18.0, 0.28)
	_expect(is_equal_approx(camera._shake_strength, 18.0), "A player hit must request eighteen pixels of shake.")
	camera._on_screen_shake_requested(14.0, 0.2)
	_expect(is_equal_approx(camera._shake_strength, 26.0), "Rapid impacts must accumulate at the twenty-six-pixel cap.")
	camera._process(0.05)
	_expect(absf(camera.offset.x) <= 26.0 and absf(camera.offset.y) <= 26.0, "Noise shake must remain within the configured cap.")
	_expect(is_zero_approx(camera.rotation), "Combat feedback must never rotate the pixel-art camera.")
	camera._process(1.0)
	_expect(camera.offset == Vector2.ZERO, "Combat feedback must restore the camera offset after decay.")
	camera.queue_free()
	feedback_layer.queue_free()
	await get_tree().process_frame


func _test_removed_graphics_setting() -> void:
	_remove_test_save_files()
	var old_save := {
		"config": {
			"music": false,
			"sound": true,
			"fullscreen": false,
			"player1": "keyboard",
			"player2": "gamepad1",
			"graphic": "low",
		},
	}
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		_failures.append("The visual feedback harness could not create its isolated save file.")
		return
	file.store_line(JSON.stringify(old_save))
	file.close()
	var defaults := {
		"config": {
			"music": true,
			"sound": true,
			"fullscreen": true,
			"player1": "gamepad1",
			"player2": "keyboard",
		},
	}
	var loaded := Save.load_data(defaults, TEST_SAVE_PATH, TEST_TEMP_PATH)
	_expect(not loaded.config.has("graphic"), "Legacy graphics quality must be ignored while loading old saves.")
	_expect(loaded.config.music == false and loaded.config.player1 == "keyboard", "Removing graphics quality must preserve other old preferences.")
	Save.save_data(loaded, TEST_SAVE_PATH, TEST_TEMP_PATH)
	file = FileAccess.open(TEST_SAVE_PATH, FileAccess.READ)
	if file == null:
		_failures.append("The visual feedback harness could not reopen its isolated save file.")
		_remove_test_save_files()
		return
	var persisted: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	_expect(persisted is Dictionary and not persisted.config.has("graphic"), "The next save must remove the legacy graphics key.")
	_remove_test_save_files()


func _remove_test_save_files() -> void:
	for path in [TEST_SAVE_PATH, TEST_TEMP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
