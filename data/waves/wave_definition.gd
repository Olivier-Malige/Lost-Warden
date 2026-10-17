class_name WaveDefinition
extends Resource

@export_range(1.0, 180.0, 0.5) var duration: float = 30.0
@export var rules: Array[SpawnRule] = []

@export_group("Encounter director")
@export var id: StringName
@export var minimum_danger := 1.0
@export var maximum_danger := 1000.0
@export var selection_weight := 1.0
@export var threat_budget := 30.0

func is_encounter_valid(lane_count: int = 12) -> bool:
	return id != &"" and duration >= 20.0 and duration <= 30.0 \
		and minimum_danger >= 1.0 and maximum_danger >= minimum_danger \
		and selection_weight >= 0.0 and threat_budget > 0.0 and is_valid(lane_count)

func is_valid(lane_count: int) -> bool:
	if duration <= 0.0 or rules.is_empty():
		return false
	for rule in rules:
		if rule == null or not rule.is_valid(lane_count):
			return false
	return true
