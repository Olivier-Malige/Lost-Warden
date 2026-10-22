class_name ProgressionConfig
extends Resource

@export var xp_base: int = 10
@export var xp_growth: float = 1.28
@export var offensive_slots: int = 3
@export var utility_slots: int = 3
@export var family_weight: int = 10
@export var reward_weight: int = 5
@export var speed_base: float = 180.0
@export var speed_max: float = 240.0
@export var manual_delay_base: float = 0.20
@export var manual_delay_min: float = 0.12
@export var attraction_base: float = 24.0
@export var attraction_max: float = 120.0
@export var energy_max: int = 12

func threshold_for_level(level: int) -> int:
	return maxi(1, roundi(xp_base * pow(xp_growth, maxi(level, 1) - 1)))

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if xp_base <= 0 or not is_finite(xp_growth) or xp_growth < 1.0:
		errors.append("XP thresholds require a positive base and finite growth >= 1.")
	if offensive_slots <= 0 or utility_slots <= 0:
		errors.append("Family slot capacities must be positive.")
	if family_weight <= 0 or reward_weight <= 0:
		errors.append("Offer weights must be positive.")
	for limits in [[speed_base, speed_max], [manual_delay_min, manual_delay_base], [attraction_base, attraction_max]]:
		if not is_finite(limits[0]) or not is_finite(limits[1]) or limits[0] <= 0.0 or limits[1] < limits[0]:
			errors.append("Foundation limits must be finite, positive and ordered.")
	if energy_max <= 0:
		errors.append("Vital limits must be positive.")
	return errors
