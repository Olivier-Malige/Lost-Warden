class_name BossDefinition
extends Resource

@export var id: StringName
@export var display_name := "Command Carrier"
@export var scene: PackedScene
@export var minimum_danger := 1.0
@export var maximum_danger := 1000.0
@export var selection_weight := 1.0
@export var health := 900.0
@export var coop_health_multiplier := 1.6
@export var cannon_health := 120.0
@export var phase_thresholds := PackedFloat32Array([0.66, 0.33])
@export var movement_speeds := PackedFloat32Array([18.0, 27.0, 36.0])
@export var movement_ranges := PackedFloat32Array([88.0, 120.0, 144.0])
@export var movement_acceleration := 180.0
@export var movement_arrival_pause := 0.35
@export var vertical_movement_range := 14.0
@export var volley_intervals := PackedFloat32Array([2.4, 1.9, 1.4])
@export var volley_counts := PackedInt32Array([3, 5, 7])
@export_range(1, 8, 1) var salvo_count := 1
@export var salvo_interval := 0.25
@export var projectile_speed := 125.0
@export var telegraph_time := 0.7
@export var reinforcement_intervals := PackedFloat32Array([12.0, 10.0, 8.0])
@export_range(0, 30, 1) var reinforcement_cap := 6
@export var coop_reinforcement_multiplier := 1.5
@export var beam_charge_time := 0.96
@export var beam_fire_time := 1.25
@export var beam_width := 12.0
@export var central_beam_width := 24.0
@export var reinforcements: Array[SpawnRule] = []

func is_valid() -> bool:
	var phases := phase_thresholds.size() + 1
	if not (id != &"" and scene != null and health > 0.0 and coop_health_multiplier >= 1.0 and cannon_health > 0.0 \
		and minimum_danger >= 1.0 and maximum_danger >= minimum_danger and selection_weight >= 0.0 \
		and projectile_speed > 0.0 and telegraph_time > 0.0 and reinforcement_cap >= 0 \
		and salvo_count >= 1 and salvo_count <= 8 and salvo_interval >= 0.21 \
		and phases >= 2 and phases <= 8 and coop_reinforcement_multiplier >= 1.0 \
		and beam_charge_time > 0.0 and beam_fire_time > 0.0 and beam_width > 0.0 \
		and central_beam_width >= beam_width \
		and movement_acceleration > 0.0 and movement_arrival_pause >= 0.0 and vertical_movement_range >= 0.0 \
		and movement_speeds.size() == phases and movement_ranges.size() == phases \
		and volley_intervals.size() == phases and volley_counts.size() == phases \
		and reinforcement_intervals.size() == phases):
		return false
	var previous := 1.0
	for threshold in phase_thresholds:
		if threshold <= 0.0 or threshold >= previous:
			return false
		previous = threshold
	for index in phases:
		if movement_speeds[index] < 0.0 or movement_ranges[index] < 0.0 or volley_intervals[index] <= 0.0 \
			or volley_counts[index] < 1 or reinforcement_intervals[index] <= 0.0:
			return false
	for rule in reinforcements:
		if rule == null or not rule.is_valid(12):
			return false
	return true
