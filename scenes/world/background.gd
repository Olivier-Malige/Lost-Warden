extends ParallaxBackground

@export var speed_Y: int = 0
@export var speed_X: int = 0


func _process(delta: float) -> void:
	scroll_base_offset += Vector2(speed_X, speed_Y) * delta
