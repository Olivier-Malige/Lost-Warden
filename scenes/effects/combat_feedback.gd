extends Node2D

const MAX_ACTIVE := 64
const GOLD := Color("ffd35a")
const IVORY := Color("fff8e8")

var collecting := false
var accent := GOLD
var target: Node2D
var age := 0.0
var duration := 0.22
var destination := Vector2.ZERO


static func spawn(parent: Node, at: Vector2, color: Color = GOLD, collector: Node2D = null) -> Node2D:
	if parent.get_tree().get_nodes_in_group(&"combat_feedback").size() >= MAX_ACTIVE:
		return null
	var effect := new()
	effect.accent = color
	effect.target = collector
	effect.collecting = collector != null
	effect.duration = 0.38 if effect.collecting else 0.22
	parent.add_child(effect)
	effect.global_position = at
	if collector != null:
		effect.destination = effect.to_local(collector.global_position)
	return effect


func _ready() -> void:
	add_to_group(&"combat_feedback")
	z_index = 8


func _process(delta: float) -> void:
	age += delta
	if age >= duration:
		queue_free()
		return
	if is_instance_valid(target):
		destination = to_local(target.global_position)
	queue_redraw()


func _draw() -> void:
	var progress := clampf(age / duration, 0.0, 1.0)
	var tint := accent
	tint.a = 1.0 - progress * progress
	if collecting:
		for i in range(6):
			var direction := Vector2.from_angle(TAU * float(i) / 6.0)
			var start := direction * (9.0 + 7.0 * sin(progress * PI))
			var point := start.lerp(destination, progress * progress)
			draw_rect(Rect2(point.round(), Vector2(3, 3)), tint)
			if progress < 0.7:
				draw_rect(Rect2((point + direction * 4.0).round(), Vector2(2, 2)), tint.darkened(0.35))
	else:
		for i in range(7):
			var direction := Vector2.from_angle(TAU * float(i) / 7.0)
			var point := direction * (2.0 + 15.0 * progress)
			draw_line(point.round(), (point + direction * (4.0 * (1.0 - progress))).round(), tint, 2.0)
	if progress < 0.24:
		draw_rect(Rect2(Vector2(-3, -1), Vector2(6, 2)), IVORY)
		draw_rect(Rect2(Vector2(-1, -3), Vector2(2, 6)), IVORY)
