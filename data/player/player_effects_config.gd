class_name PlayerEffectsConfig
extends Resource

@export_group("Reactors")
@export_range(0.0, 1.0, 0.05) var backward_amount_ratio := 0.15
@export_range(0.0, 1.0, 0.05) var idle_amount_ratio := 0.55
@export_range(0.0, 1.0, 0.05) var forward_amount_ratio := 1.0
@export_range(0.0, 4.0, 0.05) var backward_speed_scale := 0.35
@export_range(0.0, 4.0, 0.05) var idle_speed_scale := 0.8
@export_range(0.0, 4.0, 0.05) var forward_speed_scale := 1.55
@export_range(0.1, 3.0, 0.05) var backward_length_scale := 0.45
@export_range(0.1, 3.0, 0.05) var idle_length_scale := 0.85
@export_range(0.1, 3.0, 0.05) var forward_length_scale := 1.55
@export_range(0.1, 1.0, 0.05) var backward_brightness := 0.45
@export_range(0.1, 1.0, 0.05) var idle_brightness := 0.75
@export_range(0.1, 1.0, 0.05) var forward_brightness := 1.0
@export_range(0.1, 10.0, 0.1) var reactor_response_speed := 4.0

@export_group("Plasma beam")
@export_range(0.0, 1.0, 0.05) var minimum_amount_ratio := 0.4
@export_range(0.0, 1.0, 0.05) var maximum_amount_ratio := 1.0
@export_range(0.0, 4.0, 0.05) var minimum_speed_scale := 0.7
@export_range(0.0, 4.0, 0.05) var maximum_speed_scale := 1.2
@export_range(1.0, 128.0, 1.0) var minimum_emission_radius := 9.0
@export_range(1.0, 128.0, 1.0) var maximum_emission_radius := 29.0
@export_range(0.1, 4.0, 0.05) var minimum_particle_scale := 0.8
@export_range(0.1, 4.0, 0.05) var maximum_particle_scale := 2.0

func is_valid() -> bool:
	return backward_amount_ratio <= idle_amount_ratio \
		and idle_amount_ratio <= forward_amount_ratio \
		and backward_speed_scale <= idle_speed_scale \
		and idle_speed_scale <= forward_speed_scale \
		and backward_length_scale <= idle_length_scale \
		and idle_length_scale <= forward_length_scale \
		and backward_brightness <= idle_brightness \
		and idle_brightness <= forward_brightness \
		and minimum_amount_ratio <= maximum_amount_ratio \
		and minimum_speed_scale <= maximum_speed_scale \
		and minimum_emission_radius <= maximum_emission_radius \
		and minimum_particle_scale <= maximum_particle_scale
