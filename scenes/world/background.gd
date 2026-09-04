extends ParallaxBackground

const BASE_SPEED_Y := 80.0
const MIN_SPEED_Y := 60.0
const MAX_SPEED_Y := 100.0
const SPEED_RESPONSE := 130.0

@export var speed_Y: float = BASE_SPEED_Y
@export var speed_X: float = 0.0

var _player_intents := {}
var _target_speed_y := BASE_SPEED_Y

func _ready() -> void:
	Events.player_motion_changed.connect(_on_player_motion_changed)


func _process(delta: float) -> void:
	speed_Y = move_toward(speed_Y, _target_speed_y, SPEED_RESPONSE * delta)
	scroll_base_offset += Vector2(speed_X, speed_Y) * delta

func _on_player_motion_changed(player_id: String, vertical_intent: float) -> void:
	_player_intents[player_id] = clampf(vertical_intent, -1.0, 1.0)
	var total := 0.0
	for intent in _player_intents.values():
		total += float(intent)
	var average := total / float(_player_intents.size())
	_target_speed_y = lerpf(MIN_SPEED_Y, MAX_SPEED_Y, (average + 1.0) * 0.5)
