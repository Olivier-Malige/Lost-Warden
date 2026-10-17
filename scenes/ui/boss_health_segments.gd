extends Control

var thresholds := PackedFloat32Array()

func _ready() -> void:
	resized.connect(queue_redraw)

func set_thresholds(values: PackedFloat32Array) -> void:
	thresholds = values.duplicate()
	queue_redraw()

func _draw() -> void:
	for threshold in thresholds:
		var x := roundf(size.x * threshold)
		draw_rect(Rect2(x - 1, 0, 3, size.y), Color("10131c"))
		draw_line(Vector2(x, 0), Vector2(x, 2), Color("b8a571"), 1)
		draw_line(Vector2(x, size.y - 2), Vector2(x, size.y), Color("b8a571"), 1)
