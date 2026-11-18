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

enum Family { OPENING, FLEET, AMBUSH, DEBRIS, ELITE_HUNT, CROSSFIRE, REENTRY }

@export var family: Family = Family.OPENING
@export var minimum_combat_time := 0.0
@export var minimum_survival_time := 0.0
@export var coordinated := false
@export_range(0.35, 5.0, 0.05) var coordinated_delay := 1.15

func is_encounter_valid(lane_count: int = 12) -> bool:
	var minimum_duration := 6.0 if family in [Family.REENTRY, Family.DEBRIS] else 20.0
	return id != &"" and duration >= minimum_duration and duration <= 30.0 \
		and minimum_danger >= 1.0 and maximum_danger >= minimum_danger \
		and selection_weight >= 0.0 and threat_budget > 0.0 and is_valid(lane_count)

func is_valid(lane_count: int) -> bool:
	if duration <= 0.0 or rules.is_empty():
		return false
	for rule in rules:
		if rule == null or not rule.is_valid(lane_count):
			return false
	return true
