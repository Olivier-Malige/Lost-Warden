class_name WaveSpawnerConfig
extends Resource

@export_group("Formation")
@export_range(1, 32, 1) var lane_count := 12
@export_range(1, 200, 1) var solo_enemy_cap := 45
@export_range(1, 200, 1) var coop_enemy_cap := 60
@export var movement_seed := 0x4D4F5645

@export_group("Timing")
@export_range(1.0, 180.0, 0.5) var wave_duration := 36.0
@export_range(0.0, 30.0, 0.5) var inter_wave_delay := 2.0
@export_range(1.0, 2.0, 0.05) var spawn_interval_multiplier := 1.1

@export_group("Difficulty")
@export_range(0.1, 10.0, 0.05) var difficulty_start := 1.0
@export_range(0.1, 10.0, 0.05) var difficulty_end := 3.55
@export_range(0.1, 1.0, 0.01) var max_wave_pace_multiplier := 0.82

@export_group("Endless loop")
@export_range(0, 99, 1) var loop_start_index := 17
@export_range(0.0, 1.0, 0.01) var health_step := 0.08
@export_range(1.0, 5.0, 0.05) var health_cap := 1.75
@export_range(0.0, 1.0, 0.01) var pace_step := 0.04
@export_range(0.1, 1.0, 0.01) var pace_cap := 0.65
@export_range(1, 20, 1) var formation_step_cycles := 2
@export_range(0, 12, 1) var formation_bonus_cap := 2
@export_range(1, 20, 1) var elite_step_cycles := 3
@export_range(0, 3, 1) var elite_bonus_cap := 2

@export_group("Elite")
@export var elite_definition: EliteDefinition

func is_valid() -> bool:
	return wave_duration > 0.0 \
		and inter_wave_delay >= 0.0 \
		and spawn_interval_multiplier >= 1.0 \
		and lane_count > 0 \
		and solo_enemy_cap > 0 \
		and coop_enemy_cap >= solo_enemy_cap \
		and difficulty_end > difficulty_start \
		and health_cap >= 1.0 \
		and formation_step_cycles > 0 \
		and elite_step_cycles > 0 \
		and elite_definition != null
