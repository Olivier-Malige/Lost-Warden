class_name ProjectileVfxConfig
extends Resource

@export_group("Glow")
@export var glow_material: Material
@export_range(1.0, 3.0, 0.05) var core_brightness := 1.65
@export_range(1.0, 5.0, 0.05) var glow_scale := 1.25
@export var glow_spread := Vector2(1.35, 0.68)
@export_range(0.0, 1.0, 0.01) var glow_alpha := 0.5
@export var player_one_color := Color(1.0, 0.22, 0.18)
@export var player_two_color := Color(0.25, 0.42, 1.0)

@export_group("Trail")
@export_range(0.0, 32.0, 0.5) var trail_width := 6.0
@export_range(0.0, 128.0, 1.0) var trail_length := 34.0
@export_range(0.0, 1.0, 0.05) var trail_middle_offset := 0.35
@export var trail_head_color := Color(0.95, 0.98, 1.0, 0.95)
@export var player_one_trail_color := Color(0.15, 0.8, 1.0, 0.45)
@export var player_two_trail_color := Color(1.0, 0.32, 0.66, 0.45)

func player_color(player_id: String) -> Color:
	return player_one_color if player_id == "player1" else player_two_color

func glow_color(player_id: String) -> Color:
	var color := player_color(player_id)
	return Color(color.r, color.g, color.b, glow_alpha)

func trail_color(player_id: String) -> Color:
	return player_one_trail_color if player_id == "player1" else player_two_trail_color

func is_valid() -> bool:
	return glow_material != null and glow_scale >= 1.0 and trail_width >= 0.0 and trail_length >= 0.0
