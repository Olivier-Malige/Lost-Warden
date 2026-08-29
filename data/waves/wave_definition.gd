class_name WaveDefinition
extends Resource

@export_range(1.0, 180.0, 0.5) var duration: float = 30.0
@export_range(0.1, 10.0, 0.05) var difficulty: float = 1.0
@export var rules: Array[SpawnRule] = []

func is_valid(lane_count: int) -> bool:
	if duration <= 0.0 or difficulty <= 0.0 or rules.is_empty():
		return false
	for rule in rules:
		if rule == null or not rule.is_valid(lane_count):
			return false
	return true
