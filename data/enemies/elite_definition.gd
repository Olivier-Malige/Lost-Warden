class_name EliteDefinition
extends Resource

@export_group("Gameplay")
@export_range(1.0, 10.0, 0.05) var health_multiplier := 2.5
@export_range(0.1, 5.0, 0.05) var speed_multiplier := 1.1
@export_range(0.05, 2.0, 0.05) var fire_delay_multiplier := 0.8
@export_range(1, 20, 1) var score_multiplier := 3

@export_group("Presentation")
@export var outline_color := Color("b979c8")
@export var aura_color := Color("ff5a4d")
@export_range(0.0, 1.0, 0.01) var aura_alpha := 0.16
@export var health_bar_background := Color("101522")
@export var health_bar_size := Vector2(30, 3)
