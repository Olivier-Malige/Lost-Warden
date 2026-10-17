class_name WaveSpawnerConfig
extends Resource

@export_group("Formation")
@export_range(1, 32, 1) var lane_count := 12
@export_range(1, 200, 1) var solo_enemy_cap := 70
@export_range(1, 200, 1) var coop_enemy_cap := 90
@export_range(0.0, 20.0, 1.0) var v_formation_depth := 6.0

@export_group("Co-op")
@export_range(1.0, 3.0, 0.05) var coop_budget_multiplier := 1.2
@export_range(1.0, 5.0, 0.05) var coop_common_health_multiplier := 1.25
@export_range(1.0, 5.0, 0.05) var coop_specialist_health_multiplier := 1.45
@export_range(1.0, 5.0, 0.05) var coop_heavy_health_multiplier := 1.60

@export_group("Elite")
@export var elite_definition: EliteDefinition
@export_range(1, 10, 1) var elite_cap := 3

func is_valid() -> bool:
	return lane_count > 0 and solo_enemy_cap > 0 and coop_enemy_cap >= solo_enemy_cap \
		and v_formation_depth >= 0.0 and coop_budget_multiplier >= 1.0 \
		and coop_common_health_multiplier >= 1.0 and coop_specialist_health_multiplier >= 1.0 \
		and coop_heavy_health_multiplier >= 1.0 and elite_definition != null and elite_cap > 0
