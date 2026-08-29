class_name EliteIndicator
extends Node2D

var target: Enemy
var definition: EliteDefinition
var max_health := 1
var current_health := 1
var radius := 18.0
var elapsed := 0.0

func setup(p_target: Enemy, p_max_health: int, p_definition: EliteDefinition) -> void:
	target = p_target
	definition = p_definition
	max_health = maxi(p_max_health, 1)
	current_health = max_health
	var sprite := target.get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.texture:
		radius = clampf(sprite.get_rect().size.length() * 0.28, 18.0, 34.0)
	show_behind_parent = true
	queue_redraw()

func set_health(value: int) -> void:
	current_health = clampi(value, 0, max_health)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + sin(elapsed * 4.0) * 0.5
	var low_graphics: bool = String(global.saveData.config.graphic) == "low"
	var aura_alpha := definition.low_graphics_aura_alpha if low_graphics else definition.aura_alpha + pulse * 0.1
	draw_circle(Vector2.ZERO, radius + 4.0 + pulse * 2.0, Color(definition.aura_color, aura_alpha))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, definition.outline_color, 1.0, true)
	var bar_position := Vector2(-definition.health_bar_size.x * 0.5, -radius - 10.0)
	draw_rect(Rect2(bar_position, definition.health_bar_size), definition.health_bar_background)
	var fill_size := Vector2(definition.health_bar_size.x - 2.0, definition.health_bar_size.y - 2.0)
	draw_rect(Rect2(bar_position + Vector2.ONE, Vector2(fill_size.x * float(current_health) / max_health, fill_size.y)), definition.outline_color)
