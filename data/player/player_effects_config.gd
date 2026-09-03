class_name PlayerEffectsConfig
extends Resource

@export_group("Reactors")
@export_range(0.0, 1.0, 0.05) var idle_amount_ratio := 0.6
@export_range(0.0, 1.0, 0.05) var forward_amount_ratio := 1.0
@export_range(0.0, 1.0, 0.05) var reverse_amount_ratio := 0.35

@export_group("Plasma beam")
@export_range(0.0, 1.0, 0.05) var minimum_amount_ratio := 0.4
@export_range(0.0, 1.0, 0.05) var maximum_amount_ratio := 1.0
@export_range(0.0, 4.0, 0.05) var minimum_speed_scale := 0.7
@export_range(0.0, 4.0, 0.05) var maximum_speed_scale := 1.2
@export_range(1.0, 128.0, 1.0) var minimum_emission_radius := 18.0
@export_range(1.0, 128.0, 1.0) var maximum_emission_radius := 58.0
@export_range(0.1, 4.0, 0.05) var minimum_particle_scale := 0.8
@export_range(0.1, 4.0, 0.05) var maximum_particle_scale := 2.0

func is_valid() -> bool:
	return minimum_amount_ratio <= maximum_amount_ratio \
		and minimum_speed_scale <= maximum_speed_scale \
		and minimum_emission_radius <= maximum_emission_radius \
		and minimum_particle_scale <= maximum_particle_scale
