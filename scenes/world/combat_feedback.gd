extends Camera2D

const MAX_SHAKE := 13.0
const MAX_STRONG_SHAKE := 26.0
const NOISE_SPEED := 36.0

var _noise := FastNoiseLite.new()
var _noise_position := 0.0
var _shake_strength := 0.0
var _shake_time := 0.0
var _shake_duration := 0.0
var _flash_tween: Tween
@onready var _flash: ColorRect = $"../FeedbackLayer/Flash"

func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 0.18
	Events.screen_shake_requested.connect(_on_screen_shake_requested)
	Events.screen_flash_requested.connect(_on_screen_flash_requested)

func _process(delta: float) -> void:
	if _shake_time <= 0.0:
		offset = Vector2.ZERO
		_shake_strength = 0.0
		_shake_duration = 0.0
		return
	_shake_time = maxf(_shake_time - delta, 0.0)
	if _shake_time <= 0.0:
		offset = Vector2.ZERO
		_shake_strength = 0.0
		_shake_duration = 0.0
		return
	var decay := _shake_time / maxf(_shake_duration, 0.001)
	var strength := _shake_strength * decay * decay
	_noise_position += NOISE_SPEED * delta
	offset = Vector2(
		_noise.get_noise_2d(_noise_position, 0.0) * strength,
		_noise.get_noise_2d(0.0, _noise_position) * strength
	)

# Scripted heavy impacts can exceed the normal cap without amplifying ordinary combat.
func _on_screen_shake_requested(strength: float, duration: float) -> void:
	var impulse := maxf(strength, 0.0) * 0.5
	var limit := clampf(maxf(_shake_strength, impulse), MAX_SHAKE, MAX_STRONG_SHAKE)
	_shake_strength = minf(_shake_strength + impulse, limit)
	_shake_time = maxf(_shake_time, duration)
	_shake_duration = maxf(_shake_duration, _shake_time)

func _on_screen_flash_requested(color: Color, duration: float) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash.color = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
