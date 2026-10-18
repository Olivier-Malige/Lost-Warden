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
@export var phase_thresholds := PackedFloat32Array([0.5])
@export var movement_speeds := PackedFloat32Array([80.0, 115.0])
@export var movement_ranges := PackedFloat32Array([120.0, 144.0])
@export var movement_acceleration := 180.0
@export var movement_arrival_pause := 0.35
@export var vertical_movement_range := 14.0
@export var attack_pause := 0.35
@export var phase_one_patterns: Array[BossAttackPattern] = []
@export var phase_two_patterns: Array[BossAttackPattern] = []
@export_range(0, 30, 1) var reinforcement_cap := 6
@export var coop_reinforcement_multiplier := 1.5
@export var beam_charge_time := 0.96
@export var beam_fire_time := 1.25
@export var beam_width := 12.0
@export var central_beam_width := 24.0
@export var beam_damage_interval := 0.35
@export var reinforcements: Array[SpawnRule] = []

func is_valid() -> bool:
	var phases := phase_thresholds.size() + 1
	if not (id != &"" and scene != null and health > 0.0 and coop_health_multiplier >= 1.0 and cannon_health > 0.0 \
		and minimum_danger >= 1.0 and maximum_danger >= minimum_danger and selection_weight >= 0.0 \
		and attack_pause > 0.0 and reinforcement_cap >= 0 \
		and phases == 2 and coop_reinforcement_multiplier >= 1.0 \
		and beam_charge_time > 0.0 and beam_fire_time > 0.0 and beam_width > 0.0 \
		and central_beam_width >= beam_width and beam_damage_interval > 0.0 \
		and movement_acceleration > 0.0 and movement_arrival_pause >= 0.0 and vertical_movement_range >= 0.0 \
		and movement_speeds.size() == phases and movement_ranges.size() == phases \
		and not phase_one_patterns.is_empty() and not phase_two_patterns.is_empty()):
		return false
	var previous := 1.0
	for threshold in phase_thresholds:
		if threshold <= 0.0 or threshold >= previous:
			return false
		previous = threshold
	for index in phases:
		if movement_speeds[index] < 0.0 or movement_ranges[index] < 0.0:
			return false
	for patterns in [phase_one_patterns, phase_two_patterns]:
		for pattern in patterns:
			if pattern == null or not pattern.is_valid():
				return false
	for pattern in phase_one_patterns:
		if pattern.kind == BossAttackPattern.Kind.BEAM:
			return false
	for rule in reinforcements:
		if rule == null or not rule.is_valid(12):
			return false
	return true
