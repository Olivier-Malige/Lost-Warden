class_name PlayerEffectsConfig
extends Resource

@export_group("Reactors")
@export_range(0.0, 1.0, 0.05) var idle_amount_ratio := 0.6
@export_range(0.0, 1.0, 0.05) var forward_amount_ratio := 1.0
@export_range(0.0, 1.0, 0.05) var reverse_amount_ratio := 0.35
@export_range(0.1, 1.0, 0.1) var low_graphics_amount_scale := 0.5

@export_group("Beam charge")
@export var visible_after := 0.5
@export var minimum_particles := 5
@export var maximum_particles := 23
@export var low_graphics_amount_scale_charge := 0.5
@export var minimum_speed_scale := 0.7
@export var maximum_speed_scale := 1.2
