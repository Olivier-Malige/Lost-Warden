class_name EliteIndicator
extends Node2D

var target: Enemy
var definition: EliteDefinition
var max_health := 1.0
var current_health := 1.0
var radius := 9.0

func setup(p_target: Enemy, p_max_health: float, p_definition: EliteDefinition) -> void:
	target = p_target
	definition = p_definition
	max_health = maxf(p_max_health, 1.0)
	current_health = max_health
	var sprite := target.get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.texture:
		radius = sprite.get_rect().size.y * absf(sprite.scale.y) * 0.5
	queue_redraw()

func set_health(value: float) -> void:
	current_health = clampf(value, 0.0, max_health)
	queue_redraw()

func _draw() -> void:
	var bar_position := Vector2(-definition.health_bar_size.x * 0.5, -radius - 5.0)
	draw_rect(Rect2(bar_position, definition.health_bar_size), definition.health_bar_background)
	var fill_size := Vector2(definition.health_bar_size.x - 2.0, definition.health_bar_size.y - 2.0)
	draw_rect(Rect2(bar_position + Vector2.ONE, Vector2(fill_size.x * float(current_health) / max_health, fill_size.y)), definition.outline_color)
