extends Camera2D

const MAX_SHAKE := 26.0
const SCORE_POPUP := preload("res://scenes/ui/score.tscn")
const NOISE_SPEED := 36.0

var _noise := FastNoiseLite.new()
var _noise_position := 0.0
var _shake_strength := 0.0
var _shake_time := 0.0
var _shake_duration := 0.0
var _flash_tween: Tween
var _score_popup: Node2D
@onready var _flash: ColorRect = $"../FeedbackLayer/Flash"

func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 0.18
	Events.screen_shake_requested.connect(_on_screen_shake_requested)
	Events.screen_flash_requested.connect(_on_screen_flash_requested)
	Events.score_popup_requested.connect(_on_score_popup_requested)

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

func _on_screen_shake_requested(strength: float, duration: float) -> void:
	_shake_strength = minf(_shake_strength + maxf(strength, 0.0), MAX_SHAKE)
	_shake_time = maxf(_shake_time, duration)
	_shake_duration = maxf(_shake_duration, _shake_time)

func _on_screen_flash_requested(color: Color, duration: float) -> void:
	if _flash_tween:
		_flash_tween.kill()
	_flash.color = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_score_popup_requested(points: int, combo: int, multiplier: float, world_position: Vector2) -> void:
	call_deferred("_accumulate_score_popup", points, combo, multiplier, world_position)

func _accumulate_score_popup(points: int, combo: int, multiplier: float, world_position: Vector2) -> void:
	if is_instance_valid(_score_popup):
		_score_popup.add_score(points, combo, multiplier, world_position)
		return
	_score_popup = SCORE_POPUP.instantiate()
	_score_popup.setScore = points
	_score_popup.combo = combo
	_score_popup.multiplier = multiplier
	_score_popup.position = world_position
	get_parent().add_child(_score_popup)
