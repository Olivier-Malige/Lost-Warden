extends Node2D

var _age := 0.0
var _protection := 0.0

func present(can_trigger: bool, protection: float, delta := 0.0) -> void:
	visible = can_trigger or protection > 0.0
	if _protection != protection:
		_protection = protection
		queue_redraw()
	if not visible: return
	_age += delta
	modulate.a = lerpf(0.35, 1.0, protection) if protection > 0.0 else 0.75 + sin(_age * TAU / 1.2) * 0.25

func _draw() -> void:
	var center := Vector2(0, -20)
	draw_polyline(PackedVector2Array([center + Vector2(0, -4), center + Vector2(4, 0), center + Vector2(0, 4), center + Vector2(-4, 0), center + Vector2(0, -4)]), Color("101522"), 3.0)
	draw_polyline(PackedVector2Array([center + Vector2(0, -4), center + Vector2(4, 0), center + Vector2(0, 4), center + Vector2(-4, 0), center + Vector2(0, -4)]), Color.WHITE, 1.0)
	draw_rect(Rect2(center - Vector2.ONE, Vector2(2, 2)), Color.WHITE)
	if _protection > 0.0:
		for index in 6:
			var direction := Vector2.from_angle(TAU * index / 6)
			draw_line((direction * 12).round(), (direction * 16).round(), Color.WHITE, 2.0)
