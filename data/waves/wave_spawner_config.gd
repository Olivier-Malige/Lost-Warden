class_name WaveSpawnerConfig
extends Resource

@export_group("Formation")
@export_range(1, 32, 1) var lane_count := 12
@export_range(1, 200, 1) var solo_enemy_cap := 45
@export_range(1, 200, 1) var coop_enemy_cap := 60

@export_group("Difficulty")
@export_range(0.1, 10.0, 0.05) var difficulty_start := 1.3
@export_range(0.1, 10.0, 0.05) var difficulty_end := 2.8
@export_range(0.1, 1.0, 0.01) var max_wave_pace_multiplier := 0.82

@export_group("Endless loop")
@export_range(0, 99, 1) var loop_start_index := 8
@export_range(0.0, 1.0, 0.01) var health_step := 0.1
@export_range(1.0, 5.0, 0.05) var health_cap := 1.5
@export_range(0.0, 1.0, 0.01) var pace_step := 0.05
@export_range(0.1, 1.0, 0.01) var pace_cap := 0.8

@export_group("Elite")
@export var elite_definition: EliteDefinition

func is_valid() -> bool:
	return lane_count > 0 \
		and solo_enemy_cap > 0 \
		and coop_enemy_cap >= solo_enemy_cap \
		and difficulty_end > difficulty_start \
		and health_cap >= 1.0 \
		and elite_definition != null
