extends GPUParticles2D

const MIN_SPEED_SCALE := 0.8
const MAX_SPEED_SCALE := 1.25
const SPEED_RESPONSE := 1.2

var _player_intents := {}
var _target_speed_scale := 1.0


func _ready() -> void:
	texture = _create_streak_texture()
	Events.player_motion_changed.connect(_on_player_motion_changed)


func _process(delta: float) -> void:
	speed_scale = move_toward(speed_scale, _target_speed_scale, SPEED_RESPONSE * delta)


func _on_player_motion_changed(player_id: String, vertical_intent: float) -> void:
	_player_intents[player_id] = clampf(vertical_intent, -1.0, 1.0)
	var total := 0.0
	for intent in _player_intents.values():
		total += float(intent)
	var average := total / float(_player_intents.size())
	_target_speed_scale = lerpf(MIN_SPEED_SCALE, MAX_SPEED_SCALE, (average + 1.0) * 0.5)


func _create_streak_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.72, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.58, 0.72, 0.9, 0.0),
		Color(0.78, 0.88, 1.0, 0.28),
		Color(1.0, 0.97, 0.85, 0.72),
	])
	var streak := GradientTexture2D.new()
	streak.gradient = gradient
	streak.width = 2
	streak.height = 24
	streak.fill_from = Vector2(0.5, 0.0)
	streak.fill_to = Vector2(0.5, 1.0)
	return streak
