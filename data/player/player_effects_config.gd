class_name PlayerEffectsConfig
extends Resource

@export_group("Reactors")
@export_range(0.0, 1.0, 0.05) var idle_amount_ratio := 0.6
@export_range(0.0, 1.0, 0.05) var forward_amount_ratio := 1.0
@export_range(0.0, 1.0, 0.05) var reverse_amount_ratio := 0.35
@export_range(0.1, 1.0, 0.1) var low_graphics_amount_scale := 0.5

@export_group("Beam charge")
@export_range(0.0, 5.0, 0.05) var visible_after := 0.5
@export_range(0.0, 1.0, 0.05) var minimum_amount_ratio := 0.25
@export_range(0.0, 1.0, 0.05) var maximum_amount_ratio := 1.0
@export_range(0.0, 4.0, 0.05) var minimum_speed_scale := 0.7
@export_range(0.0, 4.0, 0.05) var maximum_speed_scale := 1.2

func is_valid() -> bool:
	return minimum_amount_ratio <= maximum_amount_ratio \
		and minimum_speed_scale <= maximum_speed_scale
