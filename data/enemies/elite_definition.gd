class_name EliteDefinition
extends Resource

@export_group("Gameplay")
@export var health_multiplier := 2.5
@export var speed_multiplier := 1.1
@export var fire_delay_multiplier := 0.8
@export var score_multiplier := 3

@export_group("Presentation")
@export var outline_color := Color("b979c8")
@export var aura_color := Color("ff5a4d")
@export var aura_alpha := 0.16
@export var low_graphics_aura_alpha := 0.08
@export var health_bar_background := Color("101522")
@export var health_bar_size := Vector2(30, 3)
