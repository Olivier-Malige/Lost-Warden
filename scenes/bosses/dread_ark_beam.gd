extends Node2D

const TEXTURE := preload("res://assets/sprites/combat/animation_rework/dread_ark_beam_sheet.png")

@export var offsets := PackedFloat32Array([0.0])

var active := false
var warning := false
var width := 12.0
var central_width := 12.0
var damage_interval := 0.35
var _elapsed := 0.0
var _contact_cooldowns: Dictionary[int, float] = {}

func warn() -> void:
	active = false
	warning = true
	_elapsed = 0.0
	_contact_cooldowns.clear()
	hide()
	queue_redraw()

func fire() -> void:
	active = true
	warning = false
	_contact_cooldowns.clear()
	show()
	queue_redraw()

func stop() -> void:
	active = false
	warning = false
	_contact_cooldowns.clear()
	hide()

func _physics_process(delta: float) -> void:
	if not visible or get_tree().paused:
		return
	_elapsed += delta
	queue_redraw()
	if not active:
		return
	for id in _contact_cooldowns.keys():
		_contact_cooldowns[id] -= delta
		if _contact_cooldowns[id] <= 0.0:
			_contact_cooldowns.erase(id)
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
			var defenses: Node = player.get("defenses")
			var intersects: bool = defenses.intersects_beam(beam_rect, player_rect) if defenses != null else beam_rect.intersects(player_rect)
			if intersects:
				var id := player.get_instance_id()
				if not _contact_cooldowns.has(id):
					_contact_cooldowns[id] = damage_interval
					if player.has_method("_hit_by_beam"):
						player._hit_by_beam()
					else:
						player._hit_something(1)
				break

func _length() -> float:
	return maxf(get_viewport_rect().end.y - global_position.y, 0.0)

func _draw() -> void:
	if not active:
		return
	var length := _length()
	for offset in offsets:
		var lane_width := central_width if is_zero_approx(offset) else width
		var visual_width := 32.0 * lane_width / 12.0
		var frame := int(_elapsed / 0.075) % 4
		for y in range(0, ceili(length), 64):
			var height := minf(64, length - y)
			draw_texture_rect_region(TEXTURE, Rect2(offset - visual_width * 0.5, y, visual_width, height), Rect2(frame * 32, 0, 32, height))
