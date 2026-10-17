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
@export var phase_thresholds := PackedFloat32Array([0.66, 0.33])
@export var movement_speeds := PackedFloat32Array([18.0, 27.0, 36.0])
@export var volley_intervals := PackedFloat32Array([2.4, 1.9, 1.4])
@export var volley_counts := PackedInt32Array([3, 5, 7])
@export var projectile_speed := 125.0
@export var telegraph_time := 0.7
@export var reinforcement_intervals := PackedFloat32Array([12.0, 10.0, 8.0])
@export var reinforcements: Array[SpawnRule] = []

func is_valid() -> bool:
	if not (id != &"" and scene != null and health > 0.0 and coop_health_multiplier >= 1.0 \
		and minimum_danger >= 1.0 and maximum_danger >= minimum_danger and selection_weight >= 0.0 \
		and projectile_speed > 0.0 and telegraph_time > 0.0 \
		and phase_thresholds.size() == 2 and phase_thresholds[0] > phase_thresholds[1] \
		and phase_thresholds[0] < 1.0 and phase_thresholds[1] > 0.0 \
		and movement_speeds.size() == 3 and volley_intervals.size() == 3 \
		and volley_counts.size() == 3 and reinforcement_intervals.size() == 3):
		return false
	for index in 3:
		if movement_speeds[index] < 0.0 or volley_intervals[index] <= 0.0 \
			or volley_counts[index] < 1 or reinforcement_intervals[index] <= 0.0:
			return false
	for rule in reinforcements:
		if rule == null or not rule.is_valid(12):
			return false
	return true
