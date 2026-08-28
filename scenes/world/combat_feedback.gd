extends Camera2D

const MAX_SHAKE := 18.0

var _rng := RandomNumberGenerator.new()
var _shake_strength := 0.0
var _shake_time := 0.0
var _shake_duration := 0.0
var _flash_tween: Tween
var _hit_stop_id := 0
@onready var _flash: ColorRect = $"../FeedbackLayer/Flash"

func _ready() -> void:
	_rng.randomize()
	Events.screen_shake_requested.connect(_on_screen_shake_requested)
	Events.screen_flash_requested.connect(_on_screen_flash_requested)
	Events.hit_stop_requested.connect(_on_hit_stop_requested)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if _shake_time <= 0.0:
		offset = Vector2.ZERO
		_shake_strength = 0.0
		_shake_duration = 0.0
		return
	_shake_time = maxf(_shake_time - delta, 0.0)
	var decay := _shake_time / maxf(_shake_duration, 0.001)
	var strength := _shake_strength * decay * decay
	offset = Vector2(
		_rng.randf_range(-strength, strength),
		_rng.randf_range(-strength, strength)
	)

func _on_screen_shake_requested(strength: float, duration: float) -> void:
	var quality_scale := 0.65 if global.saveData.config.graphic == "low" else 1.0
	_shake_strength = minf(maxf(_shake_strength, strength * quality_scale), MAX_SHAKE)
	_shake_time = maxf(_shake_time, duration)
	_shake_duration = maxf(_shake_duration, _shake_time)

func _on_screen_flash_requested(color: Color, duration: float) -> void:
	if _flash_tween:
		_flash_tween.kill()
	var quality_scale := 0.65 if global.saveData.config.graphic == "low" else 1.0
	color.a *= quality_scale
	_flash.color = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_hit_stop_requested(duration: float) -> void:
	_hit_stop_id += 1
	var request_id := _hit_stop_id
	get_tree().paused = true
	await get_tree().create_timer(duration, true, false, true).timeout
	if request_id == _hit_stop_id:
		get_tree().paused = false
