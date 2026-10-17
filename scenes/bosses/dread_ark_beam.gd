extends Node2D

const TEXTURE := preload("res://assets/sprites/combat/animation_rework/dread_ark_beam_sheet.png")

@export var offsets := PackedFloat32Array([0.0])

var active := false
var warning := false
var width := 12.0
var central_width := 12.0
var _elapsed := 0.0
var _hit_left := 0.0

func warn() -> void:
	active = false
	warning = true
	_elapsed = 0.0
	show()
	queue_redraw()

func fire() -> void:
	active = true
	warning = false
	_hit_left = 0.0
	show()
	queue_redraw()

func stop() -> void:
	active = false
	warning = false
	hide()

func _physics_process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	queue_redraw()
	if not active:
		return
	_hit_left -= delta
	if _hit_left > 0.0:
		return
	_hit_left = 0.15
	for player in get_tree().get_nodes_in_group("player"):
		if not player.has_method("_hit_something"):
			continue
		if player.get("state") != null and int(player.state) >= 2:
			continue
		var shape := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if not shape or not shape.shape or shape.disabled:
			continue
		var player_rect := shape.global_transform * shape.shape.get_rect()
		for offset in offsets:
			var lane_width := central_width if is_zero_approx(offset) else width
			var beam_rect := Rect2(global_position + Vector2(offset - lane_width * 0.5, 0), Vector2(lane_width, _length()))
			if beam_rect.intersects(player_rect):
				player._hit_something(10)
				break

func _length() -> float:
	return maxf(get_viewport_rect().end.y - global_position.y, 0.0)

func _draw() -> void:
	var length := _length()
	for offset in offsets:
		var lane_width := central_width if is_zero_approx(offset) else width
		if warning:
			draw_rect(Rect2(Vector2(offset - lane_width * 0.5, 0), Vector2(lane_width, length)), Color(1, 0.24, 0.32, 0.15))
			for y in range(0, ceili(length), 12):
				draw_line(Vector2(offset, y), Vector2(offset, minf(y + 5, length)), Color(1, 0.45, 0.55, 0.8), 1)
		elif active:
			var visual_width := 32.0 * lane_width / 12.0
			var frame := int(_elapsed / 0.075) % 4
			for y in range(0, ceili(length), 64):
				var height := minf(64, length - y)
				draw_texture_rect_region(TEXTURE, Rect2(offset - visual_width * 0.5, y, visual_width, height), Rect2(frame * 32, 0, 32, height))
